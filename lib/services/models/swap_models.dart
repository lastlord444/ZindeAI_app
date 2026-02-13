/// Swap Alternatives API modelleri (ALG-001).
library;

/// /get-alternatives isteği.
class SwapAlternativesRequest {
  final String yemekId;
  final String ogunSlot;
  final String diyetTipi;
  final List<String> alerjenler;
  final List<String> son7GunYemekler;

  const SwapAlternativesRequest({
    required this.yemekId,
    required this.ogunSlot,
    this.diyetTipi = 'normal',
    this.alerjenler = const [],
    this.son7GunYemekler = const [],
  });

  Map<String, dynamic> toJson() => {
        'yemek_id': yemekId,
        'ogun_slot': ogunSlot,
        'diyet_tipi': diyetTipi,
        'alerjenler': alerjenler,
        'son_7_gun_yemekler': son7GunYemekler,
      };
}

/// /get-alternatives 200 yanıtındaki tek bir alternatif yemek.
class AlternativeMeal {
  final String yemekId;
  final String ad;
  final String porsiyon;
  final double porsiyonG;
  final double kalori;
  final double protein;
  final double karb;
  final double yag;

  const AlternativeMeal({
    required this.yemekId,
    required this.ad,
    required this.porsiyon,
    required this.porsiyonG,
    required this.kalori,
    required this.protein,
    required this.karb,
    required this.yag,
  });

  factory AlternativeMeal.fromJson(Map<String, dynamic> json) {
    return AlternativeMeal(
      yemekId: json['yemek_id'] as String,
      ad: json['ad'] as String,
      porsiyon: json['porsiyon'] as String,
      porsiyonG: (json['porsiyon_g'] as num).toDouble(),
      kalori: (json['kalori'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      karb: (json['karb'] as num).toDouble(),
      yag: (json['yag'] as num).toDouble(),
    );
  }
}

/// /get-alternatives 200 yanıtı.
class SwapAlternativesResponse {
  final List<AlternativeMeal> alternatives;
  final int count;
  final String tolerance;

  const SwapAlternativesResponse({
    required this.alternatives,
    required this.count,
    required this.tolerance,
  });

  factory SwapAlternativesResponse.fromJson(Map<String, dynamic> json) {
    return SwapAlternativesResponse(
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((e) => AlternativeMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int,
      tolerance: json['tolerance'] as String,
    );
  }
}
