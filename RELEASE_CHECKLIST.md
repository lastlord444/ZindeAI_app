# Release Checklist — ZindeAI

Her release öncesi bu listeyi takip edin.

## Pre-Release

- [ ] `CHANGELOG.md` güncelle (yeni versiyon + tarih + değişiklikler)
- [ ] `pubspec.yaml` → `version` alanını güncelle (semver + build number)
- [ ] `flutter analyze` → **No issues found**
- [ ] `flutter test` → **All tests passed**
- [ ] `flutter build apk --release` → başarılı build
- [ ] Açık PR yok (`gh pr list --state open`)
- [ ] v8.3.1 uyumluluk: `docs/ALG_001_SWAP.md` referansı korunmuş

## Release

- [ ] `main` branch'inde son commit'te tüm değişiklikler mevcut
- [ ] Git tag oluştur: `git tag -a v0.X.Y -m "Release v0.X.Y"`
- [ ] Tag'i push et: `git push origin v0.X.Y`
- [ ] GitHub Release oluştur (tag'den): `gh release create v0.X.Y --generate-notes`

## Post-Release

- [ ] APK/AAB'yi test cihazına yükle ve smoke test yap
- [ ] Backend uyumluluğunu doğrula (`/health` endpoint)
- [ ] Sonraki sprint için yeni issue'lar oluştur
- [ ] `CHANGELOG.md`'ye "Unreleased" başlığı ekle

## Notlar

- Versiyon stratejisi için bkz: [VERSIONING.md](VERSIONING.md)
- Changelog formatı için bkz: [CHANGELOG.md](CHANGELOG.md)
- Backend API kontratı: `docs/ALG_001_SWAP.md`
