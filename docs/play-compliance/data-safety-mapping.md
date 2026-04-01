# Google Play Data Safety Mapping (Draft)

Important: confirm with your final backend behavior and legal policy before submission.

## Data Collected
- Personal info: phone number/account identifier
- Financial info: transaction details parsed from SMS
- App activity: in-app interactions/chat history (if enabled)

## Purpose
- App functionality (core transaction tracking and insights)
- Analytics/diagnostics (if enabled)

## Sharing
- Not sold.
- Shared only with service providers required to operate app infrastructure (if applicable).

## Processing Scope
- SMS data is processed to extract financial transactions relevant to user account features.

## Security
- Use HTTPS for API transport.
- Restrict backend/data access by authentication and authorization.

## User Controls
- User can revoke SMS permission in OS settings.
- User can stop using automatic ingestion features.
