import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/loading_widget.dart';
import 'verify_donor_screen.dart';
import 'donor_list_screen.dart';
import 'stock_screen.dart';
import 'emergency_requests_list_screen.dart';
import 'analytics_screen.dart';
import '../auth/login_screen.dart';

/// Admin Dashboard Portal layout with Desktop Sidebar & Live Analytics Overview.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  UserProfile? _adminProfile;
  AnalyticsData? _analyticsData;
  bool _isLoading = true;

  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();

  final List<SidebarItem> _sidebarItems = const [
    SidebarItem(title: 'Dashboard', icon: Icons.dashboard_outlined, index: 0),
    SidebarItem(title: 'Verify Donors', icon: Icons.verified_user_outlined, index: 1),
    SidebarItem(title: 'Donor Registry', icon: Icons.people_outline_rounded, index: 2),
    SidebarItem(title: 'Blood Stock', icon: Icons.invert_colors_outlined, index: 3),
    SidebarItem(title: 'Emergency Requests', icon: Icons.warning_amber_rounded, index: 4),
    SidebarItem(title: 'Analytics', icon: Icons.bar_chart_rounded, index: 5),
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final prof = await _authService.getCurrentProfile();
      final stats = await _analyticsService.getAnalyticsSummary();
      setState(() {
        _adminProfile = prof;
        _analyticsData = stats;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final List<Widget> subScreens = [
      _buildDashboardHome(),
      VerifyDonorScreen(onDataChanged: _loadAdminData),
      DonorListScreen(onDataChanged: _loadAdminData),
      const StockScreen(),
      EmergencyRequestsListScreen(onDataChanged: _loadAdminData),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(_sidebarItems[_selectedIndex].title),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: DashboardSidebar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (idx) {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = idx);
                },
                profile: _adminProfile,
                onLogout: _handleLogout,
                onToggleTheme: () => themeNotifier.toggleTheme(),
                isDarkMode: themeNotifier.isDarkMode,
                items: _sidebarItems,
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            DashboardSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              profile: _adminProfile,
              onLogout: _handleLogout,
              onToggleTheme: () => themeNotifier.toggleTheme(),
              isDarkMode: themeNotifier.isDarkMode,
              items: _sidebarItems,
            ),
          Expanded(child: subScreens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildDashboardHome() {
    if (_isLoading || _analyticsData == null) {
      return const LoadingWidget(message: 'Loading live admin metrics...');
    }

    final data = _analyticsData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Greeting Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_adminProfile?.name ?? 'Administrator'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Here's what's happening with HemoConnect platform today.",
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                tooltip: 'Refresh Metrics',
                onPressed: _loadAdminData,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mini Statistics Grid (Total Donors, Approved, Pending, Emergency)
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Total Donors',
                    value: '${data.totalDonors}',
                    icon: Icons.people_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.accent.withOpacity(0.3),
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  StatCard(
                    title: 'Approved Donors',
                    value: '${data.approvedDonors}',
                    icon: Icons.verified_rounded,
                    iconColor: AppColors.success,
                    iconBgColor: AppColors.successBg,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                  StatCard(
                    title: 'Pending Verifications',
                    value: '${data.pendingDonors}',
                    icon: Icons.hourglass_empty_rounded,
                    iconColor: AppColors.warning,
                    iconBgColor: AppColors.warningBg,
                    trendText: '${data.pendingDonors} Action Needed',
                    isTrendPositive: false,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  StatCard(
                    title: 'Emergency Requests',
                    value: '${data.totalEmergencyRequests}',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.danger,
                    iconBgColor: AppColors.dangerBg,
                    onTap: () => setState(() => _selectedIndex = 4),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Visual Analytics Overview Section with fl_chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood Group Inventory Distribution Bar Chart
              Expanded(
                flex: 3,
                child: PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blood Group Stock Distribution',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Approved donor counts per blood group',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 220,
                        child: _buildBloodDistributionBarChart(data.bloodGroupDistribution),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Donor Verification Status Pie Chart
              Expanded(
                flex: 2,
                child: PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Donor Verification Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Approved vs Pending vs Rejected',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: _buildStatusPieChart(
                          approved: data.approvedDonors,
                          pending: data.pendingDonors,
                          rejected: data.rejectedDonors,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloodDistributionBarChart(Map<String, int> dist) {
    final groups = dist.keys.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (dist.values.fold(0, (max, v) => v > max ? v : max) + 5).toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < groups.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      groups[idx],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  );
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
        barGroups: List.generate(groups.length, (index) {
          final group = groups[index];
          final count = dist[group] ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                gradient: AppColors.primaryGradient,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusPieChart({
    required int approved,
    required int pending,
    required int rejected,
  }) {
    final total = approved + pending + rejected;
    if (total == 0) {
      return const Center(child: Text('No donor verification records yet'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: AppColors.success,
            value: approved.toDouble(),
            title: '$approved',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: AppColors.warning,
            value: pending.toDouble(),
            title: '$pending',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: AppColors.danger,
            value: rejected.toDouble(),
            title: '$rejected',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
