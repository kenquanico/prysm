//
//  JustPickOneView.swift
//  Prysm
//
//  Meal-plan feature only.
//  Aligned to product doc: Fridge Vision scan, single suggestion output,
//  confidence tag, pantry expiry awareness, schedule-aware prep time.
//  Design language: mirrors HabitsFullView exactly (same DS tokens, same
//  card anatomy, same row pattern, same hero, same section headers).
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
                        energyLevel:      vm.energyLevel,
                        timeWindow:       vm.timeWindow
                    )
                    .staggeredAppear(appeared, delay: 0.04)

                    JPOContextHero(
                        availableMinutes: vm.availableMinutes,
                        energyLevel:      vm.energyLevel,
                        mealAccepted:     vm.mealAccepted
                    )
                    .staggeredAppear(appeared, delay: 0.10)

                    MealDecisionCard(vm: vm)
                        .staggeredAppear(appeared, delay: 0.18)

                    PantryStatusSection(items: vm.pantryItems)
                        .staggeredAppear(appeared, delay: 0.24)

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.base)
                .padding(.top, DS.Space.sm)
            }

            // Fridge scan overlay
            if vm.showFridgeScan {
                FridgeScanOverlay(vm: vm)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(10)
            }
        }
        .onAppear { appeared = true }
        .animation(DS.Animation.standard, value: vm.showFridgeScan)
    }
}

// MARK: - View Model

class JustPickOneViewModel: ObservableObject {

    // Meal
    @Published var currentMeal: MealSuggestion   = MealSuggestion.suggestions[0]
    @Published var mealAccepted: Bool            = false
    @Published var mealSkipCount: Int            = 0

    // Fridge scan
    @Published var showFridgeScan: Bool          = false
    @Published var scanPhase: ScanPhase          = .idle
    @Published var detectedItems: [String]       = []

    // Pantry
    @Published var pantryItems: [PantryItem]     = PantryItem.sampleData

    // Context — in production these come from HealthKit / Calendar
    let availableMinutes: Int  = 28
    let energyLevel: String    = "High"
    let timeWindow: String     = "6:50 – 7:20 PM"

    enum ScanPhase { case idle, scanning, revealing, done }

    // MARK: Meal actions

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
            mealAccepted  = false
            mealSkipCount = 0
            currentMeal   = MealSuggestion.suggestions[0]
        }
    }

    // MARK: Fridge scan

    func beginFridgeScan() {
        detectedItems = []
        scanPhase     = .scanning
        showFridgeScan = true

        // Simulate computer-vision detection: items reveal one by one
        let found = FridgeScanResult.sample
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(DS.Animation.standard) { self.scanPhase = .revealing }
            for (i, item) in found.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                    withAnimation(DS.Animation.snappy) { self.detectedItems.append(item) }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(found.count) * 0.25 + 0.4) {
                withAnimation(DS.Animation.standard) { self.scanPhase = .done }
                // Re-rank meal to prioritise expiring items
                self.refreshMealFromScan()
            }
        }
    }

    func dismissFridgeScan() {
        withAnimation(DS.Animation.standard) {
            showFridgeScan = false
            scanPhase      = .idle
        }
    }

    private func refreshMealFromScan() {
        // Prefer meals that use expiring pantry items
        let expiring = pantryItems
            .filter { $0.daysLeft != nil && $0.daysLeft! <= 2 }
            .map    { $0.name.lowercased() }

        let ranked = MealSuggestion.suggestions.sorted { a, b in
            let aMatch = a.ingredients.filter { expiring.contains($0.lowercased()) }.count
            let bMatch = b.ingredients.filter { expiring.contains($0.lowercased()) }.count
            return aMatch > bMatch
        }

        withAnimation(DS.Animation.standard) {
            currentMeal   = ranked.first ?? MealSuggestion.suggestions[0]
            mealSkipCount = MealSuggestion.suggestions.firstIndex(where: { $0.id == currentMeal.id }) ?? 0
        }
    }
}

// MARK: - Header  (mirrors HabitsHeaderSection)

struct JPOHeaderSection: View {
    let availableMinutes: Int
    let energyLevel: String
    let timeWindow: String

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
                Text("\(availableMinutes) min window · \(energyLevel) energy · \(timeWindow)")
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textSecondary)
            }
            Spacer()
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
            .shadow(color: Color.black.opacity(0.04), radius: 2,  x: 0, y: 1)
        }
        .padding(.top, DS.Space.sm)
    }
}

// MARK: - Context Hero  (mirrors HabitsStreakHero)

