//
//  DoneView.swift
//  Prysm
//

import SwiftUI
import Observation

// MARK: - Root
struct DoneView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm       = DoneViewModel()
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
                            key: DoneScrollOffsetKey.self,
                            value: -geo.frame(in: .named("doneScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 72)

                    // ── Title ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Done")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(vm.dateString)
                            .font(.system(size: 17))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.04)

                    // ── Period filter ──────────────────────────
                    DonePeriodFilter(selected: $vm.selectedPeriod)
                        .padding(.bottom, 20)
                        .staggeredAppear(appeared, delay: 0.08)

                    // ── Hero completion card ───────────────────
                    DoneHeroCard(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.12)

                    // ── Streak card ────────────────────────────
                    DoneStreakCard(
                        streak: vm.streak,
                        weekDots: vm.weekDots
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .staggeredAppear(appeared, delay: 0.18)

                    // ── Completed list ─────────────────────────
                    DoneCompletedSection(blocks: vm.completedBlocks)
                        .padding(.horizontal, 20)
                        .staggeredAppear(appeared, delay: 0.24)

                    Spacer(minLength: 48)
                }
            }
            .coordinateSpace(name: "doneScroll")
            .onPreferenceChange(DoneScrollOffsetKey.self) { scrollY = $0 }

            DoneFloatingBar(barProgress: barProgress) { dismiss() }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

