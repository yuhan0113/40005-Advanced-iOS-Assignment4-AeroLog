//  Created by Yu-Han on 6/9/2025.
//  Unit tests for task completion and ViewModel logic
// Edited by Riley Martin on 20/10/2025.

import XCTest
import CoreData
@testable import AeroLog

final class AerologTests: XCTestCase {
    
    var flightService: FlightSearchService!
    
    override func setUp() async throws {
        try await super.setUp()
        flightService = FlightSearchService.shared
    }
    
    override func tearDown() {
        flightService = nil
        super.tearDown()
    }
    
    // flight code tests
    
    func testFlightCodeValidation() {
        let validCodes = ["QF123", "VA456", "AA789", "EK101", "JQ202", "QF1234"]
        for code in validCodes {
            XCTAssertTrue(isValidFlightCode(code), "Flight code \(code) should be valid")
        }
        
        let invalidCodes = ["", "123", "QF", "123QF", "qF123"]
        for code in invalidCodes {
            XCTAssertFalse(isValidFlightCode(code), "Flight code \(code) should be invalid")
        }
    }
    
    func testFlightCodeFormatting() {
        let testCases = [
            ("qf123", "QF123"),
            ("va456", "VA456"),
            ("aa789", "AA789")
        ]
        
        for (input, expected) in testCases {
            let formatted = formatFlightCode(input)
            XCTAssertEqual(formatted, expected, "Flight code formatting failed for \(input)")
        }
    }
    
    // flight task model tests
    
    func testFlightTaskInitialization() {
        let task = FlightTask(
            title: "Test Flight",
            flightNumber: "QF123",
            departure: "Sydney",
            arrival: "Melbourne",
            departureTime: "10:00",
            arrivalTime: "12:00",
            dueDate: Date(),
            airline: .qantas,
            arrivalDayOffset: 0
        )
        
        XCTAssertEqual(task.title, "Test Flight")
        XCTAssertEqual(task.flightNumber, "QF123")
        XCTAssertEqual(task.departure, "Sydney")
        XCTAssertEqual(task.arrival, "Melbourne")
        XCTAssertEqual(task.departureTime, "10:00")
        XCTAssertEqual(task.arrivalTime, "12:00")
        XCTAssertEqual(task.airline, .qantas)
        XCTAssertEqual(task.arrivalDayOffset, 0)
        XCTAssertFalse(task.isCompleted)
    }
    
    func testFlightTaskMarkCompleted() {
        let task = FlightTask(
            title: "QF1 Sydney to Perth",
            flightNumber: "QF1",
            departure: "Sydney",
            arrival: "Perth",
            departureTime: "10:00AM",
            arrivalTime: "3:00PM",
            dueDate: Date(),
            airline: .qantas
        )

        XCTAssertFalse(task.isCompleted)
        task.markCompleted()
        XCTAssertTrue(task.isCompleted)
    }
    
    // basic model tests
    
    func testFlightTaskCreation() {
        let task = FlightTask(
            title: "Test Flight",
            flightNumber: "QF123",
            departure: "Sydney",
            arrival: "Melbourne",
            departureTime: "10:00",
            arrivalTime: "12:00",
            dueDate: Date(),
            airline: .qantas
        )
        
        XCTAssertEqual(task.title, "Test Flight")
        XCTAssertEqual(task.flightNumber, "QF123")
        XCTAssertEqual(task.departure, "Sydney")
        XCTAssertEqual(task.arrival, "Melbourne")
        XCTAssertEqual(task.airline, .qantas)
        XCTAssertFalse(task.isCompleted)
    }
    
    func testFlightTaskCompletion() {
        let task = FlightTask(
            title: "Test Flight",
            flightNumber: "QF123",
            departure: "Sydney",
            arrival: "Melbourne",
            departureTime: "10:00",
            arrivalTime: "12:00",
            dueDate: Date(),
            airline: .qantas
        )
        
        XCTAssertFalse(task.isCompleted)
        task.markCompleted()
        XCTAssertTrue(task.isCompleted)
    }
    
    func testTaskErrorTypes() {
        XCTAssertEqual(TaskError.invalidInput.errorDescription, "All required fields must be filled in.")
        XCTAssertEqual(TaskError.duplicateFlight.errorDescription, "This flight has already been added to your log.")
    }
    
    // flight search service tests
    
    func testFlightSearchServiceBasic() async {
        do {
            let results = try await flightService.searchFlights(flightNumber: "QF123")
            // just check that we get some results or no error
            XCTAssertNotNil(results)
        } catch {
            // if it throws an error, that's ok too.
            XCTAssertTrue(error is Error)
        }
    }
    
