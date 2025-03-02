////
////  ShuttleTrackingView.swift
////  HT_App
////
////  Created by Joy Itodo on 2/12/25.
////
//
//import SwiftUI
//import MapKit
//
//struct UserLocation: Identifiable {
//    let id = UUID()
//    let name: String
//    let coordinate: CLLocationCoordinate2D
//    let isDriver: Bool
//}
//
//struct ShuttleTrackingView: View {
//    @Binding var showFullMap: Bool
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//    )
//    
//    @State private var driverLocation: UserLocation?
//    @State private var studentLocation: UserLocation?
//    @State private var route: MKPolyline?
//    @State private var simulatedRoute: [CLLocationCoordinate2D] = []
//    @State private var currentRouteIndex = 0
//    @State private var timer: Timer?
//
//    var body: some View {
//        VStack {
//            HStack {
//                Button(action: {
//                    withAnimation {
//                        showFullMap.toggle()
//                    }
//                }) {
//                    Image(systemName: "chevron.down")
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.black.opacity(0.7))
//                        .clipShape(Circle())
//                        .shadow(radius: 5)
//                }
//                Spacer()
//            }
//            .padding()
//            
//            Spacer()
//            
//            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: {
//                var locations: [UserLocation] = []
//                if let driverLocation = driverLocation {
//                    locations.append(driverLocation)
//                }
//                if let studentLocation = studentLocation {
//                    locations.append(studentLocation)
//                }
//                return locations
//            }()) { location in
//                MapAnnotation(coordinate: location.coordinate) {
//                    VStack {
//                        if location.name == "Timo" {
//                            Image(systemName: "car.fill")
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                                .foregroundColor(.blue)
//                        } else {
//                            Image(systemName: "mappin.circle.fill")
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                                .foregroundColor(.red)
//                        }
//                        Text(location.name)
//                            .font(.caption)
//                            .background(Color.white.opacity(0.7))
//                            .cornerRadius(5)
//                    }
//                }
//            }
//            .onAppear {
//                Task {
//                    await fetchLocations()
//                }
//            }
//            .edgesIgnoringSafeArea(.all)
////            .overlay(driverRouteOverlay)
//
//        }
//        .background(Color.gray.opacity(0.8))
//        .edgesIgnoringSafeArea(.all)
//        .onDisappear {
//            timer?.invalidate()
//        }
//    }
//    
//    
//    
//    func fetchLocations() async {
//        async let driver = ShuttleDataFetcher.fetchUserLocation(email: "timo@gmail.com", isDriver: true)
//        async let student = ShuttleDataFetcher.fetchUserLocation(email: "joy@gmail.com", isDriver: false)
//        
//        driverLocation = await driver
//        studentLocation = await student
//        
//        if let driverLocation = driverLocation, let studentLocation = studentLocation {
//            await fetchRoute(from: driverLocation.coordinate, to: studentLocation.coordinate)
//            
//            let coordinates = [driverLocation.coordinate, studentLocation.coordinate]
//            fitMapToCoordinates(coordinates)
//        }
//    }
//
//    func fetchRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async {
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
//        request.transportType = .automobile
//        
//        let directions = MKDirections(request: request)
//        
//        do {
//            let response = try await directions.calculate()
//            if let route = response.routes.first {
//                self.route = route.polyline
//                self.simulatedRoute = route.polyline.coordinates
//                startSimulatedMovement()
//            }
//        } catch {
//            print("❌ Error fetching route: \(error)")
//        }
//    }
//    
//    func fitMapToCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
//        var mapRect = MKMapRect.null
//        for coordinate in coordinates {
//            let point = MKMapPoint(coordinate)
//            mapRect = mapRect.union(MKMapRect(origin: point, size: MKMapSize()))
//        }
//        let region = MKCoordinateRegion(mapRect)
//        self.region = region
//    }
//    
//    func updateRegion() {
//        guard let driverLocation = driverLocation, let studentLocation = studentLocation else {
//            return
//        }
//        
//        let coordinates = [driverLocation.coordinate, studentLocation.coordinate]
//        let latitudes = coordinates.map { $0.latitude }
//        let longitudes = coordinates.map { $0.longitude }
//        
//        let midLat = (latitudes.min()! + latitudes.max()!) / 2
//        let midLong = (longitudes.min()! + longitudes.max()!) / 2
//        let span = MKCoordinateSpan(
//            latitudeDelta: (latitudes.max()! - latitudes.min()!) * 1.5,
//            longitudeDelta: (longitudes.max()! - longitudes.min()!) * 1.5
//        )
//        
//        region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: midLat, longitude: midLong), span: span)
//    }
//
//
//    
//    func startSimulatedMovement() {
//        timer?.invalidate()
//        currentRouteIndex = 0
//        
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//            guard self.currentRouteIndex < self.simulatedRoute.count else {
//                self.timer?.invalidate()
//                return
//            }
//            
//            let nextCoordinate = self.simulatedRoute[self.currentRouteIndex]
//            self.driverLocation = UserLocation(name: "Timo", coordinate: nextCoordinate, isDriver: true)
//            self.region.center = nextCoordinate
//            
//            self.currentRouteIndex += 1
//        }
//    }
//}
//
//
//#Preview {
//    ShuttleTrackingView(showFullMap: .constant(true))
//}
//
//
//
//// Extension to get coordinates from polyline
//extension MKPolyline {
//    var coordinates: [CLLocationCoordinate2D] {
//        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
//        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
//        return coords
//    }
//}
