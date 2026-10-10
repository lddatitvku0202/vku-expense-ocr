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

  test(
    'R8 keeps working: rules for the ML Kit scripts the app does not bundle',
    () {
      final rules = File('android/app/proguard-rules.pro').readAsStringSync();
      for (final script in ['chinese', 'devanagari', 'japanese', 'korean']) {
        expect(
          rules,
          contains('-dontwarn com.google.mlkit.vision.text.$script.**'),
        );
      }
      expect(gradle, contains('proguard-rules.pro'));
      expect(gradle, contains('isMinifyEnabled = true'));
    },
  );

  test('only the Latin text recognition model is bundled (D-013)', () {
    final gradleFiles = [
      gradle,
      File('pubspec.yaml').readAsStringSync(),
    ].join();
    for (final script in ['chinese', 'devanagari', 'japanese', 'korean']) {
      expect(gradleFiles, isNot(contains('text-recognition-$script')));
    }
  });

  test('R8 keeps the reflectively loaded ML Kit component registrars', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();
    expect(
      RegExp(
        r'-keep class \* implements com\.google\.firebase\.components\.ComponentRegistrar \{\s*<init>\(\);\s*\}',
      ).hasMatch(rules),
      isTrue,
    );
  });

  group('offline by construction (NFR-1)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    /// The `<uses-permission ...>` element naming [permission], or null.
    String? element(String permission) => RegExp(
      '<uses-permission[^>]*android:name="android\.permission\.$permission"[^>]*>',
    ).firstMatch(manifest)?.group(0);

    test('the main manifest removes INTERNET and ACCESS_NETWORK_STATE', () {
      // ML Kit's data-transport library adds both; the app never uses the
      // network, so the merged release manifest must not carry them.
      for (final permission in ['INTERNET', 'ACCESS_NETWORK_STATE']) {
        expect(element(permission), isNotNull, reason: permission);
        expect(
          element(permission),
          contains('tools:node="remove"'),
          reason: permission,
        );
      }
    });

    test('the permissions the app really needs are still there', () {
      expect(element('CAMERA'), isNotNull);
      expect(element('CAMERA'), isNot(contains('tools:node="remove"')));
      expect(element('RECORD_AUDIO'), contains('tools:node="remove"'));
    });

    test('the tools namespace is declared for the remove markers', () {
      expect(
        manifest,
        contains('xmlns:tools="http://schemas.android.com/tools"'),
      );
    });

    test('no source code opens a network connection', () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      final network = RegExp(
        r"HttpClient|dart:io.*Socket|package:http|package:dio|WebSocket|Uri\.parse\('https?:",
      );
      for (final file in files) {
        expect(
          network.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    });
  });
}
