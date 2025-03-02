//
//  TransportationView.swift
//  HT_App
//
//  Created by Joy Itodo on 2/25/25.
//

import SwiftUI

struct TransportationView: View {
    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                Text("Transportation")
                    .font(.largeTitle)
                    .bold()
                Text("Track your shuttle or find a ride share")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer().frame(height: 20)
        
                NavigationLink(destination: ShuttleView()) {
                    TransportationOptionView(title: "Track Shuttle")
                }
                Divider()
                    .background(Color.maroon)
                
                NavigationLink(destination: RideShareView()) {
                    TransportationOptionView(title: "Find Ride Share")
                }
                Spacer()
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline)
        }
    }
}

struct TransportationOptionView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(Color.maroon)
        }
        
        .padding([.top, .bottom], 10)
    }
}

extension Color {
    static let maroon = Color(red: 128/255, green: 0, blue: 0)
}

#Preview{
    TransportationView()
}
