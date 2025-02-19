//
//  ShuttleTrackingSwift.swift
//  HT_App
//
//  Created by Joy Itodo on 2/12/25.
//

import SwiftUI
import MapKit
@preconcurrency import PostgresNIO

struct UserLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct ShuttleTrackingView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), 
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var userLocation: UserLocation?
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: userLocation == nil ? [] : [userLocation!]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text(location.name)
                        .font(.caption)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(5)
                }
            }
        }
        .onAppear {
            Task {
                await fetchUserLocation(email: "jane@gmail.com") // Replace with logged-in user email
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    func fetchUserLocation(email: String) async {
        guard let connection = DatabaseManager.shared.getConnection() else {
            print("❌ No database connection")
            return
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
                           
                        DispatchQueue.main.async {
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                userLocation = UserLocation(name: name, coordinate: coordinate)
                                region.center = coordinate
                        }
                }
            }
            
        } catch {
            print("❌ Database Query Failed: \(error)")
        }
    }


}

#Preview {
    ShuttleTrackingView()
}
