import 'package:shared_preferences/shared_preferences.dart';

/// Small key–value settings (theme mode for now), readable synchronously
/// so the first frame already uses the saved choice.
abstract interface class SettingsStore {
  String? getString(String key);

  Future<void> setString(String key, String value);
}

/// [SettingsStore] on `shared_preferences` (D-036). The [SharedPreferences]
/// instance is loaded once in `main()` and caches every value in memory.
class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    if (!await _prefs.setString(key, value)) {
      throw StateError('Could not save setting $key');
    }
  }
}
