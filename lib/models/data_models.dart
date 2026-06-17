import 'dart:convert';

class WaterRecord {
  final String id;
  final int amount; // ml
  final DateTime time;

  WaterRecord({
    required this.id,
    required this.amount,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'time': time.toIso8601String(),
  };

  factory WaterRecord.fromJson(Map<String, dynamic> json) => WaterRecord(
    id: json['id'],
    amount: json['amount'],
    time: DateTime.parse(json['time']),
  );
}

class WeightRecord {
  final String id;
  final double weight; // kg
  final DateTime date;
  final String? note;

  WeightRecord({
    required this.id,
    required this.weight,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'weight': weight,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
    id: json['id'],
    weight: json['weight'].toDouble(),
    date: DateTime.parse(json['date']),
    note: json['note'],
  );
}

class UserProfile {
  double? height; // cm
  double? targetWeight; // kg
  int dailyWaterGoal; // ml
  String? wakeUpTime;
  String? sleepTime;
  bool isPremium;

  UserProfile({
    this.height,
    this.targetWeight,
    this.dailyWaterGoal = 2000,
    this.wakeUpTime = '08:00',
    this.sleepTime = '23:00',
    this.isPremium = false,
  });

  Map<String, dynamic> toJson() => {
    'height': height,
    'targetWeight': targetWeight,
    'dailyWaterGoal': dailyWaterGoal,
    'wakeUpTime': wakeUpTime,
    'sleepTime': sleepTime,
    'isPremium': isPremium,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    height: json['height']?.toDouble(),
    targetWeight: json['targetWeight']?.toDouble(),
    dailyWaterGoal: json['dailyWaterGoal'] ?? 2000,
    wakeUpTime: json['wakeUpTime'] ?? '08:00',
    sleepTime: json['sleepTime'] ?? '23:00',
    isPremium: json['isPremium'] ?? false,
  );

  double? get bmi {
    if (height == null) return null;
    final h = height! / 100;
    // BMI 需要最新体重，这里只返回身高
    return null;
  }
}
