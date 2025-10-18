//
//  AppIntent.swift
//  AeroLogWidget
//
//  Created by 張宇漢 on 18/10/2025.
//

import WidgetKit
import AppIntents
import UIKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Flight Widget Configuration" }
    static var description: IntentDescription { "Configure your flight tracking widget." }

    // Configurable parameters for the flight widget
    @Parameter(title: "Show Airline Logo", default: true)
    var showAirlineLogo: Bool
    
    @Parameter(title: "Max Flights to Show", default: 3)
    var maxFlights: Int
    
    @Parameter(title: "Show Flight Status", default: true)
    var showFlightStatus: Bool
}

struct OpenFlightIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Flight Details"
    static var description: IntentDescription = "Opens the flight details in the AeroLog app"
    
    @Parameter(title: "Flight Number")
    var flightNumber: String
    
    init() {}
    
    init(flightNumber: String) {
        self.flightNumber = flightNumber
    }
    
    func perform() async throws -> some IntentResult {
        // For widget extensions, we'll use a different approach
        // The widget will handle the URL opening through the widgetURL modifier
        return .result()
    }
}

struct AddFlightIntent: AppIntent {
    static var title: LocalizedStringResource = "Add New Flight"
    static var description: IntentDescription = "Opens the add flight screen in the AeroLog app"
    
    func perform() async throws -> some IntentResult {
        // For widget extensions, we'll use a different approach
        // The widget will handle the URL opening through the widgetURL modifier
        return .result()
    }
}

