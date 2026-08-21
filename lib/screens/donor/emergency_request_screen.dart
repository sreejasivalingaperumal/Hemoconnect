import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/emergency_request.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/blood_group_chip.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/status_badge.dart';

/// Emergency blood request screen with submission form & user status tracker.
class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  bool _isSubmitting = false;

  final AuthService _authService = AuthService();
  final EmergencyService _emergencyService = EmergencyService();

  List<EmergencyRequest> _myRequests = [];
  bool _isLoadingRequests = true;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRequests();
  }

  Future<void> _loadUserRequests() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final list = await _emergencyService.getUserEmergencyRequests(user.id);
        if (mounted) setState(() => _myRequests = list);
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isLoadingRequests = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  @override
  void dispose() {
    _patientController.dispose();
    _hospitalController.dispose();
    _unitsController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitEmergencyRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _authService.currentUser;

      await _emergencyService.createEmergencyRequest(
        userId: user?.id,
        patientName: _patientController.text.trim(),
        hospital: _hospitalController.text.trim(),
        bloodGroup: _selectedBloodGroup,
        units: int.tryParse(_unitsController.text.trim()) ?? 1,
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency request dispatched successfully! 🚨'),
          backgroundColor: AppColors.danger,
        ),
      );

      // Clear form inputs
      _patientController.clear();
      _hospitalController.clear();
      _phoneController.clear();
      _locationController.clear();
      _unitsController.text = '1';

      await _loadUserRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Blood Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent Emergency Warning Banner Card
                PremiumCard(
                  gradient: AppColors.emergencyGradient,
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 40, color: Colors.white),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Blood Urgently?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Submit emergency request to alert admin & available verified blood donors nearby immediately.',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Emergency Request Form Box
                const Text(
                  'Emergency Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          controller: _patientController,
                          label: 'Patient Name',
                          hint: 'Enter full patient name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _hospitalController,
                                label: 'Hospital Name',
                                hint: 'e.g. City General Hospital',
                                prefixIcon: Icons.local_hospital_outlined,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _unitsController,
                                label: 'Units Required',
                                hint: '1',
                                prefixIcon: Icons.format_list_numbered_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Blood Group Selection Chips
                        const Text(
                          'Blood Group Required',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _bloodGroups.map((group) {
                            final isSelected = _selectedBloodGroup == group;
                            return BloodGroupChip(
                              label: group,
                              isSelected: isSelected,
                              onTap: () => setState(() => _selectedBloodGroup = group),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _phoneController,
                                label: 'Attendant Phone Number',
                                hint: '+1 234 567 8900',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _locationController,
                                label: 'City / Location',
                                hint: 'e.g. Downtown Sector 4',
                                prefixIcon: Icons.location_on_outlined,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        AppButton(
                          text: 'Send Emergency Request 🚨',
                          variant: AppButtonVariant.danger,
                          onPressed: _submitEmergencyRequest,
                          isLoading: _isSubmitting,
                          width: double.infinity,
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // My Emergency Requests Tracker History
                const Text(
                  'My Active Emergency Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                if (_isLoadingRequests)
                  const Center(child: CircularProgressIndicator())
                else if (_myRequests.isEmpty)
                  const Text(
                    'No emergency requests submitted yet.',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myRequests.length,
                    itemBuilder: (context, index) {
                      final req = _myRequests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PremiumCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.emergency_rounded, color: AppColors.danger),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Patient: ${req.patientName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${req.hospital} • ${req.units} Unit(s) (${req.bloodGroup})',
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: req.status),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
