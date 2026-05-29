//
//  DS.swift
//  Prysm
//

import SwiftUI

// MARK: - Design Tokens
struct DS {

    // MARK: Colors — near-monochrome, one accent
    struct Color {
        // Backgrounds
        static let bg            = SwiftUI.Color(hex: "#F2F2F7")
        static let surface       = SwiftUI.Color(hex: "#FFFFFF")
        static let surfaceHigh   = SwiftUI.Color(hex: "#F2F2F7")

        // Borders — hairline only
        static let border        = SwiftUI.Color(red: 0, green: 0, blue: 0, opacity: 0.07)
        static let borderMed     = SwiftUI.Color(red: 0, green: 0, blue: 0, opacity: 0.14)
        static let borderStrong  = SwiftUI.Color(red: 0, green: 0, blue: 0, opacity: 0.20)

        // Accent — restrained lavender + variants
        static let accent        = SwiftUI.Color(hex: "#6C65D9")
        static let accentMed     = SwiftUI.Color(hex: "#6C65D9").opacity(0.50)
        static let accentSoft    = SwiftUI.Color(hex: "#6C65D9").opacity(0.10)

        // Text — four levels, monochrome
        static let textPrimary    = SwiftUI.Color(hex: "#1C1C1E")
        static let textSecondary  = SwiftUI.Color(hex: "#3C3C43").opacity(0.78)
        static let textTertiary   = SwiftUI.Color(hex: "#3C3C43").opacity(0.42)
        static let textQuaternary = SwiftUI.Color(hex: "#3C3C43").opacity(0.24)

        // Semantic
        static let positive      = SwiftUI.Color(hex: "#34C759")
        static let positiveSoft  = SwiftUI.Color(hex: "#34C759").opacity(0.10)
        static let warning       = SwiftUI.Color(hex: "#FF9500")
        static let warningSoft   = SwiftUI.Color(hex: "#FF9500").opacity(0.10)
        static let negative      = SwiftUI.Color(hex: "#FF3B30")
        static let negativeSoft  = SwiftUI.Color(hex: "#FF3B30").opacity(0.10)

        // Category colors
        static let categoryA     = SwiftUI.Color(hex: "#FF6B6B")  // coral red
        static let categoryB     = SwiftUI.Color(hex: "#FF9500")  // orange
        static let categoryC     = SwiftUI.Color(hex: "#34C759")  // green
        static let categoryD     = SwiftUI.Color(hex: "#007AFF")  // blue
        static let categoryE     = SwiftUI.Color(hex: "#AF52DE")  // purple
    }

    // MARK: Typography — SF Pro only
    struct Font {
        static func largeTitle() -> SwiftUI.Font  { .system(size: 34, weight: .bold,     design: .default) }
        static func title1() -> SwiftUI.Font      { .system(size: 28, weight: .semibold, design: .default) }
        static func title2() -> SwiftUI.Font      { .system(size: 22, weight: .semibold, design: .default) }
        static func title3() -> SwiftUI.Font      { .system(size: 20, weight: .regular,  design: .default) }
        static func headline() -> SwiftUI.Font    { .system(size: 17, weight: .semibold, design: .default) }
        static func body() -> SwiftUI.Font        { .system(size: 17, weight: .regular,  design: .default) }
        static func callout() -> SwiftUI.Font     { .system(size: 16, weight: .regular,  design: .default) }
        static func subheadline() -> SwiftUI.Font { .system(size: 15, weight: .regular,  design: .default) }
        static func footnote() -> SwiftUI.Font    { .system(size: 13, weight: .regular,  design: .default) }
        static func caption1() -> SwiftUI.Font    { .system(size: 12, weight: .regular,  design: .default) }
        static func caption2() -> SwiftUI.Font    { .system(size: 11, weight: .regular,  design: .default) }
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
    }

    // MARK: Spacing — 4-pt base grid
    struct Space {
        static let xxs: CGFloat  = 2
        static let xs: CGFloat   = 4
        static let sm: CGFloat   = 8
        static let md: CGFloat   = 12
        static let base: CGFloat = 16
        static let lg: CGFloat   = 20
        static let xl: CGFloat   = 24
        static let xxl: CGFloat  = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: Radius
    struct Radius {
        static let xs: CGFloat   = 6
        static let sm: CGFloat   = 8
        static let md: CGFloat   = 12
        static let lg: CGFloat   = 16
        static let xl: CGFloat   = 20
        static let pill: CGFloat = 100
    }

    // MARK: Icon weights
    struct Icon {
        static let defaultWeight: SwiftUI.Font.Weight  = .ultraLight
        static let activeWeight: SwiftUI.Font.Weight   = .light
        static let emphasisWeight: SwiftUI.Font.Weight = .semibold
    }

    // MARK: Animation
    struct Animation {
        static let snappy   = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let gentle   = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.85)
        static let standard = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
}

// MARK: - Hex Color Init (single definition — do NOT duplicate elsewhere)
extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Surface Card
struct SurfaceCard: ViewModifier {
    var padding: CGFloat = DS.Space.base
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(DS.Color.border, lineWidth: 0.5)
            )
    }
}

extension View {
    func surfaceCard(padding: CGFloat = DS.Space.base) -> some View {
        modifier(SurfaceCard(padding: padding))
    }
}
