import Foundation

struct Stock: Codable, Identifiable, Hashable {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Double
    let high52: Double
    let low52: Double

    var id: String { symbol }

    var formattedVolume: String {
        if volume >= 1_000_000_000 {
            return String(format: "%.1fB", volume / 1_000_000_000)
        } else if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", volume / 1_000)
        }
        return String(format: "%.0f", volume)
    }

    enum CodingKeys: String, CodingKey {
        case symbol, name, price, change, volume
        case changePercent = "changesPercentage"
        case high52 = "yearHigh"
        case low52 = "yearLow"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? symbol
        price = try container.decode(Double.self, forKey: .price)
        change = try container.decodeIfPresent(Double.self, forKey: .change) ?? 0
        changePercent = try container.decodeIfPresent(Double.self, forKey: .changePercent) ?? 0
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0
        high52 = try container.decodeIfPresent(Double.self, forKey: .high52) ?? 0
        low52 = try container.decodeIfPresent(Double.self, forKey: .low52) ?? 0
    }

    init(symbol: String, name: String, price: Double, change: Double = 0,
         changePercent: Double = 0, volume: Double = 0, high52: Double = 0, low52: Double = 0) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.high52 = high52
        self.low52 = low52
    }
}
