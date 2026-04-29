//
//  LocationSubBlockDetail.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI
import MapKit

struct LocationSubBlockDetail: View {
    let name: String
    let latitude: Double
    let longitude: Double
    
    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LOCATION")
                .labelStyle()
            
            // Tappable map preview that opens in Apple Maps
            Button {
                openInMaps()
            } label: {
                Map {
                    Marker(name, coordinate: coordinate)
                }
                .frame(height: 180)
                .cornerRadius(8)
                .allowsHitTesting(false)
            }
            .buttonStyle(.plain)
            
            Button {
                openInMaps()
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.paragraph1)
                    Text(name)
                        .font(.paragraph1)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(.blue)
            }
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps()
    }
}
