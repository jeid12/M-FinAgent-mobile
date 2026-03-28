# M-FinAgent Mobile

Flutter app (Android, iOS, macOS) for transaction feed, realtime alerts, and AI chat coaching.

## Run

```bash
cd M-FinAgent-mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

For Android emulator using local backend, use host `10.0.2.2`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Test

```bash
flutter test
```

## Backend contract

- Ingest SMS: `POST /v1/transactions/ingest`
- Transactions feed: `GET /v1/transactions?phone_number=...`
- Summary: `GET /v1/transactions/summary?phone_number=...&days=7`
- AI Chat: `POST /v1/chat`
- Realtime alerts: `WS /v1/alerts/ws/{phone_number}`
