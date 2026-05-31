//
//  FreeView.swift
//  Prysm
//

import SwiftUI
import Observation

// MARK: - Root
struct FreeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm       = FreeViewModel()
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
                            key: FreeScrollOffsetKey.self,
                            value: -geo.frame(in: .named("freeScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 72)

                    // ── Title ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Free Time")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                        Text(vm.dateString)
                            .font(.system(size: 17))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.04)

                    // ── Free time hero ─────────────────────────
                    FreeHeroCard(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.08)

                    // ── Day timeline visual ────────────────────
                    FreeDayTimeline(slots: vm.daySlots)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.14)

                    // ── Suggestions ────────────────────────────
                    FreeSuggestionsSection(suggestions: vm.suggestions) { suggestion in
                        vm.addSuggestion(suggestion)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .staggeredAppear(appeared, delay: 0.20)

                    // ── Free windows list ──────────────────────
                    FreeWindowsSection(windows: vm.freeWindows)
                        .padding(.horizontal, 20)
                        .staggeredAppear(appeared, delay: 0.26)

                    Spacer(minLength: 48)
                }
            }
            .coordinateSpace(name: "freeScroll")
            .onPreferenceChange(FreeScrollOffsetKey.self) { scrollY = $0 }

            FreeFloatingBar(barProgress: barProgress) { dismiss() }
        }
        .onAppear { appeared = true }
        .navigationBarHidden(true)
    }
}

private struct FreeScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Floating Bar
struct FreeFloatingBar: View {
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
                        Text("Free Time")
                            .font(DS.Font.subheadline())
                            .foregroundColor(DS.Color.textPrimary)
                        Text("Open windows")
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

// MARK: - Hero Card
struct FreeHeroCard: View {
    let vm: FreeViewModel

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 22) {

                ZStack {
                    Circle()
                        .stroke(DS.Color.textTertiary.opacity(0.12), lineWidth: 22)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    DS.Color.textSecondary.opacity(0.4),
                                    DS.Color.textSecondary
                                ],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 22, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: DS.Color.textTertiary.opacity(0.2), radius: 6, x: 0, y: 2)

                    Image(systemName: "wind")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(DS.Color.textSecondary)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.1).delay(0.3)) {
                        animatedProgress = vm.freeFraction
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OPEN TIME")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text(vm.freeTimeFull)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WINDOWS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text("\(vm.freeWindows.count)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LONGEST")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DS.Color.textQuaternary)
                                .tracking(0.4)
                            Text(vm.longestWindow)
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

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Day overview")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.textTertiary)
                    Spacer()
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle().fill(DS.Color.warning).frame(width: 6, height: 6)
                            Text("Scheduled")
                                .font(.system(size: 11))
                                .foregroundColor(DS.Color.textTertiary)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(DS.Color.textQuaternary.opacity(0.25)).frame(width: 6, height: 6)
                            Text("Free")
                                .font(.system(size: 11))
                                .foregroundColor(DS.Color.textTertiary)
                        }
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DS.Color.surfaceHigh)
                            .frame(height: 10)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [DS.Color.warning.opacity(0.7), DS.Color.warning],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (1 - animatedProgress), height: 10)
                            .shadow(color: DS.Color.warning.opacity(0.3), radius: 3, x: 0, y: 1)
                    }
                }
                .frame(height: 10)
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

// MARK: - Day Timeline Visual
struct FreeDayTimeline: View {
    let slots: [DayTimeSlot]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Today's Timeline") { EmptyView() }

