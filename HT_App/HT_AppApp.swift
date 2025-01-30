//
//  HT_AppApp.swift
//  HT_App
//
//  Created by Joy Itodo on 1/26/25.
//


import SwiftUI
import PostgresNIO
import Logging
import NIO

class DatabaseManager {
    static let shared = DatabaseManager()
    private var connection: PostgresConnection?

    private init() {}

    func connectToDatabase() async {
        
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


        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let logger = Logger(label: "PostgreSQL")

        let configuration = PostgresConnection.Configuration(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .disable  // Use `.requireTLS` if connecting to a remote database with SSL
        )

        do {
            self.connection = try await PostgresConnection.connect(
                on: eventLoopGroup.next(),
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
        return connection
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

