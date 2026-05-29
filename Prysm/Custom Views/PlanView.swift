//
//  PlanView.swift
//  Prysm
//

import SwiftUI
import Combine

// MARK: - Plan View
struct PlanView: View {
    @StateObject private var vm = PlanViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    PlanHeaderSection(weekOffset: $vm.weekOffset)
                        .staggeredAppear(appeared, delay: 0.04)

                    WeekStripView(days: vm.weekDays, selected: $vm.selectedDate)
                        .staggeredAppear(appeared, delay: 0.10)

                    PlanHeroSection()
                        .staggeredAppear(appeared, delay: 0.14)

                    DailySummaryGrid(summary: vm.dailySummary)
                        .staggeredAppear(appeared, delay: 0.20)

                    ScheduleSection(blocks: vm.blocksForSelectedDay)
                        .staggeredAppear(appeared, delay: 0.26)

                    if !vm.unscheduled.isEmpty {
                        UnscheduledSection(tasks: vm.unscheduled)
                            .staggeredAppear(appeared, delay: 0.34)
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.base)
                .padding(.top, DS.Space.sm)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - View Model
class PlanViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var weekOffset: Int = 0

    var weekDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let sow = cal.date(from: cal.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: today))!
        let base = cal.date(byAdding: .weekOfYear, value: weekOffset, to: sow)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: base) }
    }

    var blocksForSelectedDay: [PlanBlock] {
        PlanBlock.sampleData.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }

    var unscheduled: [UnscheduledTask] { UnscheduledTask.sampleData }

    var dailySummary: DailySummary {
        let b = blocksForSelectedDay
        let total = b.reduce(0) { $0 + $1.durationMinutes }
        return DailySummary(
            totalBlocks: b.count,
            doneBlocks:  b.filter { $0.isDone }.count,
            totalMinutes: total,
            freeMinutes: max(0, 480 - total)
        )
    }
}

// MARK: - Header
struct PlanHeaderSection: View {
    @Binding var weekOffset: Int

    private var monthYear: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(monthYear)
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textTertiary)
                Text("Weekly Plan")
                    .font(DS.Font.title1())
                    .foregroundColor(DS.Color.textPrimary)
            }
            Spacer()
            HStack(spacing: 10) {
                NavButton(icon: "chevron.left") {
                    withAnimation(DS.Animation.standard) { weekOffset -= 1 }
                }
                NavButton(icon: "chevron.right") {
                    withAnimation(DS.Animation.standard) { weekOffset += 1 }
                }
            }
        }
        .padding(.top, DS.Space.sm)
    }
}

struct NavButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.Color.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    // 20pt continuous = Apple-standard squircle for floating icon buttons
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(DS.Color.surface)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Week Strip
struct WeekStripView: View {
    let days: [Date]
    @Binding var selected: Date

    private let cal = Calendar.current
    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                let isSelected = cal.isDate(day, inSameDayAs: selected)
                let isToday    = cal.isDateInToday(day)
                let dayNum     = cal.component(.day, from: day)

