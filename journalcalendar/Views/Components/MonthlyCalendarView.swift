//
//  MonthlyCalendarView.swift
//  journalcalendar
//
//  Monthly calendar grid that scrolls vertically through months.
//

import SwiftUI

struct MonthlyCalendarView: View {
    @Environment(ModelData.self) var modelData
    @Environment(AuthController.self) var auth

    @Binding var isMonthlyView: Bool
    var onDateSelected: (Date) -> Void

    @State private var displayedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showAddBlock = false

    private let calendar = Calendar.current
    private let dayOfWeekHeaders = ["S", "M", "T", "W", "T", "F", "S"]

    /// Generate 24 months: 6 months back + 18 months forward from current month
    private var months: [Date] {
        let today = Date()
        let comps = calendar.dateComponents([.year, .month], from: today)
        guard let currentMonth = calendar.date(from: comps) else { return [] }
        return (-6..<18).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: currentMonth)
        }
    }

    private var dateRange: (start: Date, end: Date) {
        let first = months.first ?? Date()
        let last = months.last ?? Date()
        let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: last) ?? last
        return (first, lastDay)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            dayOfWeekRow
            Divider()

            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: []) {
                            ForEach(months, id: \.self) { month in
                                MonthSection(
                                    month: month,
                                    blocks: modelData.blocks,
                                    onDateSelected: onDateSelected
                                )
                                .id(monthId(month))
                                .onAppear {
                                    updateYear(for: month)
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Scroll to current month
                        let today = Date()
                        let comps = calendar.dateComponents([.year, .month], from: today)
                        if let currentMonth = calendar.date(from: comps) {
                            proxy.scrollTo(monthId(currentMonth), anchor: .top)
                        }
                    }
                    .onChange(of: showAddBlock) { _, _ in }

                    // Today pill
                    Button {
                        let today = Date()
                        let comps = calendar.dateComponents([.year, .month], from: today)
                        if let currentMonth = calendar.date(from: comps) {
                            withAnimation {
                                proxy.scrollTo(monthId(currentMonth), anchor: .top)
                            }
                        }
                    } label: {
                        Text("TODAY")
                            .font(.label)
                            .foregroundStyle(Color("TextPrimary"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color("SecondaryButtonFill"))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color("BG"))
        .task {
            guard let userId = auth.currentUserId else { return }
            let range = dateRange
            await modelData.fetchBlocks(from: range.start, to: range.end, userId: userId)
        }
        .sheet(isPresented: $showAddBlock) {
            AddEventBlock(initialDate: Date())
                .environment(modelData)
                .environment(auth)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { isMonthlyView = false }) {
                Image(systemName: "chevron.left")
                    .font(.body)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Text(String(displayedYear))
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color("TextPrimary"))

            Spacer()

            // Layers icon
            Button(action: {}) {
                Image(systemName: "square.stack.3d.up")
                    .font(.body)
                    .foregroundStyle(Color("TextSecondary"))
            }

            // New block button
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
    }

    // MARK: - Day of Week Row

    private var dayOfWeekRow: some View {
        HStack(spacing: 0) {
            ForEach(dayOfWeekHeaders, id: \.self) { day in
                Text(day)
                    .font(.label)
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func monthId(_ month: Date) -> String {
        let comps = calendar.dateComponents([.year, .month], from: month)
        return "\(comps.year!)-\(comps.month!)"
    }

    private func updateYear(for month: Date) {
        let monthComp = calendar.component(.month, from: month)
        let yearComp = calendar.component(.year, from: month)
        // Update displayed year when January appears
        if monthComp == 1 {
            displayedYear = yearComp
        } else if displayedYear != yearComp {
            displayedYear = yearComp
        }
    }
}

// MARK: - Month Section

private struct MonthSection: View {
    let month: Date
    let blocks: [Block]
    let onDateSelected: (Date) -> Void

    private let calendar = Calendar.current

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: month)
    }

    private var weeks: [[Date?]] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        var comps = calendar.dateComponents([.year, .month], from: month)

        var result: [[Date?]] = []
        var currentWeek: [Date?] = []

        // First day of month
        comps.day = 1
        guard let firstDay = calendar.date(from: comps) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1 = Sunday

        // Pad leading days
        for _ in 0..<(firstWeekday - 1) {
            currentWeek.append(nil)
        }

        for day in range {
            comps.day = day
            let date = calendar.date(from: comps)
            currentWeek.append(date)
            if currentWeek.count == 7 {
                result.append(currentWeek)
                currentWeek = []
            }
        }

        // Pad trailing days
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            result.append(currentWeek)
        }

        return result
    }

    /// Group blocks by their date string for quick lookup
    private var blocksByDate: [String: [Block]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var dict: [String: [Block]] = [:]
        for block in blocks {
            let key = formatter.string(from: block.date)
            dict[key, default: []].append(block)
        }
        return dict
    }

    /// Get multi-day block spans that overlap this month
    private func blocksForDate(_ date: Date) -> [Block] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return blocksByDate[key] ?? []
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Month label - right aligned
            Text(monthName)
                .font(.heading3)
                .foregroundStyle(Color("TextPrimary"))
                .padding(.trailing, 16)
                .padding(.top, 20)
                .padding(.bottom, 8)

            // Weeks grid
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                WeekRow(
                    week: week,
                    blocksByDate: blocksByDate,
                    onDateSelected: onDateSelected
                )
            }
        }
    }
}

