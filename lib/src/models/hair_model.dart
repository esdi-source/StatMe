import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Art der Haarpflege
enum HairCareType {
  washed('Haare gewaschen', '🚿'),
  shampoo('Shampoo verwendet', '🧴'),
  conditioner('Conditioner verwendet', '💆'),
  waterOnly('Nur Wasser', '💧'),
  mask('Haarmaske', '🎭'),
  oil('Haaröl', '✨'),
  styling('Styling-Produkt', '💫'),
  custom('Sonstiges', '📝');

  final String label;
  final String emoji;
  const HairCareType(this.label, this.emoji);
}

/// Besondere Haarpflege-Ereignisse
enum HairEventType {
  haircut('Neuer Haarschnitt', '✂️'),
  coloring('Haartönung / Färben', '🎨'),
  styling('Styling / neue Frisur', '💇'),
  treatment('Behandlung / Kur', '💆'),
  other('Sonstiges', '📝');

  final String label;
  final String emoji;
  const HairEventType(this.label, this.emoji);
}

/// Produkt-Reaktion
enum ProductReaction {
  good('Gut', '👍'),
  neutral('Neutral', '😐'),
  bad('Schlecht', '👎');

  final String label;
  final String emoji;
  const ProductReaction(this.label, this.emoji);
}

/// Produktkategorie für Haarpflege
enum HairProductCategory {
  shampoo('Shampoo', '🧴'),
  conditioner('Conditioner', '💆'),
  mask('Maske', '🎭'),
  oil('Öl', '✨'),
  serum('Serum', '💧'),
  styling('Styling', '💫'),
  other('Sonstiges', '📝');

  final String label;
  final String emoji;
  const HairProductCategory(this.label, this.emoji);
}

// ============================================================================
// TÄGLICHE HAARPFLEGE
// ============================================================================

