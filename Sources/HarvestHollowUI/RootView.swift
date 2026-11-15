#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Root

public struct RootView: View {
    @StateObject private var store: GameStore
    @Environment(\.scenePhase) private var scenePhase

    @MainActor
    public init(store: GameStore? = nil) {
        _store = StateObject(wrappedValue: store ?? GameStore())
    }

    public var body: some View {
        ZStack {
            HHTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                FarmHeaderView()

                if let notice = store.offlineNotice {
                    HStack(alignment: .top, spacing: 8) {
                        NoticeBanner(
                            icon: "moon.zzz.fill",
                            title: "While you were away",
                            message: notice,
                            tint: HHTheme.lavender
                        )
                        Button {
                            store.dismissOfflineNotice()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(HHTheme.muted)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                CozyTabBar(selection: $store.selectedTab)
            }
        }
        .environmentObject(store)
        .overlay(alignment: .bottom) {
            if let toast = store.toast {
                ToastView(
                    title: toast.title,
                    detail: toast.detail,
                    icon: toast.icon,
                    tint: toast.tint
                )
                .padding(.bottom, 82)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: store.toast?.id)
                .zIndex(20)
            }
        }
        .overlay {
            if store.showWelcome {
                WelcomeView()
                    .transition(.opacity)
                    .zIndex(30)
            }
        }
        .overlay {
            if let level = store.activeLevelUp {
                LevelUpOverlay(level: level) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.activeLevelUp = nil
                    }
                }
                .transition(.opacity)
                .zIndex(40)
            }
        }
        .sheet(isPresented: $store.showInventory) {
            InventorySheet()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $store.showSettings) {
            SettingsSheet()
                .environmentObject(store)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $store.showWeatherSheet) {
            WeatherSheet()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .tint(HHTheme.forest)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                store.saveNow()
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch store.selectedTab {
        case .farm:
            FarmView()
        case .barn:
            BarnView()
        case .market:
            MarketView()
        case .house:
            HouseView()
        case .town:
            TownView()
        case .quests:
            QuestsView()
        case .arcade:
            ArcadeView()
        case .economy:
            EconomyView()
        case .world:
            World3DView()
        }
    }
}

// MARK: - Header

public struct FarmHeaderView: View {
    @EnvironmentObject private var store: GameStore

    public init() {}

    private var state: GameState { store.state }

    private var isNight: Bool {
        state.timeOfDay < 0.22 || state.timeOfDay > 0.84
    }

    private var headerText: Color {
        isNight ? .white : HHTheme.ink
    }

    private var clockText: String {
        let totalMinutes = Int(state.timeOfDay * 24 * 60) % (24 * 60)
        return String(format: "%02d:%02d", totalMinutes / 60, totalMinutes % 60)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            HHTheme.headerGradient(timeOfDay: state.timeOfDay)
                .overlay(alignment: .bottom) {
                    ZStack(alignment: .bottom) {
                        Ellipse()
                            .fill(HHTheme.forest.opacity(0.13))
                            .frame(width: 520, height: 90)
                            .offset(x: -80, y: 58)
                        Ellipse()
                            .fill(HHTheme.forest.opacity(0.2))
                            .frame(width: 460, height: 78)
                            .offset(x: 110, y: 64)
                    }
                    .allowsHitTesting(false)
                }

            VStack(spacing: 11) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(HHTheme.paper.opacity(0.9))
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(HHTheme.forest)
                    }
                    .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Harvest Hollow")
                            .font(.hhTitle(23))
                            .foregroundStyle(headerText)
                        Text("Day \(state.day) · \(state.season.title) \(state.seasonDay) · \(clockText)")
                            .font(.hhCaption(11))
                            .foregroundStyle(headerText.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 4)

                    RoundIconButton(icon: "bag.fill") {
                        store.showInventory = true
                    }
                    RoundIconButton(icon: "gearshape.fill") {
                        store.showSettings = true
                    }
                }

                HStack(spacing: 10) {
                    HStack(spacing: 7) {
                        LevelBadge(
                            level: state.level,
                            progress: state.levelProgress,
                            showXP: false
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Level \(state.level)")
                                .font(.hhHeadline(11.5))
                                .foregroundStyle(HHTheme.ink)
                                .lineLimit(1)
                            Text("\(state.xp)/\(state.xpForNextLevel) XP")
                                .font(.hhCaption(8.5))
                                .foregroundStyle(HHTheme.muted)
                                .monospacedDigit()
                                .lineLimit(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(HHTheme.paper.opacity(0.78))
                    )

                    Spacer(minLength: 4)

                    Button {
                        store.showWeatherSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Text(state.weather.emoji)
                                .font(.system(size: 15))
                            Text(state.weather.title)
                                .font(.hhHeadline(12.5))
                                .foregroundStyle(HHTheme.ink)
                            HStack(spacing: 1) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 7, weight: .bold))
                                Text(state.nextWeather.emoji)
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(HHTheme.muted)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(HHTheme.paper.opacity(0.82)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Weather: \(state.weather.title). Tomorrow: \(state.nextWeather.title).")

                    CoinPill(state.coins, compact: true)
                }

                CozyProgressBar(
                    value: state.timeOfDay,
                    tint: headerText.opacity(0.55),
                    height: 3
                )
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .frame(height: 148)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 26,
                bottomTrailingRadius: 26
            )
        )
        .shadow(color: HHTheme.soilDark.opacity(0.14), radius: 12, y: 6)
    }
}

