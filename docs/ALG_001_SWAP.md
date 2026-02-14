# ALG-001: Swap Alternatives Entegrasyonu

## Gereksinimler

Backend servisi çalışıyor olmalı:
```bash
# zindeai-swap-alternatives-service repo'sunda:
docker compose up --build -d
curl -s http://localhost:8000/health
# {"status":"healthy","version":"8.3.1"}
```

## Flutter Çalıştırma

### Android Emulator (default)
```bash
flutter run --dart-define=ALGO_BASE_URL=http://10.0.2.2:8000
```

### iOS Simulator
```bash
flutter run --dart-define=ALGO_BASE_URL=http://127.0.0.1:8000
```

### Quick Tunnel (telefon testi)
```bash
# Terminal 1: Backend
docker compose up -d

# Terminal 2: Tunnel
cloudflared tunnel --url http://localhost:8000
# Çıktı: https://random-slug.trycloudflare.com

# Terminal 3: Flutter
flutter run --dart-define=ALGO_BASE_URL=https://random-slug.trycloudflare.com
```

## Config Detayları (Issue #19: Hardening)

`AlgoConfig.baseUrl` deterministik öncelik:
1. **dart-define** (`--dart-define=ALGO_BASE_URL=...`) → geçerli http/https URL kontrolü
2. **dotenv** (`assets/.env` → `ALGO_BASE_URL=...`) → geçerli http/https URL kontrolü
3. **Safe fallback** → `http://10.0.2.2:8000` (Android emulator host)

Web notu: `flutter_dotenv` erişimi kısıtlı, dart-define tercih edilir.

Invalid URL (boş, scheme yok, host yok) → fallback'e düşer, crash yapmaz.

## Test
```bash
flutter test test/services/algo_client_test.dart
# 8 passed (config validation + API tests)
```

## Değişen Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `lib/services/algo_config.dart` | ALGO_BASE_URL dart-define config |
| `lib/services/algo_client.dart` | HTTP client (retry/backoff) |
| `lib/services/models/swap_models.dart` | Request/Response modelleri |
| `lib/services/errors.dart` | InsufficientPoolException eklendi |
| `lib/widgets/meal_card.dart` | Swap buton → API entegrasyonu |
| `test/services/algo_client_test.dart` | 5 unit test (200, 422, retry) |
| `docs/ALG_001_SWAP.md` | Bu dosya |
