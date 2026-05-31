//
//  HomeView.swift
//  Prysm
//

import SwiftUI
import Combine

// MARK: - Root
struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    HomeHeaderSection(greeting: vm.greeting, subtitle: vm.greetingSubtitle, name: "Ken")
                        .staggeredAppear(appeared, delay: 0.04)

                    FocusModeTabBar(modes: $vm.focusModes)
                        .staggeredAppear(appeared, delay: 0.10)

                    ActivityGridSection(readiness: vm.readiness, contextCards: vm.contextCards)
                        .staggeredAppear(appeared, delay: 0.16)

                    HomeTodaySection(blocks: $vm.timeBlocks)
                        .staggeredAppear(appeared, delay: 0.24)

                    if vm.showRSVPBanner {
                        RSVPBanner(invite: vm.pendingInvite!) {
                            vm.showRSVPBanner = false
                        }
                        .staggeredAppear(appeared, delay: 0.38)
                    }

                    if vm.showSuggestionBanner {
                        HomeSuggestionBanner {
                            withAnimation(DS.Animation.snappy) { vm.showSuggestionBanner = false }
                        }
                        .staggeredAppear(appeared, delay: 0.42)
                    }

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
class HomeViewModel: ObservableObject {
    @Published var focusModes     = FocusMode.modes
    @Published var contextCards   = ContextCard.sampleData
    @Published var timeBlocks     = TimeBlock.sampleData
    @Published var habits         = HabitItem.sampleData
    @Published var showSuggestionBanner = true
    @Published var showRSVPBanner       = true

    var pendingInvite: RSVPInvitation? { RSVPInvitation.sampleData.first }
    var readiness: Int { 78 }
    var energySummary: String { "Good sleep · Peak window 9–11am" }

    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var greetingSubtitle: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5:   return "Rise and shine"
        case 6:   return "Early momentum"
        case 7:   return "Morning energy"
        case 8:   return "Start strong"
        case 9:   return "Morning focus"
        case 10:  return "Fresh start"
        case 11:  return "Ready for today?"
        case 12:  return "Midday reset"
        case 13:  return "Coffee time"
        case 14:  return "Afternoon flow"
        case 15:  return "Golden hour"
        case 16:  return "Focus hour"
        case 17:  return "Keep the momentum"
        case 18:  return "Afternoon boost"
        case 19:  return "Wind down"
        case 20:  return "Evening reset"
        case 21:  return "Time to unwind"
        case 22:  return "Reflect on today"
        case 23:  return "Relax and recharge"
        default:  return "Rest mode"
        }
    }
}

// MARK: - Header (profile tap opens Settings)
struct HomeHeaderSection: View {
    let greeting: String
    let subtitle: String
    let name: String

    @State private var showSettings = false

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
                Text("\(greeting), \(name)")
                    .font(DS.Font.title1())
                    .foregroundColor(DS.Color.textPrimary)
                Text(subtitle)
                    .font(DS.Font.footnote())
                    .foregroundColor(DS.Color.textSecondary)
            }
            Spacer()

            Button(action: { showSettings = true }) {
                Image("Profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(DS.Color.border, lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .padding(.top, DS.Space.sm)
    }
}

// MARK: - Focus Mode Tab Bar
struct FocusModeTabBar: View {
    @Binding var modes: [FocusMode]
    @Namespace private var glassNS

