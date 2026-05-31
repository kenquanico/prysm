//
//  BlocksView.swift
//  Prysm
//

import SwiftUI
import Observation

// MARK: - Root
struct BlocksView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm       = BlocksViewModel()
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
                            key: BlocksScrollOffsetKey.self,
                            value: -geo.frame(in: .named("blocksScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 72)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Blocks")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(vm.dateString)
                            .font(.system(size: 17))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.04)

                    BlocksCategoryFilter(selected: $vm.selectedCategory)
                        .padding(.bottom, 20)
                        .staggeredAppear(appeared, delay: 0.08)

                    BlocksSummaryCard(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.12)

                    BlocksTimelineSection(blocks: vm.filteredBlocks)
                        .padding(.horizontal, 20)
                        .staggeredAppear(appeared, delay: 0.16)

                    Spacer(minLength: 48)
                }
            }
            .coordinateSpace(name: "blocksScroll")
            .onPreferenceChange(BlocksScrollOffsetKey.self) { scrollY = $0 }

            BlocksFloatingBar(barProgress: barProgress) { dismiss() }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

private struct BlocksScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Floating Bar
struct BlocksFloatingBar: View {
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
                        Text("Blocks")
                            .font(DS.Font.subheadline())
                            .foregroundColor(DS.Color.textPrimary)
                        Text("Today")
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

// MARK: - Category Filter
struct BlocksCategoryFilter: View {
    @Binding var selected: BlockCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Spacer().frame(width: 12)

                BlocksCategoryChip(
                    label: "All",
                    icon: "square.stack.fill",
                    color: DS.Color.accent,
                    isSelected: selected == nil
                ) { selected = nil }

                ForEach(BlockCategory.allCases, id: \.self) { cat in
                    BlocksCategoryChip(
                        label: cat.label,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: selected == cat
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = (selected == cat) ? nil : cat
                        }
                    }
                }

                Spacer().frame(width: 12)
            }
        }
    }
}

struct BlocksCategoryChip: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : DS.Color.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule()
                        .fill(color)
                        .shadow(color: color.opacity(0.35), radius: 8, x: 0, y: 3)
                } else {
                    Capsule()
                        .fill(DS.Color.surface)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary Card
struct BlocksSummaryCard: View {
    let vm: BlocksViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    ProgressRing(
                        progress: vm.completionRate,
                        size: 80,
                        lineWidth: 6,
                        trackColor: DS.Color.accent.opacity(0.10),
                        ringColor: DS.Color.accent
                    )
                    VStack(spacing: 0) {
                        Text("\(vm.doneCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text("of \(vm.totalCount)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BLOCKS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text("\(vm.totalCount) total today")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.accent)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEXT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text(vm.nextBlockTime)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text(vm.totalTime)
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

            HStack(spacing: 0) {
                ForEach(Array(vm.categoryCounts.enumerated()), id: \.offset) { idx, pair in
                    VStack(spacing: 4) {
                        Image(systemName: pair.0.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(pair.0.color)
                        Text("\(pair.1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(pair.0.label)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    if idx < vm.categoryCounts.count - 1 {
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

// MARK: - Timeline Section
struct BlocksTimelineSection: View {
    let blocks: [PlanBlock]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Timeline") {
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
                    .background(Capsule().fill(Color(uiColor: .systemBlue)))
                    .shadow(color: Color(uiColor: .systemBlue).opacity(0.30), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }

            if blocks.isEmpty {
                BlocksEmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(blocks.indices, id: \.self) { idx in
                        BlocksTimelineRow(block: blocks[idx], isLast: idx == blocks.count - 1)
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
}

struct BlocksTimelineRow: View {
    let block: PlanBlock
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            VStack(alignment: .trailing, spacing: 2) {
                Text(block.startTime)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(block.isDone ? DS.Color.textQuaternary : DS.Color.textTertiary)
                Text(block.endTime)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(DS.Color.textQuaternary)
            }
            .frame(width: 52, alignment: .trailing)
            .padding(.top, 18)

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(block.isDone ? DS.Color.positive : block.category.color)
                        .frame(width: 10, height: 10)
                    if !block.isDone {
                        Circle()
                            .fill(block.category.color.opacity(0.2))
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

            HStack(spacing: 10) {
                Image(systemName: block.isDone ? "checkmark.circle.fill" : block.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(block.isDone ? DS.Color.positive : block.category.color)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text(block.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(block.isDone ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .strikethrough(block.isDone, color: DS.Color.textQuaternary)

                    Text(block.subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DS.Color.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(block.duration)
                            .font(.system(size: 11))
                            .foregroundColor(DS.Color.textTertiary)
                        Text("·")
                            .foregroundColor(DS.Color.textQuaternary)
                            .font(.system(size: 11))
                        Text(block.category.label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(block.category.color)
                    }
                    .padding(.top, 2)
                }

                Spacer()

                if block.isDone {
                    Text("Done")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DS.Color.positive)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(DS.Color.positive.opacity(0.10)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .contentShape(Rectangle())
    }
}

struct BlocksEmptyState: View {
    var body: some View {
        VStack(spacing: DS.Space.md) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundColor(DS.Color.textQuaternary)
            Text("No blocks yet")
                .font(DS.Font.subheadline())
                .foregroundColor(DS.Color.textTertiary)
            Text("Tap Add to create your first block")
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

// MARK: - View Model
@Observable
final class BlocksViewModel {
    var selectedCategory: BlockCategory? = nil

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

    var filteredBlocks: [PlanBlock] {
        guard let cat = selectedCategory else { return allBlocks }
        return allBlocks.filter { $0.category == cat }
    }

    var totalCount: Int { allBlocks.count }
    var doneCount: Int  { allBlocks.filter { $0.isDone }.count }

    var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }

    var nextBlockTime: String {
        allBlocks.first(where: { !$0.isDone })?.startTime ?? "–"
    }

    var totalTime: String {
        let m = allBlocks.reduce(0) { $0 + $1.durationMinutes }
        return m < 60 ? "\(m)m" : "\(m / 60)h\(m % 60 > 0 ? " \(m % 60)m" : "")"
    }

    var categoryCounts: [(BlockCategory, Int)] {
        BlockCategory.allCases.compactMap { cat in
            let count = allBlocks.filter { $0.category == cat }.count
            return count > 0 ? (cat, count) : nil
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { BlocksView() }
}
