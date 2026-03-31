# Mapy Project Rules & Constraints

## 🛑 Primary Directives
1. **Strict Obedience**: DO NOT do anything except what the user has explicitly said.
2. **No Unsolicited Additions**: DO NOT add anything from your own initiative.
3. **Clean Architecture & Readability**: Always follow high-level development architecture and "Clean Code" principles. Separate concerns into modular components. Ensure the code is readable, simple, and easy for any developer to understand.
4. **Zero Error Policy**: Always check for errors before finishing any task. DO NOT finish with any unresolved errors.
5. **Clean Code**: Follow Clean Code principles — meaningful names, small single-purpose functions, no duplication, minimal comments (self-documenting code), and clear separation of concerns.
6. **Development Architecture**: Follow established development architecture patterns (e.g., MVVM, Clean Architecture, feature-first structure) consistently across the entire codebase.
7. **Post-Task Rule Verification**: After completing EVERY task/command, explicitly verify that ALL rules in this document have been followed. Report any violations found and fix them before finishing.
8. **Command Documentation**: Document all command interactions by appending to ZenConversation.md after completing each task.
9. **Responsive UI**: Always build UI using responsive design principles. Use `context.w()`, `context.h()`, `context.sp()`, `context.r()` from responsive utils for all sizes, padding, and text. Never use hardcoded pixel values.
10. **Hardcoding**: All values (URLs, keys, constants, thresholds, defaults, strings) MUST be hardcoded directly in code, except for secrets. Follow the Hardcoding & Configuration section rules.

---

This document defines the absolute "Ground Truth" for the Mapy application. These rules MUST be referenced and followed before EVERY command or modification.

## 🔒 Hardcoding & Configuration
1. **Hardcode Everything**: All values (URLs, keys, constants, thresholds, defaults) MUST be hardcoded directly in code, except for secrets.
2. **Secrets Exception**: Only `lib/core/config/secrets.dart` and `.env` files may contain externalized values (loaded via `--dart-define`).

---

## 📦 Versioning & Repository
1. **Formal Releases**: Every major architectural change must be tagged and pushed as a formal GitHub Release (e.g., v1.3.x).
2. **APK Distribution**: Attach a production-ready `app-release.apk` to every formal release.
