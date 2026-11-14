#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Market

public struct MarketView: View {
    @EnvironmentObject private var store: GameStore
    @State private var mode: MarketMode = .buy

    private var state: GameState { store.state }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                marketHeader
                if let order = state.dailyOrder {
                    dailyOrderCard(order)
                }
                modePicker
                if mode == .buy {
                    seedsSection
                    suppliesSection
                    furnitureSection
                    themesSection
                    barnLink
                } else {
                    sellSection
                }
                marketNote
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Header

    private var marketHeader: some View {
        CozyCard {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("🧺")
                        .font(.system(size: 28))
                        .frame(width: 50, height: 50)
                        .background(HHTheme.gold.opacity(0.18), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Saturday Market")
                            .font(.hhHeadline(18))
                            .foregroundStyle(HHTheme.ink)
                        Text("Open every day, rain or shine. Prices shift with the weather of the week.")
                            .font(.hhBody(12.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    CoinPill(state.coins)
                }

                HStack(spacing: 7) {
                    TagChip("Day \(state.day)", icon: "sun.max.fill", tint: HHTheme.terracotta)
                    TagChip("\(state.weather.emoji) \(state.weather.title)", tint: HHTheme.forest)
                    TagChip("Comfort +\(store.comfortBonusPercent)%", icon: "sofa.fill", tint: HHTheme.rose)
                    Spacer(minLength: 0)
                }

                HStack(spacing: 7) {
                    TownQuickLink(title: "Pond", icon: "fish.fill", tint: Color(hex: "4F6D8A")) {
                        store.openTown(.fishing)
                    }
                    TownQuickLink(title: "Kitchen", icon: "fork.knife", tint: HHTheme.terracotta) {
                        store.openTown(.kitchen)
                    }
                    TownQuickLink(title: "Almanac", icon: "calendar", tint: HHTheme.goldDeep) {
                        store.openTown(.almanac)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Mode

    private var modePicker: some View {
        Picker("Market mode", selection: $mode) {
            ForEach(MarketMode.allCases) { choice in
                Text(choice.title).tag(choice)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Daily order

    private func dailyOrderCard(_ order: DailyOrder) -> some View {
        let item = store.catalog.item(order.itemID)
        let fraction = min(1, Double(order.progress) / Double(max(1, order.target)))

        return CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ItemIconView(
                        spriteKey: item?.spriteKey,
                        emoji: item?.emoji ?? "📦",
                        size: 38
                    )
                    .frame(width: 48, height: 48)
                    .background(HHTheme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.completed ? "Order delivered!" : "Today's market order")
                            .font(.hhHeadline(15))
                            .foregroundStyle(HHTheme.ink)
                        Text(order.completed
                            ? "A new order arrives tomorrow."
                            : "Bring \(order.target) \(item?.name.lowercased() ?? "goods") to the stall.")
                            .font(.hhBody(12))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 4)
                    if order.completed {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(HHTheme.forest)
                    } else {
                        Text("\(order.progress)/\(order.target)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.forest)
                            .monospacedDigit()
                    }
                }

                CozyProgressBar(
                    value: fraction,
                    tint: order.completed ? HHTheme.forest : HHTheme.goldDeep,
                    height: 7
                )

                HStack(spacing: 7) {
                    TagChip("+\(order.rewardCoins) coins", icon: "circle.fill", tint: HHTheme.goldDeep)
                    TagChip("+\(order.rewardXP) XP", icon: "sparkles", tint: HHTheme.forest)
                    Spacer(minLength: 0)
                    if !order.completed {
                        Button {
                            mode = .sell
                        } label: {
                            Text("Sell goods")
                                .font(.hhHeadline(11.5))
                        }
                        .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
                    }
                }
            }
        }
    }

    // MARK: Seeds

    private var seedsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                "Seeds",
                subtitle: "Unlock more crops as your farm level rises.",
                icon: "leaf.fill"
            )

            VStack(spacing: 8) {
                ForEach(store.catalog.crops) { crop in
                    cropRow(crop)
                }
            }
        }
    }

    private func cropRow(_ crop: CropDefinition) -> some View {
        let unlocked = state.level >= crop.unlockLevel
        let owned = store.seedCount(crop.id)

        return VStack(spacing: 9) {
            HStack(alignment: .center, spacing: 11) {
                CropSpriteView(cropID: crop.id, size: 42)
                    .frame(width: 46)
                    .opacity(unlocked ? 1 : 0.4)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(crop.name)
                            .font(.hhHeadline(15))
                            .foregroundStyle(HHTheme.ink)
                        if !unlocked {
                            Text("Lv \(crop.unlockLevel)")
                                .font(.hhCaption(9.5))
                                .foregroundStyle(HHTheme.terracotta)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HHTheme.terracotta.opacity(0.1), in: Capsule())
                        }
                    }
                    Text("\(Int(crop.growSeconds))s grow · \(crop.minYield)–\(crop.maxYield) yield · sells \(crop.sellPrice)c")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    CoinPill(crop.seedPrice, compact: true)
                    Text("\(owned) owned")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(owned > 0 ? HHTheme.forest : HHTheme.muted)
                }
            }

            HStack(spacing: 7) {
                Text(crop.blurb)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                Button("Buy 1") {
                    store.buySeed(cropID: crop.id, quantity: 1)
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.forest))
                .disabled(!unlocked)
                .opacity(unlocked ? 1 : 0.45)

                Button("×5") {
                    store.buySeed(cropID: crop.id, quantity: 5)
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
                .disabled(!unlocked)
                .opacity(unlocked ? 1 : 0.45)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.paper.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: Supplies

    private var suppliesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                "Supplies",
                subtitle: "Keep the farm fed and the soil happy.",
                icon: "bag.fill"
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 155, maximum: 300), spacing: 10)],
                spacing: 10
            ) {
                ForEach(store.catalog.supplies) { supply in
                    supplyCard(supply)
                }
            }
        }
    }

    private func supplyCard(_ supply: SupplyDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(supply.emoji)
                    .font(.system(size: 24))
                Spacer()
                Text("\(store.itemCount(supply.id)) owned")
                    .font(.hhCaption(9.5))
                    .foregroundStyle(HHTheme.muted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(supply.name)
                    .font(.hhHeadline(14.5))
                    .foregroundStyle(HHTheme.ink)
                Text(supply.detail)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                CoinPill(supply.price, compact: true)
                Spacer(minLength: 4)
                Button("Buy") {
                    store.buySupply(supply.id, quantity: 1)
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.forest))
                Button("×5") {
                    store.buySupply(supply.id, quantity: 5)
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.paper.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: Furniture

    private var furnitureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                "Furniture",
                subtitle: "Comfort raises every market price you earn.",
                icon: "sofa.fill"
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150, maximum: 280), spacing: 10)],
                spacing: 10
            ) {
                ForEach(store.catalog.furniture) { item in
                    furnitureCard(item)
                }
            }
        }
    }

    private func furnitureCard(_ item: FurnitureDefinition) -> some View {
        let owned = store.itemCount(item.id)
        let definition = store.catalog.item(item.id)

        return VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(HHTheme.cream)
                FurnitureSpriteView(itemID: item.id, emoji: item.emoji)
                    .padding(6)
            }
            .frame(height: 72)

            HStack(spacing: 5) {
                Text(item.name)
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                Spacer(minLength: 2)
                if owned > 0 {
                    Text("×\(owned)")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.forest)
                }
            }

            HStack(spacing: 5) {
                TagChip("+\(item.comfort) comfort", icon: "heart.fill", tint: HHTheme.rose)
                Spacer(minLength: 2)
                CoinPill(item.price, compact: true)
            }

            Button {
                store.buyFurniture(item.id)
            } label: {
                Text(definition?.name == nil ? "Buy" : "Buy for the house")
                    .font(.hhHeadline(11))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(MiniActionStyle(tint: HHTheme.forest))
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.paper.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: Themes

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                "House themes",
                subtitle: "A fresh coat of paint for the old farmhouse.",
                icon: "paintbrush.fill"
            )

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(store.catalog.themes) { theme in
                        themeCard(theme)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func themeCard(_ theme: HouseTheme) -> some View {
        let owned = state.themesOwned.contains(theme.id)
        let applied = state.house.themeID == theme.id

        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                Color(hex: theme.wallHex)
                VStack(spacing: 0) {
                    Spacer()
                    Color(hex: theme.floorHex)
                        .frame(height: 26)
                }
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: theme.accentHex))
                    .frame(width: 22, height: 22)
                    .padding(9)
            }
            .frame(height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(theme.name)
                .font(.hhHeadline(13.5))
                .foregroundStyle(HHTheme.ink)

            HStack(spacing: 5) {
                if applied {
                    TagChip("Applied", icon: "checkmark", tint: HHTheme.forest)
                } else if owned {
                    TagChip("Owned", icon: "checkmark", tint: HHTheme.forest)
                } else {
                    CoinPill(theme.price, compact: true)
                }
                Spacer(minLength: 2)
            }

            Button {
                if owned {
                    store.applyTheme(theme.id)
                } else {
                    store.buyTheme(theme.id)
                }
            } label: {
                Text(applied ? "Current theme" : (owned ? "Apply theme" : "Unlock theme"))
                    .font(.hhHeadline(11))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(MiniActionStyle(tint: applied ? HHTheme.muted : HHTheme.forest))
            .disabled(applied)
            .opacity(applied ? 0.55 : 1)
        }
        .frame(width: 158, alignment: .leading)
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.paper.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(applied ? HHTheme.forest.opacity(0.35) : HHTheme.ink.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: Barn link

    private var barnLink: some View {
        Button {
            store.selectedTab = .barn
        } label: {
            HStack(spacing: 11) {
                Text("🐓")
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .background(HHTheme.leaf.opacity(0.13), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Looking for a barn friend?")
                        .font(.hhHeadline(14.5))
                        .foregroundStyle(HHTheme.ink)
                    Text("Chickens, cows, pigs and more are waiting in the barn.")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HHTheme.muted)
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HHTheme.leaf.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(HHTheme.leaf.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Sell

    private var sellSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                SectionHeader(
                    "Sell your goods",
                    subtitle: "Prices move daily. Comfort adds a little extra.",
                    icon: "shippingbox.fill"
                )
                Spacer(minLength: 8)
                TagChip("+\(store.comfortBonusPercent)% comfort", icon: "sofa.fill", tint: HHTheme.rose)
            }

            if store.sellableInventory.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "Nothing to sell yet",
                    message: "Harvest a crop or collect a barn good, then bring it back to the stall.",
                    accent: HHTheme.goldDeep
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(store.sellableInventory, id: \.item.id) { entry in
                        sellRow(entry.item, count: entry.count)
                    }
                }
            }
        }
    }

    private func sellRow(_ item: ItemDefinition, count: Int) -> some View {
        let price = store.sellPrice(for: item.id)
        let trend = store.priceTrend(for: item.id)
        let trendPercent = Int((trend * 100).rounded())

        return HStack(spacing: 10) {
            ItemIconView(spriteKey: item.spriteKey, emoji: item.emoji, size: 36)
                .frame(width: 44, height: 44)
                .background(HHTheme.cream, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    Text("×\(count)")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                }
                HStack(spacing: 5) {
                    Text("\(price)c each")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.forest)
                    if abs(trendPercent) >= 2 {
                        Text(trendPercent > 0 ? "▲ \(trendPercent)%" : "▼ \(abs(trendPercent))%")
                            .font(.hhCaption(9.5))
                            .foregroundStyle(trendPercent > 0 ? HHTheme.forest : HHTheme.terracotta)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                (trendPercent > 0 ? HHTheme.forest : HHTheme.terracotta).opacity(0.1),
                                in: Capsule()
                            )
                    } else {
                        Text("steady")
                            .font(.hhCaption(9.5))
                            .foregroundStyle(HHTheme.muted)
                    }
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(price * count)c")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.goldDeep)
                HStack(spacing: 5) {
                    Button("Sell 1") {
                        store.sell(itemID: item.id, quantity: 1)
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.forest))
                    Button("All") {
                        store.sellAll(itemID: item.id)
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
                }
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(HHTheme.paper.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: Footer

    private var marketNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🪙")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 3) {
                Text("How prices work")
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                Text("Each item has a daily price swing between 0.82× and 1.28×. Placing furniture at home raises comfort, which adds up to a 25% bonus on every sale.")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.sky.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.sky.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Mode

enum MarketMode: String, CaseIterable, Identifiable {
    case buy
    case sell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
}
#endif
