import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/donor.dart';
import '../../services/donor_service.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

/// Donor Registry page providing complete search, filtering, and CRUD management.
class DonorListScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const DonorListScreen({super.key, this.onDataChanged});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  final DonorService _donorService = DonorService();
  final _searchController = TextEditingController();

  List<Donor> _donors = [];
  bool _isLoading = true;

  String _statusFilter = 'All';
  String _bloodGroupFilter = 'All';

  final List<String> _statusOptions = ['All', 'Approved', 'Pending', 'Rejected'];
  final List<String> _bloodOptions = ['All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonors() async {
    setState(() => _isLoading = true);
    try {
      final list = await _donorService.getDonors(
        statusFilter: _statusFilter,
        bloodGroupFilter: _bloodGroupFilter,
        searchQuery: _searchController.text,
      );
      setState(() => _donors = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDonor(Donor donor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Donor Record'),
        content: Text('Are you sure you want to delete ${donor.name} from the database?'),
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
        await _donorService.deleteDonor(donor.id);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donor record deleted.'),
            backgroundColor: AppColors.danger,
          ),
        );

        widget.onDataChanged?.call();
        _loadDonors();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Registry Management'),
      ),
      body: Column(
        children: [
          // Filter Bar Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _loadDonors(),
                    decoration: InputDecoration(
                      hintText: 'Search name, phone, city...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),

                // Status Filter Dropdown
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Status: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _statusFilter,
                      underline: const SizedBox.shrink(),
                      items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _statusFilter = v);
                          _loadDonors();
                        }
                      },
                    ),
                  ],
                ),

                // Blood Group Filter Dropdown
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Blood: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _bloodGroupFilter,
                      underline: const SizedBox.shrink(),
                      items: _bloodOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _bloodGroupFilter = v);
                          _loadDonors();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading donor directory...')
                : _donors.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No Donors Found',
                        description: 'No donor records match your specified search criteria.',
                      )
                    : isDesktop
                        ? _buildDesktopDataTable()
                        : _buildMobileCardsList(),
          ),
        ],
      ),
    );
  }

  // Desktop DataTable Representation
  Widget _buildDesktopDataTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PremiumCard(
        padding: const EdgeInsets.all(0),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.05)),
            columns: const [
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Blood Group', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('City', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _donors.map((donor) {
              return DataRow(
                cells: [
                  DataCell(Text(donor.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        donor.bloodGroup,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  DataCell(Text(donor.city)),
                  DataCell(Text(donor.phone)),
                  DataCell(StatusBadge(status: donor.status)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                          tooltip: 'Delete Donor',
                          onPressed: () => _deleteDonor(donor),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Mobile Cards List Representation
  Widget _buildMobileCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _donors.length,
      itemBuilder: (context, index) {
        final donor = _donors[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      donor.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    StatusBadge(status: donor.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Blood Group: ${donor.bloodGroup} • City: ${donor.city}'),
                Text('Phone: ${donor.phone}', style: const TextStyle(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                    label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                    onPressed: () => _deleteDonor(donor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
