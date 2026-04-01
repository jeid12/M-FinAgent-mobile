# Google Play SMS Permissions Declaration Package

App: MFinAgent
Package: com.mfinagent.mobile
Core feature: Automatic financial transaction ingestion from incoming and historical SMS to build spending feed, summaries, and AI financial guidance.

## 1) Permissions Requested
- android.permission.RECEIVE_SMS
- android.permission.READ_SMS

## 2) Why SMS Is Core Functionality
MFinAgent is a personal finance app that automatically converts mobile-money and bank transaction SMS into a structured financial ledger.
Without SMS access, the app cannot perform its primary feature set:
- automatic transaction capture
- real-time feed updates
- spending summaries and balance insights
- AI financial coaching based on actual transaction history

SMS parsing is not a secondary/optional marketing feature. It is the primary ingestion channel that powers the product's core user experience.

## 3) User Benefit Statement (Play Form Ready)
MFinAgent reads transaction SMS from providers such as MTN MoMo, Airtel Money, and bank alerts to automatically build a personal finance timeline for the user. This eliminates manual bookkeeping and enables real-time spending analysis, budget warnings, and savings recommendations.

## 4) Data Handling Statement (Play Form Ready)
- We process only SMS relevant to financial transactions.
- SMS is used only to extract transaction data (amount, direction, counterparty, timestamp, provider).
- Data is used to provide in-app finance features for the account owner.
- We do not sell SMS data.
- Users can revoke SMS permission from Android settings at any time.

## 5) Prominent In-App Disclosure (Before Permission Prompt)
Show this text before triggering runtime SMS permission dialog:

Title: Allow SMS Access for Automatic Transaction Tracking
Body: MFinAgent uses SMS access to detect mobile-money and bank transaction messages and automatically build your spending feed and financial insights. We only use relevant financial SMS content to power this app experience. You can disable SMS access anytime in Android settings.
Buttons:
- Continue
- Not now

## 6) Required Demo Video Checklist (for Play review)
Create a short unlisted YouTube video (2-5 minutes) showing:
1. App launch and login.
2. Screen explaining why SMS access is needed.
3. Runtime prompt for READ_SMS/RECEIVE_SMS and user approval.
4. Incoming SMS (or historical fetch) being ingested.
5. Transactions appearing in feed.
6. Summary/insights updated from ingested SMS.
7. Profile/settings path where user can continue using app and optionally revoke permission at OS level.

## 7) Play Console Permissions Declaration Answers (Suggested)
Use case category:
- Core app functionality

Why permission is needed:
- App reads financial transaction SMS to automatically create a personal finance ledger and insights.

What happens if denied:
- Automatic ingestion is disabled; user can still open app but core transaction automation features are limited.

Data sharing:
- Not sold.
- Used only to provide user-requested finance features.

## 8) Reviewer Notes (paste in Play Console if needed)
MFinAgent is a finance tracking application whose primary function is to ingest and classify transaction SMS from local mobile-money and banking providers. SMS access is necessary to provide the app's advertised automatic tracking and AI analysis features. The app requests SMS permissions only to power this core functionality.

## 9) Submission Attachments to Prepare
- Privacy Policy URL updated with SMS usage section.
- Demo video URL.
- Screenshots of disclosure and permission prompt.
- Confirmation that app behavior matches declared use.
