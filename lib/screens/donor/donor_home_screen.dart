import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/profile.dart';
import '../../models/donor.dart';
import '../../services/auth_service.dart';
import '../../services/donor_service.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_widget.dart';
import 'donate_screen.dart';
import 'search_screen.dart';
import 'emergency_request_screen.dart';
import 'profile_screen.dart';
import '../about_screen.dart';
import '../auth/login_screen.dart';


/// Donor Portal Dashboard with Home hero banner, stats summary & navigation.
class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  int _currentIndex = 0;
  UserProfile? _profile;
  Donor? _myDonorApplication;
  bool _isLoading = true;

  final AuthService _authService = AuthService();
  final DonorService _donorService = DonorService();

  @override
  void initState() {
    super.initState();
    _loadDonorData();
  }

  Future<void> _loadDonorData() async {
    setState(() => _isLoading = true);
    try {
      final prof = await _authService.getCurrentProfile();
      if (prof != null) {
        final donorApp = await _donorService.getUserDonorApplication(prof.id);
        setState(() {
          _profile = prof;
          _myDonorApplication = donorApp;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final List<Widget> pages = [
      _buildHomeContent(),
      const SearchScreen(),
      const DonateScreen(),
      const EmergencyRequestScreen(),
      ProfileScreen(onProfileUpdated: _loadDonorData),
    ];

    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Loading your donor dashboard...'));
    }

    return Scaffold(
      body: Row(
        children: [
          // Desktop Navigation Rail / Drawer
          if (isDesktop) ...[
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavigate,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                  label: Text('Find Donors'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
                  label: Text('Donate'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.warning_amber_rounded),
                  selectedIcon: Icon(Icons.warning_rounded, color: AppColors.danger),
                  label: Text('Emergency'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],

          // Main Page Content View
          Expanded(child: pages[_currentIndex]),
        ],
      ),

      // Mobile Bottom Navigation Bar
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onNavigate,
              selectedItemColor: AppColors.primary,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_outline_rounded),
                  activeIcon: Icon(Icons.favorite_rounded),
                  label: 'Donate',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.warning_amber_rounded),
                  activeIcon: Icon(Icons.warning_rounded),
                  label: 'Emergency',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  Widget _buildHomeContent() {
    final userName = _profile?.name ?? 'Donor';
    final userBlood = _profile?.bloodGroup ?? 'Unknown';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                    '$userName ',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to make a difference today?',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                tooltip: 'About HemoConnect',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Hero Banner Card
          PremiumCard(
            gradient: AppColors.primaryGradient,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Save Lives Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Donation Can\nSave Up To 3 Lives',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.favorite_rounded, size: 18),
                        label: const Text(
                          'Donate Now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _onNavigate(2), // Switch to Donate screen
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 90,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Quick Action Section
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
            children: [
              _buildActionCard(
                title: 'Donate Blood',
                icon: Icons.water_drop_rounded,
                color: AppColors.primary,
                bgColor: const Color(0xFFFFE6EC),
                onTap: () => _onNavigate(2),
              ),
              _buildActionCard(
                title: 'Find Donors',
                icon: Icons.search_rounded,
                color: AppColors.info,
                bgColor: AppColors.infoBg,
                onTap: () => _onNavigate(1),
              ),
              _buildActionCard(
                title: 'Emergency',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
                bgColor: AppColors.dangerBg,
                onTap: () => _onNavigate(3),
              ),
              _buildActionCard(
                title: 'My Profile',
                icon: Icons.person_rounded,
                color: AppColors.success,
                bgColor: AppColors.successBg,
                onTap: () => _onNavigate(4),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Mini Statistics & Status Row
          const Text(
            'Donation Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Blood Group',
                  value: userBlood,
                  icon: Icons.bloodtype_rounded,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.accent.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  title: 'Donation Status',
                  value: _myDonorApplication?.status ?? 'Not Registered',
                  icon: Icons.verified_user_rounded,
                  iconColor: _myDonorApplication?.isApproved == true
                      ? AppColors.success
                      : AppColors.warning,
                  iconBgColor: _myDonorApplication?.isApproved == true
                      ? AppColors.successBg
                      : AppColors.warningBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Application Banner if Pending
          if (_myDonorApplication != null) ...[
            PremiumCard(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Application Verification Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _myDonorApplication!.isApproved
                              ? 'Your profile is verified and active for donor matching!'
                              : 'Your application is waiting for admin verification.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: _myDonorApplication!.status),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
