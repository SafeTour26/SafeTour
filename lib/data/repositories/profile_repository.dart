import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  static const String _userSessionKey = 'safetour_device_user_id';
  static const String _userNameKey = 'safetour_user_name';
  static const String _userPhoneKey = 'safetour_user_phone';
  static const String _userEmailKey = 'safetour_user_email';
  static const String _profileCompletedKey = 'safetour_profile_completed';

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns current authenticated user ID or creates persistent device session
  Future<String> getOrCreateUserId() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      return currentUser.id;
    }

    // Try signing in anonymously via Supabase Auth
    try {
      final response = await _supabase.auth.signInAnonymously();
      if (response.user != null) {
        return response.user!.id;
      }
    } catch (_) {}

    // Offline device ID fallback
    final prefs = await SharedPreferences.getInstance();
    String? localId = prefs.getString(_userSessionKey);
    if (localId == null) {
      localId =
          'anon-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
      await prefs.setString(_userSessionKey, localId);
    }
    return localId;
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(_userNameKey);
    if (local != null && local.isNotEmpty) return local;

    final user = _supabase.auth.currentUser;
    final metaName = user?.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.isNotEmpty) {
      await prefs.setString(_userNameKey, metaName);
      return metaName;
    }

    return 'Bengaluru Traveler';
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  Future<void> saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPhoneKey, phone);
  }

  Future<String> getUserEmail() async {
    final user = _supabase.auth.currentUser;
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email!;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? 'guest@safetour.app';
  }

  Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  Future<bool> isProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileCompletedKey) ?? false;
  }

  Future<void> setProfileCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileCompletedKey, completed);
  }

  /// Syncs Name and Phone to Supabase profiles table and caches locally
  Future<void> syncProfileToSupabase({
    required String name,
    required String phone,
  }) async {
    await saveUserName(name);
    await saveUserPhone(phone);
    await setProfileCompleted(true);

    final user = _supabase.auth.currentUser;
    if (user != null) {
      if (user.email != null) {
        await saveUserEmail(user.email!);
      }
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': name,
          'phone_number': phone,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Safe offline resilience
      }
    }
  }

  /// Attempts to fetch existing profile from Supabase
  Future<void> fetchRemoteProfileIfAvailable() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (user.email != null) {
      await saveUserEmail(user.email!);
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final name = data['full_name'] as String?;
        final phone = data['phone_number'] as String?;
        if (name != null && name.isNotEmpty) {
          await saveUserName(name);
        }
        if (phone != null && phone.isNotEmpty) {
          await saveUserPhone(phone);
        }
        if (name != null &&
            name.isNotEmpty &&
            phone != null &&
            phone.isNotEmpty) {
          await setProfileCompleted(true);
        }
      }
    } catch (_) {}
  }

  /// Clears stored user session and cached profile details upon logout
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userSessionKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_profileCompletedKey);
  }
}
