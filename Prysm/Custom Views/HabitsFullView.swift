//
//  HabitsFullView.swift
//  Prysm
//

import SwiftUI
import Combine

// MARK: - Root
struct HabitsFullView: View {
    @StateObject private var vm = HabitsViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    HabitsHeaderSection(
                        doneCount:  vm.doneToday,
                        total:      vm.habits.count,
                        bestStreak: vm.topStreak
                    )
                    .staggeredAppear(appeared, delay: 0.04)

                    HabitsStreakHero(
                        doneCount:  vm.doneToday,
                        total:      vm.habits.count,
                        topStreak:  vm.topStreak,
                        progress:   vm.progress
                    )
                    .staggeredAppear(appeared, delay: 0.10)

                    HabitsWeekGrid(habits: vm.habits)
                        .staggeredAppear(appeared, delay: 0.16)

                    ForEach(Array(FullHabit.HabitCategory.allCases.enumerated()), id: \.element) { i, cat in
                        let filtered = vm.habits(for: cat)
                        if !filtered.isEmpty {
                            HabitsCategorySection(
                                category: cat,
                                habits:   filtered,
                                vm:       vm
                            )
                            .staggeredAppear(appeared, delay: 0.22 + Double(i) * 0.06)
                        }
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
class HabitsViewModel: ObservableObject {
    @Published var habits: [FullHabit] = FullHabit.sampleData

    var doneToday: Int  { habits.filter { $0.isCheckedToday }.count }
    var topStreak: Int  { habits.map { $0.streak }.max() ?? 0 }
    var progress: Double { habits.isEmpty ? 0 : Double(doneToday) / Double(habits.count) }

    func habits(for cat: FullHabit.HabitCategory) -> [FullHabit] {
        habits.filter { $0.category == cat }
    }

    func toggle(_ habit: FullHabit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        withAnimation(DS.Animation.snappy) {
            habits[idx].isCheckedToday.toggle()
            habits[idx].streak += habits[idx].isCheckedToday ? 1 : -1
            habits[idx].streak = max(0, habits[idx].streak)
        }
    }
}

// MARK: - Header
struct HabitsHeaderSection: View {
    let doneCount: Int
    let total: Int
    let bestStreak: Int

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dateString)
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textTertiary)
                Text("Habits")
                    .font(DS.Font.title1())
                    .foregroundColor(DS.Color.textPrimary)
                Text("\(doneCount) of \(total) done today")
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textSecondary)
            }
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Color.warning)
                Text("\(bestStreak)d")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.Color.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .padding(.top, DS.Space.sm)
    }
}

// MARK: - Streak Hero
struct HabitsStreakHero: View {
    let doneCount: Int
    let total: Int
    let topStreak: Int
    let progress: Double

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "7C6AF7"))

            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Progress")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .tracking(0.3)
                        Text("\(doneCount) of \(total)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    ZStack {
                        ProgressRing(
                            progress: progress,
                            size: 64,
                            lineWidth: 5,
                            trackColor: Color.white.opacity(0.18),
                            ringColor: .white
                        )
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Spacer(minLength: 10)

                Text("Keep going — you're building consistency.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.74))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 28)

                HStack(spacing: 10) {
                    HeroStatPill(icon: "flame.fill",   value: "\(topStreak)d", label: "Best streak")
                    HeroStatPill(icon: "checkmark.circle.fill", value: "\(doneCount)", label: "Done today")
                    HeroStatPill(icon: "chart.bar.fill", value: "\(total - doneCount)", label: "Remaining")
                }
            }
            .padding(24)
        }
        .frame(height: 248)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "7C6AF7").opacity(0.45), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
    }
}

private struct HeroStatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.80))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - 7-day grid
struct HabitsWeekGrid: View {
    let habits: [FullHabit]
    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: DS.Space.md) {

            HStack {
                Text("This Week")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                Text("7-day view")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(DS.Color.textTertiary)
            }

            HStack(spacing: 0) {
                Spacer().frame(width: 108)
                ForEach(Array(dayLetters.enumerated()), id: \.offset) { _, d in
                    Text(d)
                        .font(DS.Font.caption2())
                        .foregroundColor(DS.Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(habits.enumerated()), id: \.element.id) { idx, habit in
                    HStack(spacing: 0) {
                        HStack(spacing: DS.Space.sm) {
                            Image(systemName: habit.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(habit.category.color)
                                .frame(width: 18)
                            Text(habit.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(DS.Color.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(width: 108, alignment: .leading)

                        ForEach(0..<7, id: \.self) { dayIdx in
                            let filled = habit.weekHistory[safe: dayIdx] ?? false
                            ZStack {
                                Circle()
                                    .fill(filled
                                          ? habit.category.color
                                          : DS.Color.surfaceHigh)
                                    .frame(width: 22, height: 22)
                                if filled {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Circle()
                                        .stroke(DS.Color.border, lineWidth: 0.5)
                                        .frame(width: 22, height: 22)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, DS.Space.base)
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

// MARK: - Category Section
struct HabitsCategorySection: View {
    let category: FullHabit.HabitCategory
    let habits: [FullHabit]
    @ObservedObject var vm: HabitsViewModel

    var doneInCategory: Int { habits.filter { $0.isCheckedToday }.count }

    var body: some View {
        VStack(spacing: DS.Space.md) {

            HStack {
                Text(category.rawValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                Text("\(doneInCategory)/\(habits.count)")
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
                ForEach(habits, id: \.id) { habit in
                    FullHabitRow(habit: habit) { vm.toggle(habit) }
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

// MARK: - Habit Row
struct FullHabitRow: View {
    let habit: FullHabit
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {

                // Left: color bar
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(habit.isCheckedToday
                          ? DS.Color.textQuaternary.opacity(0.4)
                          : habit.category.color)
                    .frame(width: 3, height: 36)

                // Icon — replaced with checkmark when done
                Image(systemName: habit.isCheckedToday ? "checkmark" : habit.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(
                        habit.isCheckedToday
                            ? DS.Color.positive
                            : habit.category.color
                    )
                    .frame(width: 30, alignment: .center)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(habit.isCheckedToday
                                         ? DS.Color.textTertiary
                                         : DS.Color.textPrimary)
                        .strikethrough(habit.isCheckedToday, color: DS.Color.textQuaternary)
                    Text(habit.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(DS.Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Trailing: flame + streak number only
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(habit.streak > 0
                                         ? DS.Color.warning
                                         : DS.Color.textQuaternary)
                    Text("\(habit.streak)d")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(habit.streak > 0
                                         ? DS.Color.textPrimary
                                         : DS.Color.textTertiary)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, DS.Space.base)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