    var body: some View {
        HStack(spacing: 0) {
            ForEach(modes.indices, id: \.self) { idx in
                let mode = modes[idx]
                let isActive = mode.isActive

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        for i in modes.indices { modes[i].isActive = false }
                        modes[idx].isActive = true
                    }
                } label: {
                    Text(mode.label)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                        .foregroundColor(isActive ? DS.Color.textPrimary : DS.Color.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isActive {
                                Capsule()
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                    .matchedGeometryEffect(id: "glass-pill", in: glassNS)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(DS.Color.border, lineWidth: 0.5)
                )
        }
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Activity Grid Section
struct ActivityGridSection: View {
    let readiness: Int
    let contextCards: [ContextCard]

    private var readinessColor: Color {
        readiness >= 70 ? DS.Color.positive : readiness >= 45 ? DS.Color.warning : DS.Color.negative
    }

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            NavigationLink(destination: ReadinessView()) {
                ActivityCard(label: "Readiness", accent: readinessColor) {
                    HStack(spacing: 14) {
                        ZStack {
                            ProgressRing(
                                progress: Double(readiness) / 100,
                                size: 72,
                                lineWidth: 5,
                                trackColor: Color.black.opacity(0.08),
                                ringColor: readinessColor
                            )
                            Text("\(readiness)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(DS.Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Peak")
                                .font(.system(size: 11))
                                .foregroundColor(DS.Color.textSecondary)
                            Text("9–11 AM")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DS.Color.textPrimary)
                            Text("Good sleep")
                                .font(.system(size: 11))
                                .foregroundColor(DS.Color.textSecondary)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 14)
                }
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: StepsView()) {
                
                
                ActivityCard(label: "Steps", accent: Color.blue) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("6,240")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text("of 10k goal")
                            .font(.system(size: 11))
                            .foregroundColor(DS.Color.textSecondary)
                        Spacer(minLength: 4)
                        MiniBarGraph(
                            values: [0.1, 0.3, 0.5, 0.8, 0.6, 0.4, 0.7, 0.9, 0.5, 0.3, 0.2, 0.4],
                            accentColor: Color.blue,
                            timeLabels: ["12AM", "6AM", "12PM", "6PM"]
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            NavigationLink(destination: FocusView()) {
                ActivityCard(label: "Focus", accent: Color.purple) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("2h 15m")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Color.textPrimary)
                        Text("deep work today")
                            .font(.system(size: 11))
                            .foregroundColor(DS.Color.textSecondary)
                        Spacer(minLength: 4)
                        MiniBarGraph(
                            values: [0, 0, 0.2, 0.9, 1.0, 0.8, 0.1, 0.6, 0.7, 0.3, 0, 0],
                            accentColor: Color.purple,
                            timeLabels: ["12AM", "6AM", "12PM", "6PM"]
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            ActivityCard(label: "Schedule", accent: Color.teal) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Color.textPrimary)
                    Text("events remaining")
                        .font(.system(size: 11))
                        .foregroundColor(DS.Color.textSecondary)
                    Spacer(minLength: 4)
                    EventTimelineStrip(
                        events: [
                            EventDot(hour: 9,  label: "Standup"),
                            EventDot(hour: 13, label: "Lunch"),
                            EventDot(hour: 16, label: "Review")
                        ],
                        accentColor: Color.teal
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - ActivityCard
struct ActivityCard<Content: View>: View {
    let label: String
    let accent: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DS.Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DS.Color.textTertiary.opacity(0.6))
            }

            content()
                .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// MARK: - MiniBarGraph
struct MiniBarGraph: View {
    let values: [Double]
    let accentColor: Color
    let timeLabels: [String]

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                let count = CGFloat(values.count)
                let spacing: CGFloat = 2
                let barWidth = max(1, (geo.size.width - (count - 1) * spacing) / count)
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(values.indices, id: \.self) { i in
                        let h = max(3, geo.size.height * CGFloat(values[i]))
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(accentColor.opacity(values[i] > 0.05 ? 0.75 : 0.12))
                            .frame(width: barWidth, height: h)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 32)

            HStack {
                ForEach(Array(timeLabels.enumerated()), id: \.offset) { idx, label in
                    Text(label)
                        .font(.system(size: 8))
                        .foregroundColor(DS.Color.textQuaternary)
                    if idx < timeLabels.count - 1 { Spacer() }
                }
            }
        }
    }
}

// MARK: - EventTimelineStrip
struct EventDot {
    let hour: Int
    let label: String
}

struct EventTimelineStrip: View {
    let events: [EventDot]
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(accentColor.opacity(0.15))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .offset(y: 5)

                    ForEach(events.indices, id: \.self) { i in
                        let pct = CGFloat(events[i].hour) / 23.0
                        let x = pct * (geo.size.width - 8)
                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)
                            .offset(x: x, y: 1)
                    }
                }
            }
            .frame(height: 12)

            HStack {
                Text("12AM")
                Spacer()
                Text("6AM")
                Spacer()
                Text("12PM")
                Spacer()
                Text("6PM")
            }
            .font(.system(size: 8))
            .foregroundColor(DS.Color.textQuaternary)
        }
    }
}

// MARK: - Today Schedule
struct HomeTodaySection: View {
    @Binding var blocks: [TimeBlock]

    var body: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Today") {
                Button("See all") {}
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(uiColor: .systemBlue))
            }

            VStack(spacing: 0) {
                ForEach(blocks.indices, id: \.self) { idx in
                    HomeTimeBlockRow(block: blocks[idx])
                        .onTapGesture {
                            withAnimation(DS.Animation.snappy) {
                                blocks[idx].isDone.toggle()
                            }
                        }
                    if idx < blocks.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                            .opacity(0.25)
                    }
                }
            }
            .padding(DS.Space.base)
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

