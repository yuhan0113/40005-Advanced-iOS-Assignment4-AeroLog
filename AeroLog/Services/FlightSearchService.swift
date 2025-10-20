//
//  FlightSearchService.swift
//  AeroLog
//
//  Created by Riley Martin on 10/13/2025.
//

import Foundation

enum FlightDataSource {
    case mock
    case aviationStackAPI
}

let USE_MOCK_DATA: FlightDataSource = .aviationStackAPI

struct FlightSearchResult: Identifiable, Codable {
    let id = UUID()
    let flightDate: String
    let flightStatus: String
    let departure: DepartureInfo
    let arrival: ArrivalInfo
    let airline: AirlineInfo
    let flight: FlightInfo
    let live: LiveInfo?
    
    struct DepartureInfo: Codable {
        let airport: String
        let timezone: String?
        let iata: String?
        let icao: String?
        let terminal: String?
        let gate: String?
        let delay: Int?
        let scheduled: String
        let estimated: String?
        let actual: String?
    }
    
    struct ArrivalInfo: Codable {
        let airport: String
        let timezone: String?
        let iata: String?
        let icao: String?
        let terminal: String?
        let gate: String?
        let baggage: String?
        let delay: Int?
        let scheduled: String
        let estimated: String?
        let actual: String?
    }
    
    struct AirlineInfo: Codable {
        let name: String
        let iata: String?
        let icao: String?
    }
    
    struct FlightInfo: Codable {
        let number: String
        let iata: String?
        let icao: String?
    }
    
    struct LiveInfo: Codable {
        let updated: String?
        let latitude: Double?
        let longitude: Double?
        let altitude: Double?
        let direction: Double?
        let speed_horizontal: Double?
        let speed_vertical: Double?
        let is_ground: Bool?
    }
    
    enum CodingKeys: String, CodingKey {
        case flightDate = "flight_date"
        case flightStatus = "flight_status"
        case departure, arrival, airline, flight, live
    }
}

struct FlightSearchResponse: Codable {
    let pagination: Pagination?
    let data: [FlightSearchResult]
    
    struct Pagination: Codable {
        let limit: Int
        let offset: Int
        let count: Int
        let total: Int
    }
}

class FlightSearchService {
    static let shared = FlightSearchService()
    
    private let baseURL = "https://api.aviationstack.com/v1/flights"
    
    func searchFlights(flightNumber: String) async throws -> [FlightSearchResult] {
        if USE_MOCK_DATA == .mock {
            return try await searchFlightsMock(flightNumber: flightNumber)
        } else {
            // Try API first, fallback to mock if no results
            do {
                let apiResults = try await searchFlightsAPI(flightNumber: flightNumber)
                if !apiResults.isEmpty {
                    return apiResults
                }
            } catch {
                print("API search failed: \(error)")
            }
            
            // Fallback to mock data for demo purposes
            print("No API results found, using mock data for: \(flightNumber)")
            return try await searchFlightsMock(flightNumber: flightNumber)
        }
    }
    
    private func searchFlightsMock(flightNumber: String) async throws -> [FlightSearchResult] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let flightCode = flightNumber.uppercased()
        let airlineCode = String(flightCode.prefix(2))
        let number = String(flightCode.dropFirst(2))
        
        let airlineNames: [String: String] = [
            "QF": "Qantas Airways",
            "VA": "Virgin Australia",
            "AA": "American Airlines",
            "CA": "Air Canada",
            "CI": "China Airlines",
            "CX": "Cathay Pacific",
            "EK": "Emirates",
            "JQ": "Jetstar Airways"
        ]
        
        let routes: [String: (dep: String, depIATA: String, arr: String, arrIATA: String)] = [
            "QF": ("Sydney Kingsford Smith", "SYD", "Los Angeles Intl", "LAX"),
            "VA": ("Melbourne", "MEL", "Brisbane", "BNE"),
            "AA": ("Dallas/Fort Worth", "DFW", "New York JFK", "JFK"),
            "CA": ("Toronto Pearson", "YYZ", "Vancouver Intl", "YVR"),
            "CI": ("Taipei Taoyuan", "TPE", "Tokyo Narita", "NRT"),
            "CX": ("Hong Kong Intl", "HKG", "Singapore Changi", "SIN"),
            "EK": ("Dubai Intl", "DXB", "London Heathrow", "LHR"),
            "JQ": ("Sydney", "SYD", "Gold Coast", "OOL")
        ]
        
        guard let airlineName = airlineNames[airlineCode],
              let route = routes[airlineCode] else {
            return []
        }
        
        var results: [FlightSearchResult] = []
        let statuses = ["active", "scheduled", "scheduled", "scheduled", "scheduled", "scheduled", "scheduled"]
        
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let flightDate = dateFormatter.string(from: date)
            
            var departureTime: Date
            if dayOffset == 0 {
                departureTime = Calendar.current.date(byAdding: .hour, value: -3, to: Date())!
            } else {
                departureTime = Calendar.current.date(bySettingHour: 14 + (dayOffset % 3), minute: 30, second: 0, of: date)!
            }
            let arrivalTime = Calendar.current.date(byAdding: .hour, value: 13, to: departureTime)!
            
            let iso8601Formatter = ISO8601DateFormatter()
            let depScheduled = iso8601Formatter.string(from: departureTime)
            let arrScheduled = iso8601Formatter.string(from: arrivalTime)
            
