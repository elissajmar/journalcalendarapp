//
//  LocationSubBlockEdit.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI
import MapKit

struct LocationSubBlockEdit: View {
    @Binding var locationName: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var isExpanded: Bool
    var onRemove: () -> Void
    
    @State private var searchService = LocationSearchService()
    @State private var isSearching = false
    
    private var hasLocation: Bool {
        latitude != 0 || longitude != 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("LOCATION")
                        .labelStyle()
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            onRemove()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if hasLocation && !isSearching {
                        // Show selected location with map preview
                        selectedLocationView
                    } else {
                        // Search field
                        searchView
                    }
                }
            }
        }
    }
    
    // MARK: - Selected Location View
    
    private var selectedLocationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Map preview
            Map {
                Marker(locationName, coordinate: CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                ))
            }
            .frame(height: 180)
            .cornerRadius(8)
            .allowsHitTesting(false)
            
            // Location name + change button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(locationName)
                        .font(.paragraph1)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    isSearching = true
                    searchService.queryFragment = ""
                } label: {
                    Text("Change")
                        .labelStyle()
                }
            }
        }
    }
    
    // MARK: - Search View
    
    private var searchView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search for a place", text: $searchService.queryFragment)
                .font(.paragraph1)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
            
            if !searchService.results.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(searchService.results.prefix(5), id: \.self) { completion in
                        Button {
                            selectCompletion(completion)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                    .font(.paragraph1)
                                    .foregroundStyle(.primary)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .labelStyle()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                        
                        if completion != searchService.results.prefix(5).last {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        Task {
            if let result = await searchService.resolve(completion) {
                locationName = result.name
                latitude = result.coordinate.latitude
                longitude = result.coordinate.longitude
                isSearching = false
                searchService.queryFragment = ""
            }
        }
    }
}
