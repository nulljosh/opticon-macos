import SwiftUI
import Charts

struct StockDetailView: View {
    @Environment(AppState.self) private var appState
    let stock: Stock

    @State private var selectedRange = "1y"
    @State private var isLoading = true
    @State private var error: String?
    @State private var priceHistory: [PriceHistory.DataPoint] = []

    private let ranges = ["1d", "5d", "1mo", "3mo", "1y"]

    private var isWatchlisted: Bool {
        appState.isInWatchlist(stock.symbol)
    }

    private var changeColor: Color {
        stock.change >= 0 ? Color(hex: "34c759") : Color(hex: "ff3b30")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(String(format: "$%.2f", stock.price))
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                    HStack(spacing: 6) {
                        Text(String(format: "%@%.2f", stock.change >= 0 ? "+" : "", stock.change))
                        Text(String(format: "(%.2f%%)", stock.changePercent))
                    }
                    .font(.callout.monospaced())
                    .foregroundStyle(changeColor)
                }
                .padding(.top, 8)

                if isLoading {
                    ProgressView()
                        .frame(height: 220)
                } else if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(height: 220)
                } else if priceHistory.count >= 2 {
                    chartView
                } else {
                    VStack(spacing: 8) {
                        Text(priceHistory.isEmpty ? "No chart data available" : "Not enough data for intraday chart")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if priceHistory.count == 1 {
                            Text(String(format: "$%.2f", priceHistory[0].close))
                                .font(.title2.monospaced())
                        }
                    }
                    .frame(height: 220)
                }

                Picker("Range", selection: $selectedRange) {
                    ForEach(ranges, id: \.self) { range in
                        Text(range.uppercased()).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(spacing: 12) {
                    if stock.volume > 0 {
                        infoRow("Volume", value: stock.formattedVolume)
                    }
                    if stock.high52 > 0 {
                        infoRow("52W High", value: String(format: "$%.2f", stock.high52))
                    }
                    if stock.low52 > 0 {
                        infoRow("52W Low", value: String(format: "$%.2f", stock.low52))
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle(stock.symbol)
        .toolbar {
            if appState.isLoggedIn {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                            if isWatchlisted {
                                await appState.removeWatchlistSymbol(stock.symbol)
                            } else {
                                await appState.addWatchlistSymbol(stock.symbol)
                            }
                        }
                    } label: {
                        Image(systemName: isWatchlisted ? "star.fill" : "star")
                            .foregroundStyle(isWatchlisted ? Color(hex: "f5a623") : .secondary)
                    }
                }
            }
        }
        .task(id: selectedRange) {
            await loadHistory()
        }
    }

    @ViewBuilder
    private var chartView: some View {
        let points = priceHistory.compactMap { point -> (Date, Double)? in
            guard let date = point.parsedDate else { return nil }
            return (date, point.close)
        }
        let minPrice = points.map(\.1).min() ?? 0
        let maxPrice = points.map(\.1).max() ?? 0
        let padding = (maxPrice - minPrice) * 0.1

        Chart {
            ForEach(points, id: \.0) { date, close in
                LineMark(
                    x: .value("Date", date),
                    y: .value("Price", close)
                )
                .foregroundStyle(Color(hex: "0071e3"))

                AreaMark(
                    x: .value("Date", date),
                    y: .value("Price", close)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color(hex: "0071e3").opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: (minPrice - padding)...(maxPrice + padding))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisValueLabel(format: xAxisFormat)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) {
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 220)
        .clipped()
        .padding(.horizontal)
    }

    private var xAxisFormat: Date.FormatStyle {
        switch selectedRange {
        case "1d", "5d":
            return .dateTime.month(.abbreviated).day()
        case "1mo":
            return .dateTime.month(.abbreviated).day()
        default:
            return .dateTime.month(.abbreviated)
        }
    }

    private func loadHistory() async {
        isLoading = true
        error = nil
        do {
            let result = try await OpticonAPI.shared.fetchPriceHistory(symbol: stock.symbol, range: selectedRange)
            priceHistory = result.history
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospaced())
        }
    }
}
