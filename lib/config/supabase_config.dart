/// Supabase 설정
/// 실제 배포 시에는 환경 변수나 --dart-define 사용 권장
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iyvercsvligervllxnjb.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5dmVyY3N2bGlnZXJ2bGx4bmpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MDk0MjMsImV4cCI6MjA4NjM4NTQyM30.6FSwdmk4NT2ujlZ4KqxgKHhpE2F9j7ZBrNujeXABO-o',
  );
}
