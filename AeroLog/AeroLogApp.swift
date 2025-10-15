//  Created by Yu-Han on 6/9/2025.
//  App entry point for AeroLog
//
//  Edited by Riley Martin on 13/10/2025
//
//  Edited by Yu-Han on 15/10/2025

import SwiftUI
import UserNotifications

@main
struct AeroLogApp: App {
    init() {
        AirportCoordinates.loadAirports()
        NotificationManager.shared.requestAuthorizationIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
