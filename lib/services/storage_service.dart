import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/claim.dart';

class StorageService {
  static const _claimsKey = 'insurance_claims_data';
  static const _themeKey = 'app_theme_mode';

  // Save all claims to local storage
  Future<void> saveClaims(List<Claim> claims) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = claims.map((c) => c.toJson()).toList();
      await prefs.setString(_claimsKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail - data won't persist but app still works
      print('Error saving claims: $e');
    }
  }

  // Load claims from local storage
  Future<List<Claim>> loadClaims() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_claimsKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((j) => Claim.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading claims: $e');
      return [];
    }
  }

  // Clear all stored claims
  Future<void> clearClaims() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_claimsKey);
    } catch (e) {
      print('Error clearing claims: $e');
    }
  }

  // Save theme preference
  Future<void> saveThemeMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Load theme preference
  Future<bool> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_themeKey) ?? false;
    } catch (e) {
      return false;
    }
  }
}
