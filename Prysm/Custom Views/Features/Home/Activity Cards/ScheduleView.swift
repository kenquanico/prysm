//
//  ScheduleView.swift
//  Prysm
//
//  Created by Ken Aldrey Quanico on 5/31/26.
//


//
//  ScheduleView.swift
//  Prysm
//

import SwiftUI
import Observation

// MARK: - Root
struct ScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm       = ScheduleViewModel()
    @State private var appeared = false
    @State private var scrollY: CGFloat = 0

    private var barProgress: CGFloat { min(1, max(0, scrollY / 60)) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScheduleScrollOffsetKey.self,
                            value: -geo.frame(in: .named("scheduleScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 72)

                    // ── Title ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Schedule")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(vm.dateString)
                            .font(.system(size: 17))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.04)

                    // ── Day strip ────────────────────────────────
                    ScheduleDayStrip(selected: $vm.selectedDay)
                        .padding(.bottom, 20)
                        .staggeredAppear(appeared, delay: 0.08)

                    // ── Summary card ─────────────────────────────
                    ScheduleSummaryCard(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.12)

                    // ── Timeline ─────────────────────────────────
                    ScheduleTimelineSection(events: vm.events)
                        .padding(.horizontal, 20)
                        .staggeredAppear(appeared, delay: 0.16)

                    Spacer(minLength: 48)
                }
            }
            .coordinateSpace(name: "scheduleScroll")
            .onPreferenceChange(ScheduleScrollOffsetKey.self) { scrollY = $0 }

            // ── Floating bar ─────────────────────────────────────
            ScheduleFloatingBar(barProgress: barProgress) { dismiss() }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

private struct ScheduleScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Floating Bar
struct ScheduleFloatingBar: View {
    let barProgress: CGFloat
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(Double(barProgress))
                .overlay(alignment: .bottom) {
                    Divider().opacity(Double(barProgress) * 0.35)
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 52, height: 52)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())

                    Spacer()

                    VStack(spacing: 1) {
                        Text("Schedule")
                            .font(DS.Font.subheadline())
                            .foregroundColor(DS.Color.textPrimary)
                        Text("Today")
                            .font(DS.Font.caption1())
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    .opacity(Double(barProgress))
                    .animation(.easeInOut(duration: 0.2), value: barProgress)

                    Spacer()

                    Color.clear.frame(width: 52, height: 52)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .frame(height: 64)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Day Strip
struct ScheduleDayStrip: View {
    @Binding var selected: Int

    private let days: [(label: String, num: String)] = {
        let cal = Calendar.current
        let today = Date()
        return (-2...4).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: today)!
            let dayLabel = cal.isDateInToday(d) ? "Today" :
                           DateFormatter().apply { $0.dateFormat = "EEE" }.string(from: d)
            let numLabel = DateFormatter().apply { $0.dateFormat = "d" }.string(from: d)
            return (dayLabel, numLabel)
        }
    }()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Spacer().frame(width: 12)
                ForEach(days.indices, id: \.self) { i in
                    let isSelected = selected == i
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = i
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(days[i].label)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .white : DS.Color.textTertiary)
                            Text(days[i].num)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white : DS.Color.textPrimary)
                        }
                        .frame(width: 56, height: 64)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.teal)
                                    .shadow(color: Color.teal.opacity(0.35), radius: 10, x: 0, y: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(DS.Color.surface)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer().frame(width: 12)
            }
        }
    }
}

// MARK: - Summary Card
struct ScheduleSummaryCard: View {
    let vm: ScheduleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .center, spacing: 20) {
                // Event count ring
                ZStack {
                    ProgressRing(
                        progress: Double(vm.completedEvents) / Double(max(1, vm.totalEvents)),
                        size: 80,
                        lineWidth: 6,
                        trackColor: Color.teal.opacity(0.10),
                        ringColor: Color.teal
                    )
                    VStack(spacing: 0) {
                        Text("\(vm.completedEvents)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text("of \(vm.totalEvents)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SCHEDULE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text("\(vm.remainingEvents) events left")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color.teal)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEXT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text(vm.nextEventTime)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FREE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text(vm.freeTime)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.positive)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .opacity(0.25)
                .padding(.horizontal, 18)

            HStack(spacing: 0) {
                ScheduleSummaryStat(
                    icon: "clock.fill",
                    iconColor: Color.teal,
                    label: "Scheduled",
                    value: vm.scheduledHours
                )
                Divider().frame(height: 36).opacity(0.25)
                ScheduleSummaryStat(
                    icon: "sparkles",
                    iconColor: Color(hex: "F59E0B"),
                    label: "Free Blocks",
                    value: "\(vm.freeBlocks)"
                )
                Divider().frame(height: 36).opacity(0.25)
                ScheduleSummaryStat(
                    icon: "person.2.fill",
                    iconColor: Color(hex: "0EA5E9"),
                    label: "With Others",
                    value: "\(vm.socialEvents)"
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DS.Color.surface)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 3,  x: 0, y: 1)
    }
}

struct ScheduleSummaryStat: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconColor)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(DS.Color.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Timeline Section
struct ScheduleTimelineSection: View {
    let events: [ScheduleEvent]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Timeline") {
                Button("Add") {}
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(uiColor: .systemBlue))
            }

            VStack(spacing: 0) {
                ForEach(events.indices, id: \.self) { idx in
                    ScheduleEventRow(event: events[idx], isLast: idx == events.count - 1)
                }
            }
            .padding(.vertical, DS.Space.sm)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }
}

