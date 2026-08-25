import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/profile.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final int index;
  final String? category;
  final int badgeCount;

  const SidebarItem({
    required this.title,
    required this.icon,
    required this.index,
    this.category,
    this.badgeCount = 0,
  });
}

/// Desktop Navigation Sidebar for Admin Dashboard and Desktop Layouts with categories & notification badges.
class DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final UserProfile? profile;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final List<SidebarItem> items;
  final int pendingDonorsCount;
  final int pendingEmergencyCount;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.profile,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.items,
    this.pendingDonorsCount = 0,
    this.pendingEmergencyCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group sidebar items by category
    final Map<String, List<SidebarItem>> groupedItems = {};
    for (var item in items) {
      final category = item.category ?? 'MAIN';
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // App Header & Branding Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.primaryButtonGlow,
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HemoConnect',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      profile?.isAdmin == true ? 'Admin Management' : 'Donor Portal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Grouped Navigation Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: groupedItems.entries.map((entry) {
                final categoryName = entry.key;
                final categoryItems = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 14, bottom: 8),
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                    ...categoryItems.map((item) {
                      final isSelected = selectedIndex == item.index;

                      // Determine badge count
                      int badge = 0;
                      if (item.index == 1) badge = pendingDonorsCount;
                      if (item.index == 4) badge = pendingEmergencyCount;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected ? AppColors.primaryButtonGlow : null,
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            size: 20,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ),
                          trailing: badge > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : (item.index == 4 ? AppColors.danger : AppColors.warning),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$badge',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () => onDestinationSelected(item.index),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Bottom Controls: User profile summary, Theme switch & Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (profile != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          profile!.name.isNotEmpty ? profile!.name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile!.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              profile!.email,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 20,
                      ),
                      tooltip: 'Toggle Theme',
                      onPressed: onToggleTheme,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      tooltip: 'Sign Out',
                      onPressed: onLogout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
