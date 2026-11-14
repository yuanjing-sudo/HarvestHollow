#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Town hub

public struct TownView: View {
    @EnvironmentObject private var store: GameStore

    private var state: GameState { store.state }

    public init() {}

    public var body: some View {
        NavigationStack(path: $store.townPath) {
            ScrollView {
                VStack(spacing: 15) {
                    townHero
                    dailyGiftCard
                    if let buff = store.currentFoodBuff {
                        activeBuffCard(buff)
                    }
                    townPlaces
                    townNotices
                    weeklySnapshot
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TownRoute.self) { route in
                destination(for: route)
            }
        }
    }

    // MARK: Hero

    private var townHero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                WeatherDiorama(
                    weather: state.weather,
                    timeOfDay: state.timeOfDay,
                    compact: false
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(state.season.emoji)
                        Text("\(state.season.title) · Day \(state.seasonDay)")
                    }
                    .font(.hhCaption(10.5))
                    .foregroundStyle(.white.opacity(0.9))

                    Text("Hollowmere")
                        .font(.hhTitle(28))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.16), radius: 3, y: 1)

                    Text(state.season.greeting)
                        .font(.hhBody(12))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(15)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(state.weather.emoji)
                        .font(.system(size: 25))
                    Text(state.weather.title)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 7, weight: .bold))
                        Text(state.nextWeather.emoji)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            .frame(height: 174)

            HStack(spacing: 0) {
                heroStat(
                    value: "\(state.day)",
                    label: "Day",
                    icon: "sun.max.fill",
                    tint: HHTheme.goldDeep
                )
                Divider().frame(height: 28).overlay(HHTheme.ink.opacity(0.08))
                heroStat(
                    value: "\(store.uniqueFishCaught)/\(store.catalog.fish.count)",
                    label: "Fish",
                    icon: "fish.fill",
                    tint: Color(hex: "4F6D8A")
                )
                Divider().frame(height: 28).overlay(HHTheme.ink.opacity(0.08))
                heroStat(
                    value: "\(store.uniqueRecipesCooked)/\(store.catalog.recipes.count)",
                    label: "Recipes",
                    icon: "fork.knife",
                    tint: HHTheme.terracotta
                )
                Divider().frame(height: 28).overlay(HHTheme.ink.opacity(0.08))
                heroStat(
                    value: "\(store.claimedAchievementCount)",
                    label: "Badges",
                    icon: "rosette",
                    tint: HHTheme.lavender
                )
            }
            .padding(.vertical, 10)
            .background(HHTheme.paper)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: HHTheme.soilDark.opacity(0.16), radius: 16, y: 8)
    }

    private func heroStat(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(.hhCaption(9))
                .foregroundStyle(HHTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Daily gift

    private var dailyGiftCard: some View {
        CozyCard {
            VStack(spacing: 11) {
                HStack(alignment: .top, spacing: 11) {
                    Text(store.dailyGift.emoji)
                        .font(.system(size: 27))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle().fill(
                                LinearGradient(
                                    colors: [HHTheme.rose.opacity(0.35), HHTheme.gold.opacity(0.28)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .overlay(Circle().stroke(HHTheme.rose.opacity(0.2), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(store.canClaimDailyGift ? "A parcel on the step" : "Parcel opened")
                                .font(.hhHeadline(14.5))
                                .foregroundStyle(HHTheme.ink)
                            if store.dailyGiftStreak > 0 {
                                TagChip("\(store.dailyGiftStreak)-day streak", icon: "flame.fill", tint: HHTheme.terracotta)
                            }
                        }
                        Text(store.canClaimDailyGift
                            ? "Day \(store.dailyGiftCycleDay) of 7 · \(store.dailyGift.title)"
                            : "Come back tomorrow for the next little parcel.")
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 2)
                }

                HStack(spacing: 6) {
                    TagChip("+\(store.dailyGift.coins) coins", icon: "circle.fill", tint: HHTheme.goldDeep)
                    TagChip("+\(store.dailyGift.xp) XP", icon: "sparkles", tint: HHTheme.forest)
                    ForEach(Array(store.dailyGift.items.keys.sorted().prefix(2)), id: \.self) { itemID in
                        if let item = store.catalog.item(itemID) {
                            TagChip("\(item.emoji) ×\(store.dailyGift.items[itemID] ?? 1)", tint: HHTheme.rose)
                        }
                    }
                    Spacer(minLength: 0)
                }

                Button {
                    store.claimDailyGift()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: store.canClaimDailyGift ? "gift.fill" : "checkmark.circle.fill")
                        Text(store.canClaimDailyGift ? "Open today's parcel" : "Claimed today")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())
                .disabled(!store.canClaimDailyGift)
                .opacity(store.canClaimDailyGift ? 1 : 0.65)
            }
        }
    }

    private func activeBuffCard(_ buff: FoodBuff) -> some View {
        HStack(spacing: 10) {
            Text(buff.emoji)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .background(Color(hex: buff.kind.tintHex).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(buff.name)
                        .font(.hhHeadline(13))
                        .foregroundStyle(HHTheme.ink)
                    TagChip("+\(buff.percent)%", icon: buff.kind.icon, tint: Color(hex: buff.kind.tintHex))
                }
                Text("\(buff.kind.summary) · \(timeRemainingText(buff)) left")
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: buff.kind.tintHex).opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: buff.kind.tintHex).opacity(0.16), lineWidth: 1)
        )
    }

    private func timeRemainingText(_ buff: FoodBuff) -> String {
        let seconds = max(0, Int(buff.secondsRemaining(at: Date())))
        if seconds >= 60 { return "\(seconds / 60)m" }
        return "\(seconds)s"
    }

    // MARK: Places

    private var townPlaces: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(
                    "Places in town",
                    subtitle: "The pond, the kitchen, and the quieter corners of the valley.",
                    icon: "map.fill"
                )
                Spacer(minLength: 4)
                Text("\(Int(store.collectionProgress * 100))%")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.forest)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HHTheme.forest.opacity(0.09), in: Capsule())
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 9)],
                spacing: 9
            ) {
                TownFeatureCard(
                    title: "Hollow Pond",
                    subtitle: "Cast a line, meet the fish, upgrade your rod.",
                    icon: "fish.fill",
                    accent: Color(hex: "4F6D8A"),
                    badge: "\(store.uniqueFishCaught)/\(store.catalog.fish.count)"
                ) {
                    store.townPath.append(.fishing)
                }

                TownFeatureCard(
                    title: "Cottage Kitchen",
                    subtitle: "Turn harvests into meals with a little magic.",
                    icon: "fork.knife",
                    accent: HHTheme.terracotta,
                    badge: "\(store.uniqueRecipesCooked)/\(store.catalog.recipes.count)"
                ) {
                    store.townPath.append(.kitchen)
                }

                TownFeatureCard(
                    title: "Almanac",
                    subtitle: "Weather, seasons, markets, and crop mastery.",
                    icon: "calendar",
                    accent: HHTheme.goldDeep,
                    badge: store.season.emoji
                ) {
                    store.townPath.append(.almanac)
                }

                TownFeatureCard(
                    title: "Collection",
                    subtitle: "Every crop, fish, barn good, dish, and recipe.",
                    icon: "books.vertical.fill",
                    accent: HHTheme.lavender,
                    badge: "\(Int(store.collectionProgress * 100))%"
                ) {
                    store.townPath.append(.collection)
                }

                TownFeatureCard(
                    title: "Achievements",
                    subtitle: "Long-term goals with coins, items, and bragging rights.",
                    icon: "rosette",
                    accent: HHTheme.forest,
                    badge: store.claimableAchievementCount > 0
                        ? "\(store.claimableAchievementCount) ready"
                        : "\(store.claimedAchievementCount)/\(store.catalog.achievements.count)"
                ) {
                    store.townPath.append(.achievements)
                }

                TownFeatureCard(
                    title: "How to Play",
                    subtitle: "A friendly guide to every corner of the farm.",
                    icon: "questionmark.circle.fill",
                    accent: HHTheme.muted
                ) {
                    store.townPath.append(.help)
                }
            }
        }
    }

    // MARK: Notices

    private var townNotices: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(
                "Town notes",
                subtitle: "What the valley is talking about today.",
                icon: "text.bubble.fill"
            )

            eventRow(
                icon: "megaphone.fill",
                tint: HHTheme.terracotta,
                title: store.festival?.name ?? "A quiet day in Hollowmere",
                detail: store.festival?.blurb ?? "The square is calm. A good day for the pond or a slow afternoon in the kitchen."
            )

            if let quest = store.activeQuest {
                Button {
                    store.selectedTab = .quests
                } label: {
                    eventRow(
                        icon: "book.closed.fill",
                        tint: HHTheme.forest,
                        title: "Story: \(quest.title)",
                        detail: quest.blurb
                    )
                }
                .buttonStyle(.plain)
            }

            if let order = state.dailyOrder, !order.completed {
                Button {
                    store.selectedTab = .market
                } label: {
                    eventRow(
                        icon: "shippingbox.fill",
                        tint: HHTheme.goldDeep,
                        title: "Daily order: \(store.catalog.item(order.itemID)?.name ?? "goods")",
                        detail: "\(order.progress)/\(order.target) delivered · +\(order.rewardCoins) coins"
                    )
                }
                .buttonStyle(.plain)
            }

            if store.claimableAchievementCount > 0 {
                Button {
                    store.townPath.append(.achievements)
                } label: {
                    eventRow(
                        icon: "rosette",
                        tint: HHTheme.lavender,
                        title: "\(store.claimableAchievementCount) achievement\(store.claimableAchievementCount == 1 ? "" : "s") ready",
                        detail: "The journal has fresh rewards waiting to be claimed."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func eventRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hhHeadline(12.5))
                    .foregroundStyle(HHTheme.ink)
                Text(detail)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(HHTheme.paper.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.09), lineWidth: 1)
        )
    }

    // MARK: Snapshot

    private var weeklySnapshot: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    "The week so far",
                    subtitle: "A few quiet numbers from the farm ledger.",
                    icon: "chart.line.uptrend.xyaxis"
                )

                HStack(spacing: 9) {
                    StatTile(
                        title: "Coins",
                        value: "\(state.coins)",
                        icon: "circle.fill",
                        tint: HHTheme.goldDeep
                    )
                    StatTile(
                        title: "Harvests",
                        value: "\(state.stats.cropsHarvested)",
                        icon: "basket.fill",
                        tint: HHTheme.forest
                    )
                    StatTile(
                        title: "Collection",
                        value: "\(Int(store.collectionProgress * 100))%",
                        icon: "books.vertical.fill",
                        tint: HHTheme.lavender
                    )
                }

                HStack(spacing: 7) {
                    TownQuickLink(title: "Farm", icon: "leaf.fill", tint: HHTheme.forest) {
                        store.selectedTab = .farm
                    }
                    TownQuickLink(title: "Barn", icon: "pawprint.fill", tint: HHTheme.terracotta) {
                        store.selectedTab = .barn
                    }
                    TownQuickLink(title: "Market", icon: "cart.fill", tint: HHTheme.goldDeep) {
                        store.selectedTab = .market
                    }
                    TownQuickLink(title: "Quests", icon: "checklist", tint: HHTheme.lavender) {
                        store.selectedTab = .quests
                    }
                }
            }
        }
    }

    // MARK: Destinations

    @ViewBuilder
    private func destination(for route: TownRoute) -> some View {
        switch route {
        case .fishing:
            FishingView()
        case .kitchen:
            KitchenView()
        case .achievements:
            AchievementsView()
        case .almanac:
            AlmanacView()
        case .collection:
            CollectionView()
        case .help:
            HelpView()
        }
    }
}
#endif
