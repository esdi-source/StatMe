import 'package:equatable/equatable.dart';

class SettingsModel extends Equatable {
  final String id;
  final String userId;
  final int dailyWaterGoalMl;
  final int dailyCalorieGoal;
  final int dailyStepsGoal;
  final String timezone;
  final String locale;
  final bool notificationsEnabled;
  final bool darkMode;

  const SettingsModel({
    required this.id,
    required this.userId,
    this.dailyWaterGoalMl = 2500,
    this.dailyCalorieGoal = 2000,
    this.dailyStepsGoal = 10000,
    this.timezone = 'Europe/Berlin',
    this.locale = 'de_DE',
    this.notificationsEnabled = true,
    this.darkMode = false,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyWaterGoalMl: json['daily_water_goal_ml'] as int? ?? 2500,
      dailyCalorieGoal: json['daily_calorie_goal'] as int? ?? 2000,
      dailyStepsGoal: json['daily_steps_goal'] as int? ?? 10000,
      timezone: json['timezone'] as String? ?? 'Europe/Berlin',
      locale: json['locale'] as String? ?? 'de_DE',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      darkMode: json['dark_mode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_water_goal_ml': dailyWaterGoalMl,
      'daily_calorie_goal': dailyCalorieGoal,
      'daily_steps_goal': dailyStepsGoal,
      'timezone': timezone,
      'locale': locale,
      'notifications_enabled': notificationsEnabled,
      'dark_mode': darkMode,
    };
  }

  SettingsModel copyWith({
    String? id,
    String? userId,
    int? dailyWaterGoalMl,
    int? dailyCalorieGoal,
    int? dailyStepsGoal,
    String? timezone,
    String? locale,
    bool? notificationsEnabled,
    bool? darkMode,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        dailyWaterGoalMl,
        dailyCalorieGoal,
        dailyStepsGoal,
        timezone,
        locale,
        notificationsEnabled,
        darkMode,
      ];
}
