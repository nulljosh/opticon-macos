![Opticon](icon.svg)

# Opticon macOS

![version](https://img.shields.io/badge/version-v0.1.0-blue)

Native macOS companion for [Opticon](https://opticon.heyitsmejosh.com). Financial terminal with situation map, markets, prediction markets, portfolio tracking, and alerts.

## Features

- **Situation Map** -- GDELT earthquakes, flights, incidents on an interactive map
- **Markets** -- Stocks, commodities, crypto in table layout with search
- **Predictions** -- Polymarket prediction markets
- **Portfolio** -- Holdings, spending forecast (Charts), budget, debt, goals, statements
- **Alerts** -- Price alerts with create/delete
- **Auth** -- Login, register, Touch ID (LocalAuthentication), Keychain persistence

## Build

```
xcodegen generate
xcodebuild -project Opticon.xcodeproj -scheme Opticon -destination 'platform=macOS' build
```

Requires macOS 14+, Swift 6.0, Xcode 26+.

## Architecture

![Architecture](architecture.svg)

macOS app talks to the Vercel API (same backend as web + iOS). Auth stored in Keychain with optional Touch ID unlock.

## License

MIT 2026, Joshua Trommel
