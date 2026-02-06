import 'package:equatable/equatable.dart';

class SurvivalGuide extends Equatable {
  final String id;
  final String title;
  final String category;
  final String iconAsset;
  final int essentialSteps;
  final bool isAvailableOffline;
  final List<SurvivalStep> steps;
  final DateTime? lastUpdated;

  const SurvivalGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.iconAsset,
    required this.essentialSteps,
    this.isAvailableOffline = false,
    required this.steps,
    this.lastUpdated,
  });

  SurvivalGuide copyWith({
    String? id,
    String? title,
    String? category,
    String? iconAsset,
    int? essentialSteps,
    bool? isAvailableOffline,
    List<SurvivalStep>? steps,
    DateTime? lastUpdated,
  }) {
    return SurvivalGuide(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      iconAsset: iconAsset ?? this.iconAsset,
      essentialSteps: essentialSteps ?? this.essentialSteps,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
      steps: steps ?? this.steps,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'iconAsset': iconAsset,
      'essentialSteps': essentialSteps,
      'isAvailableOffline': isAvailableOffline,
      'steps': steps.map((s) => s.toJson()).toList(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory SurvivalGuide.fromJson(Map<String, dynamic> json) {
    return SurvivalGuide(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      iconAsset: json['iconAsset'] as String,
      essentialSteps: json['essentialSteps'] as int,
      isAvailableOffline: json['isAvailableOffline'] as bool? ?? false,
      steps: (json['steps'] as List)
          .map((s) => SurvivalStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        iconAsset,
        essentialSteps,
        isAvailableOffline,
        steps,
        lastUpdated,
      ];
}

class SurvivalStep extends Equatable {
  final int order;
  final String title;
  final String description;
  final String? imageAsset;

  const SurvivalStep({
    required this.order,
    required this.title,
    required this.description,
    this.imageAsset,
  });

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'title': title,
      'description': description,
      'imageAsset': imageAsset,
    };
  }

  factory SurvivalStep.fromJson(Map<String, dynamic> json) {
    return SurvivalStep(
      order: json['order'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      imageAsset: json['imageAsset'] as String?,
    );
  }

  @override
  List<Object?> get props => [order, title, description, imageAsset];
}
