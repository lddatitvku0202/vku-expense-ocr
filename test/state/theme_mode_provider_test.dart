import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vku_expense_ocr/services/settings_store.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/state/theme_mode_provider.dart';

import '../support/memory_settings_store.dart';

void main() {
  ProviderContainer container(SettingsStore store) {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('follows the system until the user chooses (FR-8.1)', () {
    expect(
      container(MemorySettingsStore()).read(themeModeProvider),
      ThemeMode.system,
    );
  });

  test('each choice is applied and saved', () async {
    final store = MemorySettingsStore();
    final c = container(store);

    for (final mode in ThemeMode.values.reversed) {
      await c.read(themeModeProvider.notifier).select(mode);
      expect(c.read(themeModeProvider), mode);
      expect(store.values[ThemeModeNotifier.storageKey], mode.name);
    }
  });

  test('a saved choice is read back by a new app run', () async {
    SharedPreferences.setMockInitialValues({});
    final firstRun = container(
      SharedPreferencesSettingsStore(await SharedPreferences.getInstance()),
    );
    await firstRun.read(themeModeProvider.notifier).select(ThemeMode.dark);

    final secondRun = container(
      SharedPreferencesSettingsStore(await SharedPreferences.getInstance()),
    );
    expect(secondRun.read(themeModeProvider), ThemeMode.dark);
  });

  test('an unknown saved value falls back to the system setting', () {
    final store = MemorySettingsStore({ThemeModeNotifier.storageKey: 'sepia'});
    expect(container(store).read(themeModeProvider), ThemeMode.system);
  });
}
