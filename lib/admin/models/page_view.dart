class PageView {
  const PageView({
    required this.id,
    required this.sessionId,
    required this.pageUrl,
    required this.createdAt,
    this.referrer,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.deviceType,
    this.browser,
    this.screenWidth,
    this.durationSeconds,
  });

  final String id;
  final String sessionId;
  final String pageUrl;
  final String? referrer;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? deviceType;
  final String? browser;
  final int? screenWidth;
  final double? durationSeconds;
  final DateTime createdAt;

  factory PageView.fromJson(Map<String, dynamic> json) {
    return PageView(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      pageUrl: json['page_url'] as String? ?? '',
      referrer: json['referrer'] as String?,
      utmSource: json['utm_source'] as String?,
      utmMedium: json['utm_medium'] as String?,
      utmCampaign: json['utm_campaign'] as String?,
      deviceType: json['device_type'] as String?,
      browser: json['browser'] as String?,
      screenWidth: _toInt(json['screen_width']),
      durationSeconds: _toDouble(json['duration_seconds']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'page_url': pageUrl,
      'referrer': referrer,
      'utm_source': utmSource,
      'utm_medium': utmMedium,
      'utm_campaign': utmCampaign,
      'device_type': deviceType,
      'browser': browser,
      'screen_width': screenWidth,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Summary data for the 4 top cards on the analytics dashboard.
class VisitorSummary {
  const VisitorSummary({
    required this.todayCount,
    required this.yesterdayCount,
    required this.avgDurationSeconds,
    required this.bounceRate,
    required this.topPage,
    required this.topPageViews,
  });

  final int todayCount;
  final int yesterdayCount;
  final double avgDurationSeconds;
  final double bounceRate;
  final String topPage;
  final int topPageViews;

  double get changePercent {
    if (yesterdayCount == 0) {
      return todayCount > 0 ? 100.0 : 0.0;
    }
    return ((todayCount - yesterdayCount) / yesterdayCount) * 100;
  }
}

/// Average duration per page, used for the TOP 5 chart.
class PageDuration {
  const PageDuration({
    required this.pageUrl,
    required this.avgDurationSeconds,
    required this.viewCount,
  });

  final String pageUrl;
  final double avgDurationSeconds;
  final int viewCount;
}
