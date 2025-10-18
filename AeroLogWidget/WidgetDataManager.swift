//
//  WidgetDataManager.swift
//  AeroLogWidget
//
//  Created by 張宇漢 on 18/10/2025.
//

import Foundation
import CoreData
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AeroLogModel")
        
        // Use App Groups for shared data access
        if let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yuhanchang.aerolog2025") {
            let storeDescription = NSPersistentStoreDescription(url: storeURL.appendingPathComponent("AeroLogModel.sqlite"))
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Widget Core Data error: \(error)")
            }
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func fetchUpcomingFlights(limit: Int = 3) -> [FlightInfo] {
        let request: NSFetchRequest<FlightTaskEntity> = FlightTaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "dueDate >= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let flightNumber = entity.flightNumber,
                      let departure = entity.departure,
                      let arrival = entity.arrival,
                      let departureTime = entity.departureTime,
                      let airlineRaw = entity.airlineRaw else {
                    return nil
                }
                
                return FlightInfo(
                    flightNumber: flightNumber,
                    departure: departure,
                    arrival: arrival,
                    departureTime: departureTime,
                    airline: airlineRaw
                )
            }
        } catch {
            print("Widget fetch error: \(error)")
            return []
        }
    }
}

struct FlightInfo {
    let flightNumber: String
    let departure: String
    let arrival: String
    let departureTime: String
    let airline: String
}

