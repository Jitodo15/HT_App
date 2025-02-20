//
//  CalendarView.swift
//  HT_App
//
//  Created by Ayomide Isinkaye on 2/3/25.
//

import Foundation
import SwiftUI

struct Event: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var color: Color
}

struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    @State private var newEventTitle: String = ""
    @State private var isTyping: Bool = false
    @State private var selectedColor: Color = .red
    @State private var events: [Event] = []
    @State private var searchText: String = ""

    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        } else {
            return events.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            // search bar feature
            HStack {
                TextField("Search events...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .opacity(searchText.isEmpty ? 0 : 1)
                }
            }
            .padding(.top)

            // calendar display
            DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()

            // event display under calendar
            List {
                ForEach(filteredEvents) { event in
                    HStack {
                        Circle()
                            .fill(event.color)
                            .frame(width: 10, height: 10)
                        Text(event.title)
                            .fontWeight(.medium)
                    }
                    .onTapGesture {
                        selectedDate = event.date // jump to event data
                        searchText = "" // clear the search
                    }
                }
            }

            Spacer()

            // automatically schedule event from the text bar ebside the plus
            HStack {
                TextField("Add event title & time", text: $newEventTitle, onEditingChanged: { editing in
                    isTyping = editing
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(height: 40)

                ColorPicker("", selection: $selectedColor)
                    .frame(width: 30)

                Button(action: addEvent) {
                    Image(systemName: isTyping ? "checkmark.circle.fill" : "plus.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Calendar")
    }

    // add the event
    private func addEvent() {
        guard !newEventTitle.isEmpty else { return }
        let newEvent = Event(title: newEventTitle, date: selectedDate, color: selectedColor)
        events.append(newEvent)
        newEventTitle = ""
        isTyping = false
        Text("Calendar Page")
    }
}

#Preview {
    CalendarView()
}
