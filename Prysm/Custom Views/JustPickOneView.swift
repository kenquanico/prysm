//
//  JustPickOneView.swift
//  Prysm
//
//  Created by Ken Aldrey Quanico on 5/25/26.
//


//
//  JustPickOneView.swift
//  Prysm
//
//  "Just Pick One" — Prysm's signature decision engine.
//  One answer. Not ten options.
//  Cross-references fridge inventory, calendar time, and energy state
//  to surface exactly one meal and one task at any moment.
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
                VStack(spacing: DS.Space.xl) {

                    JPOHeaderSection()
                        .staggeredAppear(appeared, delay: 0.04)

                    // MEAL CARD
                    MealDecisionCard(vm: vm)
                        .staggeredAppear(appeared, delay: 0.10)

                    // TASK CARD
                    TaskDecisionCard(vm: vm)
                        .staggeredAppear(appeared, delay: 0.18)

                    // PANTRY STATUS
                    PantryStatusSection(items: vm.pantryItems)
                        .staggeredAppear(appeared, delay: 0.26)

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

    // Meal decisioning
    @Published var currentMeal: MealSuggestion = MealSuggestion.suggestions[0]
    @Published var mealAccepted: Bool = false
    @Published var mealSkipCount: Int = 0
    @Published var isScanning: Bool = false

    // Task decisioning
    @Published var currentTask: TaskSuggestion = TaskSuggestion.suggestions[0]
    @Published var taskAccepted: Bool = false
    @Published var taskSkipCount: Int = 0

    // Pantry
    @Published var pantryItems: [PantryItem] = PantryItem.sampleData

    // Context (would come from HealthKit + Calendar in production)
    let availableMinutes: Int = 28
    let energyLevel: String = "High"
    let timeWindow: String = "6:50 – 7:20 PM"

    func skipMeal() {
        guard !mealAccepted else { return }
        withAnimation(DS.Animation.standard) {
            mealSkipCount += 1
            let next = MealSuggestion.suggestions[mealSkipCount % MealSuggestion.suggestions.count]
            currentMeal = next
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
            let next = TaskSuggestion.suggestions[taskSkipCount % TaskSuggestion.suggestions.count]
            currentTask = next
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
        // Simulates fridge scan — in production this calls the on-device CV model
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(DS.Animation.standard) { self.isScanning = false }
        }
    }
}

// MARK: - Header
struct JPOHeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs) {
            Text("Right now")
                .font(DS.Font.footnote())
                .foregroundColor(DS.Color.textTertiary)
            Text("Just Pick One")
                .font(DS.Font.title1())
                .foregroundColor(DS.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DS.Space.sm)
    }
}

// MARK: - Meal Decision Card
// This is the core Prysm UX: one suggestion, swipe for next.
// No lists. No menus. One answer.
struct MealDecisionCard: View {
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Section label + context
            HStack {
                Label("MEAL", systemImage: "fork.knife")
                    .font(DS.Font.caption2())
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.textTertiary)
                    .tracking(0.8)
                Spacer()
                // Time window from calendar
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11, weight: .ultraLight))
                        .foregroundColor(DS.Color.textTertiary)
                    Text("\(vm.availableMinutes) min window")
                        .font(DS.Font.caption2())
                        .foregroundColor(DS.Color.textTertiary)
                }
            }
            .padding(.bottom, DS.Space.md)

            if vm.mealAccepted {
                // Accepted state
                MealAcceptedView(meal: vm.currentMeal) {
                    vm.resetMeal()
                }
            } else {
                // Decision state — ONE suggestion
                MealSuggestionView(meal: vm.currentMeal, vm: vm)
            }
        }
        .surfaceCard()
    }
}

struct MealSuggestionView: View {
    let meal: MealSuggestion
    @ObservedObject var vm: JustPickOneViewModel
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Meal name — large, confident
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(meal.name)
                    .font(DS.Font.title2())
                    .foregroundColor(DS.Color.textPrimary)
                    .offset(x: dragOffset * 0.3)

