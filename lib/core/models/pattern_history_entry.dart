import 'package:equatable/equatable.dart';

/// Pattern history entry model for storing saved encryption patterns
class PatternHistoryEntry extends Equatable {
  final String id;
  final String inputText;
  final String algorithm;
  final int gridSize;
  final String material;
  final List<int> encryptedPattern;
  final DateTime timestamp;
  final String? notes;
  final Map<String, dynamic> metadata;

  const PatternHistoryEntry({
    required this.id,
    required this.inputText,
    required this.algorithm,
    required this.gridSize,
    required this.material,
    required this.encryptedPattern,
    required this.timestamp,
    this.notes,
    this.metadata = const {},
  });

  PatternHistoryEntry.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        inputText = map['inputText'] as String,
        algorithm = map['algorithm'] as String,
        gridSize = map['gridSize'] as int,
        material = map['material'] as String,
        encryptedPattern = (map['encryptedPattern'] as List<dynamic>)
            .map((e) => e as int)
            .toList(),
        timestamp = DateTime.parse(map['timestamp'] as String),
        notes = map['notes'] as String?,
        metadata = Map<String, dynamic>.from(map['metadata'] as Map<String, dynamic>? ?? {});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inputText': inputText,
      'algorithm': algorithm,
      'gridSize': gridSize,
      'material': material,
      'encryptedPattern': encryptedPattern,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  PatternHistoryEntry copyWith({
    String? id,
    String? inputText,
    String? algorithm,
    int? gridSize,
    String? material,
    List<int>? encryptedPattern,
    DateTime? timestamp,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return PatternHistoryEntry(
      id: id ?? this.id,
      inputText: inputText ?? this.inputText,
      algorithm: algorithm ?? this.algorithm,
      gridSize: gridSize ?? this.gridSize,
      material: material ?? this.material,
      encryptedPattern: encryptedPattern ?? this.encryptedPattern,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        inputText,
        algorithm,
        gridSize,
        material,
        encryptedPattern,
        timestamp,
        notes,
        metadata,
      ];

  @override
  String toString() {
    return 'PatternHistoryEntry(id: $id, inputText: $inputText, algorithm: $algorithm, gridSize: $gridSize, material: $material, timestamp: $timestamp)';
  }
}