            VStack(spacing: 12) {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(slots.indices, id: \.self) { i in
                            let slot = slots[i]
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(slot.isFree
                                    ? DS.Color.surfaceHigh
                                    : slot.color)
                                .frame(width: max(2, geo.size.width * slot.fraction - 2))
                                .overlay(
                                    slot.isFree
                                    ? RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .strokeBorder(DS.Color.border.opacity(0.5), lineWidth: 0.5)
                                    : nil
                                )
                        }
                    }
                }
                .frame(height: 20)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

                HStack {
                    Text("6AM")
                    Spacer()
                    Text("12PM")
                    Spacer()
                    Text("6PM")
                    Spacer()
                    Text("10PM")
                }
                .font(.system(size: 10))
                .foregroundColor(DS.Color.textQuaternary)

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(DS.Color.warning)
                            .frame(width: 14, height: 8)
                        Text("Blocked")
                            .font(.system(size: 11))
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(DS.Color.surfaceHigh)
                            .frame(width: 14, height: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .strokeBorder(DS.Color.border, lineWidth: 0.5)
                            )
                        Text("Free")
                            .font(.system(size: 11))
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    Spacer()
                    Text("\(slots.filter { !$0.isFree }.count) blocks · \(slots.filter { $0.isFree }.count) gaps")
                        .font(.system(size: 11))
                        .foregroundColor(DS.Color.textQuaternary)
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

// MARK: - Suggestions Section
struct FreeSuggestionsSection: View {
    let suggestions: [FreeSuggestion]
    let onAdd: (FreeSuggestion) -> Void

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Suggestions") {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                    Text("AI")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(DS.Color.textTertiary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DS.Color.textTertiary.opacity(0.08))
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Spacer().frame(width: 0)
                    ForEach(suggestions) { suggestion in
                        FreeSuggestionCard(suggestion: suggestion) {
                            onAdd(suggestion)
                        }
                    }
                    Spacer().frame(width: 0)
                }
            }
        }
    }
}

struct FreeSuggestionCard: View {
    let suggestion: FreeSuggestion
    let onAdd: () -> Void

    @State private var added = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(suggestion.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(suggestion.color)
                }
                Spacer()
                Text(suggestion.duration)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DS.Color.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(DS.Color.textTertiary.opacity(0.07))
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Color.textPrimary)
                Text(suggestion.timeSlot)
                    .font(.system(size: 12))
                    .foregroundColor(DS.Color.textSecondary)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    added = true
                }
                onAdd()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: added ? "checkmark" : "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text(added ? "Added" : "Add block")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(added ? DS.Color.positive : suggestion.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill((added ? DS.Color.positive : suggestion.color).opacity(0.10))
                )
            }
            .buttonStyle(.plain)
            .disabled(added)
        }
        .padding(16)
        .frame(width: 172)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DS.Color.surface)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Free Windows Section