struct JPOContextHero: View {
    let availableMinutes: Int
    let energyLevel: String
    let mealAccepted: Bool

    private var progress: Double { mealAccepted ? 1.0 : 0.0 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "3D7EF5"))

            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mealAccepted ? "Meal locked" : "Meal pending")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .tracking(0.3)
                        Text(mealAccepted ? "Done" : "1 left")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    ZStack {
                        ProgressRing(
                            progress:   progress,
                            size:       64,
                            lineWidth:  5,
                            trackColor: Color.white.opacity(0.18),
                            ringColor:  .white
                        )
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .animation(DS.Animation.gentle, value: progress)
                }

                Spacer(minLength: 10)

                Text(mealAccepted
                     ? "All set — enjoy your meal."
                     : "One tap to lock in what you're cooking tonight.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.74))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 28)

                HStack(spacing: 10) {
                    HeroStatPill2(icon: "clock.fill",          value: "\(availableMinutes)m", label: "Available")
                    HeroStatPill2(icon: "bolt.fill",           value: energyLevel,            label: "Energy")
                    HeroStatPill2(icon: "fork.knife",          value: mealAccepted ? "1" : "0", label: "Decided")
                }
            }
            .padding(24)
        }
        .frame(height: 232)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "3D7EF5").opacity(0.45), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.25),          radius:  6, x: 0, y: 4)
    }
}

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

// MARK: - Meal Decision Card  (mirrors HabitsCategorySection)

struct MealDecisionCard: View {
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(spacing: DS.Space.md) {

            // Section header
            HStack {
                Text("Meal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
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

            // Card body
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
            .shadow(color: Color.black.opacity(0.03), radius:  3, x: 0, y: 1)
        }
    }
}

// MARK: - Meal Suggestion View

struct MealSuggestionView: View {
    let meal: MealSuggestion
    @ObservedObject var vm: JustPickOneViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Name + tags
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(meal.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)

                HStack(spacing: DS.Space.md) {
                    JPOTag(icon: "clock",  text: "\(meal.prepMinutes) min")
                    JPOTag(icon: "flame",  text: meal.difficulty)
                    ConfidenceTag(tag: meal.confidenceTag)
                }
            }

