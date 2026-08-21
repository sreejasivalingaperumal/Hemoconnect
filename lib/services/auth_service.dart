import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  bool get isAuthenticated => currentUser != null;

  // =========================
  // LOGIN
  // =========================

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Login failed.');
    }

    final profile = await getProfile(user.id);

    if (profile == null) {
      throw Exception(
        'Profile not found. Please contact the administrator.',
      );
    }

    return profile;
  }

  // =========================
  // REGISTER
  // =========================

  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String bloodGroup,
    required String city,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'blood_group': bloodGroup,
        'city': city.trim(),
      },
    );

    final user = response.user;

    if (user == null) {
      throw Exception(
        'Registration failed. Please try again.',
      );
    }

    // If email confirmation is enabled,
    // Supabase may create the user but not create a session.
    if (response.session == null) {
      throw Exception(
        'Account created. Please verify your email before logging in.',
      );
    }

    final profile = await _createInitialProfile(
      id: user.id,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      bloodGroup: bloodGroup,
      city: city.trim(),
      role: 'donor',
    );

    return profile;
  }

  // =========================
  // CREATE PROFILE
  // =========================

  Future<UserProfile> _createInitialProfile({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? bloodGroup,
    String? city,
    String role = 'donor',
  }) async {
    final profileMap = {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'blood_group': bloodGroup,
      'city': city,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _client
          .from('profiles')
          .upsert(
            profileMap,
            onConflict: 'id',
          )
          .select()
          .single();

      return UserProfile.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(
        'Profile creation failed: ${e.message}',
      );
    }
  }

  // =========================
  // GET PROFILE
  // =========================

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromJson(response);
    } on PostgrestException {
      return null;
    }
  }

  // =========================
  // CURRENT PROFILE
  // =========================

  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return getProfile(user.id);
  }

  // =========================
  // UPDATE PROFILE
  // =========================

  Future<UserProfile> updateProfile({
    required String userId,
    required String name,
    required String phone,
    required String bloodGroup,
    required String city,
  }) async {
    final updates = {
      'name': name.trim(),
      'phone': phone.trim(),
      'blood_group': bloodGroup,
      'city': city.trim(),
    };

    try {
      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(
        'Profile update failed: ${e.message}',
      );
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}