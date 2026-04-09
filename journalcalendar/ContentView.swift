//
//  ContentView.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import SwiftUI

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
        .environment(ModelData.preview())
        .environment(AuthController())
}
