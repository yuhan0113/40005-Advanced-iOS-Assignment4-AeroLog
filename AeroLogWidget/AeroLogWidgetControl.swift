//
//  AeroLogWidgetControl.swift
//  AeroLogWidget
//
//  Created by Yu-Han on 18/10/2025.
//

import AppIntents
import SwiftUI
import WidgetKit

struct AeroLogWidgetControl: ControlWidget {
    static let kind: String = "AeroLogWidgetControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Flight Reminder",
                isOn: value.remindersEnabled,
                action: ToggleReminderIntent(value.flightNumber)
            ) { isEnabled in
                Label(isEnabled ? "Reminders On" : "Reminders Off", systemImage: "bell")
            }
        }
        .displayName("Flight Reminders")
        .description("Toggle flight reminder notifications.")
    }
}

extension AeroLogWidgetControl {
    struct Value {
        var remindersEnabled: Bool
        var flightNumber: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: FlightConfiguration) -> Value {
            AeroLogWidgetControl.Value(remindersEnabled: true, flightNumber: configuration.flightNumber)
        }

        func currentValue(configuration: FlightConfiguration) async throws -> Value {
            // Check if reminders are enabled for this flight
            let remindersEnabled = true // This would check the actual reminder status
            return AeroLogWidgetControl.Value(remindersEnabled: remindersEnabled, flightNumber: configuration.flightNumber)
        }
    }
}

struct FlightConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Flight Configuration"

    @Parameter(title: "Flight Number", default: "QF123")
    var flightNumber: String
}

struct ToggleReminderIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Toggle Flight Reminder"

    @Parameter(title: "Flight Number")
    var flightNumber: String

    @Parameter(title: "Reminders Enabled")
    var value: Bool

    init() {}

    init(_ flightNumber: String) {
        self.flightNumber = flightNumber
    }

    func perform() async throws -> some IntentResult {
        // Toggle flight reminder notifications
        // This would interact with the NotificationManager
        return .result()
    }
}

