//
//  DirectionsResponse.swift
//  HT_App
//
//  Created by Joy Itodo on 2/24/25.
//

import Foundation


struct DirectionsResponse: Codable {
    let routes: [Route]
}

struct Route: Codable {
    let overviewPolyline: OverviewPolyline
    
    enum CodingKeys: String, CodingKey {
        case overviewPolyline = "overview_polyline"
    }
}

struct OverviewPolyline: Codable {
    let points: String
}
