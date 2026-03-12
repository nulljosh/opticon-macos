import CoreLocation
import Foundation

private extension KeyedDecodingContainer {
    func lossyString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func lossyDouble(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Double(value)
        }
        return nil
    }

    func lossyInt(forKey key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Int(Double(value) ?? 0)
        }
        return nil
    }
}

private extension String {
    var isLowSignalIncidentType: Bool {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .lowercased()
        let lowSignalTypes: Set<String> = [
            "gate",
            "bollard",
            "barrier",
            "obstruction",
            "hazard",
            "incident",
            "closure",
            "construction",
            "event"
        ]
        return lowSignalTypes.contains(normalized)
    }

    var normalizedIncidentTitle: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                guard !lowercased.isEmpty else { return "" }
                return lowercased.prefix(1).uppercased() + lowercased.dropFirst()
            }
            .joined(separator: " ")
    }
}

struct Earthquake: Decodable, Identifiable {
    let id: String
    let title: String
    let magnitude: Double
    let latitude: Double
    let longitude: Double
    let depthKm: Double?
    let place: String?
    let occurredAt: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, magnitude, latitude, longitude, place
        case mag, lat, lon, time, depth
        case depthKm = "depth_km"
        case occurredAt = "occurred_at"
    }

    init(
        id: String,
        title: String,
        magnitude: Double,
        latitude: Double,
        longitude: Double,
        depthKm: Double?,
        place: String?,
        occurredAt: String?
    ) {
        self.id = id
        self.title = title
        self.magnitude = magnitude
        self.latitude = latitude
        self.longitude = longitude
        self.depthKm = depthKm
        self.place = place
        self.occurredAt = occurredAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        magnitude = container.lossyDouble(forKey: .magnitude)
            ?? container.lossyDouble(forKey: .mag)
            ?? 0
        latitude = container.lossyDouble(forKey: .latitude)
            ?? container.lossyDouble(forKey: .lat)
            ?? 0
        longitude = container.lossyDouble(forKey: .longitude)
            ?? container.lossyDouble(forKey: .lon)
            ?? 0
        depthKm = container.lossyDouble(forKey: .depthKm)
            ?? container.lossyDouble(forKey: .depth)
        place = container.lossyString(forKey: .place)
        occurredAt = container.lossyString(forKey: .occurredAt)
            ?? container.lossyString(forKey: .time)
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? place
            ?? "Earthquake"
        id = container.lossyString(forKey: .id)
            ?? "\(title)-\(occurredAt ?? "unknown")-\(latitude)-\(longitude)"
    }
}

struct Flight: Decodable, Identifiable {
    let id: String
    let callsign: String
    let origin: String?
    let destination: String?
    let latitude: Double
    let longitude: Double
    let altitudeFeet: Int?
    let status: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id, callsign, origin, destination, latitude, longitude, status
        case icao24, lat, lon, altitude
        case altitudeFeet = "altitude_feet"
    }

    init(
        id: String,
        callsign: String,
        origin: String?,
        destination: String?,
        latitude: Double,
        longitude: Double,
        altitudeFeet: Int?,
        status: String?
    ) {
        self.id = id
        self.callsign = callsign
        self.origin = origin
        self.destination = destination
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeFeet = altitudeFeet
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallbackId = container.lossyString(forKey: .icao24) ?? UUID().uuidString
        id = container.lossyString(forKey: .id) ?? fallbackId
        callsign = container.lossyString(forKey: .callsign) ?? fallbackId.uppercased()
        origin = container.lossyString(forKey: .origin)
        destination = container.lossyString(forKey: .destination)
        latitude = container.lossyDouble(forKey: .latitude)
            ?? container.lossyDouble(forKey: .lat)
            ?? 0
        longitude = container.lossyDouble(forKey: .longitude)
            ?? container.lossyDouble(forKey: .lon)
            ?? 0
        altitudeFeet = container.lossyInt(forKey: .altitudeFeet)
            ?? container.lossyInt(forKey: .altitude)
        status = container.lossyString(forKey: .status)
    }
}

struct FlightFeed: Decodable {
    let states: [Flight]
    let meta: FlightFeedMeta?
}

struct FlightFeedMeta: Decodable {
    let status: String?
    let warning: String?
    let cached: Bool?
    let degraded: Bool?
}

struct Incident: Decodable, Identifiable {
    let id: String
    let title: String
    let severity: String
    let latitude: Double
    let longitude: Double
    let summary: String?
    let reportedAt: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, severity, latitude, longitude, summary
        case type, lat, lon, description
        case reportedAt = "reported_at"
    }

    init(
        id: String,
        title: String,
        severity: String,
        latitude: Double,
        longitude: Double,
        summary: String?,
        reportedAt: String?
    ) {
        self.id = id
        self.title = title
        self.severity = severity
        self.latitude = latitude
        self.longitude = longitude
        self.summary = summary
        self.reportedAt = reportedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sourceTitle = container.lossyString(forKey: .title)
        let sourceType = container.lossyString(forKey: .type)
        let normalizedTitle = sourceTitle?.normalizedIncidentTitle
        let normalizedType = sourceType?.normalizedIncidentTitle
        let fallbackTitle = normalizedTitle
            ?? (sourceType?.isLowSignalIncidentType == true ? nil : normalizedType)
            ?? "Incident"
        title = fallbackTitle
        severity = container.lossyString(forKey: .severity) ?? "info"
        latitude = container.lossyDouble(forKey: .latitude)
            ?? container.lossyDouble(forKey: .lat)
            ?? 0
        longitude = container.lossyDouble(forKey: .longitude)
            ?? container.lossyDouble(forKey: .lon)
            ?? 0
        summary = container.lossyString(forKey: .summary)
            ?? container.lossyString(forKey: .description)
        reportedAt = container.lossyString(forKey: .reportedAt)
        id = container.lossyString(forKey: .id)
            ?? "\(fallbackTitle)-\(latitude)-\(longitude)"
    }
}

struct WeatherAlert: Decodable, Identifiable {
    let id: String
    let title: String
    let severity: String
    let summary: String?
    let effectiveAt: String?
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, severity, summary
        case event, headline, expires
        case effectiveAt = "effective_at"
        case expiresAt = "expires_at"
    }

    init(
        id: String,
        title: String,
        severity: String,
        summary: String?,
        effectiveAt: String?,
        expiresAt: String?
    ) {
        self.id = id
        self.title = title
        self.severity = severity
        self.summary = summary
        self.effectiveAt = effectiveAt
        self.expiresAt = expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallbackTitle = container.lossyString(forKey: .title)
            ?? container.lossyString(forKey: .event)
            ?? "Weather Alert"
        title = fallbackTitle
        severity = container.lossyString(forKey: .severity) ?? "info"
        summary = container.lossyString(forKey: .summary)
            ?? container.lossyString(forKey: .headline)
        effectiveAt = container.lossyString(forKey: .effectiveAt)
        expiresAt = container.lossyString(forKey: .expiresAt)
            ?? container.lossyString(forKey: .expires)
        id = container.lossyString(forKey: .id)
            ?? "\(fallbackTitle)-\(expiresAt ?? "none")"
    }
}