                HStack(spacing: DS.Space.md) {
                    JPOTag(icon: "clock", text: "\(meal.prepMinutes) min")
                    JPOTag(icon: "flame", text: meal.difficulty)
                    ConfidenceTag(tag: meal.confidenceTag)
                }
            }

            // 3-step card — not a full recipe, just enough to execute
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
                        SoftDivider()
                    }
                }
            }
            .padding(DS.Space.md)
            .background(DS.Color.surfaceHigh)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — inner surface

            // Ingredients used (from fridge scan)
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

            SoftDivider()

            // Action row — This is it. Yes or next.
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
                                .font(.system(size: 13, weight: .ultraLight))
                                .foregroundColor(DS.Color.textTertiary)
                        }
                        Text(vm.isScanning ? "Scanning…" : "Scan fridge")
                            .font(DS.Font.footnote())
                            .foregroundColor(DS.Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — button
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Color.border, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isScanning)

                // Skip — swipe feel without swipe
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
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — button
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Color.border, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                // Accept — the one tap that ends the decision
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
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — button
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .id(meal.id)
    }
}

struct MealAcceptedView: View {
    let meal: MealSuggestion
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.md) {
                ZStack {
                    Circle()
                        .fill(DS.Color.positiveSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(DS.Color.positive)
                }
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
                    if idx < meal.steps.count - 1 { SoftDivider() }
                }
            }
            .padding(DS.Space.md)
            .background(DS.Color.positiveSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — inner surface

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

// MARK: - Task Decision Card
// Same philosophy as meal — one task, not a list.
// Cross-references energy level + deadlines + historical patterns.
struct TaskDecisionCard: View {
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                Label("TASK", systemImage: "sparkles")
                    .font(DS.Font.caption2())
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.textTertiary)
                    .tracking(0.8)
                Spacer()
                EnergyDot(level: .high)
            }
            .padding(.bottom, DS.Space.md)

            if vm.taskAccepted {
                TaskAcceptedView(task: vm.currentTask) { vm.resetTask() }
            } else {
                TaskSuggestionView(task: vm.currentTask, vm: vm)
            }
        }
        .surfaceCard()
    }
}

struct TaskSuggestionView: View {
    let task: TaskSuggestion
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // The one task
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(task.title)
                    .font(DS.Font.title2())
                    .foregroundColor(DS.Color.textPrimary)

                HStack(spacing: DS.Space.md) {
                    JPOTag(icon: "clock",      text: "\(task.estimatedMinutes) min")
                    JPOTag(icon: "brain",      text: task.cognitiveLoad)
                    JPOTag(icon: "flag",       text: task.source)
                }
            }

            // Why now — the reasoning Prysm surfaced this
            HStack(alignment: .top, spacing: DS.Space.sm) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 12, weight: .ultraLight))
                    .foregroundColor(DS.Color.accent)
                    .padding(.top, 1)
                Text(task.whyNow)
                    .font(DS.Font.caption1())
                    .foregroundColor(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Space.md)
            .background(DS.Color.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — inner surface

            // Timer suggestion — already attached
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundColor(DS.Color.textTertiary)
                Text("Suggested: \(task.timerMinutes) min focus block")
                    .font(DS.Font.caption1())
                    .foregroundColor(DS.Color.textTertiary)
            }

            SoftDivider()

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
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — button
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
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — button
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .id(task.id)
    }
}

struct TaskAcceptedView: View {
    let task: TaskSuggestion
    let onReset: () -> Void

    @State private var secondsElapsed: Int = 0
    @State private var timerActive: Bool = true
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var elapsed: String {
        let m = secondsElapsed / 60
        let s = secondsElapsed % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Text("In progress")
                        .font(DS.Font.caption1())
                        .foregroundColor(DS.Color.accent)
                    Text(task.title)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Color.textPrimary)
                }
                Spacer()
                // Live timer
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

            // Progress toward suggested duration
            let targetSeconds = task.timerMinutes * 60
            let progress = min(Double(secondsElapsed) / Double(targetSeconds), 1.0)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.textQuaternary).frame(height: 2)
                    Capsule()
                        .fill(DS.Color.accent)
                        .frame(width: geo.size.width * progress, height: 2)
                        .animation(DS.Animation.gentle, value: progress)
                }
            }
            .frame(height: 2)

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
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — button
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
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // Apple standard — button
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Pantry Status Section
// Shows what Prysm knows is in your fridge. Flags items nearing expiry.
struct PantryStatusSection: View {
    let items: [PantryItem]

