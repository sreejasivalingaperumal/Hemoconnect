/// Profile data model representing user account records in Supabase.
class UserProfile {
  final String id;
  final String name;
  final String? phone;
  final String email;
  final String? bloodGroup;
  final String role; // 'donor' or 'admin'
  final String? city;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    this.phone,
    required this.email,
    this.bloodGroup,
    this.role = 'donor',
    this.city,
    required this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      phone: json['phone'] as String?,
      email: json['email'] as String? ?? '',
      bloodGroup: json['blood_group'] as String?,
      role: json['role'] as String? ?? 'donor',
      city: json['city'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'blood_group': bloodGroup,
      'role': role,
      'city': city,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? bloodGroup,
    String? city,
    String? role,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      role: role ?? this.role,
      city: city ?? this.city,
      createdAt: createdAt,
    );
  }
}
