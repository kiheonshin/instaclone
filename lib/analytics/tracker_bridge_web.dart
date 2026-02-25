// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:js' as js;

void init({required String supabaseUrl, required String supabaseAnonKey}) {
  try {
    if (js.context['analyticsTrackerInit'] == null) {
      return;
    }
    final config = <String, String>{
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
    };
    js.context.callMethod('analyticsTrackerInit', [config]);
  } catch (_) {
    // keep app startup resilient even if analytics script fails
  }
}

void trackCta(String ctaId, {Map<String, dynamic>? payload}) {
  try {
    if (js.context['analyticsTrackCta'] == null) {
      return;
    }
    final jsPayload = payload ?? const <String, dynamic>{};
    js.context.callMethod('analyticsTrackCta', [ctaId, jsPayload]);
  } catch (_) {
    // no-op
  }
}
