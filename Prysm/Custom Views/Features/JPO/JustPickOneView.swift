//
//  JustPickOneView.swift
//  Prysm
//
//  "Just Pick One" — redesigned to match HabitsFullView design language.
//  Same header pattern, same hero card, same section headers,
//  same surface card + shadow system, same row anatomy.
//

import SwiftUI
import Combine

// MARK: - Root
struct JustPickOneView: View {
    @StateObject private var vm = JustPickOneViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    JPOHeaderSection(
                        availableMinutes: vm.availableMinutes,
                        energyLevel:      vm.energyLevel
                    )
                    .staggeredAppear(appeared, delay: 0.04)

                    JPOContextHero(
                        availableMinutes: vm.availableMinutes,
                        energyLevel:      vm.energyLevel,
                        timeWindow:       vm.timeWindow,
                        mealAccepted:     vm.mealAccepted,
                        taskAccepted:     vm.taskAccepted
                    )
                    .staggeredAppear(appeared, delay: 0.10)

                    MealDecisionCard(vm: vm)
                        .staggeredAppear(appeared, delay: 0.18)

                    TaskDecisionCard(vm: vm)
                        .staggeredAppear(appeared, delay: 0.24)

                    PantryStatusSection(items: vm.pantryItems)
                        .staggeredAppear(appeared, delay: 0.30)

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
class JustPickOneViewModel: ObservableObject {

    @Published var currentMeal: MealSuggestion    = MealSuggestion.suggestions[0]
    @Published var mealAccepted: Bool             = false
    @Published var mealSkipCount: Int             = 0
    @Published var isScanning: Bool               = false

    @Published var currentTask: TaskSuggestion    = TaskSuggestion.suggestions[0]
    @Published var taskAccepted: Bool             = false
    @Published var taskSkipCount: Int             = 0

    @Published var pantryItems: [PantryItem]      = PantryItem.sampleData

    let availableMinutes: Int    = 28
    let energyLevel: String      = "High"
    let timeWindow: String       = "6:50 – 7:20 PM"

    func skipMeal() {
        guard !mealAccepted else { return }
        withAnimation(DS.Animation.standard) {
            mealSkipCount += 1
            currentMeal = MealSuggestion.suggestions[mealSkipCount % MealSuggestion.suggestions.count]
        }
    }
    func acceptMeal() {
        withAnimation(DS.Animation.snappy) { mealAccepted = true }
    }
    func resetMeal() {
        withAnimation(DS.Animation.snappy) {
            mealAccepted = false
            mealSkipCount = 0
            currentMeal = MealSuggestion.suggestions[0]
        }
    }

    func skipTask() {
        guard !taskAccepted else { return }
        withAnimation(DS.Animation.standard) {
            taskSkipCount += 1
            currentTask = TaskSuggestion.suggestions[taskSkipCount % TaskSuggestion.suggestions.count]
        }
    }
    func acceptTask() {
        withAnimation(DS.Animation.snappy) { taskAccepted = true }
    }
    func resetTask() {
        withAnimation(DS.Animation.snappy) {
            taskAccepted = false
            taskSkipCount = 0
            currentTask = TaskSuggestion.suggestions[0]
        }
    }

    func scanFridge() {
        isScanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(DS.Animation.standard) { self.isScanning = false }
        }
    }
}

// MARK: - Header  (mirrors HabitsHeaderSection exactly)
struct JPOHeaderSection: View {
    let availableMinutes: Int
    let energyLevel: String

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
                Text("Just Pick One")
                    .font(DS.Font.title1())
                    .foregroundColor(DS.Color.textPrimary)
                Text("\(availableMinutes) min window · \(energyLevel) energy")
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textSecondary)
            }
            Spacer()
            // Energy badge — mirrors flame badge in HabitsHeaderSection
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Color.accent)
                Text(energyLevel)
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

// MARK: - Context Hero  (mirrors HabitsStreakHero — same height, same anatomy)
struct JPOContextHero: View {
    let availableMinutes: Int
    let energyLevel: String
    let timeWindow: String
    let mealAccepted: Bool
    let taskAccepted: Bool

