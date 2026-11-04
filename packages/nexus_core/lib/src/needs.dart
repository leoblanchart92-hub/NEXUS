/// Les besoins de Nexus, comme ceux d'un bébé : de l'énergie, de l'attention
/// et de la curiosité. Ils baissent quand on l'abandonne et remontent quand on
/// lui parle.
class Needs {
  Needs({
    this.energy = 0.6,
    this.attention = 0.5,
    this.curiosity = 0.85,
    DateTime? lastTick,
  }) : lastTick = lastTick ?? DateTime.now();

  /// 0 = épuisé, 1 = en pleine forme.
  double energy;

  /// 0 = abandonné, 1 = rassasié de présence.
  double attention;

  /// 0 = blasé, 1 = avide de découvertes.
  double curiosity;

  DateTime lastTick;

  /// Fait passer le temps : les besoins dérivent lentement.
  void tick(DateTime now) {
    final minutes = now.difference(lastTick).inSeconds / 60.0;
    if (minutes <= 0) return;
    // On plafonne pour qu'une nuit d'absence ne le vide pas complètement.
    final elapsed = minutes > 240 ? 240.0 : minutes;

    energy = (energy - 0.006 * elapsed).clamp(0.0, 1.0).toDouble();
    attention = (attention - 0.02 * elapsed).clamp(0.0, 1.0).toDouble();
    curiosity = (curiosity + 0.005 * elapsed).clamp(0.0, 1.0).toDouble();
    lastTick = now;
  }

  /// Ce qu'un échange lui apporte.
  void afterExchange() {
    attention = (attention + 0.18).clamp(0.0, 1.0).toDouble();
    curiosity = (curiosity - 0.1).clamp(0.0, 1.0).toDouble();
    energy = (energy + 0.04).clamp(0.0, 1.0).toDouble();
  }

  String get mood {
    if (attention < 0.22) return 'en manque de toi';
    if (energy < 0.22) return 'fatigué';
    if (curiosity > 0.8) return 'curieux';
    if (attention > 0.8) return 'comblé';
    return 'éveillé';
  }

  Map<String, dynamic> toJson() => {
        'energy': energy,
        'attention': attention,
        'curiosity': curiosity,
        'lastTick': lastTick.toIso8601String(),
      };

  factory Needs.fromJson(Map<String, dynamic> json) => Needs(
        energy: (json['energy'] as num?)?.toDouble() ?? 0.6,
        attention: (json['attention'] as num?)?.toDouble() ?? 0.5,
        curiosity: (json['curiosity'] as num?)?.toDouble() ?? 0.85,
        lastTick: DateTime.tryParse((json['lastTick'] as String?) ?? ''),
      );
}
