import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Bewertungsskala für Hautzustand
enum SkinCondition {
  veryBad(1, 'Sehr schlecht', '😞'),
  bad(2, 'Schlecht', '😕'),
  neutral(3, 'Neutral', '😐'),
  good(4, 'Gut', '🙂'),
  veryGood(5, 'Sehr gut', '😊');

  final int value;
  final String label;
  final String emoji;
  const SkinCondition(this.value, this.label, this.emoji);
}

/// Gesichtsbereiche
enum FaceArea {
  forehead('Stirn'),
  cheeks('Wangen'),
  chin('Kinn'),
  nose('Nase'),
  eyeArea('Augenbereich');

  final String label;
  const FaceArea(this.label);
}

/// Hautattribute
enum SkinAttribute {
  dry('Trocken'),
  oily('Fettig'),
  blemished('Unrein'),
  irritated('Gereizt'),
  sensitive('Empfindlich');

  final String label;
  const SkinAttribute(this.label);
}

/// Produktkategorie
enum SkinProductCategory {
  cleanser('Reiniger'),
  toner('Toner'),
  serum('Serum'),
  moisturizer('Creme'),
  sunscreen('Sonnenschutz'),
  mask('Maske'),
  other('Sonstiges');

  final String label;
  const SkinProductCategory(this.label);
}

/// Produktverträglichkeit
enum ProductTolerance {
  good('Gut vertragen'),
  neutral('Neutral'),
  bad('Schlecht vertragen');

  final String label;
  const ProductTolerance(this.label);
}

// ============================================================================
// TÄGLICHER HAUTZUSTAND
// ============================================================================

/// Ein täglicher Hautzustand-Eintrag
class SkinEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final SkinCondition overallCondition;
  final Map<FaceArea, SkinCondition>? areaConditions;
  final List<SkinAttribute> attributes;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SkinEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.overallCondition,
    this.areaConditions,
    this.attributes = const [],
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  SkinEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    SkinCondition? overallCondition,
    Map<FaceArea, SkinCondition>? areaConditions,
    List<SkinAttribute>? attributes,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkinEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      overallCondition: overallCondition ?? this.overallCondition,
      areaConditions: areaConditions ?? this.areaConditions,
      attributes: attributes ?? this.attributes,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SkinEntry.fromJson(Map<String, dynamic> json) {
    Map<FaceArea, SkinCondition>? areas;
    if (json['area_conditions'] != null) {
      final areaJson = json['area_conditions'] as Map<String, dynamic>;
      areas = {};
      for (final entry in areaJson.entries) {
        final area = FaceArea.values.firstWhere((a) => a.name == entry.key);
        final condition = SkinCondition.values.firstWhere((c) => c.name == entry.value);
        areas[area] = condition;
      }
    }

    return SkinEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      overallCondition: SkinCondition.values.firstWhere(
        (c) => c.name == json['overall_condition'],
        orElse: () => SkinCondition.neutral,
      ),
      areaConditions: areas,
      attributes: (json['attributes'] as List<dynamic>?)
          ?.map((a) => SkinAttribute.values.firstWhere((s) => s.name == a))
          .toList() ?? [],
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, String>? areasJson;
    if (areaConditions != null) {
      areasJson = {};
      for (final entry in areaConditions!.entries) {
        areasJson[entry.key.name] = entry.value.name;
      }
    }

    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'overall_condition': overallCondition.name,
      'area_conditions': areasJson,
      'attributes': attributes.map((a) => a.name).toList(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, date, overallCondition, areaConditions, attributes, note, createdAt, updatedAt];
}

// ============================================================================
// PFLEGEROUTINE
// ============================================================================

/// Ein Pflegeschritt in der Routine
class SkinCareStep extends Equatable {
  final String id;
  final String userId;
  final String name;
  final int order;
  final bool isDaily;
  final List<int>? weekdays; // 1-7 für Mo-So, null = täglich
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SkinCareStep({
    required this.id,
    required this.userId,
    required this.name,
    this.order = 0,
    this.isDaily = true,
    this.weekdays,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  SkinCareStep copyWith({
    String? id,
    String? userId,
    String? name,
    int? order,
    bool? isDaily,
    List<int>? weekdays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkinCareStep(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      order: order ?? this.order,
      isDaily: isDaily ?? this.isDaily,
      weekdays: weekdays ?? this.weekdays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SkinCareStep.fromJson(Map<String, dynamic> json) {
    return SkinCareStep(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      order: json['order'] as int? ?? 0,
      isDaily: json['is_daily'] as bool? ?? true,
      weekdays: (json['weekdays'] as List<dynamic>?)?.cast<int>(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'order': order,
      'is_daily': isDaily,
      'weekdays': weekdays,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, name, order, isDaily, weekdays, isActive, createdAt, updatedAt];
}

/// Ein erledigter Pflegeschritt
class SkinCareCompletion extends Equatable {
  final String id;
  final String userId;
  final String stepId;
  final DateTime date;
  final DateTime completedAt;

  const SkinCareCompletion({
    required this.id,
    required this.userId,
    required this.stepId,
    required this.date,
    required this.completedAt,
  });

  factory SkinCareCompletion.fromJson(Map<String, dynamic> json) {
    return SkinCareCompletion(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      stepId: json['step_id'] as String,
      date: DateTime.parse(json['date'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'step_id': stepId,
      'date': date.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, stepId, date, completedAt];
}

// ============================================================================
// PRODUKTE
// ============================================================================

/// Ein Hautpflegeprodukt
class SkinProduct extends Equatable {
  final String id;
  final String userId;
  final String name;
  final SkinProductCategory category;
  final ProductTolerance? tolerance;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SkinProduct({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.tolerance,
    this.note,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  SkinProduct copyWith({
    String? id,
    String? userId,
    String? name,
    SkinProductCategory? category,
    ProductTolerance? tolerance,
    String? note,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkinProduct(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      tolerance: tolerance ?? this.tolerance,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SkinProduct.fromJson(Map<String, dynamic> json) {
    return SkinProduct(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: SkinProductCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SkinProductCategory.other,
      ),
      tolerance: json['tolerance'] != null
          ? ProductTolerance.values.firstWhere((t) => t.name == json['tolerance'])
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
      'user_id': userId,
      'name': name,
      'category': category.name,
      'tolerance': tolerance?.name,
      'note': note,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, name, category, tolerance, note, isActive, createdAt, updatedAt];
}

// ============================================================================
// NOTIZEN
// ============================================================================

/// Eine Hautnotiz
class SkinNote extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final String content;
  final DateTime createdAt;

  const SkinNote({
    required this.id,
    required this.userId,
    required this.date,
    required this.content,
    required this.createdAt,
  });

  factory SkinNote.fromJson(Map<String, dynamic> json) {
    return SkinNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, date, content, createdAt];
}

// ============================================================================
// FOTOS (Metadaten, nicht das Bild selbst)
// ============================================================================

/// Metadaten für ein Hautfoto
class SkinPhoto extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final String localPath; // Lokaler Pfad zum Foto
  final String? note;
  final DateTime createdAt;

  const SkinPhoto({
    required this.id,
    required this.userId,
    required this.date,
    required this.localPath,
    this.note,
    required this.createdAt,
  });

  factory SkinPhoto.fromJson(Map<String, dynamic> json) {
    return SkinPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      localPath: json['local_path'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'local_path': localPath,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, date, localPath, note, createdAt];
}
