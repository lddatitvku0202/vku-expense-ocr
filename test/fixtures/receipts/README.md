# Receipt fixtures

Synthetic receipts modelled on real Vietnamese shops, used to test
`RowGrouper` + `ReceiptParser` end to end. Expected values live in
`expected.dart` and were written **before** the parser existed.

## Format

- One text line = one visual row of the paper receipt, top to bottom.
- ` | ` separates text blocks that ML Kit returns as separate lines on the
  same row, e.g. a label on the left and its amount on the right.
- Lines starting with `#` are comments, not OCR text.
- `# skew: 0.08` (optional) tilts the photo: right-hand blocks move down by
  `skew × x` pixels. Default skew is `0.01`.

## How the loader turns a fixture into OCR lines

`test/support/receipt_fixture.dart` gives every block a synthetic bounding
box: row pitch 32 px, line height 20 px, first block at x = 16, further
blocks at x = 260, 370, 480. Right-hand blocks get ±4 px vertical jitter.
Lines are emitted **column by column** (all left blocks first, then the
right blocks), the way ML Kit returns text blocks, so the parser only sees
"label + amount" on one row if the row grouper does its job.
