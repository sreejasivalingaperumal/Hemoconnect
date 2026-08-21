import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/donor.dart';

/// Donor service performing CRUD and search operations on Supabase `donors` table.
class DonorService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Submit new donor registration application
  Future<Donor> createDonorRegistration({
    required String userId,
    required String name,
    required String phone,
    required String city,
    required String bloodGroup,
    String? medicalCondition,
    String? alcohol,
    String? smoking,
    String? medicalReportPath,
  }) async {
    final payload = {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'city': city,
      'blood_group': bloodGroup,
      'medical_condition': medicalCondition,
      'alcohol': alcohol,
      'smoking': smoking,
      'medical_report': medicalReportPath,
      'status': 'Pending',
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _client.from('donors').insert(payload).select().single();
    return Donor.fromJson(response);
  }

  /// Get donor application for a specific user ID
  Future<Donor?> getUserDonorApplication(String userId) async {
    try {
      final response = await _client
          .from('donors')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Donor.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Search and fetch all approved donors for public/donor search
  Future<List<Donor>> getApprovedDonors({
    String? bloodGroup,
    String? city,
  }) async {
    dynamic query = _client.from('donors').select().eq('status', 'Approved');

    if (bloodGroup != null && bloodGroup.isNotEmpty && bloodGroup != 'All') {
      query = query.eq('blood_group', bloodGroup);
    }

    if (city != null && city.trim().isNotEmpty) {
      query = query.ilike('city', '%${city.trim()}%');
    }

    final response = await query.order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((item) => Donor.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Admin fetch donors with advanced multi-field filtering
  Future<List<Donor>> getDonors({
    String? statusFilter,
    String? bloodGroupFilter,
    String? cityFilter,
    String? searchQuery,
  }) async {
    dynamic query = _client.from('donors').select();

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All') {
      query = query.eq('status', statusFilter);
    }

    if (bloodGroupFilter != null && bloodGroupFilter.isNotEmpty && bloodGroupFilter != 'All') {
      query = query.eq('blood_group', bloodGroupFilter);
    }

    if (cityFilter != null && cityFilter.isNotEmpty && cityFilter != 'All') {
      query = query.ilike('city', '%$cityFilter%');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      query = query.or('name.ilike.$q,phone.ilike.$q,city.ilike.$q');
    }

    final response = await query.order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((item) => Donor.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Update donor status (Approved / Rejected / Pending)
  Future<Donor> updateDonorStatus(String donorId, String status) async {
    final response = await _client
        .from('donors')
        .update({'status': status})
        .eq('id', donorId)
        .select()
        .single();

    return Donor.fromJson(response);
  }

  /// Delete donor record (Admin only)
  Future<void> deleteDonor(String donorId) async {
    await _client.from('donors').delete().eq('id', donorId);
  }

  /// Calculate real Blood Stock count for each of the 8 blood groups (Approved donors only)
  Future<Map<String, int>> getBloodStockCount() async {
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final Map<String, int> stock = {for (var group in bloodGroups) group: 0};

    final response = await _client
        .from('donors')
        .select('blood_group')
        .eq('status', 'Approved');

    final list = response as List<dynamic>;
    for (var item in list) {
      final bg = item['blood_group'] as String?;
      if (bg != null && stock.containsKey(bg)) {
        stock[bg] = (stock[bg] ?? 0) + 1;
      }
    }

    return stock;
  }
}
