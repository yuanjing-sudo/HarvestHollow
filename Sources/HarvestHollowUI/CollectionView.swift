#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Collection

public struct CollectionView: View {
    @EnvironmentObject private var store: GameStore
    @State private var category: CollectionCategory = .crops
    @State private var selectedFish: FishDefinition?
    @State private var selectedDetail: CollectionDetail?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                TownScreenHeader(
                    title: "Collection Book",
                    subtitle: "A paper record of everything the farm has grown, caught, cooked, and sent to market.",
                    icon: "books.vertical.fill",
                    accent: HHTheme.lavender
                )

                summaryCard
                categoryTabs
                collectionGrid
                collectionNotes
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(HHTheme.cream)
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $selectedFish) { fish in
            FishDetailSheet(fish: fish)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedDetail) { detail in
            CollectionDetailSheet(detail: detail)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Summary

    private var summaryCard: some View {
        CozyCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProgressRing(
                        value: store.collectionProgress,
                        tint: HHTheme.lavender,
                        lineWidth: 8,
                        label: "\(Int(store.collectionProgress * 100))%",
                        detail: "found"
                    )
                    .frame(width: 70, height: 70)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("The Hollow collection")
                            .font(.hhTitle(21))
                            .foregroundStyle(HHTheme.ink)
                        Text("\(totalFound) of \(totalPossible) entries discovered")
                            .font(.hhBody(12))
                            .foregroundStyle(HHTheme.muted)
                        Text(collectionMessage)
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    ForEach(CollectionCategory.allCases) { item in
                        VStack(spacing: 3) {
                            HStack(spacing: 3) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 9, weight: .bold))
                                Text("\(foundCount(item))/\(totalCount(item))")
                                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                    .monospacedDigit()
                            }
                            .foregroundStyle(categoryColor(item))
                            MiniTrendBar(value: progress(item), tint: categoryColor(item))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var totalFound: Int {
        CollectionCategory.allCases.reduce(0) { $0 + foundCount($1) }
    }

    private var totalPossible: Int {
        CollectionCategory.allCases.reduce(0) { $0 + totalCount($1) }
    }

    private var collectionMessage: String {
        if store.collectionProgress >= 1 {
            return "Every page is full. The valley is quietly impressed."
        }
        if store.collectionProgress > 0.65 {
            return "The book is filling up. A few blank corners remain."
        }
        if store.collectionProgress > 0.25 {
            return "A good start. There are still stories hiding in the pond and the pantry."
        }
        return "The first page is always the quietest. Go and find something new."
    }

    private func categoryColor(_ item: CollectionCategory) -> Color {
        switch item {
        case .crops: return HHTheme.forest
        case .fish: return Color(hex: "4F6D8A")
        case .barnGoods: return HHTheme.terracotta
        case .dishes: return HHTheme.goldDeep
        case .recipes: return HHTheme.lavender
        }
    }

    private func progress(_ item: CollectionCategory) -> Double {
        let total = max(1, totalCount(item))
        return Double(foundCount(item)) / Double(total)
    }

    private func foundCount(_ item: CollectionCategory) -> Int {
        switch item {
        case .crops:
            return store.catalog.crops.filter { store.isCropDiscovered($0.id) }.count
        case .fish:
            return store.uniqueFishCaught
        case .barnGoods:
            return store.catalog.animals.filter { store.isItemDiscovered($0.productItemID) }.count
        case .dishes:
            return store.catalog.recipes.filter {
                store.itemCount($0.dishItemID) > 0
                    || store.soldCount(itemID: $0.dishItemID) > 0
                    || store.hasCooked(recipeID: $0.id)
            }.count
        case .recipes:
            return store.catalog.recipes.filter { store.hasCooked(recipeID: $0.id) }.count
        }
    }

    private func totalCount(_ item: CollectionCategory) -> Int {
        switch item {
        case .crops: return store.catalog.crops.count
        case .fish: return store.catalog.fish.count
        case .barnGoods: return store.catalog.animals.count
        case .dishes: return store.catalog.recipes.count
        case .recipes: return store.catalog.recipes.count
        }
    }

    // MARK: Tabs

    private var categoryTabs: some View {
        CozySegmentedPicker(
            items: CollectionCategory.allCases,
            selection: $category,
            tint: categoryColor(category),
            icon: { $0.icon },
            title: { "\($0.title) \(foundCount($0))/\(totalCount($0))" }
        )
    }

    // MARK: Grid

    private var collectionGrid: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionHeader(
                    category.title,
                    subtitle: categorySubtitle,
                    icon: category.icon,
                    accent: categoryColor(category)
                )
                Spacer(minLength: 4)
                Text("\(foundCount(category))/\(totalCount(category))")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(categoryColor(category))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor(category).opacity(0.09), in: Capsule())
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 102, maximum: 150), spacing: 8)],
                spacing: 8
            ) {
                switch category {
                case .crops:
                    ForEach(store.catalog.crops) { crop in
                        cropTile(crop)
                    }
                case .fish:
                    ForEach(store.catalog.fish) { fish in
                        fishTile(fish)
                    }
                case .barnGoods:
                    ForEach(store.catalog.animals) { species in
                        barnGoodTile(species)
                    }
                case .dishes:
                    ForEach(store.catalog.recipes) { recipe in
                        dishTile(recipe)
                    }
                case .recipes:
                    ForEach(store.catalog.recipes) { recipe in
                        recipeTile(recipe)
                    }
                }
            }
        }
    }

    private var categorySubtitle: String {
        switch category {
        case .crops: return "Every crop you have harvested at least once."
        case .fish: return "The pond's residents, from minnows to legends."
        case .barnGoods: return "Eggs, milk, wool, honey, and other barn treasures."
        case .dishes: return "Meals that have passed through the kitchen."
        case .recipes: return "Recipes you have actually cooked, not merely read."
        }
    }

    private func cropTile(_ crop: CropDefinition) -> some View {
        let discovered = store.isCropDiscovered(crop.id)
        let count = store.cropHarvestCount(crop.id)
        let tier = store.cropMasteryTier(crop.id)
        return collectionTile(
            spriteKey: crop.spriteKey,
            emoji: crop.emoji,
            title: discovered ? crop.name : "???",
            subtitle: discovered ? "\(count) harvested" : "Not yet grown",
            badge: discovered ? tier.emoji : nil,
            discovered: discovered,
            tint: HHTheme.forest
        ) {
            selectedDetail = CollectionDetail(
                id: "crop.\(crop.id)",
                title: discovered ? crop.name : "Undiscovered crop",
                subtitle: "Field collection",
                spriteKey: crop.spriteKey,
                emoji: crop.emoji,
                discovered: discovered,
                countLabel: "\(count) harvested",
                blurb: discovered ? crop.blurb : "Plant the seed and bring in a harvest to fill this page.",
                rows: [
                    ("clock.fill", "Grow time", "\(Int(crop.growSeconds / 60)) min"),
                    ("star.fill", "Mastery", discovered ? "\(tier.title) \(CropMastery.stars(for: count))" : "—"),
                    ("circle.fill", "Seed price", "\(crop.seedPrice) coins"),
                    ("cart.fill", "Sale value", "\(store.sellPrice(for: crop.produceItemID)) coins")
                ]
            )
        }
    }

    private func fishTile(_ fish: FishDefinition) -> some View {
        let discovered = store.isFishCaught(fish.id)
        let count = store.fishCatchCount(fish.id)
        let best = store.bestWeight(forFish: fish.id)
        return collectionTile(
            spriteKey: fish.spriteKey,
            emoji: fish.emoji,
            title: discovered ? fish.name : "???",
            subtitle: discovered ? String(format: "%.1f lb best", best) : "Not yet caught",
            badge: discovered ? fish.rarity.stars : nil,
            discovered: discovered,
            tint: Color(hex: fish.rarity.tintHex)
        ) {
            selectedFish = fish
        }
    }

    private func barnGoodTile(_ species: AnimalSpecies) -> some View {
        let item = store.catalog.item(species.productItemID)
        let discovered = store.isItemDiscovered(species.productItemID)
        let count = store.itemCount(species.productItemID) + store.soldCount(itemID: species.productItemID)
        return collectionTile(
            spriteKey: item?.spriteKey,
            emoji: item?.emoji ?? "📦",
            title: discovered ? (item?.name ?? "Barn good") : "???",
            subtitle: discovered ? "\(count) collected" : "Not yet gathered",
            badge: discovered ? (item?.emoji ?? "🐾") : nil,
            discovered: discovered,
            tint: HHTheme.terracotta
        ) {
            selectedDetail = CollectionDetail(
                id: "good.\(species.id)",
                title: discovered ? (item?.name ?? "Barn good") : "Undiscovered barn good",
                subtitle: "Barn collection",
                spriteKey: item?.spriteKey,
                emoji: item?.emoji ?? "📦",
                discovered: discovered,
                countLabel: "\(count) collected",
                blurb: item?.detail ?? "Welcome \(species.name.lowercased()) to the barn and collect their gift.",
                rows: [
                    ("pawprint.fill", "From", species.name),
                    ("clock.fill", "Produce time", "\(Int(species.produceSeconds / 60)) min"),
                    ("cart.fill", "Sale value", "\(store.sellPrice(for: species.productItemID)) coins"),
                    ("shippingbox.fill", "Capacity", "\(species.capacity) stored")
                ]
            )
        }
    }

    private func dishTile(_ recipe: RecipeDefinition) -> some View {
        let item = store.catalog.item(recipe.dishItemID)
        let discovered = store.itemCount(recipe.dishItemID) > 0
            || store.soldCount(itemID: recipe.dishItemID) > 0
            || store.hasCooked(recipeID: recipe.id)
        let count = store.itemCount(recipe.dishItemID)
        return collectionTile(
            spriteKey: recipe.spriteKey,
            emoji: recipe.emoji,
            title: discovered ? recipe.name : "???",
            subtitle: discovered ? "\(count) in pantry" : "Not yet cooked",
            badge: discovered ? "\(recipe.buff.percent)%" : nil,
            discovered: discovered,
            tint: Color(hex: recipe.buff.kind.tintHex)
        ) {
            selectedDetail = dishDetail(recipe, itemName: item?.name ?? recipe.name, discovered: discovered)
        }
    }

    private func recipeTile(_ recipe: RecipeDefinition) -> some View {
        let discovered = store.hasCooked(recipeID: recipe.id)
        let count = store.cookedCount(recipeID: recipe.id)
        return collectionTile(
            spriteKey: recipe.spriteKey,
            emoji: recipe.emoji,
            title: discovered ? recipe.name : "???",
            subtitle: discovered ? "Cooked \(count)×" : "Not yet discovered",
            badge: discovered ? recipe.category.title : nil,
            discovered: discovered,
            tint: HHTheme.lavender
        ) {
            selectedDetail = recipeDetail(recipe, discovered: discovered, cooked: count)
        }
    }

    private func dishDetail(
        _ recipe: RecipeDefinition,
        itemName: String,
        discovered: Bool
    ) -> CollectionDetail {
        CollectionDetail(
            id: "dish.\(recipe.id)",
            title: discovered ? itemName : "Undiscovered dish",
            subtitle: "Kitchen collection",
            spriteKey: recipe.spriteKey,
            emoji: recipe.emoji,
            discovered: discovered,
            countLabel: "\(store.itemCount(recipe.dishItemID)) in pantry",
            blurb: discovered ? recipe.blurb : "Cook this recipe to add it to the collection.",
            rows: [
                ("fork.knife", "Category", recipe.category.title),
                ("sparkles", "Buff", recipe.buffSummary),
                ("cart.fill", "Sale value", "\(store.sellPrice(for: recipe.dishItemID)) coins"),
                ("flame.fill", "Cooked", "\(store.cookedCount(recipeID: recipe.id)) times")
            ]
        )
    }

    private func recipeDetail(
        _ recipe: RecipeDefinition,
        discovered: Bool,
        cooked: Int
    ) -> CollectionDetail {
        CollectionDetail(
            id: "recipe.\(recipe.id)",
            title: discovered ? recipe.name : "Undiscovered recipe",
            subtitle: "Recipe collection",
            spriteKey: recipe.spriteKey,
            emoji: recipe.emoji,
            discovered: discovered,
            countLabel: "\(cooked) cooked",
            blurb: discovered ? recipe.blurb : "Reach level \(recipe.unlockLevel) and cook this dish to reveal the page.",
            rows: [
                ("lock.open.fill", "Unlock", "Level \(recipe.unlockLevel)"),
                ("sparkles", "Buff", recipe.buffSummary),
                ("shippingbox.fill", "Ingredients", "\(recipe.ingredients.count) kinds"),
                ("flame.fill", "Prep", "\(Int(recipe.prepSeconds)) sec")
            ]
        )
    }

    private func collectionTile(
        spriteKey: String?,
        emoji: String,
        title: String,
        subtitle: String,
        badge: String?,
        discovered: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(tint.opacity(discovered ? 0.09 : 0.035))
                        .frame(height: 62)
                    ItemIconView(spriteKey: spriteKey, emoji: emoji, size: 54)
                        .opacity(discovered ? 1 : 0.22)
                        .saturation(discovered ? 1 : 0)
                    if !discovered {
                        Image(systemName: "questionmark")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted.opacity(0.65))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    if let badge, discovered {
                        Text(badge)
                            .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.white.opacity(0.82), in: Capsule())
                            .padding(4)
                    }
                }
                Text(title)
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(discovered ? HHTheme.ink : HHTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(6)
            .background(HHTheme.paper.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(discovered ? 0.14 : 0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Notes

    private var collectionNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "A note on the book",
                subtitle: "Nothing in the collection is lost when you sell it.",
                icon: "bookmark.fill"
            )
            noteRow("🌾", "Harvesting a crop records it permanently. Mastery keeps counting afterward.")
            noteRow("🐟", "Catching a fish once is enough. The best weight is kept as a little trophy.")
            noteRow("🍲", "Cooking and eating are separate pages: recipes and dishes both count.")
            noteRow("🏪", "Selling a barn good or dish records it even if the pantry is empty.")
        }
    }

    private func noteRow(_ emoji: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji).font(.system(size: 15))
            Text(text)
                .font(.hhBody(11.5))
                .foregroundStyle(HHTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Collection detail model

public struct CollectionDetail: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let spriteKey: String?
    public let emoji: String
    public let discovered: Bool
    public let countLabel: String
    public let blurb: String
    public let rows: [(icon: String, label: String, value: String)]

    public init(
        id: String,
        title: String,
        subtitle: String,
        spriteKey: String?,
        emoji: String,
        discovered: Bool,
        countLabel: String,
        blurb: String,
        rows: [(icon: String, label: String, value: String)]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.spriteKey = spriteKey
        self.emoji = emoji
        self.discovered = discovered
        self.countLabel = countLabel
        self.blurb = blurb
        self.rows = rows
    }
}

