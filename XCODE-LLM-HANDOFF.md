# Opticon macOS Handoff

## Goal
Make `opticon-macos` feel closer to the iOS app while keeping the map as the full-window background:
- map edge to edge
- floating bottom nav only
- no top location picker/header bar
- real device location instead of hardcoded city presets
- cleaner flight status messaging
- real app icon instead of default macOS template icon

## Current Status
- Project path: `/Users/joshua/Documents/Code/opticon-macos`
- Xcode project: `Opticon.xcodeproj`
- App builds have succeeded multiple times earlier in the session with unsigned CLI builds.
- The latest work introduced a new `LocationManager.swift` and refactored `SituationView.swift` toward location-driven state.
- The user reports Xcode is still failing during the current iteration, so this handoff should be treated as "mid-refactor".

## Important Changes Already Made

### Navigation / Shell
- Replaced sidebar navigation with a bottom tab bar in `ContentView.swift`.
- Moved toward floating nav overlay instead of persistent sidebar.
- Increased bottom tab hit targets and constrained width to reduce interaction glitches.
- Removed the black slab background behind the nav and moved toward translucent glass styling.

### Situation View
- Removed the top-right location picker UI from `SituationView.swift`.
- Removed the top header bar entirely from `SituationView.swift` in the latest pass.
- Changed road incident markers from yellow warning style to blue event dots.
- Added a distinct current-location pin style.
- Started migrating from hardcoded city presets to:
  - device location
  - map viewport-driven data loads

### Flights
- `OpticonAPI.fetchFlights(...)` was changed from returning `[Flight]` to returning `FlightFeed`.
- `SituationView.loadFlights(...)` was updated to unwrap `feed.states`.
- Flight chip messaging was changed from blunt `Flights unavailable` to:
  - `cached flights`
  - `0 flights`
  - `Flights degraded`

### Auth Persistence
- Successful auth now auto-saves credentials in Keychain.
- Sign-out no longer clears saved credentials.
- Login sheet prefills from saved Keychain credentials.

## Files Most Recently Touched
- `ContentView.swift`
- `Views/SituationView.swift`
- `Services/LocationManager.swift`
- `API/OpticonAPI.swift`
- `Models/SituationData.swift`
- `Models/AppState.swift`
- `Views/LoginSheet.swift`

## Likely Current Blocker
The current blocker is most likely around `Services/LocationManager.swift` after the Swift 6 / actor-isolation refactor.

Current implementation strategy:
- `@MainActor final class LocationManager`
- `extension LocationManager: @preconcurrency CLLocationManagerDelegate`
- delegate methods marked `nonisolated`
- delegate methods hop back to main actor with `Task { @MainActor in ... }`

If Xcode is still failing:
1. Inspect `LocationManager.swift` first.
2. If Swift 6 still complains about isolation/sendability, simplify further:
   - keep the object `@MainActor`
   - keep delegate callbacks `nonisolated`
   - move all state mutations into tiny `@MainActor` helper methods
   - avoid inline closures that capture `self` unnecessarily

## Other Known Outstanding Issues

### App Icon
- The app still shows the default macOS icon.
- `Assets.xcassets/AppIcon.appiconset/Contents.json` exists, but icon image files were not successfully populated during this session.
- Need to generate real PNG icon assets from `icon.svg` and wire them into `AppIcon.appiconset`.

### Project Hygiene
- `xcodebuild` still reports duplicate group warnings for:
  - `API`
  - `Models`
  - `Services`
  - `Views`
- These come from malformed group structure in the generated `.xcodeproj`.
- Root cause likely lives in `project.yml` / xcodegen structure, not source files.

### Responsive Layout
- `Markets` tab has had layout glitches at half-screen widths.
- The bottom nav previously disappeared or got distorted when switching to `Markets`.
- Shell should be retested at:
  - fullscreen
  - half-screen
  - narrower desktop window widths

## Intended End State
- Situation map fills the entire window.
- No top header bar.
- Floating translucent bottom nav only.
- Real current location name shown only if needed, not via a big persistent header.
- Data updates based on device location + current map viewport.
- Markets tab does not break the nav layout.
- App icon is real.

## Suggested Next Steps
1. Get `LocationManager.swift` compiling cleanly.
2. Run Xcode build again.
3. Verify `SituationView` with:
   - no top bar
   - working bottom nav
   - current location pin
   - viewport-driven reloads
4. Fix `AppIcon.appiconset`.
5. Re-test `Markets` at smaller window sizes.
6. Clean up xcodegen project/group warnings if time remains.
