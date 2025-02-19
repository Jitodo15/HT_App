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
    init() {
        Task {
            await DatabaseManager.shared.connectToDatabase()
        }
    }
    

    var body: some Scene {
        WindowGroup {
            NavigationView {
                SignupView()
            }
        }
    }
}
