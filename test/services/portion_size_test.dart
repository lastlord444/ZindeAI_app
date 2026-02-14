import 'package:flutter_test/flutter_test.dart';
import 'package:zindeai_app/services/models/portion_size.dart';

void main() {
  group('PortionSize enum', () {
    test('3 değer: small, medium, large', () {
      expect(PortionSize.values.length, 3);
      expect(PortionSize.small.label, 'S');
      expect(PortionSize.medium.label, 'M');
      expect(PortionSize.large.label, 'L');
    });

    test('multiplier değerleri doğru', () {
      expect(PortionSize.small.multiplier, 0.60);
      expect(PortionSize.medium.multiplier, 1.00);
      expect(PortionSize.large.multiplier, 1.50);
    });

    test('displayName Türkçe', () {
      expect(PortionSize.small.displayName, 'Küçük');
      expect(PortionSize.medium.displayName, 'Orta');
      expect(PortionSize.large.displayName, 'Büyük');
    });
  });

  group('scaleToPortionSize', () {
    // Baz değerler (medium porsiyon):
    // 300 kcal, 20g protein, 30g karb, 10g yağ, 250g porsiyon
    const baseKalori = 300.0;
    const baseProtein = 20.0;
    const baseKarb = 30.0;
    const baseYag = 10.0;
    const basePorsiyonG = 250.0;

    test('medium → 1.0x (değerler aynen döner)', () {
      final result = scaleToPortionSize(
        baseKalori: baseKalori,
        baseProtein: baseProtein,
        baseKarb: baseKarb,
        baseYag: baseYag,
        basePorsiyonG: basePorsiyonG,
        portion: PortionSize.medium,
      );

      expect(result['kalori'], 300.0);
      expect(result['protein'], 20.0);
      expect(result['karb'], 30.0);
      expect(result['yag'], 10.0);
      expect(result['porsiyonG'], 250.0);
    });

    test('small → 0.6x (doğru çarpım)', () {
      final result = scaleToPortionSize(
        baseKalori: baseKalori,
        baseProtein: baseProtein,
        baseKarb: baseKarb,
        baseYag: baseYag,
        basePorsiyonG: basePorsiyonG,
        portion: PortionSize.small,
      );

      // 300 * 0.6 = 180.0
      expect(result['kalori'], 180.0);
      // 20 * 0.6 = 12.0
      expect(result['protein'], 12.0);
      // 30 * 0.6 = 18.0
      expect(result['karb'], 18.0);
      // 10 * 0.6 = 6.0
      expect(result['yag'], 6.0);
      // 250 * 0.6 = 150.0
      expect(result['porsiyonG'], 150.0);
    });

    test('large → 1.5x (doğru çarpım)', () {
      final result = scaleToPortionSize(
        baseKalori: baseKalori,
        baseProtein: baseProtein,
        baseKarb: baseKarb,
        baseYag: baseYag,
        basePorsiyonG: basePorsiyonG,
        portion: PortionSize.large,
      );

      // 300 * 1.5 = 450.0
      expect(result['kalori'], 450.0);
      // 20 * 1.5 = 30.0
      expect(result['protein'], 30.0);
      // 30 * 1.5 = 45.0
      expect(result['karb'], 45.0);
      // 10 * 1.5 = 15.0
      expect(result['yag'], 15.0);
      // 250 * 1.5 = 375.0
      expect(result['porsiyonG'], 375.0);
    });

    test('küsürlü değerler tek ondalığa yuvarlanır', () {
      // 123.456 * 0.6 = 74.0736 → 74.1 (tek ondalık)
      final result = scaleToPortionSize(
        baseKalori: 123.456,
        baseProtein: 7.77,
        baseKarb: 15.55,
        baseYag: 3.33,
        basePorsiyonG: 180.0,
        portion: PortionSize.small,
      );

      // 123.456 * 0.6 = 74.0736 → 74.1
      expect(result['kalori'], closeTo(74.1, 0.05));
      // 7.77 * 0.6 = 4.662 → 4.7
      expect(result['protein'], closeTo(4.7, 0.05));
      // 15.55 * 0.6 = 9.33 → 9.3
      expect(result['karb'], closeTo(9.3, 0.05));
      // 3.33 * 0.6 = 1.998 → 2.0
      expect(result['yag'], closeTo(2.0, 0.05));
      // 180 * 0.6 = 108.0
      expect(result['porsiyonG'], 108.0);
    });

    test('sıfır değerler sıfır kalır', () {
      final result = scaleToPortionSize(
        baseKalori: 0,
        baseProtein: 0,
        baseKarb: 0,
        baseYag: 0,
        basePorsiyonG: 0,
        portion: PortionSize.large,
      );

      expect(result['kalori'], 0.0);
      expect(result['protein'], 0.0);
      expect(result['karb'], 0.0);
      expect(result['yag'], 0.0);
      expect(result['porsiyonG'], 0.0);
    });
  });
}