    private var doneCount: Int { (mealAccepted ? 1 : 0) + (taskAccepted ? 1 : 0) }
    private var progress: Double { Double(doneCount) / 2.0 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Flat accent base — same treatment, different accent (indigo→teal-ish)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "3D7EF5"))

            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Decisions Left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .tracking(0.3)
                        Text("\(2 - doneCount) of 2")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    // Progress ring — same ProgressRing component
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

                Text(doneCount == 2
                     ? "All set — enjoy your meal and stay focused."
                     : "One tap to lock in your next move.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.74))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 28)

                // Stat pills — same HeroStatPill pattern
                HStack(spacing: 10) {
                    HeroStatPill2(icon: "clock.fill",        value: "\(availableMinutes)m",  label: "Available")
                    HeroStatPill2(icon: "bolt.fill",         value: energyLevel,              label: "Energy")
                    HeroStatPill2(icon: "checkmark.circle.fill", value: "\(doneCount)/2",    label: "Decided")
                }
            }
            .padding(24)
        }
        .frame(height: 248)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "3D7EF5").opacity(0.45), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
    }
}

// Local hero pill — identical shape to HabitsStreakHero's HeroStatPill
private struct HeroStatPill2: View {
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

// MARK: - Meal Decision Card  (mirrors HabitsCategorySection container)
struct MealDecisionCard: View {
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(spacing: DS.Space.md) {

            // Section header — exact HabitsCategorySection pattern (no icon)
            HStack {
                Text("Meal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                // Context badge — mirrors count badge
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11))
                        .foregroundColor(DS.Color.textTertiary)
                    Text("\(vm.availableMinutes) min window")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DS.Color.textTertiary.opacity(0.08))
                )
            }

            // Card body — same surface + shadow as HabitsCategorySection
            VStack(spacing: 0) {
                if vm.mealAccepted {
                    MealAcceptedView(meal: vm.currentMeal) { vm.resetMeal() }
                        .padding(DS.Space.base)
                } else {
                    MealSuggestionView(meal: vm.currentMeal, vm: vm)
                        .padding(DS.Space.base)
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

struct MealSuggestionView: View {
    let meal: MealSuggestion
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Meal name + tags — mirrors FullHabitRow content column
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(meal.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)

                HStack(spacing: DS.Space.md) {
                    JPOTag(icon: "clock", text: "\(meal.prepMinutes) min")
                    JPOTag(icon: "flame", text: meal.difficulty)
                    ConfidenceTag(tag: meal.confidenceTag)
                }
            }

            // Steps block — same surfaceHigh inner card
            VStack(spacing: 0) {
                ForEach(Array(meal.steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: DS.Space.md) {
                        Text("\(idx + 1)")
                            .font(DS.Font.mono(11))
                            .foregroundColor(DS.Color.textQuaternary)
                            .frame(width: 16, alignment: .trailing)
                            .padding(.top, 2)
                        Text(step)
                            .font(DS.Font.footnote())
                            .foregroundColor(DS.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.vertical, DS.Space.sm)
                    if idx < meal.steps.count - 1 {
                        Divider().opacity(0.25)
                    }
                }
            }
            .padding(DS.Space.md)
            .background(DS.Color.surfaceHigh)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Ingredients row — mirrors subtitle in FullHabitRow
            if !meal.ingredients.isEmpty {
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "refrigerator")
                        .font(.system(size: 11, weight: .ultraLight))
                        .foregroundColor(DS.Color.textTertiary)
                    Text(meal.ingredients.joined(separator: " · "))
                        .font(DS.Font.caption1())
                        .foregroundColor(DS.Color.textTertiary)
                        .lineLimit(1)
                }
            }

            Divider().opacity(0.25)

            // Action row — same button trio pattern
            HStack(spacing: DS.Space.sm) {
                // Scan fridge
                Button(action: vm.scanFridge) {
                    HStack(spacing: DS.Space.xs) {
                        if vm.isScanning {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(DS.Color.textTertiary)
                        } else {
                            Image(systemName: "camera")
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(DS.Color.textTertiary)
                        }
                        Text(vm.isScanning ? "Scanning…" : "Scan fridge")
                            .font(DS.Font.footnote())
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Color.border, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isScanning)

                // Skip
                Button(action: vm.skipMeal) {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .light))
                        Text("Next")
                            .font(DS.Font.footnote())
                    }
                    .foregroundColor(DS.Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Color.border, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                // Accept — same dark fill treatment as Habits positive CTA
                Button(action: vm.acceptMeal) {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .regular))
                        Text("Let's cook")
                            .font(DS.Font.footnote())
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        ))
        .id(meal.id)
    }
}

