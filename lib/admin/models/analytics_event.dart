class AnalyticsEvent {
  const AnalyticsEvent({
    required this.id,
    required this.eventType,
    required this.pageUrl,
    required this.elementInfo,
    required this.sessionId,
    required this.createdAt,
    this.xPos,
    this.yPos,
    this.scrollDepth,
    this.userAgent,
    this.referrer,
  });

  final String id;
  final String eventType;
  final String pageUrl;
  final Map<String, dynamic> elementInfo;
  final int? xPos;
  final int? yPos;
  final int? scrollDepth;
  final String sessionId;
  final DateTime createdAt;
  final String? userAgent;
  final String? referrer;

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    final rawElementInfo = json['element_info'];
    final info = rawElementInfo is Map
        ? Map<String, dynamic>.from(rawElementInfo)
        : <String, dynamic>{};

    return AnalyticsEvent(
      id: json['id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      pageUrl: json['page_url'] as String? ?? '',
      elementInfo: info,
      xPos: _toInt(json['x_pos']),
      yPos: _toInt(json['y_pos']),
      scrollDepth: _toInt(json['scroll_depth']),
      sessionId: json['session_id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      userAgent: json['user_agent'] as String?,
      referrer: json['referrer'] as String?,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse(value.toString());
  }
}
