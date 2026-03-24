# Mapy 🗺️

A private, cloud-connected Flutter navigation app powered by OpenStreetMap, OSRM, and Supabase — with **no paid APIs**.

---

## What is Mapy?

**Mapy** is a high-performance navigation application built with **Flutter**. It provides a fully personalized map experience — featuring secure cloud-synced accounts, 3D road-following navigation, and smart location management. Every piece of user data is stored securely in **Supabase**, ensuring a private and persistent experience without the need for expensive third-party mapping services.

> *"A personal navigation companion that knows where you live, where you work, and gets you there — beautifully."*

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter (Dart) |
| **Map Engine** | **MapLibre GL 0.22.0** (OpenStreetMap Vector Tiles) |
| **Backend / Auth** | **Supabase** (Postgres + Real-time Auth + Storage) |
| **Animations** | `flutter_animate` + **Global Hero Motion** |
| **Notifications** | `flutter_local_notifications` (Live Guidance) |
| **Geocoding** | **Nominatim** (Free OpenStreetMap Geocoding) |
| **Routing** | **OSRM** (Open Source Routing Machine) |
| **Location** | `geolocator` + `permission_handler` |
| **Image Upload** | `image_picker` + Supabase Storage |

---

## Feature Highlights

### 🚗 Pro-Active 3D Navigation Engine
- **3D Perspective**: Hardware-accelerated 3D tilt (up to 60°) for a professional "road-ahead" view.
- **Glide Physics**: Butter-smooth 60Hz vector interpolation for car movement between GPS updates.
- **Auto-Bearing**: Precise, hardware-synced map rotation following your heading in real-time.
- **Dynamic Modes**: Instant recalculation for **Car 🚗, Motorcycle 🏍️, Bicycle 🚲, and Walking 🚶**.
- **Live Notifications**: Turn-by-turn guidance and ETA updates delivered via system notifications.

### 🔍 Smart Search & Routing
- **Global Search**: Address search powered by Nominatim with dedicated result cards and recent history.
- **Road-Following Routes**: Precise paths fetched from OSRM that follow actual roads, not straight lines.
- **One-Tap Shortcuts**: Your last search results are displayed as quick-access chips on the main map.
- **Home & Work Sync**: cloud-synced "Home" and "Work" pins with a combined picker/navigation flow.

### 👤 User Profile & Security
- **Secure Auth**: Full registration, login, and in-app password reset via Supabase Auth.
- **Profile Cloud Sync**: Row-Level Security (RLS) ensures your home/work/pins are private and available on any device.
- **Avatar Management**: Secure profile picture uploads to Supabase Storage with instant UI synchronization.
- **Modern Settings**: A unified hub for managing account details, appearance, and one-time profile updates (like Date of Birth).

### ✨ Premium Visual Identity
- **Neon UI**: Multi-layered glowing destination markers and road-following polylines.
- **Unified Bottom Stack**: A responsive, glassmorphism-inspired UI layout with consistent 12px spacing and animated transitions.
- **Fluid Motion**: Global Hero animations and Cupertino transitions for a high-end, tactile feel.
- **Brand Consistency**: A custom 3D app icon and matching high-resolution splash screen for a seamless OS-to-App transition.

---

## Setup & Deployment

1. **Clone & Config**:
   ```bash
   git clone https://github.com/FaroukAshraf991/mapy.git
   cp lib/core/config/secrets.dart.example lib/core/config/secrets.dart
   ```
2. **Supabase Schema**: Run the SQL in `secrets.dart.example` to create the `profiles` table and enable RLS.
3. **Storage**: Create a public bucket named `avatars` in Supabase.
4. **Launch**:
   ```bash
   flutter pub get
   flutter run
   ```

## License
MIT
