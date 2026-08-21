import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/profile.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final int index;

  const SidebarItem({
    required this.title,
    required this.icon,
    required this.index,
  });
}

/// Desktop Navigation Sidebar for Admin Dashboard and Desktop Layouts.
class DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final UserProfile? profile;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final List<SidebarItem> items;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.profile,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 250,
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
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HemoConnect',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      profile?.isAdmin == true ? 'Admin Portal' : 'Donor Portal',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Navigation Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                final isSelected = selectedIndex == item.index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
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
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () => onDestinationSelected(item.index),
                  ),
                );
              },
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
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          profile!.name.isNotEmpty ? profile!.name[0].toUpperCase() : 'U',
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
