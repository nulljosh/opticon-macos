import Foundation

private extension KeyedDecodingContainer where Key == Stock.CodingKeys {
    func flexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            let cleaned = value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "+", with: "")
            return Double(cleaned)
        }
        return nil
    }
}

struct Stock: Decodable, Identifiable, Hashable {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Double
    let high52: Double
    let low52: Double
    let marketCap: Double?
    let peRatio: Double?

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

    var formattedMarketCap: String {
        guard let marketCap, marketCap > 0 else { return "N/A" }
        if marketCap >= 1_000_000_000_000 {
            return String(format: "$%.2fT", marketCap / 1_000_000_000_000)
        } else if marketCap >= 1_000_000_000 {
            return String(format: "$%.1fB", marketCap / 1_000_000_000)
        } else if marketCap >= 1_000_000 {
            return String(format: "$%.0fM", marketCap / 1_000_000)
        }
        return String(format: "$%.0f", marketCap)
    }

    var formattedPERatio: String {
        guard let peRatio, peRatio > 0 else { return "N/A" }
        return String(format: "%.1f", peRatio)
    }

    enum CodingKeys: String, CodingKey {
        case symbol, name, price, change, volume
        case changePercent = "changesPercentage"
        case changePercentAlt = "changePercent"
        case changePercentSnake = "change_percent"
        case regularMarketChangePercent
        case high52 = "yearHigh"
        case low52 = "yearLow"
        case marketCap
        case marketCapSnake = "market_cap"
        case marketCapitalization
        case pe
        case peRatio
        case trailingPE
        case priceEarningsRatio
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? symbol
        price = container.flexibleDouble(forKey: .price) ?? 0
        change = container.flexibleDouble(forKey: .change) ?? 0
        let decodedPercent = container.flexibleDouble(forKey: .changePercent)
            ?? container.flexibleDouble(forKey: .changePercentAlt)
            ?? container.flexibleDouble(forKey: .changePercentSnake)
            ?? container.flexibleDouble(forKey: .regularMarketChangePercent)
        if let decodedPercent {
            changePercent = decodedPercent
        } else if price != 0 {
            changePercent = (change / (price - change)) * 100
        } else {
            changePercent = 0
        }
        volume = container.flexibleDouble(forKey: .volume) ?? 0
        high52 = container.flexibleDouble(forKey: .high52) ?? 0
        low52 = container.flexibleDouble(forKey: .low52) ?? 0
        marketCap = container.flexibleDouble(forKey: .marketCap)
            ?? container.flexibleDouble(forKey: .marketCapSnake)
            ?? container.flexibleDouble(forKey: .marketCapitalization)
        peRatio = container.flexibleDouble(forKey: .pe)
            ?? container.flexibleDouble(forKey: .peRatio)
            ?? container.flexibleDouble(forKey: .trailingPE)
            ?? container.flexibleDouble(forKey: .priceEarningsRatio)
    }

    init(symbol: String, name: String, price: Double, change: Double = 0,
         changePercent: Double = 0, volume: Double = 0, high52: Double = 0, low52: Double = 0,
         marketCap: Double? = nil, peRatio: Double? = nil) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.high52 = high52
        self.low52 = low52
        self.marketCap = marketCap
        self.peRatio = peRatio
    }
}
