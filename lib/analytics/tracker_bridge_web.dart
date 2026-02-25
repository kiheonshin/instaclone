// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:js' as js;
import 'dart:convert';

void init({required String supabaseUrl, required String supabaseAnonKey}) {
  try {
    final pendingConfig = js.JsObject.jsify({
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
    });
    js.context['__instacloneAnalyticsInitConfig'] = pendingConfig;

    if (js.context['analyticsTrackerInit'] == null) {
      return;
    }
    // Pass primitive args to avoid Map interop ambiguity.
    js.context.callMethod('analyticsTrackerInit', [supabaseUrl, supabaseAnonKey]);
  } catch (_) {
    // keep app startup resilient even if analytics script fails
  }
}

void trackCta(String ctaId, {Map<String, dynamic>? payload}) {
  try {
    if (js.context['analyticsTrackCta'] == null) {
      return;
    }
    // Send payload as JSON string for stable interop.
    final payloadJson = jsonEncode(payload ?? const <String, dynamic>{});
    js.context.callMethod('analyticsTrackCta', [ctaId, payloadJson]);
  } catch (_) {
    // no-op
  }
}