            let liveInfo: FlightSearchResult.LiveInfo?
            if dayOffset == 0 && statuses[dayOffset] == "active" {
                liveInfo = FlightSearchResult.LiveInfo(
                    updated: iso8601Formatter.string(from: Date()),
                    latitude: -20.0,
                    longitude: 160.0,
                    altitude: 10668.0,
                    direction: 270.0,
                    speed_horizontal: 850.0,
                    speed_vertical: 0.0,
                    is_ground: false
                )
            } else {
                liveInfo = nil
            }
            
            let result = FlightSearchResult(
                flightDate: flightDate,
                flightStatus: statuses[dayOffset],
                departure: FlightSearchResult.DepartureInfo(
                    airport: route.dep,
                    timezone: "UTC",
                    iata: route.depIATA,
                    icao: nil,
                    terminal: dayOffset % 2 == 0 ? "1" : "2",
                    gate: "A\(10 + dayOffset)",
                    delay: dayOffset == 3 ? 15 : nil,
                    scheduled: depScheduled,
                    estimated: nil,
                    actual: nil
                ),
                arrival: FlightSearchResult.ArrivalInfo(
                    airport: route.arr,
                    timezone: "UTC",
                    iata: route.arrIATA,
                    icao: nil,
                    terminal: "B",
                    gate: "B\(20 + dayOffset)",
                    baggage: "Carousel \(dayOffset + 1)",
                    delay: nil,
                    scheduled: arrScheduled,
                    estimated: nil,
                    actual: nil
                ),
                airline: FlightSearchResult.AirlineInfo(
                    name: airlineName,
                    iata: airlineCode,
                    icao: nil
                ),
                flight: FlightSearchResult.FlightInfo(
                    number: number,
                    iata: flightCode,
                    icao: nil
                ),
                live: liveInfo
            )
            
            results.append(result)
        }
        
        return results
    }
    
    private func searchFlightsAPI(flightNumber: String) async throws -> [FlightSearchResult] {
        let apiKey = Secrets.flightAPIKey
        
        guard !apiKey.isEmpty else {
            throw NSError(domain: "FlightSearchService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not configured"])
        }
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "flight_iata", value: flightNumber.uppercased()),
            URLQueryItem(name: "limit", value: "5")
        ]
        
        guard let url = components?.url else {
            throw NSError(domain: "FlightSearchService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FlightSearchService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FlightSearchService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        let searchResponse = try JSONDecoder().decode(FlightSearchResponse.self, from: data)
        
        guard let firstFlight = searchResponse.data.first else {
            return []
        }
        
        // generate future flights since free api tier doesn't give us that
        var expandedResults: [FlightSearchResult] = []
        
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let newFlightDate = dateFormatter.string(from: date)
            
            let iso8601Formatter = ISO8601DateFormatter()
            let originalDepDate = iso8601Formatter.date(from: firstFlight.departure.scheduled) ?? Date()
            let originalArrDate = iso8601Formatter.date(from: firstFlight.arrival.scheduled) ?? Date()
            
            let newDepDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: originalDepDate)!
            let newArrDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: originalArrDate)!
            
            let newDepScheduled = iso8601Formatter.string(from: newDepDate)
            let newArrScheduled = iso8601Formatter.string(from: newArrDate)
            
            let newResult = FlightSearchResult(
                flightDate: newFlightDate,
                flightStatus: dayOffset == 0 ? firstFlight.flightStatus : "scheduled",
                departure: FlightSearchResult.DepartureInfo(
                    airport: firstFlight.departure.airport,
                    timezone: firstFlight.departure.timezone,
                    iata: firstFlight.departure.iata,
                    icao: firstFlight.departure.icao,
                    terminal: firstFlight.departure.terminal,
                    gate: firstFlight.departure.gate,
                    delay: dayOffset == 0 ? firstFlight.departure.delay : nil,
                    scheduled: newDepScheduled,
                    estimated: nil,
                    actual: nil
                ),
                arrival: FlightSearchResult.ArrivalInfo(
                    airport: firstFlight.arrival.airport,
                    timezone: firstFlight.arrival.timezone,
                    iata: firstFlight.arrival.iata,
                    icao: firstFlight.arrival.icao,
                    terminal: firstFlight.arrival.terminal,
                    gate: firstFlight.arrival.gate,
                    baggage: firstFlight.arrival.baggage,
                    delay: dayOffset == 0 ? firstFlight.arrival.delay : nil,
                    scheduled: newArrScheduled,
                    estimated: nil,
                    actual: nil
                ),
                airline: firstFlight.airline,
                flight: firstFlight.flight,
                live: dayOffset == 0 ? firstFlight.live : nil
            )
            
            expandedResults.append(newResult)
        }
        
        return expandedResults
    }
    
    func fetchLiveFlightData(flightNumber: String, flightDate: String) async throws -> FlightSearchResult? {
        let apiKey = Secrets.flightAPIKey
        
        guard !apiKey.isEmpty else {
            throw NSError(domain: "FlightSearchService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not configured"])
        }
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "flight_iata", value: flightNumber.uppercased())
        ]
        
        guard let url = components?.url else {
            throw NSError(domain: "FlightSearchService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FlightSearchService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FlightSearchService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        let searchResponse = try JSONDecoder().decode(FlightSearchResponse.self, from: data)
        
        // prefer flights with live gps data
        for flight in searchResponse.data {
            if flight.live != nil {
                return flight
            }
        }
        
        // fall back to any flight data even without gps
        if let anyFlight = searchResponse.data.first {
            return anyFlight
        }
        
        return nil
    }
}