struct FreeWindowsSection: View {
    let windows: [FreeWindow]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Open Windows") {
                Text("\(windows.count) gaps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.Color.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Color.textTertiary.opacity(0.08))
                    )
            }

            if windows.isEmpty {
                FreeEmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(windows.indices, id: \.self) { idx in
                        FreeWindowRow(window: windows[idx])
                        if idx < windows.count - 1 {
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

struct FreeWindowRow: View {
    let window: FreeWindow

    var qualityColor: Color {
        switch window.quality {
        case .prime:  return DS.Color.positive
        case .good:   return DS.Color.warning
        case .light:  return DS.Color.textTertiary
        }
    }

    var body: some View {
        HStack(spacing: 14) {

            VStack(alignment: .trailing, spacing: 2) {
                Text(window.startTime)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.Color.textTertiary)
                Text(window.endTime)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(DS.Color.textQuaternary)
            }
            .frame(width: 44, alignment: .trailing)

            ZStack {
                Circle()
                    .fill(DS.Color.textQuaternary.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: "wind")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(DS.Color.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(window.duration)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.Color.textPrimary)

                HStack(spacing: 6) {
                    Text(window.label)
                        .font(.system(size: 12))
                        .foregroundColor(DS.Color.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(qualityColor)
                        .frame(width: 6, height: 6)
                    Text(window.quality.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(qualityColor)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(qualityColor.opacity(0.10))
                )

                Button {
                } label: {
                    Text("Fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(uiColor: .systemBlue))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}

struct FreeEmptyState: View {
    var body: some View {
        VStack(spacing: DS.Space.md) {
            Image(systemName: "wind")
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundColor(DS.Color.textQuaternary)
            Text("Day is fully packed!")
                .font(DS.Font.subheadline())
                .foregroundColor(DS.Color.textTertiary)
            Text("No open windows remaining")
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

// MARK: - Models
struct DayTimeSlot {
    let isFree: Bool
    let color: Color
    let fraction: CGFloat
}

struct FreeWindow: Identifiable {
    let id = UUID()
    let startTime: String
    let endTime: String
    let duration: String
    let label: String
    let quality: FreeWindowQuality
}

enum FreeWindowQuality: String {
    case prime = "Prime"
    case good  = "Good"
    case light = "Light"
}

struct FreeSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let duration: String
    let timeSlot: String
}

// MARK: - View Model
@Observable
final class FreeViewModel {
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

    private var scheduledMinutes: Int {
        allBlocks.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalDayMinutes: Int { 480 }

    var freeMinutes: Int { max(0, totalDayMinutes - scheduledMinutes) }
    var freeFraction: Double { Double(freeMinutes) / Double(totalDayMinutes) }

    var freeTimeFull: String {
        let m = freeMinutes
        return m < 60 ? "\(m)m" : "\(m / 60)h\(m % 60 > 0 ? " \(m % 60)m" : "")"
    }

    var longestWindow: String { "2h 30m" }

    var daySlots: [DayTimeSlot] {
        [
            DayTimeSlot(isFree: true,  color: .clear,          fraction: 0.08),
            DayTimeSlot(isFree: false, color: DS.Color.warning, fraction: 0.12),
            DayTimeSlot(isFree: true,  color: .clear,          fraction: 0.06),
            DayTimeSlot(isFree: false, color: DS.Color.warning, fraction: 0.09),
            DayTimeSlot(isFree: true,  color: .clear,          fraction: 0.15),
            DayTimeSlot(isFree: false, color: DS.Color.warning, fraction: 0.10),
            DayTimeSlot(isFree: true,  color: .clear,          fraction: 0.08),
            DayTimeSlot(isFree: false, color: DS.Color.warning, fraction: 0.08),
            DayTimeSlot(isFree: true,  color: .clear,          fraction: 0.24),
        ]
    }

    var freeWindows: [FreeWindow] {
        [
            FreeWindow(startTime: "6:00",  endTime: "7:30",  duration: "1h 30m", label: "Morning slot — great for deep work",   quality: .prime),
            FreeWindow(startTime: "11:00", endTime: "1:30",  duration: "2h 30m", label: "Midday gap — longest open window",     quality: .prime),
            FreeWindow(startTime: "3:30",  endTime: "4:00",  duration: "30m",    label: "Short window — good for admin",        quality: .good),
            FreeWindow(startTime: "5:00",  endTime: "10:00", duration: "5h",     label: "Evening — personal time",             quality: .light),
        ]
    }

    var suggestions: [FreeSuggestion] {
        [
            FreeSuggestion(title: "Reading block",   icon: "book.fill",           color: Color(hex: "5E5CE6"), duration: "45 min", timeSlot: "11:00 AM gap"),
            FreeSuggestion(title: "Walk outside",    icon: "figure.walk",         color: DS.Color.positive,   duration: "30 min", timeSlot: "3:30 PM gap"),
            FreeSuggestion(title: "Journaling",      icon: "pencil.and.outline",  color: Color(hex: "FF9F0A"), duration: "20 min", timeSlot: "6:00 AM slot"),
            FreeSuggestion(title: "Learning session",icon: "graduationcap.fill",  color: Color(hex: "0EA5E9"), duration: "1h",     timeSlot: "11:30 AM gap"),
        ]
    }

    func addSuggestion(_ suggestion: FreeSuggestion) {
        // Hook to add suggestion as a block in the plan
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { FreeView() }
}
