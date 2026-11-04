import 'dart:convert';

import 'memory.dart';

/// Tout ce que Nexus est à un instant donné : son nom, son âge, sa voix,
/// les règles écrites par son humain et sa mémoire.
///
/// Plus de stades, plus d'expérience : ce qui compte, c'est ce qu'elle a
/// retenu.
class NexusState {
  NexusState({
    required this.name,
    DateTime? bornAt,
    this.voiceEnabled = false,
    this.persona = '',
    Memory? memory,
  })  : bornAt = bornAt ?? DateTime.now(),
        memory = memory ?? Memory();

  String name;
  final DateTime bornAt;

  /// Si vrai, Nexus prononce ses réponses à voix haute.
  bool voiceEnabled;

  /// Les règles de personnalité écrites par son humain. Injectées dans
  /// chaque tour de parole : c'est ce qui la dirige.
  String persona;

  final Memory memory;

  int get ageInDays {
    final days = DateTime.now().difference(bornAt).inDays;
    return days < 0 ? 0 : days;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'bornAt': bornAt.toIso8601String(),
        'voiceEnabled': voiceEnabled,
        'persona': persona,
        'memory': memory.toJson(),
      };

  factory NexusState.fromJson(Map<String, dynamic> json) {
    final rawMemory = json['memory'];
    return NexusState(
      name: (json['name'] as String?) ?? 'Nexus',
      bornAt: DateTime.tryParse((json['bornAt'] as String?) ?? ''),
      voiceEnabled: (json['voiceEnabled'] as bool?) ?? false,
      persona: (json['persona'] as String?) ?? '',
      memory: rawMemory is Map
          ? Memory.fromJson(Map<String, dynamic>.from(rawMemory))
          : null,
    );
  }

  String encode() => jsonEncode(toJson());

  factory NexusState.decode(String raw) =>
      NexusState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