/// Ein täglicher Haarpflege-Eintrag
class HairCareEntry extends Equatable {
  final String id;
  final String oderId;
  final DateTime date;
  final List<HairCareType> careTypes;
  final List<String> customProducts;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HairCareEntry({
    required this.id,
    required this.oderId,
    required this.date,
    required this.careTypes,
    this.customProducts = const [],
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  HairCareEntry copyWith({
    String? id,
    String? oderId,
    DateTime? date,
    List<HairCareType>? careTypes,
    List<String>? customProducts,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HairCareEntry(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      date: date ?? this.date,
      careTypes: careTypes ?? this.careTypes,
      customProducts: customProducts ?? this.customProducts,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HairCareEntry.fromJson(Map<String, dynamic> json) {
    return HairCareEntry(
      id: json['id'] as String,
      oderId: json['oder_id'] as String,
      date: DateTime.parse(json['date'] as String),
      careTypes: (json['care_types'] as List<dynamic>?)
          ?.map((t) => HairCareType.values.firstWhere(
                (c) => c.name == t,
                orElse: () => HairCareType.custom,
              ))
          .toList() ??
          [],
      customProducts: (json['custom_products'] as List<dynamic>?)
          ?.map((p) => p as String)
          .toList() ??
          [],
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oder_id': oderId,
      'date': date.toIso8601String().split('T').first,
      'care_types': careTypes.map((t) => t.name).toList(),
      'custom_products': customProducts,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, oderId, date, careTypes, customProducts, note, createdAt, updatedAt];
}

// ============================================================================
// BESONDERE EREIGNISSE
// ============================================================================

/// Ein besonderes Haarpflege-Ereignis (Haarschnitt, Färben, etc.)
class HairEvent extends Equatable {
  final String id;
  final String oderId;
  final DateTime date;
  final HairEventType eventType;
  final String? title;
  final String? note;
  final String? salonName;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HairEvent({
    required this.id,
    required this.oderId,
    required this.date,
    required this.eventType,
    this.title,
    this.note,
    this.salonName,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
  });

  HairEvent copyWith({
    String? id,
    String? oderId,
    DateTime? date,
    HairEventType? eventType,
    String? title,
    String? note,
    String? salonName,
    double? cost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HairEvent(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      date: date ?? this.date,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      note: note ?? this.note,
      salonName: salonName ?? this.salonName,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HairEvent.fromJson(Map<String, dynamic> json) {
    return HairEvent(
      id: json['id'] as String,
      oderId: json['oder_id'] as String,
      date: DateTime.parse(json['date'] as String),
      eventType: HairEventType.values.firstWhere(
        (t) => t.name == json['event_type'],
        orElse: () => HairEventType.other,
      ),
      title: json['title'] as String?,
      note: json['note'] as String?,
      salonName: json['salon_name'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oder_id': oderId,
      'date': date.toIso8601String().split('T').first,
      'event_type': eventType.name,
      'title': title,
      'note': note,
      'salon_name': salonName,
      'cost': cost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, oderId, date, eventType, title, note, salonName, cost, createdAt, updatedAt];
}

// ============================================================================
// PFLEGEPRODUKTE
// ============================================================================

/// Ein Haarpflege-Produkt
class HairProduct extends Equatable {
  final String id;
  final String oderId;
  final String name;
  final HairProductCategory category;
  final String? brand;
  final ProductReaction? reaction;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HairProduct({
    required this.id,
    required this.oderId,
    required this.name,
    required this.category,
    this.brand,
    this.reaction,
    this.note,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  HairProduct copyWith({
    String? id,
    String? oderId,
    String? name,
    HairProductCategory? category,
    String? brand,
    ProductReaction? reaction,
    String? note,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HairProduct(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      reaction: reaction ?? this.reaction,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HairProduct.fromJson(Map<String, dynamic> json) {
    return HairProduct(
      id: json['id'] as String,
      oderId: json['oder_id'] as String,
      name: json['name'] as String,
      category: HairProductCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => HairProductCategory.other,
      ),
      brand: json['brand'] as String?,
      reaction: json['reaction'] != null
          ? ProductReaction.values.firstWhere(
              (r) => r.name == json['reaction'],
              orElse: () => ProductReaction.neutral,
            )
          : null,
      note: json['note'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oder_id': oderId,
      'name': name,
      'category': category.name,
      'brand': brand,
      'reaction': reaction?.name,
      'note': note,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, oderId, name, category, brand, reaction, note, isActive, createdAt, updatedAt];
}

// ============================================================================
// STATISTIK HILFKLASSE
// ============================================================================

/// Haarpflege-Statistik für einen Zeitraum
class HairCareStatistics {
  final int totalWashDays;
  final int shampooDays;
  final int conditionerDays;
  final int waterOnlyDays;
  final int totalEvents;
  final Map<HairCareType, int> careTypeFrequency;
  final List<HairEvent> recentEvents;
  final int daysSinceLastWash;
  final int daysSinceLastHaircut;

  const HairCareStatistics({
    required this.totalWashDays,
    required this.shampooDays,
    required this.conditionerDays,
    required this.waterOnlyDays,
    required this.totalEvents,
    required this.careTypeFrequency,
    required this.recentEvents,
    required this.daysSinceLastWash,
    required this.daysSinceLastHaircut,
  });

  factory HairCareStatistics.empty() {
    return const HairCareStatistics(
      totalWashDays: 0,
      shampooDays: 0,
      conditionerDays: 0,
      waterOnlyDays: 0,
      totalEvents: 0,
      careTypeFrequency: {},
      recentEvents: [],
      daysSinceLastWash: -1,
      daysSinceLastHaircut: -1,
    );
  }

  factory HairCareStatistics.calculate({
    required List<HairCareEntry> entries,
    required List<HairEvent> events,
    int days = 7,
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final recentEntries = entries.where((e) => e.date.isAfter(startDate)).toList();
    final recentEvents = events.where((e) => e.date.isAfter(startDate)).toList();

    // Zähle Care Types
    final Map<HairCareType, int> frequency = {};
    int washDays = 0;
    int shampooDays = 0;
    int conditionerDays = 0;
    int waterOnlyDays = 0;

    for (final entry in recentEntries) {
      if (entry.careTypes.contains(HairCareType.washed)) washDays++;
      if (entry.careTypes.contains(HairCareType.shampoo)) shampooDays++;
      if (entry.careTypes.contains(HairCareType.conditioner)) conditionerDays++;
      if (entry.careTypes.contains(HairCareType.waterOnly)) waterOnlyDays++;
      
      for (final type in entry.careTypes) {
        frequency[type] = (frequency[type] ?? 0) + 1;
      }
    }

    // Berechne Tage seit letzter Wäsche
    int daysSinceLastWash = -1;
    final washedEntries = entries.where((e) => 
      e.careTypes.contains(HairCareType.washed) || 
      e.careTypes.contains(HairCareType.shampoo) ||
      e.careTypes.contains(HairCareType.waterOnly)
    ).toList();
    if (washedEntries.isNotEmpty) {
      washedEntries.sort((a, b) => b.date.compareTo(a.date));
      daysSinceLastWash = now.difference(washedEntries.first.date).inDays;
    }

    // Berechne Tage seit letztem Haarschnitt
    int daysSinceLastHaircut = -1;
    final haircutEvents = events.where((e) => e.eventType == HairEventType.haircut).toList();
    if (haircutEvents.isNotEmpty) {
      haircutEvents.sort((a, b) => b.date.compareTo(a.date));
      daysSinceLastHaircut = now.difference(haircutEvents.first.date).inDays;
    }

    return HairCareStatistics(
      totalWashDays: washDays,
      shampooDays: shampooDays,
      conditionerDays: conditionerDays,
      waterOnlyDays: waterOnlyDays,
      totalEvents: recentEvents.length,
      careTypeFrequency: frequency,
      recentEvents: recentEvents,
      daysSinceLastWash: daysSinceLastWash,
      daysSinceLastHaircut: daysSinceLastHaircut,
    );
  }
}
