import 'tracker_bridge_stub.dart'
    if (dart.library.html) 'tracker_bridge_web.dart'
    as impl;

class AnalyticsTrackerBridge {
  const AnalyticsTrackerBridge._();

  static void init({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    impl.init(supabaseUrl: supabaseUrl, supabaseAnonKey: supabaseAnonKey);
  }

  static void trackCta(String ctaId, {Map<String, dynamic>? payload}) {
    impl.trackCta(ctaId, payload: payload);
  }
}