                Button {
                    withAnimation(DS.Animation.snappy) { selected = day }
                } label: {
                    VStack(spacing: DS.Space.xs) {
                        Text(dayLetters[safe: idx] ?? "")
                            .font(DS.Font.caption2())
                            .foregroundColor(isSelected ? DS.Color.accent : DS.Color.textTertiary)

                        ZStack {
                            if isSelected {
                                // Circle is the correct squircle at 1:1 aspect ratio
                                Circle()
                                    .fill(DS.Color.accent)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: DS.Color.accent.opacity(0.35), radius: 8, x: 0, y: 3)
                            } else if isToday {
                                Circle()
                                    .fill(DS.Color.accentSoft)
                                    .frame(width: 32, height: 32)
                            }
                            Text("\(dayNum)")
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(
                                    isSelected ? .white :
                                    isToday    ? DS.Color.accent :
                                    DS.Color.textPrimary
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DS.Space.md)
        .padding(.horizontal, DS.Space.sm)
        .background(
            // 20pt continuous — Apple's standard panel/card radius for mid-size containers
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DS.Color.surface)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Plan Hero Section
// MARK: - Plan Hero Section
struct PlanHeroSection: View {

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            ZStack(alignment: .bottomLeading) {

                // 1. Flat base color — nothing else on the surface
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "4eabae"))

                // 2. Content
                VStack(alignment: .leading, spacing: 0) {

                    Text("Custom Plan")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Spacer(minLength: 10)

                    Text("Your activities, focus blocks,\ndays of the week, and more.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.74))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 32)

                    HStack {
                        Spacer()
                        Text("Let's get started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(uiColor: .systemBlue))
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .padding(24)
            }
            .frame(height: 248)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            // This is where ALL the depth comes from
            .shadow(color: Color(hex: "4eabae").opacity(0.45), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)        }
    }
}
struct DailySummaryGrid: View {
    let summary: DailySummary

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            PlanStatCard(
                icon: "square.stack.fill",
                value: "\(summary.totalBlocks)",
                label: "blocks",
                sublabel: "total today",
                accent: DS.Color.accent
            )
            PlanStatCard(
                icon: "checkmark.circle.fill",
                value: "\(summary.doneBlocks)",
                label: "done",
                sublabel: "completed",
                accent: DS.Color.positive
            )
            PlanStatCard(
                icon: "clock.fill",
                value: formatMin(summary.totalMinutes),
                label: "scheduled",
                sublabel: "blocked time",
                accent: DS.Color.warning
            )
            PlanStatCard(
                icon: "wind",
                value: formatMin(summary.freeMinutes),
                label: "free",
                sublabel: "open time",
                accent: DS.Color.textTertiary
            )
        }
    }

    private func formatMin(_ m: Int) -> String {
        m < 60 ? "\(m)m" : "\(m / 60)h\(m % 60 > 0 ? " \(m % 60)m" : "")"
    }
}

struct PlanStatCard: View {
    let icon: String
    let value: String
    let label: String
    let sublabel: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top row: icon + chevron
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DS.Color.textTertiary.opacity(0.6))
            }

            Spacer()

            // Big value
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DS.Color.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Spacer(minLength: 3)

            // Label
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.Color.textPrimary)

            // Sublabel
            Text(sublabel)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(DS.Color.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 136)
        .background(
            // 20pt continuous = Apple widget/card squircle (Home Screen widget standard)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Schedule Section
struct ScheduleSection: View {
    let blocks: [PlanBlock]

    var body: some View {
        VStack(spacing: DS.Space.md) {
            HStack {
                Text("Schedule")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                Button {
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        // Capsule is the correct fully-continuous pill shape — preserve
                        Capsule()
                            .fill(Color(uiColor: .systemBlue))
                    )
                    .shadow(color: Color(uiColor: .systemBlue).opacity(0.30), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }

            if blocks.isEmpty {
                EmptyScheduleView()
            } else {
                VStack(spacing: 0) {
                    ForEach(blocks.indices, id: \.self) { idx in
                        PlanBlockRow(block: blocks[idx])
                        if idx < blocks.count - 1 {
                            Divider()
                                .padding(.leading, 64)
                                .opacity(0.25)
                        }
                    }
                }
                .background(
                    // 20pt continuous for list container panel
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(DS.Color.surface)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            }
        }
    }
}

struct PlanBlockRow: View {
    let block: PlanBlock

    var body: some View {
        HStack(spacing: 14) {

            // Time column
            VStack(alignment: .trailing, spacing: 2) {
                Text(block.startTime)
                    .font(DS.Font.mono(11))
                    .foregroundColor(DS.Color.textTertiary)
                Text(block.endTime)
                    .font(DS.Font.mono(10))
                    .foregroundColor(DS.Color.textQuaternary)
            }
            .frame(width: 38, alignment: .trailing)

            // Category color bar — 3pt continuous pill
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    block.isDone
                        ? DS.Color.textQuaternary.opacity(0.4)
                        : block.category.color
                )
                .frame(width: 3, height: 36)

            // Icon
            Image(systemName: block.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(
                    block.isDone
                        ? DS.Color.textQuaternary
                        : block.category.color
                )
                .frame(width: 30, alignment: .center)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(block.isDone ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .strikethrough(block.isDone, color: DS.Color.textQuaternary)
                Text(block.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(DS.Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Duration chip — 8pt continuous at compact scale
            Text(block.duration)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.Color.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DS.Color.textTertiary.opacity(0.08))
                )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}

struct EmptyScheduleView: View {
    var body: some View {
        VStack(spacing: DS.Space.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundColor(DS.Color.textQuaternary)
            Text("Nothing scheduled")
                .font(DS.Font.subheadline())
                .foregroundColor(DS.Color.textTertiary)
            Text("Tap Add to plan your day")
                .font(DS.Font.footnote())
                .foregroundColor(DS.Color.textQuaternary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.xxl)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DS.Color.surface)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 5)
    }
}

// MARK: - Unscheduled Section
struct UnscheduledSection: View {
    let tasks: [UnscheduledTask]

    var body: some View {
        VStack(spacing: DS.Space.md) {
            HStack {
                Text("Unscheduled")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                // Count badge — 12pt continuous chip
                Text("\(tasks.count) tasks")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.Color.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Color.textTertiary.opacity(0.08))
                    )
            }

            VStack(spacing: 0) {
                ForEach(tasks.indices, id: \.self) { idx in
                    HStack(spacing: 14) {

                        Image(systemName: tasks[idx].icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(DS.Color.textSecondary)
                            .frame(width: 30, alignment: .center)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tasks[idx].title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(DS.Color.textPrimary)
                            Text("~\(tasks[idx].estimatedMinutes) min")
                                .font(.system(size: 12))
                                .foregroundColor(DS.Color.textSecondary)
                        }

                        Spacer()

                        PriorityBadge(level: tasks[idx].priority.badge)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, DS.Space.base)
                    .contentShape(Rectangle())

                    if idx < tasks.count - 1 {
                        Divider()
                            .padding(.leading, 64)
                            .opacity(0.25)
                    }
                }
            }
            .background(
                // 20pt continuous list container panel
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - surfaceCard modifier (updated for continuous geometry)
// If surfaceCard is defined as a ViewModifier elsewhere, update its internals to match:
//
// struct SurfaceCardModifier: ViewModifier {
//     var padding: CGFloat
//     func body(content: Content) -> some View {
//         content
//             .padding(padding)
//             .background(
//                 RoundedRectangle(cornerRadius: 20, style: .continuous)
//                     .fill(DS.Color.surface)
//             )
//             .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//             .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
//             .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
//     }
// }
