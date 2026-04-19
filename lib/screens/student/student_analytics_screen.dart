import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';

class StudentAnalyticsScreen extends StatelessWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    final gradesByMonth = <int, List<double>>{};
    for (final g in data.grades) {
      final month = g.gradedAt.month;
      gradesByMonth.putIfAbsent(month, () => []).add(g.percentage);
    }

    final spots = gradesByMonth.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return FlSpot(e.key.toDouble(), avg);
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.analytics, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Үлгерім динамикасы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: SizedBox(
                height: 220,
                child: spots.length < 2
                    ? const Center(child: Text('Деректер жеткіліксіз'))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  const months = ['', 'Қ', 'А', 'Н', 'С', 'М', 'М', 'Ш', 'Т', 'Қ', 'Қ', 'Қ', 'Ж'];
                                  final i = v.toInt();
                                  if (i < 1 || i > 12) return const SizedBox();
                                  return Text(months[i], style: const TextStyle(fontSize: 11));
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: AppColors.accentBlue,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.accentBlue.withValues(alpha: 0.1),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.accentBlue,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          ],
                          minY: 0,
                          maxY: 100,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Row(
              children: [
                _SummaryCard(
                  label: AppStrings.averageScore,
                  value: '${data.averageGrade.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 14),
                _SummaryCard(
                  label: AppStrings.attendance,
                  value: '${data.attendanceRate.toStringAsFixed(0)}%',
                  icon: Icons.event_available_rounded,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _SummaryCard(
                  label: AppStrings.completionRate,
                  value: data.submissions.isNotEmpty && data.assignments.isNotEmpty
                      ? '${((data.submissions.length / data.assignments.length) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(width: 14),
                _SummaryCard(
                  label: AppStrings.missedAssignments,
                  value: '${data.missedAssignmentCount}',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
