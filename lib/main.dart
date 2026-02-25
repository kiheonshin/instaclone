import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'config/supabase_config.dart';
import 'analytics/tracker_bridge.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('ko', timeago.KoMessages());

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  AnalyticsTrackerBridge.init(
    supabaseUrl: SupabaseConfig.url,
    supabaseAnonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: InstaCloneApp()));
}
