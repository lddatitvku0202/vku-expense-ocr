import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/screens/review/review_screen.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

import '../support/fake_expense_repository.dart';
import '../support/fake_image_storage.dart';

/// Friday 09/10/2026 20:00.
final _now = DateTime(2026, 10, 9, 20);

ScanResult _scan({
  String? merchant = 'CO.OPMART HUẾ',
  FieldConfidence merchantConfidence = FieldConfidence.high,
  int? total = 245000,
  FieldConfidence totalConfidence = FieldConfidence.high,
  DateTime? date,
  FieldConfidence dateConfidence = FieldConfidence.high,
  ExpenseCategory? category = ExpenseCategory.food,
  FieldConfidence categoryConfidence = FieldConfidence.high,
  String? error,
}) => ScanResult(
  imagePath: '/cache/scan/receipt.jpg',
  receipt: ParsedReceipt(
    merchant: merchant,
    total: total,
    date: dateConfidence == FieldConfidence.missing
        ? null
        : (date ?? DateTime(2026, 9, 14)),
    suggestedCategory: category,
    rawText: 'CO.OPMART HUẾ\nTổng thanh toán 245.000',
    merchantConfidence: merchantConfidence,
    totalConfidence: totalConfidence,
    dateConfidence: dateConfidence,
    categoryConfidence: categoryConfidence,
  ),
  rows: const ['CO.OPMART HUẾ', 'Tổng thanh toán 245.000'],
  ocrDuration: const Duration(milliseconds: 420),
  error: error,
);

final _saved = Expense(
  id: 7,
  merchant: 'Highlands Coffee',
  amount: 59000,
  date: DateTime(2026, 10, 6, 9, 30),
  category: ExpenseCategory.food,
  imagePath: '/docs/receipts/7.jpg',
  thumbPath: '/docs/receipts/7_thumb.jpg',
  rawText: 'HIGHLANDS COFFEE\nTổng 59.000',
  createdAt: DateTime(2026, 10, 6, 9, 31),
  updatedAt: DateTime(2026, 10, 6, 9, 31),
);

