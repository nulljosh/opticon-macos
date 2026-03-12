![Opticon](icon.svg)

# Opticon macOS

![version](https://img.shields.io/badge/version-v0.1.0-blue)

Native macOS companion for [Opticon](https://opticon.heyitsmejosh.com). Financial terminal with a live map, markets, prediction markets, portfolio tracking, alerts, and account settings.

## Features

- **Map** -- Interactive MapKit view with device location, earthquakes, flights, incidents, and per-source toggles
- **Markets** -- Stocks, commodities, crypto in table layout with search and a bounded live ticker strip
- **Predictions** -- Polymarket prediction markets
- **Portfolio** -- Holdings, spending forecast (Charts), budget, debt, goals, statements
- **Alerts** -- Price alerts with create/delete
- **Auth** -- Login, register, Touch ID (LocalAuthentication), Keychain persistence, saved credentials
- **Settings** -- Subscription/account controls plus map source toggles

## Build

```
xcodegen generate
xcodebuild -project Opticon.xcodeproj -scheme Opticon -destination 'platform=macOS' build
```

Requires macOS 14+, Swift 6.0, Xcode 26+.

## Architecture

![Architecture](architecture.svg)

macOS app talks to the Vercel API (same backend as web + iOS). Auth is stored in Keychain with optional Touch ID unlock. The shell uses a bottom tab bar, the map uses viewport-driven reloads, and the markets ticker is intentionally width-bounded so tab switches do not resize the window.

## License

MIT 2026, Joshua Trommel
