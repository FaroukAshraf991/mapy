# CLAUDE.md — AI Assistant Guide for Mapy

---

> ## PRIORITY TODO LIST
> **These are the highest-priority tasks. Address these before anything else.**
>
> - [ ] **[BUG] Work & Home pins not persisting** — Work and Home location pins are not saved to the cloud. When the user signs out or switches accounts, the pins are lost and must be re-entered. They need to be stored in Supabase and restored on login.
> - [ ] **[FEATURE] Mute/Unmute button for voice navigation** — Add a mute/unmute toggle button during active navigation to allow the user to silence or re-enable the TTS voice guidance on the fly.
> - [ ] **[UI] Move pins scroll bar into the search page** — The horizontal scroll bar containing quick-access pins (Recents, Home, Work, Add) should be relocated inside the search page, not on the main map screen.
> - [ ] **[UI] Replace pins scroll bar with POI category tiles** — Under the search bar, display a horizontal scroll bar of POI category tiles (Restaurants, Gas Station, Parking, Hotel, Shopping, Hospital) in place of the current pins scroll bar.
> - [ ] **[FEATURE] First-launch theme selection bottom sheet** — On first app install, show a bottom sheet drawer that slides up from the bottom asking the user to choose their preferred theme: Light, Dark, or System default.

---

## Project Overview

**Mapy** is a Flutter-based navigation app (v1.5.0) with a companion Next.js admin dashboard. It uses open-source mapping (MapLibre GL, OpenStreetMap, OSRM, Nominatim) and Supabase for auth/backend — no paid APIs required.

---

## Repository Structure

```
mapy/
├── lib/                        # Flutter/Dart app source
│   ├── main.dart               # Entry point (BLoC init, router setup)
│   ├── blocs/                  # State management (Cubits)
│   │   ├── auth/               # Auth state
│   │   ├── map/                # Map/navigation state
│   │   └── theme/              # Theme mode (light/dark/system)
│   ├── core/
│   │   ├── config/secrets.dart # Supabase credentials (--dart-define)
│   │   ├── constants/app_constants.dart  # ALL hardcoded values
│   │   ├── router/             # GoRouter setup + route names
│   │   └── utils/              # Responsive helpers, transitions
│   ├── features/               # Feature-first modules
│   │   ├── auth/               # Login, register, password update
│   │   ├── map/                # Main map, navigation, route preview
│   │   ├── profile/            # User profile + account switcher
│   │   └── settings/           # App settings screen
│   ├── models/                 # Shared data models
│   ├── repositories/           # Data access layer
│   └── services/               # Business logic (geocoding, TTS, weather, etc.)
├── web_dashboard/              # Next.js 14 + TypeScript admin dashboard
│   ├── app/                    # App Router pages
│   ├── components/ui/          # Radix UI components
│   └── lib/                    # Supabase client utilities
├── test/                       # Flutter tests (smoke test only)
├── android/ ios/ linux/ macos/ windows/  # Platform build configs
├── assets/                     # Icons and graphics
├── releases/                   # Pre-built APKs
├── pubspec.yaml                # Flutter dependencies
├── run.sh                      # Dev runner (loads .env → --dart-define)
├── rules.md                    # MANDATORY development rules
└── features.md                 # Planned feature roadmap
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile framework | Flutter 3.6.0+ / Dart 3.6.0+ |
| Maps | MapLibre GL 0.22.0 |
| State management | BLoC/Cubit (flutter_bloc 9.2.0) |
| Routing | go_router 17.1.0 |
| Backend/Auth | Supabase v2.12.0 |
| Geocoding | Nominatim (OSM, free) |
| Routing engine | OSRM (free) |
| Location | geolocator 14.0.2 |
| Notifications | flutter_local_notifications 21.0.0 |
| Voice navigation | flutter_tts 4.2.5 |
| Animations | flutter_animate 4.5.2 |
| Local storage | shared_preferences 2.5.4 |
| Web dashboard | Next.js 14, React 18, Tailwind CSS 3, Radix UI |

---

## Development Commands

### Flutter App

```bash
# Install dependencies
flutter pub get

# Run app (preferred — loads secrets from .env)
./run.sh

# Run app manually with secrets
flutter run \
  --dart-define=SUPABASE_URL="<url>" \
  --dart-define=SUPABASE_ANON_KEY="<key>"

# Lint check (must pass with zero warnings)
flutter analyze

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Regenerate app icons
flutter pub run flutter_launcher_icons

# Regenerate splash screen
flutter pub run flutter_native_splash:create
```

### Web Dashboard

```bash
cd web_dashboard

# Install dependencies
npm install

# Dev server (localhost:3000)
npm run dev

# Production build
npm run build

