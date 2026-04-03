//
//  SubBlock.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import Foundation

/// Represents the types of sub-blocks available to add to an event block.
enum SubBlockType: String, CaseIterable, Identifiable {
    case journal = "Journal"
    case images = "Images"
    case link = "Link"
    case location = "Location"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .journal: return "book"
        case .images: return "photo.on.rectangle"
        case .link: return "link"
        case .location: return "mappin.and.ellipse"
        }
    }
}

/// A sub-block is a modular content section within an event block.
enum SubBlock: Identifiable {
    case journal(id: UUID = UUID(), text: String)
    case images(id: UUID = UUID(), imageData: [Data])
    case link(id: UUID = UUID(), url: String)
    case location(id: UUID = UUID(), name: String, latitude: Double, longitude: Double)
    
    var id: UUID {
        switch self {
        case .journal(let id, _): return id
        case .images(let id, _): return id
        case .link(let id, _): return id
        case .location(let id, _, _, _): return id
        }
    }
    
    var type: SubBlockType {
        switch self {
        case .journal: return .journal
        case .images: return .images
        case .link: return .link
        case .location: return .location
        }
    }
}
