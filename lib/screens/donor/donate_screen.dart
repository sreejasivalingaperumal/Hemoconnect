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
        withData: true,
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

      if (_pickedFile != null && _pickedFile!.bytes != null) {
        reportStoragePath = await _storageService.uploadMedicalReport(
          userId: user.id,
          fileName: _pickedFile!.name,
          fileBytes: _pickedFile!.bytes!,
        );
      }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Donor Application'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Step Wizard Progress Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStepIconBadge(0, Icons.person_outline_rounded, 'Personal'),
                          _buildStepConnector(0),
                          _buildStepIconBadge(1, Icons.water_drop_outlined, 'Blood Group'),
                          _buildStepConnector(1),
                          _buildStepIconBadge(2, Icons.health_and_safety_outlined, 'Health'),
                          _buildStepConnector(2),
                          _buildStepIconBadge(3, Icons.cloud_upload_outlined, 'Report'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Step Content Box
                PremiumCard(
                  padding: const EdgeInsets.all(28),
                  child: _buildCurrentStepWidget(),
                ),
                const SizedBox(height: 28),

                // Navigation Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      AppButton(
                        text: 'Back',
                        variant: AppButtonVariant.outline,
                        onPressed: () => setState(() => _currentStep--),
                        height: 48,
                        width: 120,
                      )
                    else
                      const SizedBox.shrink(),
                    if (_currentStep < 3)
                      AppButton(
                        text: 'Next Step →',
                        onPressed: () => setState(() => _currentStep++),
                        height: 48,
                        width: 140,
                      )
                    else
                      AppButton(
                        text: 'Submit Application',
                        variant: AppButtonVariant.primary,
                        isLoading: _isUploading,
                        onPressed: _submitDonorApplication,
                        height: 48,
                        width: 200,
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

  Widget _buildStepIconBadge(int stepIndex, IconData icon, String label) {
    final isActive = stepIndex == _currentStep;
    final isDone = stepIndex < _currentStep;

    Color color = AppColors.textMutedLight;
    if (isActive) color = AppColors.primary;
    if (isDone) color = AppColors.success;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : (isDone ? AppColors.successBg : AppColors.primary.withOpacity(0.08)),
            shape: BoxShape.circle,
            boxShadow: isActive ? AppColors.primaryButtonGlow : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            size: 20,
            color: isActive ? Colors.white : (isDone ? AppColors.success : AppColors.textSecondaryLight),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int afterStep) {
    final isDone = afterStep < _currentStep;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isDone ? AppColors.success : AppColors.borderLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
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
          'Personal Contact Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        const Text(
          'Verify your location and phone number for emergency blood dispatch matching.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 24),
        AppTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 18),
        AppTextField(
          controller: _phoneController,
          label: 'Contact Phone Number',
          hint: '+1 234 567 8900',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 18),
        AppTextField(
          controller: _cityController,
          label: 'City / Current Region',
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
          'Select Your Blood Group',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        const Text(
          'Accurate blood group information ensures rapid matching during patient emergencies.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
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
          'Health & Medical Declaration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        const Text(
          'Safe donation screening helps protect both donor health and recipient patients.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 24),
        AppTextField(
          controller: _conditionController,
          label: 'Medical Conditions / Past Surgeries (If Any)',
          hint: 'e.g. None, Mild Diabetes, Controlled Asthma',
          prefixIcon: Icons.medical_services_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        const Text(
          'Alcohol Usage',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: ['No', 'Occasionally', 'Regularly'].map((option) {
            final isSelected = _alcoholUsage == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => setState(() => _alcoholUsage = option),
              selectedColor: AppColors.primary.withOpacity(0.18),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Smoking Habit',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: ['No', 'Occasionally', 'Regularly'].map((option) {
            final isSelected = _smokingHabit == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => setState(() => _smokingHabit = option),
              selectedColor: AppColors.primary.withOpacity(0.18),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        const Text(
          'Attach a recent blood test lab report or medical clearance certificate (PDF, JPG, PNG).',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 28),
        if (_pickedFile == null)
          InkWell(
            onTap: _pickMedicalReport,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.35),
                  width: 1.8,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Click to Browse & Upload File',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Supports PDF, JPG, JPEG, PNG (Max 10MB)',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.success, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedFile!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB • Ready for verification upload',
                        style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            child: PremiumCard(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 64, color: AppColors.success),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Application Submitted! ❤️',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your volunteer donor application has been securely received by HemoConnect administration. Our medical team is reviewing your clearance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // Verification Timeline Steps
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TimelineStep('Application', 'Submitted', true),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                        _TimelineStep('Verification', 'Pending', true),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMutedLight),
                        _TimelineStep('Donor Matching', 'Active', false),
                      ],
                    ),
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
                    height: 50,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String status;
  final bool isDone;

  const _TimelineStep(this.title, this.status, this.isDone);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          status,
          style: TextStyle(
            fontSize: 10,
            color: isDone ? AppColors.primary : AppColors.textMutedLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
