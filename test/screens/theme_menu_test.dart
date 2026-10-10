import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/screens/dashboard/dashboard_screen.dart';
import 'package:vku_expense_ocr/state/theme_mode_provider.dart';

import '../support/app_harness.dart';
import '../support/memory_settings_store.dart';

void main() {
  MaterialApp app(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp));
  Brightness shown(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(DashboardScreen))).brightness;

  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(DashboardScreen.themeMenuKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the menu on the Dashboard AppBar lists the three modes (FR-8.1)',
    (tester) async {
      await pumpApp(tester, settings: MemorySettingsStore());

      await tester.tap(find.byKey(DashboardScreen.themeMenuKey));
      await tester.pumpAndSettle();
      for (final label in ['Sáng', 'Tối', 'Theo hệ thống']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('the current mode is marked in the menu', (tester) async {
    await pumpApp(
      tester,
      settings: MemorySettingsStore({ThemeModeNotifier.storageKey: 'dark'}),
    );
    await tester.tap(find.byKey(DashboardScreen.themeMenuKey));
    await tester.pumpAndSettle();

    final checked = find.descendant(
      of: find.byType(PopupMenuItem<ThemeMode>),
      matching: find.byIcon(Icons.check),
    );
    expect(checked, findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(PopupMenuItem<ThemeMode>, 'Tối'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('choosing a mode changes the look and saves the choice', (
    tester,
  ) async {
    final store = MemorySettingsStore();
    await pumpApp(tester, settings: store);
    expect(app(tester).themeMode, ThemeMode.system);

    await choose(tester, 'Tối');
    expect(app(tester).themeMode, ThemeMode.dark);
    expect(shown(tester), Brightness.dark);
    expect(store.values[ThemeModeNotifier.storageKey], 'dark');

    await choose(tester, 'Sáng');
    expect(app(tester).themeMode, ThemeMode.light);
    expect(shown(tester), Brightness.light);
    expect(store.values[ThemeModeNotifier.storageKey], 'light');

    await choose(tester, 'Theo hệ thống');
    expect(app(tester).themeMode, ThemeMode.system);
    expect(store.values[ThemeModeNotifier.storageKey], 'system');
  });

  testWidgets('"Theo hệ thống" follows the phone setting', (tester) async {
    await pumpApp(tester, settings: MemorySettingsStore());
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(shown(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(shown(tester), Brightness.light);
  });

  testWidgets('the saved mode is applied when the app starts', (tester) async {
    await pumpApp(
      tester,
      settings: MemorySettingsStore({ThemeModeNotifier.storageKey: 'dark'}),
    );
    expect(shown(tester), Brightness.dark);
  });

  testWidgets('the button has a tooltip for screen readers', (tester) async {
    await pumpApp(tester, settings: MemorySettingsStore());
    expect(
      tester
          .widget<PopupMenuButton<ThemeMode>>(
            find.byKey(DashboardScreen.themeMenuKey),
          )
          .tooltip,
      'Giao diện',
    );
  });
}
