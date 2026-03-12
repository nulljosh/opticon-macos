import SwiftUI

struct MarketsView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var isVisible = false
    @State private var hasLoaded = false
    @State private var selectedStock: Stock?

    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var marketStatusText: String { usMarketStatus.label }
    private var marketStatusColor: Color { usMarketStatus.color }

    private var allItems: [MarketItem] {
        var items: [MarketItem] = []
        for stock in appState.stocks {
            items.append(MarketItem(
                name: stock.name, symbol: stock.symbol, price: stock.price,
                changePercent: stock.changePercent, kind: .stock(stock)
            ))
        }
        for commodity in appState.commodities {
            items.append(MarketItem(
                name: commodity.name, symbol: commodity.name, price: commodity.price,
                changePercent: commodity.changePercent, kind: .commodity
            ))
        }
        for coin in appState.crypto {
            items.append(MarketItem(
                name: coin.symbol, symbol: coin.symbol, price: coin.spot,
                changePercent: coin.chgPct, kind: .crypto
            ))
        }
        return items.sorted { $0.changePercent > $1.changePercent }
    }

    private var filteredItems: [MarketItem] {
        if searchText.isEmpty { return allItems }
        return allItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if appState.isLoading && appState.stocks.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.stocks.isEmpty && appState.commodities.isEmpty && appState.crypto.isEmpty {
                ContentUnavailableView(
                    "Markets Temporarily Unavailable",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Click refresh to try again.")
                )
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Circle()
                            .fill(marketStatusColor)
                            .frame(width: 10, height: 10)
                        Text(marketStatusText)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("Auto refresh: 30s")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            Task {
                                async let s: Void = appState.loadStocks(force: true)
                                async let c: Void = appState.loadCommodities(force: true)
                                async let k: Void = appState.loadCrypto(force: true)
                                _ = await (s, c, k)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    HStack(spacing: 12) {
                        NavigationLink {
                            NewsView()
                                .environment(appState)
                        } label: {
                            Label("News", systemImage: "newspaper")
                        }
                        NavigationLink {
                            MacroView()
                                .environment(appState)
                        } label: {
                            Label("Macro", systemImage: "chart.bar.doc.horizontal")
                        }
                        NavigationLink {
                            AlertsView()
                                .environment(appState)
                        } label: {
                            Label("Alerts", systemImage: "bell.badge")
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    TextField("Search markets", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    Table(filteredItems) {
                        TableColumn("Symbol") { item in
                            HStack(spacing: 6) {
                                if case .stock(let stock) = item.kind, appState.isLoggedIn {
                                    Button {
                                        Task {
                                            if appState.isInWatchlist(stock.symbol) {
                                                await appState.removeWatchlistSymbol(stock.symbol)
                                            } else {
                                                await appState.addWatchlistSymbol(stock.symbol)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: appState.isInWatchlist(stock.symbol) ? "star.fill" : "star")
                                            .foregroundStyle(appState.isInWatchlist(stock.symbol) ? Color(hex: "f5a623") : .secondary)
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text(item.symbol)
                                    .font(.body.weight(.medium))
                            }
                        }
                        .width(min: 80, ideal: 120)

                        TableColumn("Name") { item in
                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .width(min: 100, ideal: 200)

                        TableColumn("Price") { item in
                            Text(String(format: "$%.2f", item.price))
                                .font(.body.monospacedDigit())
                        }
                        .width(min: 80, ideal: 100)

                        TableColumn("Change") { item in
                            Text(String(format: "%@%.2f%%", item.changePercent >= 0 ? "+" : "", item.changePercent))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(item.changePercent >= 0 ? Color(hex: "34c759") : Color(hex: "ff3b30"))
                        }
                        .width(min: 80, ideal: 100)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            isVisible = true
            guard !hasLoaded else { return }
            hasLoaded = true
            Task {
                async let stocks: Void = appState.loadStocks()
                async let watchlist: Void = appState.loadWatchlist()
                async let commodities: Void = appState.loadCommodities()
                async let crypto: Void = appState.loadCrypto()
                _ = await (stocks, watchlist, commodities, crypto)
            }
        }
        .onDisappear { isVisible = false }
        .onChange(of: appState.isLoggedIn) { _, isLoggedIn in
            guard isLoggedIn, appState.watchlist.isEmpty else { return }
            Task { await appState.loadWatchlist() }
        }
        .onReceive(refreshTimer) { _ in
            guard isVisible else { return }
            Task {
                async let s: Void = appState.loadStocks(force: true)
                async let c: Void = appState.loadCommodities(force: true)
                async let k: Void = appState.loadCrypto(force: true)
                _ = await (s, c, k)
            }
        }
    }
}

private extension MarketsView {
    var usMarketStatus: (label: String, color: Color) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let now = Date()
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        let weekday = components.weekday ?? 0
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        let isWeekday = (2...6).contains(weekday)
        let premarketStart = 4 * 60
        let marketOpen = 9 * 60 + 30
        let marketClose = 16 * 60
        let afterHoursClose = 20 * 60

        guard isWeekday else { return ("Market Closed", .secondary) }
        if minutes >= marketOpen && minutes < marketClose {
            return ("Market Open", Color(hex: "34c759"))
        }
        if minutes >= premarketStart && minutes < marketOpen {
            return ("Pre-Market", Color(hex: "f5a623"))
        }
        if minutes >= marketClose && minutes < afterHoursClose {
            return ("After Hours", Color(hex: "f5a623"))
        }
        return ("Market Closed", .secondary)
    }
}

private struct MarketItem: Identifiable {
    let name: String
    let symbol: String
    let price: Double
    let changePercent: Double
    let kind: Kind

    var id: String {
        switch kind {
        case .stock: return "stock-\(symbol)"
        case .commodity: return "commodity-\(name)"
        case .crypto: return "crypto-\(symbol)"
        }
    }

    enum Kind {
        case stock(Stock)
        case commodity
        case crypto
    }
}
