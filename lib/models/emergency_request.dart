/// Emergency blood request model representing urgent requests in Supabase.
class EmergencyRequest {
  final String id;
  final String? userId;
  final String patientName;
  final String hospital;
  final String bloodGroup;
  final int units;
  final String phone;
  final String location;
  final String status; // 'Pending', 'Processing', 'Completed'
  final DateTime requestDate;
  final DateTime createdAt;

  EmergencyRequest({
    required this.id,
    this.userId,
    required this.patientName,
    required this.hospital,
    required this.bloodGroup,
    required this.units,
    required this.phone,
    required this.location,
    this.status = 'Pending',
    required this.requestDate,
    required this.createdAt,
  });

  bool get isPending => status == 'Pending';
  bool get isProcessing => status == 'Processing';
  bool get isCompleted => status == 'Completed';

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      patientName: json['patient_name'] as String? ?? '',
      hospital: json['hospital'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? 'O+',
      units: (json['units'] as num?)?.toInt() ?? 1,
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      requestDate: json['request_date'] != null
          ? DateTime.parse(json['request_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_name': patientName,
      'hospital': hospital,
      'blood_group': bloodGroup,
      'units': units,
      'phone': phone,
      'location': location,
      'status': status,
      'request_date': requestDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
