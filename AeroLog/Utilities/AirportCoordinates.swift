//
//  AirportCoordinates.swift
//  AeroLog
//
//  Created by Riley Martin on 13/10/2025
//

import Foundation
import CoreLocation

struct Airport {
    let iata: String
    let icao: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// loads airport data from csv so we can map iata codes to coordinates
class AirportCoordinates {
    private static var airports: [String: Airport] = [:]
    private static var isLoaded = false
    
    static func loadAirports() {
        guard !isLoaded else { return }
        
        guard let path = Bundle.main.path(forResource: "iata-icao", ofType: "csv"),
              let content = try? String(contentsOfFile: path) else {
            return
        }
        
        let rows = content.components(separatedBy: .newlines)
        for (index, row) in rows.enumerated() {
            guard index > 0, !row.isEmpty else { continue }
            
            let columns = parseCSVRow(row)
            guard columns.count >= 7,
                  !columns[2].isEmpty,
                  let lat = Double(columns[5]),
                  let lon = Double(columns[6]) else {
                continue
            }
            
            let iata = columns[2]
            let icao = columns[3]
            let name = columns[4]
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            let airport = Airport(iata: iata, icao: icao, name: name, coordinate: coordinate)
            airports[iata.uppercased()] = airport
            if !icao.isEmpty {
                airports[icao.uppercased()] = airport
            }
        }
        
        isLoaded = true
    }
    
    private static func parseCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn)
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }
        columns.append(currentColumn)
        
        return columns
    }
    
    static func getCoordinate(for code: String) -> CLLocationCoordinate2D? {
        loadAirports()
        return airports[code.uppercased()]?.coordinate
    }
    
    static func getAirport(for code: String) -> Airport? {
        loadAirports()
        return airports[code.uppercased()]
    }
    
    static func getCityName(for code: String) -> String? {
        loadAirports()
        return airports[code.uppercased()]?.name
    }
}

