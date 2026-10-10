import 'package:vku_expense_ocr/core/amount_input.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

/// Form validators of the Review screen (FR-4.3). Each returns a Vietnamese
/// message for the user, or `null` when the value is valid.
abstract final class ExpenseValidators {
  static const int maxMerchantLength = 100;

  // Compiled once: the amount validator runs while the user types.
  static final RegExp _separators = RegExp(r'[.,\s]');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static String? merchant(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Hãy nhập tên cửa hàng.';
    if (name.length > maxMerchantLength) {
      return 'Tên cửa hàng tối đa $maxMerchantLength ký tự.';
    }
    return null;
  }

  /// A positive whole number of dong once separators are removed.
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Hãy nhập số tiền.';
    final digits = value.replaceAll(_separators, '');
    if (digits.length > AmountInput.maxDigits && _digitsOnly.hasMatch(digits)) {
      return 'Số tiền quá lớn.';
    }
    final amount = AmountInput.parse(value);
    if (amount == null) return 'Số tiền chỉ gồm chữ số, ví dụ 150.000.';
    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0 đ. Hóa đơn 0 đ (ví dụ được giảm giá '
          'toàn bộ) không cần lưu thành giao dịch.';
    }
    return null;
  }

  /// Any time today or earlier; [now] is injected for tests.
  static String? date(DateTime? value, {required DateTime now}) {
    if (value == null) return 'Hãy chọn ngày giao dịch.';
    if (DateRanges.startOfDay(value).isAfter(DateRanges.startOfDay(now))) {
      return 'Ngày giao dịch không được ở tương lai.';
    }
    return null;
  }

  static String? category(ExpenseCategory? value) =>
      value == null ? 'Hãy chọn một danh mục.' : null;
}
