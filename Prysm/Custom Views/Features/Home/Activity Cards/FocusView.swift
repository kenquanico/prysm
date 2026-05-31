//
//  FocusView.swift
//  Prysm
//

import SwiftUI
import Observation

// MARK: - Root
struct FocusView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm       = FocusViewModel()
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
                            key: FocusScrollOffsetKey.self,
                            value: -geo.frame(in: .named("focusScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 72)

                    // ── Title ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Focus")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(vm.periodSubtitle)
                            .font(.system(size: 17))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.04)

                    // ── Segmented control ────────────────────────
                    HStack {
                        Spacer()
                        FocusSegmentedControl(selected: $vm.selectedPeriod)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.08)

                    // ── Summary hero card ────────────────────────
                    FocusSummaryCard(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.12)

                    // ── Metric cards ─────────────────────────────
                    VStack(spacing: 16) {
                        ForEach(vm.metricCards) { card in
                            FocusMetricCard(card: card, period: vm.selectedPeriod)
                        }
                    }
                    .padding(.horizontal, 20)
                    .staggeredAppear(appeared, delay: 0.16)

                    // ── Session log ──────────────────────────────
                    FocusSessionLog(sessions: vm.recentSessions)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .staggeredAppear(appeared, delay: 0.20)

                    Spacer(minLength: 48)
                }
            }
            .coordinateSpace(name: "focusScroll")
            .onPreferenceChange(FocusScrollOffsetKey.self) { scrollY = $0 }

            // ── Floating bar ─────────────────────────────────────
            FocusFloatingBar(barProgress: barProgress) { dismiss() }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

private struct FocusScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Floating Bar
struct FocusFloatingBar: View {
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
                        Text("Focus")
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

// MARK: - Segmented Control
struct FocusSegmentedControl: View {
    @Binding var selected: FocusPeriod

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(FocusPeriod.allCases) { period in
                    segmentItem(period)
                }
            }
            .glassEffect(in: Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func segmentItem(_ period: FocusPeriod) -> some View {
        let isActive = selected == period

        let label = Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = period
            }
        } label: {
            Text(period.rawValue)
                .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm)
        }
        .buttonStyle(.plain)

        if isActive {
            label.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            label
        }
    }
}

// MARK: - Period
enum FocusPeriod: String, CaseIterable, Identifiable {
    case day = "D", week = "W", month = "M", year = "Y"
    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .day:   return "Today"
        case .week:  return "This Week"
        case .month: return "This Month"
        case .year:  return "This Year"
        }
    }

    var timeLabels: [String] {
        switch self {
        case .day:   return ["12 AM", "6 AM", "12 PM", "6 PM"]
        case .week:  return ["Mon", "Wed", "Fri", "Sun"]
        case .month: return ["1", "8", "16", "24", "30"]
        case .year:  return ["Jan", "Apr", "Jul", "Oct"]
        }
    }
}

// MARK: - Summary Hero Card
struct FocusSummaryCard: View {
    let vm: FocusViewModel

