//
//  ShuttleDataFetcher.swift
//  HT_App
//
//  Created by Joy Itodo on 2/12/25.
//

import Foundation
import CoreLocation
@preconcurrency import PostgresNIO

struct ShuttleDataFetcher {
    
    static func fetchUserLocation(email: String, isDriver: Bool) async -> UserLocation? {
        guard let connection = DatabaseManager.shared.getConnection() else {
            print("❌ No database connection")
            return nil
        }
        
        do {
            let query = "SELECT full_name, latitude, longitude FROM users WHERE email = $1;"
            let emailData = PostgresData(string: email)
          
            let result = try await connection.query(query, [emailData]).get()
            
            if let row = result.first?.makeRandomAccess() {
                
                if let name = row[data: "full_name"].string,
                   let latitude = try row[data: "latitude"].double,
                   let longitude = try row[data: "longitude"].double {
                        print("Latitude: \(latitude), Longitude: \(longitude)")
                           
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        return UserLocation(name: name, coordinate: coordinate, isDriver: isDriver)
                }
            }
            
        } catch {
            print("❌ Database Query Failed: \(error)")
        }
        
        return nil
    }
}
