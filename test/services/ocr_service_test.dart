import 'dart:math' show Point;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/services/ocr_service.dart';

TextLine mlLine(String text, Rect box, List<Point<int>> corners) => TextLine(
  text: text,
  elements: const [],
  boundingBox: box,
  recognizedLanguages: const [],
  cornerPoints: corners,
  confidence: null,
  angle: null,
);

Map<String, Object?> jsonLine(String text, int left, int top) => {
  'text': text,
  'rect': {'left': left, 'top': top, 'right': left + 100, 'bottom': top + 20},
  'recognizedLanguages': <String>[],
  'points': [
    {'x': left, 'y': top},
    {'x': left + 100, 'y': top},
    {'x': left + 100, 'y': top + 20},
    {'x': left, 'y': top + 20},
  ],
  'confidence': 0.9,
  'angle': 0.0,
  'elements': <Object?>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ocrLinesFrom (FR-2.2 adapter)', () {
    test('keeps every line with its text, box and corner points', () {
      final recognized = RecognizedText(
        text: 'TỔNG CỘNG\n84.000',
        blocks: [
          TextBlock(
            text: 'TỔNG CỘNG',
            lines: [
              mlLine('TỔNG CỘNG', const Rect.fromLTRB(10, 100, 110, 120), [
                const Point(10, 100),
                const Point(110, 100),
                const Point(110, 120),
                const Point(10, 120),
              ]),
            ],
            boundingBox: const Rect.fromLTRB(10, 100, 110, 120),
            recognizedLanguages: const [],
            cornerPoints: const [],
          ),
          TextBlock(
            text: '84.000',
            lines: [
              mlLine('84.000', const Rect.fromLTRB(300, 102, 360, 122), []),
            ],
            boundingBox: const Rect.fromLTRB(300, 102, 360, 122),
            recognizedLanguages: const [],
            cornerPoints: const [],
          ),
        ],
      );

      expect(ocrLinesFrom(recognized), const [
        OcrLine(
          text: 'TỔNG CỘNG',
          boundingBox: Rect.fromLTRB(10, 100, 110, 120),
          cornerPoints: [
            Offset(10, 100),
            Offset(110, 100),
            Offset(110, 120),
            Offset(10, 120),
          ],
        ),
        // Missing corner points become null, not an empty list.
        OcrLine(text: '84.000', boundingBox: Rect.fromLTRB(300, 102, 360, 122)),
      ]);
    });

    test('an image without text gives no lines', () {
      expect(ocrLinesFrom(RecognizedText(text: '', blocks: const [])), isEmpty);
    });
  });

  group('MlKitOcrService (platform channel mocked)', () {
    const channel = MethodChannel('google_mlkit_text_recognizer');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'vision#startTextRecognizer') {
              return {
                'text': 'Tổng cộng 84.000',
                'blocks': [
                  {
                    'text': 'Tổng cộng',
                    'rect': {
                      'left': 10,
                      'top': 100,
                      'right': 110,
                      'bottom': 120,
                    },
                    'recognizedLanguages': <String>[],
                    'points': <Object?>[],
                    'lines': [
                      jsonLine('Tổng cộng', 10, 100),
                      jsonLine('84.000', 300, 102),
                    ],
                  },
                ],
              };
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('recognizes a file with the Latin script and times it', () async {
      final service = MlKitOcrService();
      final result = await service.recognize('/tmp/receipt.jpg');

      expect(result.lines.map((l) => l.text), ['Tổng cộng', '84.000']);
      expect(result.lines.first.cornerPoints, hasLength(4));
      expect(result.elapsed, greaterThanOrEqualTo(Duration.zero));

      final start = calls.single;
      expect(start.method, 'vision#startTextRecognizer');
      final args = start.arguments as Map<Object?, Object?>;
      expect(args['script'], TextRecognitionScript.latin.index);
      final image = args['imageData']! as Map<Object?, Object?>;
      expect(image['type'], 'file');
      expect(image['path'], '/tmp/receipt.jpg');
    });

    test('close() releases the native recognizer (FR-2.5)', () async {
      final service = MlKitOcrService();
      await service.recognize('/tmp/receipt.jpg');
      await service.close();

      expect(calls.last.method, 'vision#closeTextRecognizer');
      final startId = (calls.first.arguments as Map<Object?, Object?>)['id'];
      expect((calls.last.arguments as Map<Object?, Object?>)['id'], startId);
    });

    test('a native failure surfaces as an exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'InputImageConverterError');
          });
      final service = MlKitOcrService();
      expect(
        service.recognize('/tmp/broken.jpg'),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
