import SwiftUI

struct TickerBarView: View {
    let appState: AppState
    var onSelectStock: ((Stock) -> Void)? = nil

    private var visibleStocks: [Stock] {
        Array(appState.stocks.prefix(12))
    }

    var body: some View {
        HStack(spacing: 18) {
            ForEach(visibleStocks) { stock in
                Button {
                    onSelectStock?(stock)
                } label: {
                    TickerItemView(stock: stock)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .clipped()
    }
}

private struct TickerItemView: View {
    let stock: Stock

    private var changeColor: Color {
        stock.change >= 0 ? Color(hex: "34c759") : Color(hex: "ff3b30")
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(stock.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)

            Text(stock.price, format: .currency(code: "USD").precision(.fractionLength(2)))
                .font(.caption.monospacedDigit())
                .foregroundStyle(changeColor)
        }
        .lineLimit(1)
    }
}