    var expiringItems: [PantryItem] { items.filter { $0.daysLeft != nil && $0.daysLeft! <= 2 } }
    var freshItems:    [PantryItem] { items.filter { $0.daysLeft == nil || $0.daysLeft! > 2 } }

    var body: some View {
        VStack(spacing: DS.Space.md) {
            SectionHeader(title: "Pantry") {
                HStack(spacing: DS.Space.xs) {
                    if !expiringItems.isEmpty {
                        Text("\(expiringItems.count) expiring soon")
                            .font(DS.Font.caption1())
                            .foregroundColor(DS.Color.warning)
                    }
                    Button {
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "camera")
                                .font(.system(size: 11, weight: .ultraLight))
                            Text("Scan")
                                .font(DS.Font.footnote())
                        }
                        .foregroundColor(DS.Color.accent)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 0) {
                if !expiringItems.isEmpty {
                    ForEach(expiringItems) { item in
                        PantryRow(item: item)
                        SoftDivider()
                    }
                }
                ForEach(Array(freshItems.enumerated()), id: \.element.id) { idx, item in
                    PantryRow(item: item)
                    if idx < freshItems.count - 1 { SoftDivider() }
                }
            }
            .surfaceCard(padding: 0)
        }
    }
}

struct PantryRow: View {
    let item: PantryItem

    var body: some View {
        HStack(spacing: DS.Space.md) {
            Image(systemName: item.icon)
                .font(.system(size: 14, weight: .ultraLight))
                .foregroundColor(item.daysLeft != nil && item.daysLeft! <= 2 ? DS.Color.warning : DS.Color.textTertiary)
                .frame(width: 20)

            Text(item.name)
                .font(DS.Font.subheadline())
                .foregroundColor(DS.Color.textPrimary)

            Spacer()

            if let days = item.daysLeft {
                Text(days <= 1 ? "Expires today" : "Expires in \(days)d")
                    .font(DS.Font.caption1())
                    .foregroundColor(days <= 1 ? DS.Color.negative : DS.Color.warning)
            } else {
                Text(item.quantity)
                    .font(DS.Font.caption1())
                    .foregroundColor(DS.Color.textTertiary)
            }
        }
        .padding(.horizontal, DS.Space.base)
        .padding(.vertical, DS.Space.md)
    }
}

// MARK: - Supporting UI
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
        case favorite    = "Favourite"
        case newEasy     = "New · easy"
        case useItUp     = "Use it up"
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
            .clipShape(Capsule()) // Pill tags always use Capsule — matches Apple's own chip/badge pattern
    }
}

// MARK: - Models

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
    var daysLeft: Int?   // nil = not tracked / fresh

    static let sampleData: [PantryItem] = [
        PantryItem(icon: "leaf",           name: "Spinach",      quantity: "1 bag",   daysLeft: 1),
        PantryItem(icon: "oval",           name: "Eggs",         quantity: "4 left",  daysLeft: 2),
        PantryItem(icon: "drop.fill",      name: "Milk",         quantity: "Half",    daysLeft: 2),
        PantryItem(icon: "circle.fill",    name: "Pasta",        quantity: "500g",    daysLeft: nil),
        PantryItem(icon: "cube.fill",      name: "Rice",         quantity: "1kg",     daysLeft: nil),
        PantryItem(icon: "bolt.fill",      name: "Olive oil",    quantity: "Plenty",  daysLeft: nil),
        PantryItem(icon: "star.fill",      name: "Garlic",       quantity: "1 head",  daysLeft: nil),
        PantryItem(icon: "rectangle.fill", name: "Butter",       quantity: "100g",    daysLeft: nil),
    ]
}
