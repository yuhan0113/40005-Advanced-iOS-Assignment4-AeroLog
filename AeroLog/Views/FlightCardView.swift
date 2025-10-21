//
//  FlightCardView.swift
//  AeroLog
//
//  Created by Yu-Han on 06/09/2025
//
//  Edited by Riley Martin on 13/10/2025
//

import SwiftUI

struct FlightCardView: View {
    let task: FlightTask
    
    var isActive: Bool {
        guard let (departure, arrival) = parseFlightTimes() else { return false }
        let now = Date()
        return now >= departure && now <= arrival
    }
    
    var flightProgress: Double {
        guard let (departure, arrival) = parseFlightTimes() else { return 0.0 }
        guard isActive else { return 0.0 }
        
        let now = Date()
        let totalDuration = arrival.timeIntervalSince(departure)
        let elapsed = now.timeIntervalSince(departure)
        
        let progress = elapsed / totalDuration
        return min(max(progress, 0.0), 1.0)
    }
    
    func parseFlightTimes() -> (departure: Date, arrival: Date)? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        guard let depTime = dateFormatter.date(from: task.departureTime),
              let arrTime = dateFormatter.date(from: task.arrivalTime) else {
            return nil
        }
        
        let calendar = Calendar.current
        let depComponents = calendar.dateComponents([.hour, .minute], from: depTime)
        let arrComponents = calendar.dateComponents([.hour, .minute], from: arrTime)
        
        guard let departure = calendar.date(bySettingHour: depComponents.hour ?? 0,
                                            minute: depComponents.minute ?? 0,
                                            second: 0,
                                            of: task.dueDate) else {
            return nil
        }
        
        // handle multi-day flights by adding the day offset to arrival date
        var arrivalBaseDate = task.dueDate
        if task.arrivalDayOffset > 0 {
            arrivalBaseDate = calendar.date(byAdding: .day, value: task.arrivalDayOffset, to: task.dueDate) ?? task.dueDate
        }
        
        guard let arrival = calendar.date(bySettingHour: arrComponents.hour ?? 0,
                                          minute: arrComponents.minute ?? 0,
                                          second: 0,
                                          of: arrivalBaseDate) else {
            return nil
        }
        
        return (departure, arrival)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(task.airline.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.airline.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 6) {
                        Text(task.flightNumber)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("In Flight")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        } else if task.isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                Text("Completed")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
                .padding(.horizontal)
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FROM")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(task.departure)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(task.departureTime)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 8) {
                    Image(systemName: "airplane")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(90))
                    
                    if isActive {
                        Text("\(Int(flightProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("TO")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(task.arrival)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(task.arrivalTime)
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            
            if isActive {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(spacing: 6) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: flightProgress * (UIScreen.main.bounds.width - 64), height: 6)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text(task.departure)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Flight in Progress")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(task.arrival)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}
