import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/app.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/state/theme_mode_provider.dart';

import 'support/memory_settings_store.dart';

void main() {
  testWidgets('the app uses the saved theme mode and reacts to changes', (
    tester,
  ) async {
    final store = MemorySettingsStore({ThemeModeNotifier.storageKey: 'dark'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
        child: const VkuExpenseApp(),
      ),
    );
    await tester.pumpAndSettle();

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.dark);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    await container.read(themeModeProvider.notifier).select(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.light);
    expect(store.values[ThemeModeNotifier.storageKey], 'light');
  });
}
