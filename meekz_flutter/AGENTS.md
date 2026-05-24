# AGENTS.md — Meekz Codex Rules

## Project Overview

Meekz is a Flutter/Firebase mobile-based gamified screening prototype for Malaysian children aged 6 to 8.
It provides preliminary learning-related risk indicators across three domains: literacy, numeracy, and attention-related task behaviour.

Meekz is NOT a diagnostic system. It does not diagnose, confirm, detect, or label any learning disability.
The AI-assisted component explains rule-based screening outputs only. It does not generate or decide screening results.

---

## Hard Rules — Never Violate Under Any Circumstance

1. Never call OpenRouter or any external AI API directly from Flutter.
   All AI calls must go through Firebase Cloud Functions only.

2. Never hardcode API keys, secrets, or credentials in any file.
   Use Firebase environment config or Google Secret Manager only.
   The OPENROUTER_API_KEY must only be accessed via process.env inside Cloud Functions.

3. Never send the following data to OpenRouter or any external API:
   - Child full name
   - School name
   - Parent contact details
   - Raw game response history
   - Any personally identifiable information (PII)
   Only anonymized, structured screening output fields are permitted.

4. Never use the following words or phrases in any user-facing string, UI label,
   result text, explanation text, recommendation text, or notification:
   - diagnosed
   - confirmed disorder
   - has dyslexia
   - has dyscalculia
   - has ADHD
   - ADHD confirmed
   - dyslexia detected
   - dyscalculia detected
   - disorder identified
   - learning disability confirmed
   - learning disability detected
   - clinical diagnosis
   - confirmed learning disability

5. Never modify the rule-based classification logic in lib/classification/
   without an explicit instruction that specifically names that folder and file.

6. Never modify the safety filter in functions/safety/safetyFilter.js
   without an explicit instruction that specifically names that file.

7. Never remove, disable, or bypass the template fallback system in functions/templates/.
   The app must always be able to produce a result without calling OpenRouter.

8. Never store child names, school names, parent contact details, or any PII
   in Firestore result documents.

9. Never upgrade Flutter package versions or Node.js dependency versions
   unless explicitly instructed to do so.

10. Never introduce Python, TypeScript, or any language other than Dart (Flutter)
    and Node.js (Cloud Functions) without explicit permission.

---

## Screening Domain Rules

- The three screening domains are:
  1. Literacy-related indicators
  2. Numeracy-related indicators
  3. Attention-related task-behaviour indicators

- Domain indicators use only these values: low / moderate / high / inconclusive
  Never use: medium, severe, normal, abnormal, positive, negative, pass, fail

- The overall indicator uses the same four values: low / moderate / high / inconclusive

- The reliability flag uses only these values: valid / caution / invalid

- Attention-related indicators must never be labelled as ADHD indicators.
  Use "attention-related task-behaviour indicator" only.

- ADHD, dyslexia, and dyscalculia may appear only as background context in comments
  or documentation. Never use them in user-facing strings.

---

## AI Explanation Rules

- The AI explanation flow is:
  Flutter → Firebase Cloud Function → OpenRouter → Safety Filter → Firestore

- The Cloud Function must validate all inputs before calling OpenRouter.

- The AI prompt must instruct the model to:
  - Respond only in the selectedLanguage field
  - Explain the rule-based result in simple, adult-friendly language
  - Keep explanation under 150 words
  - Never use forbidden diagnostic wording (see Hard Rules above)
  - State clearly that the result is a preliminary screening indicator only
  - Recommend further professional observation for moderate or high overall indicators

- The safety filter must block and discard any AI output containing forbidden phrases.

- If the safety filter fails, or if the Cloud Function call times out or errors,
  the system must silently return the appropriate template fallback.
  The user must never see a raw error, a blank screen, or an unresolved spinner.

- Flutter must apply an 8-second timeout to the Cloud Function call.
  If no response is received within 8 seconds, use the local template fallback.

- The "source" field (ai or template) must be stored in Firestore for logging only.
  Never display it to the user.

---

## Folder Structure — Do Not Restructure Without Permission

```
meekz/
├── AGENTS.md
├── lib/
│   ├── classification/        ← Rule-based classification logic only. Do not touch without explicit instruction.
│   ├── models/                ← Dart data models (ScreeningResult, domain models)
│   ├── screens/               ← Flutter UI screens
│   ├── services/              ← Firebase and Cloud Function call services
│   └── widgets/               ← Reusable UI components
├── functions/
│   ├── index.js               ← Cloud Function entry point
│   ├── safety/
│   │   └── safetyFilter.js   ← Forbidden phrase checker. Do not touch without explicit instruction.
│   └── templates/
│       ├── en.js              ← English fallback templates
│       ├── ms.js              ← Bahasa Melayu fallback templates
│       └── zh.js              ← Mandarin fallback templates
├── test/
│   ├── classification_test/   ← Unit tests for rule-based classification
│   └── functions_test/        ← Tests for Cloud Function behaviour
└── .env.example               ← Lists required environment variables. No real values.
```

- Do not create files outside this structure without explicit permission.
- Do not rename folders, files, classes, or variables without explicit instruction.
- Do not move files between folders without explicit instruction.

---

## When Making Changes

- Change only the files explicitly named in the task instruction.
- If you believe another file needs to change, stop and ask before touching it.
- Do not refactor code that is not directly related to the current task.
- Do not remove or rewrite existing comments unless instructed.
- Do not change code formatting or indentation style in files you are not actively modifying.
- Preserve all existing function signatures unless the task explicitly requires changing them.

---

## Result Summary Screen Rules

The result summary screen must display:
- Domain indicators with colour coding: low = green, moderate = amber, high = red, inconclusive = grey
- Overall indicator
- Reliability flag (show only if caution or invalid — do not show "valid" as a label)
- Explanation text
- Recommendation text
- Disclaimer text (always visible, smaller font, grey italic style)
- A "What should I do next?" referral guidance section based on overall indicator

The result summary screen must never display:
- The words diagnosed, ADHD, dyslexia, or dyscalculia in a confirmatory context
- The source field (whether result came from AI or template)
- Raw JSON or any technical output
- Unhandled error messages

---

## Testing Rules

- After any change to lib/classification/, run all tests in test/classification_test/.
- After any change to functions/, run all tests in test/functions_test/.
- Do not mark a task as complete if any test fails.
- If a test file does not exist yet for the area being modified, create it before completing the task.

---

## Multilingual Rules

- Meekz supports three languages: English (en), Bahasa Melayu (ms), Mandarin (zh).
- All user-facing strings must be available in all three languages.
- Template fallbacks must exist for all combinations of language and overall indicator.
- Never hard-code a language string in a screen or widget directly.
  Always reference the language service or localization system.

---

## Security Rules

- .env must be listed in .gitignore. Never commit a .env file with real values.
- Only .env.example (with placeholder values) may be committed to the repository.
- Firebase rules (firestore.rules) must restrict read/write access to authenticated users only.
- No Firestore document may be publicly readable or writable.

---

## Scope Boundary Reminder

Every Codex task should specify which files or folders are in scope.
If a task does not specify a scope, ask for clarification before making any changes.
Default assumption: only the file(s) explicitly named in the task are in scope.
All other files are out of scope unless stated otherwise.
