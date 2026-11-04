import 'package:flutter/material.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';

/// L'école de Nexus : on lui apprend un mot et sa définition.
class LessonSheet extends StatefulWidget {
  const LessonSheet({super.key, required this.controller});

  final NexusController controller;

  static Future<void> show(BuildContext context, NexusController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NexusColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: LessonSheet(controller: controller),
      ),
    );
  }

  @override
  State<LessonSheet> createState() => _LessonSheetState();
}

class _LessonSheetState extends State<LessonSheet> {
  final TextEditingController _word = TextEditingController();
  final TextEditingController _definition = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _word.dispose();
    _definition.dispose();
    super.dispose();
  }

  Future<void> _teach() async {
    final word = _word.text.trim();
    final definition = _definition.text.trim();

    if (word.isEmpty || definition.isEmpty) {
      setState(() => _error = 'Il lui faut un mot et une définition.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    await widget.controller.teach(word, definition);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('📚', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "L'école de Nexus",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: NexusColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Un mot, sa définition : il les retient et gagne de l'expérience. "
            'Demande-lui ensuite « c\'est quoi… » ou « récite-moi ».',
            style: TextStyle(
              color: NexusColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _word,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'Le mot',
              hintText: 'lune',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _definition,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ce que ça veut dire',
              hintText: 'le satellite naturel de la Terre',
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: NexusColors.rose, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _teach,
              child: Text(_saving ? 'Il apprend…' : 'Lui apprendre'),
            ),
          ),
        ],
      ),
    );
  }
}
