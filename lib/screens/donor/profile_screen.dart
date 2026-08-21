import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/loading_widget.dart';
import '../auth/login_screen.dart';

/// User Profile Management Screen with Dark Mode toggle & Supabase Sign Out.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final p = await _authService.getCurrentProfile();
      if (p != null && mounted) {
        setState(() {
          _profile = p;
          _nameController.text = p.name;
          _phoneController.text = p.phone ?? '';
          _cityController.text = p.city ?? '';
          if (p.bloodGroup != null && _bloodGroups.contains(p.bloodGroup)) {
            _selectedBloodGroup = p.bloodGroup!;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    setState(() => _isSaving = true);

    try {
      final updated = await _authService.updateProfile(
        userId: _profile!.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bloodGroup: _selectedBloodGroup,
        city: _cityController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _profile = updated;
        _isEditing = false;
      });

      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of HemoConnect?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Loading profile...'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit Profile',
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Profile Avatar Header Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          _profile?.name.isNotEmpty == true ? _profile!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _profile?.name ?? 'User',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.email ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _profile?.isAdmin == true
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.successBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _profile?.isAdmin == true ? 'Role: Administrator 🛡️' : 'Role: Blood Donor 🩸',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _profile?.isAdmin == true ? AppColors.primary : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Information Form / Card
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Account Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (_isEditing)
                            AppButton(
                              text: 'Save',
                              onPressed: _saveProfile,
                              isLoading: _isSaving,
                              height: 36,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isEditing) ...[
                        AppTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          prefixIcon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _cityController,
                          label: 'City',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Blood Group',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedBloodGroup,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.water_drop_outlined, size: 20),
                          ),
                          items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedBloodGroup = v!),
                        ),
                      ] else ...[
                        _buildInfoRow(Icons.phone_outlined, 'Phone', _profile?.phone ?? 'Not provided'),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.location_on_outlined, 'City', _profile?.city ?? 'Not provided'),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.bloodtype_outlined, 'Blood Group', _profile?.bloodGroup ?? 'Not set'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Settings & Preferences Card
                PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Toggle between sleek dark and warm light UI', style: TextStyle(fontSize: 12)),
                        secondary: Icon(
                          themeNotifier.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: AppColors.primary,
                        ),
                        value: themeNotifier.isDarkMode,
                        onChanged: (_) => themeNotifier.toggleTheme(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Sign Out Button
                AppButton(
                  text: 'Sign Out of Account',
                  variant: AppButtonVariant.danger,
                  icon: Icons.logout_rounded,
                  onPressed: _handleLogout,
                  width: double.infinity,
                  height: 48,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
