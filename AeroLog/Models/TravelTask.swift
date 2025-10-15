//
//  TravelTask.swift
//  AeroLog
//
//  Created by Yu-Han on 04/09/2025

import Foundation

// Protocol defining shared travel task behaviour
protocol TravelTask {
    var id: UUID { get }
    var title: String { get set }
    var dueDate: Date { get set }
    var isCompleted: Bool { get set }

    func markCompleted()
}
