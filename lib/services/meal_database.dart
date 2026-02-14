// Lokal yemek veritabanı — 2000+ öğün.
// Her yemek: id, ad, meal_type listesi, goal_tag listesi,
// 100g başına makrolar (kcal, protein, carb, fat),
// porsiyon_g (varsayılan gram), ve kategori.
//
// meal_type enum:
//   kahvalti, ara_ogun_1, ogle, ara_ogun_2, aksam, gece_atistirmasi
//
// goal_tag: cut, maintain, bulk (bir yemek birden fazla goal'e uygun olabilir)

class LocalMeal {
  final String id;
  final String ad;
  final List<String> mealTypes;
  final List<String> goalTags;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final double defaultPortionG;
  final String kategori;

  const LocalMeal({
    required this.id,
    required this.ad,
    required this.mealTypes,
    required this.goalTags,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    required this.defaultPortionG,
    required this.kategori,
  });

  double kcalForPortion(double g) => kcalPer100g * g / 100;
  double proteinForPortion(double g) => proteinPer100g * g / 100;
  double carbForPortion(double g) => carbPer100g * g / 100;
  double fatForPortion(double g) => fatPer100g * g / 100;
}

/// Adjuster item — makro ince ayar için eklenen küçük gıdalar.
class AdjusterItem {
  final String id;
  final String ad;
  final String adjustType; // 'protein', 'carb', 'fat'
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final double minG;
  final double maxG;

  const AdjusterItem({
    required this.id,
    required this.ad,
    required this.adjustType,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    required this.minG,
    required this.maxG,
  });
}

/// 2000+ yemek veritabanı.
///
/// Yapı:
/// - 120 temel yemek şablonu (gerçek besin değerleri)
/// - Her şablondan farklı porsiyon/soslu varyasyonlar üretilir
/// - Toplam: 2000+ benzersiz yemek
class MealDatabase {
  const MealDatabase();

  /// Belirli öğün tipi + hedef için uygun yemekleri getirir.
  List<LocalMeal> getMealsFor({
    required String mealType,
    required String goalTag,
  }) {
    return allMeals
        .where((m) =>
            m.mealTypes.contains(mealType) && m.goalTags.contains(goalTag))
        .toList();
  }

  // ─────────────────────────────────────────────────────
  //  TEMEL YEMEK ŞABLONLARİ (120 adet - gerçek besin değerleri)
  // ─────────────────────────────────────────────────────

  /// Tüm yemekler — lazy init, tek seferde oluşturulur.
  static final List<LocalMeal> allMeals = _buildAllMeals();

