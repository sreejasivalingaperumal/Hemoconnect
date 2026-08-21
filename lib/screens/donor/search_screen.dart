import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/donor.dart';
import '../../services/donor_service.dart';
import '../../widgets/blood_group_chip.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/app_button.dart';

/// Donor search screen allowing public lookup of verified approved donors.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DonorService _donorService = DonorService();
  final _cityController = TextEditingController();

  String _selectedBloodGroup = 'All';
  List<Donor> _approvedDonors = [];
  bool _isLoading = true;

  final List<String> _bloodGroupFilters = [
    'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _fetchApprovedDonors();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchApprovedDonors() async {
    setState(() => _isLoading = true);
    try {
      final list = await _donorService.getApprovedDonors(
        bloodGroup: _selectedBloodGroup,
        city: _cityController.text,
      );
      setState(() => _approvedDonors = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showContactDialog(Donor donor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                donor.name.isNotEmpty ? donor.name[0] : 'D',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                donor.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.bloodtype_rounded, 'Blood Group', donor.bloodGroup),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.location_on_rounded, 'City', donor.city),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.phone_rounded, 'Phone Number', donor.phone),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified Active Blood Donor',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: Text('Call ${donor.phone}'),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dialing ${donor.name} at ${donor.phone}...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Blood Donor'),
      ),
      body: Column(
        children: [
          // Filter Bar Header Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City Search Input
                TextField(
                  controller: _cityController,
                  onChanged: (_) => _fetchApprovedDonors(),
                  decoration: InputDecoration(
                    hintText: 'Search city or region...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _cityController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _cityController.clear();
                              _fetchApprovedDonors();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                // Blood Group Chips Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _bloodGroupFilters.map((group) {
                      final isSelected = _selectedBloodGroup == group;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: BloodGroupChip(
                          label: group,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedBloodGroup = group);
                            _fetchApprovedDonors();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Donors List View
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Searching verified donors...')
                : _approvedDonors.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'No Approved Donors Found',
                        description:
                            'No active verified donors match your selected blood group or city criteria.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _approvedDonors.length,
                        itemBuilder: (context, index) {
                          final donor = _approvedDonors[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PremiumCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      donor.name.isNotEmpty ? donor.name[0].toUpperCase() : 'D',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          donor.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: AppColors.textSecondaryLight,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              donor.city,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.water_drop_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          donor.bloodGroup,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  AppButton(
                                    text: 'Contact',
                                    variant: AppButtonVariant.outline,
                                    height: 38,
                                    onPressed: () => _showContactDialog(donor),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
