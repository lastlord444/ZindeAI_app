/// Porsiyon boyutu enum'u ve lokal makro hesaplaması.
///
/// Backend'de (calc_raw) porsiyon bazlı hesaplama var ama /get-alternatives
/// endpoint'i şu an hep "medium" kullanıyor. Bu dosya Flutter tarafında
/// UI-only porsiyon seçimi sağlar.
///
/// Oranlar (DB ortalaması baz alınmıştır):
///   small  = 0.60x (orta porsiyonun %60'ı)
///   medium = 1.00x (default)
///   large  = 1.50x (orta porsiyonun %150'si)
library;

/// Porsiyon boyutu.
enum PortionSize {
  small('S', 'Küçük', 0.60),
  medium('M', 'Orta', 1.00),
  large('L', 'Büyük', 1.50);

  /// Kısa etiket (S/M/L).
  final String label;

  /// Türkçe ad.
  final String displayName;

  /// Medium'a göre çarpan.
  final double multiplier;

  const PortionSize(this.label, this.displayName, this.multiplier);
}

/// API'den gelen medium bazlı makro değerlerini seçilen porsiyona göre ölçekler.
///
/// [baseKalori], [baseProtein], [baseKarb], [baseYag] değerleri
/// API'den gelen medium porsiyon değerleridir.
/// [basePorsiyonG] medium porsiyon gramıdır.
/// [portion] seçilen porsiyon boyutudur.
///
/// Dönen map: {kalori, protein, karb, yag, porsiyonG} — hepsi double.
Map<String, double> scaleToPortionSize({
  required double baseKalori,
  required double baseProtein,
  required double baseKarb,
  required double baseYag,
  required double basePorsiyonG,
  required PortionSize portion,
}) {
  final m = portion.multiplier;
  return {
    'kalori': _round1(baseKalori * m),
    'protein': _round1(baseProtein * m),
    'karb': _round1(baseKarb * m),
    'yag': _round1(baseYag * m),
    'porsiyonG': _round1(basePorsiyonG * m),
  };
}

/// Tek ondalık basamağa yuvarla.
double _round1(double value) {
  return (value * 10).roundToDouble() / 10;
}