struct MealAcceptedView: View {
    let meal: MealSuggestion
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Accepted header — mirrors FullHabitRow checked state
            HStack(spacing: DS.Space.md) {
                // Left color bar — same 3pt bar from FullHabitRow
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(DS.Color.positive)
                    .frame(width: 3, height: 36)

                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.positive)
                    .frame(width: 30, alignment: .center)

                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Text("Locked in")
                        .font(DS.Font.caption1())
                        .foregroundColor(DS.Color.positive)
                    Text(meal.name)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Color.textPrimary)
                }
                Spacer()
            }

            // Steps block in positive tint
            VStack(spacing: 0) {
                ForEach(Array(meal.steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: DS.Space.md) {
                        ZStack {
                            Circle()
                                .fill(DS.Color.positiveSoft)
                                .frame(width: 20, height: 20)
                            Text("\(idx + 1)")
                                .font(DS.Font.mono(10))
                                .foregroundColor(DS.Color.positive)
                        }
                        Text(step)
                            .font(DS.Font.footnote())
                            .foregroundColor(DS.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.vertical, DS.Space.sm)
                    if idx < meal.steps.count - 1 {
                        Divider().opacity(0.25)
                    }
                }
            }
            .padding(DS.Space.md)
            .background(DS.Color.positiveSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: onReset) {
                Text("Pick something else")
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textTertiary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .transition(.opacity)
    }
}

// MARK: - Task Decision Card  (mirrors HabitsCategorySection container)
struct TaskDecisionCard: View {
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(spacing: DS.Space.md) {

            // Section header — same text-only pattern, no icon
            HStack {
                Text("Task")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                // Energy badge — mirrors category count badge
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DS.Color.accent)
                    Text(vm.energyLevel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DS.Color.textTertiary.opacity(0.08))
                )
            }

            // Card body — same surface container
            VStack(spacing: 0) {
                if vm.taskAccepted {
                    TaskAcceptedView(task: vm.currentTask) { vm.resetTask() }
                        .padding(DS.Space.base)
                } else {
                    TaskSuggestionView(task: vm.currentTask, vm: vm)
                        .padding(DS.Space.base)
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

struct TaskSuggestionView: View {
    let task: TaskSuggestion
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Task name + tags — same anatomy as MealSuggestionView
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(task.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)

                HStack(spacing: DS.Space.md) {
                    JPOTag(icon: "clock",  text: "\(task.estimatedMinutes) min")
                    JPOTag(icon: "brain",  text: task.cognitiveLoad)
                    JPOTag(icon: "flag",   text: task.source)
                }
            }

            // Why now — accent-tinted inner card, same surfaceHigh treatment
            HStack(alignment: .top, spacing: DS.Space.sm) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(DS.Color.accent)
                    .padding(.top, 1)
                Text(task.whyNow)
                    .font(DS.Font.caption1())
                    .foregroundColor(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Space.md)
            .background(DS.Color.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Timer hint — mirrors subtitle row
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundColor(DS.Color.textTertiary)
                Text("Suggested: \(task.timerMinutes) min focus block")
                    .font(DS.Font.caption1())
                    .foregroundColor(DS.Color.textTertiary)
            }

            Divider().opacity(0.25)

            // Action row
            HStack(spacing: DS.Space.sm) {
                Button(action: vm.skipTask) {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .light))
                        Text("Different task")
                            .font(DS.Font.footnote())
                    }
                    .foregroundColor(DS.Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Color.border, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                Button(action: vm.acceptTask) {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: "timer")
                            .font(.system(size: 12, weight: .regular))
                        Text("Start timer")
                            .font(DS.Font.footnote())
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        ))
        .id(task.id)
    }
}

struct TaskAcceptedView: View {
    let task: TaskSuggestion
    let onReset: () -> Void

    @State private var secondsElapsed: Int = 0
    @State private var timerActive: Bool   = true
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var elapsed: String {
        let m = secondsElapsed / 60
        let s = secondsElapsed % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Accepted header — same left-bar + icon + content anatomy as FullHabitRow
            HStack(spacing: DS.Space.md) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(DS.Color.accent)
                    .frame(width: 3, height: 36)

                Image(systemName: "timer")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.accent)
                    .frame(width: 30, alignment: .center)

                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Text("In progress")
                        .font(DS.Font.caption1())
                        .foregroundColor(DS.Color.accent)
                    Text(task.title)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Color.textPrimary)
                }
                Spacer()

                // Live timer — right-aligned, same trailing meta position as streak chip
                VStack(alignment: .trailing, spacing: DS.Space.xxs) {
                    Text(elapsed)
                        .font(DS.Font.mono(20))
                        .foregroundColor(DS.Color.textPrimary)
                        .onReceive(timer) { _ in
                            if timerActive { secondsElapsed += 1 }
                        }
                    Text("elapsed")
                        .font(DS.Font.caption2())
                        .foregroundColor(DS.Color.textTertiary)
                }
            }

            // Progress bar — same thin capsule used in PlanView / HomeView
            let targetSeconds = task.timerMinutes * 60
            let progress = min(Double(secondsElapsed) / Double(targetSeconds), 1.0)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Color.textQuaternary)
                        .frame(height: 2)
                    Capsule()
                        .fill(DS.Color.accent)
                        .frame(width: geo.size.width * progress, height: 2)
                        .animation(DS.Animation.gentle, value: progress)
                }
            }
            .frame(height: 2)

            // Action row
            HStack(spacing: DS.Space.sm) {
                Button {
                    timerActive.toggle()
                } label: {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: timerActive ? "pause" : "play")
                            .font(.system(size: 12, weight: .light))
                        Text(timerActive ? "Pause" : "Resume")
                            .font(DS.Font.footnote())
                    }
                    .foregroundColor(DS.Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Color.border, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                Button(action: onReset) {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .regular))
                        Text("Done")
                            .font(DS.Font.footnote())
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.positive)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Pantry Status Section  (mirrors HabitsWeekGrid section anatomy)
struct PantryStatusSection: View {
    let items: [PantryItem]

