//
//  FlightDetailView.swift
//  AeroLog
//
//  Created by Yu-Han on 06/09/2025
//
//  Edited by Riley Martin on 13/10/2025
//  Edited by Yu-Han on 15/10/2025
//  Polished UI by ChatGPT on 20/10/2025
//

import SwiftUI
import CoreLocation
import MapKit
import UIKit

struct FlightDetailView: View {
    let task: FlightTask

    @State private var isLoading = true
    @State private var departureCoordinate: CLLocationCoordinate2D?
    @State private var arrivalCoordinate: CLLocationCoordinate2D?
    @State private var planeCoordinate: CLLocationCoordinate2D?
    @State private var liveFlightData: FlightSearchResult?
    @State private var isFlightActive = false
    @State private var arrivalWeather: WeatherResponse?
    @State private var weatherError: String = ""
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )

    let flightService = FlightSearchService.shared
    let weatherService = WeatherService()

    // MARK: - Distance/Duration helpers
    var routeDistanceKm: Double? {
        guard let dep = departureCoordinate, let arr = arrivalCoordinate else { return nil }
        return Self.haversineDistanceKm(from: dep, to: arr)
    }

    var scheduledDurationHours: Double? {
        guard let (dep, arr) = parseFlightTimes() else { return nil }
        let seconds = arr.timeIntervalSince(dep)
        return max(0, seconds) / 3600.0
    }

    static func haversineDistanceKm(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let earthRadiusKm = 6371.0
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(from.latitude * .pi / 180) * cos(to.latitude * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map layer
            FlightMapView(
                departureCoordinate: departureCoordinate,
                arrivalCoordinate: arrivalCoordinate,
                planeCoordinate: planeCoordinate,
                departureCode: task.departure,
                arrivalCode: task.arrival,
                isActive: isFlightActive,
                liveData: liveFlightData?.live,
                region: $mapRegion
            )
            .ignoresSafeArea()

            // Subtle bottom gradient to help legibility
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.25), Color.black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Loading state
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading flight details...")
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    Spacer()
                }
                .transition(.opacity)
            }

            // Polished bottom sheet
            if !isLoading {
                FlightDetailBottomSheet(
                    task: task,
                    isFlightActive: isFlightActive,
                    arrivalWeather: arrivalWeather,
                    weatherError: weatherError,
                    routeDistanceKm: routeDistanceKm,
                    scheduledDurationHours: scheduledDurationHours
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .contain)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await fetchLocationsAndWeather() }
        }
    }

    // MARK: - Data & State

    func fetchLocationsAndWeather() async {
        await MainActor.run { isLoading = true }

        checkIfFlightIsActive()

        async let departureTask: () = fetchDepartureCoordinate()
        async let arrivalTask: () = fetchArrivalCoordinate()
        _ = await (departureTask, arrivalTask)

        await fetchLiveFlightDataIfActive()

        // Weather (arrival)
        if let arr = arrivalCoordinate {
            do {
                let weather = try await weatherService.fetchWeather(for: arr)
                await MainActor.run { self.arrivalWeather = weather }
            } catch {
                await MainActor.run { self.weatherError = "Unable to load weather." }
            }
        }

        await MainActor.run {
            if let dep = departureCoordinate, let arr = arrivalCoordinate {
                var centerLat = (dep.latitude + arr.latitude) / 2
                var centerLon = (dep.longitude + arr.longitude) / 2

                if let plane = planeCoordinate {
                    centerLat = (dep.latitude + arr.latitude + plane.latitude) / 3
                    centerLon = (dep.longitude + arr.longitude + plane.longitude) / 3
                }

                var latDelta = abs(dep.latitude - arr.latitude) * 1.5
                var lonDelta = abs(dep.longitude - arr.longitude) * 1.5

                latDelta = min(max(latDelta, 10), 170)
                lonDelta = min(max(lonDelta, 10), 350)

                withAnimation(.easeInOut(duration: 0.35)) {
                    mapRegion = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                        span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
                    )
                }
            }
            isLoading = false
        }
    }

    func checkIfFlightIsActive() {
        guard let (departure, arrival) = parseFlightTimes() else {
            isFlightActive = false
            return
        }
        let now = Date()
        isFlightActive = now >= departure && now <= arrival
    }

    func parseFlightTimes() -> (departure: Date, arrival: Date)? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        guard let depTime = dateFormatter.date(from: task.departureTime),
              let arrTime = dateFormatter.date(from: task.arrivalTime) else {
            return nil
        }

        let calendar = Calendar.current
        let depComponents = calendar.dateComponents([.hour, .minute], from: depTime)
        let arrComponents = calendar.dateComponents([.hour, .minute], from: arrTime)

        guard let departure = calendar.date(bySettingHour: depComponents.hour ?? 0,
                                            minute: depComponents.minute ?? 0,
                                            second: 0,
                                            of: task.dueDate) else { return nil }

        var arrivalBaseDate = task.dueDate
        if task.arrivalDayOffset > 0 {
            arrivalBaseDate = calendar.date(byAdding: .day,
                                            value: task.arrivalDayOffset,
                                            to: task.dueDate) ?? task.dueDate
        }

        guard let arrival = calendar.date(bySettingHour: arrComponents.hour ?? 0,
                                          minute: arrComponents.minute ?? 0,
                                          second: 0,
                                          of: arrivalBaseDate) else { return nil }

        return (departure, arrival)
    }

    // Try to fetch real GPS; fall back to interpolation
    func fetchLiveFlightDataIfActive() async {
        guard isFlightActive else { return }

        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let flightDate = dateFormatter.string(from: task.dueDate)

            if let liveData = try await flightService.fetchLiveFlightData(
                flightNumber: task.flightNumber,
                flightDate: flightDate
            ) {
                await MainActor.run {
                    self.liveFlightData = liveData

                    if let live = liveData.live,
                       let lat = live.latitude,
                       let lon = live.longitude {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            self.planeCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        }
                    } else {
                        calculatePlanePosition()
                    }
                }
            } else {
                await MainActor.run { calculatePlanePosition() }
            }
        } catch {
            await MainActor.run { calculatePlanePosition() }
        }
    }

    // Free-tier fallback: linear interpolation by elapsed time
    func calculatePlanePosition() {
        guard let (departure, arrival) = parseFlightTimes(),
              let depCoord = departureCoordinate,
              let arrCoord = arrivalCoordinate else {
            return
        }

        let now = Date()
        let totalDuration = arrival.timeIntervalSince(departure)
        let elapsed = now.timeIntervalSince(departure)
        let progress = elapsed / totalDuration

        let clamped = min(max(progress, 0.0), 1.0)
        let lat = depCoord.latitude + (arrCoord.latitude - depCoord.latitude) * clamped
        let lon = depCoord.longitude + (arrCoord.longitude - depCoord.longitude) * clamped

        withAnimation(.easeInOut(duration: 0.35)) {
            planeCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    func fetchDepartureCoordinate() async {
        if let coordinate = AirportCoordinates.getCoordinate(for: task.departure) {
            await MainActor.run { self.departureCoordinate = coordinate }
        }
    }

    func fetchArrivalCoordinate() async {
        if let coordinate = AirportCoordinates.getCoordinate(for: task.arrival) {
            await MainActor.run { self.arrivalCoordinate = coordinate }
        }
    }
}

// MARK: - Map Representable

struct FlightMapView: UIViewRepresentable {
    let departureCoordinate: CLLocationCoordinate2D?
    let arrivalCoordinate: CLLocationCoordinate2D?
    let planeCoordinate: CLLocationCoordinate2D?
    let departureCode: String
    let arrivalCode: String
    let isActive: Bool
    let liveData: FlightSearchResult.LiveInfo?
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        if #available(iOS 17.0, *) {
            let cfg = MKStandardMapConfiguration(elevationStyle: .realistic, emphasisStyle: .muted)
            cfg.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = cfg
        } else {
            mapView.pointOfInterestFilter = .excludingAll
        }

        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Departure pin
        if let dep = departureCoordinate {
            let depAnnotation = MKPointAnnotation()
            depAnnotation.coordinate = dep
            if let airport = AirportCoordinates.getAirport(for: departureCode) {
                depAnnotation.title = "\(departureCode) - \(airport.name)"
                depAnnotation.subtitle = "Departure"
            } else {
                depAnnotation.title = departureCode
                depAnnotation.subtitle = "Departure"
            }
            mapView.addAnnotation(depAnnotation)
        }

        // Arrival pin
        if let arr = arrivalCoordinate {
            let arrAnnotation = MKPointAnnotation()
            arrAnnotation.coordinate = arr
            if let airport = AirportCoordinates.getAirport(for: arrivalCode) {
                arrAnnotation.title = "\(arrivalCode) - \(airport.name)"
                arrAnnotation.subtitle = "Arrival"
            } else {
                arrAnnotation.title = arrivalCode
                arrAnnotation.subtitle = "Arrival"
            }
            mapView.addAnnotation(arrAnnotation)
        }

        // Live plane pin
        if let plane = planeCoordinate {
            let planeAnnotation = MKPointAnnotation()
            planeAnnotation.coordinate = plane
            planeAnnotation.title = "✈️ LIVE"
            planeAnnotation.subtitle = "In Flight"
            mapView.addAnnotation(planeAnnotation)
        }

        // Flight path
        if let dep = departureCoordinate, let arr = arrivalCoordinate {
            if let plane = planeCoordinate, isActive {
                let completedPath = MKPolyline(coordinates: [dep, plane], count: 2)
                mapView.addOverlay(completedPath, level: .aboveRoads)

                let remainingPath = MKPolyline(coordinates: [plane, arr], count: 2)
                mapView.addOverlay(remainingPath, level: .aboveRoads)
            } else {
                let fullPath = MKPolyline(coordinates: [dep, arr], count: 2)
                mapView.addOverlay(fullPath, level: .aboveRoads)
            }

            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isActive: isActive)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let isActive: Bool

        init(isActive: Bool) {
            self.isActive = isActive
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "FlightPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.displayPriority = .required
            } else {
                annotationView?.annotation = annotation
            }

            if let subtitle = annotation.subtitle ?? nil {
                if subtitle.contains("In Flight") {
                    annotationView?.markerTintColor = .systemOrange
                    annotationView?.glyphImage = UIImage(systemName: "airplane.circle.fill")
                    annotationView?.glyphTintColor = .white
                } else if subtitle.contains("Departure") {
                    annotationView?.markerTintColor = .systemBlue
                    annotationView?.glyphImage = UIImage(systemName: "airplane.departure")
                } else if subtitle.contains("Arrival") {
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "airplane.arrival")
                }
            }

            return annotationView
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: polyline)
            r.lineJoin = .round
            r.lineCap = .round

            if polyline.pointCount >= 2 {
                let points = polyline.points()
                let first = points[0].coordinate
                let second = points[1].coordinate
                let distance = abs(first.latitude - second.latitude) + abs(first.longitude - second.longitude)
                let isCompletedPath = distance < 50 // heuristic based on your split overlays

                if isActive && isCompletedPath {
                    r.strokeColor = UIColor.systemGreen.withAlphaComponent(0.85)
                    r.lineWidth = 5
                } else {
                    r.strokeColor = UIColor.systemBlue.withAlphaComponent(0.55)
                    r.lineWidth = 4
                    r.lineDashPattern = [10, 6]
                }
            } else {
                r.strokeColor = UIColor.systemBlue.withAlphaComponent(0.55)
                r.lineWidth = 4
            }

            return r
        }
    }
}

