# MyDay — Development Setup Instructions

## Prerequisites
- **Flutter SDK**: 3.44+
- **Dart SDK**: 3.12+
- **Node.js**: v20+ / v22+
- **npm**: 10+
- **Android Studio / Android SDK** (API 34+)

## Mobile Setup
```bash
cd apps/mobile
flutter pub get
flutter gen-l10n
flutter test
```

## Web Landing Setup
```bash
cd apps/web
npm install
npm run dev
```

## Super Admin Console Setup
```bash
cd apps/admin
npm install
npm run dev
```

## Linting and Code Quality
```bash
# Mobile static analysis
cd apps/mobile
flutter analyze
dart format --set-exit-if-changed .
```
