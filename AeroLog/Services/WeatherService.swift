//
//  WeatherService.swift
//  AeroLog
//
//  Created by Yu-Han on 07/10/2025
//
//  Edited by Riley Martin on 13/10/2025
//

import Foundation
import CoreLocation

// MARK: - Weather Response Models

struct WeatherResponse {
    let location: LocationInfo
    let current: CurrentWeather
}

struct LocationInfo {
    let name: String
    let country: String
    let localtime: String
}

struct CurrentWeather {
    let temperature: Double
    let weather_descriptions: [String]
    let weather_icons: [String]
    let wind_speed: Int
    let humidity: Int
    let visibility: Int
}

// MARK: - WeatherService

class WeatherService {
    private let geocoder = CLGeocoder()

    func fetchWeather(for location: CLLocationCoordinate2D) async throws -> WeatherResponse {
        let apiKey = Secrets.weatherAPIKey
        guard !apiKey.isEmpty else { throw NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing Weather API key"]) }

        // Reverse geocode for display names (non-fatal if fails)
        var locationName = "Unknown"
        var country = "Unknown"
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
            if let placemark = placemarks.first {
                locationName = placemark.locality ?? placemark.name ?? locationName
                country = placemark.country ?? country
            }
        } catch {
            // ignore
        }

        let urlString = "https://api.weatherapi.com/v1/current.json?key=\(apiKey)&q=\(location.latitude),\(location.longitude)&aqi=no"
        guard let url = URL(string: urlString) else { throw NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "WeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Weather server error"])
        }

        struct APIResponse: Decodable {
            struct Current: Decodable {
                let temp_c: Double
                let wind_kph: Double
                let humidity: Int
                let vis_km: Double
                let condition: Condition
                struct Condition: Decodable { let text: String }
            }
            let current: Current
            struct Location: Decodable { let localtime: String }
            let location: Location
        }

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)

        let responseModel = WeatherResponse(
            location: LocationInfo(name: locationName, country: country, localtime: decoded.location.localtime),
            current: CurrentWeather(
                temperature: decoded.current.temp_c,
                weather_descriptions: [decoded.current.condition.text],
                weather_icons: [Self.symbolName(for: decoded.current.condition.text)],
                wind_speed: Int(decoded.current.wind_kph),
                humidity: decoded.current.humidity,
                visibility: Int(decoded.current.vis_km)
            )
        )

        return responseModel
    }

    private static func symbolName(for condition: String) -> String {
        let text = condition.lowercased()
        if text.contains("rain") { return "cloud.rain" }
        if text.contains("thunder") { return "cloud.bolt.rain" }
        if text.contains("snow") { return "cloud.snow" }
        if text.contains("cloud") || text.contains("overcast") { return "cloud" }
        if text.contains("sunny") || text.contains("clear") { return "sun.max" }
        if text.contains("mist") || text.contains("fog") { return "cloud.fog" }
        return "cloud.sun"
    }
}

