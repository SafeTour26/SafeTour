import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/safety_zone.dart';
import '../local/initial_safety_data.dart';
import '../../core/utils/distance_formatter.dart';

class SafetyZoneRepository {
  static const String _cacheKey = 'safetour_safety_zones_cache';
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SafetyZone>> getSafetyZones({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(cachedJson);
          if (list.isNotEmpty) {
            return list
                .map((e) => SafetyZone.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
    }

    try {
      final response = await _supabase
          .from('safety_zones')
          .select('*')
          .order('overall_score', ascending: false)
          .timeout(const Duration(seconds: 8));

      final List<SafetyZone> zones = (response as List)
          .map((item) => SafetyZone.fromJson(item as Map<String, dynamic>))
          .toList();

      if (zones.isNotEmpty) {
        await prefs.setString(_cacheKey, jsonEncode(response));
        return zones;
      }
    } catch (_) {
      // Fallback to local offline cache or pre-bundled dataset
    }

    // Final fallback: pre-bundled 100 Bengaluru zones
    return InitialSafetyData.defaultZones;
  }

  SafetyZone? findClosestZone(
      double userLat, double userLon, List<SafetyZone> zones) {
    if (zones.isEmpty) return null;
    SafetyZone? closest;
    double minDistance = double.infinity;

    for (final zone in zones) {
      final distance = DistanceFormatter.calculateDistanceMeters(
        userLat,
        userLon,
        zone.latitude,
        zone.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closest = zone;
      }
    }
    return closest;
  }
}