    private let accent = Color.purple

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top: big time + ring
            HStack(alignment: .center, spacing: 20) {
                // Concentric rings
                ZStack {
                    // Outer ring: goal progress
                    ProgressRing(
                        progress: vm.goalProgress,
                        size: 90,
                        lineWidth: 6,
                        trackColor: Color.purple.opacity(0.10),
                        ringColor: Color.purple
                    )
                    // Inner ring: flow score
                    ProgressRing(
                        progress: vm.flowScore,
                        size: 70,
                        lineWidth: 5,
                        trackColor: Color.indigo.opacity(0.10),
                        ringColor: Color.indigo
                    )
                    VStack(spacing: 0) {
                        Text("\(vm.deepWorkHours)h")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text("\(vm.deepWorkMinutes)m")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DEEP WORK")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text("2h 15m today")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(accent)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GOAL")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text("4h 00m")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FLOW")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text("\(Int(vm.flowScore * 100))%")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.indigo)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Divider
            Divider()
                .opacity(0.25)
                .padding(.horizontal, 18)

            // Bottom: peak window + streak
            HStack(spacing: 0) {
                FocusSummaryStat(
                    icon: "bolt.fill",
                    iconColor: Color(hex: "F59E0B"),
                    label: "Peak Window",
                    value: "9–11 AM"
                )
                Divider()
                    .frame(height: 36)
                    .opacity(0.25)
                FocusSummaryStat(
                    icon: "flame.fill",
                    iconColor: Color(hex: "EF4444"),
                    label: "Streak",
                    value: "7 days"
                )
                Divider()
                    .frame(height: 36)
                    .opacity(0.25)
                FocusSummaryStat(
                    icon: "brain.head.profile",
                    iconColor: Color.purple,
                    label: "Sessions",
                    value: "3 today"
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

struct FocusSummaryStat: View {
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

// MARK: - Metric Card
struct FocusMetricCard: View {
    let card: FocusCardData
    let period: FocusPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 6) {
                Text(card.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Color.textSecondary)
                    .tracking(0.5)

                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(card.valueString)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(card.accentColor)
                    if let unit = card.unit {
                        Text(unit)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(card.accentColor)
                    }
                }

                if let delta = card.delta {
                    HStack(spacing: 4) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(delta >= 0 ? "+" : "")\(delta)% vs last period")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(delta >= 0 ? DS.Color.positive : DS.Color.negative)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 16)

            FocusGridChart(
                bars: card.bars(for: period),
                accentColor: card.accentColor,
                timeLabels: period.timeLabels
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DS.Color.surface)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 3,  x: 0, y: 1)
    }
}

// MARK: - Grid Chart (mirrors StepsGridChart)
struct FocusGridChart: View {
    let bars: [Double]
    let accentColor: Color
    let timeLabels: [String]

    private let gridRows = 2
    private let chartH: CGFloat = 120

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack(alignment: .bottomLeading) {

                    ForEach(0...gridRows, id: \.self) { row in
                        let y = h * CGFloat(row) / CGFloat(gridRows)
                        Path { p in
                            p.move(to:    CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(
                            DS.Color.border.opacity(0.7),
                            style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                        )
                    }

                    ForEach(timeLabels.indices, id: \.self) { col in
                        let x = col == 0 ? 0 :
                            w * CGFloat(col) / CGFloat(max(1, timeLabels.count - 1))
                        Path { p in
                            p.move(to:    CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: h))
                        }
                        .stroke(
                            DS.Color.border.opacity(0.7),
                            style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                        )
                    }

                    if bars.contains(where: { $0 > 0 }) {
                        let count = CGFloat(bars.count)
                        let gap: CGFloat = bars.count > 20 ? 1.5 : 3
                        let barW = (w - (count - 1) * gap) / count

                        HStack(alignment: .bottom, spacing: gap) {
                            ForEach(bars.indices, id: \.self) { i in
                                let bh = max(bars[i] > 0 ? 2 : 0, bars[i] * h)
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(accentColor)
                                    .frame(width: barW, height: bh)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .frame(height: chartH)

            HStack {
                ForEach(timeLabels.indices, id: \.self) { i in
                    Text(timeLabels[i])
                        .font(.system(size: 11))
                        .foregroundColor(DS.Color.textQuaternary)
                    if i < timeLabels.count - 1 { Spacer() }
                }
            }
        }
    }
}

// MARK: - Session Log
struct FocusSessionLog: View {
    let sessions: [FocusSession]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Sessions") {
                Button("See all") {}
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(uiColor: .systemBlue))
            }

            VStack(spacing: 0) {
                ForEach(sessions.indices, id: \.self) { idx in
                    FocusSessionRow(session: sessions[idx])
                    if idx < sessions.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                            .opacity(0.25)
                    }
                }
            }
            .padding(DS.Space.base)
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

struct FocusSessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: session.type.icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(session.type.color)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(session.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.Color.textPrimary)
                    if session.isFlow {
                        FlowBadge()
                    }
                }

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(session.timeRange)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(DS.Color.textTertiary)

                    Text("·")
                        .foregroundColor(DS.Color.textQuaternary)
                        .font(.system(size: 12))

                    Text(session.duration)
                        .font(.system(size: 12))
                        .foregroundColor(DS.Color.textTertiary)
                }
            }

            Spacer()

            // Focus quality bar
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.quality)%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(session.type.color)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(session.type.color.opacity(0.12))
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(session.type.color)
                            .frame(width: geo.size.width * CGFloat(session.quality) / 100)
                    }
                }
                .frame(width: 48, height: 4)
            }
            .frame(width: 48)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

struct FlowBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 8, weight: .bold))
            Text("Flow")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(Color.indigo)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.indigo.opacity(0.12))
        )
    }
}

// MARK: - Models
struct FocusCardData: Identifiable {
    let id = UUID()
    let label: String
    let valueString: String
    let unit: String?
    let delta: Int?
    let accentColor: Color
    let dayBars:   [Double]
    let weekBars:  [Double]
    let monthBars: [Double]
    let yearBars:  [Double]

