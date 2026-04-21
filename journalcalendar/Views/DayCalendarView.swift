//
//  DayCalendarView.swift
//  journalcalendar
//
//  The 1-day and 3-day calendar views with header, time grid, and event blocks.
//

import SwiftUI

struct DayCalendarView: View {
    @Environment(ModelData.self) var modelData
    @Environment(AuthController.self) var auth

    @Binding var isMonthlyView: Bool
    @Binding var selectedBlockId: UUID?
    @Binding var showAddBlock: Bool

    @State private var dayNav = DayNavigator()
    @State private var is3DayView = false

    @State private var hourHeight: CGFloat = 120
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    private var drag: BlockDragHelper { BlockDragHelper(hourHeight: hourHeight) }

    private var offscreenCounts: OffscreenBlockCounter.Result {
        let counter = OffscreenBlockCounter(layout: BlockLayoutEngine(hourHeight: hourHeight))
        return counter.count(blocks: todaysBlocks, scrollOffset: scrollOffset, viewportHeight: viewportHeight)
    }

    /// Called by HomeView when returning from monthly view with a specific date
    var initialDate: Date?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    if is3DayView {
                        ThreeDayCalendarGridView(
                            dates: threeDates,
                            allBlocks: modelData.blocks,
                            hourHeight: $hourHeight,
                            onBlockTapped: { block in selectedBlockId = block.id }
                        )
                        .pinchToZoom(hourHeight: $hourHeight, min: 40, max: 240)
                    } else {
                        CalendarGridView(
                            blocks: todaysBlocks,
                            hourHeight: $hourHeight,
                            selectedDate: dayNav.selectedDate,
                            slideTransition: dayNav.slideTransition,
                            onBlockTapped: { block in
                                selectedBlockId = block.id
                            },
                            onBlockDragFinished: { block, translation in
                                finishDrag(for: block, translation: translation)
                            }
                        )
                        .pinchToZoom(hourHeight: $hourHeight, min: 40, max: 240)
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y + geo.contentInsets.top
                } action: { _, newValue in
                    scrollOffset = newValue
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.visibleRect.height
                } action: { _, newValue in
                    viewportHeight = newValue
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 40, coordinateSpace: .local)
                        .onEnded { value in
                            let h = value.translation.width
                            let v = value.translation.height
                            guard abs(h) > abs(v) * 2 else { return }
                            let step = is3DayView ? 3 : 1
                            if h < 0 {
                                dayNav.advance(days: step)
                            } else {
                                dayNav.advance(days: -step)
                            }
                        }
                )
                .onAppear {
                    proxy.scrollTo(8, anchor: .top)
                }
                .onChange(of: dayNav.selectedDate) { _, _ in
                    proxy.scrollTo(8, anchor: .top)
                }
            }
            .overlay(alignment: .top) {
                if !is3DayView && offscreenCounts.aboveCount > 0 {
                    MoreEventsPill(count: offscreenCounts.aboveCount, direction: .up)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .bottom) {
                if !is3DayView && offscreenCounts.belowCount > 0 {
                    MoreEventsPill(count: offscreenCounts.belowCount, direction: .down)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: offscreenCounts.aboveCount)
            .animation(.easeInOut(duration: 0.25), value: offscreenCounts.belowCount)
        }
        .background(Color("BG"))
        .task(id: "\(is3DayView)-\(Int(dayNav.selectedDate.timeIntervalSince1970))") {
            guard let userId = auth.currentUserId else { return }
            if is3DayView {
                await modelData.fetchBlocks(for: threeDates, userId: userId)
            } else {
                await modelData.fetchBlocks(for: dayNav.selectedDate, userId: userId)
            }
        }
        .onAppear {
            if let initialDate {
                dayNav.selectedDate = initialDate
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isMonthlyView = true
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .foregroundStyle(Color("TextSecondary"))
                }

                Text(monthName(from: dayNav.selectedDate))
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                Button(action: { is3DayView.toggle() }) {
                    Text(is3DayView ? "3 Day" : "1 Day")
                        .font(.label)
                        .foregroundStyle(Color("TextPrimary"))
                        .textCase(.none)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color("SecondaryButtonFill"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: {}) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.body)
                        .foregroundStyle(Color("TextSecondary"))
                }

                Button(action: { showAddBlock = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("New")
                    }
                    .font(.label)
                    .textCase(.none)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color("ButtonPrimary"))
                    .foregroundStyle(Color("TextPrimaryLight"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            if is3DayView {
                HStack(spacing: 0) {
                    Spacer().frame(width: 72)
                    ForEach(Array(threeDates.enumerated()), id: \.offset) { _, date in
                        Text(dayLabel(from: date))
                            .font(.label)
                            .foregroundStyle(Color("TextSecondary"))
                            .frame(maxWidth: .infinity)
                    }
                    Spacer().frame(width: 16)
                }
                .padding(.vertical, 8)
                .id(dayNav.selectedDate)
                .transition(dayNav.slideTransition)
            } else {
                Text(dayLabel(from: dayNav.selectedDate))
                    .font(.label)
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .id(dayNav.selectedDate)
                    .transition(dayNav.slideTransition)
            }

            Divider()
        }
    }

    // MARK: - Helpers

    private var threeDates: [Date] {
        (0..<3).map { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: dayNav.selectedDate) ?? dayNav.selectedDate
        }
    }

    private var todaysBlocks: [Block] {
        let calendar = Calendar.current
        return modelData.blocks.filter { block in
            calendar.isDate(block.startTime, inSameDayAs: dayNav.selectedDate)
        }
    }

    private func monthName(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: date)
    }

    private func dayLabel(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE d"
        return f.string(from: date).uppercased()
    }

    private func finishDrag(for block: Block, translation: CGFloat) {
        guard let newTimes = drag.newTimes(for: block, translation: translation) else {
            return
        }
        guard let userId = auth.currentUserId else { return }

        Task {
            await modelData.updateBlock(
                id: block.id,
                title: block.title,
                startTime: newTimes.start,
                endTime: newTimes.end,
                subBlocks: block.subBlocks,
                userId: userId
            )
        }
    }
}
