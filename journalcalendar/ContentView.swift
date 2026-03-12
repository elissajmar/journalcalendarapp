//
//  ContentView.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Calendar Journal")
                    .font(.largeTitle)
                    .padding()
                
                Text("Data models are ready!")
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