// MARK: - Tab bar

public struct CozyTabBar: View {
    @Binding public var selection: AppTab
    @EnvironmentObject private var store: GameStore

    public init(selection: Binding<AppTab>) {
        _selection = selection
    }

    private func badgeCount(for tab: AppTab) -> Int {
        guard tab == .town else { return 0 }
        return (store.canClaimDailyGift ? 1 : 0) + (store.claimableAchievementCount > 0 ? 1 : 0)
    }

    public var body: some View {
        HStack(spacing: 1) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    if tab == .town, selection == .town {
                        store.closeTownToRoot()
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 2) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 15, weight: .bold))
                                .frame(width: 22, height: 19)
                            if badgeCount(for: tab) > 0 {
                                Circle()
                                    .fill(HHTheme.terracotta)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 3, y: -1)
                            }
                        }
                        Text(tab.shortTitle)
                            .font(.system(size: 8.6, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selection == tab ? .white : HHTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(HHTheme.forest)
                                .shadow(color: HHTheme.forest.opacity(0.24), radius: 4, y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 7)
        .padding(.top, 6)
        .padding(.bottom, 5)
        .background(
            HHTheme.paper.opacity(0.96)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(HHTheme.ink.opacity(0.06))
                        .frame(height: 1)
                }
        )
    }
}

// MARK: - Welcome

public struct WelcomeView: View {
    @EnvironmentObject private var store: GameStore

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Text("A cozy farm, all in Swift")
                            .font(.hhCaption(11))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                    }

                    if let pig = SpriteLibrary.animal("pig") {
                        PixelSpriteView(pig)
                            .frame(width: 150, height: 120)
                            .padding(.top, 4)
                    }

                    Text("Welcome to\nHarvest Hollow")
                        .font(.hhTitle(30))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(HHTheme.ink)

                    Text("A little farm, a warm cottage, and a valley full of friends.")
                        .font(.hhBody(14))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        welcomeRow(
                            icon: "leaf.fill",
                            title: "Plant, water, harvest",
                            detail: "Pick a seed, tap an empty plot, then water it. Tap a ripe crop to collect it."
                        )
                        welcomeRow(
                            icon: "pawprint.fill",
                            title: "Make barn friends",
                            detail: "Feed animals and collect eggs, milk, wool and other goods."
                        )
                        welcomeRow(
                            icon: "cart.fill",
                            title: "Sell, decorate, grow",
                            detail: "Trade at the market, cozy up the cottage, and finish quests to level up."
                        )
                    }

                    Button {
                        store.dismissWelcome()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Start farming")
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozyPrimaryButtonStyle())
                    .padding(.top, 4)

                    Text("Progress saves automatically, even while the app is closed.")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(HHTheme.cream)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(HHTheme.paper, lineWidth: 2)
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func welcomeRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(HHTheme.forest)
                .frame(width: 34, height: 34)
                .background(HHTheme.forest.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hhHeadline(14))
                    .foregroundStyle(HHTheme.ink)
                Text(detail)
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Level up

public struct LevelUpOverlay: View {
    public let level: Int
    public let onDismiss: () -> Void

    public init(level: Int, onDismiss: @escaping () -> Void) {
        self.level = level
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(HHTheme.goldDeep)
                Text("Level \(level)")
                    .font(.hhTitle(34))
                    .foregroundStyle(HHTheme.ink)
                Text("The valley noticed. New crops, animals and land may have unlocked.")
                    .font(.hhBody(14))
                    .foregroundStyle(HHTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Lovely", action: onDismiss)
                    .buttonStyle(CozyPrimaryButtonStyle())
                    .padding(.top, 2)
            }
            .padding(26)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(HHTheme.paper)
            )
            .shadow(color: .black.opacity(0.22), radius: 24, y: 10)
            .padding(.horizontal, 26)
        }
    }
}
#endif
