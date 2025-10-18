//
//  ContentView.swift
//  AeroLog
//
//  Created by Yu-Han on 06/09/2025
//
//  Edited by Riley Martin on 13/10/2025
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showFlightSearch = false
    @State private var sheetDetent: PresentationDetent = .height(240)
    @State private var showingResults = false

    var groupedFlights: [(date: Date, flights: [FlightTask])] {
        let grouped = Dictionary(grouping: viewModel.tasks) { task in
            Calendar.current.startOfDay(for: task.dueDate)
        }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, flights: $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.tasks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.bottom, 8)

                        Text("Ready for Takeoff?")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Add your first flight to start tracking your journey")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showFlightSearch = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Flight")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                        .padding(.top, 20)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(groupedFlights, id: \.date) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(formatDateHeader(group.date))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                    
                                    ForEach(group.flights) { task in
                                        NavigationLink(destination: FlightDetailView(task: task)) {
                                            FlightCardView(task: task)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                deleteTask(task)
                                            } label: {
                                                Label("Delete Flight", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteTask(task)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await refreshFlights()
                    }
                }
            }
            .navigationTitle("My Flights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: UserProfileView(viewModel: UserViewModel())) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFlightSearch = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .onAppear {
                viewModel.fetchTasks()
                checkForSharedFlightCode()
            }
            .sheet(isPresented: $showFlightSearch) {
                FlightSearchView(viewModel: viewModel, sheetDetent: $sheetDetent, showingResults: $showingResults)
                    .presentationDetents(showingResults ? [.large] : [.height(240), .large], selection: $sheetDetent)
                    .presentationDragIndicator(.hidden)
                    .interactiveDismissDisabled(showingResults)
                    .onDisappear {
                        sheetDetent = .height(240)
                        showingResults = false
                    }
            }
        }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func deleteTask(_ task: FlightTask) {
        if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
            viewModel.removeTask(at: IndexSet(integer: index))
        }
    }
    
    private func refreshFlights() async {
        await MainActor.run {
            viewModel.fetchTasks()
        }
    }
    
    private func checkForSharedFlightCode() {
        let userDefaults = UserDefaults(suiteName: "group.com.yuhanchang.aerolog2025")
        if let sharedFlightCode = userDefaults?.string(forKey: "sharedFlightCode") {
            // Clear the shared code
            userDefaults?.removeObject(forKey: "sharedFlightCode")
            userDefaults?.removeObject(forKey: "sharedFlightCodeDate")
            
            // Show flight search with the shared code
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showFlightSearch = true
                // You could pre-populate the search field here if needed
            }
        }
    }
}

#Preview {
    ContentView()
}
