//
//  ContentView.swift
//  Prysm
//
//  Root. Tab navigation. Liquid glass segmented-control tab bar.
//  Left cluster slides a floating glass pill behind the active tab.
//  Right solo pill is the ⚡ Pick One shortcut.
//

import SwiftUI
import Combine

// MARK: - App Router (shared navigation state)
final class AppRouter: ObservableObject {
    @Published var selectedTab: ContentView.Tab = .home
}

// MARK: - Root
struct ContentView: View {
    @StateObject private var router = AppRouter()
    @State private var showComposeOverlay = false
    @Namespace private var composeNamespace

    enum Tab: String, CaseIterable {
        case home    = "cube"
        case plan    = "square.and.pencil"
        case habits  = "checkmark.circle"
        case pickOne = "bolt.circle"

        var label: String {
            switch self {
            case .home:    return "Core"
            case .plan:    return "Plan"
            case .habits:  return "Habits"
            case .pickOne: return "Pick One"
            }
        }

        var isSolo: Bool { self == .pickOne }
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            AppTabView(
                router: router,
                showComposeOverlay: $showComposeOverlay,
                composeNamespace: composeNamespace
            )
        } else {
            legacyLayout
        }
    }

    // MARK: Pre-iOS-26 fallback
    private var legacyLayout: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedTab {
                case .home:    HomeView()
                case .plan:    PlanView()
                case .habits:  HabitsFullView()
                case .pickOne: JustPickOneView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }

            CustomTabBar(selected: Binding(
                get: { router.selectedTab },
                set: { router.selectedTab = $0 }
            ))
            .padding(.horizontal, DS.Space.lg)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .bottom)
        .environmentObject(router)
    }
}

// MARK: - iOS 26 Tab View (native TabView + liquid glass bar)
@available(iOS 26.0, *)
struct AppTabView: View {
    @ObservedObject var router: AppRouter
    @Binding var showComposeOverlay: Bool
    var composeNamespace: Namespace.ID

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                Tab(value: tab, role: tab == .pickOne ? .search : nil) {
                    AppTabRootView(tab: tab)
                } label: {
                    if tab == .pickOne {
                        Label(tab.label, systemImage: tab.rawValue)
                            .matchedTransitionSource(id: "pickone-tab", in: composeNamespace)
                    } else {
                        Label(tab.label, systemImage: tab.rawValue)
                    }
                }
            }
        }
        .tint(Color(hex: "#4eabae"))
    }
}

// MARK: - Tab Root View switcher
struct AppTabRootView: View {
    let tab: ContentView.Tab
    var body: some View {
        switch tab {
        case .home:    NavigationStack { HomeView() }
        case .plan:    PlanView()
        case .habits:  HabitsFullView()
        case .pickOne: JustPickOneView()
        }
    }
}

// MARK: - Custom Tab Bar
//
// Layout (Apple split-pill pattern):
//   ┌─────────────────────────────┐   ┌────────────┐
//   │  [Core]   [Plan]  [Habits]  │   │ [⚡Pick One] │
//   └─────────────────────────────┘   └────────────┘
//
// Each outer capsule is a single liquid-glass surface via GlassEffectContainer.
// Active tab gets .regular.interactive() pill; inactive gets .clear.interactive().
// No manual backgrounds — glass handles all surfaces.
//
struct CustomTabBar: View {
    @Binding var selected: ContentView.Tab

    private let groupTabs: [ContentView.Tab] = [.home, .plan, .habits]
    private let soloTab:    ContentView.Tab  = .pickOne

    var body: some View {
        HStack(spacing: DS.Space.sm) {

            // ── Left cluster — one shared glass surface ───────────────
            GlassEffectContainer(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(groupTabs, id: \.self) { tab in
                        tabItem(tab)
                    }
                }
                .glassEffect(in: Capsule())          // outer capsule shell
            }

            // ── Right solo pill — its own glass surface ───────────────
            GlassEffectContainer(spacing: 0) {
                tabItem(soloTab)
                    .glassEffect(in: Capsule())      // solo pill shell
            }
        }
    }

    // MARK: – Shared tab item builder
    @ViewBuilder
    private func tabItem(_ tab: ContentView.Tab) -> some View {
        let isActive = selected == tab

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isActive ? "\(tab.rawValue).fill" : tab.rawValue)
                    .font(.system(size: 21, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
                    .scaleEffect(isActive ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)

                Text(tab.label)
                    .font(DS.Font.caption2())
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
            }
            .padding(.horizontal, tab.isSolo ? DS.Space.lg : DS.Space.md)
            .padding(.vertical, DS.Space.sm)
        }
        .buttonStyle(.plain)
        // Active = floating glass pill lifted above the outer shell.
        // Inactive = transparent so the outer shell shows through cleanly.
        .glassEffect(
            isActive ? .regular.interactive() : .clear.interactive(),
            in: Capsule()
        )
    }
}
