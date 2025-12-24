/// Demo Data Service
/// Provides realistic fake data for demo mode
library;

import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DemoDataService {
  static const _uuid = Uuid();
  static const String demoUserId = 'demo-user-001';
  
  static UserModel getDemoUser() {
    return UserModel(
      id: demoUserId,
      email: 'demo@statme.app',
      displayName: 'Demo Benutzer',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
  }
  
  static SettingsModel getDemoSettings() {
    return SettingsModel(
      id: _uuid.v4(),
      userId: demoUserId,
      dailyWaterGoalMl: 2500,
      dailyCalorieGoal: 2000,
      dailyStepsGoal: 10000,
      timezone: 'Europe/Berlin',
      locale: 'de_DE',
      notificationsEnabled: true,
      darkMode: false,
    );
  }
  
  static List<TodoModel> getDemoTodos() {
    final now = DateTime.now();
    return [
      TodoModel(
        id: _uuid.v4(),
        userId: demoUserId,
        title: 'Morgenroutine',
        description: 'Stretching, Meditation, Frühstück',
        startDate: now.subtract(const Duration(days: 7)),
        rruleText: 'FREQ=DAILY',
        priority: TodoPriority.high,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      TodoModel(
        id: _uuid.v4(),
        userId: demoUserId,
        title: 'Wasser trinken',
        description: '8 Gläser Wasser am Tag',
        startDate: now.subtract(const Duration(days: 14)),
        rruleText: 'FREQ=DAILY',
        priority: TodoPriority.medium,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
      TodoModel(
        id: _uuid.v4(),
        userId: demoUserId,
        title: 'Wöchentlicher Sport',
        description: 'Joggen oder Fitnessstudio',
        startDate: now.subtract(const Duration(days: 21)),
        rruleText: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        priority: TodoPriority.high,
        createdAt: now.subtract(const Duration(days: 21)),
        updatedAt: now.subtract(const Duration(days: 21)),
      ),
      TodoModel(
        id: _uuid.v4(),
        userId: demoUserId,
        title: 'Arzttermin',
        description: 'Jährliche Vorsorgeuntersuchung',
        startDate: now.add(const Duration(days: 30)),
        priority: TodoPriority.medium,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      TodoModel(
        id: _uuid.v4(),
        userId: demoUserId,
        title: 'Vitamine nehmen',
        description: 'Vitamin D und B12',
        startDate: now.subtract(const Duration(days: 30)),
        rruleText: 'FREQ=DAILY',
        priority: TodoPriority.low,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      TodoModel(
        id: _uuid.v4(),
        userId: demoUserId,
        title: 'Monatliche Reflexion',
        description: 'Ziele überprüfen und anpassen',
        startDate: now.subtract(const Duration(days: 60)),
        rruleText: 'FREQ=MONTHLY;BYMONTHDAY=1',
        priority: TodoPriority.medium,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 60)),
      ),
    ];
  }
  
  static List<TodoOccurrence> getDemoOccurrences(List<TodoModel> todos) {
    final occurrences = <TodoOccurrence>[];
    final now = DateTime.now();
    
    for (final todo in todos) {
      // Create occurrences for the last 7 days and next 7 days
      for (int i = -7; i <= 7; i++) {
        final dueDate = now.add(Duration(days: i));
        occurrences.add(TodoOccurrence(
          id: _uuid.v4(),
          todoId: todo.id,
          userId: demoUserId,
          dueAt: DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0),
          done: i < 0 ? (i.abs() % 3 != 0) : false, // Some past ones done
          reminderSent: i < 0,
        ));
      }
    }
    
    return occurrences;
  }
  
  static List<ProductModel> getDemoProducts() {
    final now = DateTime.now();
    return [
      ProductModel(
        id: _uuid.v4(),
        barcode: '4001475104800',
        productName: 'Haferflocken',
        kcalPer100g: 372,
        proteinPer100g: 13.5,
        carbsPer100g: 58.7,
        fatPer100g: 7.0,
        fiberPer100g: 10.0,
        lastChecked: now,
      ),
      ProductModel(
        id: _uuid.v4(),
        barcode: '4000400132857',
        productName: 'Vollmilch 3,5%',
        kcalPer100g: 64,
        proteinPer100g: 3.3,
        carbsPer100g: 4.8,
        fatPer100g: 3.5,
        fiberPer100g: 0,
        lastChecked: now,
      ),
      ProductModel(
        id: _uuid.v4(),
        barcode: '4005500050606',
        productName: 'Vollkornbrot',
        kcalPer100g: 219,
        proteinPer100g: 8.4,
        carbsPer100g: 37.6,
        fatPer100g: 3.0,
        fiberPer100g: 8.5,
        lastChecked: now,
      ),
      ProductModel(
        id: _uuid.v4(),
        barcode: '4000521003456',
        productName: 'Banane',
        kcalPer100g: 89,
        proteinPer100g: 1.1,
        carbsPer100g: 22.8,
        fatPer100g: 0.3,
        fiberPer100g: 2.6,
        lastChecked: now,
      ),
      ProductModel(
        id: _uuid.v4(),
        barcode: '4006040003211',
        productName: 'Hühnerbrust',
        kcalPer100g: 165,
        proteinPer100g: 31.0,
        carbsPer100g: 0,
        fatPer100g: 3.6,
        fiberPer100g: 0,
        lastChecked: now,
      ),
      ProductModel(
        id: _uuid.v4(),
        barcode: '4002359001234',
        productName: 'Griechischer Joghurt',
        kcalPer100g: 97,
        proteinPer100g: 9.0,
        carbsPer100g: 3.6,
        fatPer100g: 5.0,
        fiberPer100g: 0,
        lastChecked: now,
      ),
      ProductModel(
        id: _uuid.v4(),
        barcode: '4008400401234',
        productName: 'Reis (gekocht)',
        kcalPer100g: 130,
        proteinPer100g: 2.7,
        carbsPer100g: 28.2,
        fatPer100g: 0.3,
        fiberPer100g: 0.4,
        lastChecked: now,
      ),
      ProductModel(
        id: _uuid.v4(),
        barcode: '4006381001234',
        productName: 'Lachs',
        kcalPer100g: 208,
        proteinPer100g: 20.4,
        carbsPer100g: 0,
        fatPer100g: 13.4,
        fiberPer100g: 0,
        lastChecked: now,
      ),
    ];
  }
  
  static List<FoodLogModel> getDemoFoodLogs() {
    final now = DateTime.now();
    final logs = <FoodLogModel>[];
    final products = getDemoProducts();
    
    // Generate food logs for the last 7 days
    for (int day = 0; day < 7; day++) {
      final date = now.subtract(Duration(days: day));
      
      // Breakfast
      logs.add(FoodLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        productName: 'Haferflocken',
        grams: 80,
        calories: (372 / 100) * 80,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 8, 0),
      ));
      logs.add(FoodLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        productName: 'Vollmilch 3,5%',
        grams: 200,
        calories: (64 / 100) * 200,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 8, 5),
      ));
      logs.add(FoodLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        productName: 'Banane',
        grams: 120,
        calories: (89 / 100) * 120,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 8, 10),
      ));
      
      // Lunch
      logs.add(FoodLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        productName: 'Hühnerbrust',
        grams: 150,
        calories: (165 / 100) * 150,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 12, 30),
      ));
      logs.add(FoodLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        productName: 'Reis (gekocht)',
        grams: 180,
        calories: (130 / 100) * 180,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 12, 30),
      ));
      
      // Dinner
      logs.add(FoodLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        productName: day % 2 == 0 ? 'Lachs' : 'Vollkornbrot',
        grams: day % 2 == 0 ? 180 : 100,
        calories: day % 2 == 0 ? (208 / 100) * 180 : (219 / 100) * 100,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 19, 0),
      ));
    }
    
    return logs;
  }
  
  static List<WaterLogModel> getDemoWaterLogs() {
    final now = DateTime.now();
    final logs = <WaterLogModel>[];
    
    // Generate water logs for the last 7 days
    for (int day = 0; day < 7; day++) {
      final date = now.subtract(Duration(days: day));
      final dailyTarget = 2000 + (day * 100); // Vary intake
      
      // Morning
      logs.add(WaterLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        ml: 300,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 7, 0),
      ));
      
      // Throughout the day
      logs.add(WaterLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        ml: 250,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 10, 0),
      ));
      logs.add(WaterLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        ml: 300,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 12, 30),
      ));
      logs.add(WaterLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        ml: 250,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 15, 0),
      ));
      logs.add(WaterLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        ml: 300,
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 18, 0),
      ));
      logs.add(WaterLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        ml: 200 + (day * 50),
        date: date,
        createdAt: DateTime(date.year, date.month, date.day, 21, 0),
      ));
    }
    
    return logs;
  }
  
  static List<StepsLogModel> getDemoStepsLogs() {
    final now = DateTime.now();
    final logs = <StepsLogModel>[];
    
    // Generate step logs for the last 30 days
    for (int day = 0; day < 30; day++) {
      final date = now.subtract(Duration(days: day));
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      
      // Weekend = more steps (hiking, activities)
      // Weekday = moderate steps (work commute)
      final baseSteps = isWeekend ? 12000 : 8000;
      final variance = (day * 317) % 4000; // Pseudo-random variance
      
      logs.add(StepsLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        steps: baseSteps + variance,
        date: date,
        source: 'manual',
      ));
    }
    
    return logs;
  }
  
  static List<SleepLogModel> getDemoSleepLogs() {
    final now = DateTime.now();
    final logs = <SleepLogModel>[];
    
    // Generate sleep logs for the last 14 days
    for (int day = 0; day < 14; day++) {
      final date = now.subtract(Duration(days: day));
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      
      // Weekend = sleep longer
      final startHour = isWeekend ? 23 : 22;
      final startMinute = 30 + (day % 30);
      final endHour = isWeekend ? 9 : 6;
      final endMinute = 30 + (day * 3) % 30;
      
      final startTs = DateTime(
        date.year, date.month, date.day - 1, startHour, startMinute,
      );
      final endTs = DateTime(date.year, date.month, date.day, endHour, endMinute);
      
      logs.add(SleepLogModel.calculate(
        id: _uuid.v4(),
        userId: demoUserId,
        startTs: startTs,
        endTs: endTs,
      ));
    }
    
    return logs;
  }
  
  static List<MoodLogModel> getDemoMoodLogs() {
    final now = DateTime.now();
    final logs = <MoodLogModel>[];
    
    final moodNotes = [
      'Guter Tag!',
      'Etwas müde',
      'Produktiv gewesen',
      'Schönes Wetter genossen',
      'Stress bei der Arbeit',
      'Entspannter Abend',
      'Sport gemacht - fühle mich super!',
      null,
      'Zeit mit Freunden verbracht',
      null,
    ];
    
    // Generate mood logs for the last 14 days
    for (int day = 0; day < 14; day++) {
      final date = now.subtract(Duration(days: day));
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      
      // Weekend = generally happier
      final baseMood = isWeekend ? 7 : 6;
      final variance = (day * 3) % 4 - 1; // -1 to 2
      final mood = (baseMood + variance).clamp(1, 10);
      
      logs.add(MoodLogModel(
        id: _uuid.v4(),
        userId: demoUserId,
        mood: mood,
        date: date,
        note: moodNotes[day % moodNotes.length],
      ));
    }
    
    return logs;
  }
}
