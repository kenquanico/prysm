//
//  Models.swift
//  Prysm
//

import SwiftUI

// MARK: - Focus Mode
struct FocusMode: Identifiable, Hashable {
    let id = UUID()
    var icon: String
    var label: String
    var isActive: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: FocusMode, r: FocusMode) -> Bool { l.id == r.id }

    static let modes: [FocusMode] = [
        FocusMode(icon: "graduationcap", label: "Study",    isActive: true),
        FocusMode(icon: "briefcase",     label: "Work",     isActive: false),
        FocusMode(icon: "person",        label: "Personal", isActive: false),
        FocusMode(icon: "moon",          label: "Rest",     isActive: false),
    ]
}

// MARK: - Context Card
struct ContextCard: Identifiable {
    let id = UUID()
    var icon: String
    var label: String
    var value: String
    var trend: String? = nil

    static let sampleData: [ContextCard] = [
        ContextCard(icon: "bolt",        label: "Energy",  value: "High",    trend: nil),
        ContextCard(icon: "bed.double",  label: "Sleep",   value: "7h 42m",  trend: "↑22m"),
        ContextCard(icon: "wind",        label: "Free",    value: "3h 10m",  trend: nil),
        ContextCard(icon: "flame",       label: "Streak",  value: "12 days", trend: nil),
    ]
}

// MARK: - Block Category (shared top-level)
enum BlockCategory: CaseIterable {
    case study, health, lecture, focus, rest, meeting, errand

    var color: Color {
        switch self {
        case .study:   return DS.Color.categoryA
        case .health:  return DS.Color.categoryB
        case .lecture: return DS.Color.categoryC
        case .focus:   return DS.Color.accent
        case .rest:    return DS.Color.categoryE
        case .meeting: return DS.Color.negative
        case .errand:  return DS.Color.categoryD
        }
    }

    var label: String {
        switch self {
        case .study:   return "Study"
        case .health:  return "Health"
        case .lecture: return "Lecture"
        case .focus:   return "Focus"
        case .rest:    return "Rest"
        case .meeting: return "Meeting"
        case .errand:  return "Errand"
        }
    }

    var icon: String {
        switch self {
        case .study:   return "book.fill"
        case .health:  return "heart.fill"
        case .lecture: return "graduationcap.fill"
        case .focus:   return "brain.head.profile"
        case .rest:    return "moon.fill"
        case .meeting: return "person.2.fill"
        case .errand:  return "bag.fill"
        }
    }
}

// MARK: - Time Block (Home today view)
struct TimeBlock: Identifiable {
    let id = UUID()
    var time: String
    var title: String
    var subtitle: String
    var icon: String
    var duration: String
    var isNow: Bool = false
    var isDone: Bool = false
    var category: BlockCategory

    static let sampleData: [TimeBlock] = [
        TimeBlock(time: "7:00",  title: "Morning run",      subtitle: "30 min · Fitness",        icon: "figure.run",    duration: "30m",  isDone: true,  category: .health),
        TimeBlock(time: "8:00",  title: "Study session",    subtitle: "iOS Dev · Deep work",     icon: "book",          duration: "2h",   isNow: true,   category: .study),
        TimeBlock(time: "10:00", title: "Gym workout",      subtitle: "Upper body · HealthKit",  icon: "dumbbell",      duration: "1h",                  category: .health),
        TimeBlock(time: "1:00",  title: "CCS 101 lecture",  subtitle: "Room B-204",              icon: "graduationcap", duration: "1.5h",                category: .lecture),
        TimeBlock(time: "3:00",  title: "Focus block",      subtitle: "Project work",            icon: "sparkles",      duration: "2h",                  category: .focus),
        TimeBlock(time: "6:00",  title: "Wind down",        subtitle: "No screens",              icon: "moon.stars",    duration: "∞",                   category: .rest),
    ]
}

