//
//  SettingsView.swift
//  Prysm
//

import SwiftUI
import Combine

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SettingsViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    SettingsHeaderSection()
                        .staggeredAppear(appeared, delay: 0.04)

                    SettingsProfileHero()
                        .staggeredAppear(appeared, delay: 0.10)

                    // Focus & Energy
                    VStack(spacing: DS.Space.md) {
                        SettingsSectionHeader(title: "Focus & Energy")
                        SettingsSectionContainer {
                            SettingsNavRow(icon: "clock.fill",    iconColor: DS.Color.accent,      title: "Peak Hours",     subtitle: "9:00 AM – 11:00 AM")
                            SettingsDivider()
                            SettingsNavRow(icon: "bolt.fill",     iconColor: DS.Color.warning,     title: "Default Energy", subtitle: "Auto-detected")
                            SettingsDivider()
                            SettingsNavRow(icon: "moon.fill",     iconColor: Color(hex: "7C6AF7"), title: "Focus Mode",     subtitle: "Deep Work")
                            SettingsDivider()
                            SettingsToggleRow(icon: "bell.fill",  iconColor: DS.Color.negative,    title: "Notifications",  isOn: $vm.notificationsOn)
                        }
                    }
                    .staggeredAppear(appeared, delay: 0.16)

                    // Habits
                    VStack(spacing: DS.Space.md) {
                        SettingsSectionHeader(title: "Habits")
                        SettingsSectionContainer {
                            SettingsNavRow(icon: "flame.fill",        iconColor: DS.Color.warning,  title: "Daily Reminder", subtitle: "7:00 AM")
                            SettingsDivider()
                            SettingsNavRow(icon: "calendar",          iconColor: DS.Color.positive, title: "Rest Days",      subtitle: "Sunday")
                            SettingsDivider()
                            SettingsToggleRow(icon: "chart.bar.fill", iconColor: DS.Color.accent,   title: "Streak Alerts",  isOn: $vm.streakAlerts)
                        }
                    }
                    .staggeredAppear(appeared, delay: 0.22)

                    // Appearance
                    VStack(spacing: DS.Space.md) {
                        SettingsSectionHeader(title: "Appearance")
                        SettingsSectionContainer {
                            SettingsNavRow(icon: "circle.lefthalf.filled", iconColor: DS.Color.textPrimary, title: "Theme",         subtitle: "System")
                            SettingsDivider()
                            SettingsNavRow(icon: "textformat.size",        iconColor: DS.Color.accent,      title: "Text Size",     subtitle: "Default")
                            SettingsDivider()
                            SettingsToggleRow(icon: "sparkles",            iconColor: Color(hex: "7C6AF7"), title: "Reduce Motion", isOn: $vm.reduceMotion)
                        }
                    }
                    .staggeredAppear(appeared, delay: 0.28)

                    // Data & Integrations
                    VStack(spacing: DS.Space.md) {
                        SettingsSectionHeader(title: "Data & Integrations")
                        SettingsSectionContainer {
                            SettingsNavRow(icon: "calendar.badge.clock", iconColor: Color(hex: "4285F4"), title: "Google Calendar", subtitle: "Connected")
                            SettingsDivider()
                            SettingsNavRow(icon: "checklist",            iconColor: Color(hex: "E84135"), title: "Todoist",         subtitle: "Connected")
                            SettingsDivider()
                            SettingsNavRow(icon: "heart.fill",           iconColor: DS.Color.negative,    title: "Apple Health",    subtitle: "Connected")
                            SettingsDivider()
                            SettingsNavRow(icon: "square.and.arrow.up",  iconColor: DS.Color.accent,      title: "Export Data",     subtitle: "")
                        }
                    }
                    .staggeredAppear(appeared, delay: 0.34)

                    // Account
                    VStack(spacing: DS.Space.md) {
                        SettingsSectionHeader(title: "Account")
                        SettingsSectionContainer {
                            SettingsNavRow(icon: "person.fill",              iconColor: DS.Color.accent,        title: "Edit Profile",    subtitle: "")
                            SettingsDivider()
                            SettingsNavRow(icon: "lock.fill",                iconColor: DS.Color.textSecondary, title: "Privacy",         subtitle: "")
                            SettingsDivider()
                            SettingsNavRow(icon: "questionmark.circle.fill", iconColor: DS.Color.textSecondary, title: "Help & Feedback", subtitle: "")
                            SettingsDivider()
                            SettingsDestructiveRow(icon: "arrow.right.square.fill", title: "Sign Out")
                        }
                    }
                    .staggeredAppear(appeared, delay: 0.40)

                    Text("Prysm · Version 1.0.0")
                        .font(DS.Font.caption2())
                        .foregroundColor(DS.Color.textQuaternary)
                        .staggeredAppear(appeared, delay: 0.46)

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.base)
                .padding(.top, DS.Space.xl)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - View Model
class SettingsViewModel: ObservableObject {
    @Published var notificationsOn: Bool = true
    @Published var streakAlerts: Bool    = true
    @Published var reduceMotion: Bool    = false
}

// MARK: - Header
struct SettingsHeaderSection: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Settings")
                    .font(DS.Font.title1())
                    .foregroundColor(DS.Color.textPrimary)
                Text("Prysm preferences")
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textSecondary)
            }
            Spacer()

            // Liquid glass close button — Apple-style large tap target
            Button(action: { dismiss() }) {
                ZStack {
                    // Liquid glass layered effect
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
                        .frame(width: 44, height: 44)
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.75))
                }
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Profile Hero
struct SettingsProfileHero: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "1C1C1E"))

            VStack(alignment: .leading, spacing: 0) {

                // ── Top: photo + info ────────────────────────────
                HStack(alignment: .center, spacing: 16) {
                    Image("Profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ken Aldrey")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("ken@prysm.app")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    Spacer()

                    // Pro badge — single spark icon + "Pro" label, gray
                    VStack(spacing: 3) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.55))
                        Text("Pro")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.45))
                    }
                }

                // ── Divider ──────────────────────────────────────
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                    .padding(.vertical, 20)

                // ── Stats row — icon + big number + label ────────
                HStack(spacing: 0) {
                    SettingsHeroStat(icon: "flame.fill",      iconColor: Color(hex: "FF6B35"), value: "14d",  label: "Streak")

                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 0.5, height: 44)

                    SettingsHeroStat(icon: "checkmark.seal.fill", iconColor: Color(hex: "34C759"), value: "87%",  label: "Habit rate")

                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 0.5, height: 44)

                    SettingsHeroStat(icon: "brain.head.profile",  iconColor: Color(hex: "7C6AF7"), value: "6.2h", label: "Focus avg")
                }
            }
            .padding(24)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Hero Stat — icon (no bg) + big value + label
private struct SettingsHeroStat: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconColor)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Helpers
struct SettingsSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DS.Color.textPrimary)
            Spacer()
        }
    }
}

struct SettingsSectionContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: 0) {
            content()
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

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 56)
            .opacity(0.25)
    }
}

// MARK: - Row: Navigate
struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.Color.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(DS.Color.textTertiary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DS.Color.textQuaternary)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}

// MARK: - Row: Toggle
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, alignment: .center)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DS.Color.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(DS.Color.accent)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}

// MARK: - Row: Destructive
struct SettingsDestructiveRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(DS.Color.negative)
                .frame(width: 28, alignment: .center)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DS.Color.negative)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DS.Color.negative.opacity(0.35))
        }
        .padding(.vertical, 15)
        .padding(.horizontal, DS.Space.base)
        .contentShape(Rectangle())
    }
}
