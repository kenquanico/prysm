//
//  ReadinessView.swift
//  Prysm
//

import SwiftUI

// MARK: - Root
struct ReadinessView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ReadinessViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Nav header
                    ReadinessNavHeader(score: vm.score) {
                        dismiss()
                    }
                    .staggeredAppear(appeared, delay: 0.04)

                    // Hero ring
                    ReadinessHeroRing(
                        score: vm.score,
                        label: vm.scoreLabel,
                        sublabel: vm.scoreSublabel,
                        ringColor: vm.ringColor
                    )
                    .staggeredAppear(appeared, delay: 0.10)

                    // Week strip
                    ReadinessWeekStrip(days: vm.weekDays)
                        .staggeredAppear(appeared, delay: 0.16)

                    // Pillar grid
                    ReadinessPillarGrid(pillars: vm.pillars)
                        .staggeredAppear(appeared, delay: 0.22)

                    // Peak window card
                    ReadinessPeakCard(
                        peakStart: vm.peakStart,
                        peakEnd: vm.peakEnd,
                        energySummary: vm.energySummary
                    )
                    .staggeredAppear(appeared, delay: 0.30)

                    // History chart
                    ReadinessHistoryCard(history: vm.history)
                        .staggeredAppear(appeared, delay: 0.36)

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.base)
                .padding(.top, DS.Space.sm)
            }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

// MARK: - View Model
class ReadinessViewModel: ObservableObject {
    let score: Int = 78

    var scoreLabel: String {
        score >= 85 ? "Optimal" : score >= 65 ? "Good" : score >= 45 ? "Fair" : "Low"
    }

    var scoreSublabel: String {
        score >= 85 ? "You're primed — push hard today" :
        score >= 65 ? "Solid baseline, stay focused" :
        score >= 45 ? "Moderate — pace yourself" :
                      "Recovery day recommended"
    }

    var ringColor: Color {
        score >= 70 ? DS.Color.positive : score >= 45 ? DS.Color.warning : DS.Color.negative
    }

    var peakStart: String { "9:00 AM" }
    var peakEnd: String   { "11:00 AM" }
    var energySummary: String { "Good sleep · HRV elevated · Low stress load" }

    var weekDays: [ReadinessDayDot] {
        let scores = [62, 71, 55, 80, 74, 78, 0]
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return zip(labels, scores).enumerated().map { idx, pair in
            ReadinessDayDot(
                label: pair.0,
                score: pair.1,
                isToday: idx == 5
            )
        }
    }

    var pillars: [ReadinessPillar] {
        [
            ReadinessPillar(title: "Sleep",        icon: "moon.fill",          value: 85, unit: "7h 20m",  accent: Color(hex: "5E5CE6")),
            ReadinessPillar(title: "HRV",           icon: "waveform.path.ecg", value: 72, unit: "58 ms",   accent: DS.Color.positive),
            ReadinessPillar(title: "Resting HR",    icon: "heart.fill",        value: 68, unit: "52 bpm",  accent: DS.Color.negative),
            ReadinessPillar(title: "Recovery",      icon: "bolt.heart.fill",   value: 76, unit: "Good",    accent: Color(hex: "FF9F0A")),
            ReadinessPillar(title: "Stress",        icon: "brain.head.profile",value: 80, unit: "Low",     accent: Color(hex: "30D158")),
            ReadinessPillar(title: "Activity Load", icon: "figure.run",        value: 55, unit: "Moderate",accent: Color(hex: "FF6B35")),
        ]
    }

    var history: [Int] {
        [65, 70, 55, 80, 74, 68, 60, 77, 82, 78, 73, 78, 71, 78]
    }
}

// MARK: - Nav Header
struct ReadinessNavHeader: View {
    let score: Int
    let onBack: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.Color.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(DS.Color.surface)
                    )
                    .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text("Readiness")
                    .font(DS.Font.title3())
                    .foregroundColor(DS.Color.textPrimary)
                Text("Today · May 30")
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textTertiary)
            }

            Spacer()

            // Spacer mirror for centering
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, DS.Space.sm)
    }
}

