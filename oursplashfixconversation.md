# Splash Screen Fix Conversation

## Problem
The app works fine in debug mode (via VS Code), but after stopping the debugger and opening the app from the phone, it gets stuck on the splash screen and never opens.

## Root Cause
VS Code's Flutter debug launcher runs `flutter run` with `--start-paused` by default. The debugger connects and sends a `resume` command, so the app works during debugging. However, when you stop debugging and reopen the app from the phone, the same debug APK starts paused but no debugger is attached to send the `resume` command — so the Dart isolate stays paused forever and `main()` never executes, leaving the splash screen visible.

This is **expected Flutter debug-build behavior**, not a code bug. The debug APK isn't designed to run standalone.

## Fix Applied

### 1. Hardened `lib/main.dart`
- Wrapped the entire `main()` body in a try/catch
- If any initialization fails (Supabase, SharedPreferences, BLoC setup, router, etc.), the app now shows a `_StartupErrorApp` error screen with the error message and stack trace instead of silently hanging
- Added `_StartupErrorApp` widget — dark-themed error screen with expandable stack trace and a restart hint

### 2. Built a proper release APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://admnocqbnyvhmzseehek.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
Output: `build/app/outputs/flutter-apk/app-release.apk` (103.7MB)

## How to Install
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```
Or transfer the APK to your phone and install manually.

## What is `run.sh`
A script that reads `.env` and passes Supabase credentials to `flutter run` via `--dart-define` flags:
```bash
#!/bin/bash
set -a
source .env
set +a

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
```
Only for debug/profile runs. Does not build release APKs.

## Going Forward
- **Development**: Keep using VS Code debug launch as normal
- **Testing standalone on device**: Always build release or profile
  - `flutter build apk --release`
  - `flutter run --profile`
- Could also run from terminal: `flutter run` (without `--start-paused`) to avoid the issue entirely