void main() {
  late FakeExpenseRepository repo;
  late FakeImageStorage storage;

  setUp(() {
    repo = FakeExpenseRepository([_saved]);
    storage = FakeImageStorage();
  });

  /// Starts on a home page and pushes [location], so popping is visible.
  Future<GoRouter> pumpReview(
    WidgetTester tester, {
    String location = '/review',
    Object? extra,
    Size physicalSize = const Size(1080, 1920),
    double devicePixelRatio = 3,
  }) async {
    tester.view
      ..physicalSize = physicalSize
      ..devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) => switch (state.extra) {
            final ScanResult scan => ReviewScreen(
              receipt: scan.receipt,
              scan: scan,
            ),
            final ParsedReceipt receipt => ReviewScreen(receipt: receipt),
            _ => const ReviewScreen(),
          },
        ),
        GoRoute(
          path: '/expense/:id',
          builder: (context, state) =>
              ReviewScreen(expenseId: int.parse(state.pathParameters['id']!)),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repo),
          imageStorageProvider.overrideWithValue(storage),
          clockProvider.overrideWithValue(() => _now),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(location, extra: extra));
    await tester.pumpAndSettle();
    return router;
  }

  Finder field(Key key) => find.byKey(key);
  String textOf(WidgetTester tester, Key key) => tester
      .widget<EditableText>(
        find.descendant(of: field(key), matching: find.byType(EditableText)),
      )
      .controller
      .text;
  EditableText editable(WidgetTester tester, Key key) =>
      tester.widget<EditableText>(
        find.descendant(of: field(key), matching: find.byType(EditableText)),
      );

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(ReviewScreen.saveButtonKey));
    await tester.tap(find.byKey(ReviewScreen.saveButtonKey));
    await tester.pumpAndSettle();
  }

  group('scanned receipt', () {
    testWidgets('shows the photo and every parsed field (FR-4.1, FR-4.2)', (
      tester,
    ) async {
      await pumpReview(tester, extra: _scan());

      expect(find.text('Xác nhận hóa đơn'), findsOneWidget);
      expect(find.byKey(ReviewScreen.imageKey), findsOneWidget);
      expect(textOf(tester, ReviewScreen.merchantFieldKey), 'CO.OPMART HUẾ');
      expect(textOf(tester, ReviewScreen.amountFieldKey), '245.000');
      expect(find.text('14/09/2026'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('category-food')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('the photo can be zoomed (InteractiveViewer)', (tester) async {
      await pumpReview(tester, extra: _scan());

      await tester.tap(find.byKey(ReviewScreen.imageKey));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('raw OCR text and OCR time are available (FR-4.5, FR-2.4)', (
      tester,
    ) async {
      await pumpReview(tester, extra: _scan());

      await tester.ensureVisible(find.text('Xem văn bản OCR gốc'));
      expect(find.textContaining('420 ms'), findsOneWidget);
      await tester.tap(find.text('Xem văn bản OCR gốc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tổng thanh toán 245.000'), findsOneWidget);
    });

    testWidgets('a scan that could not be read says so and keeps the form', (
      tester,
    ) async {
      await pumpReview(
        tester,
        extra: const ScanResult(
          imagePath: '/cache/scan/receipt.jpg',
          receipt: ParsedReceipt.empty(),
          rows: [],
          ocrDuration: Duration.zero,
          error: 'Không đọc được ảnh hóa đơn. Hãy chụp lại hoặc nhập tay.',
        ),
      );

      expect(find.textContaining('Không đọc được ảnh hóa đơn'), findsOneWidget);
      expect(find.byKey(ReviewScreen.merchantFieldKey), findsOneWidget);
    });
  });

  group('confidence marks (FR-4.4): icon + caption, not only colour', () {
    testWidgets('high-confidence fields have no mark', (tester) async {
      await pumpReview(tester, extra: _scan());

      expect(find.byKey(ReviewScreen.merchantWarningKey), findsNothing);
      for (final name in ['amount', 'date', 'category']) {
        expect(find.byKey(Key('confidence-$name')), findsNothing, reason: name);
      }
    });

    testWidgets('missing merchant: the most prominent warning, at the top', (
      tester,
    ) async {
      await pumpReview(
        tester,
        extra: _scan(
          merchant: null,
          merchantConfidence: FieldConfidence.missing,
        ),
      );

      final banner = find.byKey(ReviewScreen.merchantWarningKey);
      expect(banner, findsOneWidget);
      expect(
        find.descendant(of: banner, matching: find.byIcon(Icons.error)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: banner,
          matching: find.text('Không đọc được tên cửa hàng'),
        ),
        findsOneWidget,
      );
      // Above every other field, and larger than the inline notes.
      expect(
        tester.getTopLeft(banner).dy,
        lessThan(
          tester.getTopLeft(find.byKey(ReviewScreen.merchantFieldKey)).dy,
        ),
      );
    });

    testWidgets('low-confidence merchant: banner asks to check', (
      tester,
    ) async {
      await pumpReview(
        tester,
        extra: _scan(merchantConfidence: FieldConfidence.low),
      );

      final banner = find.byKey(ReviewScreen.merchantWarningKey);
      expect(
        find.descendant(
          of: banner,
          matching: find.byIcon(Icons.warning_amber_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: banner,
          matching: find.textContaining('Không chắc chắn — hãy kiểm tra lại'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('amount, date and category marks have an icon and a caption', (
      tester,
    ) async {
      await pumpReview(
        tester,
        extra: _scan(
          totalConfidence: FieldConfidence.low,
          dateConfidence: FieldConfidence.missing,
          category: null,
          categoryConfidence: FieldConfidence.missing,
        ),
      );

      final amount = find.byKey(const Key('confidence-amount'));
      expect(
        find.descendant(of: amount, matching: find.byIcon(Icons.help_outline)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: amount,
          matching: find.text('Không chắc chắn — hãy kiểm tra lại số tiền'),
        ),
        findsOneWidget,
      );

      final date = find.byKey(const Key('confidence-date'));
      expect(
        find.descendant(of: date, matching: find.byIcon(Icons.error_outline)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: date,
          matching: find.text('Không đọc được ngày — đã điền tạm hôm nay'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('09/10/2026'),
        findsOneWidget,
        reason: 'today suggested',
      );

      final category = find.byKey(const Key('confidence-category'));
      expect(
        find.descendant(
          of: category,
          matching: find.byIcon(Icons.error_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: category,
          matching: find.text('Chưa đoán được danh mục — hãy chọn'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a mark disappears once the user corrects that field', (
      tester,
    ) async {
      await pumpReview(
        tester,
        extra: _scan(
          merchant: null,
          merchantConfidence: FieldConfidence.missing,
        ),
      );

      await tester.enterText(
        field(ReviewScreen.merchantFieldKey),
        'Co.opmart Huế',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ReviewScreen.merchantWarningKey), findsNothing);
    });
  });

  group('validators (FR-4.3)', () {
    testWidgets(
      'empty merchant and amount, missing category: Vietnamese messages',
      (tester) async {
        await pumpReview(tester);

        await tapSave(tester);
        expect(find.text('Hãy nhập tên cửa hàng.'), findsOneWidget);
        expect(find.text('Hãy nhập số tiền.'), findsOneWidget);
        expect(find.text('Hãy chọn một danh mục.'), findsOneWidget);
        expect(repo.insertCalls, 0);
        expect(find.byType(ReviewScreen), findsOneWidget);
      },
    );

    testWidgets('a 0 đ receipt is refused with an explanation', (tester) async {
      await pumpReview(tester, extra: _scan());

      await tester.enterText(field(ReviewScreen.amountFieldKey), '0');
      await tapSave(tester);
      expect(find.textContaining('lớn hơn 0'), findsOneWidget);
      expect(find.textContaining('giảm giá toàn bộ'), findsOneWidget);
      expect(repo.insertCalls, 0);
    });

    testWidgets('a future date (e.g. a misread year) is refused', (
      tester,
    ) async {
      await pumpReview(tester, extra: _scan(date: DateTime(2062, 9, 14)));

      await tapSave(tester);
      expect(
        find.text('Ngày giao dịch không được ở tương lai.'),
        findsOneWidget,
      );
      expect(repo.insertCalls, 0);
    });

    testWidgets('the date picker never offers a future day', (tester) async {
      await pumpReview(tester, extra: _scan());

      await tester.tap(field(ReviewScreen.dateFieldKey));
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.lastDate, DateTime(2026, 10, 9));

      await tester.tap(find.text('1'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('01/09/2026'), findsOneWidget);
    });
  });

  group('amount field (FR-4.6)', () {
    testWidgets('groups thousands while typing', (tester) async {
      await pumpReview(tester);

      await tester.enterText(field(ReviewScreen.amountFieldKey), '1250000');
      await tester.pump();
      expect(textOf(tester, ReviewScreen.amountFieldKey), '1.250.000');
    });

    testWidgets('typing in the middle keeps the cursor next to the new digit', (
      tester,
    ) async {
      await pumpReview(tester, extra: _scan());
      await tester.tap(field(ReviewScreen.amountFieldKey));
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '2459.000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      final value = editable(
        tester,
        ReviewScreen.amountFieldKey,
      ).controller.value;
      expect(value.text, '2.459.000');
      expect(value.selection.baseOffset, 5); // "2.459|.000"
    });

    for (final pasted in ['150,000', '150.000đ']) {
      testWidgets('pasting "$pasted" saves 150000', (tester) async {
        await pumpReview(tester, extra: _scan());

        await tester.enterText(field(ReviewScreen.amountFieldKey), pasted);
        await tester.pump();
        expect(textOf(tester, ReviewScreen.amountFieldKey), '150.000');
        await tapSave(tester);
        final added = (await repo.getAll()).firstWhere((e) => e.id != 7);
        expect(added.amount, 150000);
      });
    }
  });

  group('saving', () {
    testWidgets(
      'scan: stores the photo, adds the expense, snack bar, back (FR-4.8)',
      (tester) async {
        await pumpReview(tester, extra: _scan());

        await tapSave(tester);

        expect(storage.savedSources, ['/cache/scan/receipt.jpg']);
        final added = (await repo.getAll()).firstWhere((e) => e.id != 7);
        expect(added.merchant, 'CO.OPMART HUẾ');
        expect(added.amount, 245000);
        expect(added.date, DateTime(2026, 9, 14));
        expect(added.category, ExpenseCategory.food);
        expect(added.imagePath, '/fake/receipts/receipt_1.jpg');
        expect(added.thumbPath, '/fake/receipts/receipt_1_thumb.jpg');
        expect(added.rawText, 'CO.OPMART HUẾ\nTổng thanh toán 245.000');
        expect(added.createdAt, _now);
        expect(find.text('home'), findsOneWidget);
        expect(find.text('Đã lưu giao dịch.'), findsOneWidget);
      },
    );

    testWidgets(
      'database error: photo removed, error shown, screen stays open',
      (tester) async {
        repo.failNextInsert = Exception('disk full');
        await pumpReview(tester, extra: _scan());

        await tapSave(tester);

        expect(storage.deletedPaths, [
          '/fake/receipts/receipt_1.jpg',
          '/fake/receipts/receipt_1_thumb.jpg',
        ]);
        expect(find.byType(ReviewScreen), findsOneWidget);
        expect(find.text('home'), findsNothing);
        expect(find.textContaining('Không lưu được giao dịch'), findsOneWidget);
        expect(textOf(tester, ReviewScreen.merchantFieldKey), 'CO.OPMART HUẾ');
      },
    );

    testWidgets(
      'manual entry: empty form without photo, add without photo (FR-4.9)',
      (tester) async {
        await pumpReview(tester);

        expect(find.text('Thêm giao dịch thủ công'), findsOneWidget);
        expect(find.byKey(ReviewScreen.imageKey), findsNothing);
        expect(find.text('Xem văn bản OCR gốc'), findsNothing);
        expect(textOf(tester, ReviewScreen.merchantFieldKey), isEmpty);
        expect(
          find.text('09/10/2026'),
          findsOneWidget,
          reason: 'defaults to today',
        );

        await tester.enterText(
          field(ReviewScreen.merchantFieldKey),
          'Quán cơm Bà Năm',
        );
        await tester.enterText(field(ReviewScreen.amountFieldKey), '35000');
        await tester.ensureVisible(find.byKey(const Key('category-food')));
        await tester.tap(find.byKey(const Key('category-food')));
        await tapSave(tester);

        expect(storage.savedSources, isEmpty);
        final added = (await repo.getAll()).firstWhere((e) => e.id != 7);
        expect(added.merchant, 'Quán cơm Bà Năm');
        expect(added.amount, 35000);
        expect(added.imagePath, isNull);
        expect(find.text('home'), findsOneWidget);
      },
    );

    testWidgets('edit: loads the saved expense and calls edit (FR-4.9)', (
      tester,
    ) async {
      await pumpReview(tester, location: '/expense/7');

      expect(find.text('Sửa giao dịch'), findsOneWidget);
      expect(textOf(tester, ReviewScreen.merchantFieldKey), 'Highlands Coffee');
      expect(textOf(tester, ReviewScreen.amountFieldKey), '59.000');
      expect(find.text('06/10/2026'), findsOneWidget);
      expect(find.byKey(ReviewScreen.imageKey), findsOneWidget);

      await tester.enterText(field(ReviewScreen.amountFieldKey), '65000');
      await tapSave(tester);

      expect(repo.updateCalls, 1);
      expect(repo.insertCalls, 0);
      final updated = (await repo.getById(7))!;
      expect(updated.amount, 65000);
      expect(updated.date, _saved.date, reason: 'same day keeps the time');
      expect(updated.imagePath, _saved.imagePath);
      expect(storage.savedSources, isEmpty);
      expect(find.text('home'), findsOneWidget);
      expect(find.text('Đã cập nhật giao dịch.'), findsOneWidget);
    });

    testWidgets('edit: an unknown id shows a message', (tester) async {
      await pumpReview(tester, location: '/expense/99');
      expect(find.text('Không tìm thấy giao dịch'), findsOneWidget);
    });
  });

  group('leaving (FR-4.8)', () {
    testWidgets('without changes the back button just goes back', (
      tester,
    ) async {
      await pumpReview(tester, extra: _scan());

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('with changes the back button asks first', (tester) async {
      await pumpReview(tester, extra: _scan());
      await tester.enterText(field(ReviewScreen.merchantFieldKey), 'Co.opmart');
      await tester.pump(); // the next frame, as when a person types

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(textOf(tester, ReviewScreen.merchantFieldKey), 'Co.opmart');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(repo.insertCalls, 0);
    });

    testWidgets('the Android back button asks too', (tester) async {
      await pumpReview(tester, location: '/expense/7');
      await tester.enterText(field(ReviewScreen.amountFieldKey), '1');
      await tester.pump(); // the next frame, as when a person types

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect((await repo.getById(7))!.amount, 59000);
    });
  });

  group('keyboard and layout (FR-4.7, FR-8.2)', () {
    testWidgets('Next moves from the merchant to the amount', (tester) async {
      await pumpReview(tester, extra: _scan());

      expect(
        editable(tester, ReviewScreen.merchantFieldKey).textInputAction,
        TextInputAction.next,
      );
      await tester.tap(field(ReviewScreen.merchantFieldKey));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        editable(tester, ReviewScreen.amountFieldKey).focusNode.hasFocus,
        isTrue,
      );
      expect(
        editable(tester, ReviewScreen.amountFieldKey).keyboardType,
        TextInputType.number,
      );
    });

    for (final (name, size, dpr) in [
      ('small phone 320 x 480', const Size(640, 960), 2.0),
      ('landscape 640 x 360', const Size(1920, 1080), 3.0),
    ]) {
      testWidgets('$name with the keyboard open: no overflow, Save reachable', (
        tester,
      ) async {
        await pumpReview(
          tester,
          extra: _scan(
            merchant: null,
            merchantConfidence: FieldConfidence.missing,
          ),
          physicalSize: size,
          devicePixelRatio: dpr,
        );
        tester.view.viewInsets = FakeViewPadding(bottom: size.height * 0.45);
        addTearDown(tester.view.resetViewInsets);
        await tester.ensureVisible(field(ReviewScreen.merchantFieldKey));
        await tester.pumpAndSettle();
        await tester.tap(field(ReviewScreen.merchantFieldKey));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byKey(ReviewScreen.saveButtonKey),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.byKey(ReviewScreen.saveButtonKey).hitTestable(),
          findsOneWidget,
        );
      });
    }
  });
}
