import 'package:flutter/material.dart';

enum InkRole { dataHigh, dataLow, fake, metadata }

class InkDefinition {
  final int id;           // 0-4
  final String name;      // e.g., "75°C (Reactive)"
  final String label;     // Simbol di PDF (e.g., "75C")
  final Color visualColor; // Warna visual di layar HP (Cyan/Blue)
  final InkRole role;     // Peran logikanya

  const InkDefinition({
    required this.id,
    required this.name,
    required this.label,
    required this.visualColor,
    required this.role,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InkDefinition &&
      other.id == id &&
      other.name == name &&
      other.label == label &&
      other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, label, role);
}

class MaterialProfile {
  final String name;
  final List<InkDefinition> inks;

  const MaterialProfile({required this.name, required this.inks});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialProfile &&
      other.name == name &&
      _listEquals(other.inks, inks);
  }

  @override
  int get hashCode => Object.hash(name, inks);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Profil Default sesuai Paper Paundra
  static const MaterialProfile standardSet = MaterialProfile(
    name: "Standard Set A (Le Chatelier)",
    inks: [
      InkDefinition(id: 0, name: "75°C Reactive", label: "75R", visualColor: Colors.cyanAccent, role: InkRole.dataHigh),
      InkDefinition(id: 1, name: "75°C Protected", label: "75P", visualColor: Colors.cyan, role: InkRole.fake),
      InkDefinition(id: 2, name: "55°C Reactive", label: "55R", visualColor: Colors.tealAccent, role: InkRole.dataLow),
      InkDefinition(id: 3, name: "55°C Protected", label: "55P", visualColor: Colors.teal, role: InkRole.fake),
      InkDefinition(id: 4, name: "35°C Marker", label: "35M", visualColor: Colors.blue, role: InkRole.metadata),
    ],
  );
}