// MARK: - Polished Bottom Sheet

struct FlightDetailBottomSheet: View {
    let task: FlightTask
    let isFlightActive: Bool
    let arrivalWeather: WeatherResponse?
    let weatherError: String
    let routeDistanceKm: Double?
    let scheduledDurationHours: Double?

    var body: some View {
        VStack(spacing: 14) {
            // Handle
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // HERO HEADER
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.blue.opacity(0.25), .purple.opacity(0.25)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15)))
                    Image(task.airline.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                }
                .frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(task.flightNumber)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .monospacedDigit()
                        StatusPill(text: isFlightActive ? "In Flight" : "Scheduled",
                                   tint: isFlightActive ? .green : .blue)
                    }
                    Text("\(task.airline.rawValue)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .accessibilityLabel("\(task.flightNumber), \(isFlightActive ? "In Flight" : "Scheduled") with \(task.airline.rawValue)")

            // ROUTE CARD
            GlassCard {
                RouteRow(departure: task.departure,
                         departureTime: task.departureTime,
                         arrival: task.arrival,
                         arrivalTime: task.arrivalTime)
            }

            // WEATHER
            if let w = arrivalWeather {
                GlassCard { WeatherSummaryView(weather: w) }
                    .transition(.opacity)
            } else if !weatherError.isEmpty {
                GlassCard {
                    HStack {
                        Image(systemName: "cloud.drizzle")
                        Text(weatherError)
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            // STATS GRID
            if let km = routeDistanceKm, let hours = scheduledDurationHours {
                GlassCard {
                    StatGrid(items: [
                        .init(icon: "ruler", label: "Distance", value: "\(Int(km)) km"),
                        .init(icon: "clock", label: "Duration", value: RouteStatsView.formatHours(hours))
                    ])
                }
                .transition(.opacity)
            }

            // Quick Actions (optional hooks)
            HStack(spacing: 10) {
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    // Connect to your share logic if desired
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)
                    // Hook into notification scheduling (your Notification Extension)
                } label: {
                    Label("Remind Me", systemImage: "bell.badge")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -6)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Existing Components (kept) + Polish Helpers

struct FlightInfoCard: View {
    let task: FlightTask

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(task.airline.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.08), radius: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.airline.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(task.flightNumber)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DEPARTURE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(task.departure)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(task.departureTime)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundColor(.gray)

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("ARRIVAL")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(task.arrival)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(task.arrivalTime)
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
    }
}

struct WeatherSummaryView: View {
    let weather: WeatherResponse

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: weather.current.weather_icons.first ?? "cloud")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Arrival Weather — \(weather.location.name), \(weather.location.country)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(weather.current.weather_descriptions.first ?? "—")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(Int(weather.current.temperature))°C")
                    .font(.headline)
                    .monospacedDigit()
                Text("Wind \(weather.current.wind_speed) km/h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct RouteStatsView: View {
    let distanceKm: Double
    let durationHours: Double

    var body: some View {
        HStack {
            Label("Distance", systemImage: "ruler")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(String(format: "%.0f", distanceKm)) km")
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()

            Spacer()

            Label("Duration", systemImage: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(Self.formatHours(durationHours))
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // Exposed (not private) so StatGrid can reuse
    static func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}

// MARK: - UI Helpers

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Glass card wrapper
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12))
            )
            .padding(.horizontal, 16)
    }
}