# Lint
npm run lint
```

---

## Environment & Secrets

### Flutter secrets (`lib/core/config/secrets.dart`)

Credentials are injected at runtime via `--dart-define`. The file contains fallback defaults for development only — **never commit real credentials**.

```bash
# .env (gitignored) — used by run.sh
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Web Dashboard (`.env.local` — gitignored)

```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

Copy from `web_dashboard/.env.example` to get started.

---

## Architecture & Code Conventions

### Feature-First Clean Architecture

Each feature lives in `lib/features/<name>/` and contains:
- `screens/` — full-page widgets
- `widgets/` — feature-specific sub-widgets
- `services/` — business logic
- `models/` — feature-specific data models (if needed)

Shared concerns go in `lib/repositories/`, `lib/services/`, or `lib/models/`.

### Mandatory Rules (from `rules.md`)

1. **File size limit:** Dart files must stay within **150–200 lines**. Split into helpers when needed.
2. **Responsive UI:** Always use the responsive utilities — never hardcode pixel values:
   - `context.w(x)` — width relative to 375dp baseline
   - `context.h(x)` — height relative to 812dp baseline
   - `context.sp(x)` — font size scaling
   - `context.r(x)` — radius/size scaling
3. **Zero lint warnings:** `flutter analyze` must produce zero issues before any commit.
4. **No hardcoded secrets:** Supabase credentials go through `--dart-define` only.
5. **Constants centralized:** All non-secret app constants (colors, URLs, thresholds) go in `lib/core/constants/app_constants.dart`.
6. **Clean architecture:** Repositories handle data access; Cubits handle state; screens are thin UI layers.
7. **Follow existing patterns:** Match the style of surrounding code. Don't introduce new patterns without reason.

### State Management (BLoC/Cubit)

- `AuthCubit` — manages auth state (authenticated / unauthenticated / loading)
- `MapCubit` — manages map state (location, route, camera, navigation)
- `ThemeCubit` — manages light/dark/system theme

Cubits are provided at the root in `main.dart` via `MultiBlocProvider`.

### Routing (GoRouter)

- Route names defined as constants in `lib/core/router/app_routes.dart`
- Router configured in `lib/core/router/app_router.dart`
- Auth redirect logic embedded in router redirect callback

### Animations

- Use `flutter_animate` for standard animations
- `FadeSlideAnimationMixin` in `lib/core/mixins/` for reusable fade-slide effects
- `AppTransitions` in `lib/core/utils/app_transitions.dart` for page transitions

---

## Git Conventions

### Branches

- `main` — stable, production-ready
- Feature branches follow: `type/short-description` or `claude/description-id`

### Commit Format

```
type(scope): description
```

- **Types:** `feat`, `fix`, `refactor`, `chore`, `docs`
- **Scope:** optional module/component (e.g., `map`, `auth`, `security`)
- **Description:** lowercase, imperative mood (e.g., "add voice navigation toggle")

**Examples:**
```
feat(map): add multi-stop routing support
fix(auth): handle expired session token gracefully
refactor: reduce file sizes and extract helper widgets
chore: upgrade dependencies to latest stable
```

---

## Deployment

### Mobile (Android)
- Build: `flutter build apk --release`
- Releases are manually attached to GitHub tags as APK artifacts
- Major feature releases get formal GitHub releases

### Web Dashboard
- Auto-deployed via **Vercel** on push to `main`
- Build root configured to `web_dashboard/` subdirectory
- Config: `web_dashboard/vercel.json`

---

## Testing

Currently minimal — only a smoke test in `test/widget_test.dart`. Run with:

```bash
flutter test
```

When adding tests:
- Unit tests: test cubits, repositories, and services in isolation
- Widget tests: use `WidgetTester` for screen and widget rendering
- Place test files mirroring the `lib/` structure under `test/`

---

## Key Files Reference

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point — BLoC providers, Supabase init, router |
| `lib/core/constants/app_constants.dart` | All hardcoded constants (colors, URLs, thresholds) |
| `lib/core/config/secrets.dart` | Supabase credentials (read from `--dart-define`) |
| `lib/core/router/app_router.dart` | GoRouter config + auth redirect logic |
| `lib/core/router/app_routes.dart` | Named route constants |
| `lib/core/utils/responsive.dart` | `context.w/h/sp/r()` responsive helpers |
| `lib/blocs/map/map_cubit.dart` | Core map/navigation state machine |
| `pubspec.yaml` | Flutter dependencies and asset declarations |
| `run.sh` | Dev runner that sources `.env` and passes secrets |
| `rules.md` | Full project development rules — read before making changes |
| `features.md` | Planned features roadmap |
| `web_dashboard/package.json` | Dashboard npm scripts and dependencies |
