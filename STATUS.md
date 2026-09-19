# Sanad — Development Status

## Current environment

- Flutter 3.47.4 / Dart 3.13.3 installed at `/data/tools/flutter`.
- Host: Debian Linux.
- Android SDK, Java, ADB: not installed.
- macOS/Xcode: unavailable on this host.
- Therefore Android/iOS release builds cannot yet be produced here.

## Implemented

- Flutter project created for Android/iOS/Web.
- App identity: `ly.sanad.sanad`.
- Arabic RTL starter home screen.
- Customer-facing service cards.
- Initial booking bottom sheet.
- Initial unified-app direction; worker role/backend still to be implemented.
- Initial tests for home services and opening a booking request.

## Verification

Commands executed successfully:

```text
flutter analyze
No issues found!

flutter test
All tests passed!
```

## Not yet implemented

- Backend and database.
- Authentication/SMS.
- Customer/worker role permissions.
- Real orders, offers, matching, chat, notifications.
- Cash settlement ledger and commission rules.
- Worker verification.
- Complaints and warranty.
- Production admin dashboard.
- Android SDK/release build.
- macOS/Xcode/iOS release build.
- Store signing and publishing.

## Next engineering slice

Build the domain/backend contract and a local in-memory vertical slice for:

```text
create request → submit offer → accept offer → complete service → review
```

Then replace the in-memory repository with a secured backend.
