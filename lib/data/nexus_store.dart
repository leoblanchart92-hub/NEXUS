import 'dart:io';

import 'package:nexus_core/nexus_core.dart';
import 'package:path_provider/path_provider.dart';

/// Sauvegarde l'état de Nexus sur le téléphone, dans un fichier JSON.
///
/// C'est ce qui permet à Nexus de continuer à grandir entre deux ouvertures
/// de l'application : son vocabulaire et sa mémoire vivent dans ce fichier.
class NexusStore {
  static const String fileName = 'nexus_state.json';

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}/$fileName');
  }

  Future<NexusState?> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return NexusState.decode(raw);
    } catch (_) {
      // Un état illisible ne doit jamais empêcher l'application de démarrer :
      // il vaut mieux un Nexus qui renaît qu'un écran noir.
      return null;
    }
  }

  Future<void> save(NexusState state) async {
    try {
      final file = await _file();
      await file.writeAsString(state.encode(), flush: true);
    } catch (_) {
      // Si l'écriture échoue, la session continue en mémoire.
    }
  }

  Future<void> wipe() async {
    try {
      final file = await _file();
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Rien à faire : l'état sera simplement réécrit à la prochaine session.
    }
  }
}
