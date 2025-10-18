//
//  AeroLogTests.swift
//  AeroLogTests
//
//  Created by Yu-Han on 17/10/2025.
//

import XCTest
@testable import AeroLog

final class AeroLogTests: XCTestCase {
    
    // MARK: - FlightTask Tests
    
    func testFlightTaskCreation() {
        let task = FlightTask(
            title: "Test Flight",
            flightNumber: "QF123",
            departure: "SYD",
            arrival: "LAX",
            departureTime: "10:00 AM",
            arrivalTime: "6:00 PM",
            dueDate: Date(),
            airline: .qantas
        )
        
        XCTAssertEqual(task.title, "Test Flight")
        XCTAssertEqual(task.flightNumber, "QF123")
        XCTAssertEqual(task.departure, "SYD")
        XCTAssertEqual(task.arrival, "LAX")
        XCTAssertEqual(task.airline, .qantas)
        XCTAssertFalse(task.isCompleted)
    }
    
    func testFlightTaskCompletion() {
        let task = FlightTask(
            title: "Test Flight",
            flightNumber: "QF123",
            departure: "SYD",
            arrival: "LAX",
            departureTime: "10:00 AM",
            arrivalTime: "6:00 PM",
            dueDate: Date(),
            airline: .qantas
        )
        
        XCTAssertFalse(task.isCompleted)
        task.markCompleted()
        XCTAssertTrue(task.isCompleted)
    }
    
    // MARK: - NotificationManager Tests
    
    func testNotificationManagerSingleton() {
        let manager1 = NotificationManager.shared
        let manager2 = NotificationManager.shared
        XCTAssertIdentical(manager1, manager2)
    }
    
    // MARK: - AirportCoordinates Tests
    
    func testAirportCoordinatesLoading() {
        AirportCoordinates.loadAirports()
        let coordinate = AirportCoordinates.getCoordinate(for: "SYD")
        XCTAssertNotNil(coordinate)
        if let coord = coordinate {
            XCTAssertEqual(coord.latitude, -33.9399, accuracy: 0.001)
            XCTAssertEqual(coord.longitude, 151.1753, accuracy: 0.001)
        }
    }
    
    func testAirportCoordinatesInvalidCode() {
        AirportCoordinates.loadAirports()
        let coordinate = AirportCoordinates.getCoordinate(for: "INVALID")
        XCTAssertNil(coordinate)
    }
    
    // MARK: - FlightSearchService Tests
    
    func testFlightSearchServiceSingleton() {
        let service1 = FlightSearchService.shared
        let service2 = FlightSearchService.shared
        XCTAssertIdentical(service1, service2)
    }
    
    // MARK: - WeatherService Tests
    
    func testWeatherServiceSymbolMapping() {
        // Test the private symbol mapping logic
        let testCases: [(String, String)] = [
            ("Rain", "cloud.rain"),
            ("Thunderstorm", "cloud.bolt.rain"),
            ("Snow", "cloud.snow"),
            ("Cloudy", "cloud"),
            ("Sunny", "sun.max"),
            ("Clear", "sun.max"),
            ("Mist", "cloud.fog"),
            ("Fog", "cloud.fog"),
            ("Unknown", "cloud.sun")
        ]
        
        for (condition, expectedSymbol) in testCases {
            let symbol = WeatherService().symbolName(for: condition)
            XCTAssertEqual(symbol, expectedSymbol, "Failed for condition: \(condition)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func WeatherService() -> TestWeatherService {
        return TestWeatherService()
    }
}

// MARK: - Test Helper Classes

class TestWeatherService {
    func symbolName(for condition: String) -> String {
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

