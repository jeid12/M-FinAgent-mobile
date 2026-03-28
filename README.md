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
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## Android Real Device Setup

1. Start backend on your laptop:

```bash
cd M-FinAgent-backend
/Users/mac/Documents/projects/gdg/bhk/.venv/bin/python -m uvicorn main:app --reload --port 8000
```

2. Ensure phone and laptop are on the same Wi-Fi.

3. Find your laptop LAN IP (example `192.168.1.20`) and run Flutter with that URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

4. Grant SMS permissions on first launch. The app listens for MTN/Airtel messages and ingests supported SMS into backend automatically while the app is open.

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