            // Why this meal — context insight card (product doc: "confidence tag + context")
            if let reason = meal.contextReason {
                HStack(alignment: .top, spacing: DS.Space.sm) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(DS.Color.accent)
                        .padding(.top, 1)
                    Text(reason)
                        .font(DS.Font.caption1())
                        .foregroundColor(DS.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(DS.Space.md)
                .background(DS.Color.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Steps block
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

            // Ingredients row
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

            // Expiring ingredient warning (product doc: "flags items nearing expiry")
            let expiringUsed = meal.ingredients.filter { ing in
                vm.pantryItems.contains { $0.name.localizedCaseInsensitiveContains(ing) && $0.daysLeft != nil && $0.daysLeft! <= 2 }
            }
            if !expiringUsed.isEmpty {
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(DS.Color.warning)
                    Text("Uses expiring: \(expiringUsed.joined(separator: ", "))")
                        .font(DS.Font.caption1())
                        .foregroundColor(DS.Color.warning)
                }
                .padding(.horizontal, DS.Space.sm)
                .padding(.vertical, DS.Space.xs)
                .background(DS.Color.warning.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Divider().opacity(0.25)

            // Action row
            HStack(spacing: DS.Space.sm) {
                // Fridge scan (Prysm core feature)
                Button(action: vm.beginFridgeScan) {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: "camera")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(DS.Color.textTertiary)
                        Text("Scan fridge")
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

                // Accept
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

// MARK: - Meal Accepted View

struct MealAcceptedView: View {
    let meal: MealSuggestion
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Accepted header — left bar + icon + content (same as FullHabitRow checked state)
            HStack(spacing: DS.Space.md) {
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

            // Steps — positive tint
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

// MARK: - Fridge Scan Overlay  (product doc: Fridge Vision Integration)

struct FridgeScanOverlay: View {
    @ObservedObject var vm: JustPickOneViewModel
    @State private var scanLineY: CGFloat = 0

    var body: some View {
        ZStack {
            // Dim backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { vm.dismissFridgeScan() }

            VStack(spacing: 0) {

                // Handle
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(DS.Color.textQuaternary)
                    .frame(width: 36, height: 4)
                    .padding(.bottom, DS.Space.md)

                // Sheet
                VStack(alignment: .leading, spacing: DS.Space.lg) {

                    // Header
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(DS.Color.accent)
                        Text("Fridge Vision")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                        Spacer()
                        Button(action: vm.dismissFridgeScan) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DS.Color.textTertiary)
                                .padding(8)
                                .background(DS.Color.surfaceHigh)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Viewfinder
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DS.Color.surfaceHigh)
                            .frame(height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(DS.Color.border, lineWidth: 0.5)
                            )

                        if vm.scanPhase == .scanning {
                            // Animated scan line
                            GeometryReader { geo in
                                Capsule()
                                    .fill(DS.Color.accent.opacity(0.7))
                                    .frame(height: 2)
                                    .offset(y: scanLineY)
                                    .onAppear {
                                        withAnimation(
                                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                                        ) { scanLineY = geo.size.height - 2 }
                                    }
                            }
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack {
                                Spacer()
                                Text("Scanning contents…")
                                    .font(DS.Font.caption1())
                                    .foregroundColor(DS.Color.textTertiary)
                                    .padding(.bottom, DS.Space.md)
                            }
                            .frame(height: 180)
                        }

                        if vm.scanPhase == .revealing || vm.scanPhase == .done {
                            // Detected items appear one-by-one
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Space.sm) {
                                    ForEach(vm.detectedItems, id: \.self) { item in
                                        Text(item)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(DS.Color.accent)
                                            .padding(.horizontal, DS.Space.sm)
                                            .padding(.vertical, DS.Space.xs)
                                            .background(DS.Color.accentSoft)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                                    }
                                }
                                .padding(.horizontal, DS.Space.md)
                            }
                            .frame(height: 180)
                        }
                    }

                    // Status / result
                    if vm.scanPhase == .done {
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            HStack(spacing: DS.Space.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DS.Color.positive)
                                    .font(.system(size: 14))
                                Text("\(vm.detectedItems.count) items detected. Meal suggestion updated.")
                                    .font(DS.Font.footnote())
                                    .foregroundColor(DS.Color.textSecondary)
                            }

                            // Expiry highlight
                            let expiringDetected = vm.pantryItems
                                .filter { $0.daysLeft != nil && $0.daysLeft! <= 2 }
                            if !expiringDetected.isEmpty {
                                HStack(spacing: DS.Space.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(DS.Color.warning)
                                        .font(.system(size: 12))
                                    Text("Prioritised recipe using: \(expiringDetected.map { $0.name }.joined(separator: ", "))")
                                        .font(DS.Font.caption1())
                                        .foregroundColor(DS.Color.warning)
                                }
                                .padding(DS.Space.sm)
                                .background(DS.Color.warning.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }

                        // Done button
                        Button(action: vm.dismissFridgeScan) {
                            Text("Use this suggestion")
                                .font(DS.Font.footnote())
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DS.Space.sm)
                                .background(DS.Color.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)

                    } else if vm.scanPhase == .scanning {
                        HStack(spacing: DS.Space.sm) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(DS.Color.textTertiary)
                            Text("Identifying ingredients…")
                                .font(DS.Font.caption1())
                                .foregroundColor(DS.Color.textTertiary)
                        }
                    }
                }
                .padding(DS.Space.lg)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(DS.Color.surface)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 30, x: 0, y: -4)
            }
            .padding(.horizontal, DS.Space.base)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, DS.Space.xl)
        }
    }
}

// MARK: - Pantry Status Section  (mirrors HabitsWeekGrid anatomy)

struct PantryStatusSection: View {
    let items: [PantryItem]

    var expiringItems: [PantryItem] { items.filter { $0.daysLeft != nil && $0.daysLeft! <= 2 } }
    var freshItems:    [PantryItem] { items.filter { $0.daysLeft == nil || $0.daysLeft! > 2 } }

    var body: some View {
        VStack(spacing: DS.Space.md) {

            HStack {
                Text("Pantry")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
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
                Button { } label: {
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

            VStack(spacing: 0) {
                ForEach(expiringItems) { item in PantryRow(item: item) }
                ForEach(freshItems)    { item in PantryRow(item: item) }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.03), radius:  3, x: 0, y: 1)
        }
    }
}

struct PantryRow: View {
    let item: PantryItem

    var isExpiring: Bool { item.daysLeft != nil && item.daysLeft! <= 2 }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isExpiring ? DS.Color.warning : DS.Color.textQuaternary.opacity(0.3))
                .frame(width: 3, height: 28)

            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(isExpiring ? DS.Color.warning : DS.Color.textTertiary)
                .frame(width: 24, alignment: .center)

