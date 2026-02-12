/// 관리자 로그인 전체 URL
/// - Web: https://도메인/admin/login
/// - 기타: /admin/login
import 'app_url_stub.dart' if (dart.library.html) 'app_url_web.dart' as _url;

String get adminLoginFullUrl => _url.adminLoginFullUrl;
