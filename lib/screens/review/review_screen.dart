import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vku_expense_ocr/core/amount_input.dart';
import 'package:vku_expense_ocr/core/category_style.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/core/expense_validators.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/screens/review/review_draft.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/widgets/confidence_note.dart';
import 'package:vku_expense_ocr/widgets/ocr_text_panel.dart';
import 'package:vku_expense_ocr/widgets/receipt_image_view.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// Review & verification form (FR-4).
///
/// One screen serves three modes (FR-4.9):
/// - review a freshly scanned receipt ([scan] or [receipt] is set),
/// - add an expense manually (nothing set),
/// - edit a saved expense ([expenseId] is set, route `/expense/:id`).
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, this.receipt, this.expenseId, this.scan});

  final ParsedReceipt? receipt;
  final int? expenseId;

  /// Photo path, OCR time and rows of a scan, when the receipt came from
  /// the camera or the gallery.
  final ScanResult? scan;

  static const Key merchantFieldKey = Key('review-merchant');
  static const Key amountFieldKey = Key('review-amount');
  static const Key dateFieldKey = Key('review-date');
  static const Key saveButtonKey = Key('review-save');
  static const Key imageKey = Key('review-image');
  static const Key merchantWarningKey = Key('review-merchant-warning');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenseId case final id?) {
      // Edit mode reads the saved expense from app state (FR-8.4).
      return ref
          .watch(expenseListProvider)
          .when(
            loading: () => const _Message(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => _Message(
              child: StateMessage(
                icon: Icons.error_outline,
                title: 'Không tải được giao dịch',
                message: 'Hãy thử lại hoặc quay lại.',
                action: FilledButton(
                  onPressed: () => ref.invalidate(expenseListProvider),
                  child: const Text('Thử lại'),
                ),
              ),
            ),
            data: (expenses) {
              final expense = expenses.where((e) => e.id == id).firstOrNull;
              if (expense == null) {
                return const _Message(
                  child: StateMessage(
                    icon: Icons.search_off,
                    title: 'Không tìm thấy giao dịch',
                    message: 'Giao dịch này có thể đã bị xóa.',
                  ),
                );
              }
              return _ReviewForm(
                key: ValueKey('edit-$id'),
                draft: ReviewDraft.fromExpense(expense),
              );
            },
          );
    }

    final today = ref.read(clockProvider)();
    final draft = switch ((scan, receipt)) {
      (final ScanResult scan, _) => ReviewDraft.fromScan(scan, today: today),
      (null, final ParsedReceipt receipt) => ReviewDraft.fromReceipt(
        receipt,
        today: today,
      ),
      (null, null) => ReviewDraft.manual(today: today),
    };
    return _ReviewForm(draft: draft);
  }
}

