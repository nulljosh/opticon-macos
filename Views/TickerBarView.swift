import SwiftUI

struct TickerBarView: View {
    let appState: AppState
    var onSelectStock: ((Stock) -> Void)? = nil

    @State private var singleTrackWidth: CGFloat = 0
    @State private var trackOffset: CGFloat = 0
    @State private var isHovering = false

    private let itemSpacing: CGFloat = 18
    private let animationSpeed: CGFloat = 40

    private var visibleStocks: [Stock] {
        Array(appState.stocks.prefix(14))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if visibleStocks.isEmpty {
                    Color.clear
                } else {
                    HStack(spacing: itemSpacing) {
                        tickerTrack(visibleStocks)
                        tickerTrack(visibleStocks)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: trackOffset)
                    .onAppear {
                        restartAnimation(containerWidth: geometry.size.width)
                    }
                    .onChange(of: visibleStocks.map(\.id)) { _, _ in
                        restartAnimation(containerWidth: geometry.size.width)
                    }
                    .onChange(of: singleTrackWidth) { _, _ in
                        restartAnimation(containerWidth: geometry.size.width)
                    }
                    .onChange(of: isHovering) { _, hovering in
                        if hovering {
                            stopAnimation()
                        } else {
                            restartAnimation(containerWidth: geometry.size.width)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .clipped()
    }

    private func tickerTrack(_ stocks: [Stock]) -> some View {
        HStack(spacing: itemSpacing) {
            ForEach(stocks) { stock in
                Button {
                    onSelectStock?(stock)
                } label: {
                    TickerItemView(stock: stock)
                }
                .buttonStyle(.plain)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(trackWidthReader)
    }

    private var trackWidthReader: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    singleTrackWidth = geometry.size.width
                }
                .onChange(of: geometry.size.width) { _, width in
                    singleTrackWidth = width
                }
        }
    }

    private func restartAnimation(containerWidth: CGFloat) {
        guard !isHovering else { return }
        guard singleTrackWidth > containerWidth, visibleStocks.count > 1 else {
            stopAnimation()
            return
        }

        let distance = singleTrackWidth + itemSpacing
        let duration = max(distance / animationSpeed, 12)

        trackOffset = 0
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            trackOffset = -distance
        }
    }

    private func stopAnimation() {
        withAnimation(.none) {
            trackOffset = 0
        }
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
        .padding(.vertical, 2)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
}