// MARK: - Week Row

private struct WeekRow: View {
    let week: [Date?]
    let blocksByDate: [String: [Block]]
    let onDateSelected: (Date) -> Void

    private let calendar = Calendar.current
    private let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Events that need to be displayed on this row
    private var rowEvents: [RowEvent] {
        var events: [RowEvent] = []
        var seen: Set<UUID> = []

        for (colIndex, date) in week.enumerated() {
            guard let date else { continue }
            let key = dateKeyFormatter.string(from: date)
            for block in blocksByDate[key] ?? [] {
                guard !seen.contains(block.id) else { continue }
                seen.insert(block.id)

                // Check if block spans multiple days
                let startDay = calendar.startOfDay(for: block.startTime)
                let endDay = calendar.startOfDay(for: block.endTime)

                if startDay == endDay {
                    // Single-day event
                    events.append(RowEvent(block: block, startCol: colIndex, endCol: colIndex))
                } else {
                    // Multi-day event - clamp to this week
                    let eventEndCol = min(6, colIndex + calendar.dateComponents([.day], from: startDay, to: endDay).day!)
                    events.append(RowEvent(block: block, startCol: colIndex, endCol: min(eventEndCol, 6)))
                }
            }
        }

        return events.sorted { $0.startCol < $1.startCol }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Date numbers
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    if let date = week[index] {
                        let isToday = calendar.isDateInToday(date)
                        Button {
                            onDateSelected(date)
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.paragraph1)
                                .foregroundStyle(isToday ? .white : Color("TextPrimary"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background {
                                    if isToday {
                                        Circle()
                                            .fill(Color("ButtonPrimary"))
                                            .frame(width: 28, height: 28)
                                    }
                                }
                        }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Event pills
            let events = rowEvents
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(events.prefix(3), id: \.block.id) { event in
                        eventPill(event)
                    }
                }
            }
        }
        .padding(.bottom, 4)
        .frame(minHeight: 70, alignment: .top)
    }

    private func eventPill(_ event: RowEvent) -> some View {
        GeometryReader { geo in
            let colWidth = geo.size.width / 7.0
            let xOffset = colWidth * CGFloat(event.startCol)
            let pillWidth = colWidth * CGFloat(event.endCol - event.startCol + 1) - 4

            Text(event.block.title)
                .font(.system(size: 11))
                .foregroundStyle(Color("TextPrimary"))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(width: max(pillWidth, 0), alignment: .leading)
                .background(Color("CardFill"))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .offset(x: xOffset + 2)
        }
        .frame(height: 20)
    }
}

private struct RowEvent {
    let block: Block
    let startCol: Int
    let endCol: Int
}

#Preview {
    MonthlyCalendarView(isMonthlyView: .constant(true), onDateSelected: { _ in })
        .environment(ModelData.preview())
}
