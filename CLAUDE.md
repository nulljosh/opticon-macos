# Opticon macOS

Native macOS companion for Opticon. Sidebar navigation, table layouts, no UIKit.

## Key Files

- `OpticonApp.swift` -- WindowGroup entry point, unified toolbar, 1200x800 default
- `ContentView.swift` -- NavigationSplitView sidebar with 5 sections
- `API/OpticonAPI.swift` -- all backend requests (shared with iOS)
- `Models/AppState.swift` -- @Observable shared state
- `Views/SituationView.swift` -- map view (MapKit)
- `Views/MarketsView.swift` -- Table layout for stocks/commodities/crypto
- `Views/PortfolioView.swift` -- spending forecast (Charts), holdings, budget, debt, goals, statements
- `Views/SettingsView.swift` -- account, subscription, change email/password, delete
- `Views/LoginSheet.swift` -- login/register with Touch ID support

## Build

```
xcodegen generate
xcodebuild -project Opticon.xcodeproj -scheme Opticon -destination 'platform=macOS' build
```

## What Matters

- No UIKit anywhere -- pure SwiftUI + AppKit via SwiftUI
- Haptics removed (no UIFeedbackGenerator on macOS)
- iOS text field modifiers removed (.keyboardType, .textInputAutocapitalization, .submitLabel)
- Toolbar placements use .cancellationAction / .automatic instead of .topBarLeading / .topBarTrailing
- Touch ID works via LocalAuthentication framework (same as iOS)
- Backend is identical to iOS -- same API, same models

## Testing

Tests in `Tests/`. Run with:
```
xcodebuild test -project Opticon.xcodeproj -scheme OpticonTests -destination 'platform=macOS'
```
