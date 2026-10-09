import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vku_expense_ocr/services/settings_store.dart';

void main() {
  test(
    'SharedPreferencesSettingsStore writes and reads back after reload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = SharedPreferencesSettingsStore(
        await SharedPreferences.getInstance(),
      );

      expect(first.getString('theme_mode'), isNull);
      await first.setString('theme_mode', 'dark');
      expect(first.getString('theme_mode'), 'dark');

      // A new instance (as after an app restart) sees the saved value.
      final second = SharedPreferencesSettingsStore(
        await SharedPreferences.getInstance(),
      );
      expect(second.getString('theme_mode'), 'dark');
    },
  );

  test('reads values saved by an earlier app run', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final store = SharedPreferencesSettingsStore(
      await SharedPreferences.getInstance(),
    );
    expect(store.getString('theme_mode'), 'light');
  });
}
