//
//  RideShareView.swift
//  HT_App
//
//  Created by Joy Itodo on 3/1/25.
//

import SwiftUI
import UIKit
import GoogleMaps
import CoreLocation

struct RideShareView: View {
    @ObservedObject var viewModel = RideShareViewModel()
    @State private var rideType: String = "inbound"
    @State private var selectedDriver: Driver?
    
    
    var body: some View {
        VStack(spacing: 16) {

            Text("Rideshare")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            Picker(selection: $rideType, label: Text("")) {
                Text("Inbound (To Campus)").tag("inbound")
                Text("Outbound (To St. Edwards)").tag("outbound")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .frame(height: 55) 
            .tint(Color.maroon)
            .onChange(of: rideType) { newValue in
                viewModel.fetchDrivers(for: newValue)
            }
            
            GoogleMapsView()


            if !viewModel.message.isEmpty {
                Text(viewModel.message)
                    .foregroundColor(Color.maroon)
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.drivers) { driver in
                            DriverCard(driver: driver)
                                .onTapGesture {
                                  selectedDriver = driver
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            if let selectedDriver = selectedDriver {
                Button(action: {
                    bookRide(driver: selectedDriver)
                }) {
                    Text("Book Ride with \(selectedDriver.name)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.maroon)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.fetchDrivers(for: rideType)
        }
        .padding(.top, 10)
        .toolbar(.hidden, for: .tabBar)
    }

    func bookRide(driver: Driver) {
        print("Booked ride with \(driver.name) in \(driver.car) at \(driver.inboundHours)")
    }
}

struct RideTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.maroon : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

struct DriverCard: View {
    let driver: Driver
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(driver.name)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(driver.car)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(driver.inboundHours)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

struct RideShareView_Previews: PreviewProvider {
    static var previews: some View {
        RideShareView()
    }
}

struct GoogleMapsView: UIViewRepresentable {
    let initialUserLocation = CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431) // Austin, TX
    @State private var driverLocation = CLLocationCoordinate2D(latitude: 30.2600, longitude: -97.7500) // Simulated Start
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: initialUserLocation.latitude, longitude: initialUserLocation.longitude, zoom: 14)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        
        // Add user location marker
        let userMarker = GMSMarker(position: initialUserLocation)
        userMarker.title = "Pickup Location"
        userMarker.icon = GMSMarker.markerImage(with: .blue)
        userMarker.map = mapView

        // Add driver location marker
        let driverMarker = GMSMarker(position: driverLocation)
        driverMarker.title = "Driver"
        driverMarker.icon = UIImage(systemName: "car.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        driverMarker.map = mapView

        // Start simulating movement
        DispatchQueue.main.async {
            simulateDriverMovement(driverMarker: driverMarker, mapView: mapView)
        }

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {}

   
    private func simulateDriverMovement(driverMarker: GMSMarker, mapView: GMSMapView) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            let latDiff = (initialUserLocation.latitude - driverMarker.position.latitude) * 0.1
            let lonDiff = (initialUserLocation.longitude - driverMarker.position.longitude) * 0.1

            driverMarker.position = CLLocationCoordinate2D(
                latitude: driverMarker.position.latitude + latDiff,
                longitude: driverMarker.position.longitude + lonDiff
            )

            
            let newCamera = GMSCameraPosition.camera(
                withLatitude: driverMarker.position.latitude,
                longitude: driverMarker.position.longitude,
                zoom: 14
            )
            mapView.animate(to: newCamera)

            
            if abs(latDiff) < 0.0001 && abs(lonDiff) < 0.0001 {
                timer.invalidate()
            }
        }
    }
}
