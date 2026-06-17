import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';

class DataService {
  static const String _waterKey = 'water_records';
  static const String _weightKey = 'weight_records';
  static const String _profileKey = 'user_profile';

  // ========== Water Records ==========
  
  Future<List<WaterRecord>> getWaterRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_waterKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => WaterRecord.fromJson(e)).toList();
  }

  Future<List<WaterRecord>> getTodayWaterRecords() async {
    final records = await getWaterRecords();
    final today = DateTime.now();
    return records.where((r) =>
      r.time.year == today.year &&
      r.time.month == today.month &&
      r.time.day == today.day
    ).toList();
  }

  Future<int> getTodayWaterTotal() async {
    final records = await getTodayWaterRecords();
    return records.fold<int>(0, (sum, r) => sum + r.amount);
  }

  Future<void> addWaterRecord(WaterRecord record) async {
    final records = await getWaterRecords();
    records.add(record);
    await _saveWaterRecords(records);
  }

  Future<void> deleteWaterRecord(String id) async {
    final records = await getWaterRecords();
    records.removeWhere((r) => r.id == id);
    await _saveWaterRecords(records);
  }

  Future<void> _saveWaterRecords(List<WaterRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_waterKey, data);
  }

  // ========== Weight Records ==========
  
  Future<List<WeightRecord>> getWeightRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_weightKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => WeightRecord.fromJson(e)).toList();
  }

  Future<void> addWeightRecord(WeightRecord record) async {
    final records = await getWeightRecords();
    records.add(record);
    records.sort((a, b) => a.date.compareTo(b.date));
    await _saveWeightRecords(records);
  }

  Future<void> deleteWeightRecord(String id) async {
    final records = await getWeightRecords();
    records.removeWhere((r) => r.id == id);
    await _saveWeightRecords(records);
  }

  Future<void> _saveWeightRecords(List<WeightRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_weightKey, data);
  }

  // ========== User Profile ==========
  
  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profileKey);
    if (data == null) return UserProfile();
    return UserProfile.fromJson(jsonDecode(data));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // ========== Statistics ==========
  
  Future<Map<String, dynamic>> getWeeklyWaterStats() async {
    final records = await getWaterRecords();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final weekRecords = records.where((r) => r.time.isAfter(weekAgo)).toList();
    
    Map<String, int> daily = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.month}/${day.day}';
      daily[key] = 0;
    }
    
    for (final r in weekRecords) {
      final key = '${r.time.month}/${r.time.day}';
      daily[key] = (daily[key] ?? 0) + r.amount;
    }
    
    return daily;
  }

  Future<List<WeightRecord>> getMonthlyWeightRecords() async {
    final records = await getWeightRecords();
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    return records.where((r) => r.date.isAfter(monthAgo)).toList();
  }
}