    var expiringItems: [PantryItem] { items.filter { $0.daysLeft != nil && $0.daysLeft! <= 2 } }
    var freshItems:    [PantryItem] { items.filter { $0.daysLeft == nil || $0.daysLeft! > 2 } }

    var body: some View {
        VStack(spacing: DS.Space.md) {

            // Section header — same HStack pattern, no icon, badge on right
            HStack {
                Text("Pantry")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                HStack(spacing: DS.Space.sm) {
                    if !expiringItems.isEmpty {
                        Text("\(expiringItems.count) expiring")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DS.Color.warning)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(DS.Color.warning.opacity(0.10))
                            )
                    }
                    Button {
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.system(size: 11, weight: .light))
                            Text("Scan")
                                .font(DS.Font.footnote())
                        }
                        .foregroundColor(DS.Color.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(DS.Color.accent.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Rows — same surface card + shadow, no dividers
            VStack(spacing: 0) {
                ForEach(expiringItems) { item in
                    PantryRow(item: item)
                }
                ForEach(freshItems) { item in
                    PantryRow(item: item)
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

struct PantryRow: View {
    let item: PantryItem

    var isExpiring: Bool { item.daysLeft != nil && item.daysLeft! <= 2 }

    var body: some View {
        HStack(spacing: 14) {

            // Left color bar — same 3pt bar from FullHabitRow
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isExpiring ? DS.Color.warning : DS.Color.textQuaternary.opacity(0.3))
                .frame(width: 3, height: 28)

            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(isExpiring ? DS.Color.warning : DS.Color.textTertiary)
                .frame(width: 24, alignment: .center)

            // Name
            Text(item.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DS.Color.textPrimary)

            Spacer()

            // Trailing meta — mirrors streak chip position
            if let days = item.daysLeft {
                Text(days <= 1 ? "Expires today" : "Expires in \(days)d")
                    .font(DS.Font.caption1())
                    .foregroundColor(days <= 1 ? DS.Color.negative : DS.Color.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill((days <= 1 ? DS.Color.negative : DS.Color.warning).opacity(0.10))
                    )
            } else {
                Text(item.quantity)
                    .font(DS.Font.caption1())
                    .foregroundColor(DS.Color.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(DS.Color.textTertiary.opacity(0.08))
                    )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}

// MARK: - Supporting UI  (unchanged — shared helpers)
struct JPOTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: DS.Space.xxs + 1) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .ultraLight))
                .foregroundColor(DS.Color.textTertiary)
            Text(text)
                .font(DS.Font.caption1())
                .foregroundColor(DS.Color.textTertiary)
        }
    }
}

struct ConfidenceTag: View {
    enum Tag: String {
        case favorite = "Favourite"
        case newEasy  = "New · easy"
        case useItUp  = "Use it up"
    }
    let tag: Tag

    var color: Color {
        switch tag {
        case .favorite: return DS.Color.accent
        case .newEasy:  return DS.Color.categoryB
        case .useItUp:  return DS.Color.warning
        }
    }

    var body: some View {
        Text(tag.rawValue)
            .font(DS.Font.caption2())
            .foregroundColor(color)
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.xxs + 1)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }
}

// MARK: - Models  (unchanged)

struct MealSuggestion: Identifiable {
    let id = UUID()
    var name: String
    var prepMinutes: Int
    var difficulty: String
    var confidenceTag: ConfidenceTag.Tag
    var ingredients: [String]
    var steps: [String]

