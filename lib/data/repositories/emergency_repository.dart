import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emergency_contact.dart';
import '../models/sos_event.dart';

class EmergencyRepository {
  static const String _contactsCachePrefix = 'safetour_contacts_cache_';
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<EmergencyContact>> getContacts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_contactsCachePrefix$userId';

    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 6));

      final List<EmergencyContact> contacts = (response as List)
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();

      await prefs.setString(cacheKey, jsonEncode(response));
      return contacts;
    } catch (_) {
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(cachedJson);
          return list
              .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }
    return [];
  }

  Future<EmergencyContact?> addContact(EmergencyContact contact) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .insert(contact.toJson())
          .select()
          .single();

      return EmergencyContact.fromJson(response);
    } catch (_) {
      return contact; // Optimistic return for local use
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      await _supabase.from('emergency_contacts').delete().eq('id', contactId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SOSEvent?> triggerSOSEvent({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'active',
      };

      final response =
          await _supabase.from('sos_events').insert(payload).select().single();

      return SOSEvent.fromJson(response);
    } catch (_) {
      // Local fallback event
      return SOSEvent(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        status: 'active',
        triggeredAt: DateTime.now(),
      );
    }
  }

  Future<void> resolveSOSEvent(String eventId,
      {String status = 'resolved'}) async {
    if (eventId.startsWith('local-')) return;
    try {
      await _supabase
          .from('sos_events')
          .update({'status': status}).eq('id', eventId);
    } catch (_) {}
  }
}
