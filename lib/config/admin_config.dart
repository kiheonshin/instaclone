/// 관리자 서브도메인 감지
/// - Web: window.location 사용 (hash 라우팅 대응)
/// - 기타: false
import 'admin_config_stub.dart'
    if (dart.library.html) 'admin_config_web.dart' as _impl;

bool get isAdminSubdomain => _impl.isAdminSubdomain;
