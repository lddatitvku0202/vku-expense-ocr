import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

import '../support/fake_expense_repository.dart';
import '../support/fake_image_storage.dart';

/// Friday 09/10/2026 20:00: the selected month is October 2026 and the
/// selected week is Monday 05/10 – Sunday 11/10.
final _now = DateTime(2026, 10, 9, 20);

Expense _expense(
  String merchant,
  int amount,
  DateTime date, {
  int? id,
  ExpenseCategory category = ExpenseCategory.food,
  bool photo = false,
}) => Expense(
  id: id,
  merchant: merchant,
  amount: amount,
  date: date,
  category: category,
  imagePath: photo ? '/docs/receipts/$merchant.jpg' : null,
  thumbPath: photo ? '/docs/receipts/${merchant}_thumb.jpg' : null,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  late FakeExpenseRepository repo;
  late FakeImageStorage storage;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repo),
        imageStorageProvider.overrideWithValue(storage),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    storage = FakeImageStorage();
    repo = FakeExpenseRepository([
      _expense(
        'Highlands',
        59000,
        DateTime(2026, 10, 6, 9),
        id: 1,
        photo: true,
      ),
      _expense(
        'Fahasa',
        120000,
        DateTime(2026, 10, 2),
        id: 2,
        category: ExpenseCategory.study,
      ),
      _expense(
        'Grab',
        45000,
        DateTime(2026, 9, 30),
        id: 3,
        category: ExpenseCategory.travel,
      ),
    ]);
  });

  List<Expense> listOf(ProviderContainer c) =>
      c.read(expenseListProvider).requireValue;
  int monthTotal(ProviderContainer c) =>
      c.read(monthTotalProvider).requireValue;
  int food(ProviderContainer c) => c
      .read(categoryTotalsProvider)
      .requireValue
      .amountOf(ExpenseCategory.food);
  List<int> week(ProviderContainer c) =>
      c.read(weeklyTotalsProvider).requireValue.days;

  group('loading', () {
    test('loads every expense, newest first', () async {
      final c = container();
      expect(c.read(expenseListProvider), isA<AsyncLoading<List<Expense>>>());

      final list = await c.read(expenseListProvider.future);
      expect(list.map((e) => e.id), [1, 2, 3]);
    });

    test('derived providers follow the list: loading, then data', () async {
      final c = container();
      expect(c.read(monthTotalProvider).isLoading, isTrue);
      await c.read(expenseListProvider.future);

      expect(monthTotal(c), 59000 + 120000); // Grab is in September
      expect(food(c), 59000);
      expect(week(c), [0, 59000, 0, 0, 0, 0, 0]);
    });

    test(
      'a database error reaches the derived providers as AsyncError',
      () async {
        repo.failGetAll = Exception('disk I/O error');
        final c = container();
        await expectLater(c.read(expenseListProvider.future), throwsException);

        expect(c.read(expenseListProvider).hasError, isTrue);
        expect(c.read(categoryTotalsProvider).hasError, isTrue);
        expect(c.read(weeklyTotalsProvider).hasError, isTrue);
        expect(c.read(monthTotalProvider).hasError, isTrue);
      },
    );
  });

  group('add / edit', () {
    test('add inserts, returns the id and updates every total', () async {
      final c = container();
      await c.read(expenseListProvider.future);

      final saved = await c
          .read(expenseListProvider.notifier)
          .add(_expense('Circle K', 25000, DateTime(2026, 10, 9, 7)));

      expect(saved.id, 4);
      expect(listOf(c).first, saved);
      expect(monthTotal(c), 59000 + 120000 + 25000);
      expect(food(c), 59000 + 25000);
      expect(week(c), [0, 59000, 0, 0, 25000, 0, 0]);
    });

    test(
      'edit replaces the expense and moves it between categories and days',
      () async {
        final c = container();
        await c.read(expenseListProvider.future);
        final highlands = listOf(c).first;

        await c
            .read(expenseListProvider.notifier)
            .edit(
              highlands.copyWith(
                amount: 65000,
                category: ExpenseCategory.entertainment,
                date: DateTime(2026, 10, 11, 21),
              ),
            );

        expect(listOf(c).first.amount, 65000);
        expect(food(c), 0);
        expect(
          c
              .read(categoryTotalsProvider)
              .requireValue
              .amountOf(ExpenseCategory.entertainment),
          65000,
        );
        expect(week(c), [0, 0, 0, 0, 0, 0, 65000]);
        expect(
          storage.deletedPaths,
          isEmpty,
          reason: 'same photo, nothing to delete',
        );
      },
    );

    test('edit that replaces the photo deletes the old files', () async {
      final c = container();
      await c.read(expenseListProvider.future);
      final highlands = listOf(c).first;

      await c
          .read(expenseListProvider.notifier)
          .edit(
            highlands.copyWith(
              imagePath: () => '/docs/receipts/new.jpg',
              thumbPath: () => '/docs/receipts/new_thumb.jpg',
            ),
          );

      expect(storage.deletedPaths, [
        '/docs/receipts/Highlands.jpg',
        '/docs/receipts/Highlands_thumb.jpg',
      ]);
    });

    test('a failed edit leaves the list and the files unchanged', () async {
      final c = container();
      await c.read(expenseListProvider.future);
      final ghost = _expense('Ghost', 1000, DateTime(2026, 10, 9), id: 99);

      await expectLater(
        c.read(expenseListProvider.notifier).edit(ghost),
        throwsStateError,
      );
      expect(listOf(c).map((e) => e.id), [1, 2, 3]);
      expect(storage.deletedPaths, isEmpty);
    });
  });

  group('addWithPhoto (Review save, FR-5.3)', () {
    test('stores the photo, then saves the expense with its paths', () async {
      final c = container();
      await c.read(expenseListProvider.future);

      final saved = await c
          .read(expenseListProvider.notifier)
          .addWithPhoto(
            _expense('Circle K', 25000, DateTime(2026, 10, 9)),
            photoPath: '/cache/scan/receipt.jpg',
          );

      expect(storage.savedSources, ['/cache/scan/receipt.jpg']);
      expect(saved.imagePath, '/fake/receipts/receipt_1.jpg');
      expect(saved.thumbPath, '/fake/receipts/receipt_1_thumb.jpg');
      expect(await repo.getById(saved.id!), saved);
      expect(listOf(c).first, saved);
    });

    test('without a photo it is a plain add', () async {
      final c = container();
      await c.read(expenseListProvider.future);

      final saved = await c
          .read(expenseListProvider.notifier)
          .addWithPhoto(_expense('Quán cơm', 35000, DateTime(2026, 10, 9)));

      expect(storage.savedSources, isEmpty);
      expect(saved.imagePath, isNull);
      expect(listOf(c), hasLength(4));
    });

    test(
      'a database error deletes the photo just stored and rethrows',
      () async {
        final c = container();
        await c.read(expenseListProvider.future);
        repo.failNextInsert = Exception('disk full');

        await expectLater(
          c
              .read(expenseListProvider.notifier)
              .addWithPhoto(
                _expense('Circle K', 25000, DateTime(2026, 10, 9)),
                photoPath: '/cache/scan/receipt.jpg',
              ),
          throwsException,
        );

        expect(storage.deletedPaths, [
          '/fake/receipts/receipt_1.jpg',
          '/fake/receipts/receipt_1_thumb.jpg',
        ]);
        expect(listOf(c), hasLength(3));
      },
    );

    test('a photo that cannot be stored saves nothing', () async {
      final c = container();
      await c.read(expenseListProvider.future);
      storage.failNextSave = const ImageStorageException('Ảnh bị hỏng.');

      await expectLater(
        c
            .read(expenseListProvider.notifier)
            .addWithPhoto(
              _expense('Circle K', 25000, DateTime(2026, 10, 9)),
              photoPath: '/cache/scan/broken.jpg',
            ),
        throwsA(isA<ImageStorageException>()),
      );
      expect(repo.insertCalls, 0);
      expect(listOf(c), hasLength(3));
    });
  });

  group('remove', () {
    test(
      'updates the state at once, before the database call finishes',
      () async {
        final c = container();
        await c.read(expenseListProvider.future);

        final pending = c.read(expenseListProvider.notifier).remove(1);
        // Synchronously gone: a Dismissible must leave the tree on the next frame.
        expect(listOf(c).map((e) => e.id), [2, 3]);
        expect(monthTotal(c), 120000);
        expect(week(c), [0, 0, 0, 0, 0, 0, 0]);

        final removed = await pending;
        expect(removed?.merchant, 'Highlands');
        expect(await repo.getById(1), isNull);
      },
    );

    test('a database error puts the expense back and rethrows', () async {
      final c = container();
      await c.read(expenseListProvider.future);
      repo.failNextDelete = Exception('locked');

      await expectLater(
        c.read(expenseListProvider.notifier).remove(1),
        throwsException,
      );
      expect(listOf(c).map((e) => e.id), [1, 2, 3]);
      expect(
        c.read(expenseListProvider.notifier).isPendingDeletion(1),
        isFalse,
      );
    });

    test('an unknown id returns null and changes nothing', () async {
      final c = container();
      await c.read(expenseListProvider.future);

      expect(await c.read(expenseListProvider.notifier).remove(42), isNull);
      expect(listOf(c), hasLength(3));
    });
  });

  group('undo window (FR-5.4, D-032)', () {
    const window = ExpenseListNotifier.undoWindow;

    test('photo files are kept during the window and deleted when it ends', () {
      fakeAsync((async) {
        final c = container();
        unawaited(c.read(expenseListProvider.future));
        async.flushMicrotasks();

        unawaited(c.read(expenseListProvider.notifier).remove(1));
        async.flushMicrotasks();
        expect(
          c.read(expenseListProvider.notifier).isPendingDeletion(1),
          isTrue,
        );

        async.elapse(window - const Duration(milliseconds: 1));
        expect(storage.deletedPaths, isEmpty);

        async.elapse(const Duration(milliseconds: 1));
        expect(storage.deletedPaths, [
          '/docs/receipts/Highlands.jpg',
          '/docs/receipts/Highlands_thumb.jpg',
        ]);
        expect(
          c.read(expenseListProvider.notifier).isPendingDeletion(1),
          isFalse,
        );
      });
    });

    test(
      'restore within the window brings back the same id and keeps the photo',
      () {
        fakeAsync((async) {
          final c = container();
          unawaited(c.read(expenseListProvider.future));
          async.flushMicrotasks();
          final original = listOf(c).first;

          unawaited(c.read(expenseListProvider.notifier).remove(1));
          async.elapse(window ~/ 2);

          bool? restored;
          c
              .read(expenseListProvider.notifier)
              .restore(1)
              .then((r) => restored = r);
          async.flushMicrotasks();

          expect(restored, isTrue);
          expect(listOf(c).first, original);
          expect(monthTotal(c), 59000 + 120000);
          expect(food(c), 59000);
          expect(week(c), [0, 59000, 0, 0, 0, 0, 0]);

          async.elapse(window * 2);
          expect(
            storage.deletedPaths,
            isEmpty,
            reason: 'the timer was cancelled',
          );
        });
      },
    );

    test('restore after the window returns false and does not bring back a photo-less row', () {
      fakeAsync((async) {
        final c = container();
        unawaited(c.read(expenseListProvider.future));
        async.flushMicrotasks();

        unawaited(c.read(expenseListProvider.notifier).remove(1));
        async.elapse(window);

        bool? restored;
        c
            .read(expenseListProvider.notifier)
            .restore(1)
            .then((r) => restored = r);
        async.flushMicrotasks();

        expect(restored, isFalse);
        expect(listOf(c).map((e) => e.id), [2, 3]);
        expect(storage.deletedPaths, hasLength(2));
      });
    });

    test('commitDeletion ends the window early (snack bar dismissed)', () {
      fakeAsync((async) {
        final c = container();
        unawaited(c.read(expenseListProvider.future));
        async.flushMicrotasks();

        unawaited(c.read(expenseListProvider.notifier).remove(1));
        async.flushMicrotasks();
        unawaited(c.read(expenseListProvider.notifier).commitDeletion(1));
        async.flushMicrotasks();

        expect(storage.deletedPaths, hasLength(2));
        async.elapse(window * 2);
        expect(storage.deletedPaths, hasLength(2), reason: 'deleted only once');
      });
    });

    test('each removal has its own window', () {
      fakeAsync((async) {
        repo = FakeExpenseRepository([
          _expense('A', 1000, DateTime(2026, 10, 6), id: 1, photo: true),
          _expense('B', 2000, DateTime(2026, 10, 7), id: 2, photo: true),
        ]);
        final c = container();
        unawaited(c.read(expenseListProvider.future));
        async.flushMicrotasks();

        unawaited(c.read(expenseListProvider.notifier).remove(1));
        async.elapse(const Duration(seconds: 2));
        unawaited(c.read(expenseListProvider.notifier).remove(2));
        async.elapse(window - const Duration(seconds: 2));

        expect(storage.deletedPaths, [
          '/docs/receipts/A.jpg',
          '/docs/receipts/A_thumb.jpg',
        ]);
        async.elapse(const Duration(seconds: 2));
        expect(storage.deletedPaths, hasLength(4));
      });
    });

    test(
      'a manual expense without photo is removed without deleting files',
      () {
        fakeAsync((async) {
          final c = container();
          unawaited(c.read(expenseListProvider.future));
          async.flushMicrotasks();

          unawaited(c.read(expenseListProvider.notifier).remove(2));
          async.elapse(window);
          expect(storage.deletedPaths, isEmpty);
          expect(listOf(c).map((e) => e.id), [1, 3]);
        });
      },
    );

    test(
      'a failed restore keeps the deletion pending, files still go at the end',
      () {
        fakeAsync((async) {
          final c = container();
          unawaited(c.read(expenseListProvider.future));
          async.flushMicrotasks();

          unawaited(c.read(expenseListProvider.notifier).remove(1));
          async.flushMicrotasks();
          repo.failNextInsert = Exception('disk full');

          Object? error;
          c.read(expenseListProvider.notifier).restore(1).catchError((
            Object e,
          ) {
            error = e;
            return false;
          });
          async.flushMicrotasks();

          expect(error, isA<Exception>());
          expect(listOf(c).map((e) => e.id), [2, 3]);
          async.elapse(window);
          expect(storage.deletedPaths, hasLength(2));
        });
      },
    );

    test('holdForUndo keeps the photo until the snack bar decides', () {
      fakeAsync((async) {
        final c = container();
        unawaited(c.read(expenseListProvider.future));
        async.flushMicrotasks();
        final notifier = c.read(expenseListProvider.notifier);

        unawaited(notifier.remove(1));
        async.flushMicrotasks();
        notifier.holdForUndo(1);
        async.elapse(window * 3);
        expect(storage.deletedPaths, isEmpty, reason: 'no timer while held');
        expect(notifier.isPendingDeletion(1), isTrue);

        bool? restored;
        notifier.restore(1).then((r) => restored = r);
        async.flushMicrotasks();
        expect(restored, isTrue);
        expect(listOf(c).first.id, 1);
      });
    });

    test('a held deletion is final once committed', () {
      fakeAsync((async) {
        final c = container();
        unawaited(c.read(expenseListProvider.future));
        async.flushMicrotasks();
        final notifier = c.read(expenseListProvider.notifier);

        unawaited(notifier.remove(1));
        async.flushMicrotasks();
        notifier.holdForUndo(1);
        unawaited(notifier.commitDeletion(1));
        async.flushMicrotasks();
        expect(storage.deletedPaths, hasLength(2));
        expect(notifier.isPendingDeletion(1), isFalse);
      });
    });

    test('holdForUndo on an id that is not pending does nothing', () {
      fakeAsync((async) {
        final c = container();
        unawaited(c.read(expenseListProvider.future));
        async.flushMicrotasks();
        c.read(expenseListProvider.notifier).holdForUndo(42);
        async.elapse(window * 2);
        expect(storage.deletedPaths, isEmpty);
      });
    });

    test(
      'disposing the state (app closing) deletes pending files right away',
      () {
        fakeAsync((async) {
          final c = ProviderContainer(
            overrides: [
              expenseRepositoryProvider.overrideWithValue(repo),
              imageStorageProvider.overrideWithValue(storage),
              clockProvider.overrideWithValue(() => _now),
            ],
          );
          unawaited(c.read(expenseListProvider.future));
          async.flushMicrotasks();
          unawaited(c.read(expenseListProvider.notifier).remove(1));
          async.flushMicrotasks();

          c.dispose();
          async.flushMicrotasks();
          expect(storage.deletedPaths, hasLength(2));
        });
      },
    );
  });
}