  static List<LocalMeal> _buildAllMeals() {
    final meals = <LocalMeal>[];
    int idCounter = 0;

    String nextId() => 'meal_${++idCounter}';

    // ════════════════════════════════════════════════════
    //  KAHVALTI YEMEKLERİ
    // ════════════════════════════════════════════════════
    final kahvaltiBase = [
      // Yüksek protein kahvaltılar
      _T('Yumurta (haslama)', 155, 13.0, 1.1, 11.0, 120, 'protein_agirlikli'),
      _T('Yumurta (menemen)', 140, 10.0, 5.0, 9.5, 200, 'protein_agirlikli'),
      _T('Omlet (peynirli)', 180, 13.0, 2.0, 13.5, 180, 'protein_agirlikli'),
      _T('Omlet (sebzeli)', 130, 10.0, 4.0, 8.5, 200, 'protein_agirlikli'),
      _T('Omlet (mantarli)', 125, 10.5, 3.0, 8.0, 200, 'protein_agirlikli'),
      _T('Beyaz peynir', 264, 17.0, 1.5, 21.0, 60, 'protein_agirlikli'),
      _T('Lor peyniri', 98, 11.0, 3.4, 4.3, 100, 'protein_agirlikli'),
      _T('Cottage cheese', 98, 11.1, 3.4, 4.3, 150, 'protein_agirlikli'),
      _T('Sut (yarim yagli)', 50, 3.3, 4.8, 1.8, 200, 'protein_agirlikli'),
      _T('Yogurt (sade)', 63, 5.0, 4.0, 3.3, 200, 'protein_agirlikli'),
      _T('Yogurt (yunan)', 100, 10.0, 3.0, 5.0, 200, 'protein_agirlikli'),
      // Karbonhidrat kahvaltılar
      _T('Tam bugday ekmek', 247, 13.0, 41.0, 3.4, 80, 'karb_agirlikli'),
      _T('Yulaf ezmesi', 389, 16.9, 66.3, 6.9, 60, 'karb_agirlikli'),
      _T('Yulaf ezmesi (meyveli)', 350, 13.0, 62.0, 6.0, 80, 'karb_agirlikli'),
      _T('Muzlu yulaf', 320, 12.0, 58.0, 5.5, 90, 'karb_agirlikli'),
      _T('Granola', 471, 10.5, 64.0, 20.0, 50, 'karb_agirlikli'),
      _T('Tam bugday tost', 260, 14.0, 42.0, 4.0, 100, 'karb_agirlikli'),
      _T('Pankek (protein)', 200, 20.0, 22.0, 3.5, 150, 'karb_agirlikli'),
      _T('Muzlu pankek', 220, 8.0, 35.0, 5.0, 150, 'karb_agirlikli'),
      // Dengeli kahvaltılar
      _T('Avokadolu tost', 230, 6.0, 22.0, 13.0, 150, 'dengeli'),
      _T('Peynirli tost', 290, 14.0, 30.0, 12.0, 120, 'dengeli'),
      _T('Sucuklu yumurta', 220, 14.0, 2.0, 17.0, 180, 'dengeli'),
      _T('Kasar peyniri', 340, 25.0, 1.0, 26.0, 40, 'protein_agirlikli'),
      _T('Zeytin', 115, 0.8, 6.0, 10.7, 40, 'yag_agirlikli'),
      _T('Domates/salatalik', 20, 1.0, 3.5, 0.3, 150, 'sebze'),
      _T('Bal + tereyagi', 340, 0.6, 76.0, 4.0, 30, 'karb_agirlikli'),
      _T('Chia puding', 486, 17.0, 42.0, 31.0, 60, 'dengeli'),
      _T('Smoothie bowl', 120, 5.0, 22.0, 2.0, 300, 'karb_agirlikli'),
      _T('Protein smoothie', 90, 12.0, 8.0, 1.5, 350, 'protein_agirlikli'),
    ];

    // ════════════════════════════════════════════════════
    //  ARA ÖĞÜN YEMEKLERİ
    // ════════════════════════════════════════════════════
    final araOgunBase = [
      _T('Protein bar', 350, 30.0, 35.0, 10.0, 60, 'protein_agirlikli'),
      _T('Muz', 89, 1.1, 22.8, 0.3, 120, 'karb_agirlikli'),
      _T('Elma', 52, 0.3, 13.8, 0.2, 180, 'karb_agirlikli'),
      _T('Portakal', 47, 0.9, 11.8, 0.1, 200, 'karb_agirlikli'),
      _T('Ceviz', 654, 15.2, 13.7, 65.2, 30, 'yag_agirlikli'),
      _T('Badem', 579, 21.2, 21.7, 49.9, 30, 'yag_agirlikli'),
      _T('Findik', 628, 15.0, 17.0, 61.0, 30, 'yag_agirlikli'),
      _T('Kaju', 553, 18.2, 30.2, 43.9, 30, 'yag_agirlikli'),
      _T('Karisik kuruyemis', 607, 20.0, 21.0, 54.0, 35, 'yag_agirlikli'),
      _T('Yogurt + meyve', 80, 5.0, 12.0, 1.5, 200, 'dengeli'),
      _T('Yogurt + bal', 95, 4.5, 16.0, 1.8, 200, 'dengeli'),
      _T('Protein shake', 120, 24.0, 4.0, 1.5, 300, 'protein_agirlikli'),
      _T('Whey protein (su ile)', 400, 80.0, 8.0, 4.0, 30, 'protein_agirlikli'),
      _T('Kazein protein', 370, 75.0, 6.0, 3.5, 30, 'protein_agirlikli'),
      _T('Pirinc patlagi', 387, 8.0, 85.0, 2.8, 30, 'karb_agirlikli'),
      _T('Hurma', 277, 1.8, 75.0, 0.2, 40, 'karb_agirlikli'),
      _T('Kuru kayisi', 241, 3.4, 63.0, 0.5, 40, 'karb_agirlikli'),
      _T('Kuru uzum', 299, 3.1, 79.2, 0.5, 40, 'karb_agirlikli'),
      _T('Havuc + humus', 120, 4.0, 15.0, 5.0, 150, 'dengeli'),
      _T('Yer fistigi ezmesi', 588, 25.0, 20.0, 50.0, 20, 'yag_agirlikli'),
      _T('Yer fistigi ezmesi (tam)', 600, 26.0, 16.0, 52.0, 25, 'yag_agirlikli'),
      _T('Peynirli kraker', 400, 12.0, 55.0, 15.0, 40, 'karb_agirlikli'),
      _T('Ton balikli kraker', 180, 18.0, 15.0, 5.0, 100, 'protein_agirlikli'),
      _T('Süzme yogurt', 57, 10.0, 3.5, 0.7, 200, 'protein_agirlikli'),
      _T('Sut (laktozsuz)', 48, 3.5, 4.8, 1.5, 250, 'protein_agirlikli'),
      _T('Kefir', 65, 3.3, 4.0, 3.5, 200, 'dengeli'),
      _T('Ayran', 40, 1.7, 2.5, 2.0, 250, 'protein_agirlikli'),
      _T('Meyve suyu (taze)', 45, 0.5, 10.5, 0.1, 250, 'karb_agirlikli'),
      _T('Yesil smoothie', 55, 2.0, 10.0, 0.5, 300, 'karb_agirlikli'),
      _T('Cilek', 32, 0.7, 7.7, 0.3, 150, 'karb_agirlikli'),
      _T('Yaban mersini', 57, 0.7, 14.5, 0.3, 100, 'karb_agirlikli'),
    ];

    // ════════════════════════════════════════════════════
    //  ÖĞLE YEMEKLERİ
    // ════════════════════════════════════════════════════
    final ogleBase = [
      // Et bazlı
      _T('Tavuk gogsu (izgara)', 165, 31.0, 0.0, 3.6, 200, 'protein_agirlikli'),
      _T('Tavuk gogsu (firinda)', 170, 30.0, 2.0, 4.5, 200, 'protein_agirlikli'),
      _T('Tavuk but (firinda)', 209, 26.0, 0.0, 10.9, 180, 'protein_agirlikli'),
      _T('Tavuk sote', 160, 22.0, 5.0, 6.0, 250, 'protein_agirlikli'),
      _T('Hindi gogsu', 135, 30.0, 0.0, 1.0, 200, 'protein_agirlikli'),
      _T('Dana biftek (izgara)', 250, 26.0, 0.0, 15.0, 180, 'protein_agirlikli'),
      _T('Dana kofte (izgara)', 220, 18.0, 5.0, 14.0, 200, 'protein_agirlikli'),
      _T('Dana rosto', 190, 28.0, 0.0, 8.0, 200, 'protein_agirlikli'),
      _T('Kuzu tandir', 250, 20.0, 3.0, 17.0, 200, 'protein_agirlikli'),
      // Balik
      _T('Somon (izgara)', 208, 20.0, 0.0, 13.0, 200, 'protein_agirlikli'),
      _T('Somon (firinda)', 210, 20.5, 0.0, 13.5, 200, 'protein_agirlikli'),
      _T('Levrek (izgara)', 124, 23.0, 0.0, 3.0, 200, 'protein_agirlikli'),
      _T('Ton baligi (konserve)', 116, 26.0, 0.0, 1.0, 150, 'protein_agirlikli'),
      _T('Hamsi tava', 190, 18.0, 5.0, 11.0, 180, 'protein_agirlikli'),
      _T('Karides sote', 100, 21.0, 1.0, 1.5, 200, 'protein_agirlikli'),
      // Sebze + tahıl
      _T('Pilav (pirinc)', 130, 2.7, 28.2, 0.3, 200, 'karb_agirlikli'),
      _T('Bulgur pilavi', 83, 3.1, 18.6, 0.2, 200, 'karb_agirlikli'),
      _T('Kinoa', 120, 4.4, 21.3, 1.9, 200, 'karb_agirlikli'),
      _T('Makarna (tam bugday)', 124, 5.3, 26.5, 0.5, 200, 'karb_agirlikli'),
      _T('Makarna (normal)', 131, 5.0, 25.0, 1.1, 200, 'karb_agirlikli'),
      _T('Kuru fasulye', 127, 8.7, 22.8, 0.5, 200, 'karb_agirlikli'),
      _T('Nohut', 164, 8.9, 27.4, 2.6, 200, 'karb_agirlikli'),
      _T('Mercimek corbasi', 56, 3.6, 8.5, 0.9, 300, 'karb_agirlikli'),
      _T('Kirmizi mercimek', 116, 9.0, 20.0, 0.4, 200, 'karb_agirlikli'),
      // Salatalar
      _T('Tavuklu salata', 120, 15.0, 5.0, 4.5, 300, 'protein_agirlikli'),
      _T('Ton balikli salata', 110, 16.0, 4.0, 3.5, 300, 'protein_agirlikli'),
      _T('Sezar salata', 140, 10.0, 8.0, 8.0, 300, 'dengeli'),
      _T('Yesil salata (zeytinyagli)', 50, 1.5, 5.0, 3.0, 200, 'sebze'),
      _T('Coban salata', 30, 1.0, 4.0, 1.0, 200, 'sebze'),
      // Kombinasyonlar
      _T('Tavuk + pilav', 150, 16.0, 15.0, 3.0, 350, 'dengeli'),
      _T('Tavuk + bulgur', 140, 17.0, 12.0, 3.0, 350, 'dengeli'),
      _T('Tavuk + kinoa', 145, 18.0, 14.0, 3.5, 350, 'dengeli'),
      _T('Kofte + pilav', 180, 12.0, 18.0, 7.0, 350, 'dengeli'),
      _T('Balik + sebze', 130, 18.0, 5.0, 4.0, 350, 'protein_agirlikli'),
      _T('Sebzeli nohut', 100, 5.0, 16.0, 2.0, 300, 'karb_agirlikli'),
      _T('Etli nohut', 140, 10.0, 15.0, 5.0, 300, 'dengeli'),
      _T('Etli kuru fasulye', 135, 9.0, 16.0, 4.5, 300, 'dengeli'),
      _T('Bezelye yemegi', 81, 5.5, 14.4, 0.4, 300, 'karb_agirlikli'),
      _T('Ispanak yemegi', 23, 2.9, 3.6, 0.4, 300, 'sebze'),
      _T('Brokoli (buharda)', 34, 2.8, 7.0, 0.4, 200, 'sebze'),
      _T('Karnabahar (firinda)', 40, 3.0, 5.0, 1.5, 200, 'sebze'),
      _T('Patlican musakka', 95, 4.0, 8.0, 5.5, 300, 'dengeli'),
      _T('Karniyarik', 120, 6.0, 10.0, 7.0, 300, 'dengeli'),
      _T('Imam bayildi', 80, 1.5, 7.0, 5.0, 300, 'sebze'),
      _T('Dolma (zeytinyagli)', 140, 3.0, 22.0, 5.0, 250, 'karb_agirlikli'),
      _T('Yaprak sarma (etli)', 170, 8.0, 15.0, 9.0, 250, 'dengeli'),
    ];

    // ════════════════════════════════════════════════════
    //  AKŞAM YEMEKLERİ (öğle ile benzer ama farklı varyasyonlar)
    // ════════════════════════════════════════════════════
    final aksamBase = [
      _T('Tavuk gogsu (soslu)', 175, 28.0, 5.0, 5.0, 200, 'protein_agirlikli'),
      _T('Tavuk sish', 165, 30.0, 2.0, 4.0, 200, 'protein_agirlikli'),
      _T('Tavuk tantuni', 155, 22.0, 8.0, 4.5, 250, 'protein_agirlikli'),
      _T('Dana antrikot', 271, 26.0, 0.0, 18.0, 180, 'protein_agirlikli'),
      _T('Dana eti sote', 190, 24.0, 4.0, 9.0, 250, 'protein_agirlikli'),
      _T('Kuzu pirzola', 294, 25.0, 0.0, 21.0, 150, 'protein_agirlikli'),
      _T('Somon teriyaki', 220, 21.0, 8.0, 12.0, 200, 'protein_agirlikli'),
      _T('Levrek bugulamasi', 120, 22.0, 0.0, 3.5, 250, 'protein_agirlikli'),
      _T('Alabalik (izgara)', 140, 23.0, 0.0, 5.0, 200, 'protein_agirlikli'),
      _T('Karidesli makarna', 160, 12.0, 20.0, 4.0, 300, 'dengeli'),
      _T('Tavuklu makarna', 155, 14.0, 18.0, 3.5, 300, 'dengeli'),
      _T('Bolonez soslu makarna', 145, 8.0, 18.0, 5.0, 300, 'dengeli'),
      _T('Tavuk wrap', 170, 15.0, 18.0, 4.5, 250, 'dengeli'),
      _T('Fajita (tavuklu)', 150, 14.0, 15.0, 4.0, 300, 'dengeli'),
      _T('Sebze corbasi', 35, 1.5, 6.0, 0.5, 300, 'sebze'),
      _T('Tavuk corbasi', 50, 5.0, 5.0, 1.5, 300, 'protein_agirlikli'),
      _T('Tarhana corbasi', 45, 2.0, 8.0, 0.5, 300, 'karb_agirlikli'),
      _T('Ezogelin corbasi', 65, 3.5, 10.0, 1.5, 300, 'karb_agirlikli'),
      _T('Somon + tatli patates', 160, 14.0, 18.0, 4.5, 350, 'dengeli'),
      _T('Tavuk + tatli patates', 140, 16.0, 16.0, 2.5, 350, 'dengeli'),
      _T('Kofte + salata', 170, 16.0, 5.0, 10.0, 300, 'protein_agirlikli'),
      _T('Et sote + pilav', 160, 14.0, 16.0, 5.0, 350, 'dengeli'),
      _T('Balik + bulgur', 125, 16.0, 12.0, 2.5, 350, 'protein_agirlikli'),
      _T('Sebzeli tavuk guves', 100, 12.0, 8.0, 3.0, 350, 'protein_agirlikli'),
      _T('Etli sebze turlu', 90, 7.0, 8.0, 4.0, 350, 'dengeli'),
      _T('Zeytinyagli fasulye', 80, 4.0, 10.0, 3.0, 300, 'sebze'),
      _T('Zeytinyagli enginar', 70, 2.5, 8.0, 3.5, 300, 'sebze'),
      _T('Zeytinyagli barbunya', 90, 5.0, 12.0, 3.0, 300, 'karb_agirlikli'),
      _T('Patates püresi', 83, 2.0, 17.0, 0.7, 200, 'karb_agirlikli'),
      _T('Tatli patates (firinda)', 90, 2.0, 21.0, 0.1, 200, 'karb_agirlikli'),
    ];

    // ════════════════════════════════════════════════════
    //  GECE ATIŞTIRMASI
    // ════════════════════════════════════════════════════
    final geceBase = [
      _T('Cottage cheese', 98, 11.1, 3.4, 4.3, 150, 'protein_agirlikli'),
      _T('Süzme yogurt', 57, 10.0, 3.5, 0.7, 200, 'protein_agirlikli'),
      _T('Kazein shake', 120, 24.0, 3.0, 1.0, 300, 'protein_agirlikli'),
      _T('Yogurt + chia', 90, 7.0, 8.0, 4.0, 200, 'dengeli'),
      _T('Sut + bal', 70, 3.5, 10.0, 2.0, 250, 'karb_agirlikli'),
      _T('Badem sutu', 17, 0.6, 0.6, 1.3, 250, 'yag_agirlikli'),
      _T('Avokado', 160, 2.0, 8.5, 14.7, 80, 'yag_agirlikli'),
      _T('Lor peyniri + ceviz', 150, 10.0, 5.0, 10.0, 100, 'dengeli'),
      _T('Protein puding', 110, 15.0, 10.0, 2.0, 200, 'protein_agirlikli'),
      _T('Quark', 67, 12.0, 4.0, 0.2, 200, 'protein_agirlikli'),
    ];

    // ═══════════════════════════════════════════════════
    //  VARYASYON ÜRETİCİ
    //
    //  Her temel yemekten 8-15 varyasyon üretir:
    //  - Farklı porsiyon boyutları (S/M/L/XL)
    //  - Farklı pişirme yöntemleri (±%5-10 makro farkı)
    //  - Sos/garnitür eklentileri
    //  Bu sayede 2000+ benzersiz yemek elde edilir.
    // ═══════════════════════════════════════════════════

    // KAHVALTI
    for (final t in kahvaltiBase) {
      final variants = _generateVariants(
        base: t,
        mealTypes: ['kahvalti'],
        goalTags: _goalTagsForKategori(t.kategori),
        idGen: nextId,
      );
      meals.addAll(variants);
    }

    // ARA ÖĞÜN — hem ara_ogun_1 hem ara_ogun_2'ye uygun
    for (final t in araOgunBase) {
      final variants = _generateVariants(
        base: t,
        mealTypes: ['ara_ogun_1', 'ara_ogun_2', 'gece_atistirmasi'],
        goalTags: _goalTagsForKategori(t.kategori),
        idGen: nextId,
      );
      meals.addAll(variants);
    }

    // ÖĞLE
    for (final t in ogleBase) {
      final variants = _generateVariants(
        base: t,
        mealTypes: ['ogle'],
        goalTags: _goalTagsForKategori(t.kategori),
        idGen: nextId,
      );
      meals.addAll(variants);
    }

    // AKŞAM
    for (final t in aksamBase) {
      final variants = _generateVariants(
        base: t,
        mealTypes: ['aksam'],
        goalTags: _goalTagsForKategori(t.kategori),
        idGen: nextId,
      );
      meals.addAll(variants);
    }

    // GECE
    for (final t in geceBase) {
      final variants = _generateVariants(
        base: t,
        mealTypes: ['gece_atistirmasi', 'ara_ogun_2'],
        goalTags: _goalTagsForKategori(t.kategori),
        idGen: nextId,
      );
      meals.addAll(variants);
    }

    return meals;
  }