    func bars(for period: FocusPeriod) -> [Double] {
        switch period {
        case .day:   return dayBars
        case .week:  return weekBars
        case .month: return monthBars
        case .year:  return yearBars
        }
    }
}

struct FocusSession: Identifiable {
    let id = UUID()
    let title: String
    let timeRange: String
    let duration: String
    let quality: Int
    let isFlow: Bool
    let type: FocusSessionType
}

enum FocusSessionType {
    case deepWork, review, planning

    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .review:   return "doc.text.magnifyingglass"
        case .planning: return "list.bullet.clipboard"
        }
    }

    var color: Color {
        switch self {
        case .deepWork: return .purple
        case .review:   return Color(hex: "0EA5E9")
        case .planning: return Color(hex: "10B981")
        }
    }
}

// MARK: - View Model
@Observable
final class FocusViewModel {
    var selectedPeriod: FocusPeriod = .day

    var periodSubtitle: String { selectedPeriod.subtitle }

    // Summary hero values
    let deepWorkHours   = 2
    let deepWorkMinutes = 15
    let goalProgress    = 0.56   // 2h15m of 4h goal
    let flowScore       = 0.72

    var metricCards: [FocusCardData] {
        [
            FocusCardData(
                label: "DEEP WORK",
                valueString: "2h 15m",
                unit: nil,
                delta: +18,
                accentColor: .purple,
                dayBars:   hourly([0,0,0,0,0,0,0,0,0,1,1,0.9,0.2,0,0.7,0.8,0.3,0,0,0,0,0,0,0]),
                weekBars:  norm([1.2, 2.8, 3.1, 2.0, 3.5, 2.25, 0]),
                monthBars: norm([2.0,2.5,1.8,3.2,2.8,3.5,2.1,1.9,3.0,2.7,
                                 3.4,3.1,2.6,2.25,3.0,2.9,2.4,3.6,3.2,2.8,
                                 2.5,3.0,2.7,2.2,3.3,3.7,2.9,3.2,2.6,2.25]),
                yearBars:  norm([48,62,55,70,64,61,75,68,63,66,59,42].map(Double.init))
            ),
            FocusCardData(
                label: "FLOW SESSIONS",
                valueString: "3",
                unit: nil,
                delta: +50,
                accentColor: Color.indigo,
                dayBars:   hourly([0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0]),
                weekBars:  norm([1, 2, 3, 1, 3, 3, 0]),
                monthBars: norm([1,2,1,3,2,3,1,1,2,2,3,2,2,3,2,2,1,3,3,2,1,2,2,1,3,3,2,3,2,3].map(Double.init)),
                yearBars:  norm([12,16,14,19,17,16,21,18,17,18,15,10].map(Double.init))
            ),
            FocusCardData(
                label: "AVG SESSION LENGTH",
                valueString: "45",
                unit: "min",
                delta: +12,
                accentColor: Color(hex: "0EA5E9"),
                dayBars:   hourly([0,0,0,0,0,0,0,0,0,60,55,50,0,0,45,40,30,0,0,0,0,0,0,0]),
                weekBars:  norm([38, 42, 48, 40, 50, 45, 0]),
                monthBars: norm([40,44,38,50,45,52,42,39,48,44,51,47,43,45,
                                 47,46,41,53,49,44,42,47,44,40,50,54,46,49,43,45].map(Double.init)),
                yearBars:  norm([38,42,40,46,43,41,48,45,43,44,41,36].map(Double.init))
            ),
        ]
    }

    var recentSessions: [FocusSession] {
        [
            FocusSession(
                title: "Product design sprint",
                timeRange: "9:00 – 10:30 AM",
                duration: "1h 30m",
                quality: 94,
                isFlow: true,
                type: .deepWork
            ),
            FocusSession(
                title: "Code review & PRs",
                timeRange: "11:00 – 11:45 AM",
                duration: "45m",
                quality: 78,
                isFlow: false,
                type: .review
            ),
            FocusSession(
                title: "Weekly planning",
                timeRange: "2:00 – 2:30 PM",
                duration: "30m",
                quality: 65,
                isFlow: false,
                type: .planning
            ),
        ]
    }

    private func hourly(_ vals: [Double]) -> [Double] {
        let mx = vals.max() ?? 1
        return vals.map { mx > 0 ? $0 / mx : 0 }
    }

    private func norm(_ vals: [Double]) -> [Double] {
        let mx = vals.max() ?? 1
        return vals.map { mx > 0 ? $0 / mx : 0 }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { FocusView() }
}