private struct DoneScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Floating Bar
struct DoneFloatingBar: View {
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
                        Text("Done")
                            .font(DS.Font.subheadline())
                            .foregroundColor(DS.Color.textPrimary)
                        Text("Completed")
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

// MARK: - Period Filter
enum DonePeriod: String, CaseIterable, Identifiable {
    case today = "Today", week = "This Week", month = "This Month"
    var id: String { rawValue }
}

struct DonePeriodFilter: View {
    @Binding var selected: DonePeriod

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Spacer().frame(width: 12)
                ForEach(DonePeriod.allCases) { period in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: selected == period ? .semibold : .regular))
                            .foregroundColor(selected == period ? .white : DS.Color.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background {
                                if selected == period {
                                    Capsule()
                                        .fill(DS.Color.positive)
                                        .shadow(color: DS.Color.positive.opacity(0.35), radius: 8, x: 0, y: 3)
                                } else {
                                    Capsule()
                                        .fill(DS.Color.surface)
                                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
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

// MARK: - Hero Completion Card
struct DoneHeroCard: View {
    let vm: DoneViewModel

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 22) {

                // Animated completion ring
                ZStack {
                    Circle()
                        .stroke(DS.Color.positive.opacity(0.12), lineWidth: 22)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            AngularGradient(
                                colors: [DS.Color.positive.opacity(0.6), DS.Color.positive],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 22, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: DS.Color.positive.opacity(0.3), radius: 8, x: 0, y: 3)

                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(DS.Color.positive)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.1).delay(0.3)) {
                        animatedProgress = vm.completionRate
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COMPLETED")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .tracking(0.6)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(vm.doneCount)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(DS.Color.positive)
                            Text("/ \(vm.totalCount) blocks")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(DS.Color.textSecondary)
                        }
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RATE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text("\(Int(vm.completionRate * 100))%")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.positive)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TIME SAVED")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text(vm.timeDone)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
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

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily progress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.textTertiary)
                    Spacer()
                    Text("\(Int(vm.completionRate * 100))%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.Color.positive)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DS.Color.surfaceHigh)
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [DS.Color.positive.opacity(0.7), DS.Color.positive],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedProgress, height: 8)
                            .shadow(color: DS.Color.positive.opacity(0.35), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 8)
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

// MARK: - Streak Card
struct DoneStreakCard: View {
    let streak: Int
    let weekDots: [DoneWeekDot]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Streak") { EmptyView() }

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 20) {

                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B35"), Color(hex: "FF9F0A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color(hex: "FF6B35").opacity(0.3), radius: 10, x: 0, y: 4)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(streak)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                            Text("day streak")
                                .font(.system(size: 15))
                                .foregroundColor(DS.Color.textSecondary)
                        }
                        Text("Keep it up — you're on a roll!")
                            .font(.system(size: 13))
                            .foregroundColor(DS.Color.textTertiary)
                    }

                    Spacer()
                }
                .padding(18)

                Divider().opacity(0.25).padding(.horizontal, 18)

                HStack(spacing: 0) {
                    ForEach(weekDots.indices, id: \.self) { idx in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(weekDots[idx].completed
                                        ? DS.Color.positive
                                        : (weekDots[idx].isToday
                                            ? DS.Color.positive.opacity(0.15)
                                            : DS.Color.surfaceHigh))
                                    .frame(width: 32, height: 32)
                                if weekDots[idx].completed {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else if weekDots[idx].isToday {
                                    Circle()
                                        .fill(DS.Color.positive)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            Text(weekDots[idx].label)
                                .font(.system(size: 10, weight: weekDots[idx].isToday ? .bold : .regular))
                                .foregroundColor(weekDots[idx].isToday ? DS.Color.textPrimary : DS.Color.textQuaternary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
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

// MARK: - Completed Section
struct DoneCompletedSection: View {
    let blocks: [PlanBlock]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Completed") {
                Text("\(blocks.count) items")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.Color.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Color.textTertiary.opacity(0.08))
                    )
            }

            if blocks.isEmpty {
                DoneEmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(blocks.indices, id: \.self) { idx in
                        DoneBlockRow(block: blocks[idx])
                        if idx < blocks.count - 1 {
                            Divider()
                                .padding(.leading, 64)
                                .opacity(0.25)
                        }
                    }
                }
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
}

struct DoneBlockRow: View {
    let block: PlanBlock

    var body: some View {
        HStack(spacing: 14) {

            ZStack {
                Circle()
                    .fill(DS.Color.positive)
                    .frame(width: 36, height: 36)
                    .shadow(color: DS.Color.positive.opacity(0.25), radius: 6, x: 0, y: 2)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.Color.textTertiary)
                    .strikethrough(true, color: DS.Color.textQuaternary)

                HStack(spacing: 6) {
                    Text("\(block.startTime) – \(block.endTime)")
                        .font(.system(size: 12))
                        .foregroundColor(DS.Color.textQuaternary)
                    Text("·")
                        .foregroundColor(DS.Color.textQuaternary)
                        .font(.system(size: 12))
                    Text(block.duration)
                        .font(.system(size: 12))
                        .foregroundColor(DS.Color.textQuaternary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: block.category.icon)
                    .font(.system(size: 9, weight: .semibold))
                Text(block.category.label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(block.category.color.opacity(0.7))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(block.category.color.opacity(0.08))
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}

struct DoneEmptyState: View {
    var body: some View {
        VStack(spacing: DS.Space.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundColor(DS.Color.textQuaternary)
            Text("Nothing completed yet")
                .font(DS.Font.subheadline())
                .foregroundColor(DS.Color.textTertiary)
            Text("Complete your blocks to see them here")
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

// MARK: - Supporting Models
struct DoneWeekDot {
    let label: String
    let completed: Bool
    let isToday: Bool
}

// MARK: - View Model
@Observable
final class DoneViewModel {
    var selectedPeriod: DonePeriod = .today

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    private var allBlocks: [PlanBlock] {
        PlanBlock.sampleData.filter {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }
    }

    var completedBlocks: [PlanBlock] { allBlocks.filter { $0.isDone } }
    var doneCount: Int  { completedBlocks.count }
    var totalCount: Int { allBlocks.count }

    var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }

    var timeDone: String {
        let mins = completedBlocks.reduce(0) { $0 + $1.durationMinutes }
        return mins < 60 ? "\(mins)m" : "\(mins / 60)h\(mins % 60 > 0 ? " \(mins % 60)m" : "")"
    }

    var streak: Int { 7 }

    var weekDots: [DoneWeekDot] {
        let labels    = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let completed = [true, true, true, true, true, false, false]
        let todayIdx  = 5
        return labels.indices.map { i in
            DoneWeekDot(label: labels[i], completed: completed[i], isToday: i == todayIdx)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { DoneView() }
}