            Text(item.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DS.Color.textPrimary)

            Spacer()

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

// MARK: - Shared atoms

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
        case favorite  = "Favourite"
        case newEasy   = "New · easy"
        case useItUp   = "Use it up"
        case quickWin  = "Quick win"
    }
    let tag: Tag

    var color: Color {
        switch tag {
        case .favorite: return DS.Color.accent
        case .newEasy:  return DS.Color.categoryB
        case .useItUp:  return DS.Color.warning
        case .quickWin: return DS.Color.positive
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

// MARK: - Models

struct MealSuggestion: Identifiable {
    let id = UUID()
    var name: String
    var prepMinutes: Int
    var difficulty: String
    var confidenceTag: ConfidenceTag.Tag
    var ingredients: [String]
    var steps: [String]
    var contextReason: String?   // product doc: "why this meal right now"

    static let suggestions: [MealSuggestion] = [
        MealSuggestion(
            name:          "Egg fried rice",
            prepMinutes:   12,
            difficulty:    "Easy",
            confidenceTag: .useItUp,
            ingredients:   ["Rice", "Eggs", "Soy sauce", "Spring onion"],
            steps: [
                "Heat wok or pan until very hot. Add oil.",
                "Scramble eggs in pan, push to side. Add cold rice, break up clumps.",
                "Add soy sauce and spring onion. Toss everything together 2 min.",
            ],
            contextReason: "Your eggs expire today and you have leftover rice — this clears both."
        ),
        MealSuggestion(
            name:          "Garlic butter pasta",
            prepMinutes:   18,
            difficulty:    "Easy",
            confidenceTag: .favorite,
            ingredients:   ["Pasta", "Garlic", "Butter", "Parmesan"],
            steps: [
                "Boil salted water, cook pasta until al dente (11 min).",
                "Melt butter in pan, sauté minced garlic 2 min until fragrant.",
                "Toss pasta in butter sauce, finish with parmesan and black pepper.",
            ],
            contextReason: "You've cooked this 6 times and always rated it well. Fits in your 28-min window."
        ),
        MealSuggestion(
            name:          "Avocado toast with poached egg",
            prepMinutes:   10,
            difficulty:    "Easy",
            confidenceTag: .quickWin,
            ingredients:   ["Bread", "Avocado", "Eggs", "Lemon"],
            steps: [
                "Toast bread. Mash avocado with lemon juice, salt, and pepper.",
                "Bring water to gentle simmer, add splash of vinegar. Crack egg in.",
                "Poach egg 3 min. Spread avo on toast, top with egg and chilli flakes.",
            ],
            contextReason: "Shortest prep time available. Perfect before your 7:20 PM commitment."
        ),
        MealSuggestion(
            name:          "Chicken stir fry",
            prepMinutes:   22,
            difficulty:    "Medium",
            confidenceTag: .favorite,
            ingredients:   ["Chicken breast", "Broccoli", "Soy sauce", "Garlic"],
            steps: [
                "Slice chicken thin. Mix soy sauce, garlic, a bit of sesame oil.",
                "High heat: cook chicken 4 min each side until golden. Set aside.",
                "Stir fry broccoli 3 min, return chicken, pour sauce over. Toss.",
            ],
            contextReason: nil
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
        PantryItem(icon: "leaf",            name: "Spinach",   quantity: "1 bag",  daysLeft: 1),
        PantryItem(icon: "oval",            name: "Eggs",      quantity: "4 left", daysLeft: 1),
        PantryItem(icon: "drop.fill",       name: "Milk",      quantity: "Half",   daysLeft: 2),
        PantryItem(icon: "circle.fill",     name: "Pasta",     quantity: "500 g",  daysLeft: nil),
        PantryItem(icon: "cube.fill",       name: "Rice",      quantity: "1 kg",   daysLeft: nil),
        PantryItem(icon: "bolt.fill",       name: "Olive oil", quantity: "Plenty", daysLeft: nil),
        PantryItem(icon: "star.fill",       name: "Garlic",    quantity: "1 head", daysLeft: nil),
        PantryItem(icon: "rectangle.fill",  name: "Butter",    quantity: "100 g",  daysLeft: nil),
    ]
}

// Simulated fridge scan result (in production: on-device CV model output)
enum FridgeScanResult {
    static let sample: [String] = [
        "Eggs", "Spinach", "Milk", "Leftover rice",
        "Butter", "Garlic", "Soy sauce", "Parmesan",
    ]
}
