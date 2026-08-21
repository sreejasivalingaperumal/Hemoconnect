import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../theme/app_colors.dart';
import '../../models/donor.dart';
import '../../services/donor_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

/// Donor verification dashboard where admins review applications & medical clearance reports.
class VerifyDonorScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const VerifyDonorScreen({super.key, this.onDataChanged});

  @override
  State<VerifyDonorScreen> createState() => _VerifyDonorScreenState();
}

class _VerifyDonorScreenState extends State<VerifyDonorScreen> {
  final DonorService _donorService = DonorService();
  final StorageService _storageService = StorageService();

  List<Donor> _pendingDonors = [];
  bool _isLoading = true;
  String _activeFilter = 'Pending'; // 'Pending', 'Approved', 'Rejected', 'All'

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    setState(() => _isLoading = true);
    try {
      final list = await _donorService.getDonors(statusFilter: _activeFilter);
      setState(() => _pendingDonors = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewMedicalReport(String reportPath) async {
    try {
      final signedUrl = await _storageService.getSignedReportUrl(reportPath);

      if (!mounted) return;

      // Check if it's an image format
      final isImage = reportPath.toLowerCase().endsWith('.jpg') ||
          reportPath.toLowerCase().endsWith('.jpeg') ||
          reportPath.toLowerCase().endsWith('.png');

      if (isImage) {
        _showImagePreviewDialog(signedUrl);
      } else {
        // Try opening with OpenFile or open URL
        final result = await OpenFile.open(signedUrl);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report URL: $signedUrl'),
              action: SnackBarAction(label: 'Copy/Open', onPressed: () {}),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open medical report: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Medical Report Preview'),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.network(
                imageUrl,
                height: 400,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Unable to load report image preview.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(Donor donor, String newStatus) async {
    if (newStatus == 'Rejected') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Rejection'),
          content: Text('Are you sure you want to reject ${donor.name}\'s donor application?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await _donorService.updateDonorStatus(donor.id, newStatus);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Donor application marked as $newStatus!'),
          backgroundColor: newStatus == 'Approved' ? AppColors.success : AppColors.danger,
        ),
      );

      widget.onDataChanged?.call();
      _fetchDonors();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Donor Applications'),
      ),
      body: Column(
        children: [
          // Filter Tabs Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: ['Pending', 'Approved', 'Rejected', 'All'].map((status) {
                final isSelected = _activeFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _activeFilter = status);
                      _fetchDonors();
                    },
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Donors List
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Fetching donor verifications...')
                : _pendingDonors.isEmpty
                    ? EmptyState(
                        icon: Icons.done_all_rounded,
                        title: 'No $_activeFilter Applications',
                        description:
                            'There are currently no donor applications in the $_activeFilter verification status.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _pendingDonors.length,
                        itemBuilder: (context, index) {
                          final donor = _pendingDonors[index];
                          return _buildExpandableDonorCard(donor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDonorCard(Donor donor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        padding: const EdgeInsets.all(20),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 16),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              donor.name.isNotEmpty ? donor.name[0].toUpperCase() : 'D',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          title: Row(
            children: [
              Text(
                donor.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  donor.bloodGroup,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${donor.city} • ${donor.phone}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          trailing: StatusBadge(status: donor.status),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Health & Medical Details Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailLabel('Medical History', donor.medicalCondition ?? 'None reported'),
                      const SizedBox(height: 10),
                      _buildDetailLabel('Alcohol Use', donor.alcohol ?? 'No'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailLabel('Smoking Habit', donor.smoking ?? 'No'),
                      const SizedBox(height: 10),
                      _buildDetailLabel(
                        'Application Date',
                        '${donor.createdAt.day}/${donor.createdAt.month}/${donor.createdAt.year}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Medical Report File Button
            if (donor.medicalReport != null && donor.medicalReport!.isNotEmpty) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('View Medical Report Attachment 📄'),
                onPressed: () => _viewMedicalReport(donor.medicalReport!),
              ),
              const SizedBox(height: 16),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No medical report document attached.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                ),
              ),

            // Action Approval Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (donor.status != 'Rejected')
                  AppButton(
                    text: 'Reject ✕',
                    variant: AppButtonVariant.danger,
                    height: 38,
                    onPressed: () => _updateStatus(donor, 'Rejected'),
                  ),
                const SizedBox(width: 12),
                if (donor.status != 'Approved')
                  AppButton(
                    text: 'Approve ✓',
                    variant: AppButtonVariant.success,
                    height: 38,
                    onPressed: () => _updateStatus(donor, 'Approved'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
