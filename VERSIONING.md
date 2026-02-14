# Versioning Strategy — ZindeAI

## Semantic Versioning (SemVer)

Format: `MAJOR.MINOR.PATCH+BUILD`

Örnek: `0.3.1+12`

| Segment | Ne zaman artırılır? | Örnek |
|---------|---------------------|-------|
| **MAJOR** | Breaking change (API kontratı değişikliği, veri modeli kırılması) | `0.x.x` → `1.0.0` |
| **MINOR** | Yeni özellik (geriye uyumlu) | `0.2.x` → `0.3.0` |
| **PATCH** | Hata düzeltme, küçük iyileştirme | `0.3.0` → `0.3.1` |
| **BUILD** | Her CI build'de otomatik artır | `0.3.1+11` → `0.3.1+12` |

## pubspec.yaml

```yaml
version: 0.3.1+12
```

Flutter bu değeri otomatik olarak:
- **Android:** `versionName` = `0.3.1`, `versionCode` = `12`
- **iOS:** `CFBundleShortVersionString` = `0.3.1`, `CFBundleVersion` = `12`

## Versiyon Artırma Kuralları

### PATCH artır (0.3.0 → 0.3.1)
- Bug fix
- Typo düzeltme
- Performans iyileştirme (API değişikliği yok)
- Test ekleme
- Docs güncelleme

### MINOR artır (0.3.x → 0.4.0)
- Yeni ekran / özellik ekleme
- Yeni API endpoint entegrasyonu
- UI/UX değişikliği (mevcut davranış korunur)

### MAJOR artır (0.x.x → 1.0.0)
- Veri modeli kırılması (migration gerekli)
- Backend API kontratı değişikliği (v8.3.x → v9.x)
- Minimum SDK versiyon değişikliği

## Build Number

- Her PR merge'inde +1 artırılır
- CI'da otomatik artırma (opsiyonel): `flutter build apk --build-number=${{ github.run_number }}`
- Manuel: `pubspec.yaml`'da `+N` kısmını artır

## Git Tag

```bash
# Release tag oluştur
git tag -a v0.3.1 -m "Release v0.3.1: bug fixes + config hardening"
git push origin v0.3.1

# GitHub Release
gh release create v0.3.1 --generate-notes
```

## Mevcut Versiyon Geçmişi

| Versiyon | Tarih | Notlar |
|----------|-------|--------|
| `0.1.0` | 2026-02 | İlk çalışan prototip (plan oluştur + günlük görünüm) |
| `0.2.0` | 2026-02 | ALG-001 Swap Alternatives entegrasyonu |
| `0.3.0` | 2026-02 | UX polish, weekly summary, performance, logging, cache |
| `0.3.1` | 2026-02 | E2E smoke test, CI coverage, config hardening |
