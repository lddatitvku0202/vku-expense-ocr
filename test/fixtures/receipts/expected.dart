/// Expected parse results for every fixture in this folder.
///
/// Written before the parser existed (TDD). Never change a value to match
/// the parser output; only correct a value that disagrees with the receipt
/// itself, and explain why in the commit message.
library;

import 'package:vku_expense_ocr/models/expense_category.dart';

enum ReceiptField { merchant, total, date, category }

class ReceiptExpectation {
  const ReceiptExpectation({
    required this.file,
    required this.merchant,
    required this.total,
    required this.date,
    required this.category,
  });

  final String file;

  /// Receipt lines that name the shop; matching any of them is correct
  /// (compared without accents or case). `null`: no shop name is printed.
  final List<String>? merchant;

  /// Amount actually paid, in dong.
  final int? total;

  /// Transaction date as (year, month, day); `null`: no date is printed.
  final (int, int, int)? date;

  final ExpenseCategory? category;
}

const receiptExpectations = <ReceiptExpectation>[
  ReceiptExpectation(
    file: 'coopmart_hue.txt',
    merchant: ['CO.OPMART HUẾ', 'SAIGON CO.OP'],
    total: 245000,
    date: (2026, 9, 14),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'winmart.txt',
    merchant: ['WinMart+'],
    total: 68500,
    date: (2026, 9, 30),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'bach_hoa_xanh.txt',
    merchant: ['BÁCH HÓA XANH'],
    total: 100000,
    date: (2026, 10, 2),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'lotte_mart.txt',
    merchant: ['LOTTE Mart', 'LOTTE MART ĐÀ NẴNG'],
    total: 451550,
    date: (2026, 10, 12),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'highlands_coffee.txt',
    merchant: ['HIGHLANDS COFFEE', 'Highlands Coffee Vincom Huế'],
    total: 119000,
    date: (2026, 10, 5),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'phuc_long.txt',
    merchant: ['PHUC LONG', 'Phúc Long Coffee & Tea'],
    total: 139500,
    date: (2026, 10, 7),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'the_coffee_house.txt',
    merchant: ['THE COFFEE HOUSE'],
    total: 94000,
    date: (2026, 10, 9),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'circle_k.txt',
    merchant: ['Circle K', 'CIRCLE K VIETNAM'],
    total: 49000,
    date: (2026, 10, 10),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'gs25.txt',
    merchant: ['GS25', 'GS25 Lý Thường Kiệt'],
    total: 84000,
    date: (2026, 10, 11),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'fahasa.txt',
    merchant: ['FAHASA', 'NHÀ SÁCH FAHASA HUẾ'],
    total: 247500,
    date: (2026, 10, 13),
    category: ExpenseCategory.study,
  ),
  ReceiptExpectation(
    file: 'grab.txt',
    merchant: ['Grab'],
    total: 44000,
    date: (2026, 10, 14),
    category: ExpenseCategory.travel,
  ),
  ReceiptExpectation(
    file: 'be.txt',
    merchant: ['beCar'],
    total: 93000,
    date: (2026, 10, 15),
    category: ExpenseCategory.travel,
  ),
  ReceiptExpectation(
    file: 'cgv.txt',
    merchant: ['CGV Cinemas', 'CGV Vincom Huế'],
    total: 289000,
    date: (2026, 10, 16),
    category: ExpenseCategory.entertainment,
  ),
  ReceiptExpectation(
    file: 'the_gioi_di_dong.txt',
    merchant: ['THẾ GIỚI DI ĐỘNG'],
    total: 1250000,
    date: (2026, 10, 18),
    category: ExpenseCategory.gear,
  ),
  ReceiptExpectation(
    file: 'cellphones.txt',
    merchant: ['CellphoneS'],
    total: 2230000,
    date: (2026, 10, 23),
    category: ExpenseCategory.gear,
  ),
  ReceiptExpectation(
    file: 'quan_com.txt',
    merchant: ['QUÁN CƠM BÀ NĂM'],
    total: 94000,
    date: null,
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'bookworm_english.txt',
    merchant: ['BOOKWORM BOOKSTORE'],
    total: 945250,
    date: (2026, 10, 19),
    category: ExpenseCategory.study,
  ),
  ReceiptExpectation(
    file: 'photocopy.txt',
    merchant: ['PHOTO COPY THANH TÂM'],
    total: 110000,
    date: (2026, 10, 20),
    category: ExpenseCategory.study,
  ),
  ReceiptExpectation(
    file: 'maycha_noisy.txt',
    merchant: ['TRÀ SỮA MAYCHA'],
    total: 63000,
    date: (2026, 10, 21),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'cropped_cafe.txt',
    merchant: null,
    total: 79000,
    date: null,
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'karaoke.txt',
    merchant: ['KARAOKE NICE'],
    total: 1018710,
    date: (2026, 10, 22),
    category: ExpenseCategory.entertainment,
  ),
  ReceiptExpectation(
    file: 'pho24_ocr_digits.txt',
    merchant: ['PHỞ 24', 'Phở 24 - Vincom Plaza Huế'],
    total: 139500,
    date: (2026, 10, 24),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'banh_mi_skewed.txt',
    merchant: ['BÁNH MÌ MADAM KHÁNH'],
    total: 90000,
    date: (2026, 10, 25),
    category: ExpenseCategory.food,
  ),
  // Phase 3: rotated photos (deskew with ML Kit corner points).
  ReceiptExpectation(
    file: 'tilted_minimart.txt',
    merchant: ['MINIMART AN BÌNH'],
    total: 70000,
    date: (2026, 10, 26),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'tilted_cafe_ccw.txt',
    merchant: ['CỘNG CÀ PHÊ'],
    total: 149000,
    date: (2026, 10, 28),
    category: ExpenseCategory.food,
  ),
  ReceiptExpectation(
    file: 'sideways_bookshop.txt',
    merchant: ['NHÀ SÁCH MINH TRÍ'],
    total: 115000,
    date: (2026, 10, 27),
    category: ExpenseCategory.study,
  ),
];
