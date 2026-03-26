//
//  MoreEventsPill.swift
//  journalcalendar
//
//  Pill-shaped indicator showing how many events exist
//  above or below the current scroll viewport.
//

import SwiftUI

struct MoreEventsPill: View {
    enum Direction {
        case up, down
        
        var chevronName: String {
            switch self {
            case .up: return "chevron.up"
            case .down: return "chevron.down"
            }
        }
    }
    
    let count: Int
    let direction: Direction
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: direction.chevronName)
                .font(.system(size: 10, weight: .semibold))
            
            Text("\(count) MORE")
                .font(.label)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        MoreEventsPill(count: 2, direction: .down)
        MoreEventsPill(count: 1, direction: .up)
    }
    .padding()
}
