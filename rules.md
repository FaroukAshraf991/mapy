# Mapy Project Rules & Constraints

## 🛑 Primary Directives
1. **Strict Obedience**: DO NOT do anything except what the user has explicitly said.
2. **No Unsolicited Additions**: DO NOT add anything from your own initiative.
3. **Clean Architecture & Readability**: Always follow high-level development architecture and "Clean Code" principles. Separate concerns into modular components. Ensure the code is readable, simple, and easy for any developer to understand.
4. **Zero Error Policy**: Always check for errors before finishing any task. DO NOT finish with any unresolved errors.

---

This document defines the absolute "Ground Truth" for the Mapy application. These rules MUST be referenced and followed before EVERY command or modification.

## 📐 UI Layout Rules
1. **Top Search Cluster**: Positioned at `top: 60, left: 16, right: 16`. Contains Search Field, Horizontal Location Chips (`height: 44`), and a right-aligned Map Style (Layers) button.
2. **Unified Bottom Stack**: ALL bottom elements are combined into a single `Column` inside a `Positioned(bottom: 0, left: 0, right: 0)`.
3. **Bar Spacing**: Maintain a strict **12px vertical gap** between the `RouteInfoPanel` (bottom) and the `Greeting/Navigation Bar` (top).
4. **Button Cluster**: Floating control buttons (Compass, Locate Me, 2D/3D) are positioned 16px above the Greeting Bar.

## 🏗️ Architectural Constraints
1. **START/EXIT Logic**: The primary bar dynamically swaps between a blue "START" button (Ready) and a red "EXIT" button (Navigating).
2. **Modular Main Screen**: Keep the `MainMapScreen` modular by delegating UI blocks to specialized overlay widgets (e.g., `navigation_overlay.dart`, `map_controls_overlay`).
3. **Reflect.md**: All ground truth rules are also mirrored in `remember.md` for layout specific details.

## 🚀 Performance & Stability (High-FPS Rules)
1. **Camera Animations**: Never exceed **100ms** for navigation-related camera transitions to prevent stuttering/stacking.
2. **Rendering Throttle**: Use a minimum **1000ms** throttle for `_updateLayers` during routing/navigation.
3. **Aetheric Glass Styling**: Use `BackdropFilter` (blur) with `ImageFilter.blur(sigmaX: 8, sigmaY: 8)` for all map overlays to provide a premium, high-fidelity experience. Ensure `withValues(alpha: ...)` is used for translucent backgrounds.
4. **Error Hardening**: Every map layer update MUST include a 10ms stabilization delay and defensive `PlatformException` catch blocks for Android `GeoJsonSource` race conditions.

## 📦 Versioning & Repository
1. **Formal Releases**: Every major architectural change must be tagged and pushed as a formal GitHub Release (e.g., v1.3.x).
2. **APK Distribution**: Attach a production-ready `app-release.apk` to every formal release.
