import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

const food = ExpenseCategory.food;
const study = ExpenseCategory.study;
const travel = ExpenseCategory.travel;
const gear = ExpenseCategory.gear;
const entertainment = ExpenseCategory.entertainment;

void main() {
  const parser = ReceiptParser();
  (ExpenseCategory, FieldConfidence)? suggest({
    String? merchant,
    List<String> rows = const [],
  }) => parser.suggestCategory(merchant: merchant, rows: rows);

  group('from the merchant name: high confidence (FR-3.5)', () {
    const cases = {
      'HIGHLANDS COFFEE': food,
      'Phúc Long Coffee & Tea': food,
      'QUÁN CƠM BÀ NĂM': food,
      'CO.OPMART HUẾ': food,
      'KFC Việt Nam': food,
      'Nhà hàng Hải Sản Biển Đông': food,
      'NHÀ SÁCH FAHASA HUẾ': study,
      'PHOTO COPY THANH TÂM': study,
      'Văn phòng phẩm Hồng Hà': study,
      'Grab': travel,
      'beCar': travel,
      'Petrolimex Cửa hàng xăng dầu số 5': travel,
      'Vietjet Air': travel,
      'CGV Vincom Huế': entertainment,
      'KARAOKE NICE': entertainment,
      'Lotte Cinema Đà Nẵng': entertainment,
      'THẾ GIỚI DI ĐỘNG': gear,
      'CellphoneS': gear,
      'Điện Máy Xanh': gear,
    };
    for (final MapEntry(key: merchant, value: category) in cases.entries) {
      test('"$merchant" is ${category.name}', () {
        expect(suggest(merchant: merchant), (category, FieldConfidence.high));
      });
    }
  });

  group('from the receipt content: low confidence', () {
    test('food', () {
      expect(
        suggest(
          merchant: 'ABC',
          rows: ['Cơm gà xối mỡ 35.000', 'Trà đá 4.000'],
        ),
        (food, FieldConfidence.low),
      );
    });

    test('study', () {
      final rows = [
        'Giáo trình Flutter 145.000',
        'Vở kẻ ngang 18.000',
        'Bút bi 4.000',
      ];
      expect(suggest(rows: rows), (study, FieldConfidence.low));
    });

    test('travel', () {
      final rows = ['Cước phí 46.000', 'Quãng đường: 9,6 km', 'Điểm đón: KTX'];
      expect(suggest(rows: rows), (travel, FieldConfidence.low));
    });

    test('gear', () {
      final rows = ['Tai nghe Bluetooth 1.090.000', 'Bảo hành: 12 tháng'];
      expect(suggest(rows: rows), (gear, FieldConfidence.low));
    });

    test('entertainment', () {
      final rows = [
        'Vé 2D người lớn 90.000',
        'Suất chiếu 20:15',
        'Phòng chiếu 3',
      ];
      expect(suggest(rows: rows), (entertainment, FieldConfidence.low));
    });
  });

  test('the merchant name outweighs the content', () {
    final rows = ['Bắp rang bơ 59.000', 'Coca-Cola 35.000'];
    expect(suggest(merchant: 'CGV Cinemas', rows: rows), (
      entertainment,
      FieldConfidence.high,
    ));
  });

  test('matching ignores accents and case', () {
    expect(suggest(merchant: 'NHA SACH TIEN THO'), (
      study,
      FieldConfidence.high,
    ));
  });

  test('returns null when it cannot guess (FR-3.5)', () {
    expect(suggest(merchant: 'ABC XYZ', rows: ['Mặt hàng A 50.000']), isNull);
    expect(suggest(), isNull);
  });

  test('returns null when the content is a tie', () {
    expect(suggest(rows: ['Cơm gà 35.000', 'Bút bi 4.000']), isNull);
  });
}
