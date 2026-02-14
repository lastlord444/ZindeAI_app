/// Macro adjuster — bu modül artık local_plan_generator.dart içinde entegre.
///
/// [LocalPlanGenerator._tryAdjust] metodu adjuster mantığını içerir.
/// Bu dosya sadece referans ve import kolaylığı için korunuyor.
///
/// Adjuster stratejileri:
/// 1. Yağ açığı: zeytinyağı, hindistan cevizi yağı, avokado, badem (5-15g)
/// 2. Protein açığı: whey protein, süzme yoğurt, lor peyniri (15-150g)
/// 3. Karb açığı: pirinç, tam buğday ekmek, muz, bal (25-120g)
///
/// Adjuster item'ları [MealDatabase.adjusterItems] listesinde tanımlıdır.
library macro_adjuster;
