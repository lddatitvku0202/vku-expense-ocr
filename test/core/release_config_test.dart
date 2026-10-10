import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release signing is configured without any secret in the repository
/// (brief 2.4, Phase 11).
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('release builds read android/key.properties', () {
    expect(gradle, contains('key.properties'));
    expect(gradle, contains('storeFile'));
    expect(gradle, contains('keyAlias'));
    expect(gradle, contains('signingConfigs'));
    expect(
      RegExp(
        r'release\s*\{[^}]*signingConfig\s*=',
        dotAll: true,
      ).hasMatch(gradle),
      isTrue,
    );
  });

  test('the secret files are ignored by git', () {
    final ignore = File('.gitignore').readAsStringSync();
    for (final pattern in [
      '*.jks',
      '*.keystore',
      'android/key.properties',
      '*.apk',
      '*.aab',
    ]) {
      expect(ignore, contains(pattern));
    }
  });

  test('no keystore, key.properties or password is tracked by git', () {
    final tracked = Process.runSync('git', ['ls-files']).stdout as String;
    expect(tracked, isNot(contains('key.properties')));
    expect(
      RegExp(r'\.(jks|keystore|apk|aab)$', multiLine: true).hasMatch(tracked),
      isFalse,
    );
    expect(gradle, isNot(contains('storePassword = "')));
    expect(gradle, isNot(contains('keyPassword = "')));
  });

  test('SIGNING.md explains how to recreate the keystore', () {
    final doc = File('docs/SIGNING.md').readAsStringSync();
    expect(doc, contains('keytool'));
    expect(doc, contains('key.properties'));
    expect(doc, contains('apksigner'));
  });
}