  /// Kategori'ye göre hangi goal'lere uygun olduğunu belirler.
  static List<String> _goalTagsForKategori(String kategori) {
    switch (kategori) {
      case 'protein_agirlikli':
        return ['cut', 'maintain', 'bulk'];
      case 'karb_agirlikli':
        return ['maintain', 'bulk'];
      case 'yag_agirlikli':
        return ['maintain', 'bulk'];
      case 'dengeli':
        return ['cut', 'maintain', 'bulk'];
      case 'sebze':
        return ['cut', 'maintain'];
      default:
        return ['cut', 'maintain', 'bulk'];
    }
  }

  /// Bir temel yemekten 8-15 varyasyon üretir.
  static List<LocalMeal> _generateVariants({
    required _T base,
    required List<String> mealTypes,
    required List<String> goalTags,
    required String Function() idGen,
  }) {
    final variants = <LocalMeal>[];

    // Porsiyon boyutları ve çarpanları
    final portions = <String, double>{
      '': 1.0,           // Normal
      ' (S)': 0.7,       // Small
      ' (L)': 1.3,       // Large
      ' (XL)': 1.6,      // Extra Large
    };

    // Pişirme varyasyonları (makrolar hafifçe değişir)
    final cookingMods = <String, List<double>>{
      '': [1.0, 1.0, 1.0, 1.0],           // Normal
      ' (az yagli)': [0.92, 1.0, 1.0, 0.7],   // Az yağ
      ' (extra protein)': [1.05, 1.15, 0.95, 0.95], // Protein boost
      ' (light)': [0.85, 0.95, 0.90, 0.80],    // Light versiyon
    };

    for (final pEntry in portions.entries) {
      for (final cEntry in cookingMods.entries) {
        final suffix = '${pEntry.key}${cEntry.key}'.trim();
        final pMul = pEntry.value;
        final cMods = cEntry.value;

        variants.add(LocalMeal(
          id: idGen(),
          ad: '${base.ad}$suffix',
          mealTypes: mealTypes,
          goalTags: goalTags,
          kcalPer100g: base.kcal * cMods[0],
          proteinPer100g: base.protein * cMods[1],
          carbPer100g: base.carb * cMods[2],
          fatPer100g: base.fat * cMods[3],
          defaultPortionG: base.portion * pMul,
          kategori: base.kategori,
        ));
      }
    }

    return variants;
  }

