//  Created by Yu-Han on 6/9/2025.
//  App entry point for AeroLog
//
//  Edited by Riley Martin on 13/10/2025

import SwiftUI

@main
struct AeroLogApp: App {
    init() {
        AirportCoordinates.loadAirports()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
