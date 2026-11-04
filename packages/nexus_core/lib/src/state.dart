import 'dart:convert';

import 'lexicon.dart';
import 'memory.dart';
import 'needs.dart';
import 'stage.dart';

/// Tout ce que Nexus est à un instant donné : son nom, son âge, son
/// expérience, son vocabulaire, sa mémoire et ses besoins.
class NexusState {
  NexusState({
    required this.name,
    DateTime? bornAt,
    this.xp = 0,
    this.exchanges = 0,
    this.affection = 0.5,
    this.assurance = 0.15,
    Lexicon? lexicon,
    Memory? memory,
    Needs? needs,
    DateTime? lastSeen,
  })  : bornAt = bornAt ?? DateTime.now(),
        lexicon = lexicon ?? Lexicon(),
        memory = memory ?? Memory(),
        needs = needs ?? Needs(),
        lastSeen = lastSeen ?? DateTime.now();

  String name;
  final DateTime bornAt;
  int xp;
  int exchanges;
  double affection;
  double assurance;
  final Lexicon lexicon;
  final Memory memory;
  final Needs needs;
  DateTime lastSeen;

  Stage get stage => stageForXp(xp);

  /// Progression (0 → 1) vers le stade suivant.
  double get stageProgress {
    final next = stage.nextStage;
    if (next == null) return 1;
    final span = next.threshold - stage.threshold;
    if (span <= 0) return 1;
    return ((xp - stage.threshold) / span).clamp(0.0, 1.0).toDouble();
  }

  /// Expérience restante avant le stade suivant.
  int get xpToNextStage {
    final next = stage.nextStage;
    if (next == null) return 0;
    final remaining = next.threshold - xp;
    return remaining < 0 ? 0 : remaining;
  }

  int get ageInDays {
    final days = DateTime.now().difference(bornAt).inDays;
    return days < 0 ? 0 : days;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'bornAt': bornAt.toIso8601String(),
        'xp': xp,
        'exchanges': exchanges,
        'affection': affection,
        'assurance': assurance,
        'lexicon': lexicon.toJson(),
        'memory': memory.toJson(),
        'needs': needs.toJson(),
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory NexusState.fromJson(Map<String, dynamic> json) {
    final rawLexicon = json['lexicon'];
    final rawMemory = json['memory'];
    final rawNeeds = json['needs'];

    return NexusState(
      name: (json['name'] as String?) ?? 'Nexus',
      bornAt: DateTime.tryParse((json['bornAt'] as String?) ?? ''),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      exchanges: (json['exchanges'] as num?)?.toInt() ?? 0,
      affection: (json['affection'] as num?)?.toDouble() ?? 0.5,
      assurance: (json['assurance'] as num?)?.toDouble() ?? 0.15,
      lexicon: rawLexicon is Map
          ? Lexicon.fromJson(Map<String, dynamic>.from(rawLexicon))
          : null,
      memory: rawMemory is Map
          ? Memory.fromJson(Map<String, dynamic>.from(rawMemory))
          : null,
      needs: rawNeeds is Map
          ? Needs.fromJson(Map<String, dynamic>.from(rawNeeds))
          : null,
      lastSeen: DateTime.tryParse((json['lastSeen'] as String?) ?? ''),
    );
  }

  String encode() => jsonEncode(toJson());

  factory NexusState.decode(String raw) =>
      NexusState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