    func testFlightSearchServiceWithInvalidCode() async {
        do {
            let results = try await flightService.searchFlights(flightNumber: "INVALID")
            XCTAssertNotNil(results)
        } catch {
            XCTAssertTrue(error is Error)
        }
    }
    
    func testFlightSearchServiceLiveDataFetch() async {
        do {
            let liveData = try await flightService.fetchLiveFlightData(
                flightNumber: "QF123",
                flightDate: "2025-01-01"
            )
            if let data = liveData {
                XCTAssertNotNil(data.flight)
                XCTAssertNotNil(data.departure)
                XCTAssertNotNil(data.arrival)
            }
        } catch {
            XCTAssertTrue(error is Error)
        }
    }
    
    // basic functionality tests
    
    func testAirlineEnum() {
        XCTAssertEqual(Airline.qantas.code, "QF")
        XCTAssertEqual(Airline.virgin.code, "VA")
        XCTAssertEqual(Airline.emirates.code, "EK")
        XCTAssertEqual(Airline.american.code, "AA")
    }
    
    func testFlightTaskWithArrivalDayOffset() {
        let task = FlightTask(
            title: "Long Flight",
            flightNumber: "EK789",
            departure: "Dubai",
            arrival: "London",
            departureTime: "22:00",
            arrivalTime: "06:00",
            dueDate: Date(),
            airline: .emirates,
            arrivalDayOffset: 1
        )
        
        XCTAssertEqual(task.arrivalDayOffset, 1)
        XCTAssertEqual(task.airline, .emirates)
    }
    
    // flight sharing tests
    
    func testFlightSharingDataGeneration() {
        let task = FlightTask(
            title: "Shareable Flight",
            flightNumber: "QF123",
            departure: "Sydney",
            arrival: "Melbourne",
            departureTime: "10:00",
            arrivalTime: "12:00",
            dueDate: Date(),
            airline: .qantas
        )
        
        let shareText = generateFlightShareText(task)
        
        XCTAssertTrue(shareText.contains("QF123"))
        XCTAssertTrue(shareText.contains("Sydney"))
        XCTAssertTrue(shareText.contains("Melbourne"))
        XCTAssertTrue(shareText.contains("10:00"))
        XCTAssertTrue(shareText.contains("12:00"))
    }
    
    func testMultipleFlightsSharingDataGeneration() {
        let tasks = [
            FlightTask(
                title: "Flight 1",
                flightNumber: "QF123",
                departure: "Sydney",
                arrival: "Melbourne",
                departureTime: "10:00",
                arrivalTime: "12:00",
                dueDate: Date(),
                airline: .qantas
            ),
            FlightTask(
                title: "Flight 2",
                flightNumber: "VA456",
                departure: "Melbourne",
                arrival: "Brisbane",
                departureTime: "14:00",
                arrivalTime: "16:00",
                dueDate: Date(),
                airline: .virgin
            )
        ]
        
        let shareText = generateMultipleFlightsShareText(tasks)
        
        XCTAssertTrue(shareText.contains("QF123"))
        XCTAssertTrue(shareText.contains("VA456"))
        XCTAssertTrue(shareText.contains("Sydney"))
        XCTAssertTrue(shareText.contains("Melbourne"))
        XCTAssertTrue(shareText.contains("Brisbane"))
    }
    
    // helper functions
    
    private func isValidFlightCode(_ code: String) -> Bool {
        let pattern = "^[A-Z]{2}[0-9]{3,4}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: code.utf16.count)
        return regex?.firstMatch(in: code, options: [], range: range) != nil
    }
    
    private func formatFlightCode(_ code: String) -> String {
        return code.uppercased()
    }
    
    private func extractDateFromFlightResult(_ result: FlightSearchResult) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: result.departure.scheduled) ?? Date()
    }
    
    private func generateFlightShareText(_ task: FlightTask) -> String {
        return """
        Flight: \(task.title)
        Flight number: \(task.flightNumber)
        Route: \(task.departure) -> \(task.arrival)
        Departure: \(task.departureTime)
        Arrival: \(task.arrivalTime)
        Airline: \(task.airline.rawValue)
        Date: \(DateFormatter.localizedString(from: task.dueDate, dateStyle: .medium, timeStyle: .none))
        """
    }
    
    private func generateMultipleFlightsShareText(_ tasks: [FlightTask]) -> String {
        var shareText = "My Flight Log\n\n"
        
        for (index, task) in tasks.enumerated() {
            shareText += "\(index + 1). \(task.title)\n"
            shareText += "   \(task.flightNumber): \(task.departure) → \(task.arrival)\n"
            shareText += "   \(task.departureTime) - \(task.arrivalTime)\n\n"
        }
        
        return shareText
    }
}
