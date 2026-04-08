# Mapy Project Rules & Constraints

## 🛑 Primary Directives
1. **Strict Obedience**: DO NOT do anything except what the user has explicitly said.
2. **No Unsolicited Additions**: DO NOT add anything from your own initiative.
3. **Clean Architecture & Readability**: Always follow high-level development architecture and "Clean Code" principles. Separate concerns into modular components. Ensure the code is readable, simple, and easy for any developer to understand.
4. **Zero Error Policy**: Always check for errors before finishing any task. DO NOT finish with any unresolved errors.
5. **Clean Code**: Follow Clean Code principles — meaningful names, small single-purpose functions, no duplication, minimal comments (self-documenting code), and clear separation of concerns.
6. **Development Architecture**: Follow established development architecture patterns (e.g., MVVM, Clean Architecture, feature-first structure) consistently across the entire codebase.
7. **Post-Task Rule Verification**: After completing EVERY task/command, explicitly verify that ALL rules in this document have been followed. Report any violations found and fix them before finishing.
8. **Responsive UI**: Always build UI using responsive design principles. Use `context.w()`, `context.h()`, `context.sp()`, `context.r()` from responsive utils for all sizes, padding, and text. Never use hardcoded pixel values.
9. **Hardcoding**: All values (URLs, keys, constants, thresholds, defaults, strings) MUST be hardcoded directly in code, except for secrets. Follow the Hardcoding & Configuration section rules.
10. **Strict File Size Limits:** No `.dart` file should exceed 150-200 lines. If a file is approaching this limit, you must refactor and split the logic or UI into smaller, modular files.
11. **Widget Extraction:** Do not write massive, deeply nested widget trees. Break down complex screens into smaller, reusable, independent widgets. Place these extracted widgets in a dedicated `widgets/` directory.
12. **Single Responsibility Principle (SRP):** Each class, function, and file must have exactly one reason to change. 
13. **Separation of Concerns:** Strictly separate the UI layer from business logic and state management. Do not put API calls, complex data parsing, or database queries directly inside UI widgets.
14. **Clean Architecture:** Structure the project logically (e.g., feature-first architecture). Keep screens, reusable widgets, models, and controllers cleanly separated in their respective directories.
15. **Readability & Naming:** Prioritize readable code over clever or compact code. Use highly descriptive names for variables, methods, and classes.

---

This document defines the absolute "Ground Truth" for the Mapy application. These rules MUST be referenced and followed before EVERY command or modification.
 
---

## 📦 Versioning & Repository
1. **Formal Releases**: Every major architectural change must be tagged and pushed as a formal GitHub Release (e.g., v1.3.x).
2. **APK Distribution**: Attach a production-ready `app-release.apk` to every formal release.

---

## 🏗️ Flutter Code Architecture & Cleanliness Guidelines

1. **Strict File Size Limits**: No `.dart` file should exceed 150-200 lines. If a file is approaching this limit, you must refactor and split the logic or UI into smaller, modular files.
2. **Widget Extraction**: Do not write massive, deeply nested widget trees. Break down complex screens into smaller, reusable, independent widgets. Place these extracted widgets in a dedicated `widgets/` directory.
3. **Single Responsibility Principle (SRP)**: Each class, function, and file must have exactly one reason to change.
4. **Separation of Concerns**: Strictly separate the UI layer from business logic and state management. Do not put API calls, complex data parsing, or database queries directly inside UI widgets.
5. **Clean Architecture**: Structure the project logically (e.g., feature-first architecture). Keep screens, reusable widgets, models, and controllers cleanly separated in their respective directories.
6. **Readability & Naming**: Prioritize readable code over clever or compact code. Use highly descriptive names for variables, methods, and classes.
