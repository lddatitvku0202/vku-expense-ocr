import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

/// Light / dark / system theme, chosen by the user and saved (FR-8.1).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String storageKey = 'theme_mode';

  /// The saved choice, or [ThemeMode.system] when none (or an unknown
  /// value from a future version) was saved.
  @override
  ThemeMode build() {
    final saved = ref.watch(settingsStoreProvider).getString(storageKey);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  /// Applies [mode] at once, then saves it. Throws if saving fails; the
  /// mode still applies until the app restarts.
  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsStoreProvider).setString(storageKey, mode.name);
  }
}
