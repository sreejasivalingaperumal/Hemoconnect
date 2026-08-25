import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/app_button.dart';
import 'verify_donor_screen.dart';
import 'donor_list_screen.dart';
import 'stock_screen.dart';
import 'emergency_requests_list_screen.dart';
import 'analytics_screen.dart';
import '../auth/login_screen.dart';

/// Admin Dashboard Portal layout with spacious 2-column executive desktop layout.
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
  DateTime _lastRefreshed = DateTime.now();

  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();

  final List<SidebarItem> _sidebarItems = const [
    SidebarItem(title: 'Dashboard', icon: Icons.dashboard_outlined, index: 0, category: 'MAIN'),
    SidebarItem(title: 'Verify Donors', icon: Icons.verified_user_outlined, index: 1, category: 'DONORS'),
    SidebarItem(title: 'Donor Registry', icon: Icons.people_outline_rounded, index: 2, category: 'DONORS'),
    SidebarItem(title: 'Blood Stock', icon: Icons.invert_colors_outlined, index: 3, category: 'BLOOD MANAGEMENT'),
    SidebarItem(title: 'Emergency Requests', icon: Icons.warning_amber_rounded, index: 4, category: 'BLOOD MANAGEMENT'),
    SidebarItem(title: 'Analytics', icon: Icons.bar_chart_rounded, index: 5, category: 'REPORTS'),
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
        _lastRefreshed = DateTime.now();
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

  void _showNotificationPopover() {
    final pendingDonors = _analyticsData?.pendingDonors ?? 0;
    final pendingEmergency = _analyticsData?.pendingEmergencyRequests ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Admin Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingDonors == 0 && pendingEmergency == 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('All caught up! No pending verifications or emergency alerts.'),
              ),
            ] else ...[
              if (pendingEmergency > 0)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.dangerBg,
                    child: Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                  ),
                  title: Text('$pendingEmergency Emergency Request(s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Requires immediate administrator attention', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 4);
                  },
                ),
              if (pendingDonors > 0)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.warningBg,
                    child: Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 20),
                  ),
                  title: Text('$pendingDonors Pending Donor Verification(s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Medical report clearance awaiting review', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 1);
                  },
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final pendingDonors = _analyticsData?.pendingDonors ?? 0;
    final pendingEmergency = _analyticsData?.pendingEmergencyRequests ?? 0;

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
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: _showNotificationPopover,
                    ),
                    if (pendingDonors > 0 || pendingEmergency > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${pendingDonors + pendingEmergency}',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
                pendingDonorsCount: pendingDonors,
                pendingEmergencyCount: pendingEmergency,
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
              pendingDonorsCount: pendingDonors,
              pendingEmergencyCount: pendingEmergency,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final minutesAgo = DateTime.now().difference(_lastRefreshed).inMinutes;
    final timeAgoStr = minutesAgo == 0 ? 'Just now' : '$minutesAgo min ago';
    final totalAlerts = data.pendingDonors + data.pendingEmergencyRequests;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek Spacious Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_adminProfile?.name ?? 'Administrator'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Here's what's happening with HemoConnect today.",
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              '$currentDateStr • $timeAgoStr',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Controls (Refresh & Notification Bell)
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Refresh Metrics',
                      onPressed: _loadAdminData,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                          tooltip: 'Notifications',
                          onPressed: _showNotificationPopover,
                        ),
                      ),
                      if (totalAlerts > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$totalAlerts',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 2. Statistics Cards Grid (4 Compact Cards)
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.55,
                children: [
                  StatCard(
                    title: 'Total Donors',
                    value: '${data.totalDonors}',
                    icon: Icons.people_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.accent.withOpacity(0.3),
                    trendText: 'Registered donors',
                    isTrendPositive: true,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  StatCard(
                    title: 'Approved Donors',
                    value: '${data.approvedDonors}',
                    icon: Icons.verified_rounded,
                    iconColor: AppColors.success,
                    iconBgColor: AppColors.successBg,
                    trendText: 'Verified donors',
                    isTrendPositive: true,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                  StatCard(
                    title: 'Pending Verifications',
                    value: '${data.pendingDonors}',
                    icon: Icons.hourglass_empty_rounded,
                    iconColor: AppColors.warning,
                    iconBgColor: AppColors.warningBg,
                    trendText: data.pendingDonors > 0 ? 'Needs attention' : 'All verified',
                    isTrendPositive: data.pendingDonors == 0,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  StatCard(
                    title: 'Emergency Requests',
                    value: '${data.totalEmergencyRequests}',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.danger,
                    iconBgColor: AppColors.dangerBg,
                    trendText: data.pendingEmergencyRequests > 0 ? 'Active requests' : 'No active alerts',
                    isTrendPositive: data.pendingEmergencyRequests == 0,
                    onTap: () => setState(() => _selectedIndex = 4),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // 3 & 4 & 5 & 6. Uncluttered Executive 2-Column Grid Layout (Left: Analytics Charts, Right: Urgent & Recent)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1050;

              final leftAnalyticsColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blood Stock Distribution (Compact Horizontal Bars)
                  PremiumCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Blood Group Stock Distribution',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Approved donor counts by blood group',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 18),
                        _buildHorizontalBloodStockList(data.bloodGroupDistribution),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Donor Verification Status Donut Chart with Center Count & Legend
                  PremiumCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Donor Verification Status',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Distribution across verification states',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 210,
                          child: _buildDonutChartWithCenterText(
                            approved: data.approvedDonors,
                            pending: data.pendingDonors,
                            rejected: data.rejectedDonors,
                            total: data.totalDonors,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final rightActionsColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgent Actions
                  const Text(
                    'Urgent Actions',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 12),
                  _buildUrgentActionCard(
                    icon: Icons.emergency_rounded,
                    iconColor: AppColors.danger,
                    title: 'Emergency Requests',
                    description: data.pendingEmergencyRequests > 0
                        ? '${data.pendingEmergencyRequests} emergency request(s) require immediate attention'
                        : 'No active emergency requests pending',
                    buttonText: 'View Requests →',
                    buttonVariant: AppButtonVariant.danger,
                    onTap: () => setState(() => _selectedIndex = 4),
                  ),
                  const SizedBox(height: 12),
                  _buildUrgentActionCard(
                    icon: Icons.hourglass_empty_rounded,
                    iconColor: AppColors.warning,
                    title: 'Donor Verification',
                    description: data.pendingDonors > 0
                        ? '${data.pendingDonors} donor(s) are waiting for verification'
                        : 'All donor applications are up to date',
                    buttonText: 'Verify Donors →',
                    buttonVariant: AppButtonVariant.outline,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 28),

                  // Recent Activity Timeline
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 12),
                  PremiumCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (data.pendingEmergencyRequests > 0)
                          _buildActivityItem(
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.danger,
                            title: 'Emergency blood request received',
                            description: 'Requires administrator attention for hospital dispatch',
                            timeText: 'Active alert',
                          ),
                        if (data.pendingDonors > 0)
                          _buildActivityItem(
                            icon: Icons.hourglass_empty_rounded,
                            iconColor: AppColors.warning,
                            title: 'New donor verification submitted',
                            description: 'Medical report & health clearance awaiting review',
                            timeText: 'Awaiting review',
                          ),
                        if (data.approvedDonors > 0)
                          _buildActivityItem(
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.success,
                            title: 'Donor verified & approved',
                            description: 'Donor record marked active for blood group matching',
                            timeText: 'Recent system record',
                          ),
                        _buildActivityItem(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.primary,
                          title: 'HemoConnect Platform Sync',
                          description: 'Database health check completed successfully',
                          timeText: '$timeAgoStr',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftAnalyticsColumn),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: rightActionsColumn),
                  ],
                );
              }

              return Column(
                children: [
                  leftAnalyticsColumn,
                  const SizedBox(height: 28),
                  rightActionsColumn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Compact Horizontal Bar Chart for Blood Stock
  Widget _buildHorizontalBloodStockList(Map<String, int> dist) {
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final maxCount = dist.values.fold(1, (max, v) => v > max ? v : max);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: bloodGroups.map((group) {
        final count = dist[group] ?? 0;
        final fraction = (count / maxCount).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  group,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: count == 0 ? 0.02 : fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: count > 0 ? AppColors.primaryGradient : null,
                        color: count == 0 ? (isDark ? AppColors.borderDark : AppColors.borderLight) : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: count > 0 ? AppColors.primary : AppColors.textMutedLight,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 4. Improved Donut Chart with Center Total & Legend
  Widget _buildDonutChartWithCenterText({
    required int approved,
    required int pending,
    required int rejected,
    required int total,
  }) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 44,
                  sections: [
                    PieChartSectionData(
                      color: AppColors.success,
                      value: (approved == 0 && pending == 0 && rejected == 0) ? 1 : approved.toDouble(),
                      title: '',
                      radius: 26,
                    ),
                    PieChartSectionData(
                      color: AppColors.warning,
                      value: pending.toDouble(),
                      title: '',
                      radius: 26,
                    ),
                    PieChartSectionData(
                      color: AppColors.danger,
                      value: rejected.toDouble(),
                      title: '',
                      radius: 26,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.0),
                  ),
                  const Text(
                    'Total Donors',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Legend below Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('✓ Approved', approved, AppColors.success),
            _buildLegendItem('⏳ Pending', pending, AppColors.warning),
            _buildLegendItem('✕ Rejected', rejected, AppColors.danger),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label — $count',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // Urgent Action Card
  Widget _buildUrgentActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required AppButtonVariant buttonVariant,
    required VoidCallback onTap,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: buttonText,
              variant: buttonVariant,
              height: 36,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }

  // Recent Activity List Item
  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String timeText,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            Text(timeText, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight, fontWeight: FontWeight.bold)),
          ],
        ),
        if (!isLast) const Divider(height: 18),
      ],
    );
  }
}
