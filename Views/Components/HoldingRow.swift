import SwiftUI

struct HoldingRow: View {
    let holding: Portfolio.Holding

    private var gainColor: Color {
        holding.gainLoss >= 0 ? Color(hex: "34c759") : Color(hex: "ff3b30")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.headline)
                Text(String(format: "%.4f shares", holding.shares))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", holding.marketValue))
                    .font(.body)
                Text(String(format: "%@$%.2f", holding.gainLoss >= 0 ? "+" : "", holding.gainLoss))
                    .font(.caption)
                    .foregroundStyle(gainColor)
            }
        }
    }
}