struct ScheduleEventRow: View {
    let event: ScheduleEvent
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // ── Time column ──────────────────────────────
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.startTime)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(event.isNow ? Color.teal : DS.Color.textTertiary)
                Text(event.endTime)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(DS.Color.textQuaternary)
            }
            .frame(width: 52, alignment: .trailing)
            .padding(.top, 18)

            // ── Timeline spine ───────────────────────────
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.isNow ? Color.teal : (event.isDone ? DS.Color.positive : DS.Color.border))
                        .frame(width: 10, height: 10)
                    if event.isNow {
                        Circle()
                            .fill(Color.teal.opacity(0.25))
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.top, 20)

                if !isLast {
                    Rectangle()
                        .fill(DS.Color.border.opacity(0.5))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 32)

            // ── Event content ────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: event.type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(event.isDone ? DS.Color.textQuaternary : event.type.color)
                        .frame(width: 28, alignment: .center)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(event.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(event.isDone ? DS.Color.textTertiary : DS.Color.textPrimary)
                                .strikethrough(event.isDone, color: DS.Color.textQuaternary)
                            if event.isNow {
                                NowIndicator()
                            }
                        }

                        if let subtitle = event.subtitle {
                            Text(subtitle)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(DS.Color.textSecondary)
                                .lineLimit(1)
                        }

                        HStack(spacing: 6) {
                            Text(event.duration)
                                .font(.system(size: 11))
                                .foregroundColor(DS.Color.textTertiary)

                            if let location = event.location {
                                Text("·")
                                    .foregroundColor(DS.Color.textQuaternary)
                                    .font(.system(size: 11))
                                HStack(spacing: 3) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 10))
                                    Text(location)
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(DS.Color.textTertiary)
                            }
                        }
                        .padding(.top, 2)
                    }

                    Spacer()

                    // Done checkmark
                    ZStack {
                        Circle()
                            .stroke(
                                event.isDone ? DS.Color.positive : DS.Color.border,
                                lineWidth: event.isDone ? 0 : 1.2
                            )
                            .frame(width: 26, height: 26)
                        if event.isDone {
                            Circle()
                                .fill(DS.Color.positive)
                                .frame(width: 26, height: 26)
                                .shadow(color: DS.Color.positive.opacity(0.30), radius: 6, x: 0, y: 2)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)

                // Accent bar if it's a long block
                if event.durationMinutes >= 60 && !event.isDone {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(event.type.color.opacity(0.08))
                        .frame(maxWidth: .infinity)
                        .frame(height: 4)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(event.type.color.opacity(0.4))
                                .frame(width: event.isNow ? 80 : 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Models
struct ScheduleEvent: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let location: String?
    let startTime: String
    let endTime: String
    let duration: String
    let durationMinutes: Int
    let isNow: Bool
    let isDone: Bool
    let type: ScheduleEventType
}

enum ScheduleEventType {
    case meeting, focus, personal, meal, travel

    var icon: String {
        switch self {
        case .meeting:  return "person.2.fill"
        case .focus:    return "brain.head.profile"
        case .personal: return "star.fill"
        case .meal:     return "fork.knife"
        case .travel:   return "car.fill"
        }
    }

    var color: Color {
        switch self {
        case .meeting:  return Color.teal
        case .focus:    return Color.purple
        case .personal: return Color(hex: "F59E0B")
        case .meal:     return Color(hex: "10B981")
        case .travel:   return Color(hex: "0EA5E9")
        }
    }
}

// MARK: - View Model
@Observable
final class ScheduleViewModel {
    var selectedDay: Int = 2   // today (index 2 in -2...4 range)

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    let totalEvents     = 5
    let completedEvents = 2
    var remainingEvents: Int { totalEvents - completedEvents }
    let nextEventTime   = "1:00 PM"
    let freeTime        = "3h 20m"
    let scheduledHours  = "4h 30m"
    let freeBlocks      = 3
    let socialEvents    = 3

    var events: [ScheduleEvent] {
        [
            ScheduleEvent(
                title: "Morning Standup",
                subtitle: "Engineering team sync",
                location: "Zoom",
                startTime: "9:00",
                endTime: "9:30",
                duration: "30m",
                durationMinutes: 30,
                isNow: false,
                isDone: true,
                type: .meeting
            ),
            ScheduleEvent(
                title: "Deep Work",
                subtitle: "Product design sprint",
                location: nil,
                startTime: "10:00",
                endTime: "11:30",
                duration: "1h 30m",
                durationMinutes: 90,
                isNow: false,
                isDone: true,
                type: .focus
            ),
            ScheduleEvent(
                title: "Lunch",
                subtitle: "Break & recharge",
                location: "Canteen",
                startTime: "12:00",
                endTime: "1:00",
                duration: "1h",
                durationMinutes: 60,
                isNow: true,
                isDone: false,
                type: .meal
            ),
            ScheduleEvent(
                title: "Design Review",
                subtitle: "Q2 feature walkthrough",
                location: "Conference Room B",
                startTime: "2:00",
                endTime: "3:00",
                duration: "1h",
                durationMinutes: 60,
                isNow: false,
                isDone: false,
                type: .meeting
            ),
            ScheduleEvent(
                title: "1:1 with Manager",
                subtitle: "Weekly check-in",
                location: "Slack Huddle",
                startTime: "4:00",
                endTime: "4:30",
                duration: "30m",
                durationMinutes: 30,
                isNow: false,
                isDone: false,
                type: .meeting
            ),
        ]
    }
}

// MARK: - DateFormatter helper
private extension DateFormatter {
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { ScheduleView() }
}
