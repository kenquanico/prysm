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
        // ✅ REMOVED the onChange block that was redirecting away from pickOne
    }
}

// MARK: - Tab Root View switcher (used by both paths)
struct AppTabRootView: View {
    let tab: ContentView.Tab
    var body: some View {
        switch tab {
        case .home:    HomeView()
        case .plan:    PlanView()
        case .habits:  HabitsFullView()
        case .pickOne: JustPickOneView()
        }
    }
}

// MARK: - Custom Tab Bar (pre-iOS-26 / always-custom fallback)
//
// Layout (Apple split-pill pattern):
//   ┌─────────────────────────┐   ┌───────────┐
//   │  Home    Plan    Habits  │   │ ⚡ Pick One │
//   └─────────────────────────┘   └───────────┘
//
struct CustomTabBar: View {
    @Binding var selected: ContentView.Tab
    @Namespace private var selectorNS

    private let groupTabs: [ContentView.Tab] = [.home, .plan, .habits]
    private let soloTab:    ContentView.Tab  = .pickOne

    var body: some View {
        HStack(spacing: DS.Space.sm) {

            // ── Left cluster ─────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(groupTabs, id: \.self) { tab in
                    segmentedItem(tab)
                }
            }
            .padding(.horizontal, DS.Space.xs)
            .padding(.vertical, DS.Space.xs)
            .background {
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(0.08), radius: 44, x: 0, y: 10)
            }

            // ── Right solo pill ───────────────────────────────────────
            soloItem(soloTab)
                .padding(.horizontal, DS.Space.lg)
                .padding(.vertical, DS.Space.md)
                .background {
                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                        .fill(Color.clear)
                        .shadow(color: .black.opacity(0.08), radius: 44, x: 0, y: 10)
                }
        }
    }

    // MARK: Segmented item (left cluster)
    @ViewBuilder
    private func segmentedItem(_ tab: ContentView.Tab) -> some View {
        let isActive = selected == tab

        Button {
            withAnimation(DS.Animation.snappy) { selected = tab }
        } label: {
            VStack(spacing: DS.Space.xs) {
                Image(systemName: isActive ? "\(tab.rawValue).fill" : tab.rawValue)
                    .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(
                        isActive
                        ? AnyShapeStyle(Color(hex: "#5b8fcb"))
                        : AnyShapeStyle(Color.secondary)
                    )
                    .scaleEffect(isActive ? 1.06 : 1.0)
                    .animation(DS.Animation.snappy, value: isActive)

                Text(tab.label)
                    .font(DS.Font.caption2())
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
                        .matchedGeometryEffect(id: "selector", in: selectorNS)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Solo pill item (right)
    @ViewBuilder
    private func soloItem(_ tab: ContentView.Tab) -> some View {
        let isActive = selected == tab

        Button {
            withAnimation(DS.Animation.snappy) { selected = tab }
        } label: {
            VStack(spacing: DS.Space.xs) {
                Image(systemName: tab.rawValue)
                    .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(
                        isActive
                        ? AnyShapeStyle(Color(hex: "#5b8fcb"))
                        : AnyShapeStyle(Color.secondary)
                    )
                    .scaleEffect(isActive ? 1.06 : 1.0)
                    .animation(DS.Animation.snappy, value: isActive)

                Text(tab.label)
                    .font(DS.Font.caption2())
                    .foregroundStyle(
                        isActive
                        ? AnyShapeStyle(Color(hex: "#5b8fcb"))
                        : AnyShapeStyle(Color.secondary)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
