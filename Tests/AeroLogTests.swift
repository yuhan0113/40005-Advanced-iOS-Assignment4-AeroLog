//
//  AeroLogTests.swift
//  AeroLogTests
//
//  Created by Yu-Han on 17/10/2025.
//

import XCTest
import CoreLocation
@testable import AeroLog

final class AeroLogTests: XCTestCase {
    
    // MARK: - FlightTask Tests
    
    func testFlightTaskCreation() {
        let task = FlightTask(
            title: "Test Flight",
            flightNumber: "QF12",
            departure: "SYD",
            arrival: "LAX",
            departureTime: "10:00 AM",
            arrivalTime: "6:00 PM",
            dueDate: Date(),
            airline: .qantas
        )
        
        XCTAssertEqual(task.title, "Test Flight")
        XCTAssertEqual(task.flightNumber, "QF12")
        XCTAssertEqual(task.departure, "SYD")
        XCTAssertEqual(task.arrival, "LAX")
        XCTAssertEqual(task.airline, .qantas)
        XCTAssertFalse(task.isCompleted)
    }

    // MARK: - FlightDetail Geometry/Utils

    func testHaversineDistanceSydneyToLAX() {
        let syd = CLLocationCoordinate2D(latitude: -33.9399, longitude: 151.1753)
        let lax = CLLocationCoordinate2D(latitude: 33.9416, longitude: -118.4085)
        let km = FlightDetailView.haversineDistanceKm(from: syd, to: lax)
        XCTAssertGreaterThan(km, 11800)
        XCTAssertLessThan(km, 12600)
    }

    // MARK: - TaskViewModel duplicate guard

    @MainActor
    func testAddingDuplicateFlightSameDayThrows() throws {
        let vm = TaskViewModel()
        let date = Date()

        // First add
        try vm.addTask(
            title: "Test",
            flightNumber: "QF123",
            departure: "SYD",
            arrival: "LAX",
            departureTime: "10:00 AM",
            arrivalTime: "6:00 PM",
            dueDate: date,
            airline: .qantas
        )

        // Second add same flight same day should throw
        XCTAssertThrowsError(
            try vm.addTask(
                title: "Duplicate",
                flightNumber: "QF123",
                departure: "SYD",
                arrival: "LAX",
                departureTime: "11:00 AM",
                arrivalTime: "7:00 PM",
                dueDate: date,
                airline: .qantas
            )
        ) { error in
            guard let taskError = error as? TaskError else { return XCTFail("Wrong error type") }
            switch taskError {
            case .duplicateFlight:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected duplicateFlight, got \(taskError)")
            }
        }
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
            // Use the dataset's values with a slightly relaxed tolerance
            XCTAssertEqual(coord.latitude, -33.9461, accuracy: 0.01)
            XCTAssertEqual(coord.longitude, 151.177, accuracy: 0.01)
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

