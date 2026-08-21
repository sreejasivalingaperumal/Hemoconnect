import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../services/analytics_service.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/loading_widget.dart';

/// Full Platform Analytics Dashboard with interactive fl_charts powered by real Supabase metrics.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await _analyticsService.getAnalyticsSummary();
      if (mounted) setState(() => _data = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Health Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading || _data == null
          ? const LoadingWidget(message: 'Generating real-time visual charts...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              'Total Registered Users',
                              '${_data!.totalProfiles}',
                              Icons.people_alt_rounded,
                              AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildMetricTile(
                              'Total Donors Submitted',
                              '${_data!.totalDonors}',
                              Icons.water_drop_rounded,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildMetricTile(
                              'Emergency Requests',
                              '${_data!.totalEmergencyRequests}',
                              Icons.emergency_rounded,
                              AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Chart 1: Blood Group Distribution Bar Chart
                      PremiumCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Blood Group Inventory Distribution',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Distribution of verified donors across all 8 blood groups',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 260,
                              child: _buildBloodDistributionChart(_data!.bloodGroupDistribution),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Side-by-side Donut Charts: Donor Verification vs Emergency Request Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PremiumCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Donor Approval Ratio',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 220,
                                    child: _buildDonorStatusPieChart(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: PremiumCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Emergency Request Status',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 220,
                                    child: _buildEmergencyStatusPieChart(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloodDistributionChart(Map<String, int> dist) {
    final keys = dist.keys.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (dist.values.fold(0, (max, v) => v > max ? v : max) + 5).toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < keys.length) {
                  return Text(keys[idx], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(keys.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (dist[keys[i]] ?? 0).toDouble(),
                gradient: AppColors.primaryGradient,
                width: 20,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDonorStatusPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 36,
        sections: [
          PieChartSectionData(
            color: AppColors.success,
            value: _data!.approvedDonors.toDouble(),
            title: '${_data!.approvedDonors}',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: AppColors.warning,
            value: _data!.pendingDonors.toDouble(),
            title: '${_data!.pendingDonors}',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: AppColors.danger,
            value: _data!.rejectedDonors.toDouble(),
            title: '${_data!.rejectedDonors}',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStatusPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 36,
        sections: [
          PieChartSectionData(
            color: AppColors.warning,
            value: _data!.pendingEmergencyRequests.toDouble(),
            title: '${_data!.pendingEmergencyRequests}',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: AppColors.info,
            value: _data!.processingEmergencyRequests.toDouble(),
            title: '${_data!.processingEmergencyRequests}',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: AppColors.success,
            value: _data!.completedEmergencyRequests.toDouble(),
            title: '${_data!.completedEmergencyRequests}',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
