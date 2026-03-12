![Opticon](icon.svg)

# Opticon macOS

![version](https://img.shields.io/badge/version-v0.1.0-blue)

Native macOS companion for [Opticon](https://opticon.heyitsmejosh.com). Financial terminal with a live map, markets, prediction markets, portfolio tracking, alerts, and account settings.

## Features

- **Map** -- Interactive MapKit view with device location, earthquakes, flights, incidents, and per-source toggles
- **Markets** -- Stocks, commodities, crypto in a sortable table with search, P/E and market-cap columns, and a scrolling marquee ticker with hover-to-pause
- **Predictions** -- Polymarket prediction markets
- **Portfolio** -- Holdings, spending forecast (Charts), budget, debt, goals, statements
- **Alerts** -- Price alerts with create/delete
- **Auth** -- Login, register, Touch ID (LocalAuthentication), Keychain persistence, saved credentials
- **Settings** -- Card-based layout with profile, subscription tiers, account actions, map source toggles, and danger zone
- **Keyboard Shortcuts** -- Cmd+1 through Cmd+5 to switch tabs

## Build

```
xcodegen generate
xcodebuild -project Opticon.xcodeproj -scheme Opticon -destination 'platform=macOS' build
```

Requires macOS 14+, Swift 6.0, Xcode 26+.

## Architecture

![Architecture](architecture.svg)

- Vercel API backend (shared with web + iOS)
- Keychain auth with optional Touch ID unlock
- Bottom tab bar shell, Cmd+1-5 keyboard shortcuts
- Viewport-driven map reloads
- Marquee ticker with hover-to-pause
- Card-based Settings layout
- Markets sortable by symbol, name, price, P/E, market cap, change

## License

MIT 2026, Joshua Trommel
