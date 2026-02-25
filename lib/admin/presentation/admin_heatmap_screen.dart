import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/analytics_event.dart';
import '../providers/admin_providers.dart';

class AdminHeatmapScreen extends ConsumerStatefulWidget {
  const AdminHeatmapScreen({super.key});

  @override
  ConsumerState<AdminHeatmapScreen> createState() => _AdminHeatmapScreenState();
}

class _AdminHeatmapScreenState extends ConsumerState<AdminHeatmapScreen> {
  Timer? _replayTimer;
  String? _selectedSessionId;
  int _replayIndex = 0;
  bool _isReplayPlaying = false;

  @override
  void dispose() {
    _replayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFilter = ref.watch(analyticsDateFilterProvider);
    final selectedPage = ref.watch(analyticsSelectedPageProvider);
    final pagesAsync = ref.watch(adminAnalyticsPagesProvider);
    final eventsAsync = ref.watch(adminAnalyticsEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heatmap Analytics'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
            onPressed: () {
              ref.invalidate(adminAnalyticsPagesProvider);
              ref.invalidate(adminAnalyticsEventsProvider);
            },
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
        error: (error, _) => Center(child: Text('분석 데이터를 불러오지 못했습니다: $error')),
        data: (events) {
          final clickEvents = events
              .where(
                (event) =>
                    event.eventType == 'click' ||
                    event.eventType == 'cta_click' ||
                    event.eventType == 'rage_click' ||
                    event.eventType == 'dead_click',
              )
              .toList();
          final rageEvents =
              events.where((event) => event.eventType == 'rage_click').toList();
          final dwellEvents =
              events.where((event) => event.eventType == 'page_dwell').toList();
          final uniqueSessions = events
              .map((event) => event.sessionId)
              .where((sessionId) => sessionId.isNotEmpty)
              .toSet();

          final averageDwellMs = dwellEvents.isEmpty
              ? 0.0
              : dwellEvents
                      .map(
                        (event) =>
                            _toDouble(event.elementInfo['duration_ms']) ?? 0.0,
                      )
                      .fold<double>(0.0, (sum, value) => sum + value) /
                  dwellEvents.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FilterCard(
                  dateFilter: dateFilter,
                  selectedPage: selectedPage,
                  pagesAsync: pagesAsync,
                  onDateFilterChanged: (next) {
                    ref.read(analyticsDateFilterProvider.notifier).state = next;
                  },
                  onPageChanged: (nextPage) {
                    ref.read(analyticsSelectedPageProvider.notifier).state =
                        nextPage;
                  },
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  cards: [
                    _SummaryCardData(
                      title: '클릭 이벤트',
                      value: '${clickEvents.length}',
                      subtitle: 'CTA / Rage / Dead 포함',
                      icon: Icons.ads_click,
                    ),
                    _SummaryCardData(
                      title: '세션 수',
                      value: '${uniqueSessions.length}',
                      subtitle: '고유 session_id 기준',
                      icon: Icons.groups_outlined,
                    ),
                    _SummaryCardData(
                      title: '평균 체류',
                      value: _formatDurationMs(averageDwellMs),
                      subtitle: 'page_dwell 평균',
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '페이지 클릭 히트맵',
                  subtitle: '클릭 밀집도 시각화 (canvas)',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        child: CustomPaint(
                          painter: _HeatmapPainter(
                            events: clickEvents,
                            theme: theme,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '스크롤 깊이 분포',
                  subtitle: '25/50/75/100% 도달 비율',
                  child: _ScrollDepthChart(
                    events: events,
                    totalSessions: math.max(uniqueSessions.length, 1),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Rage Click 발생 지점',
                  subtitle: '500ms 내 동일 위치 3회 이상 클릭',
                  child: _RageClickList(events: rageEvents),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '세션 리플레이',
                  subtitle: 'session_id 기준 이벤트 재생',
                  child: _buildSessionReplay(events),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionReplay(List<AnalyticsEvent> events) {
    final theme = Theme.of(context);
    final sessionMap = _groupEventsBySession(events);

    final sessionItems = sessionMap.entries
        .map(
          (entry) => _SessionItem(
            sessionId: entry.key,
            events: entry.value,
            lastSeenAt: entry.value.last.createdAt,
          ),
        )
        .toList()
      ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));

    if (sessionItems.isEmpty) {
      return Text('해당 조건에 세션 데이터가 없습니다.', style: theme.textTheme.bodyMedium);
    }

    if (_selectedSessionId == null ||
        !sessionMap.containsKey(_selectedSessionId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedSessionId = sessionItems.first.sessionId;
          _replayIndex = 0;
          _isReplayPlaying = false;
        });
      });
    }

    final activeSessionId = (_selectedSessionId != null &&
            sessionMap.containsKey(_selectedSessionId))
        ? _selectedSessionId!
        : sessionItems.first.sessionId;
    final sessionEvents = sessionMap[activeSessionId]!;
    final maxIndex = math.max(sessionEvents.length - 1, 0);
    final clampedIndex = _replayIndex.clamp(0, maxIndex);
    final currentEvent = sessionEvents[clampedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(activeSessionId),
          initialValue: activeSessionId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '세션 선택'),
          items: sessionItems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.sessionId,
                  child: Text(
                    '${item.sessionId} · ${_formatDateTime(item.lastSeenAt)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (nextSession) {
            if (nextSession == null) {
              return;
            }
            _pauseReplay();
            setState(() {
              _selectedSessionId = nextSession;
              _replayIndex = 0;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _isReplayPlaying
                  ? () => _pauseReplay()
                  : () => _startReplay(sessionEvents),
              icon: Icon(_isReplayPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isReplayPlaying ? '일시정지' : '재생'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                _pauseReplay();
                setState(() => _replayIndex = 0);
              },
              icon: const Icon(Icons.replay),
              label: const Text('처음으로'),
            ),
            const Spacer(),
            Text('이벤트 ${clampedIndex + 1} / ${sessionEvents.length}'),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: clampedIndex.toDouble(),
          min: 0,
          max: maxIndex.toDouble(),
          onChanged: (nextIndex) {
            _pauseReplay();
            setState(() => _replayIndex = nextIndex.round());
          },
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              child: CustomPaint(
                painter: _SessionReplayPainter(
                  events: sessionEvents,
                  currentIndex: clampedIndex,
                  theme: theme,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '[${currentEvent.eventType}] ${_formatDateTime(currentEvent.createdAt)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text('page: ${currentEvent.pageUrl}', style: theme.textTheme.bodySmall),
      ],
    );
  }

  Map<String, List<AnalyticsEvent>> _groupEventsBySession(
    List<AnalyticsEvent> events,
  ) {
    final sortedEvents = [...events]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final sessionMap = <String, List<AnalyticsEvent>>{};
    for (final event in sortedEvents) {
      if (event.sessionId.isEmpty) {
        continue;
      }
      sessionMap
          .putIfAbsent(event.sessionId, () => <AnalyticsEvent>[])
          .add(event);
    }
    return sessionMap;
  }

  void _startReplay(List<AnalyticsEvent> events) {
    if (events.length <= 1) {
      return;
    }

    _replayTimer?.cancel();
    setState(() {
      if (_replayIndex >= events.length - 1) {
        _replayIndex = 0;
      }
      _isReplayPlaying = true;
    });
    _replayTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_replayIndex >= events.length - 1) {
          _isReplayPlaying = false;
          timer.cancel();
          return;
        }
        _replayIndex += 1;
      });
    });
  }

  void _pauseReplay() {
    _replayTimer?.cancel();
    if (_isReplayPlaying && mounted) {
      setState(() => _isReplayPlaying = false);
    }
  }
}

class _FilterCard extends ConsumerWidget {
  const _FilterCard({
    required this.dateFilter,
    required this.selectedPage,
    required this.pagesAsync,
    required this.onDateFilterChanged,
    required this.onPageChanged,
  });