// MARK: - Hero Ring
struct ReadinessHeroRing: View {
    let score: Int
    let label: String
    let sublabel: String
    let ringColor: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer glow halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ringColor.opacity(0.12), ringColor.opacity(0)],
                            center: .center,
                            startRadius: 80,
                            endRadius: 160
                        )
                    )
                    .frame(width: 300, height: 300)

                // Track ring
                Circle()
                    .stroke(DS.Color.surface, lineWidth: 22)
                    .frame(width: 220, height: 220)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [ringColor.opacity(0.6), ringColor, ringColor.opacity(0.9)],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ringColor.opacity(0.35), radius: 10, x: 0, y: 4)

                // Tip dot
                Circle()
                    .fill(ringColor)
                    .frame(width: 18, height: 18)
                    .shadow(color: ringColor.opacity(0.5), radius: 6, x: 0, y: 2)
                    .offset(y: -110)
                    .rotationEffect(.degrees(-90 + animatedProgress * 360))

                // Center content
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Color.textPrimary)
                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ringColor)
                }
            }
            .frame(height: 270)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                    animatedProgress = Double(score) / 100
                }
            }

            Text(sublabel)
                .font(DS.Font.subheadline())
                .foregroundColor(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Week Strip
struct ReadinessDayDot {
    let label: String
    let score: Int
    let isToday: Bool
}

struct ReadinessWeekStrip: View {
    let days: [ReadinessDayDot]

    private func ringColor(_ score: Int) -> Color {
        guard score > 0 else { return DS.Color.border }
        return score >= 70 ? DS.Color.positive : score >= 45 ? DS.Color.warning : DS.Color.negative
    }

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "This Week") { EmptyView() }

            HStack(spacing: 0) {
                ForEach(days.indices, id: \.self) { idx in
                    let day = days[idx]
                    VStack(spacing: 8) {
                        Text(day.label)
                            .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                            .foregroundColor(day.isToday ? DS.Color.textPrimary : DS.Color.textTertiary)

                        ZStack {
                            Circle()
                                .stroke(ringColor(day.score).opacity(0.2), lineWidth: 2.5)
                                .frame(width: 34, height: 34)

                            if day.score > 0 {
                                Circle()
                                    .trim(from: 0, to: Double(day.score) / 100)
                                    .stroke(ringColor(day.score), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                    .frame(width: 34, height: 34)
                                    .rotationEffect(.degrees(-90))
                            }

                            if day.isToday {
                                Circle()
                                    .fill(ringColor(day.score))
                                    .frame(width: 10, height: 10)
                            }
                        }

                        Text(day.score > 0 ? "\(day.score)" : "–")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(day.score > 0 ? DS.Color.textSecondary : DS.Color.textQuaternary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(DS.Space.base)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Pillar Grid
struct ReadinessPillar {
    let title: String
    let icon: String
    let value: Int
    let unit: String
    let accent: Color
}

struct ReadinessPillarGrid: View {
    let pillars: [ReadinessPillar]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Factors") { EmptyView() }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(pillars.indices, id: \.self) { idx in
                    ReadinessPillarCard(pillar: pillars[idx])
                }
            }
        }
    }
}

struct ReadinessPillarCard: View {
    let pillar: ReadinessPillar
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: pillar.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(pillar.accent)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(pillar.accent.opacity(0.12))
                    )

                Spacer()

                Text("\(pillar.value)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(DS.Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pillar.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Color.textPrimary)
                Text(pillar.unit)
                    .font(.system(size: 11))
                    .foregroundColor(DS.Color.textSecondary)
            }

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Color.surfaceHigh)
                        .frame(height: 4)

                    Capsule()
                        .fill(pillar.accent)
                        .frame(width: geo.size.width * animatedProgress, height: 4)
                }
            }
            .frame(height: 4)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9).delay(0.3)) {
                    animatedProgress = Double(pillar.value) / 100
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Peak Window Card
struct ReadinessPeakCard: View {
    let peakStart: String
    let peakEnd: String
    let energySummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Peak Window") { EmptyView() }

            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF9F0A"), Color(hex: "FF6B35")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "FF9F0A").opacity(0.3), radius: 10, x: 0, y: 4)

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(peakStart) – \(peakEnd)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DS.Color.textPrimary)
                    Text(energySummary)
                        .font(.system(size: 13))
                        .foregroundColor(DS.Color.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Timeline visual showing the peak window
            ReadinessDayTimeline(peakHourStart: 9, peakHourEnd: 11)
        }
        .padding(DS.Space.base)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DS.Color.surface)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

