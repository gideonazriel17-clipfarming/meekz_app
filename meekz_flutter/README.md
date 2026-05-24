# Meekz Flutter Backend Scaffold

Meekz is a Flutter + Firebase prototype for preliminary learning-related risk indicators among Malaysian early primary children aged 6 to 8.

This scaffold implements the backend-facing app layer:

- Firebase Authentication for adult users only.
- Cloud Firestore service classes for users, children, screening sessions, game results, risk classifications, and result summaries.
- Client-side rule-based classification isolated in `RiskClassificationService`.
- Template-based, non-diagnostic result summary generation.
- Firestore security rules for owner-only access and age/enum validation.

Meekz is not a diagnostic system. It does not diagnose dyslexia, dyscalculia, ADHD, or any learning disability.

For FYP1, Meekz uses controlled template-based explanations only. External AI integration is future work and is not part of the current implementation baseline.

## Local Setup

Flutter, Dart, and Firebase CLI must be installed before running this project.

```powershell
cd meekz_flutter
flutter create . --platforms=android,ios
flutter pub get
flutterfire configure
flutter test
```

`flutter create .` fills in native platform folders that could not be generated in this workspace because the Flutter CLI is not currently installed. After `flutterfire configure`, initialize Firebase in the app using the generated `firebase_options.dart` if your platform setup requires explicit options.

## Firebase Rules

Deploy Firestore rules after reviewing the Firebase project:

```powershell
firebase deploy --only firestore:rules
```
