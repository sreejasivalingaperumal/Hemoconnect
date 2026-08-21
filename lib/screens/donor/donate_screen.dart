import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/donor_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/blood_group_chip.dart';
import '../../widgets/premium_card.dart';

/// 4-Step Donor Registration Wizard with File Picker & Supabase Storage.
class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  int _currentStep = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _conditionController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  String _alcoholUsage = 'No';
  String _smokingHabit = 'No';

  // File Picker variables
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  bool _isSubmitted = false;

  final AuthService _authService = AuthService();
  final DonorService _donorService = DonorService();
  final StorageService _storageService = StorageService();

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    final profile = await _authService.getCurrentProfile();
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone ?? '';
        _cityController.text = profile.city ?? '';
        if (profile.bloodGroup != null && _bloodGroups.contains(profile.bloodGroup)) {
          _selectedBloodGroup = profile.bloodGroup!;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedicalReport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, // Loads file bytes into memory for cross-platform support
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _submitDonorApplication() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit your application.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all personal information fields.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? reportStoragePath;

      // Upload file to Supabase Storage if picked
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        reportStoragePath = await _storageService.uploadMedicalReport(
          userId: user.id,
          fileName: _pickedFile!.name,
          fileBytes: _pickedFile!.bytes!,
        );
      }

      // Create Donor Record in Supabase
      await _donorService.createDonorRegistration(
        userId: user.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        bloodGroup: _selectedBloodGroup,
        medicalCondition: _conditionController.text.trim().isEmpty
            ? 'None reported'
            : _conditionController.text.trim(),
        alcohol: _alcoholUsage,
        smoking: _smokingHabit,
        medicalReportPath: reportStoragePath,
      );

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate Blood Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator Header
                Row(
                  children: List.generate(4, (index) {
                    final isActive = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of 4',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _getStepTitle(_currentStep),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Step Content Box
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStepWidget(),
                ),
                const SizedBox(height: 24),

                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      AppButton(
                        text: 'Back',
                        variant: AppButtonVariant.outline,
                        onPressed: () => setState(() => _currentStep--),
                        height: 46,
                      )
                    else
                      const SizedBox.shrink(),
                    if (_currentStep < 3)
                      AppButton(
                        text: 'Next Step',
                        onPressed: () => setState(() => _currentStep++),
                        height: 46,
                      )
                    else
                      AppButton(
                        text: 'Submit for Verification',
                        variant: AppButtonVariant.primary,
                        isLoading: _isUploading,
                        onPressed: _submitDonorApplication,
                        height: 46,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'Blood Group';
      case 2:
        return 'Health Info';
      case 3:
        return 'Medical Report';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal();
      case 1:
        return _buildStep2Blood();
      case 2:
        return _buildStep3Health();
      case 3:
        return _buildStep4Report();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Personal Info
  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Verify your contact details for emergency donor dispatch.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _phoneController,
          label: 'Contact Phone Number',
          hint: '+1 234 567 8900',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _cityController,
          label: 'City / Location',
          hint: 'Enter your city',
          prefixIcon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  // STEP 2: Blood Group
  Widget _buildStep2Blood() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Blood Group',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose your blood group accurately for inventory matching.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _bloodGroups.map((group) {
            final isSelected = _selectedBloodGroup == group;
            return BloodGroupChip(
              label: group,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedBloodGroup = group),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 3: Health Info
  Widget _buildStep3Health() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health & Lifestyle Declaration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Help us verify donation safety for recipient patients.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _conditionController,
          label: 'Medical Conditions / History (If Any)',
          hint: 'e.g. None, Diabetes, Mild Hypertension, Asthma',
          prefixIcon: Icons.medical_services_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        const Text(
          'Alcohol Consumption',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['No', 'Occasionally', 'Regularly'].map((option) {
            final isSelected = _alcoholUsage == option;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => setState(() => _alcoholUsage = option),
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Smoking Habit',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['No', 'Occasionally', 'Regularly'].map((option) {
            final isSelected = _smokingHabit == option;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => setState(() => _smokingHabit = option),
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 4: Medical Report Upload
  Widget _buildStep4Report() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Medical Clearance Report',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload a recent blood lab report or medical clearance certificate (PDF, JPG, PNG).',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 24),
        if (_pickedFile == null)
          InkWell(
            onTap: _pickMedicalReport,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text(
                    'Click to upload medical document',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Supported formats: PDF, JPG, JPEG, PNG (Max 10MB)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_rounded, color: AppColors.success, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedFile!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB • Ready to upload',
                        style: const TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                  onPressed: () => setState(() => _pickedFile = null),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Application Submitted Success Screen
  Widget _buildSuccessScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              const Text(
                'Application Submitted ❤️',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your donor profile is waiting for admin verification.\nThank you for volunteering to save lives!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Return to Dashboard',
                onPressed: () {
                  setState(() {
                    _isSubmitted = false;
                    _currentStep = 0;
                  });
                },
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
