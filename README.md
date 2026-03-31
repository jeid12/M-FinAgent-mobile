# M-FinAgent Mobile

Flutter app (Android, iOS, macOS) for transaction feed, realtime alerts, and AI chat coaching.

## Problem Statement

Despite the widespread use of MTN MoMo and Airtel Money in Rwanda, users lack clear visibility into daily cash flow because financial history is scattered across isolated SMS notifications. This creates invisible spending, weak budgeting discipline, and missed savings goals.

## Proposed Solution

M-FinAgent provides a proactive AI financial co-pilot experience.

- Capture mobile money SMS notifications from MTN/Airtel.
- Convert raw SMS into structured transactions through FastAPI.
- Store and analyze transaction behavior in PostgreSQL.
- Trigger real-time overspending alerts and actionable coaching.
- Enable conversational planning in chat for what-if scenarios.

## Technical Architecture Flow

1. Capture: Flutter listens to MTN/Airtel SMS events.
2. Process and Store: FastAPI extracts amount and merchant, classifies transaction, and stores data.
3. Analyze and Alert: AI agent evaluates new transactions versus history and sends warnings/tips.
4. Converse: User opens Chat to ask personalized spending and affordability questions.

## Run

```bash
cd m_finagent_mobile
flutter pub get
flutter run
```

Default backend URL is `https://m-finagent-backend.onrender.com`.

If you want to run against a local backend instead:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=ANDROID_EMULATOR=true
```

## Android Real Device Setup

1. Start backend on your laptop:

```bash
cd M-FinAgent-backend
/Users/mac/Documents/projects/gdg/bhk/M-FinAgent-backend/.venv/bin/python -m uvicorn main:app --app-dir /Users/mac/Documents/projects/gdg/bhk/M-FinAgent-backend --host 0.0.0.0 --port 8000
```

2. Ensure phone and laptop are on the same Wi-Fi.

3. Find your laptop LAN IP (example `192.168.1.20`) and run Flutter with that URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

4. Register/login in the app with phone number + password (minimum 8 chars).

4. Grant SMS permissions on first launch. The app listens for MTN/Airtel messages and ingests supported SMS into backend automatically while the app is open.

For Android emulator using local backend, use host `10.0.2.2`:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=ANDROID_EMULATOR=true
```

## Troubleshooting: Failed host lookup

If you see a SocketException like `Failed host lookup`, the app cannot resolve the backend hostname from the running device.

- Android emulator + local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=ANDROID_EMULATOR=true
```

- iOS simulator + local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

- Physical device + local backend (replace with your laptop LAN IP):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Also ensure your backend is running with `--host 0.0.0.0 --port 8000` and device/laptop are on the same network when testing local APIs.

## Test

```bash
flutter test
```

## Backend contract

- Ingest SMS: `POST /v1/transactions/ingest`
- Transactions feed: `GET /v1/transactions?limit=50`
- Summary: `GET /v1/transactions/summary?days=7`
- AI Chat: `POST /v1/chat` with `{ "question": "..." }`
- Realtime alerts: `WS /v1/alerts/ws/me`
