//
//  BlockLayoutEngine.swift
//  journalcalendar
//
//  Calculates block positions on the calendar grid,
//  handling overlapping events with column layout.
//

import Foundation
import CoreGraphics

struct BlockPosition {
    let block: Block
    let column: Int
    let totalColumns: Int
}

struct BlockLayoutEngine {
    let hourHeight: CGFloat
    
    // MARK: - Position Calculation
    
    /// Calculate column positions for all blocks, handling overlaps
    func positions(for blocks: [Block]) -> [BlockPosition] {
        let sortedBlocks = blocks.sorted { $0.startTime < $1.startTime }
        var positions: [BlockPosition] = []
        
        for block in sortedBlocks {
            let overlappingBlocks = sortedBlocks.filter { other in
                blocksOverlap(block, other)
            }
            
            let column = findAvailableColumn(for: block, in: overlappingBlocks, existing: positions)
            let totalColumns = maxColumnsNeeded(for: overlappingBlocks, positions: positions)
            
            positions.append(BlockPosition(
                block: block,
                column: column,
                totalColumns: max(totalColumns, column + 1)
            ))
        }
        
        // Normalize so all blocks in an overlap group share the same totalColumns
        var finalPositions: [BlockPosition] = []
        for position in positions {
            let overlappingBlocks = sortedBlocks.filter { other in
                blocksOverlap(position.block, other)
            }
            let maxColumns = overlappingBlocks.compactMap { block in
                positions.first(where: { $0.block.id == block.id })?.totalColumns
            }.max() ?? 1
            
            finalPositions.append(BlockPosition(
                block: position.block,
                column: position.column,
                totalColumns: maxColumns
            ))
        }
        
        return finalPositions
    }
    
    // MARK: - Size & Offset
    
    /// Height in points for a block based on its duration
    func height(for block: Block) -> CGFloat {
        let duration = block.endTime.timeIntervalSince(block.startTime)
        let hours = duration / 3600
        return max(CGFloat(hours) * hourHeight - 8, 16)
    }
    
    /// Y offset in points for a block based on its start time
    func yOffset(for block: Block) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: block.startTime)
        let minute = calendar.component(.minute, from: block.startTime)
        
        let hourOffset = CGFloat(hour) * hourHeight
        let minuteOffset = (CGFloat(minute) / 60.0) * hourHeight
        
        return hourOffset + minuteOffset
    }
    
    // MARK: - Overlap Detection
    
    func blocksOverlap(_ block1: Block, _ block2: Block) -> Bool {
        return block1.startTime < block2.endTime && block1.endTime > block2.startTime
    }
    
    // MARK: - Private
    
    private func findAvailableColumn(for block: Block, in overlappingBlocks: [Block], existing: [BlockPosition]) -> Int {
        let overlappingPositions = existing.filter { position in
            overlappingBlocks.contains(where: { $0.id == position.block.id }) &&
            blocksOverlap(block, position.block)
        }
        
        var column = 0
        let usedColumns = Set(overlappingPositions.map { $0.column })
        while usedColumns.contains(column) {
            column += 1
        }
        return column
    }
    
    private func maxColumnsNeeded(for overlappingBlocks: [Block], positions: [BlockPosition]) -> Int {
        let overlappingPositions = positions.filter { position in
            overlappingBlocks.contains(where: { $0.id == position.block.id })
        }
        
        if overlappingPositions.isEmpty {
            return 1
        }
        
        return (overlappingPositions.map { $0.column }.max() ?? 0) + 1
    }
}
