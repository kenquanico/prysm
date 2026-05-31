//
//  StepsView.swift
//  Prysm
//

import SwiftUI
import Observation

// MARK: - Root
struct StepsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm       = StepsViewModel()
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
                            key: StepsScrollOffsetKey.self,
                            value: -geo.frame(in: .named("stepsScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 72)

                    // ── Title ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Steps")
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
                        StepsSegmentedControl(selected: $vm.selectedPeriod)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.08)

                    // ── Metric cards ─────────────────────────────
                    VStack(spacing: 16) {
                        ForEach(vm.metricCards) { card in
                            StepsMetricCard(card: card, period: vm.selectedPeriod)
                        }
                    }
                    .padding(.horizontal, 20)
                    .staggeredAppear(appeared, delay: 0.12)

                    Spacer(minLength: 48)
                }
            }
            .coordinateSpace(name: "stepsScroll")
            .onPreferenceChange(StepsScrollOffsetKey.self) { scrollY = $0 }

            // ── Floating bar ─────────────────────────────────────
            StepsFloatingBar(barProgress: barProgress) { dismiss() }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

private struct StepsScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Floating bar
struct StepsFloatingBar: View {
    let barProgress: CGFloat
    let onBack: () -> Void

    var body: some View {
        ZStack {
            // FIX #3: allowsHitTesting(false) so the material layer
            // never intercepts taps meant for the button below it.
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(Double(barProgress))
                .overlay(alignment: .bottom) {
                    Divider().opacity(Double(barProgress) * 0.35)
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)          // ← FIX #3

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 52, height: 52)
                            .contentShape(Circle())   // ← FIX #2
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())

                    Spacer()

                    VStack(spacing: 1) {
                        Text("Steps")
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
struct StepsSegmentedControl: View {
    @Binding var selected: StepsPeriod

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(StepsPeriod.allCases) { period in
                    segmentItem(period)
                }
            }
            .glassEffect(in: Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func segmentItem(_ period: StepsPeriod) -> some View {
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
enum StepsPeriod: String, CaseIterable, Identifiable {
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

// MARK: - Metric Card
struct StepsMetricCard: View {
    let card: StepsCardData
    let period: StepsPeriod

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
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 16)

            StepsGridChart(
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

// MARK: - Grid Chart
struct StepsGridChart: View {
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

// MARK: - Card Data
struct StepsCardData: Identifiable {
    let id = UUID()
    let label: String
    let valueString: String
    let unit: String?
    let accentColor: Color
    let dayBars:   [Double]
    let weekBars:  [Double]
    let monthBars: [Double]
    let yearBars:  [Double]

    func bars(for period: StepsPeriod) -> [Double] {
        switch period {
        case .day:   return dayBars
        case .week:  return weekBars
        case .month: return monthBars
        case .year:  return yearBars
        }
    }
}

// MARK: - View Model
@Observable
final class StepsViewModel {
    var selectedPeriod: StepsPeriod = .day

    var periodSubtitle: String { selectedPeriod.subtitle }

    var metricCards: [StepsCardData] {
        [
            StepsCardData(
                label: "COUNT",
                valueString: "6,240",
                unit: nil,
                accentColor: Color(red: 0.52, green: 0.38, blue: 0.92),
                dayBars:   hourly([0,0,0,0,0,180,420,890,1200,980,640,520,310,480,760,640,220,180,100,80,40,20,0,0]),
                weekBars:  norm([4200,7800,5500,9200,8100,6240,0]),
                monthBars: norm([7200,8100,6400,9500,7800,8900,7100,6500,8300,7600,
                                 9100,8400,7200,6240,8100,7900,6800,9200,8700,7400,
                                 6900,8100,7300,6600,8800,9300,7900,8500,7100,6240]),
                yearBars:  norm([198000,215000,187000,224000,201000,198000,
                                 231000,219000,204000,212000,195000,140000])
            ),
            StepsCardData(
                label: "DISTANCE",
                valueString: "4.80",
                unit: "KM",
                accentColor: Color(red: 0.18, green: 0.72, blue: 0.93),
                dayBars:   hourly([0,0,0,0,0,120,380,780,1050,870,560,430,260,400,640,540,180,150,80,60,30,10,0,0]),
                weekBars:  norm([3.1,5.8,4.1,7.2,6.3,4.8,0]),
                monthBars: norm([5.4,6.1,4.8,7.2,5.9,6.7,5.3,4.9,6.2,5.7,6.8,6.3,5.4,4.8,
                                 6.1,5.9,5.1,6.9,6.5,5.6,5.2,6.1,5.5,4.9,6.6,7.0,5.9,6.4,5.3,4.8]),
                yearBars:  norm([148,161,140,168,151,149,173,164,153,159,146,105].map(Double.init))
            ),
        ]
    }

    private func hourly(_ vals: [Int]) -> [Double] {
        let mx = Double(vals.max() ?? 1)
        return vals.map { mx > 0 ? Double($0) / mx : 0 }
    }

    private func norm(_ vals: [Double]) -> [Double] {
        let mx = vals.max() ?? 1
        return vals.map { mx > 0 ? $0 / mx : 0 }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { StepsView() }
}
