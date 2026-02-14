# Changelog — ZindeAI

Tüm önemli değişiklikler bu dosyada dokümante edilir.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) + [Semantic Versioning](https://semver.org/)

---

## [Unreleased]

### Planned
- Swap Alternatives: Porsiyon seçimi (Small/Medium/Large)
- CI: Build artifact + coverage report otomasyonu

---

## [0.3.1] - 2026-02-14

### Added
- E2E smoke tests (8 scenarios, 28 tests total) → `test/e2e_smoke_test.dart`
- CI: Coverage summary + artifact uploads (apk + lcov)
- Config hardening: `ALGO_BASE_URL` validation + web-safe fallback

### Fixed
- ALGO_BASE_URL: Invalid URL crash → safe fallback
- Web platformda dotenv erişim hatası → try/catch + log

### Changed
- `docs/ALG_001_SWAP.md`: Config hardening notu eklendi
- CI workflow: `flutter test --coverage` + lcov summary
- `lib/services/algo_config.dart`: URL validation + LogService entegrasyonu

---

## [0.3.0] - 2026-02-14

### Added
- Swap Alternatives UX polish: loading indicator + retry buton
- Weekly summary: macro totals + adherence calculation
- Plan ekranı performans optimizasyonu (rebuild azaltma)
- Minimal error logging service (`LogService`)
- Offline-first cache (`PlanCacheService`, 24h TTL)

### Fixed
- Weekly summary: NaN/Infinity handling + empty week edge case
- Plan ekranı: gereksiz rebuild'ler → `ValueNotifier` + `const` widgets

### Changed
- `lib/widgets/weekly_summary.dart`: doğru toplam + adherence hesabı
- `lib/screens/generate_plan_screen.dart`: rebuild optimizasyonu
- `lib/services/plan_cache_service.dart`: cache + TTL logic

---

## [0.2.0] - 2026-02-13

### Added
- ALG-001: Swap Alternatives backend entegrasyonu
- `AlgoClient`: HTTP client (retry/backoff logic)
- `SwapAlternativesRequest/Response` modelleri
- Swap buton: MealCard widget'ına entegrasyon
- 422 INSUFFICIENT_POOL handling → friendly error message

### Changed
- `lib/services/algo_config.dart`: dart-define + dotenv precedence
- `lib/widgets/meal_card.dart`: swap buton + API call
- `docs/ALG_001_SWAP.md`: backend API kontratı (v8.3.1)

---

## [0.1.0] - 2026-02-10

### Added
- İlk çalışan prototip
- Plan oluşturma ekranı (goal + budget seçimi)
- Günlük plan görünümü (meal cards)
- Haftalık plan görünümü (skeleton)
- Mock `PlanService` (backend bağımsız)

---

## Changelog Formatı

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Yeni özellik A

### Fixed
- Bug B düzeltildi

### Changed
- Modül C güncellendi

### Deprecated
- Eski API D artık kullanılmıyor

### Removed
- Eski kod E silindi

### Security
- Güvenlik açığı F kapatıldı
```
