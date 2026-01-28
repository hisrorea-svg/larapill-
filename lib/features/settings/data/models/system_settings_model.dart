import 'package:flutter/foundation.dart';

/// DTO (Data Transfer Object) for System Settings.
///
/// Responsible for:
/// - Key-value pair management
/// - Immutability and copyWith pattern
@immutable
class SystemSettingsModel {
  final String key;
  final String value;
  final String? description;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SystemSettingsModel({
    required this.key,
    required this.value,
    this.description,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Map (database row).
  factory SystemSettingsModel.fromMap(Map<String, dynamic> map) {
    return SystemSettingsModel(
      key: map['key'] as String,
      value: map['value'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'category': category,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with optional field replacements.
  SystemSettingsModel copyWith({
    String? key,
    String? value,
    String? description,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SystemSettingsModel(
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SystemSettingsModel('
        'key: $key, '
        'value: $value, '
        'category: $category)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemSettingsModel &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          description == other.description &&
          category == other.category &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      key.hashCode ^
      value.hashCode ^
      description.hashCode ^
      category.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
