//
//  OffscreenBlockCounter.swift
//  journalcalendar
//
//  Calculates how many blocks are fully outside the visible
//  scroll viewport, above and below.
//

import CoreGraphics

struct OffscreenBlockCounter {
    let layout: BlockLayoutEngine
    
    /// The vertical padding applied by CalendarGridView's .padding(.vertical)
    private let gridVerticalPadding: CGFloat = 16
    
    /// The additional offset applied to each block in CalendarGridView
    private let blockExtraOffset: CGFloat = 8
    
    struct Result {
        let aboveCount: Int
        let belowCount: Int
    }
    
    /// Count how many blocks are fully hidden above or below the viewport.
    ///
    /// - Parameters:
    ///   - blocks: Today's blocks to check
    ///   - scrollOffset: The content offset Y of the scroll view
    ///   - viewportHeight: The visible height of the scroll view
    func count(blocks: [Block], scrollOffset: CGFloat, viewportHeight: CGFloat) -> Result {
        var above = 0
        var below = 0
        
        for block in blocks {
            let blockTop = gridVerticalPadding + layout.yOffset(for: block) + blockExtraOffset
            let blockBottom = blockTop + layout.height(for: block)
            
            let viewTop = scrollOffset
            let viewBottom = scrollOffset + viewportHeight
            
            if blockBottom < viewTop {
                above += 1
            } else if blockTop > viewBottom {
                below += 1
            }
        }
        
        return Result(aboveCount: above, belowCount: below)
    }
}
