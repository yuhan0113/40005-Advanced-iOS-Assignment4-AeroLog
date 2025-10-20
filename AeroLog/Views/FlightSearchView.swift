//
//  FlightSearchView.swift
//  AeroLog
//
//  Created by Riley Martin on 13/10/2025
//

import SwiftUI

struct FlightSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @Binding var sheetDetent: PresentationDetent
    @Binding var showingResults: Bool
    
    @State private var flightCode = ""
    let preFilledFlightCode: String?
    
    init(viewModel: TaskViewModel, sheetDetent: Binding<PresentationDetent>, showingResults: Binding<Bool>, preFilledFlightCode: String? = nil) {
        self.viewModel = viewModel
        self._sheetDetent = sheetDetent
        self._showingResults = showingResults
        self.preFilledFlightCode = preFilledFlightCode
    }
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var searchResults: [FlightSearchResult] = []
    @State private var duplicateFlightError = ""
    @State private var showDuplicateError = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if hasSearched && !searchResults.isEmpty {
                    Button(action: {
                        withAnimation {
                            hasSearched = false
                            searchResults = []
                            flightCode = ""
                            showingResults = false
                            sheetDetent = .height(240)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.leading)
                }
                
                Spacer()
                
                Button(action: {
                    showingResults = false
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            if !hasSearched || searchResults.isEmpty {
                VStack(spacing: 16) {
                    Text("Enter Flight Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                    
                    TextField("e.g., QF123", text: $flightCode)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.title3)
                        .frame(height: 48)
                        .padding(.horizontal)
                }
            }
            
            if hasSearched {
                if searchResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                        
                        Text("No flights found")
                            .font(.headline)
                        
                        Text("Try a different flight code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        Text("Results for \(flightCode)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(searchResults) { result in
                                    FlightResultCard(result: result, viewModel: viewModel, dismiss: dismiss, showingResults: $showingResults)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            if !hasSearched || searchResults.isEmpty {
                Button(action: {
                    searchFlights()
                }) {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Search")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(flightCode.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .disabled(flightCode.isEmpty || isSearching)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if let preFilled = preFilledFlightCode {
                flightCode = preFilled
                // Automatically search if we have a pre-filled code
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    searchFlights()
                }
            }
        }
    }
    
    private func searchFlights() {
        isSearching = true
        hasSearched = false
        
        Task {
            do {
                let results = try await FlightSearchService.shared.searchFlights(flightNumber: flightCode)
                await MainActor.run {
                    searchResults = results
                    hasSearched = true
                    isSearching = false
                    if !results.isEmpty {
                        withAnimation {
                            showingResults = true
                            sheetDetent = .large
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    searchResults = []
                    hasSearched = true
                    isSearching = false
                }
            }
        }
    }
}

struct FlightResultCard: View {
    let result: FlightSearchResult
    @ObservedObject var viewModel: TaskViewModel
    let dismiss: DismissAction
    @Binding var showingResults: Bool
    @State private var showDuplicateAlert = false
    @State private var duplicateMessage = ""
    
    var departureTimeLocal: String? {
        return extractLiteralDateTime(result.departure.scheduled)
    }
    
    var arrivalTimeLocal: String? {
        return extractLiteralDateTime(result.arrival.scheduled)
    }
    
    // literally parse the iso string without any timezone conversions
    // this means we show exactly what the api gives us
    private func extractLiteralDateTime(_ isoString: String) -> String? {
        let components = isoString.components(separatedBy: "T")
        guard components.count == 2 else { return nil }
        
        let datePart = components[0]
        var timeWithZone = components[1]
        
        if let plusIndex = timeWithZone.firstIndex(of: "+") {
            timeWithZone = String(timeWithZone[..<plusIndex])
        } else if let lastDashIndex = timeWithZone.lastIndex(of: "-"), timeWithZone.distance(from: timeWithZone.startIndex, to: lastDashIndex) > 5 {
            timeWithZone = String(timeWithZone[..<lastDashIndex])
        }
        
        let dateComponents = datePart.components(separatedBy: "-")
        guard dateComponents.count == 3,
              let year = Int(dateComponents[0]),
              let month = Int(dateComponents[1]),
              let day = Int(dateComponents[2]) else {
            return nil
        }
        
        let timeComponents = timeWithZone.components(separatedBy: ":")
        guard timeComponents.count >= 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        
        return "\(dateFormatter.string(from: date)) at \(displayHour):\(String(format: "%02d", minute)) \(period)"
    }
    
    func parseDateString(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    func formattedDateTime(_ dateString: String) -> String? {
        guard let date = parseDateString(dateString) else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.airline.name)
                        .font(.headline)
                    
                    Text("Flight \(result.flight.iata ?? result.flight.number)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: result.flightStatus)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(result.departure.iata ?? result.departure.airport)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if let scheduled = departureTimeLocal {
                        Text(scheduled)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(result.arrival.iata ?? result.arrival.airport)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if let scheduled = arrivalTimeLocal {
                        Text(scheduled)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            if result.flightStatus.lowercased() == "active" || result.flightStatus.lowercased() == "en-route" {
                FlightProgressBar(
                    departureTime: result.departure.scheduled,
                    arrivalTime: result.arrival.scheduled,
                    departureAirport: result.departure.iata ?? "DEP",
                    arrivalAirport: result.arrival.iata ?? "ARR"
                )
                .padding(.vertical, 8)
            }
            
            if let gate = result.departure.gate {
                Text("Gate: \(gate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                addFlightToLog()
            }) {
                Text("Add to My Flights")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Already Added", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(duplicateMessage)
        }
    }
    
    private func addFlightToLog() {
        let departureTime = extractTimeInTimezone(from: result.departure.scheduled, timezone: result.departure.timezone) ?? "N/A"
        let arrivalTime = extractTimeInTimezone(from: result.arrival.scheduled, timezone: result.arrival.timezone) ?? "N/A"
        
        let departureLocation = result.departure.iata ?? result.departure.airport
        let arrivalLocation = result.arrival.iata ?? result.arrival.airport
        
        let flightNumber = result.flight.iata ?? result.flight.number
        
        let airline = matchAirline(from: result.airline.iata ?? "")
        
        let dueDate = extractLiteralDate(from: result.departure.scheduled) ?? Date()
        // figure out how many days between departure and arrival for multi-day flights
        let arrivalDayOffset = calculateArrivalDayOffset(departureISO: result.departure.scheduled, arrivalISO: result.arrival.scheduled)
        
        do {
            try viewModel.addTask(
                title: "\(departureLocation) to \(arrivalLocation)",
                flightNumber: flightNumber,
                departure: departureLocation,
                arrival: arrivalLocation,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                dueDate: dueDate,
                airline: airline,
                arrivalDayOffset: arrivalDayOffset
            )
            showingResults = false
            dismiss()
        } catch TaskError.duplicateFlight {
            duplicateMessage = "This flight is already in your log."
            showDuplicateAlert = true
        } catch {
            //
        }
    }
    
    private func matchAirline(from iataCode: String) -> Airline {
        return Airline.allCases.first(where: { $0.code == iataCode.uppercased() }) ?? .qantas
    }
    
    private func parseDate(from dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    private func formatDateTime(_ dateString: String) -> String? {
        guard let date = parseDate(from: dateString) else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func extractTime(from dateString: String) -> String? {
        guard let date = parseDate(from: dateString) else { return nil }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func extractTimeInTimezone(from dateString: String, timezone: String?) -> String? {
        let components = dateString.components(separatedBy: "T")
        guard components.count == 2 else { return nil }
        
        var timeWithZone = components[1]
        
        if let plusIndex = timeWithZone.firstIndex(of: "+") {
            timeWithZone = String(timeWithZone[..<plusIndex])
        } else if let lastDashIndex = timeWithZone.lastIndex(of: "-"), timeWithZone.distance(from: timeWithZone.startIndex, to: lastDashIndex) > 5 {
            timeWithZone = String(timeWithZone[..<lastDashIndex])
        }
        
        let timeComponents = timeWithZone.components(separatedBy: ":")
        guard timeComponents.count >= 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return nil
        }
        
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        
        return "\(displayHour):\(String(format: "%02d", minute)) \(period)"
    }
    
    private func extractLiteralDate(from isoString: String) -> Date? {
        let components = isoString.components(separatedBy: "T")
        guard components.count >= 1 else { return nil }
        
        let datePart = components[0]
        let dateComponents = datePart.components(separatedBy: "-")
        guard dateComponents.count == 3,
              let year = Int(dateComponents[0]),
              let month = Int(dateComponents[1]),
              let day = Int(dateComponents[2]) else {
            return nil
        }
        
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
    
    private func calculateArrivalDayOffset(departureISO: String, arrivalISO: String) -> Int {
        guard let departureDate = extractLiteralDate(from: departureISO),
              let arrivalDate = extractLiteralDate(from: arrivalISO) else {
            return 0
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: departureDate, to: arrivalDate)
        return components.day ?? 0
    }
    
    private func formatDate(_ dateString: String) -> String? {
        guard let date = parseDate(from: dateString) else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct FlightProgressBar: View {
    let departureTime: String
    let arrivalTime: String
    let departureAirport: String
    let arrivalAirport: String
    
    var progress: Double {
        let iso8601Formatter = ISO8601DateFormatter()
        guard let depDate = iso8601Formatter.date(from: departureTime),
              let arrDate = iso8601Formatter.date(from: arrivalTime) else {
            return 0.5
        }
        
        let now = Date()
        let totalDuration = arrDate.timeIntervalSince(depDate)
        let elapsed = now.timeIntervalSince(depDate)
        
        let calculatedProgress = elapsed / totalDuration
        return min(max(calculatedProgress, 0.0), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green)
                    .frame(width: max(0, progress * UIScreen.main.bounds.width * 0.85), height: 8)
            }
            
            HStack {
                Text(departureAirport)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))% complete")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(arrivalAirport)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "scheduled":
            return .blue
        case "active", "en-route":
            return .green
        case "landed":
            return .gray
        case "cancelled":
            return .red
        case "delayed":
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
}
