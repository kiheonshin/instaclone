import 'dart:html' as html;

/// Web: 전체 도메인 + /admin/login (예: https://instaclone.vercel.app/admin/login)
String get adminLoginFullUrl {
  final origin = html.window.location.origin;
  return '$origin/admin/login';
}
