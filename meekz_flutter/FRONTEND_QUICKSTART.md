# Meekz Flutter — Quick Start

## 1. Install dependencies
Open a terminal in `meekz_flutter/` and run:

```bash
flutter pub get
```

## 2. Run the app
```bash
flutter run
```

> **Note:** The app requires a `google-services.json` (Android) or `GoogleService-Info.plist`
> (iOS) file in the appropriate platform folder before it will connect to Firebase.
> Download these from the Firebase Console → Project Settings → Your Apps.

## 3. File structure created

```
meekz_flutter/lib/
├── main.dart                          ← App entry (ProviderScope + router + theme)
├── meekz_backend.dart                 ← Backend barrel export (unchanged)
└── src/
    ├── models/          ← Existing (unchanged)
    ├── services/        ← Existing (unchanged)
    ├── constants/       ← Existing (unchanged)
    └── ui/              ← NEW — all frontend code
        ├── theme/
        │   └── meekz_theme.dart       ← Colours, spacing, MaterialApp theme
        ├── providers/
        │   └── app_providers.dart     ← Riverpod providers
        ├── router/
        │   └── app_router.dart        ← go_router + auth guard
        ├── widgets/
        │   └── shared_widgets.dart    ← Buttons, pills, cards, banners
        └── screens/
            ├── onboarding/
            │   └── onboarding_screen.dart
            ├── auth/
            │   └── auth_screen.dart
            ├── dashboard/
            │   └── dashboard_screen.dart
            ├── child/
            │   └── child_profile_form_screen.dart
            ├── assessment/
            │   └── assessment_menu_screen.dart
            ├── game/
            │   └── game_screen.dart
            └── report/
                └── report_screen.dart
```
