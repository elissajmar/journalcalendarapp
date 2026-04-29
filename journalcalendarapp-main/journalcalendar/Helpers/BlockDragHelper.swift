//
//  BlockDragHelper.swift
//  journalcalendar
//
//  Handles drag-to-reschedule math: pixel-to-time conversion,
//  15-minute snapping, and new time calculation.
//

import Foundation
import CoreGraphics

struct BlockDragHelper {
    let hourHeight: CGFloat
    
    /// Snap a raw pixel offset to the nearest 15-minute increment (in pixels)
    func snappedOffset(from dragOffset: CGFloat) -> CGFloat {
        let snappedMinutes = snappedMinutesDelta(from: dragOffset)
        return (snappedMinutes / 60) * hourHeight
    }
    
    /// The snapped Y position for a block being dragged
    func snappedDropY(for block: Block, dragOffset: CGFloat, baseYOffset: CGFloat) -> CGFloat {
        return baseYOffset + snappedOffset(from: dragOffset)
    }
    
    /// Format the snapped drop time as HH:mm (24-hour, no AM/PM)
    func snappedTimeLabel(for block: Block, dragOffset: CGFloat) -> String {
        let snappedMinutes = snappedMinutesDelta(from: dragOffset)
        let newStartTime = block.startTime.addingTimeInterval(snappedMinutes * 60)
        return DateFormatters.time24h.string(from: newStartTime)
    }
    
    /// Calculate the new start and end times after a drag completes.
    /// Returns nil if the snap results in no change.
    func newTimes(for block: Block, translation: CGFloat) -> (start: Date, end: Date)? {
        let snappedMinutes = snappedMinutesDelta(from: translation)
        let timeInterval = snappedMinutes * 60
        
        guard timeInterval != 0 else { return nil }
        
        let newStart = block.startTime.addingTimeInterval(timeInterval)
        let newEnd = block.endTime.addingTimeInterval(timeInterval)
        return (newStart, newEnd)
    }
    
    // MARK: - Private
    
    private func snappedMinutesDelta(from dragOffset: CGFloat) -> CGFloat {
        let minutesDelta = (dragOffset / hourHeight) * 60
        return (minutesDelta / 15).rounded() * 15
    }
}
