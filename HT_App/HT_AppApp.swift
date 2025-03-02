//
//  HT_AppApp.swift
//  HT_App
//
//  Created by Joy Itodo on 1/26/25.
// edited by ayo 02/03/25


import SwiftUI
import PostgresNIO
import Logging
import NIO
import NIOSSL
import GoogleMaps
import os.log

class DatabaseManager {
    static let shared = DatabaseManager()
    private var connection: PostgresConnection?
    private var eventLoopGroup: MultiThreadedEventLoopGroup?

    private init() { }
    
    func connectToDatabase() async {
        
        guard let dbURLString = ProcessInfo.processInfo.environment["DB_URL"],
            let dbURL = URL(string: dbURLString) else {
            print("❌ DATABASE_URL environment variable is missing or invalid")
                return
            }
                
        guard let host = dbURL.host,
            let username = dbURL.user,
            let password = dbURL.password else {
            print("❌ Error extracting database credentials")
            return
        }
                
        let database = dbURL.lastPathComponent
        let port = dbURL.port ?? 5432  
        print("🚀 Connecting to Render PostgreSQL at \(host):\(port)...")
    
        
     
        print(ProcessInfo.processInfo.environment)


        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let logger = Logger(label: "PostgreSQL")
        
        let tlsConfiguration = try? NIOSSLContext(configuration: .clientDefault)
        let configuration = PostgresConnection.Configuration(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tlsConfiguration == nil ? .disable : .require(tlsConfiguration!)  // use `.requireTLS` only if connecting to a remote database with SSL
        )
        
        do {
            self.connection = try await PostgresConnection.connect(
                on: eventLoopGroup!.next(),
                configuration: configuration,
                id: .init(1),
                logger: logger
            )
            print("✅ Connected to PostgreSQL successfully!")
        } catch {
            os_log("❌ Database Connection Failed with error: %@", log: .default, type: .error, String(reflecting: error))


            print("❌ Database Connection Failed: \(String(reflecting: error))")
        
        }
    }
    
    
    func getConnection() -> PostgresConnection? {
        guard let connection = connection else {
            print("❌ Database not connected")
            return nil
        }
        return connection
    }
    

    func closeConnection() {
        try? connection?.close().wait()
        eventLoopGroup?.shutdownGracefully { error in
            if let error = error {
                print("❌ Error shutting down event loop group: \(error)")
            }
        }
    }
    
}

@main
struct HT_AppApp: App {
    @StateObject private var locationManager = LocationManager()
    
    init() {
        var api_key = ProcessInfo.processInfo.environment["MAP_API_KEY"]
        GMSServices.provideAPIKey(ProcessInfo.processInfo.environment["MAP_API_KEY"] as! String)
        Task {
            await DatabaseManager.shared.connectToDatabase()
        }
    }
    

    var body: some Scene {
        WindowGroup {
            NavigationView {
                SignupView()
                    .onAppear {
                        locationManager.startUpdatingLocation()
                        startPeriodicLocationUpdates()
                    }
            }
        }
    }
    
    private func startPeriodicLocationUpdates() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Every 5 minutes
            Task {
                await updateUserLocation()
            }
        }
    }

    private func updateUserLocation() async {
        guard let userLocation = locationManager.location else {
            print("❌ Location not available yet")
            return
        }
            
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
            
        guard let userID = fetchCurrentUserID() else {
            print("❌ No logged-in user")
            return
        }

            await updateUserLocationInDatabase(userID: userID, latitude: latitude, longitude: longitude)
    }
        
    private func fetchCurrentUserID() -> Int? {
            // Implement a way to get the currently logged-in user's ID
            // This could be from UserDefaults, AppStorage, or a global state manager
        return UserDefaults.standard.integer(forKey: "userID")
    }
        
    private func updateUserLocationInDatabase(userID: Int, latitude: Double, longitude: Double) async {
        guard let connection = DatabaseManager.shared.getConnection() else {
            print("❌ No active database connection")
            return
        }
            
        let sql = "UPDATE users SET latitude = $1, longitude = $2 WHERE id = $3"
        let latData = PostgresData(double: latitude)
        let lonData = PostgresData(double: longitude)
        let userIDData = PostgresData(int: userID)
            
        do {
            try await connection.query(sql, [latData, lonData, userIDData]).get()
            print("✅ Location updated successfully for user \(userID)")
        } catch {
            print("❌ Error updating location: \(error)")
        }
    }
}