/// Scaffold for the loading / error / not-found states of edit mode.
class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(ReviewMode.edit.title)),
    body: SafeArea(child: child),
  );
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({super.key, required this.draft});

  final ReviewDraft draft;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  final _merchantFocus = FocusNode(debugLabel: 'merchant');
  final _amountFocus = FocusNode(debugLabel: 'amount');

  DateTime? _date;
  ExpenseCategory? _category;

  // Marks from the parser; a mark is cleared once the user edits the field
  // (they have checked it).
  late FieldConfidence _merchantConfidence;
  late FieldConfidence _amountConfidence;
  late FieldConfidence _dateConfidence;
  late FieldConfidence _categoryConfidence;

  bool _saving = false;

  ReviewDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    final draft = _draft;
    _merchant = TextEditingController(text: draft.merchant)
      ..addListener(_onTextChanged);
    _amount = TextEditingController(
      text: draft.amount == null ? '' : AmountInput.format(draft.amount!),
    )..addListener(_onTextChanged);
    _date = draft.date;
    _category = draft.category;
    _merchantConfidence = draft.merchantConfidence;
    _amountConfidence = draft.amountConfidence;
    _dateConfidence = draft.dateConfidence;
    _categoryConfidence = draft.categoryConfidence;
  }

  @override
  void dispose() {
    // FR-4.7 / NFR-3: every controller and focus node is released.
    _merchant.dispose();
    _amount.dispose();
    _merchantFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  /// Rebuilds so the discard guard ([_dirty]) follows the text fields.
  void _onTextChanged() => setState(() {});

  bool get _dirty =>
      _merchant.text.trim() != _draft.merchant.trim() ||
      AmountInput.parse(_amount.text) != _draft.amount ||
      _date != _draft.date ||
      _category != _draft.category;

  // --- Actions ---------------------------------------------------------------

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final today = DateRanges.startOfDay(ref.read(clockProvider)());
    final current = _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null || current.isAfter(today) ? today : current,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Chọn ngày giao dịch',
    );
    if (picked == null || !mounted) return;
    field.didChange(picked);
    setState(() {
      _date = picked;
      _dateConfidence = FieldConfidence.high;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notifier = ref.read(expenseListProvider.notifier);
    final now = ref.read(clockProvider)();
    final merchant = _merchant.text.trim();
    final amount = AmountInput.parse(_amount.text)!;
    final date = _date!;
    final category = _category!;

    try {
      final String message;
      if (_draft.existing case final existing?) {
        await notifier.edit(
          existing.copyWith(
            merchant: merchant,
            amount: amount,
            // Same day: keep the original time so the order in History
            // does not change.
            date:
                DateRanges.startOfDay(date) ==
                    DateRanges.startOfDay(existing.date)
                ? existing.date
                : date,
            category: category,
          ),
        );
        message = 'Đã cập nhật giao dịch.';
      } else {
        await notifier.addWithPhoto(
          Expense(
            merchant: merchant,
            amount: amount,
            date: date,
            category: category,
            rawText: _draft.rawText,
            createdAt: now,
            updatedAt: now,
          ),
          photoPath: _draft.imagePath,
        );
        message = 'Đã lưu giao dịch.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
      // pop() rather than maybePop(): the discard question is not needed
      // after a successful save (FR-4.8).
      navigator.pop();
    } on ImageStorageException catch (error) {
      _showError('Không lưu được ảnh hóa đơn: ${error.message}');
    } on Object catch (error, stack) {
      developer.log(
        'Saving the expense failed',
        name: 'vku_expense_ocr.review',
        error: error,
        stackTrace: stack,
      );
      _showError('Không lưu được giao dịch. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: scheme.errorContainer,
          content: Text(
            message,
            style: TextStyle(color: scheme.onErrorContainer),
          ),
        ),
      );
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text('Những gì bạn vừa sửa sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return PopScope<Object?>(
      // Back button, Android back and swipe all ask first when there are
      // unsaved changes (FR-4.8).
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(draft.mode.title)),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                // Scrolls when the keyboard takes half the screen. A Column
                // (not a lazy ListView) keeps every field built, so
                // Form.validate() checks all of them.
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_merchantConfidence.needsReview) ...[
                        MerchantWarningBanner(
                          key: ReviewScreen.merchantWarningKey,
                          confidence: _merchantConfidence,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (draft.scanError case final error?) ...[
                        _ScanErrorCard(message: error),
                        const SizedBox(height: 16),
                      ],
                      if (draft.imagePath case final path?) ...[
                        ReceiptImageView(
                          key: ReviewScreen.imageKey,
                          path: path,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _merchantField(),
                      const SizedBox(height: 16),
                      _amountField(),
                      const SizedBox(height: 16),
                      _dateField(),
                      const SizedBox(height: 16),
                      _categoryField(),
                      if (draft.ocrRows case final rows?) ...[
                        const SizedBox(height: 16),
                        OcrTextPanel(
                          rows: rows,
                          ocrDuration: draft.ocrDuration,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: ReviewScreen.saveButtonKey,
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          draft.mode == ReviewMode.edit
                              ? 'Lưu thay đổi'
                              : 'Lưu giao dịch',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _merchantField() {
    final flagged = _merchantConfidence.needsReview;
    final scheme = Theme.of(context).colorScheme;
    final flagColor = _merchantConfidence == FieldConfidence.missing
        ? scheme.error
        : scheme.tertiary;
    return TextFormField(
      key: ReviewScreen.merchantFieldKey,
      controller: _merchant,
      focusNode: _merchantFocus,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      maxLength: ExpenseValidators.maxMerchantLength,
      onFieldSubmitted: (_) => _amountFocus.requestFocus(),
      onChanged: (_) {
        if (flagged) {
          setState(() => _merchantConfidence = FieldConfidence.high);
        }
      },
      validator: ExpenseValidators.merchant,
      decoration: InputDecoration(
        labelText: 'Tên cửa hàng',
        prefixIcon: const Icon(Icons.storefront_outlined),
        counterText: '',
        suffixIcon: flagged
            ? Icon(Icons.warning_amber_rounded, color: flagColor)
            : null,
        enabledBorder: flagged
            ? OutlineInputBorder(
                borderSide: BorderSide(color: flagColor, width: 2),
              )
            : null,
      ),
    );
  }

  Widget _amountField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        key: ReviewScreen.amountFieldKey,
        controller: _amount,
        focusNode: _amountFocus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: const [VndAmountInputFormatter()],
        onFieldSubmitted: (_) => _amountFocus.unfocus(),
        onChanged: (_) {
          if (_amountConfidence.needsReview) {
            setState(() => _amountConfidence = FieldConfidence.high);
          }
        },
        validator: ExpenseValidators.amount,
        decoration: const InputDecoration(
          labelText: 'Số tiền',
          prefixIcon: Icon(Icons.payments_outlined),
          suffixText: 'đ',
          hintText: 'Ví dụ 150.000',
        ),
      ),
      if (_amountConfidence.needsReview)
        ConfidenceNote(
          key: const Key('confidence-amount'),
          confidence: _amountConfidence,
          lowText: 'Không chắc chắn — hãy kiểm tra lại số tiền',
          missingText: 'Không đọc được số tiền — hãy nhập',
        ),
    ],
  );

  Widget _dateField() => FormField<DateTime>(
    initialValue: _date,
    validator: (value) =>
        ExpenseValidators.date(value, now: ref.read(clockProvider)()),
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: ReviewScreen.dateFieldKey,
          borderRadius: BorderRadius.circular(4),
          onTap: () => _pickDate(field),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Ngày',
              prefixIcon: const Icon(Icons.event_outlined),
              suffixIcon: const Icon(Icons.edit_calendar_outlined),
              errorText: field.errorText,
              errorMaxLines: 2,
            ),
            child: Text(switch (field.value) {
              final DateTime date => Formatters.date(date),
              null => 'Chọn ngày',
            }),
          ),
        ),
        if (_dateConfidence.needsReview)
          ConfidenceNote(
            key: const Key('confidence-date'),
            confidence: _dateConfidence,
            lowText: 'Không chắc chắn — hãy kiểm tra lại ngày',
            missingText: 'Không đọc được ngày — đã điền tạm hôm nay',
          ),
      ],
    ),
  );

  Widget _categoryField() => FormField<ExpenseCategory>(
    initialValue: _category,
    validator: ExpenseValidators.category,
    builder: (field) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danh mục', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ExpenseCategory.values)
                ChoiceChip(
                  key: Key('category-${category.name}'),
                  avatar: Icon(
                    category.icon,
                    color: category.colorOn(theme.brightness),
                  ),
                  label: Text(category.label),
                  selected: field.value == category,
                  onSelected: (_) {
                    field.didChange(category);
                    setState(() {
                      _category = category;
                      _categoryConfidence = FieldConfidence.high;
                    });
                  },
                ),
            ],
          ),
          if (field.errorText case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.error),
              ),
            ),
          if (_categoryConfidence.needsReview)
            ConfidenceNote(
              key: const Key('confidence-category'),
              confidence: _categoryConfidence,
              lowText: 'Chỉ là gợi ý — hãy kiểm tra lại',
              missingText: 'Chưa đoán được danh mục — hãy chọn',
            ),
        ],
      );
    },
  );
}

class _ScanErrorCard extends StatelessWidget {
  const _ScanErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
        title: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
      ),
    );
  }
}
