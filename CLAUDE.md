# Opticon macOS

Native macOS companion for Opticon. Bottom tab shell, table-heavy market views, MapKit situation map, no UIKit.

## Key Files

- `OpticonApp.swift` -- WindowGroup entry point, unified toolbar, 1200x800 default
- `Views/ContentView.swift` -- Bottom tab shell with Map/Markets/Predictions/Portfolio/Settings
- `API/OpticonAPI.swift` -- all backend requests (shared with iOS)
- `Models/AppState.swift` -- @Observable shared state
- `Models/CoreModels.swift` -- User, CommodityData, CryptoData, WatchlistItem, PriceAlert
- `Services/Helpers.swift` -- Color(hex:) extension, KeychainHelper
- `Services/LocationManager.swift` -- device location bridge for the map
- `Views/SituationView.swift` -- full-window map view (MapKit), viewport reloads, source toggles
- `Views/MarketsView.swift` -- sortable table layout for stocks/commodities/crypto with search, P/E, and market cap
- `Views/TickerBarView.swift` -- marquee ticker with hover-to-pause, used by Markets
- `Views/PortfolioView.swift` -- spending forecast (Charts), holdings, budget, debt, goals, statements
- `Views/SettingsView.swift` -- card-based settings: profile, subscription, account, map sources, danger zone
- `Views/LoginSheet.swift` -- login/register with Touch ID support

## Build

```
xcodegen generate
xcodebuild -project Opticon.xcodeproj -scheme Opticon -destination 'platform=macOS' build
```

## What Matters

- No UIKit anywhere -- pure SwiftUI + AppKit via SwiftUI
- Bottom nav is the primary shell; avoid reintroducing sidebar navigation
- Haptics removed (no UIFeedbackGenerator on macOS)
- iOS text field modifiers removed (.keyboardType, .textInputAutocapitalization, .submitLabel)
- Toolbar placements use .cancellationAction / .automatic instead of .topBarLeading / .topBarTrailing
- Touch ID works via LocalAuthentication framework (same as iOS)
- Backend is identical to iOS -- same API, same models
- Markets layout must stay width-bounded; avoid intrinsic-width views that can resize the macOS window
- Markets sorting is part of the primary interaction model now; preserve clickable sort controls for symbol, name, price, P/E, market cap, and change
- Map data sources are user-toggleable in Settings and should be respected by `SituationView`
- Keyboard shortcuts Cmd+1 through Cmd+5 switch tabs; implemented via hidden Button bridges in BottomTabBar
- Settings uses card-based ScrollView layout (not List); settingsCard() is the shared card wrapper

## Architecture Notes

- Auth auto-saves credentials in Keychain on success; login sheet prefills from saved creds
- Sign-out does not clear saved credentials
- `LocationManager` is `@MainActor`, delegate extension is `@preconcurrency CLLocationManagerDelegate` with `nonisolated` callbacks that hop to main actor via `Task { @MainActor in ... }`
- Map loads data based on device location + current viewport (no hardcoded city presets)
- Flight feed returns `FlightFeed` (not `[Flight]`); `SituationView` unwraps `feed.states`

## Known Issues

- App icon still uses default macOS template; needs PNG assets generated from `icon.svg`
- xcodegen produces duplicate group warnings for API, Models, Services, Views (cosmetic, from project.yml structure)
- Markets tab should be retested at half-screen and narrow window widths

## Testing

Tests in `Tests/`. Run with:
```
xcodebuild test -project Opticon.xcodeproj -scheme OpticonTests -destination 'platform=macOS'
```
