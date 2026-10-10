import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The name and package the user sees and the store keeps (Phase 10).
void main() {
  test('Android launcher label is "VKU Expense OCR"', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:label="VKU Expense OCR"'));
  });

  test('iOS display name is "VKU Expense OCR"', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>VKU Expense OCR</string>',
      ).hasMatch(plist),
      isTrue,
    );
  });

  test('application id keeps the vn.edu.vku organisation', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "vn.edu.vku.vku_expense_ocr"'));
    expect(gradle, contains('namespace = "vn.edu.vku.vku_expense_ocr"'));
  });
}
