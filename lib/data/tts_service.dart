import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// La voix de Nexus.
///
/// Tout passe par le moteur de synthèse vocale du téléphone : aucune donnée
/// n'est envoyée nulle part.
class TtsService {
  TtsService();

  final FlutterTts _tts = FlutterTts();
  bool _prepared = false;

  Future<void> _prepare() async {
    if (_prepared) return;
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
      await _tts.setVolume(1);
      _prepared = true;
    } catch (error) {
      debugPrint('TTS indisponible : $error');
    }
  }

  /// Prononce [text] en français. Ne lève jamais : une voix absente ne doit
  /// pas interrompre une conversation.
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      await _prepare();
      await _tts.stop();
      await _tts.speak(clean);
    } catch (error) {
      debugPrint('TTS erreur : $error');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (error) {
      debugPrint('TTS erreur : $error');
    }
  }
}
