/// How much the receipt parser trusts one extracted field (FR-3.6).
enum FieldConfidence {
  /// Found through a strong signal, e.g. a "Tổng thanh toán" keyword.
  high,

  /// Found through a fallback rule, e.g. "largest amount on the receipt".
  low,

  /// Not found at all; the user must fill it in on the Review screen.
  missing;

  /// Whether the Review screen should highlight the field (FR-4.4).
  bool get needsReview => this != high;
}
