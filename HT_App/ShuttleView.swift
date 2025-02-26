//
//  ShuttleView.swift
//  HT_App
//
//  Created by Ayomide Isinkaye on 2/3/25.
//

import Foundation
import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapViewController {
        return MapViewController()
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {}
}

struct ShuttleView: View {
    var body: some View {
        MapViewRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ShuttleView()
    
}