// Status pill used in header
struct StatusPill: View {
    let text: String
    let tint: Color
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .foregroundStyle(tint.opacity(0.95))
            .background(tint.opacity(0.15), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 0.8))
    }
}

// Route row used inside a glass card
struct RouteRow: View {
    let departure: String
    let departureTime: String
    let arrival: String
    let arrivalTime: String

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(departure)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text(departureTime)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.blue)
            }

            Spacer(minLength: 10)

            VStack(spacing: 2) {
                Image(systemName: "airplane.departure")
                Capsule().frame(width: 42, height: 2).opacity(0.25)
                Image(systemName: "airplane.arrival")
            }
            .foregroundStyle(.secondary)

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 6) {
                Text(arrival)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text(arrivalTime)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.green)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(departure) at \(departureTime) to \(arrival) at \(arrivalTime)")
    }
}

// Simple stats grid to show distance/duration
struct StatGridItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
}

struct StatGrid: View {
    let items: [StatGridItem]
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items) { item in
                HStack {
                    Image(systemName: item.icon)
                        .imageScale(.medium)
                        .frame(width: 22)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label).font(.caption).foregroundStyle(.secondary)
                        Text(item.value).font(.subheadline.weight(.semibold)).monospacedDigit()
                    }
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
            }
        }
    }
}
