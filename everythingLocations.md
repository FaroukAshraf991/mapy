# Component Locations in Maps App

This document contains the location of all UI components in the main map screen.

---

## Main Map Screen (`lib/features/map/screens/main_map_screen.dart`)

### Stack Order (bottom to top):
1. **Map** - Full screen background
2. **TopSearchOverlay** - Top section (hidden when destination selected)
3. **TopLayersButton** - Upper right corner
4. **NavigationGuidanceBar** - Top (only during navigation)
5. **BottomMapControls** - Bottom right corner

---

## TopSearchOverlay (`lib/features/map/widgets/top_search_overlay.dart`)

**Position:** `Positioned(top: topPadding + 12, left: 16, right: 16)`

Contains:
- **Greeting** - "Good morning/afternoon/evening, [Name]!"
- **MapSearchBar** - Search input field
- **ShortcutsBar** - Horizontal scroll with Home, Work, Recents, Custom Pins
- **GpsDisplay** - "Tap map to select location" label

**Visibility:** Shows when `hasRoute == false`, hidden when `hasRoute == true`

---

## TopLayersButton (`lib/features/map/widgets/map_controls_overlay.dart`)

**Position in MainMapScreen:** `Positioned(top: topPadding + 240, right: 20)`

**File:** `lib/features/map/screens/main_map_screen.dart` - Method `_buildTopLayersButton()`

- Single layers button only (showOnlyLayers: true)
- Always visible (not affected by destination selection)

---

## NavigationGuidanceBar (`lib/features/map/widgets/navigation_overlay.dart`)

**Position:** `Positioned(top: topPadding + 10, left: 12, right: 12)`

**Visibility:** Only shows when `isNavigating == true`

Contains:
- Turn-by-turn direction icon
- Distance to next turn
- Current street name

---

## BottomMapControls (`lib/features/map/widgets/bottom_map_controls.dart`)

**Position:** `Positioned(bottom: 0, left: 0, right: 0)` with padding `right: 20`

### Contains:

#### 1. MapControlsOverlay (Bottom Right)
**Position:** Column at right side

Contains (top to bottom):
- **Compass** - Shows when bearing != 0
- **Locate Me Button** - `Icons.my_location_rounded` (or `Icons.navigation_rounded` when navigating)
- **Layers Button** - Hidden (showLayersButton: false)
- **2D/3D Toggle** - `Icons.map_rounded` / `Icons.apartment_rounded`
- **Share Location** - `Icons.share_location_rounded` (only when hasRoute == false)

#### 2. TripBar
**Position:** Horizontal, centered

Contains:
- Start/End location display
- START button / EXIT button

#### 3. RouteInfoPanel
**Position:** Bottom, above TripBar

**Visibility:** Shows when `hasRoute == true`

Contains:
- Travel mode chips (car, motorcycle, bike, walk)
- ETA time
- Distance
- Routes button (when alternatives available)
- Route name

**Driving Mode (when isNavigating == true):**
- Compact mode showing only:
  - Travel mode icon
  - ETA
  - Distance

---

## Other Screens

### Next Where To Screen (`lib/features/map/screens/next_where_to_screen.dart`)
- Search bar at top
- POI categories horizontal scroll
- Results list

### Pick Location Screen (`lib/features/map/screens/pick_location_screen.dart`)
- Map with marker
- Search bar at top

---

## Key Files

| Component | File |
|-----------|------|
| Main Screen | `lib/features/map/screens/main_map_screen.dart` |
| Top Search Overlay | `lib/features/map/widgets/top_search_overlay.dart` |
| Map Controls Overlay | `lib/features/map/widgets/map_controls_overlay.dart` |
| Bottom Map Controls | `lib/features/map/widgets/bottom_map_controls.dart` |
| Navigation Overlay | `lib/features/map/widgets/navigation_overlay.dart` |
| Trip Bar | `lib/features/map/widgets/trip_bar.dart` |
| Search Bar | `lib/features/map/widgets/map_search_bar.dart` |
| Shortcuts Bar | `lib/features/map/widgets/shortcuts_bar.dart` |

---

## Visibility Conditions

| Component | Condition |
|-----------|-----------|
| TopSearchOverlay (greeting, search, shortcuts) | `!state.isNavigating && !state.routeInfo.hasRoute` |
| TopLayersButton | Always visible |
| NavigationGuidanceBar | `state.isNavigating` |
| Bottom Map Controls | Always visible |
| RouteInfoPanel | `state.routeInfo.hasRoute` |
| Share Location Button | `!state.routeInfo.hasRoute` |

---

## Last Updated: 2026-03-28
