//
//  CalendarGridView.swift
//  journalcalendar
//
//  The scrollable calendar grid with time slots and event block overlays.
//

import SwiftUI

struct CalendarGridView: View {
    var blocks: [Block]
    @Binding var hourHeight: CGFloat
    var onBlockTapped: (Block) -> Void
    var onBlockDragFinished: (Block, CGFloat) -> Void
    
    private var layout: BlockLayoutEngine { BlockLayoutEngine(hourHeight: hourHeight) }
    private var drag: BlockDragHelper { BlockDragHelper(hourHeight: hourHeight) }
    
    @State private var draggingBlockId: UUID? = nil
    @State private var dragOffset: CGFloat = 0

    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background grid with fixed heights
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        Text(DateFormatters.hourLabel(for: hour))
                            .labelStyle()
                            .frame(width: 60, alignment: .trailing)
                            .padding(.trailing, 12)
                        
                        VStack {
                            Divider()
                                .padding(.trailing, 16)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: hourHeight)
                    }
                    .id(hour)
                }
            }
            
            // Snap time indicator shown during drag
            if let dragBlock = draggingBlock {
                let snappedY = drag.snappedDropY(for: dragBlock, dragOffset: dragOffset, baseYOffset: layout.yOffset(for: dragBlock)) + 8
                Text(drag.snappedTimeLabel(for: dragBlock, dragOffset: dragOffset))
                    .font(.label)
                    .foregroundStyle(Color.accentColor)
                    .textCase(.uppercase)
                    .frame(width: 60, alignment: .trailing)
                    .padding(.trailing, 12)
                    .offset(y: snappedY - 2)
            }
            
            // Event blocks overlaid on top
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 72)
                
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        // Ghost placeholders for dragging blocks
                        ForEach(Array(blockPositions.enumerated()), id: \.offset) { _, position in
                            if draggingBlockId == position.block.id {
                                let baseY = layout.yOffset(for: position.block) + 8
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                                    .opacity(0.5)
                                    .frame(width: geometry.size.width / CGFloat(position.totalColumns))
                                    .frame(height: layout.height(for: position.block))
                                    .offset(
                                        x: (geometry.size.width / CGFloat(position.totalColumns)) * CGFloat(position.column),
                                        y: baseY
                                    )
                                    .padding(.trailing, 4)
                            }
                        }
                        
                        // Actual event blocks
                        ForEach(Array(blockPositions.enumerated()), id: \.offset) { _, position in
                            let isDragging = draggingBlockId == position.block.id
                            let baseY = layout.yOffset(for: position.block) + 8
                            let currentY = isDragging ? baseY + dragOffset : baseY
                            
                            EventBlock(block: position.block) {
                                onBlockTapped(position.block)
                            }
                            .frame(width: geometry.size.width / CGFloat(position.totalColumns))
                            .frame(height: layout.height(for: position.block))
                            .offset(
                                x: (geometry.size.width / CGFloat(position.totalColumns)) * CGFloat(position.column),
                                y: currentY
                            )
                            .shadow(color: isDragging ? .black.opacity(0.15) : .clear, radius: 8, y: 4)
                            .zIndex(isDragging ? 1 : 0)
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.3)
                                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("calendarGrid")))
                                    .onChanged { value in
                                        switch value {
                                        case .second(true, let drag):
                                            if let drag = drag {
                                                draggingBlockId = position.block.id
                                                dragOffset = drag.translation.height
                                            }
                                        default:
                                            break
                                        }
                                    }
                                    .onEnded { value in
                                        switch value {
                                        case .second(true, let drag):
                                            let translation = drag?.translation.height ?? 0
                                            finishDrag(for: position.block, translation: translation)
                                        default:
                                            draggingBlockId = nil
                                            dragOffset = 0
                                        }
                                    }
                            )
                        }
                    }
                }
                
                Spacer()
                    .frame(width: 16)
            }
        }
        .padding(.vertical)
        .coordinateSpace(name: "calendarGrid")
    }
    
    // MARK: - Helpers
    
    private var hours: [Int] { Array(0...23) }
    
    private var blockPositions: [BlockPosition] {
        layout.positions(for: blocks)
    }
    
    private var draggingBlock: Block? {
        guard let id = draggingBlockId else { return nil }
        return blocks.first { $0.id == id }
    }
    
    private func finishDrag(for block: Block, translation: CGFloat) {
        onBlockDragFinished(block, translation)
        draggingBlockId = nil
        dragOffset = 0
    }
}
