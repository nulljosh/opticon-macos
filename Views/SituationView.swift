import MapKit
import SwiftUI

struct SituationView: View {
    private enum City: String, CaseIterable, Identifiable {
        case vancouver = "Vancouver"
        case nyc = "NYC"
        case london = "London"
        case tokyo = "Tokyo"

        var id: String { rawValue }

        var apiValue: String {
            switch self {
            case .vancouver: return "vancouver"
            case .nyc: return "nyc"
            case .london: return "london"
            case .tokyo: return "tokyo"
            }
        }

        var region: MKCoordinateRegion {
            switch self {
            case .vancouver:
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
                    span: MKCoordinateSpan(latitudeDelta: 2.2, longitudeDelta: 2.2)
                )
            case .nyc:
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                    span: MKCoordinateSpan(latitudeDelta: 2.2, longitudeDelta: 2.2)
                )
            case .london:
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276),
                    span: MKCoordinateSpan(latitudeDelta: 2.2, longitudeDelta: 2.2)
                )
            case .tokyo:
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 35.6764, longitude: 139.6500),
                    span: MKCoordinateSpan(latitudeDelta: 2.2, longitudeDelta: 2.2)
                )
            }
        }
    }

    @State private var selectedCity: City = .vancouver
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
            span: MKCoordinateSpan(latitudeDelta: 2.2, longitudeDelta: 2.2)
        )
    )

    @State private var earthquakes: [Earthquake] = []
    @State private var flights: [Flight] = []
    @State private var incidents: [Incident] = []
    @State private var weatherAlerts: [WeatherAlert] = []

    @State private var error: String?
    @State private var flightStatusMessage: String?
    @State private var hasLoaded = false
    @State private var selectedEvent: MapEventDetail?

    var body: some View {
        ZStack {
            mapView

            VStack(spacing: 0) {
                headerOverlay
                Spacer()
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            restoreSnapshot()
            Task {
                await Task.yield()
                await loadData(for: selectedCity)
            }
        }
        .onChange(of: selectedCity) { _, newValue in
            mapPosition = .region(newValue.region)
            Task {
                await loadData(for: newValue)
            }
        }
        .sheet(item: $selectedEvent) { event in
            SituationEventDetailView(event: event)
                .frame(minWidth: 400, minHeight: 300)
        }
    }

    private var headerOverlay: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedCity == .vancouver ? "Current Location" : selectedCity.rawValue)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(selectedCitySubtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer()

                    Picker("Location", selection: $selectedCity) {
                        ForEach(City.allCases) { city in
                            Text(city.rawValue).tag(city)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                HStack(spacing: 8) {
                    statusChip(title: "\(earthquakes.count) quakes", color: .red)
                    statusChip(title: "\(incidents.count) incidents", color: Color(hex: "ffbf00"))
                    if !weatherAlerts.isEmpty {
                        statusChip(title: "\(weatherAlerts.count) alerts", color: Color(hex: "34c759"))
                    }
                    if let flightStatusMessage {
                        statusChip(title: flightStatusMessage, color: .secondary)
                    } else {
                        statusChip(title: "\(flights.count) flights", color: .cyan)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 12, y: 3)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var selectedCitySubtitle: String {
        switch selectedCity {
        case .vancouver:
            return "Primary live view"
        default:
            return "Secondary watch location"
        }
    }

    private func statusChip(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
            .foregroundStyle(.white)
    }

    private var mapView: some View {
        Map(position: $mapPosition) {
            ForEach(earthquakes) { quake in
                Annotation(quake.title, coordinate: quake.coordinate) {
                    Button {
                        selectedEvent = .earthquake(quake)
                    } label: {
                        mapPin(color: .red, systemImage: "waveform.path.ecg")
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(flights) { flight in
                Annotation(flight.callsign, coordinate: flight.coordinate) {
                    Button {
                        selectedEvent = .flight(flight)
                    } label: {
                        mapPin(color: .cyan, systemImage: "airplane")
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(incidents) { incident in
                Annotation(incident.title, coordinate: incident.coordinate) {
                    Button {
                        selectedEvent = .incident(incident)
                    } label: {
                        mapPin(color: Color(hex: "ffbf00"), systemImage: "exclamationmark.triangle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    private func mapPin(color: Color, systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(8)
            .background(color, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
    }

    private func loadData(for city: City) async {
        error = nil
        flightStatusMessage = nil
        defer { saveSnapshot() }

        let center = city.region.center
        let span = city.region.span
        let lamin = center.latitude - span.latitudeDelta / 2
        let lamax = center.latitude + span.latitudeDelta / 2
        let lomin = center.longitude - span.longitudeDelta / 2
        let lomax = center.longitude + span.longitudeDelta / 2

        async let earthquakeLoad = loadSection(label: "Earthquakes") {
            try await OpticonAPI.shared.fetchEarthquakes()
        }
        async let flightLoad = loadFlights(lamin: lamin, lomin: lomin, lamax: lamax, lomax: lomax)
        async let incidentLoad = loadSection(label: "Incidents") {
            try await OpticonAPI.shared.fetchIncidents(lat: center.latitude, lon: center.longitude)
        }
        async let weatherLoad = loadSection(label: "Weather") {
            try await OpticonAPI.shared.fetchWeatherAlerts(lat: center.latitude, lon: center.longitude)
        }

        let earthquakeResult = await earthquakeLoad
        let flightResult = await flightLoad
        let incidentResult = await incidentLoad
        let weatherResult = await weatherLoad

        if earthquakeResult.error == nil || !earthquakeResult.value.isEmpty {
            earthquakes = earthquakeResult.value
        }
        if flightResult.error == nil || !flightResult.value.isEmpty {
            flights = flightResult.value
        }
        if incidentResult.error == nil || !incidentResult.value.isEmpty {
            incidents = incidentResult.value
        }
        if weatherResult.error == nil || !weatherResult.value.isEmpty {
            weatherAlerts = weatherResult.value
        }
        flightStatusMessage = flightResult.error

        let failures = [
            earthquakeResult.error,
            incidentResult.error,
            weatherResult.error,
        ].compactMap { $0 }
        if !failures.isEmpty {
            error = failures.joined(separator: "  ")
        }
    }

    private func loadFlights(
        lamin: Double, lomin: Double, lamax: Double, lomax: Double
    ) async -> (value: [Flight], error: String?) {
        do {
            let flights = try await OpticonAPI.shared.fetchFlights(
                lamin: lamin, lomin: lomin, lamax: lamax, lomax: lomax
            )
            return (flights, nil)
        } catch {
            return ([], "Flights unavailable")
        }
    }

    private func loadSection<T>(
        label: String, _ operation: () async throws -> T
    ) async -> (value: T, error: String?) where T: RangeReplaceableCollection {
        do {
            return (try await operation(), nil)
        } catch {
            return (.init(), "\(label) unavailable")
        }
    }

    private func restoreSnapshot() {
        guard let data = UserDefaults.standard.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(SituationSnapshot.self, from: data)
        else {
            mapPosition = .region(selectedCity.region)
            return
        }

        if let city = City(rawValue: snapshot.selectedCity) {
            selectedCity = city
            mapPosition = .region(city.region)
        } else {
            mapPosition = .region(selectedCity.region)
        }

        earthquakes = snapshot.earthquakes.map { $0.model }
        flights = snapshot.flights.map { $0.model }
        incidents = snapshot.incidents.map { $0.model }
        weatherAlerts = snapshot.weatherAlerts.map { $0.model }
        flightStatusMessage = snapshot.flightStatusMessage
    }

    private func saveSnapshot() {
        let snapshot = SituationSnapshot(
            selectedCity: selectedCity.rawValue,
            earthquakes: earthquakes.map(SnapshotEarthquake.init),
            flights: flights.map(SnapshotFlight.init),
            incidents: incidents.map(SnapshotIncident.init),
            weatherAlerts: weatherAlerts.map(SnapshotWeatherAlert.init),
            flightStatusMessage: flightStatusMessage
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: snapshotKey)
    }

    private var snapshotKey: String { "situation.snapshot.v1" }
}

private enum MapEventDetail: Identifiable {
    case earthquake(Earthquake)
    case flight(Flight)
    case incident(Incident)

    var id: String {
        switch self {
        case .earthquake(let quake): return "quake-\(quake.id)"
        case .flight(let flight): return "flight-\(flight.id)"
        case .incident(let incident): return "incident-\(incident.id)"
        }
    }
}

private struct SituationEventDetailView: View {
    let event: MapEventDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title3.weight(.bold))

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(rows, id: \.label) { row in
                    HStack(alignment: .top) {
                        Text(row.label)
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 92, alignment: .leading)
                        Text(row.value)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var title: String {
        switch event {
        case .earthquake(let quake): return quake.title
        case .flight(let flight): return flight.callsign
        case .incident(let incident): return incident.title
        }
    }

    private var subtitle: String? {
        switch event {
        case .earthquake(let quake): return quake.place
        case .flight(let flight): return flight.origin ?? flight.destination
        case .incident(let incident): return incident.summary
        }
    }

    private var rows: [(label: String, value: String)] {
        switch event {
        case .earthquake(let quake):
            return [
                ("Magnitude", String(format: "%.1f", quake.magnitude)),
                ("Depth", quake.depthKm.map { String(format: "%.1f km", $0) } ?? "Unknown"),
                ("Latitude", String(format: "%.4f", quake.latitude)),
                ("Longitude", String(format: "%.4f", quake.longitude)),
                ("Time", quake.occurredAt ?? "Unknown"),
            ]
        case .flight(let flight):
            return [
                ("Origin", flight.origin ?? "Unknown"),
                ("Destination", flight.destination ?? "Unknown"),
                ("Altitude", flight.altitudeFeet.map { "\($0) ft" } ?? "Unknown"),
                ("Latitude", String(format: "%.4f", flight.latitude)),
                ("Longitude", String(format: "%.4f", flight.longitude)),
                ("Status", flight.status ?? "Live"),
            ]
        case .incident(let incident):
            return [
                ("Severity", incident.severity.capitalized),
                ("Latitude", String(format: "%.4f", incident.latitude)),
                ("Longitude", String(format: "%.4f", incident.longitude)),
                ("Reported", incident.reportedAt ?? "Unknown"),
                ("Summary", incident.summary ?? "No summary"),
            ]
        }
    }
}

private struct SituationSnapshot: Codable {
    let selectedCity: String
    let earthquakes: [SnapshotEarthquake]
    let flights: [SnapshotFlight]
    let incidents: [SnapshotIncident]
    let weatherAlerts: [SnapshotWeatherAlert]
    let flightStatusMessage: String?
}

private struct SnapshotEarthquake: Codable {
    let id: String
    let title: String
    let magnitude: Double
    let latitude: Double
    let longitude: Double
    let depthKm: Double?
    let place: String?
    let occurredAt: String?

    init(_ quake: Earthquake) {
        id = quake.id; title = quake.title; magnitude = quake.magnitude
        latitude = quake.latitude; longitude = quake.longitude
        depthKm = quake.depthKm; place = quake.place; occurredAt = quake.occurredAt
    }

    var model: Earthquake {
        Earthquake(id: id, title: title, magnitude: magnitude, latitude: latitude,
                   longitude: longitude, depthKm: depthKm, place: place, occurredAt: occurredAt)
    }
}

private struct SnapshotFlight: Codable {
    let id: String; let callsign: String; let origin: String?; let destination: String?
    let latitude: Double; let longitude: Double; let altitudeFeet: Int?; let status: String?

    init(_ flight: Flight) {
        id = flight.id; callsign = flight.callsign; origin = flight.origin
        destination = flight.destination; latitude = flight.latitude
        longitude = flight.longitude; altitudeFeet = flight.altitudeFeet; status = flight.status
    }

    var model: Flight {
        Flight(id: id, callsign: callsign, origin: origin, destination: destination,
               latitude: latitude, longitude: longitude, altitudeFeet: altitudeFeet, status: status)
    }
}

private struct SnapshotIncident: Codable {
    let id: String; let title: String; let severity: String
    let latitude: Double; let longitude: Double; let summary: String?; let reportedAt: String?

    init(_ incident: Incident) {
        id = incident.id; title = incident.title; severity = incident.severity
        latitude = incident.latitude; longitude = incident.longitude
        summary = incident.summary; reportedAt = incident.reportedAt
    }

    var model: Incident {
        Incident(id: id, title: title, severity: severity, latitude: latitude,
                 longitude: longitude, summary: summary, reportedAt: reportedAt)
    }
}

private struct SnapshotWeatherAlert: Codable {
    let id: String; let title: String; let severity: String
    let summary: String?; let effectiveAt: String?; let expiresAt: String?

    init(_ alert: WeatherAlert) {
        id = alert.id; title = alert.title; severity = alert.severity
        summary = alert.summary; effectiveAt = alert.effectiveAt; expiresAt = alert.expiresAt
    }

    var model: WeatherAlert {
        WeatherAlert(id: id, title: title, severity: severity, summary: summary,
                     effectiveAt: effectiveAt, expiresAt: expiresAt)
    }
}
