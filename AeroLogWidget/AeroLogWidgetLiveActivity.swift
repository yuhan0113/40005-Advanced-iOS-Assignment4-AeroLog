//
//  AeroLogWidgetLiveActivity.swift
//  AeroLogWidget
//
//  Created by Yu-Han on 18/10/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AeroLogWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var flightStatus: String
        var gateNumber: String?
        var boardingTime: String?
        var departureTime: String
    }

    // Fixed non-changing properties about your activity go here!
    var flightNumber: String
    var departure: String
    var arrival: String
    var airline: String
}

struct AeroLogWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AeroLogWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "airplane")
                        .foregroundColor(.blue)
                    Text(context.attributes.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(context.attributes.airline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(context.attributes.departure) → \(context.attributes.arrival)")
                            .font(.subheadline)
                        Text("Status: \(context.state.flightStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        if let gateNumber = context.state.gateNumber {
                            Text("Gate: \(gateNumber)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        Text("Dep: \(context.state.departureTime)")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.blue.opacity(0.1))
            .activitySystemActionForegroundColor(Color.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.flightNumber)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(context.attributes.airline)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.flightStatus)
                            .font(.caption)
                            .fontWeight(.medium)
                        if let gateNumber = context.state.gateNumber {
                            Text("Gate \(gateNumber)")
                                .font(.caption2)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("\(context.attributes.departure) → \(context.attributes.arrival)")
                            .font(.subheadline)
                        Spacer()
                        Text("Dep: \(context.state.departureTime)")
                            .font(.caption)
                    }
                }
            } compactLeading: {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(context.state.flightStatus)
                    .font(.caption)
                    .fontWeight(.medium)
            } minimal: {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "aerolog://flight/\(context.attributes.flightNumber)"))
            .keylineTint(Color.blue)
        }
    }
}

extension AeroLogWidgetAttributes {
    fileprivate static var preview: AeroLogWidgetAttributes {
        AeroLogWidgetAttributes(
            flightNumber: "QF123",
            departure: "SYD",
            arrival: "MEL",
            airline: "Qantas"
        )
    }
}

extension AeroLogWidgetAttributes.ContentState {
    fileprivate static var onTime: AeroLogWidgetAttributes.ContentState {
        AeroLogWidgetAttributes.ContentState(
            flightStatus: "On Time",
            gateNumber: "A12",
            boardingTime: "13:45",
            departureTime: "14:30"
        )
     }
     
     fileprivate static var delayed: AeroLogWidgetAttributes.ContentState {
         AeroLogWidgetAttributes.ContentState(
             flightStatus: "Delayed",
             gateNumber: "A12",
             boardingTime: "14:15",
             departureTime: "15:00"
         )
     }
}

#Preview("Notification", as: .content, using: AeroLogWidgetAttributes.preview) {
   AeroLogWidgetLiveActivity()
} contentStates: {
    AeroLogWidgetAttributes.ContentState.onTime
    AeroLogWidgetAttributes.ContentState.delayed
}

