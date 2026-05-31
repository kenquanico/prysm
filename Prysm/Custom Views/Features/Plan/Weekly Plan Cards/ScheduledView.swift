//
//  ScheduledView.swift
//  Prysm
//

import SwiftUI
import Observation

// MARK: - Root
struct ScheduledView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm       = ScheduledViewModel()
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
                            key: ScheduledScrollOffsetKey.self,
                            value: -geo.frame(in: .named("scheduledScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 72)

                    // ── Title ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Scheduled")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(vm.dateString)
                            .font(.system(size: 17))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.04)

                    // ── Segmented control ──────────────────────
                    HStack {
                        Spacer()
                        ScheduledSegmentedControl(selected: $vm.selectedView)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.08)

                    // ── Summary card ───────────────────────────
                    ScheduledSummaryCard(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.12)

                    // ── Time distribution ──────────────────────
                    ScheduledDistributionCard(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.18)

                    // ── Block list ─────────────────────────────
                    ScheduledBlocksSection(blocks: vm.sortedBlocks)
                        .padding(.horizontal, 20)
                        .staggeredAppear(appeared, delay: 0.24)

                    Spacer(minLength: 48)
                }
            }
            .coordinateSpace(name: "scheduledScroll")
            .onPreferenceChange(ScheduledScrollOffsetKey.self) { scrollY = $0 }

            ScheduledFloatingBar(barProgress: barProgress) { dismiss() }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

private struct ScheduledScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Floating Bar
struct ScheduledFloatingBar: View {
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
                        Text("Scheduled")
                            .font(DS.Font.subheadline())
                            .foregroundColor(DS.Color.textPrimary)
                        Text("Blocked time")
                            .font(DS.Font.caption1())
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    .opacity(Double(barProgress))
                    .animation(.easeInOut(duration: 0.2), value: barProgress)

                    Spacer()