// MARK: - Detail sheet

public struct CollectionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let detail: CollectionDetail

    public init(detail: CollectionDetail) {
        self.detail = detail
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 13) {
                HStack {
                    TagChip(detail.subtitle, icon: "books.vertical.fill", tint: detail.discovered ? HHTheme.lavender : HHTheme.muted)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }

                ItemIconView(spriteKey: detail.spriteKey, emoji: detail.emoji, size: 128)
                    .opacity(detail.discovered ? 1 : 0.3)
                    .saturation(detail.discovered ? 1 : 0)

                VStack(spacing: 3) {
                    Text(detail.title)
                        .font(.hhTitle(24))
                        .foregroundStyle(HHTheme.ink)
                    Text(detail.countLabel)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                    Text(detail.blurb)
                        .font(.hhBody(12.5))
                        .foregroundStyle(HHTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 3)
                }

                VStack(spacing: 9) {
                    ForEach(Array(detail.rows.enumerated()), id: \.offset) { _, row in
                        TownInfoRow(
                            icon: row.icon,
                            title: row.label,
                            value: row.value,
                            tint: detail.discovered ? HHTheme.lavender : HHTheme.muted
                        )
                    }
                }
                .padding(13)
                .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(17)
        }
        .background(HHTheme.cream)
    }
}
#endif
