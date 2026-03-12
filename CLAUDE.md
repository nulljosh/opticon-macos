# Opticon macOS

Native macOS companion for Opticon. Bottom tab shell, table-heavy market views, MapKit situation map, no UIKit.

## Key Files

- `OpticonApp.swift` -- WindowGroup entry point, unified toolbar, 1200x800 default
- `ContentView.swift` -- Bottom tab shell with Map/Markets/Predictions/Portfolio/Settings
- `API/OpticonAPI.swift` -- all backend requests (shared with iOS)
- `Models/AppState.swift` -- @Observable shared state
- `Views/SituationView.swift` -- full-window map view (MapKit), viewport reloads, source toggles
- `Views/MarketsView.swift` -- sortable table layout for stocks/commodities/crypto with search, P/E, and market cap
- `Views/TickerBarView.swift` -- bounded top ticker used by Markets
- `Views/PortfolioView.swift` -- spending forecast (Charts), holdings, budget, debt, goals, statements
- `Views/SettingsView.swift` -- account, subscription, map source toggles, change email/password, delete
- `Views/LoginSheet.swift` -- login/register with Touch ID support
- `Services/LocationManager.swift` -- device location bridge for the map

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

## Testing

Tests in `Tests/`. Run with:
```
xcodebuild test -project Opticon.xcodeproj -scheme OpticonTests -destination 'platform=macOS'
```
