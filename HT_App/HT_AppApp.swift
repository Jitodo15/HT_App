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

class DatabaseManager {
    static let shared = DatabaseManager()
    private var connection: PostgresConnection?
    private var eventLoopGroup: MultiThreadedEventLoopGroup?

    private init() {}
    
    func connectToDatabase() async {
        // directly using the provided details for my own local PostgreSQL instance
        let host = "localhost"
        let port = 5432
        let username = "postgres"
        let password = "htapp25"
        let database = "postgres"
        
        // checking if these values are correct
        print("Connecting to database with the following details:")
        print("Host: \(host), Port: \(port), Username: \(username), Database: \(database)")
        

        guard let host = ProcessInfo.processInfo.environment["DB_HOST"],
              let portString = ProcessInfo.processInfo.environment["DB_PORT"],
              let port = Int(portString),
              let username = ProcessInfo.processInfo.environment["DB_USERNAME"],
              let password = ProcessInfo.processInfo.environment["DB_PASSWORD"],
              let database = ProcessInfo.processInfo.environment["DB_NAME"] else {
            print("❌ Missing database credentials")
            
            return
        }
        print(ProcessInfo.processInfo.environment)


        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let logger = Logger(label: "PostgreSQL")
        
        let configuration = PostgresConnection.Configuration(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .disable  // use `.requireTLS` only if connecting to a remote database with SSL
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
            print("❌ Database Connection Failed: \(error)")
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
    init() {
        Task {
            await DatabaseManager.shared.connectToDatabase()
        }
    }
    

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