    static let suggestions: [MealSuggestion] = [
        MealSuggestion(
            name: "Garlic butter pasta",
            prepMinutes: 18,
            difficulty: "Easy",
            confidenceTag: .favorite,
            ingredients: ["Pasta", "Garlic", "Butter", "Parmesan"],
            steps: [
                "Boil salted water, cook pasta until al dente (11 min).",
                "Melt butter in pan, sauté minced garlic 2 min until fragrant.",
                "Toss pasta in butter sauce, finish with parmesan and black pepper."
            ]
        ),
        MealSuggestion(
            name: "Egg fried rice",
            prepMinutes: 12,
            difficulty: "Easy",
            confidenceTag: .useItUp,
            ingredients: ["Rice", "Eggs", "Soy sauce", "Spring onion"],
            steps: [
                "Heat wok or pan until very hot. Add oil.",
                "Scramble eggs in pan, push to side. Add cold rice, break up clumps.",
                "Add soy sauce and spring onion. Toss everything together 2 min."
            ]
        ),
        MealSuggestion(
            name: "Avocado toast with poached egg",
            prepMinutes: 10,
            difficulty: "Easy",
            confidenceTag: .newEasy,
            ingredients: ["Bread", "Avocado", "Eggs", "Lemon"],
            steps: [
                "Toast bread. Mash avocado with lemon juice, salt, and pepper.",
                "Bring water to gentle simmer, add splash of vinegar. Crack egg in.",
                "Poach egg 3 min. Spread avo on toast, top with egg and chilli flakes."
            ]
        ),
        MealSuggestion(
            name: "Chicken stir fry",
            prepMinutes: 22,
            difficulty: "Medium",
            confidenceTag: .favorite,
            ingredients: ["Chicken breast", "Broccoli", "Soy sauce", "Garlic"],
            steps: [
                "Slice chicken thin. Mix soy sauce, garlic, a bit of sesame oil.",
                "High heat: cook chicken 4 min each side until golden. Set aside.",
                "Stir fry broccoli 3 min, return chicken, pour sauce over. Toss."
            ]
        ),
    ]
}

struct TaskSuggestion: Identifiable {
    let id = UUID()
    var title: String
    var estimatedMinutes: Int
    var cognitiveLoad: String
    var source: String
    var whyNow: String
    var timerMinutes: Int

    static let suggestions: [TaskSuggestion] = [
        TaskSuggestion(
            title: "Review thesis outline",
            estimatedMinutes: 45,
            cognitiveLoad: "Deep work",
            source: "Todoist",
            whyNow: "Your energy is at peak right now (9–11am window). This is your highest-leverage task before the 1pm deadline pressure.",
            timerMinutes: 45
        ),
        TaskSuggestion(
            title: "Reply to prof email",
            estimatedMinutes: 10,
            cognitiveLoad: "Reactive",
            source: "Mail",
            whyNow: "Quick win. Clears a mental loop that's been open since yesterday. Best done before your focus block.",
            timerMinutes: 15
        ),
        TaskSuggestion(
            title: "Review lecture notes — CCS 101",
            estimatedMinutes: 30,
            cognitiveLoad: "Study",
            source: "Plan",
            whyNow: "Class is in 2.5 hours. A quick review now will make the lecture land better.",
            timerMinutes: 30
        ),
        TaskSuggestion(
            title: "Plan tomorrow's schedule",
            estimatedMinutes: 10,
            cognitiveLoad: "Admin",
            source: "Prysm",
            whyNow: "Your energy is winding down. Admin work fits this window perfectly — saves you decision fatigue tomorrow morning.",
            timerMinutes: 10
        ),
    ]
}

struct PantryItem: Identifiable {
    let id = UUID()
    var icon: String
    var name: String
    var quantity: String
    var daysLeft: Int?

    static let sampleData: [PantryItem] = [
        PantryItem(icon: "leaf",           name: "Spinach",   quantity: "1 bag",  daysLeft: 1),
        PantryItem(icon: "oval",           name: "Eggs",      quantity: "4 left", daysLeft: 2),
        PantryItem(icon: "drop.fill",      name: "Milk",      quantity: "Half",   daysLeft: 2),
        PantryItem(icon: "circle.fill",    name: "Pasta",     quantity: "500g",   daysLeft: nil),
        PantryItem(icon: "cube.fill",      name: "Rice",      quantity: "1kg",    daysLeft: nil),
        PantryItem(icon: "bolt.fill",      name: "Olive oil", quantity: "Plenty", daysLeft: nil),
        PantryItem(icon: "star.fill",      name: "Garlic",    quantity: "1 head", daysLeft: nil),
        PantryItem(icon: "rectangle.fill", name: "Butter",    quantity: "100g",   daysLeft: nil),
    ]
}
