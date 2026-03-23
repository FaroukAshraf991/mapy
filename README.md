# Mapy 🗺️

A private, cloud-connected Flutter navigation app powered by OpenStreetMap, OSRM, and Supabase — with **no paid APIs**.

## Features

- 🔐 Secure Auth — register, login, password reset via deep link
- 🗺️ OpenStreetMap with dark mode and satellite view toggle
- 🔍 Live geocoding search (Nominatim)
- 🛣️ Real-road route drawing with glowing blue polyline (OSRM)
- ⏱️ ETA & distance card after routing
- 🏠💼 Smart Home/Work buttons — synced to Supabase cloud
- 🕐 Recent search history (local, last 8 places)
- 📸 Profile picture upload (Supabase Storage)
- 🎨 Unified dark/light theme matching native splash screen

## Tech Stack

| | |
|---|---|
| UI | Flutter (Dart) |
| Maps | `flutter_map` + OpenStreetMap |
| Geocoding | Nominatim API (free, no key) |
| Routing | OSRM API (free, no key) |
| Backend | Supabase (Auth + Postgres + Storage) |
| Location | `geolocator` |
| Local Storage | `shared_preferences` |

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
