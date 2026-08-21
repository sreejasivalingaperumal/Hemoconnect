import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/emergency_request.dart';

/// Emergency request service managing urgent blood needs on Supabase.
class EmergencyService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Submit new urgent emergency request
  Future<EmergencyRequest> createEmergencyRequest({
    String? userId,
    required String patientName,
    required String hospital,
    required String bloodGroup,
    required int units,
    required String phone,
    required String location,
  }) async {
    final payload = {
      'user_id': userId,
      'patient_name': patientName,
      'hospital': hospital,
      'blood_group': bloodGroup,
      'units': units,
      'phone': phone,
      'location': location,
      'status': 'Pending',
      'request_date': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('emergency_requests')
        .insert(payload)
        .select()
        .single();

    return EmergencyRequest.fromJson(response);
  }

  /// Get emergency requests list with optional status filter
  Future<List<EmergencyRequest>> getEmergencyRequests({
    String? statusFilter,
  }) async {
    dynamic query = _client.from('emergency_requests').select();

    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter != 'All') {
      query = query.eq('status', statusFilter);
    }

    final response = await query.order('created_at', ascending: false);

    final list = response as List<dynamic>;

    return list
        .map(
          (item) =>
              EmergencyRequest.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Fetch emergency requests created by a specific user
  Future<List<EmergencyRequest>> getUserEmergencyRequests(
    String userId,
  ) async {
    final response = await _client
        .from('emergency_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;

    return list
        .map(
          (item) =>
              EmergencyRequest.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Update emergency request status
  /// Pending -> Processing -> Completed
  Future<EmergencyRequest> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    final response = await _client
        .from('emergency_requests')
        .update({
          'status': status,
        })
        .eq('id', requestId)
        .select()
        .single();

    return EmergencyRequest.fromJson(response);
  }

  /// Verify an emergency request.
  ///
  /// Only an authenticated admin can successfully execute this
  /// because Supabase RLS protects this operation.
  Future<EmergencyRequest> verifyEmergencyRequest({
    required String requestId,
    String? adminNote,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception('You must be logged in to verify a request.');
    }

    final response = await _client
        .from('emergency_requests')
        .update({
          'status': 'Processing',
          'verified_by': currentUser.id,
          'verified_at': DateTime.now().toIso8601String(),
          'admin_note': adminNote,
        })
        .eq('id', requestId)
        .eq('status', 'Pending')
        .select()
        .single();

    return EmergencyRequest.fromJson(response);
  }

  /// Reject an emergency request.
  ///
  /// Rejected requests will not be processed or treated as verified.
  Future<EmergencyRequest> rejectEmergencyRequest({
    required String requestId,
    String? adminNote,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception('You must be logged in to reject a request.');
    }

    final response = await _client
        .from('emergency_requests')
        .update({
          'status': 'Rejected',
          'verified_by': currentUser.id,
          'verified_at': DateTime.now().toIso8601String(),
          'admin_note': adminNote,
        })
        .eq('id', requestId)
        .eq('status', 'Pending')
        .select()
        .single();

    return EmergencyRequest.fromJson(response);
  }

  /// Delete emergency request record
  Future<void> deleteRequest(String requestId) async {
    await _client
        .from('emergency_requests')
        .delete()
        .eq('id', requestId);
  }
}