  // ─────────────────────────────────────────────────────
  //  ADJUSTER İTEMLARI (mikro ayar gıdaları)
  // ─────────────────────────────────────────────────────
  static const List<AdjusterItem> adjusterItems = [
    // Protein adjusters
    AdjusterItem(id: 'adj_1', ad: 'Whey protein (ek)', adjustType: 'protein',
        kcalPer100g: 400, proteinPer100g: 80, carbPer100g: 8, fatPer100g: 4,
        minG: 5, maxG: 40),
    AdjusterItem(id: 'adj_2', ad: 'Yumurta beyazi (ek)', adjustType: 'protein',
        kcalPer100g: 52, proteinPer100g: 11, carbPer100g: 0.7, fatPer100g: 0.2,
        minG: 30, maxG: 200),
    AdjusterItem(id: 'adj_3', ad: 'Tavuk gogsu (ek)', adjustType: 'protein',
        kcalPer100g: 165, proteinPer100g: 31, carbPer100g: 0, fatPer100g: 3.6,
        minG: 30, maxG: 150),
    AdjusterItem(id: 'adj_4', ad: 'Ton baligi (ek)', adjustType: 'protein',
        kcalPer100g: 116, proteinPer100g: 26, carbPer100g: 0, fatPer100g: 1,
        minG: 30, maxG: 100),
    AdjusterItem(id: 'adj_5', ad: 'Lor peyniri (ek)', adjustType: 'protein',
        kcalPer100g: 98, proteinPer100g: 11, carbPer100g: 3.4, fatPer100g: 4.3,
        minG: 30, maxG: 150),
    // Carb adjusters
    AdjusterItem(id: 'adj_6', ad: 'Pilav (ek)', adjustType: 'carb',
        kcalPer100g: 130, proteinPer100g: 2.7, carbPer100g: 28.2, fatPer100g: 0.3,
        minG: 30, maxG: 200),
    AdjusterItem(id: 'adj_7', ad: 'Ekmek (ek)', adjustType: 'carb',
        kcalPer100g: 247, proteinPer100g: 13, carbPer100g: 41, fatPer100g: 3.4,
        minG: 20, maxG: 100),
    AdjusterItem(id: 'adj_8', ad: 'Muz (ek)', adjustType: 'carb',
        kcalPer100g: 89, proteinPer100g: 1.1, carbPer100g: 22.8, fatPer100g: 0.3,
        minG: 50, maxG: 200),
    AdjusterItem(id: 'adj_9', ad: 'Bal (ek)', adjustType: 'carb',
        kcalPer100g: 304, proteinPer100g: 0.3, carbPer100g: 82.4, fatPer100g: 0,
        minG: 5, maxG: 30),
    // Fat adjusters
    AdjusterItem(id: 'adj_10', ad: 'Zeytinyagi (ek)', adjustType: 'fat',
        kcalPer100g: 884, proteinPer100g: 0, carbPer100g: 0, fatPer100g: 100,
        minG: 3, maxG: 25),
    AdjusterItem(id: 'adj_11', ad: 'Badem (ek)', adjustType: 'fat',
        kcalPer100g: 579, proteinPer100g: 21.2, carbPer100g: 21.7, fatPer100g: 49.9,
        minG: 5, maxG: 40),
    AdjusterItem(id: 'adj_12', ad: 'Avokado (ek)', adjustType: 'fat',
        kcalPer100g: 160, proteinPer100g: 2, carbPer100g: 8.5, fatPer100g: 14.7,
        minG: 20, maxG: 80),
    AdjusterItem(id: 'adj_13', ad: 'Ceviz (ek)', adjustType: 'fat',
        kcalPer100g: 654, proteinPer100g: 15.2, carbPer100g: 13.7, fatPer100g: 65.2,
        minG: 5, maxG: 30),
    AdjusterItem(id: 'adj_14', ad: 'Tereyagi (ek)', adjustType: 'fat',
        kcalPer100g: 717, proteinPer100g: 0.9, carbPer100g: 0.1, fatPer100g: 81.1,
        minG: 3, maxG: 20),
    // Kombine adjuster (protein + carb)
    AdjusterItem(id: 'adj_15', ad: 'Sut (ek)', adjustType: 'protein',
        kcalPer100g: 50, proteinPer100g: 3.3, carbPer100g: 4.8, fatPer100g: 1.8,
        minG: 50, maxG: 300),
    AdjusterItem(id: 'adj_16', ad: 'Yulaf (ek)', adjustType: 'carb',
        kcalPer100g: 389, proteinPer100g: 16.9, carbPer100g: 66.3, fatPer100g: 6.9,
        minG: 10, maxG: 50),
  ];
}

/// Temel yemek şablonu (internal).
class _T {
  final String ad;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  final double portion;
  final String kategori;

  const _T(this.ad, this.kcal, this.protein, this.carb, this.fat,
      this.portion, this.kategori);
}