struct HomeTimeBlockRow: View {
    let block: TimeBlock

    var body: some View {
        HStack(spacing: 18) {

            Image(systemName: block.icon)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(
                    block.isDone
                        ? DS.Color.textQuaternary
                        : (block.isNow ? block.category.color : DS.Color.textSecondary)
                )
                .frame(width: 36, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(block.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(block.isDone ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .strikethrough(block.isDone, color: DS.Color.textQuaternary)
                    if block.isNow {
                        NowIndicator()
                    }
                }

                Text(block.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(DS.Color.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .regular))
                        Text(block.time)
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundColor(DS.Color.textTertiary)

                    Text("·")
                        .foregroundColor(DS.Color.textQuaternary)
                        .font(.system(size: 12))

                    Text(block.duration)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DS.Color.textTertiary)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(
                        block.isDone ? DS.Color.positive : DS.Color.border,
                        lineWidth: block.isDone ? 0 : 1.2
                    )
                    .frame(width: 28, height: 28)

                if block.isDone {
                    Circle()
                        .fill(DS.Color.positive)
                        .frame(width: 28, height: 28)
                        .shadow(color: DS.Color.positive.opacity(0.30), radius: 6, x: 0, y: 2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - RSVP Banner
struct RSVPBanner: View {
    let invite: RSVPInvitation
    let onDismiss: () -> Void

    @State private var responded = false
    @State private var response: String = ""

    var body: some View {
        if !responded {
            VStack(spacing: 0) {

                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DS.Color.textTertiary)
                    Text("from Google Calendar")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DS.Color.textTertiary)
                        .tracking(0.6)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .frame(width: 22, height: 22)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

                Divider().opacity(0.3)

                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "4285F4"), Color(hex: "34A853")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: Color(hex: "4285F4").opacity(0.25), radius: 10, x: 0, y: 4)
                        Image(systemName: "calendar")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("RSVP needed")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.Color.textTertiary)
                            .tracking(0.5)
                        Text(invite.eventName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DS.Color.textPrimary)
                            .lineLimit(2)
                        HStack(spacing: 12) {
                            Label(invite.date, systemImage: "calendar")
                            Label(invite.travelEstimate, systemImage: "car")
                        }
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DS.Color.textSecondary)
                        .labelStyle(.titleAndIcon)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)

                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(invite.dayStatus == .free ? DS.Color.positive :
                                  invite.dayStatus == .light ? DS.Color.warning : DS.Color.negative)
                            .frame(width: 7, height: 7)
                        Text(invite.dayStatus.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(invite.dayStatus == .free ? DS.Color.positive :
                                             invite.dayStatus == .light ? DS.Color.warning : DS.Color.negative)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                (invite.dayStatus == .free ? DS.Color.positive :
                                 invite.dayStatus == .light ? DS.Color.warning : DS.Color.negative).opacity(0.10)
                            )
                    )

                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(DS.Color.textSecondary)
                        Text("Energy: \(invite.energyForecast.rawValue)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: Capsule())

                    Spacer()

                    Label(invite.relationshipWeight.rawValue, systemImage: "person.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.textSecondary)
                        .labelStyle(.titleAndIcon)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                Divider().opacity(0.3)

                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            respond("Snoozed")
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Later")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "F59E0B"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.tint(.white), in: Capsule())

                        Button {
                            respond("Yes")
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Accept")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "007AFF"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.tint(.white), in: Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }

    private func respond(_ r: String) {
        response = r
        withAnimation(DS.Animation.snappy) { responded = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onDismiss() }
    }
}

// MARK: - RSVP Button
struct RSVPButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Suggestion Banner
struct HomeSuggestionBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: DS.Space.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(DS.Color.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("45 min gap at 11:00")
                    .font(DS.Font.caption1())
                    .foregroundColor(DS.Color.textTertiary)
                Text("Add a reading block?")
                    .font(DS.Font.subheadline())
                    .foregroundColor(DS.Color.textPrimary)
            }

            Spacer()

            HStack(spacing: DS.Space.sm) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(DS.Color.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle().fill(DS.Color.surfaceHigh)
                        )
                }
                .buttonStyle(.plain)

                Button {} label: {
                    Text("Add")
                        .font(DS.Font.footnote())
                        .foregroundColor(.white)
                        .padding(.horizontal, DS.Space.md)
                        .padding(.vertical, DS.Space.xs + 2)
                        .background(DS.Color.textPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.base)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DS.Color.surface)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}
