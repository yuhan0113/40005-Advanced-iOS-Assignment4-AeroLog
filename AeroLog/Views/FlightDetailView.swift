//
//  FlightDetailView.swift
//  AeroLog
//
//  Created by Yu-Han on 06/09/2025
//
//  Edited by Riley Martin on 13/10/2025
//  Edited by Yu-Han on 15/10/2025

import SwiftUI
import CoreLocation
import MapKit

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
            // Bottom gradient to improve legibility of the overlay card
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.3), Color.black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
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
            }
            
            if !isLoading {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        HStack {
                            Text(task.airline.rawValue)
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            StatusBadge(status: isFlightActive ? "Active" : "Scheduled")
                        }
                        FlightInfoCard(task: task)
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    if let weather = arrivalWeather {
                        WeatherSummaryView(weather: weather)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .transition(.opacity)
                    } else if !weatherError.isEmpty {
                        Text(weatherError)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if let km = routeDistanceKm, let hours = scheduledDurationHours {
                        RouteStatsView(distanceKm: km, durationHours: hours)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .transition(.opacity)
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(24, corners: [.allCorners])
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -5)
                .padding(.horizontal, 16)
                .padding(.bottom, 0)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await fetchLocationsAndWeather()
            }
        }
    }

    func fetchLocationsAndWeather() async {
        await MainActor.run {
            isLoading = true
        }
        
        checkIfFlightIsActive()
        
        async let departureTask: () = fetchDepartureCoordinate()
        async let arrivalTask: () = fetchArrivalCoordinate()
        
        await departureTask
        await arrivalTask
        
        await fetchLiveFlightDataIfActive()

        // Fetch arrival weather once we have arrival coordinate
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
                
                mapRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: MKCoordinateSpan(
                        latitudeDelta: latDelta,
                        longitudeDelta: lonDelta
                    )
                )
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
                                            of: task.dueDate) else {
            return nil
        }
        
        var arrivalBaseDate = task.dueDate
        if task.arrivalDayOffset > 0 {
            arrivalBaseDate = calendar.date(byAdding: .day, value: task.arrivalDayOffset, to: task.dueDate) ?? task.dueDate
        }
        
        guard let arrival = calendar.date(bySettingHour: arrComponents.hour ?? 0,
                                          minute: arrComponents.minute ?? 0,
                                          second: 0,
                                          of: arrivalBaseDate) else {
            return nil
        }
        
        return (departure, arrival)
    }
    
    // try to get real gps data from api, fall back to calculating it ourselves
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
                        self.planeCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    } else {
                        calculatePlanePosition()
                    }
                }
            } else {
                await MainActor.run {
                    calculatePlanePosition()
                }
            }
        } catch {
            await MainActor.run {
                calculatePlanePosition()
            }
        }
    }
    
    // since free api tier doesn't give gps coords, we just linearly interpolate
    // between departure and arrival based on how much time has passed
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
        
        let clampedProgress = min(max(progress, 0.0), 1.0)
        
        let lat = depCoord.latitude + (arrCoord.latitude - depCoord.latitude) * clampedProgress
        let lon = depCoord.longitude + (arrCoord.longitude - depCoord.longitude) * clampedProgress
        
        planeCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func fetchDepartureCoordinate() async {
        if let coordinate = AirportCoordinates.getCoordinate(for: task.departure) {
            await MainActor.run {
                self.departureCoordinate = coordinate
            }
        }
    }
    
    func fetchArrivalCoordinate() async {
        if let coordinate = AirportCoordinates.getCoordinate(for: task.arrival) {
            await MainActor.run {
                self.arrivalCoordinate = coordinate
            }
        }
    }
}

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
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
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
        
        if let plane = planeCoordinate {
            let planeAnnotation = MKPointAnnotation()
            planeAnnotation.coordinate = plane
            planeAnnotation.title = "✈️ LIVE"
            planeAnnotation.subtitle = "In Flight"
            mapView.addAnnotation(planeAnnotation)
        }
        
        // draw the flight path as a polyline
        // if plane is active, split into completed (green) and remaining (blue dashed)
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
            
            if let subtitle = annotation.subtitle, let subtitleText = subtitle {
                if subtitleText.contains("In Flight") {
                    annotationView?.markerTintColor = .systemOrange
                    annotationView?.glyphImage = UIImage(systemName: "airplane")
                } else if subtitleText.contains("Departure") {
                    annotationView?.markerTintColor = .systemBlue
                    annotationView?.glyphImage = UIImage(systemName: "airplane.departure")
                } else if subtitleText.contains("Arrival") {
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "airplane.arrival")
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                if polyline.pointCount >= 2 {
                    let points = polyline.points()
                    let firstCoord = points[0].coordinate
                    let secondCoord = points[1].coordinate
                    
                    let distance = abs(firstCoord.latitude - secondCoord.latitude) + abs(firstCoord.longitude - secondCoord.longitude)
                    let isCompletedPath = distance < 50
                    
                    if isActive && isCompletedPath {
                        renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.8)
                        renderer.lineWidth = 4
                    } else {
                        renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5)
                        renderer.lineWidth = 3
                        renderer.lineDashPattern = [10, 5]
                    }
                }
                
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

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
                Text("Wind \(weather.current.wind_speed) km/h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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

            Spacer()

            Label("Duration", systemImage: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(Self.formatHours(durationHours))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private static func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}

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
