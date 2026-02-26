import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/page_view.dart';
import '../providers/admin_providers.dart';

// ─── Color palette ───
const _kChartColors = [
  Color(0xFF137FEC), // primary blue
  Color(0xFF833AB4), // purple
  Color(0xFFE1306C), // pink
  Color(0xFFFD1D1D), // red
  Color(0xFFF77737), // orange
  Color(0xFFFCAF45), // amber
  Color(0xFF2ECC71), // green
  Color(0xFF1ABC9C), // teal
];

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFilter = ref.watch(visitorDateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('방문자 분석'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
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
          // Date filter chips
          ...AnalyticsDateFilter.values.map((f) {
            final selected = f == dateFilter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ChoiceChip(
                label: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
                selected: selected,
                selectedColor: Colors.white24,
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: theme.colorScheme.onPrimary.withOpacity(0.3),
                ),
                onSelected: (_) {
                  ref.read(visitorDateFilterProvider.notifier).state = f;
                },
              ),
            );
          }),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
            onPressed: () {
              ref.invalidate(visitorSummaryProvider);
              ref.invalidate(dailyVisitorTrendProvider);
              ref.invalidate(referrerDistributionProvider);
              ref.invalidate(deviceDistributionProvider);
              ref.invalidate(hourlyDistributionProvider);
              ref.invalidate(topPagesByDurationProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(visitorSummaryProvider);
          ref.invalidate(dailyVisitorTrendProvider);
          ref.invalidate(referrerDistributionProvider);
          ref.invalidate(deviceDistributionProvider);
          ref.invalidate(hourlyDistributionProvider);
          ref.invalidate(topPagesByDurationProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 720;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary Cards ──
                      _SummaryCardsSection(),
                      const SizedBox(height: 20),

                      // ── Wide: line chart + hourly side-by-side ──
                      if (wide) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(title: '일별 방문자 추이', subtitle: '최근 30일'),
                                  const SizedBox(height: 8),
                                  _DailyTrendChart(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(title: '시간대별 방문 분포', subtitle: '24시간'),
                                  const SizedBox(height: 8),
                                  _HourlyBarChart(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _SectionTitle(title: '일별 방문자 추이', subtitle: '최근 30일'),
                        const SizedBox(height: 8),
                        _DailyTrendChart(),
                        const SizedBox(height: 20),
                        _SectionTitle(title: '시간대별 방문 분포', subtitle: '24시간'),
                        const SizedBox(height: 8),
                        _HourlyBarChart(),
                      ],
                      const SizedBox(height: 20),

                      // ── Two-column: Referrer + Device ──
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _ReferrerPieSection()),
                            const SizedBox(width: 14),
                            Expanded(child: _DeviceDonutSection()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _ReferrerPieSection(),
                            const SizedBox(height: 20),
                            _DeviceDonutSection(),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // ── Top Pages by Duration ──
                      _SectionTitle(title: '페이지별 체류시간 TOP 5'),
                      const SizedBox(height: 8),
                      _TopPagesBarChart(),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Section Title
// ═══════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(subtitle!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Summary Cards (4 cards)
// ═══════════════════════════════════════════════

class _SummaryCardsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(visitorSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _ErrorCard(message: '요약 데이터 로드 실패: $e'),
      data: (summary) {
        final change = summary.changePercent;
        final changeText = change >= 0
            ? '+${change.toStringAsFixed(1)}%'
            : '${change.toStringAsFixed(1)}%';
        final changeColor = change >= 0 ? Colors.green : Colors.red;
        final changeIcon = change >= 0 ? Icons.trending_up : Icons.trending_down;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w > 800 ? 4 : w > 480 ? 2 : 1;
            final aspectRatio = w > 800 ? 2.0 : w > 480 ? 2.2 : 3.5;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: aspectRatio,
              children: [
                _SummaryCard(
                  icon: Icons.people_outline,
                  iconColor: _kChartColors[0],
                  label: '오늘 방문자',
                  value: '${summary.todayCount}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 14, color: changeColor),
                      const SizedBox(width: 2),
                      Text(changeText,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: changeColor)),
                    ],
                  ),
                ),
                _SummaryCard(
                  icon: Icons.timer_outlined,
                  iconColor: _kChartColors[1],
                  label: '평균 체류시간',
                  value: _formatDuration(summary.avgDurationSeconds),
                ),
                _SummaryCard(
                  icon: Icons.exit_to_app,
                  iconColor: _kChartColors[4],
                  label: '이탈률',
                  value: '${summary.bounceRate.toStringAsFixed(1)}%',
                ),
                _SummaryCard(
                  icon: Icons.star_outline,
                  iconColor: _kChartColors[6],
                  label: '인기 페이지',
                  value: _shortenUrl(summary.topPage),
                  trailing: Text(
                    '${summary.topPageViews} views',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (trailing != null) ...[
              const SizedBox(height: 2),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Daily Trend Line Chart (30 days)
// ═══════════════════════════════════════════════

class _DailyTrendChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(dailyVisitorTrendProvider);
    final theme = Theme.of(context);

    return trendAsync.when(
      loading: () =>
          const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorCard(message: '추이 데이터 로드 실패'),
      data: (data) {
        if (data.isEmpty) {
          return const SizedBox(height: 220, child: Center(child: Text('데이터 없음')));
        }

        final entries = data.entries.toList();
        final maxY = entries.map((e) => e.value).reduce(math.max).toDouble();
        final adjustedMaxY = maxY == 0 ? 10.0 : maxY * 1.2;

        final spots = <FlSpot>[];
        for (int i = 0; i < entries.length; i++) {
          spots.add(FlSpot(i.toDouble(), entries[i].value.toDouble()));
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: adjustedMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (adjustedMaxY / 4).ceilToDouble().clamp(1, double.infinity),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (entries.length / 6).ceilToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          final dateStr = entries[idx].key;
                          final parts = dateStr.split('-');
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${parts[1]}/${parts[2]}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: (adjustedMaxY / 4).ceilToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final idx = spot.x.toInt();
                          final dateStr =
                              idx >= 0 && idx < entries.length ? entries[idx].key : '';
                          return LineTooltipItem(
                            '$dateStr\n${spot.y.toInt()}명',
                            TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: _kChartColors[0],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 2.5,
                          color: _kChartColors[0],
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _kChartColors[0].withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  Referrer Pie Chart
// ═══════════════════════════════════════════════

class _ReferrerPieSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(referrerDistributionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: '유입 경로 비율'),
        const SizedBox(height: 12),
        dataAsync.when(
          loading: () =>
              const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => _ErrorCard(message: '유입 경로 로드 실패'),
          data: (data) {
            if (data.isEmpty) {
              return const SizedBox(height: 220, child: Center(child: Text('데이터 없음')));
            }
            return _PieChartCard(data: data, showCenterHole: false);
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Device Donut Chart
// ═══════════════════════════════════════════════

class _DeviceDonutSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(deviceDistributionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: '디바이스별 분류'),
        const SizedBox(height: 12),
        dataAsync.when(
          loading: () =>
              const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => _ErrorCard(message: '디바이스 데이터 로드 실패'),
          data: (data) {
            if (data.isEmpty) {
              return const SizedBox(height: 220, child: Center(child: Text('데이터 없음')));
            }
            return _PieChartCard(data: data, showCenterHole: true);
          },
        ),
      ],
    );
  }
}

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({required this.data, required this.showCenterHole});
  final Map<String, int> data;
  final bool showCenterHole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.values.fold(0, (a, b) => a + b);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final pct = total == 0 ? 0.0 : (entry.value / total) * 100;
      final color = _kChartColors[i % _kChartColors.length];
      sections.add(PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        radius: showCenterHole ? 40 : 48,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: showCenterHole ? 30 : 0,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (int i = 0; i < sortedEntries.length; i++)
                  _LegendItem(
                    color: _kChartColors[i % _kChartColors.length],
                    label: _capitalizeDevice(sortedEntries[i].key),
                    count: sortedEntries[i].value,
                    total: total,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });
  final Color color;
  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (count / total) * 100;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ${pct.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Hourly Bar Chart (24 hours)
// ═══════════════════════════════════════════════

class _HourlyBarChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(hourlyDistributionProvider);
    final theme = Theme.of(context);

    return dataAsync.when(
      loading: () =>
          const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorCard(message: '시간대 데이터 로드 실패'),
      data: (data) {
        final maxY = data.values.fold(0, (a, b) => math.max(a, b)).toDouble();
        final adjustedMaxY = maxY == 0 ? 10.0 : maxY * 1.2;

        final groups = <BarChartGroupData>[];
        for (int h = 0; h < 24; h++) {
          groups.add(BarChartGroupData(
            x: h,
            barRods: [
              BarChartRodData(
                toY: (data[h] ?? 0).toDouble(),
                color: _kChartColors[0],
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
            ],
          ));
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 14, 10),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: adjustedMaxY,
                  barGroups: groups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (adjustedMaxY / 4).ceilToDouble().clamp(1, double.infinity),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        getTitlesWidget: (value, _) {
                          final h = value.toInt();
                          if (h < 0 || h > 23 || h % 3 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${h}시',
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: (adjustedMaxY / 4).ceilToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gIdx, rod, rIdx) =>
                          BarTooltipItem(
                        '${group.x}시\n${rod.toY.toInt()}건',
                        TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  Top Pages by Duration (Horizontal Bar)
// ═══════════════════════════════════════════════

class _TopPagesBarChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(topPagesByDurationProvider);
    final theme = Theme.of(context);

    return dataAsync.when(
      loading: () =>
          const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorCard(message: '체류시간 데이터 로드 실패'),
      data: (pages) {
        if (pages.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: Text('데이터 없음')));
        }

        final maxDuration =
            pages.map((p) => p.avgDurationSeconds).reduce(math.max);
        final adjustedMax = maxDuration == 0 ? 60.0 : maxDuration * 1.2;

        // Reversed so the longest is at top
        final reversed = pages.reversed.toList();
        final groups = <BarChartGroupData>[];
        for (int i = 0; i < reversed.length; i++) {
          groups.add(BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: reversed[i].avgDurationSeconds,
                color: _kChartColors[i % _kChartColors.length],
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
            ],
          ));
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 14, 10),
            child: SizedBox(
              height: math.max(160, pages.length * 44.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: BarChart(
                  BarChartData(
                    maxY: adjustedMax,
                    barGroups: groups,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (adjustedMax / 4).ceilToDouble().clamp(1, double.infinity),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.dividerColor.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= reversed.length) {
                              return const SizedBox.shrink();
                            }
                            return RotatedBox(
                              quarterTurns: -1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  _shortenUrl(reversed[idx].pageUrl),
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (adjustedMax / 4).ceilToDouble().clamp(1, double.infinity),
                          getTitlesWidget: (value, _) => RotatedBox(
                            quarterTurns: -1,
                            child: Text(
                              _formatDuration(value),
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, gIdx, rod, rIdx) {
                          final idx = group.x;
                          final page = idx >= 0 && idx < reversed.length
                              ? reversed[idx].pageUrl
                              : '';
                          return BarTooltipItem(
                            '$page\n${_formatDuration(rod.toY)}',
                            TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  Error Card
// ═══════════════════════════════════════════════

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════

String _formatDuration(double seconds) {
  if (seconds < 60) {
    return '${seconds.toStringAsFixed(0)}초';
  }
  final m = (seconds / 60).floor();
  final s = (seconds % 60).round();
  return '${m}분 ${s.toString().padLeft(2, '0')}초';
}

String _shortenUrl(String url) {
  if (url.length <= 20) return url;
  // Remove query params for display
  final qIdx = url.indexOf('?');
  final clean = qIdx > 0 ? url.substring(0, qIdx) : url;
  if (clean.length <= 20) return clean;
  return '${clean.substring(0, 18)}...';
}

String _capitalizeDevice(String raw) {
  if (raw.isEmpty) return 'Unknown';
  return raw[0].toUpperCase() + raw.substring(1);
}
