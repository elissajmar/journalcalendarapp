//
//  ContentView.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ModelData.self) var modelData
    
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
}