                    Button {
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 52, height: 52)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .frame(height: 64)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View toggle
enum ScheduledViewMode: String, CaseIterable, Identifiable {
    case list = "List", timeline = "Timeline"
    var id: String { rawValue }
}

struct ScheduledSegmentedControl: View {
    @Binding var selected: ScheduledViewMode

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ScheduledViewMode.allCases) { mode in
                    let isActive = selected == mode
                    let btn = Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = mode
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode == .list ? "list.bullet" : "clock")
                                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                            Text(mode.rawValue)
                                .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                        }
                        .foregroundStyle(isActive ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, DS.Space.md)
                        .padding(.vertical, DS.Space.sm)
                    }
                    .buttonStyle(.plain)

                    if isActive {
                        btn.glassEffect(.regular.interactive(), in: Capsule())
                    } else {
                        btn
                    }
                }
            }
            .glassEffect(in: Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary Card
struct ScheduledSummaryCard: View {
    let vm: ScheduledViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 20) {
                // Clock ring
                ZStack {
                    ProgressRing(
                        progress: vm.timeUsedFraction,
                        size: 80,
                        lineWidth: 6,
                        trackColor: DS.Color.warning.opacity(0.10),
                        ringColor: DS.Color.warning
                    )
                    VStack(spacing: 0) {
                        Text(vm.scheduledShort)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text("today")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BLOCKED TIME")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text(vm.scheduledFull)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.warning)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BLOCKS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text("\(vm.totalBlocks)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AVG LEN")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text(vm.avgLength)
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

            Divider().opacity(0.25).padding(.horizontal, 18)

            // By category stats
            HStack(spacing: 0) {
                ForEach(Array(vm.categoryMinutes.enumerated()), id: \.offset) { idx, pair in
                    VStack(spacing: 4) {
                        Image(systemName: pair.0.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(pair.0.color)
                        Text(pair.1 < 60 ? "\(pair.1)m" : "\(pair.1 / 60)h")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(pair.0.label)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    if idx < vm.categoryMinutes.count - 1 {
                        Divider().frame(height: 36).opacity(0.25)
                    }
                }
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

// MARK: - Distribution Card (stacked bar)
struct ScheduledDistributionCard: View {
    let vm: ScheduledViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Time Distribution") { EmptyView() }

            VStack(spacing: 16) {

                // Stacked horizontal bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(vm.distributionSegments.indices, id: \.self) { idx in
                            let seg = vm.distributionSegments[idx]
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(seg.color)
                                .frame(width: geo.size.width * seg.fraction - 2)
                        }
                    }
                }
                .frame(height: 14)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                // Legend
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    ForEach(vm.distributionSegments.indices, id: \.self) { idx in
                        let seg = vm.distributionSegments[idx]
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(seg.color)
                                .frame(width: 10, height: 10)
                            Text(seg.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DS.Color.textSecondary)
                            Spacer()
                            Text(seg.timeString)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                        }
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

// MARK: - Blocks Section
struct ScheduledBlocksSection: View {
    let blocks: [PlanBlock]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "All Blocks") {
                Text("\(blocks.count) blocks")
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
                ScheduledEmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(blocks.indices, id: \.self) { idx in
                        ScheduledBlockRow(block: blocks[idx])
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

struct ScheduledBlockRow: View {
    let block: PlanBlock

    var body: some View {
        HStack(spacing: 14) {

            // Color bar + icon
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(block.isDone ? DS.Color.textQuaternary.opacity(0.4) : block.category.color)
                    .frame(width: 3, height: 40)

                Image(systemName: block.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(block.isDone ? DS.Color.textQuaternary : block.category.color)
                    .frame(width: 28, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(block.isDone ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .strikethrough(block.isDone, color: DS.Color.textQuaternary)

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(block.startTime) – \(block.endTime)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(DS.Color.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // Duration pill
                Text(block.duration)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DS.Color.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(DS.Color.warning.opacity(0.10))
                    )

                if block.isDone {
                    Text("Done")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DS.Color.positive)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}

struct ScheduledEmptyState: View {
    var body: some View {
        VStack(spacing: DS.Space.md) {
            Image(systemName: "clock.badge.plus")
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundColor(DS.Color.textQuaternary)
            Text("No blocks scheduled")
                .font(DS.Font.subheadline())
                .foregroundColor(DS.Color.textTertiary)
            Text("Add blocks to fill your day")
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

// MARK: - Distribution Segment
struct ScheduledSegment {
    let label: String
    let color: Color
    let minutes: Int
    let fraction: CGFloat
    var timeString: String {
        minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h\(minutes % 60 > 0 ? " \(minutes % 60)m" : "")"
    }
}

// MARK: - View Model
@Observable
final class ScheduledViewModel {
    var selectedView: ScheduledViewMode = .list

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

    var sortedBlocks: [PlanBlock] { allBlocks }
    var totalBlocks: Int { allBlocks.count }

    private var totalMinutes: Int { allBlocks.reduce(0) { $0 + $1.durationMinutes } }

    var scheduledFull: String {
        let m = totalMinutes
        return m < 60 ? "\(m)m" : "\(m / 60)h \(m % 60 > 0 ? "\(m % 60)m" : "")"
    }

    var scheduledShort: String {
        let m = totalMinutes
        return m < 60 ? "\(m)m" : "\(m / 60)h"
    }

    var timeUsedFraction: Double {
        min(1.0, Double(totalMinutes) / 480.0)
    }

    var avgLength: String {
        guard totalBlocks > 0 else { return "–" }
        let avg = totalMinutes / totalBlocks
        return avg < 60 ? "\(avg)m" : "\(avg / 60)h"
    }

    var categoryMinutes: [(BlockCategory, Int)] {
        BlockCategory.allCases.compactMap { cat in
            let mins = allBlocks.filter { $0.category == cat }.reduce(0) { $0 + $1.durationMinutes }
            return mins > 0 ? (cat, mins) : nil
        }
    }

    var distributionSegments: [ScheduledSegment] {
        let total = CGFloat(max(1, totalMinutes))
        return categoryMinutes.map { pair in
            ScheduledSegment(
                label: pair.0.label,
                color: pair.0.color,
                minutes: pair.1,
                fraction: CGFloat(pair.1) / total
            )
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { ScheduledView() }
}
