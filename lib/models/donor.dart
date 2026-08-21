/// Donor application model representing blood donor records in Supabase.
class Donor {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String city;
  final String bloodGroup;
  final String? medicalCondition;
  final String? alcohol;
  final String? smoking;
  final String? medicalReport; // Path or URL in Supabase Storage
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime createdAt;

  Donor({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.city,
    required this.bloodGroup,
    this.medicalCondition,
    this.alcohol,
    this.smoking,
    this.medicalReport,
    this.status = 'Pending',
    required this.createdAt,
  });

  bool get isApproved => status == 'Approved';
  bool get isPending => status == 'Pending';
  bool get isRejected => status == 'Rejected';

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? 'O+',
      medicalCondition: json['medical_condition'] as String?,
      alcohol: json['alcohol'] as String?,
      smoking: json['smoking'] as String?,
      medicalReport: json['medical_report'] as String?,
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'city': city,
      'blood_group': bloodGroup,
      'medical_condition': medicalCondition,
      'alcohol': alcohol,
      'smoking': smoking,
      'medical_report': medicalReport,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
