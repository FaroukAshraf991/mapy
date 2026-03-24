# Mapy 🗺️

A private, cloud-connected Flutter navigation app powered by OpenStreetMap, OSRM, and Supabase — with **no paid APIs**.


---

## What is Mapy?

**Mapy** is a private, cloud-connected maps and navigation application built with **Flutter** for Android. It gives users a fully personal map experience — from secure login to saving home/work locations in the cloud, searching any real-world address, and drawing road-following routes with live ETA and distance estimates. Every piece of data is private to each user, stored securely in **Supabase** (a cloud Postgres database).

> *"A personal navigation companion that knows where you live, where you work, and gets you there — beautifully."*

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart) |
| Map Engine | OpenStreetMap via `flutter_map` |
| Backend / Auth | Supabase (Postgres + Auth + Storage) |
| Geocoding | Nominatim (free OpenStreetMap API) |
| Routing | OSRM — Open Source Routing Machine |
| Location | `geolocator` package |
| Local Storage | `shared_preferences` |
| Image Upload | `image_picker` + Supabase Storage |

> All third-party APIs (Nominatim, OSRM, OSM tiles) are **100% free and require no API key**.

---

## Feature Breakdown

### 1. 🔐 Secure Authentication
- **Register** with name, email, and password — stored securely in Supabase Auth
- **Login** with email and password — full Supabase session management
- **Forgot Password** — sends a reset link to the user's email
- **Deep Link handling** — the app intercepts password reset links automatically via Android/iOS URL schemes
- **Reset Password Screen** — native in-app screen; no redirect to a website

### 2. 🗺️ Interactive Map
- **OpenStreetMap** tiles rendered via `flutter_map`
- **Dark Mode Map** — tiles are programmatically inverted via a colour matrix filter
- **Satellite View** — toggle between street map and **Esri WorldImagery** satellite with one tap
- **"Locate Me" Button** — requests GPS and flies the camera to the user's position
- **"Me" Pin** — green person icon always marks the current location
- **Camera Fitting** — map automatically zooms to fit both start and destination in view

### 3. 🔍 Geocoding Search ("Where To?")
- Type any address, city, landmark, or business name
- Results fetched live from **Nominatim API** (debounced at 500ms)
- Each result shows the place name and full address in a clean card
- Selecting a result drops a **bright red destination pin** on the map

### 4. 🛣️ Road Route Drawing
- Route fetched from **OSRM** — follows **real roads**, not straight lines
- Drawn as a **glowing blue polyline** (glow layer + sharp core stroke)
- A **"Clear Route"** button dismisses the pin and polyline

### 5. ⏱️ ETA & Distance Card
- After routing, a floating card shows:
  - **Distance** — e.g. `"12.3 km"` or `"850 m"`
  - **ETA** — e.g. `"~18 min"` (real OSRM estimate)
- A **progress bar** animates at the top while the route loads

### 6. 🏠💼 Smart Home & Work Locations
- Set a **Home** and **Work** pin anywhere on the map
- Once set, tapping the button shows a contextual sheet:
  - **"Go to Home/Work"** — draws a road route to the pin
  - **"Change location"** — re-opens the map picker
  - **"Clear location"** — removes the pin from map and cloud
- A **green dot badge** on each button shows when a location is saved
- Both locations **sync to Supabase** and restore automatically on every login

### 7. ☁️ Supabase Profile Sync
- Each user has a `profiles` row in Supabase Postgres
- Home/Work coordinates and avatar URL are persisted per user
- Row-Level Security (RLS) ensures users can only access their own data

### 8. 🕐 Recent Search History
- Last **8 searched places** saved locally (`shared_preferences`)
- Opening "Where To?" without typing shows the **"Recent" list**
- **"Clear" button** wipes the history; deduplication keeps it tidy

### 9. 📸 Profile Picture
- Tap the avatar in the drawer → pick from gallery → uploads to **Supabase Storage**
- Upload spinner + success snack bar give clear feedback
- Avatar loads from the cloud on every session

### 10. 🎨 Unified Visual Theme
- Custom deep-blue palette (`#0F2027` dark / `#F8F9FA` light) applied across every screen
- Native **splash screen** matches perfectly — no jarring flash on launch
- Full **dark mode and light mode** with a toggle in the drawer

### 11. 🗂️ Navigation Drawer
- Profile header with avatar, username, and "Change photo" shortcut
- Dark Mode toggle (persisted across sessions)
- Recent Places shortcut + Settings placeholder

### 12. 🏗️ Clean Architecture
- Feature-based: `auth`, `map`, `profile` — each with `screens/`, `services/`, `models/`, `widgets/`
- Stateless static services — easy to read and test
- `flutter analyze` → **zero issues** throughout development

---

## Privacy & Security
- Supabase RLS — users cannot access each other's data
- Passwords managed entirely by Supabase Auth — never stored in the app
- Avatar uploads restricted to authenticated users via Storage policies

---

## What Makes it Stand Out
1. **No paid APIs** — OSM, OSRM, and Nominatim are all free
2. **Real road routing** — actual driving paths, not straight lines
3. **Seamless deep-link password reset** — works natively inside the app
4. **Cloud persistence** — Home/Work locations follow the user across devices
5. **Production-quality UX** — ETA cards, animated progress bars, bottom sheets, badge indicators

## Setup

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/mapy.git
cd mapy
```

### 2. Add your secrets
```bash
cp lib/core/config/secrets.dart.example lib/core/config/secrets.dart
```
Then open `lib/core/config/secrets.dart` and fill in your Supabase project URL and anon key (from **Supabase → Settings → API**).

### 3. Create the Supabase `profiles` table
Run this SQL in your **Supabase SQL Editor**:
```sql
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  home_lat double precision,
  home_lon double precision,
  work_lat double precision,
  work_lon double precision,
  avatar_url text,
  updated_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "select_own" on public.profiles for select using (auth.uid() = id);
create policy "insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "update_own" on public.profiles for update using (auth.uid() = id);
```

### 4. Create the Supabase `avatars` storage bucket
- Go to **Storage → New bucket** → name: `avatars` → toggle **Public**
- Add policies: authenticated users can INSERT/UPDATE; public can SELECT.

### 5. Run the app
```bash
flutter pub get
flutter run
```

## Architecture

Feature-based clean architecture:
```
lib/
├── core/
│   ├── constants/    # AppConstants, colours
│   └── config/       # secrets.dart (gitignored)
├── features/
│   ├── auth/         # screens + services
│   ├── map/          # screens, widgets, models, services
│   └── profile/      # ProfileService
└── main.dart
```

## License
MIT
