/// Flutter Web: window.location으로 URL 감지 ( hash 라우팅 대응 )
import 'dart:html' as html;

bool get isAdminSubdomain {
  try {
    final href = html.window.location.href.toLowerCase();
    final host = html.window.location.hostname.toLowerCase();
    final path = html.window.location.pathname.toLowerCase();
    final search = html.window.location.search;

    if (host.startsWith('admin.')) return true;
    if (host == 'admin.localhost') return true;
    if (path.startsWith('/admin') || path == '/admin') return true;
    if (search.contains('admin=1')) return true;
    if (href.contains('admin=1')) return true;

    return false;
  } catch (_) {
    return false;
  }
}
