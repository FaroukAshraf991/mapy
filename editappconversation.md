# Edit App Conversation - Account Switching & Feature Implementation

## Issue 1: Account Switching Not Working

### Problem
After switching from Account A to Account B, when going back to the switch account section, Account A was gone - no way to switch back.

### Root Cause
The `_AccountSwitcherSheet` was only displaying the currently logged-in account. It wasn't calling `AccountStorageService.getAccounts()` to load other stored accounts.

### Solution
1. Created `MapProfileHelper` class to handle profile and location saving
2. Created `MapNavigationMixin` to handle route calculation
3. Updated `_AccountSwitcherSheet` to load and display other stored accounts

---

## Issue 2: Pre-driving Screen Not Appearing

### Problem
After selecting a destination, only a location pin appeared - no route details, no start button, no pre-driving screen.

### Root Cause
The `navigateTo()` method in `map_navigation_mixin.dart` only:
- Set the destination location
- Set `isRouting` to true briefly
- Animated the camera
- Set `isRouting` to false

It never called `GeocodingService.getRouteAlternatives()` to calculate the route.

### Fix
Updated `navigateTo()` to:
1. Convert `maplibre_gl.LatLng` to `latlong2.LatLng`
2. Call `GeocodingService.getRouteAlternatives()` to calculate routes
3. Update `routeInfo` and `routeAlternatives` state
4. Use route points to calculate camera bounds
5. Set `currentStepIndex` and `distanceToNextStep`

### Files Modified
- `lib/blocs/map/map_navigation_mixin.dart`

---

## Issue 3: Layers Button Not Working

### Problem
Tapping the layers button did nothing.

### Root Cause
The `_AnimatedMapButton` had an `InkWell` with `onTap: () {}` which captured taps but did nothing.

### Fix
Removed the `InkWell` and `Material` wrapper, using only `GestureDetector` to handle taps.

### Files Modified
- `lib/features/map/widgets/map_controls_overlay.dart`

---

## Files Created

### Navigation Helpers
- `lib/blocs/map/map_navigation_mixin.dart` - Route calculation mixin
- `lib/blocs/map/map_navigation_helper.dart` - Navigation static methods
- `lib/blocs/map/map_profile_helper.dart` - Profile/location saving helper

### UI Widgets
- `lib/features/map/widgets/layers_overlay.dart` - Animated layers bottom sheet
- `lib/features/map/widgets/map_builder.dart` - Map builder helper
- `lib/features/map/widgets/navigation_guidance_bar.dart` - Navigation guidance UI
- `lib/features/map/widgets/route_info_panel.dart` - Route info panel
- `lib/features/map/widgets/route_info_default_mode.dart` - Route info helper
- `lib/features/map/widgets/search_screen_builder.dart` - Search UI builder

### Profile Widgets
- `lib/features/profile/widgets/manage_account_sheet.dart` - Account management sheet
- `lib/features/profile/widgets/edit_profile_builder.dart` - Profile UI builder
- `lib/features/profile/widgets/profile_menu_item.dart` - Menu item widget
- `lib/features/profile/widgets/account_tile.dart` - Account tile widget
- `lib/features/profile/widgets/edit_name_dialog.dart` - Name edit dialog
- `lib/features/profile/widgets/edit_dob_dialog.dart` - DOB edit dialog
- `lib/features/profile/widgets/edit_email_dialog.dart` - Email edit dialog
- `lib/features/profile/widgets/edit_password_dialog.dart` - Password edit dialog
- `lib/features/profile/widgets/switcher_avatar.dart` - Avatar widget
- `lib/features/profile/widgets/current_account_tile.dart` - Current account tile
- `lib/features/profile/widgets/switcher_account_tile.dart` - Account switch tile
- `lib/features/profile/widgets/add_account_button.dart` - Add account button
- `lib/features/profile/widgets/sign_out_button.dart` - Sign out button

### Core Utilities
- `lib/core/utils/app_transitions.dart` - Animation transitions
- `lib/core/utils/animated_bottom_sheet.dart` - Bottom sheet utilities
- `lib/core/utils/spring_animations.dart` - Spring physics animations
- `lib/features/map/utils/map_actions_helper.dart` - Map action callbacks

---

## Build Status
✅ App builds successfully
✅ No critical errors
✅ Layers button works
✅ Pre-driving screen shows after selecting destination
