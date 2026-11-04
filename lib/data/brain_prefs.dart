import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Retient, dans un petit fichier à part, quel cerveau était allumé.
///
/// C'est volontairement minuscule et sans dépendance : un identifiant, dans le
/// stockage privé de l'application.
class BrainPrefs {
  BrainPrefs._();

  static const String _fileName = 'brain.json';

  static Future<File> _file() async {
    final Directory base = await getApplicationSupportDirectory();
    return File('${base.path}/$_fileName');
  }

  /// L'identifiant du dernier cerveau allumé, ou null.
  static Future<String?> loadActiveId() async {
    try {
      final File file = await _file();
      if (!await file.exists()) return null;
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is Map && decoded['active'] is String) {
        return decoded['active'] as String;
      }
      return null;
    } catch (_) {
      // Un fichier illisible ne doit pas empêcher Nexus de démarrer.
      return null;
    }
  }

  /// Enregistre le cerveau allumé.
  static Future<void> saveActiveId(String id) async {
    try {
      final File file = await _file();
      await file.writeAsString(jsonEncode(<String, String>{'active': id}));
    } catch (_) {
      // Ce n'est qu'un confort : on continue sans.
    }
  }
}