// MARK: - Habit Item (Home compact)
struct HabitItem: Identifiable {
    let id = UUID()
    var icon: String
    var title: String
    var streak: Int
    var isChecked: Bool

    static let sampleData: [HabitItem] = [
        HabitItem(icon: "drop",        title: "Hydration",    streak: 12, isChecked: true),
        HabitItem(icon: "figure.walk", title: "Steps",        streak: 5,  isChecked: true),
        HabitItem(icon: "book.closed", title: "Reading",      streak: 7,  isChecked: false),
        HabitItem(icon: "moon",        title: "Sleep 8hrs",   streak: 3,  isChecked: false),
    ]
}

// MARK: - Full Habit
struct FullHabit: Identifiable {
    let id = UUID()
    var icon: String
    var title: String
    var subtitle: String
    var streak: Int
    var bestStreak: Int
    var isCheckedToday: Bool
    var weekHistory: [Bool]
    var category: HabitCategory

    enum HabitCategory: String, CaseIterable {
        case daily  = "Daily"
        case health = "Health"
        case mind   = "Mind"

        var color: Color {
            switch self {
            case .daily:  return DS.Color.categoryC
            case .health: return DS.Color.categoryB
            case .mind:   return DS.Color.categoryA
            }
        }

        var icon: String {
            switch self {
            case .daily:  return "sun.horizon"
            case .health: return "heart"
            case .mind:   return "brain"
            }
        }
    }

    static let sampleData: [FullHabit] = [
        FullHabit(icon: "drop",        title: "Hydration",       subtitle: "8 glasses · Daily",    streak: 12, bestStreak: 21, isCheckedToday: true,  weekHistory: [true, true, false, true, true, true, false],    category: .daily),
        FullHabit(icon: "sun.horizon", title: "Morning routine", subtitle: "Before 8am",           streak: 5,  bestStreak: 14, isCheckedToday: false, weekHistory: [true, false, true, true, false, true, false],   category: .daily),
        FullHabit(icon: "figure.walk", title: "Steps goal",      subtitle: "10,000 steps",         streak: 5,  bestStreak: 10, isCheckedToday: true,  weekHistory: [true, true, true, false, true, false, false],   category: .health),
        FullHabit(icon: "dumbbell",    title: "Workout",         subtitle: "3× per week",          streak: 8,  bestStreak: 12, isCheckedToday: false, weekHistory: [false, true, false, true, false, true, false],  category: .health),
        FullHabit(icon: "fork.knife",  title: "Eat clean",       subtitle: "No processed food",    streak: 3,  bestStreak: 9,  isCheckedToday: true,  weekHistory: [true, true, false, false, true, false, false],  category: .health),
        FullHabit(icon: "book.closed", title: "Daily reading",   subtitle: "30 min",               streak: 7,  bestStreak: 30, isCheckedToday: false, weekHistory: [true, true, true, true, false, false, false],   category: .mind),
        FullHabit(icon: "moon",        title: "Sleep 8hrs",      subtitle: "Before midnight",      streak: 3,  bestStreak: 11, isCheckedToday: false, weekHistory: [false, true, true, false, false, true, false],  category: .mind),
        FullHabit(icon: "brain",       title: "Meditation",      subtitle: "10 min · Calm",        streak: 1,  bestStreak: 8,  isCheckedToday: false, weekHistory: [false, false, true, false, false, false, false], category: .mind),
    ]
}

// MARK: - Plan Block
struct PlanBlock: Identifiable {
    let id = UUID()
    var date: Date
    var startTime: String
    var endTime: String
    var title: String
    var subtitle: String
    var icon: String
    var duration: String
    var durationMinutes: Int
    var isDone: Bool = false
    var category: BlockCategory

