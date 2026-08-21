import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/emergency_request.dart';
import '../../services/emergency_service.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/app_button.dart';

/// Admin emergency blood request management hub with status workflow updating.
class EmergencyRequestsListScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const EmergencyRequestsListScreen({super.key, this.onDataChanged});

  @override
  State<EmergencyRequestsListScreen> createState() => _EmergencyRequestsListScreenState();
}

class _EmergencyRequestsListScreenState extends State<EmergencyRequestsListScreen> {
  final EmergencyService _emergencyService = EmergencyService();

  List<EmergencyRequest> _requests = [];
  bool _isLoading = true;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final list = await _emergencyService.getEmergencyRequests(statusFilter: _statusFilter);
      setState(() => _requests = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(EmergencyRequest req, String newStatus) async {
    try {
      await _emergencyService.updateRequestStatus(req.id, newStatus);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request status updated to $newStatus!'),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onDataChanged?.call();
      _fetchRequests();
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

  Future<void> _deleteRequest(EmergencyRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Emergency Request'),
        content: Text('Are you sure you want to delete request for ${req.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _emergencyService.deleteRequest(req.id);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency request deleted.'), backgroundColor: AppColors.danger),
        );

        widget.onDataChanged?.call();
        _fetchRequests();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Blood Requests'),
      ),
      body: Column(
        children: [
          // Status Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: ['All', 'Pending', 'Processing', 'Completed','Rejected'].map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _statusFilter = status);
                      _fetchRequests();
                    },
                    selectedColor: AppColors.danger.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.danger : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Requests List View
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Fetching emergency dispatches...')
                : _requests.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_off_rounded,
                        title: 'No Emergency Requests',
                        description: 'There are currently no urgent blood requests in this status category.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          return _buildEmergencyCard(req);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(EmergencyRequest req) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        padding: const EdgeInsets.all(20),
        border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 1.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient: ${req.patientName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          req.hospital,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(status: req.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Emergency Detail Badges
            Row(
              children: [
                _buildChipBadge(Icons.water_drop_rounded, 'Blood: ${req.bloodGroup}', AppColors.primary),
                const SizedBox(width: 10),
                _buildChipBadge(Icons.format_list_numbered_rounded, '${req.units} Unit(s)', AppColors.info),
                const SizedBox(width: 10),
                _buildChipBadge(Icons.location_on_rounded, req.location, AppColors.success),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Attendant Phone: ${req.phone} • Requested: ${req.requestDate.day}/${req.requestDate.month}/${req.requestDate.year}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),

            // Action Status Update Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  tooltip: 'Delete Request',
                  onPressed: () => _deleteRequest(req),
                ),
                Row(
                  children: [
                    if (req.status != 'Processing')
                      AppButton(
                        text: 'Mark Processing',
                        variant: AppButtonVariant.outline,
                        height: 36,
                        onPressed: () => _updateStatus(req, 'Processing'),
                      ),
                    const SizedBox(width: 10),
                    if (req.status != 'Completed')
                      AppButton(
                        text: 'Mark Completed ✓',
                        variant: AppButtonVariant.success,
                        height: 36,
                        onPressed: () => _updateStatus(req, 'Completed'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
