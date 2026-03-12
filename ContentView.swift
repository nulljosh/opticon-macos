import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedSection: SidebarSection = .situation
    @State private var tickerSelectedStock: Stock?

    enum SidebarSection: String, CaseIterable, Identifiable {
        case situation = "Situation"
        case markets = "Markets"
        case predictions = "Predictions"
        case portfolio = "Portfolio"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .situation: return "map"
            case .markets: return "chart.line.uptrend.xyaxis"
            case .predictions: return "chart.pie"
            case .portfolio: return "briefcase"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            detailView
                .frame(minWidth: 700, minHeight: 500)
        }
        .navigationTitle(selectedSection.rawValue)
        .toolbar {
            if selectedSection == .markets {
                ToolbarItem(placement: .automatic) {
                    TickerToolbarView(appState: appState) { stock in
                        tickerSelectedStock = stock
                    }
                }
            }
        }
        .sheet(item: $tickerSelectedStock) { stock in
            StockDetailView(stock: stock)
                .environment(appState)
                .frame(minWidth: 500, minHeight: 400)
        }
        .overlay(alignment: .top) {
            if let error = appState.error, !error.isEmpty {
                SharedErrorBanner(message: error) {
                    appState.error = nil
                }
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $appState.showLogin) {
            LoginSheet()
                .environment(appState)
                .frame(minWidth: 400, minHeight: 400)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .situation:
            SituationView()
        case .markets:
            MarketsView()
        case .predictions:
            PredictionsView()
        case .portfolio:
            PortfolioView()
        case .settings:
            SettingsView()
        }
    }
}

private struct SharedErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: "ff3b30"))
            Text(message)
                .font(.caption)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button("Dismiss", action: onDismiss)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal)
        .shadow(radius: 8, y: 2)
    }
}

struct TickerToolbarView: View {
    let appState: AppState
    var onSelectStock: ((Stock) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(appState.stocks.prefix(8)) { stock in
                Button {
                    onSelectStock?(stock)
                } label: {
                    HStack(spacing: 4) {
                        Text(stock.symbol)
                            .font(.caption.weight(.semibold))
                        Text(String(format: "$%.2f", stock.price))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(stock.change >= 0 ? Color(hex: "34c759") : Color(hex: "ff3b30"))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
