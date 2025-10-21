//
//  ErrorHandler.swift
//
//  Created by Yu-Han on 06/09/2025


import Foundation

enum TaskError: Error, LocalizedError {
    case invalidInput
    case duplicateFlight
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "All required fields must be filled in."
        case .duplicateFlight:
            return "This flight has already been added to your log."
        }
    }
}
