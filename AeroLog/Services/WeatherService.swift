//
//  WeatherService.swift
//  AeroLog
//
//  Created by Yu-Han on 07/10/2025.
//
//  Edited by Riley Martin on 13/10/2025
//

import Foundation
import CoreLocation
import WeatherKit

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
    private let weatherService = WeatherKit.WeatherService()
    private let geocoder = CLGeocoder()

    func fetchWeather(for location: CLLocationCoordinate2D) async throws -> WeatherResponse {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        do {
            let weather = try await weatherService.weather(for: clLocation)
            let currentWeather = weather.currentWeather
            
            var locationName = "Unknown"
            var country = "Unknown"
            
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
                if let placemark = placemarks.first {
                    locationName = placemark.locality ?? placemark.name ?? "Unknown"
                    country = placemark.country ?? "Unknown"
                }
            } catch {
                //
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let localtime = dateFormatter.string(from: Date())
            
            let weatherDescription = currentWeather.condition.description
            let symbolName = currentWeather.symbolName
            
            let response = WeatherResponse(
                location: LocationInfo(
                    name: locationName,
                    country: country,
                    localtime: localtime
                ),
                current: CurrentWeather(
                    temperature: currentWeather.temperature.converted(to: .celsius).value,
                    weather_descriptions: [weatherDescription],
                    weather_icons: [symbolName],
                    wind_speed: Int(currentWeather.wind.speed.converted(to: .kilometersPerHour).value),
                    humidity: Int(currentWeather.humidity * 100),
                    visibility: Int(currentWeather.visibility.converted(to: .kilometers).value)
                )
            )
            
            return response
            
        } catch {
            throw error
        }
    }
}
