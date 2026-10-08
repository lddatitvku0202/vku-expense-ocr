import 'expected.dart';

/// Fixture fields the parser is known to get wrong, with the reason.
///
/// Starts empty: every field of every fixture is expected to be correct.
/// An entry may only be added after a real attempt to fix the parser, and
/// the fixture itself is never deleted. The benchmark test fails when a
/// listed field starts passing (remove the entry) and when an unlisted
/// field fails (a regression).
const knownLimitations = <String, Map<ReceiptField, String>>{};
