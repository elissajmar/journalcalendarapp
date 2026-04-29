//
//  LocationSearchService.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import Foundation
import MapKit

@Observable
class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
        }
    }
    var results: [MKLocalSearchCompletion] = []
    
    private let completer: MKLocalSearchCompleter
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
    
    /// Resolves a search completion into a coordinate and place name.
    func resolve(_ completion: MKLocalSearchCompletion) async -> (name: String, coordinate: CLLocationCoordinate2D)? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return nil }
            let name = [completion.title, completion.subtitle]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            return (name: name, coordinate: item.placemark.coordinate)
        } catch {
            return nil
        }
    }
}
