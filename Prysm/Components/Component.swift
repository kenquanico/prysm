//
//  Components.swift
//  Prysm
//
//  Shared UI primitives. All stateless. Nothing hardcoded — everything via DS tokens.
//

import SwiftUI

// MARK: - Pill Badge
struct PillBadge: View {
    let text: String
    var color: Color = DS.Color.textTertiary
    var background: Color = DS.Color.surfaceHigh
    var prominent: Bool = false

    var body: some View {
        Text(text)
            .font(DS.Font.caption2())
            .foregroundColor(prominent ? DS.Color.accent : color)
            .padding(.horizontal, DS.Space.sm + 2)
            .padding(.vertical, DS.Space.xxs + 1)
            .background(prominent ? DS.Color.accentSoft : background)
            .clipShape(Capsule())
    }
}

// MARK: - Icon Circle
// Thin SF Symbol in a soft-fill circle. Mono unless color carries meaning.
struct IconCircle: View {
    let systemName: String
    var color: Color = DS.Color.textTertiary
    var size: CGFloat = 34
    var fillOpacity: Double = 0.08

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(fillOpacity))
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: DS.Icon.defaultWeight))
                .foregroundColor(color)
        }
    }
}

// MARK: - Rounded Icon Square (for settings-style rows)
struct IconSquare: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.xs, style: .continuous)
                .fill(color)
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.44, weight: .light))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Section Header
struct SectionHeader<Trailing: View>: View {
    let title: String
    var trailing: (() -> Trailing)?

    init(title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DS.Font.title3())
                .fontWeight(.bold)
                .foregroundColor(DS.Color.textPrimary)
            Spacer()
            trailing?()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String) {
        self.title = title
        self.trailing = nil
    }

    var body: some View {
        Text(title.uppercased())
            .font(DS.Font.caption2())
            .fontWeight(.semibold)
            .foregroundColor(DS.Color.textTertiary)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Soft Divider
struct SoftDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.Color.border)
            .frame(height: 0.5)
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 28
    var lineWidth: CGFloat = 2.5
    var trackColor: Color = DS.Color.textQuaternary
    var ringColor: Color = DS.Color.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(DS.Animation.gentle, value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Now Indicator
struct NowIndicator: View {
    var body: some View {
        Text("Now")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color(uiColor: .systemBlue))
            .clipShape(Capsule())
    }
}

// MARK: - Timeline connector between time blocks
struct TimelineLine: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 44)
            Rectangle()
                .fill(DS.Color.border)
                .frame(width: 0.5, height: 12)
            Spacer()
        }
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    enum Level { case high, medium, low }
    let level: Level

    var label: String {
        switch level { case .high: return "High"; case .medium: return "Med"; case .low: return "Low" }
    }
    var color: Color {
        switch level {
        case .high:   return DS.Color.negative
        case .medium: return DS.Color.warning
        case .low:    return DS.Color.textTertiary
        }
    }

    var body: some View {
        Text(label)
            .font(DS.Font.caption2())
            .foregroundColor(color)
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.xxs + 1)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }
}

// MARK: - Energy Dot (biometric-linked)
struct EnergyDot: View {
    enum Level: String { case high = "High", medium = "Medium", low = "Low" }
    let level: Level

    var color: Color {
        switch level {
        case .high:   return DS.Color.positive
        case .medium: return DS.Color.warning
        case .low:    return DS.Color.negative
        }
    }

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(level.rawValue)
                .font(DS.Font.caption2())
                .foregroundColor(DS.Color.textSecondary)
        }
    }
}

// MARK: - Inline Stat
struct InlineStat: View {
    let label: String
    let value: String
    var valueColor: Color = DS.Color.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs) {
            Text(label)
                .font(DS.Font.caption2())
                .foregroundColor(DS.Color.textTertiary)
            Text(value)
                .font(DS.Font.title3())
                .foregroundColor(valueColor)
        }
    }
}
