//
//  RIdeShareViewModel.swift
//  HT_App
//
//  Created by Joy Itodo on 3/1/25.
//

import Foundation

struct Driver: Identifiable, Codable {
    var id: Int
    var name: String
    var car: String
    var inboundHours: String
    var outboundHours: String
    var pictureURL: String?
}

class RideShareViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var message: String = ""
    var currentTime: String = ""

    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"  // Time format without date
        currentTime = dateFormatter.string(from: Date())

        print("Current time: \(currentTime)")
    }

    func fetchDrivers(for rideType: String) {
        print("Fetching drivers for ride type: \(rideType) at time: \(currentTime)")

        let hardcodedDrivers: [Driver] = [
            Driver(id: 1, name: "John Doe", car: "Toyota Camry", inboundHours: "08:00 AM - 12:50 PM", outboundHours: "05:00 PM - 06:00 PM", pictureURL: "https://example.com/johndoe.jpg"),
            Driver(id: 2, name: "Jane Smith", car: "Honda Accord", inboundHours: "09:00 AM - 10:00 AM", outboundHours: "06:00 PM - 07:00 PM", pictureURL: "https://example.com/janesmith.jpg"),
            Driver(id: 3, name: "Chris Johnson", car: "BMW 3 Series", inboundHours: "07:30 AM - 09:30 AM", outboundHours: "04:30 PM - 05:30 PM", pictureURL: "https://example.com/chrisjohnson.jpg"),
            Driver(id: 4, name: "Emily Davis", car: "Ford Focus", inboundHours: "08:30 AM - 12:33 AM", outboundHours: "05:30 PM - 06:30 PM", pictureURL: "https://example.com/emilydavis.jpg")
        ]

        let filteredDrivers: [Driver]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"

        if rideType.lowercased() == "inbound" {
            filteredDrivers = hardcodedDrivers.filter { driver in
                guard let inboundStartTime = dateFormatter.date(from: driver.inboundHours.split(separator: "-")[0].trimmingCharacters(in: .whitespaces)),
                      let inboundEndTime = dateFormatter.date(from: driver.inboundHours.split(separator: "-")[1].trimmingCharacters(in: .whitespaces)) else {
                    print("Failed to parse inbound hours for driver: \(driver.name)")
                    return false
                }

                return currentTime >= dateFormatter.string(from: inboundStartTime) && currentTime <= dateFormatter.string(from: inboundEndTime)
            }
        } else {
            filteredDrivers = hardcodedDrivers.filter { driver in
                guard let outboundStartTime = dateFormatter.date(from: driver.outboundHours.split(separator: "-")[0].trimmingCharacters(in: .whitespaces)),
                      let outboundEndTime = dateFormatter.date(from: driver.outboundHours.split(separator: "-")[1].trimmingCharacters(in: .whitespaces)) else {
                    print("Failed to parse outbound hours for driver: \(driver.name)")
                    return false
                }

                return currentTime >= dateFormatter.string(from: outboundStartTime) && currentTime <= dateFormatter.string(from: outboundEndTime)
            }
        }
        print(filteredDrivers)

        if filteredDrivers.isEmpty {
            self.message = "No drivers available for the selected ride type. Please check the next available time."
        } else {
            self.drivers = filteredDrivers
            self.message = ""
        }
    }
}

