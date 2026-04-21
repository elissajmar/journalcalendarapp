//
//  ThreeDayCalendarGridView.swift
//  journalcalendar
//
//  Calendar grid showing 3 consecutive days side by side.
//  Time labels are pinned on the left; each day column slides independently.
//

import SwiftUI

struct ThreeDayCalendarGridView: View {
    var dates: [Date]       // exactly 3 dates
    var allBlocks: [Block]
    @Binding var hourHeight: CGFloat
    var onBlockTapped: (Block) -> Void

    private var layout: BlockLayoutEngine { BlockLayoutEngine(hourHeight: hourHeight) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Layer 1: Hour divider lines (full width, no labels)
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        Spacer().frame(width: 72)
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

            // Layer 2: Three day columns of event blocks
            HStack(spacing: 0) {
                Spacer().frame(width: 72)
                GeometryReader { geometry in
                    let colWidth = geometry.size.width / 3
                    ZStack(alignment: .topLeading) {
                        ForEach(0..<min(3, dates.count), id: \.self) { col in
                            let dayBlocks = blocks(for: dates[col])
                            ForEach(dayBlocks) { block in
                                EventBlock(block: block) {
                                    onBlockTapped(block)
                                }
                                .frame(width: colWidth - 8)
                                .frame(height: layout.height(for: block))
                                .offset(
                                    x: colWidth * CGFloat(col) + 4,
                                    y: layout.yOffset(for: block) + 8
                                )
                            }
                        }
                    }
                }
                Spacer().frame(width: 16)
            }

            // Layer 3: Time labels with opaque background — always above event blocks
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    Text(DateFormatters.hourLabel(for: hour))
                        .labelStyle()
                        .frame(width: 60, alignment: .trailing)
                        .padding(.trailing, 12)
                        .frame(height: hourHeight, alignment: .top)
                }
            }
            .frame(width: 72)
            .background(Color("BG"))
            .allowsHitTesting(false)
        }
        .padding(.vertical)
        .coordinateSpace(name: "threeDayGrid")
    }

    // MARK: - Helpers

    private var hours: [Int] { Array(0...23) }

    private func blocks(for date: Date) -> [Block] {
        let calendar = Calendar.current
        return allBlocks.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }
}
