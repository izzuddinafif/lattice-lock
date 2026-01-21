import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'ink_profile.dart';

part 'custom_ink_profile.g.dart';

/// Custom ink definition that users can configure
@HiveType(typeId: 100)
class CustomInkDefinition extends HiveObject {
  @HiveField(0)
  String id = ''; // Unique ID for the ink

  @HiveField(1)
  String name = ''; // e.g., "75°C Reactive"

  @HiveField(2)
  String code = ''; // e.g., "55xx", "75R"

  @HiveField(3)
  int colorValue = 0xFF000000; // ARGB color value stored as int

  @HiveField(4)
  String roleName = 'dataHigh'; // Store role as string for Hive

  @HiveField(5)
  int hexValue = 0xFF000000; // Hex color value for PDF generation

  CustomInkDefinition();

  /// Get the Color object from stored value
  Color get color => Color(colorValue);

  /// Set the Color object and store its value
  set color(Color value) {
    colorValue = value.toARGB32();
    hexValue = value.toARGB32(); // Ensure proper hex format
  }

  /// Get the InkRole from stored role name
  InkRole get role {
    try {
      return InkRole.values.firstWhere(
        (e) => e.name == roleName,
        orElse: () => InkRole.dataHigh,
      );
    } catch (e) {
      return InkRole.dataHigh;
    }
  }

  /// Set the InkRole and store its name
  set role(InkRole value) {
    roleName = value.name;
  }

  /// Create copy with modified fields
  CustomInkDefinition copyWith({
    String? id,
    String? name,
    String? code,
    Color? color,
    InkRole? role,
    int? hexValue,
  }) {
    final copy = CustomInkDefinition()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..code = code ?? this.code
      ..roleName = (role ?? this.role).name
      ..hexValue = hexValue ?? this.hexValue;

    if (color != null) {
      copy.color = color;
    } else {
      copy.colorValue = colorValue;
    }

    return copy;
  }

  /// Convert to standard InkDefinition
  InkDefinition toInkDefinition(int index) {
    return InkDefinition(
      id: index,
      name: name,
      label: code,
      visualColor: color,
      role: role,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomInkDefinition &&
      other.id == id &&
      other.name == name &&
      other.code == code &&
      other.colorValue == colorValue &&
      other.roleName == roleName;
  }

  @override
  int get hashCode => Object.hash(id, name, code, colorValue, roleName);
}

/// Custom material profile with user-configurable inks
@HiveType(typeId: 101)
class CustomMaterialProfile extends HiveObject {
  @HiveField(0)
  String id = ''; // Unique profile ID

  @HiveField(1)
  String name = ''; // Profile name

  @HiveField(2)
  List<CustomInkDefinition> inks = []; // List of custom inks

  @HiveField(3)
  DateTime createdAt = DateTime.now();

  @HiveField(4)
  DateTime modifiedAt = DateTime.now();

  @HiveField(5)
  bool isActive = false; // Whether this profile is currently active

  CustomMaterialProfile();

  /// Create standard profile as custom profile - 3 Color System
  static CustomMaterialProfile createStandardProfile() {
    final profile = CustomMaterialProfile()
      ..id = 'standard'
      ..name = 'Standard Set (Le Chatelier)'
      ..isActive = true
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now();

    profile.inks = [
      CustomInkDefinition()
        ..id = 'ink_0'
        ..name = '75°C Reactive'
        ..code = '75R'
        ..color = const Color(0xFF00E5FF)
        ..role = InkRole.dataHigh
        ..hexValue = 0xFF00E5FF,
      CustomInkDefinition()
        ..id = 'ink_1'
        ..name = '55°C Reactive'
        ..code = '55R'
        ..color = const Color(0xFF00BCD4)
        ..role = InkRole.dataLow
        ..hexValue = 0xFF00BCD4,
      CustomInkDefinition()
        ..id = 'ink_2'
        ..name = '35°C Marker'
        ..code = '35M'
        ..color = const Color(0xFF1DE9B6)
        ..role = InkRole.metadata
        ..hexValue = 0xFF1DE9B6,
    ];

    return profile;
  }

  /// Create copy with modified fields
  CustomMaterialProfile copyWith({
    String? id,
    String? name,
    List<CustomInkDefinition>? inks,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isActive,
  }) {
    final copy = CustomMaterialProfile()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..inks = inks ?? this.inks
      ..createdAt = createdAt ?? this.createdAt
      ..modifiedAt = modifiedAt ?? this.modifiedAt
      ..isActive = isActive ?? this.isActive;

    return copy;
  }

  /// Convert to standard MaterialProfile for generator compatibility
  MaterialProfile toMaterialProfile() {
    return MaterialProfile(
      name: name,
      inks: inks.asMap().entries.map((entry) {
        return entry.value.toInkDefinition(entry.key);
      }).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomMaterialProfile &&
      other.id == id &&
      other.name == name &&
      other.inks.length == inks.length;
  }

  @override
  int get hashCode => Object.hash(id, name, inks.length);
}