    static let sampleData: [PlanBlock] = {
        let today = Date()
        return [
            PlanBlock(date: today, startTime: "7:00",  endTime: "7:30",  title: "Morning run",      subtitle: "30 min · Fitness",      icon: "figure.run",    duration: "30m",  durationMinutes: 30,  isDone: true, category: .health),
            PlanBlock(date: today, startTime: "8:00",  endTime: "10:00", title: "Study session",    subtitle: "iOS Dev · Deep work",   icon: "book",          duration: "2h",   durationMinutes: 120,             category: .study),
            PlanBlock(date: today, startTime: "10:00", endTime: "11:00", title: "Gym workout",      subtitle: "Upper body",            icon: "dumbbell",      duration: "1h",   durationMinutes: 60,              category: .health),
            PlanBlock(date: today, startTime: "13:00", endTime: "14:30", title: "CCS 101 lecture",  subtitle: "Room B-204",            icon: "graduationcap", duration: "1.5h", durationMinutes: 90,              category: .lecture),
            PlanBlock(date: today, startTime: "15:00", endTime: "17:00", title: "Focus block",      subtitle: "Capstone project",      icon: "sparkles",      duration: "2h",   durationMinutes: 120,             category: .focus),
            PlanBlock(date: today, startTime: "18:00", endTime: "18:30", title: "Wind down",        subtitle: "No screens · Rest",     icon: "moon.stars",    duration: "∞",    durationMinutes: 30,              category: .rest),
        ]
    }()
}

// MARK: - Unscheduled Task
struct UnscheduledTask: Identifiable {
    let id = UUID()
    var icon: String
    var title: String
    var priority: Priority
    var estimatedMinutes: Int

    enum Priority {
        case high, medium, low

        var label: String {
            switch self {
            case .high:   return "High"
            case .medium: return "Med"
            case .low:    return "Low"
            }
        }

        var color: Color {
            switch self {
            case .high:   return DS.Color.negative
            case .medium: return DS.Color.warning
            case .low:    return DS.Color.textTertiary
            }
        }

        var badge: PriorityBadge.Level {
            switch self {
            case .high:   return .high
            case .medium: return .medium
            case .low:    return .low
            }
        }
    }

    static let sampleData: [UnscheduledTask] = [
        UnscheduledTask(icon: "doc.text", title: "Review thesis outline", priority: .high,   estimatedMinutes: 45),
        UnscheduledTask(icon: "envelope", title: "Reply to prof email",   priority: .medium, estimatedMinutes: 10),
        UnscheduledTask(icon: "cart",     title: "Grocery run",           priority: .low,    estimatedMinutes: 30),
    ]
}

// MARK: - RSVP Invitation
struct RSVPInvitation: Identifiable {
    let id = UUID()
    var eventName: String
    var eventType: String
    var from: String
    var date: String
    var time: String
    var travelEstimate: String
    var dayStatus: DayStatus
    var energyForecast: EnergyForecast
    var relationshipWeight: RelationshipWeight

    enum DayStatus: String       { case free = "Free", light = "Light", busy = "Busy" }
    enum EnergyForecast: String  { case high = "High", medium = "Medium", low = "Low" }
    enum RelationshipWeight: String {
        case close        = "Close friend"
        case family       = "Family"
        case colleague    = "Colleague"
        case acquaintance = "Acquaintance"
    }

    static let sampleData: [RSVPInvitation] = [
        RSVPInvitation(eventName: "Sophie's birthday dinner", eventType: "Dinner",      from: "Sophie Lim",  date: "Sat, Jun 7", time: "7:00 PM", travelEstimate: "18 min", dayStatus: .light, energyForecast: .high,   relationshipWeight: .close),
        RSVPInvitation(eventName: "Team social @ Mango Tree", eventType: "Work social", from: "Mark Santos", date: "Fri, Jun 6", time: "6:30 PM", travelEstimate: "8 min",  dayStatus: .busy,  energyForecast: .low,    relationshipWeight: .colleague),
    ]
}

// MARK: - Daily Summary
struct DailySummary {
    var totalBlocks: Int
    var doneBlocks: Int
    var totalMinutes: Int
    var freeMinutes: Int
}
