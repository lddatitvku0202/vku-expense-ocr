import 'package:vku_expense_ocr/services/settings_store.dart';

/// [SettingsStore] kept in a map, for widget and state tests.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
