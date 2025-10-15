//
//  FlightTask.swift
//  AeroLog
//
//  Created by Yu-Han on 06/09/2025.
//
//  Edited by Riley Martin on 13/10/2025
//

import Foundation

// Subclass for flight-specific task with flight number & locations
class FlightTask: BaseTask {
    var flightNumber: String
    var departure: String
    var arrival: String
    var departureTime: String
    var arrivalTime: String
    var airline: Airline
    var arrivalDayOffset: Int

    init(id: UUID = UUID(),
         title: String,
         flightNumber: String,
         departure: String,
         arrival: String,
         departureTime: String,
         arrivalTime: String,
         dueDate: Date,
         airline: Airline,
         arrivalDayOffset: Int = 0,
         isCompleted: Bool = false) {

        self.flightNumber = flightNumber
        self.departure = departure
        self.arrival = arrival
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.airline = airline
        self.arrivalDayOffset = arrivalDayOffset

        // Pass id, title, dueDate, and isCompleted to BaseTask
        super.init(id: id, title: title, dueDate: dueDate, isCompleted: isCompleted)
    }
}