  final AnalyticsDateFilter dateFilter;
  final String? selectedPage;
  final AsyncValue<List<String>> pagesAsync;
  final ValueChanged<AnalyticsDateFilter> onDateFilterChanged;
  final ValueChanged<String?> onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '필터',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AnalyticsDateFilter.values
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value.label),
                      selected: dateFilter == value,
                      onSelected: (_) => onDateFilterChanged(value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            pagesAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 4),
              error: (error, _) => Text('페이지 목록 로드 실패: $error'),
              data: (pages) {
                final hasSelected =
                    selectedPage == null || pages.contains(selectedPage);
                final dropdownValue = hasSelected ? selectedPage : null;
                if (!hasSelected) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onPageChanged(null);
                  });
                }
                return DropdownButtonFormField<String?>(
                  key: ValueKey(dropdownValue ?? '__all__'),
                  initialValue: dropdownValue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '페이지'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('전체 페이지'),
                    ),
                    ...pages.map(
                      (pageUrl) => DropdownMenuItem<String?>(
                        value: pageUrl,
                        child: Text(pageUrl, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onPageChanged,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.cards});

  final List<_SummaryCardData> cards;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map(
            (card) => SizedBox(
              width: 280,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 22, child: Icon(card.icon)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              card.subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScrollDepthChart extends StatelessWidget {
  const _ScrollDepthChart({required this.events, required this.totalSessions});

  final List<AnalyticsEvent> events;
  final int totalSessions;

  @override
  Widget build(BuildContext context) {
    final sessionBuckets = <int, Set<String>>{
      25: <String>{},
      50: <String>{},
      75: <String>{},
      100: <String>{},
    };

    for (final event in events) {
      if (event.eventType != 'scroll_depth') {
        continue;
      }
      final depth = event.scrollDepth;
      final sessionId = event.sessionId;
      if (depth == null ||
          !sessionBuckets.containsKey(depth) ||
          sessionId.isEmpty) {
        continue;
      }
      sessionBuckets[depth]!.add(sessionId);
    }

    return Column(
      children: sessionBuckets.entries.map((entry) {
        final count = entry.value.length;
        final ratio = count / totalSessions;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text('${entry.key}%')),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: ratio.clamp(0, 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Text(
                  '$count (${(ratio * 100).toStringAsFixed(0)}%)',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RageClickList extends StatelessWidget {
  const _RageClickList({required this.events});

  final List<AnalyticsEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text('Rage Click 이벤트가 없습니다.');
    }

    final visibleEvents = events.take(20).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleEvents.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = visibleEvents[index];
        final textPreview =
            (event.elementInfo['text_preview'] as String?) ?? '';
        final selector = (event.elementInfo['selector'] as String?) ?? '';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(radius: 16, child: Text('${index + 1}')),
          title: Text(event.pageUrl),
          subtitle: Text(
            '${_formatDateTime(event.createdAt)} · (${event.xPos ?? '-'}, ${event.yPos ?? '-'})\n$selector $textPreview',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({required this.events, required this.theme});

  final List<AnalyticsEvent> events;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    for (int i = 1; i < 5; i += 1) {
      final dx = (size.width / 5) * i;
      final dy = (size.height / 5) * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final points = events
        .map((event) => _toPlotPoint(event, size))
        .whereType<_PlotPoint>()
        .toList();

    for (final point in points) {
      final radius = 14 + (24 * point.intensity);
      final shaderPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            point.color.withValues(alpha: 0.38),
            point.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: point.offset, radius: radius));
      canvas.drawCircle(point.offset, radius, shaderPaint);
      canvas.drawCircle(
        point.offset,
        2.2 + point.intensity,
        Paint()..color = point.color.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.events != events || oldDelegate.theme != theme;
  }
}

class _SessionReplayPainter extends CustomPainter {
  const _SessionReplayPainter({
    required this.events,
    required this.currentIndex,
    required this.theme,
  });

  final List<AnalyticsEvent> events;
  final int currentIndex;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final frameEvents = events.take(currentIndex + 1).toList();
    final borderPaint = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      borderPaint,
    );

    final clickEvents = frameEvents
        .where(
          (event) =>
              event.eventType == 'click' ||
              event.eventType == 'cta_click' ||
              event.eventType == 'rage_click' ||
              event.eventType == 'dead_click',
        )
        .toList();

    for (int i = 0; i < clickEvents.length; i += 1) {
      final point = _toPlotPoint(clickEvents[i], size);
      if (point == null) {
        continue;
      }
      final isCurrent = clickEvents[i] == frameEvents.last;
      final dotPaint = Paint()
        ..color = point.color.withValues(alpha: isCurrent ? 0.95 : 0.65)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point.offset, isCurrent ? 5 : 3.2, dotPaint);
      if (isCurrent) {
        canvas.drawCircle(
          point.offset,
          14,
          Paint()
            ..color = point.color.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    double latestDepth = 0;
    for (final event in frameEvents) {
      if (event.eventType == 'scroll_depth' && event.scrollDepth != null) {
        latestDepth = math.max(latestDepth, event.scrollDepth!.toDouble());
      }
    }

    final barRect = Rect.fromLTWH(size.width - 16, 10, 6, size.height - 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
      Paint()..color = theme.colorScheme.outline.withValues(alpha: 0.22),
    );
    final depthY = barRect.bottom - (latestDepth / 100) * barRect.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barRect.left - 2, depthY - 4, barRect.width + 4, 8),
        const Radius.circular(4),
      ),
      Paint()..color = theme.colorScheme.primary,
    );
  }

  @override
  bool shouldRepaint(covariant _SessionReplayPainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.theme != theme;
  }
}

class _PlotPoint {
  const _PlotPoint({
    required this.offset,
    required this.intensity,
    required this.color,
  });

  final Offset offset;
  final double intensity;
  final Color color;
}

class _SessionItem {
  const _SessionItem({
    required this.sessionId,
    required this.events,
    required this.lastSeenAt,
  });

  final String sessionId;
  final List<AnalyticsEvent> events;
  final DateTime lastSeenAt;
}

_PlotPoint? _toPlotPoint(AnalyticsEvent event, Size canvasSize) {
  if (event.xPos == null || event.yPos == null) {
    return null;
  }

  final rawX = event.xPos!.toDouble();
  final rawY = event.yPos!.toDouble();
  final viewportW = _toDouble(event.elementInfo['viewport_w']);
  final viewportH = _toDouble(event.elementInfo['viewport_h']);

  final dx = (viewportW != null && viewportW > 0)
      ? (rawX / viewportW) * canvasSize.width
      : rawX.clamp(0, canvasSize.width).toDouble();
  final dy = (viewportH != null && viewportH > 0)
      ? (rawY / viewportH) * canvasSize.height
      : rawY.clamp(0, canvasSize.height).toDouble();

  final pointColor = switch (event.eventType) {
    'rage_click' => const Color(0xFFE53935),
    'dead_click' => const Color(0xFFFFA000),
    'cta_click' => const Color(0xFF1E88E5),
    _ => const Color(0xFFFF7043),
  };

  final intensity = switch (event.eventType) {
    'rage_click' => 1.0,
    'dead_click' => 0.8,
    'cta_click' => 0.72,
    _ => 0.56,
  };

  return _PlotPoint(
    offset: Offset(dx, dy),
    intensity: intensity,
    color: pointColor,
  );
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  final ss = local.second.toString().padLeft(2, '0');
  return '$mm/$dd $hh:$min:$ss';
}

String _formatDurationMs(double ms) {
  if (ms <= 0) {
    return '0s';
  }
  final seconds = ms / 1000;
  if (seconds < 60) {
    return '${seconds.toStringAsFixed(1)}s';
  }
  final minutes = seconds ~/ 60;
  final remain = (seconds % 60).round();
  return '${minutes}m ${remain}s';
}
