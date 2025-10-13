//
//  TimezoneHelper.swift
//  AeroLog
//
//  Created by Riley Martin on 13/10/2025
//

import Foundation
import CoreLocation

class TimezoneHelper {
    static func convertUTCToLocalTime(_ utcTimeString: String, for coordinate: CLLocationCoordinate2D) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        guard let utcDate = dateFormatter.date(from: utcTimeString) else {
            return utcTimeString
        }
        
        let timezone = TimezoneHelper.getTimezone(for: coordinate)
        
        dateFormatter.timeZone = timezone
        return dateFormatter.string(from: utcDate)
    }
    
    static func getTimezone(for coordinate: CLLocationCoordinate2D) -> TimeZone {
        let knownTimezones: [(lat: Double, lon: Double, timezone: String)] = [
            (33.9425, -118.408, "America/Los_Angeles"),
            (-33.9461, 151.177, "Australia/Sydney"),
            (-37.6690, 144.8410, "Australia/Melbourne"),
            (-27.3842, 153.1175, "Australia/Brisbane"),
            (32.8998, -97.0403, "America/Chicago"),
            (40.6413, -73.7781, "America/New_York"),
            (43.6777, -79.6248, "America/Toronto"),
            (49.1967, -123.1815, "America/Vancouver"),
            (25.0797, 121.2342, "Asia/Taipei"),
            (35.7720, 140.3929, "Asia/Tokyo"),
            (22.3080, 113.9185, "Asia/Hong_Kong"),
            (1.3644, 103.9915, "Asia/Singapore"),
            (25.2532, 55.3657, "Asia/Dubai"),
            (51.4700, -0.4543, "Europe/London")
        ]
        
        for known in knownTimezones {
            let latDiff = abs(coordinate.latitude - known.lat)
            let lonDiff = abs(coordinate.longitude - known.lon)
            if latDiff < 1.0 && lonDiff < 1.0 {
                return TimeZone(identifier: known.timezone) ?? TimeZone(identifier: "UTC")!
            }
        }
        
        return TimeZone(identifier: "UTC")!
    }
}

