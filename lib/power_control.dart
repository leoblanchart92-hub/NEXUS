/// All available local brains.
List<String> availableBrains() {
  return const ['Qwen3-0.6B', 'Qwen3-1.7B'];
}

/// Active brain id, persisted in memory.
String? activeBrainId;

/// Turn a specific brain on.
Future<void> powerOn(String id) async {
  activeBrainId = id;
}

/// Turn the active brain off.
Future<void> powerOff() async {
  activeBrainId = null;
}
