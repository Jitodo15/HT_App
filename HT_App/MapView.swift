import UIKit
import GoogleMaps
import CoreLocation

class MapViewController: UIViewController {
    var mapView: GMSMapView!
    var driverMarker: GMSMarker!
    var studentMarker: GMSMarker!
    var routePolyline: GMSPolyline?
    var etaLabel: UILabel!
    
    let driverEmail = "joy@gmail.com"
    let studentEmail = "me@gmail.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("etaLabel is: \(String(describing: etaLabel))")

        setupMapView()
        setupMarkers()
        fetchLocations()
        Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(fetchLocations), userInfo: nil, repeats: true)
    }
    
    private func setupETALabel() {
        let label = UILabel()
        label.frame = CGRect(x: 20, y: 100, width: 200, height: 40)
        label.backgroundColor = UIColor(red: 128/255, green: 0/255, blue: 0/255, alpha: 1.0)
        label.textAlignment = .center
        label.textColor = .white
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        self.view.addSubview(label)
        self.etaLabel = label
    }
    
    func updateUIWithETA(durationText: String) {
        
        print(durationText)
        guard let etaLabel = etaLabel else {
            print("❌ etaLabel is not initialized.")
            return
        }
        etaLabel.text = "ETA: \(durationText)"
        etaLabel.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        etaLabel.layer.cornerRadius = 8
        etaLabel.clipsToBounds = true
        etaLabel.textAlignment = .center
        view.bringSubviewToFront(etaLabel)
    }


    private func setupMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: 15)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        view.addSubview(mapView)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    
    private func setupMarkers() {
        driverMarker = GMSMarker()
//        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
//        let sfSymbol = UIImage(systemName: "car.fill", withConfiguration: symbolConfig)?.withRenderingMode(.alwaysOriginal)
//
//        driverMarker.icon = sfSymbol

//        driverMarker.icon = UIImage(named: "car_icon")?.withRenderingMode(.alwaysOriginal)
        driverMarker.icon = GMSMarker.markerImage(with: .red)
        driverMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        driverMarker.map = mapView
        
     
        studentMarker = GMSMarker()
        studentMarker.icon = GMSMarker.markerImage(with: .green)
        studentMarker.title = "Student"
        studentMarker.map = mapView
    }
    
    @objc private func fetchLocations() {
        print("Fetching locations...")
        
        Task {
            async let driverLocation = ShuttleDataFetcher.fetchUserLocation(email: driverEmail, isDriver: true)
            async let studentLocation = ShuttleDataFetcher.fetchUserLocation(email: studentEmail, isDriver: false)
            
            if let driver = await driverLocation {
                updateCarMarker(driverMarker, with: driver.coordinate, title: driver.name)
            }
            
            if let student = await studentLocation {
                updateMarker(studentMarker, with: student.coordinate, title: student.name)
            }
            
            if let driver = await driverLocation, let student = await studentLocation {
                drawRoute(from: driver.coordinate, to: student.coordinate)
                adjustCameraToFitRoute(from: driver.coordinate, to: student.coordinate)
                fetchETA(from: driver.coordinate, to: student.coordinate)
                print("yes")
            }
            
            DispatchQueue.main.async {
                self.mapView.clear() // Clear previous markers and route
                self.driverMarker.map = self.mapView
                self.studentMarker.map = self.mapView
                self.routePolyline?.map = self.mapView
            }
        }
    }
    
    private func updateMarker(_ marker: GMSMarker, with coordinate: CLLocationCoordinate2D, title: String) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.5)
        marker.position = coordinate
        marker.title = title
        CATransaction.commit()
    }
    
    private func updateCarMarker(_ marker: GMSMarker, with coordinate: CLLocationCoordinate2D, title: String) {
        print("Updating driver marker to: \(coordinate.latitude), \(coordinate.longitude)")

        CATransaction.begin()
        CATransaction.setAnimationDuration(1.5)
        
        let previousPosition = marker.position
        let bearing = getBearing(from: previousPosition, to: coordinate)
        
        marker.position = coordinate
        marker.rotation = bearing
        marker.title = title
        
        CATransaction.commit()
    }
    


    @objc private func fetchETA(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let originStr = "\(origin.latitude),\(origin.longitude)"
        let destinationStr = "\(destination.latitude),\(destination.longitude)"
        let apiKey = "AIzaSyC2yPOEWxrF_381zpLA8ZSyUqCMzC3C6nA"

        guard let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(originStr)&destination=\(destinationStr)&mode=driving&departure_time=now&key=\(apiKey)") else { return }
        print(url)

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let routes = json["routes"] as? [[String: Any]],
                   let route = routes.first,
                   let legs = route["legs"] as? [[String: Any]],
                   let leg = legs.first,
                   let duration = leg["duration"] as? [String: Any],
                   let durationText = duration["text"] as? String,
                   let durationValue = duration["value"] as? Double

                {
                    print("Raw JSON Response: \(json)")
//                    let currentDate = Date()
//                    let arrivalDate = currentDate.addingTimeInterval(durationValue)
//                        
//                    let dateFormatter = DateFormatter()
//                    dateFormatter.dateFormat = "hh:mm a"
//                    let arrivalTimeText = dateFormatter.string(from: arrivalDate)
                    print("✅ Estimated Time: \(durationText)")
                    
                    DispatchQueue.main.async {
                        if self.etaLabel == nil {
                           self.setupETALabel()
                        }
                        self.etaLabel?.text = "ETA: \(durationText)"
                    }
                    

                } else {
                    print("❌ Unable to parse ETA information.")
                }


            } catch let error {
                print("Failed to parse JSON: \(error)")
            }
        }.resume()
    }

    private func getBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> CLLocationDegrees {
        let deltaLongitude = end.longitude - start.longitude
        let y = sin(deltaLongitude) * cos(end.latitude)
        let x = cos(start.latitude) * sin(end.latitude) - sin(start.latitude) * cos(end.latitude) * cos(deltaLongitude)
        let bearing = atan2(y, x)
        return (bearing * 180 / .pi).truncatingRemainder(dividingBy: 360) + 180
    }
    
    private func drawRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        
        let originStr = "\(origin.latitude),\(origin.longitude)"
        let destinationStr = "\(destination.latitude),\(destination.longitude)"
        
        let apiKey = "AIzaSyC2yPOEWxrF_381zpLA8ZSyUqCMzC3C6nA"

       
        let urlStr = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originStr)&destination=\(destinationStr)&mode=driving&departure_time=now&key=\(apiKey)"
        
        guard let url = URL(string: urlStr) else { return }
       

        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            
            do {
                let result = try JSONDecoder().decode(DirectionsResponse.self, from: data)
                print("URL: \(url)")
                print("Response Data: \(String(data: url.absoluteString.data(using: .utf8)!, encoding: .utf8) ?? "No Data")")
                print(result)
                guard let route = result.routes.first,
                      let path = GMSPath(fromEncodedPath: route.overviewPolyline.points) else { return }
                
                if result.routes.isEmpty {
                           print("❌ No routes found. Check the origin, destination, or API request.")
                    }
                
                DispatchQueue.main.async {
                    self.routePolyline?.map = nil
                    
                    let polyline = GMSPolyline(path: path)
                    polyline.strokeColor = UIColor(red: 128/255, green: 0, blue: 0, alpha: 1)
                    polyline.strokeWidth = 5.0
                    polyline.map = self.mapView
                    
                    self.routePolyline = polyline
                }
                
            } catch {
                print("❌ Failed to decode directions: \(error)")
            }
        }.resume()
    }
    
    private func adjustCameraToFitRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let bounds = GMSCoordinateBounds(coordinate: origin, coordinate: destination)
        
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
        mapView.animate(with: update)
    }
}




