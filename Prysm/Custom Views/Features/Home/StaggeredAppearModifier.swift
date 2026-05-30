//
//  StaggeredAppearModifier.swift
//  Prysm
//
//  Created by Ken Aldrey Quanico on 5/26/26.
//


//
//  StaggeredAppearModifier.swift
//  Prysm
//
//  Shared view modifiers used across all views.
//

import SwiftUI

// MARK: - Staggered Appear
struct StaggeredAppearModifier: ViewModifier {
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.85)
                    .delay(delay),
                value: appeared
            )
    }
}

extension View {
    func staggeredAppear(_ appeared: Bool, delay: Double = 0) -> some View {
        modifier(StaggeredAppearModifier(appeared: appeared, delay: delay))
    }
}