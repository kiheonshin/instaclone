(function () {
  "use strict";

  if (window.__instacloneAnalyticsLoaded) {
    return;
  }
  window.__instacloneAnalyticsLoaded = true;

  const SESSION_STORAGE_KEY = "instaclone_analytics_session";
  const SESSION_TIMEOUT_MS = 30 * 60 * 1000; // 30 min inactivity timeout

  const RAGE_WINDOW_MS = 500;
  const RAGE_RADIUS_PX = 24;
  const RAGE_MIN_CLICKS = 3;
  const DEAD_CLICK_DELAY_MS = 700;
  const SCROLL_THRESHOLDS = [25, 50, 75, 100];
  const FLUSH_INTERVAL_MS = 3000;
  const FLUSH_BATCH_SIZE = 12;

  const config = {
    supabaseUrl: "",
    supabaseAnonKey: "",
  };

  let isReady = false;
  let historyHooked = false;
  let observerAttached = false;
  let flushInFlight = false;
  let queue = [];
  let flushTimer = null;

  let mutationCount = 0;
  let currentPageUrl = getCurrentPageUrl();
  let pageEnteredAt = Date.now();
  let reachedScrollDepths = new Set();
  let interactionActivityTick = 0;

  let sessionId = null;
  let sessionLastActivity = 0;

  let recentClicks = [];
  let lastRageEmitAt = 0;
  let lastRageSignature = "";

  function initFromDart(initConfigOrUrl, maybeAnonKey) {
    if (typeof initConfigOrUrl === "string") {
      config.supabaseUrl = String(initConfigOrUrl || "");
      config.supabaseAnonKey = String(maybeAnonKey || "");
    } else if (initConfigOrUrl && typeof initConfigOrUrl === "object") {
      config.supabaseUrl = String(initConfigOrUrl.supabaseUrl || "");
      config.supabaseAnonKey = String(initConfigOrUrl.supabaseAnonKey || "");
    }
    start();
    void flushQueue();
  }

  function trackCtaFromFlutter(ctaId, payload) {
    if (!ctaId) {
      return;
    }
    const elementInfo = Object.assign(
      {
        cta_id: String(ctaId),
        source: "flutter_bridge",
      },
      normalizeObject(payload),
    );
    enqueueEvent(
      buildEvent("cta_click", {
        elementInfo,
      }),
    );
  }

  window.analyticsTrackerInit = initFromDart;
  window.analyticsTrackCta = trackCtaFromFlutter;
  if (window.__instacloneAnalyticsInitConfig) {
    initFromDart(window.__instacloneAnalyticsInitConfig);
  }

  function start() {
    if (isReady) {
      return;
    }
    isReady = true;
    loadOrCreateSession();
    installListeners();
    enqueueEvent(
      buildEvent("page_view", {
        eventPageUrl: currentPageUrl,
        elementInfo: {
          reason: "initial_load",
        },
      }),
    );
    handleScrollDepth();
    if (!flushTimer) {
      flushTimer = window.setInterval(() => {
        void flushQueue();
      }, FLUSH_INTERVAL_MS);
    }
  }

  function installListeners() {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", installListeners, { once: true });
      return;
    }

    if (!historyHooked) {
      hookHistory();
      historyHooked = true;
    }

    if (!observerAttached && window.MutationObserver) {
      const observer = new MutationObserver(() => {
        mutationCount += 1;
        markInteractionActivity("dom_mutation");
      });
      observer.observe(document.documentElement, {
        subtree: true,
        childList: true,
        attributes: true,
      });
      observerAttached = true;
    }

    patchNetworkActivitySignals();

    document.addEventListener("click", onClick, true);
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("popstate", () => handleRouteChange("popstate"));
    window.addEventListener("hashchange", () => handleRouteChange("hashchange"));
    window.addEventListener("beforeunload", () => {
      emitPageDwell("unload");
      void flushQueue(true);
    });
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "hidden") {
        emitPageDwell("hidden");
        void flushQueue(true);
      } else if (document.visibilityState === "visible") {
        pageEnteredAt = Date.now();
      }
    });
  }

  function hookHistory() {
    const rawPushState = history.pushState;
    const rawReplaceState = history.replaceState;

    history.pushState = function patchedPushState() {
      rawPushState.apply(history, arguments);
      window.setTimeout(() => handleRouteChange("push_state"), 0);
    };

    history.replaceState = function patchedReplaceState() {
      rawReplaceState.apply(history, arguments);
      window.setTimeout(() => handleRouteChange("replace_state"), 0);
    };
  }

  function onClick(event) {
    const target = event.target instanceof Element ? event.target : null;
    if (!target) {
      return;
    }

    const x = Math.round(event.clientX || 0);
    const y = Math.round(event.clientY || 0);
    const elementInfo = getElementInfo(target);

    enqueueEvent(
      buildEvent("click", {
        xPos: x,
        yPos: y,
        elementInfo,
      }),
    );

    const ctaTarget = target.closest('[data-track="cta"]');
    if (ctaTarget) {
      const ctaInfo = Object.assign({}, elementInfo, {
        source: "data-track",
        cta_id:
          ctaTarget.getAttribute("data-cta-id") ||
          ctaTarget.getAttribute("id") ||
          elementInfo.selector ||
          "cta",
      });
      enqueueEvent(
        buildEvent("cta_click", {
          xPos: x,
          yPos: y,
          elementInfo: ctaInfo,
        }),
      );
    }

    detectRageClick(x, y, elementInfo);
    detectDeadClick(target, x, y, elementInfo);
  }

  let scrollTicking = false;
  function onScroll() {
    touchSession();
    if (scrollTicking) {
      return;
    }
    scrollTicking = true;
    window.requestAnimationFrame(() => {
      scrollTicking = false;
      handleScrollDepth();
    });
  }

  function handleScrollDepth() {
    const depth = getScrollDepthPercent();
    SCROLL_THRESHOLDS.forEach((threshold) => {
      if (depth >= threshold && !reachedScrollDepths.has(threshold)) {
        reachedScrollDepths.add(threshold);
        enqueueEvent(
          buildEvent("scroll_depth", {
            scrollDepth: threshold,
            elementInfo: {
              depth_percent: depth,
              viewport_h: window.innerHeight || 0,
              document_h: getDocumentHeight(),
            },
          }),
        );
      }
    });
  }

  function detectRageClick(x, y, elementInfo) {
    const now = Date.now();
    const page = getCurrentPageUrl();
    recentClicks.push({ x, y, page, t: now });
    recentClicks = recentClicks.filter((item) => now - item.t <= RAGE_WINDOW_MS && item.page === page);

    const nearby = recentClicks.filter((item) => distanceSquared(item.x, item.y, x, y) <= RAGE_RADIUS_PX * RAGE_RADIUS_PX);
    if (nearby.length < RAGE_MIN_CLICKS) {
      return;
    }

    const signature = `${page}:${Math.round(x / 12)}:${Math.round(y / 12)}`;
    if (signature === lastRageSignature && now - lastRageEmitAt < RAGE_WINDOW_MS) {
      return;
    }
    lastRageSignature = signature;
    lastRageEmitAt = now;

    enqueueEvent(
      buildEvent("rage_click", {
        xPos: x,
        yPos: y,
        elementInfo: Object.assign({}, elementInfo, {
          burst_count: nearby.length,
          window_ms: RAGE_WINDOW_MS,
          radius_px: RAGE_RADIUS_PX,
        }),
      }),
    );
  }

  function detectDeadClick(target, x, y, elementInfo) {
    if (!isPotentialClickable(target)) {
      return;
    }

    const urlSnapshot = getCurrentPageUrl();
    const mutationSnapshot = mutationCount;
    const activitySnapshot = interactionActivityTick;

    window.setTimeout(() => {
      if (document.visibilityState === "hidden") {
        return;
      }
      const samePage = getCurrentPageUrl() === urlSnapshot;
      const noMutation = mutationSnapshot === mutationCount;
      const noInteractionActivity = activitySnapshot === interactionActivityTick;
      if (samePage && noMutation && noInteractionActivity) {
        enqueueEvent(
          buildEvent("dead_click", {
            xPos: x,
            yPos: y,
            elementInfo: Object.assign({}, elementInfo, {
              delay_ms: DEAD_CLICK_DELAY_MS,
              detection: "no_navigation_no_dom_change",
            }),
          }),
        );
      }
    }, DEAD_CLICK_DELAY_MS);
  }

  function handleRouteChange(reason) {
    const nextPage = getCurrentPageUrl();
    if (nextPage === currentPageUrl) {
      return;
    }

    markInteractionActivity("route_change");
    emitPageDwell("route_change");
    currentPageUrl = nextPage;
    pageEnteredAt = Date.now();
    reachedScrollDepths = new Set();

    enqueueEvent(
      buildEvent("page_view", {
        eventPageUrl: currentPageUrl,
        elementInfo: {
          reason,
        },
      }),
    );
    handleScrollDepth();
  }

  function emitPageDwell(reason) {
    const now = Date.now();
    const durationMs = Math.max(0, now - pageEnteredAt);
    if (durationMs < 250) {
      pageEnteredAt = now;
      return;
    }

    enqueueEvent(
      buildEvent("page_dwell", {
        eventPageUrl: currentPageUrl,
        elementInfo: {
          reason,
          duration_ms: durationMs,
        },
      }),
    );
    pageEnteredAt = now;
  }

  function enqueueEvent(eventData) {
    touchSession();
    queue.push(eventData);
    if (queue.length > 2000) {
      queue = queue.slice(queue.length - 2000);
    }
    if (queue.length >= FLUSH_BATCH_SIZE) {
      void flushQueue();
    }
  }

  async function flushQueue(keepalive) {
    if (flushInFlight || queue.length === 0 || !isConfigured()) {
      return;
    }

    flushInFlight = true;
    const payload = queue.slice();
    queue = [];

    try {
      const response = await fetch(getInsertEndpoint(), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: config.supabaseAnonKey,
          Authorization: `Bearer ${config.supabaseAnonKey}`,
          Prefer: "return=minimal",
        },
        body: JSON.stringify(payload),
        keepalive: Boolean(keepalive),
      });
      if (!response.ok) {
        queue = payload.concat(queue).slice(0, 2000);
      }
    } catch (error) {
      queue = payload.concat(queue).slice(0, 2000);
    } finally {
      flushInFlight = false;
    }
  }

  function buildEvent(eventType, options) {
    const eventOptions = options || {};
    const nowIso = new Date().toISOString();
    const baseElementInfo = {
      viewport_w: window.innerWidth || 0,
      viewport_h: window.innerHeight || 0,
      route_path: getCurrentPageUrl(),
      client_timestamp: nowIso,
    };

    return {
      event_type: eventType,
      page_url: eventOptions.eventPageUrl || getCurrentPageUrl(),
      element_info: Object.assign(baseElementInfo, normalizeObject(eventOptions.elementInfo)),
      x_pos: toNullableInt(eventOptions.xPos),
      y_pos: toNullableInt(eventOptions.yPos),
      scroll_depth: toNullableInt(eventOptions.scrollDepth),
      session_id: sessionId || "",
      user_agent: navigator.userAgent || "",
      referrer: document.referrer || "",
    };
  }

  function getElementInfo(element) {
    const className = (element.className && typeof element.className === "string") ? element.className : "";
    const classList = className
      .split(" ")
      .map((item) => item.trim())
      .filter(Boolean)
      .slice(0, 6);
    return {
      tag: (element.tagName || "").toLowerCase(),
      class_list: classList,
      text_preview: extractElementText(element),
      selector: buildSelector(element),
      clickable: isPotentialClickable(element),
    };
  }

  function extractElementText(element) {
    const text =
      element.getAttribute("aria-label") ||
      element.getAttribute("alt") ||
      element.getAttribute("title") ||
      (element.innerText || "").trim() ||
      (typeof element.value === "string" ? element.value : "");
    return sanitizeText(text, 100);
  }

  function buildSelector(element) {
    if (!element || !(element instanceof Element)) {
      return "";
    }
    if (element.id) {
      return `#${element.id}`;
    }

    const parts = [];
    let current = element;
    for (let i = 0; i < 4 && current && current.tagName; i += 1) {
      const tag = current.tagName.toLowerCase();
      const cls = (current.className && typeof current.className === "string")
        ? current.className.trim().split(/\s+/).filter(Boolean).slice(0, 2).join(".")
        : "";
      parts.unshift(cls ? `${tag}.${cls}` : tag);
      current = current.parentElement;
    }
    return parts.join(" > ");
  }

  function isPotentialClickable(element) {
    if (!element || !(element instanceof Element)) {
      return false;
    }
    if (element.closest('[data-track="cta"]')) {
      return true;
    }
    if (
      element.closest("button, a, input, textarea, select, summary, [role='button'], [onclick], [tabindex]")
    ) {
      return true;
    }
    const style = window.getComputedStyle(element);
    return style.cursor === "pointer";
  }

  function getCurrentPageUrl() {
    return `${window.location.pathname}${window.location.search}${window.location.hash}`;
  }

  function getInsertEndpoint() {
    return `${config.supabaseUrl.replace(/\/+$/, "")}/rest/v1/analytics_events`;
  }

  function markInteractionActivity(_reason) {
    interactionActivityTick += 1;
  }

  function patchNetworkActivitySignals() {
    if (window.__instacloneAnalyticsNetworkPatched) {
      return;
    }
    window.__instacloneAnalyticsNetworkPatched = true;

    const rawFetch = window.fetch;
    if (typeof rawFetch === "function") {
      window.fetch = function patchedFetch(input, init) {
        const requestUrl = extractRequestUrl(input);
        const isAnalyticsSelfCall = isAnalyticsEndpointUrl(requestUrl);
        if (!isAnalyticsSelfCall) {
          markInteractionActivity("fetch_start");
        }
        return rawFetch(input, init)
          .then((response) => {
            if (!isAnalyticsSelfCall) {
              markInteractionActivity("fetch_done");
            }
            return response;
          })
          .catch((error) => {
            if (!isAnalyticsSelfCall) {
              markInteractionActivity("fetch_error");
            }
            throw error;
          });
      };
    }

    const rawXhrOpen = XMLHttpRequest.prototype.open;
    const rawXhrSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.open = function patchedXhrOpen(method, url) {
      this.__analyticsRequestUrl = url;
      return rawXhrOpen.apply(this, arguments);
    };
    XMLHttpRequest.prototype.send = function patchedXhrSend() {
      const requestUrl = extractRequestUrl(this.__analyticsRequestUrl);
      const isAnalyticsSelfCall = isAnalyticsEndpointUrl(requestUrl);
      if (!isAnalyticsSelfCall) {
        markInteractionActivity("xhr_start");
        this.addEventListener(
          "loadend",
          () => {
            markInteractionActivity("xhr_done");
          },
          { once: true },
        );
      }
      return rawXhrSend.apply(this, arguments);
    };
  }

  function extractRequestUrl(input) {
    if (!input) {
      return "";
    }
    if (typeof input === "string") {
      return input;
    }
    if (typeof input.url === "string") {
      return input.url;
    }
    return String(input);
  }

  function isAnalyticsEndpointUrl(url) {
    if (!url) {
      return false;
    }
    return String(url).includes("/rest/v1/analytics_events");
  }

  function isConfigured() {
    return Boolean(config.supabaseUrl) && Boolean(config.supabaseAnonKey);
  }

  function getDocumentHeight() {
    const bodyHeight = document.body ? document.body.scrollHeight : 0;
    const docHeight = document.documentElement ? document.documentElement.scrollHeight : 0;
    return Math.max(bodyHeight, docHeight, 1);
  }

  function getScrollDepthPercent() {
    const scrollTop = window.scrollY || document.documentElement.scrollTop || 0;
    const viewportHeight = window.innerHeight || document.documentElement.clientHeight || 0;
    const documentHeight = getDocumentHeight();
    if (documentHeight <= viewportHeight) {
      return 100;
    }
    const progress = ((scrollTop + viewportHeight) / documentHeight) * 100;
    return Math.max(0, Math.min(100, Math.round(progress)));
  }

  function loadOrCreateSession() {
    const now = Date.now();
    try {
      const raw = window.localStorage.getItem(SESSION_STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (
          parsed &&
          typeof parsed.id === "string" &&
          parsed.id.length > 8 &&
          typeof parsed.last_activity_at === "number" &&
          now - parsed.last_activity_at <= SESSION_TIMEOUT_MS
        ) {
          sessionId = parsed.id;
          sessionLastActivity = now;
          persistSession();
          return;
        }
      }
    } catch (error) {
      // ignore storage parse errors
    }

    sessionId = createSessionId();
    sessionLastActivity = now;
    persistSession();
  }

  function touchSession() {
    const now = Date.now();
    if (!sessionId || now - sessionLastActivity > SESSION_TIMEOUT_MS) {
      sessionId = createSessionId();
    }
    sessionLastActivity = now;
    persistSession();
  }

  function persistSession() {
    try {
      window.localStorage.setItem(
        SESSION_STORAGE_KEY,
        JSON.stringify({
          id: sessionId,
          last_activity_at: sessionLastActivity,
          expires_at: sessionLastActivity + SESSION_TIMEOUT_MS,
        }),
      );
    } catch (error) {
      // ignore storage errors
    }
  }

  function createSessionId() {
    const randomPart = Math.random().toString(36).slice(2, 10);
    return `sess_${Date.now().toString(36)}_${randomPart}`;
  }

  function sanitizeText(value, maxLength) {
    const text = String(value || "").replace(/\s+/g, " ").trim();
    if (!text) {
      return "";
    }
    return text.slice(0, maxLength || 120);
  }

  function normalizeObject(value) {
    if (!value) {
      return {};
    }
    if (typeof value === "string") {
      try {
        const parsed = JSON.parse(value);
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
          return parsed;
        }
      } catch (_error) {
        return {};
      }
      return {};
    }
    if (typeof value !== "object" || Array.isArray(value)) {
      return {};
    }
    return value;
  }

  function toNullableInt(value) {
    if (value === null || value === undefined || value === "") {
      return null;
    }
    const num = Number(value);
    if (!Number.isFinite(num)) {
      return null;
    }
    return Math.round(num);
  }

  function distanceSquared(x1, y1, x2, y2) {
    const dx = x1 - x2;
    const dy = y1 - y2;
    return dx * dx + dy * dy;
  }

  start();
})();
