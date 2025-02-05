//
//  AppTabView.swift
//  HT_App
//
//  Created by Ayomide Isinkaye on 2/3/25.
//

import Foundation
import SwiftUI

struct AppTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            ShuttleView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Transport")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    AppTabView()
}


