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
- Set a **Home** and **Work** pin directly on the map via a visual picker
- Once set, tapping the button shows a contextual sheet:
  - **"Go to Home/Work"** — draws a road route to the pin
  - **"Change location"** — re-opens the map picker with a confirmation flow
  - **"Clear location"** — removes the pin from map and cloud
- A **green dot badge** on each button shows when a location is saved
- Both locations **sync to Supabase** and restore automatically on every login
- **Refined UX:** Users can visually confirm and adjust the pin before saving

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

### 10. 🚗 Pro-Active 3D Navigation Engine
- **3D Perspective (Pitch/Tilt):** Hardware-accelerated 3D tilt (up to 60 degrees) for a professional "road-ahead" view.
- **Glide Physics:** Butter-smooth 60Hz vector interpolation for car movement between GPS updates.
* **Smart Auto-Bearing:** Precise, hardware-synced map rotation that tracks your heading in real-time.
* **MapLibre GL Upgrade:** Rebuilt on MapLibre 0.22.0 for superior performance and 3D vector tile rendering.
* **Minimalist Map:** Stripped the standard compass UI for a cleaner, modern navigation aesthetic.

### 11. 🕐 Smart Recent Search History
- **Dynamic Shortcut Chips:** Your last **3 search results** are displayed as quick-access chips on the main map.
- **One-Tap Routing:** Tapping a chip immediately draws a road route to that destination.
- **Auto-Refresh:** History updates instantly when you select a new place from the search screen.
- **Persistent Storage:** Synced between local `shared_preferences` and session state for reliability.

### 12. 👤 Unified Profile & Settings
- **Persistent Settings Drawer:** A dedicated hub for dark mode toggles, account info, and profile management.
- **Real-Time Profile Sync:** Full support for updating Name, Email, DOB, and Password with instant Supabase persistence.
- **Custom Avatar Management:** Securely upload and retrieve profile pictures via Supabase Storage buckets.

### 13. ✨ Premium Visual Overhaul
- **Neon Destination Marker 📍:** A custom-painted marker with a transparent center, multi-layered electric blue glow, and a subtle pulse ring.
- **Advanced Glassmorphism:** The Route Card and UI bars use `BackdropFilter` real-time blur (10px sigma) with white-tinted borders for an "Apple-style" finish.
- **Active Navigation Mode:** Tapping "START" transitions the app into a focused mode that hides non-essential UI, zooms in on your location, and provides a "NAVIGATING..." indicator.
- **Fluid Motion System:** All UI elements glide into place using `AnimatedSwitcher` with slide and fade transitions.

### 14. 🛣️ Dynamic Travel Modes
- Toggle between **Car 🚗, Motorcycle 🏍️, Bicycle 🚲, and Walking 🚶** modes.
- **Real-Time Recalculation:** Tapping a mode immediately updates the ETA and distance based on OSRM profiles.
- **Contextual Actions:** "START" and "EXIT" buttons are integrated directly into the travel mode selection row for a compact, intuitive control set.

---

## Privacy & Security
- **Supabase RLS:** Row-Level Security ensures users can only access their own profile data and coordinates.
- **Secure Auth:** Passwords managed entirely by Supabase Auth — never stored locally or in plain text.
- **Cloud Synchronization:** Your Home/Work locations and custom pins follow you across devices.

---

## What Makes it Stand Out
1. **No Paid APIs:** OSM, OSRM, and Nominatim are used to provide high-end features at zero cost.
2. **Professional 3D Engine:** High-performance vector map with tilt and rotation support.
3. **Immersive UI:** Neon aesthetics, glassmorphism, and fluid motion design.
4. **Seamless Password Resets:** Deep-link handling allows users to reset passwords natively inside the app.

---

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
Then open `lib/core/config/secrets.dart` and fill in your Supabase project URL and anon key.

### 3. Create the Supabase `profiles` table
Run this SQL in your **Supabase SQL Editor** to create the required table and RLS policies:
```sql
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  home_lat double precision,
  home_lon double precision,
  work_lat double precision,
  work_lon double precision,
  custom_pins jsonb DEFAULT '[]'::jsonb,
  avatar_url text,
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Allow select for owners" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow insert for owners" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Allow update for owners" ON public.profiles FOR UPDATE USING (auth.uid() = id);
```

### 4. Create the Supabase `avatars` storage bucket
- Create a bucket named `avatars` and set it to **Public**.
- Add policies allowing authenticated users to INSERT and UPDATE their own files.

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
