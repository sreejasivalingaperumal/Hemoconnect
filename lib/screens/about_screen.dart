import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';

/// About HemoConnect screen detailing mission, feature highlights, and v1.0 specifications.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About HemoConnect'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Logo & Branding Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.water_drop_rounded, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'HemoConnect',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connecting Donors, Saving Lives',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Version 1.0.0 (Production Build)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),

                // Mission Card
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'Our Mission',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our mission is to connect blood donors with people who need blood quickly and safely through a modern, cloud-enabled emergency HealthTech platform.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Platform Key Features List
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Core Platform Capabilities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),

                _buildFeatureCard(
                  '🩸 Donor Registration Wizard',
                  'Multi-step application supporting health disclosures and medical report file uploads.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  '🔎 Real-Time Blood Search',
                  'Instant lookup for verified, active approved donors filtered by blood group and city.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  '🚨 Emergency Dispatch Hub',
                  'Urgent blood request creation and live status tracking from Pending to Completed.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  '✅ Admin Verification Pipeline',
                  'Secure document inspection with signed Storage URLs and one-click Approval/Rejection.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  '📊 Live Blood Inventory',
                  'Dynamic calculation of available blood stock across all 8 blood groups.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  '📈 Health Analytics',
                  'Real-time statistical charts powered by fl_chart and Supabase PostgreSQL data.',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