struct ReadinessDayTimeline: View {
    let peakHourStart: CGFloat
    let peakHourEnd: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let startX = (peakHourStart / 24) * w
            let endX   = (peakHourEnd   / 24) * w

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(DS.Color.surfaceHigh)
                    .frame(height: 6)

                // Peak highlight
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF9F0A"), Color(hex: "FF6B35")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: endX - startX, height: 6)
                    .offset(x: startX)
                    .shadow(color: Color(hex: "FF9F0A").opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Text("12AM")
                    Spacer()
                    Text("6AM")
                    Spacer()
                    Text("12PM")
                    Spacer()
                    Text("6PM")
                    Spacer()
                    Text("12AM")
                }
                .font(.system(size: 9))
                .foregroundColor(DS.Color.textQuaternary)
                .offset(y: 14)
            }
        }
        .frame(height: 6)
        .padding(.bottom, 16)
    }
}

// MARK: - History Card
struct ReadinessHistoryCard: View {
    let history: [Int]

    private var maxVal: CGFloat { CGFloat(history.max() ?? 100) }

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "14-Day Trend") { EmptyView() }

            VStack(alignment: .leading, spacing: 16) {
                // Avg badge
                HStack(spacing: 8) {
                    let avg = history.filter { $0 > 0 }.reduce(0, +) / max(1, history.filter { $0 > 0 }.count)
                    Text("Avg \(avg)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.Color.positive)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(DS.Color.positive.opacity(0.12))
                        )
                    Spacer()
                }

                // Bar chart
                GeometryReader { geo in
                    let count = CGFloat(history.count)
                    let spacing: CGFloat = 5
                    let barWidth = (geo.size.width - (count - 1) * spacing) / count

                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(history.indices, id: \.self) { i in
                            let val = history[i]
                            let h = val > 0 ? max(4, (CGFloat(val) / maxVal) * geo.size.height) : 4
                            let color: Color = val >= 70 ? DS.Color.positive : val >= 45 ? DS.Color.warning : DS.Color.negative
                            let isToday = i == history.count - 1

                            ZStack(alignment: .top) {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(val > 0 ? color.opacity(isToday ? 1.0 : 0.55) : DS.Color.surfaceHigh)
                                    .frame(width: barWidth, height: h)
                                    .shadow(
                                        color: isToday ? color.opacity(0.3) : .clear,
                                        radius: 6, x: 0, y: 3
                                    )
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 80)

                // X axis labels
                HStack {
                    Text("14d ago")
                    Spacer()
                    Text("Today")
                }
                .font(.system(size: 10))
                .foregroundColor(DS.Color.textQuaternary)
            }
            .padding(DS.Space.base)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - SectionHeader (shared helper, use the one from your DS if it exists)
// Include only if you don't already have a shared SectionHeader in your codebase.
// struct SectionHeader<Trailing: View>: View {
//     let title: String
//     @ViewBuilder let trailing: () -> Trailing
//     var body: some View {
//         HStack {
//             Text(title)
//                 .font(DS.Font.headline())
//                 .foregroundColor(DS.Color.textPrimary)
//             Spacer()
//             trailing()
//         }
//     }
// }

// MARK: - Preview
#Preview {
    ReadinessView()
}