#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Kitchen

public struct KitchenView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var category: RecipeCategory?
    @State private var showOnlyCookable = false
    @State private var selectedRecipe: RecipeDefinition?
    @State private var lastCookedID: String?
    @State private var showCookedBanner = false

    private var state: GameState { store.state }
    private var recipes: [RecipeDefinition] {
        store.catalog.recipes
            .filter { category == nil || $0.category == category }
            .filter { !showOnlyCookable || store.canCook($0) }
            .sorted {
                if $0.unlockLevel == $1.unlockLevel {
                    return $0.name < $1.name
                }
                return $0.unlockLevel < $1.unlockLevel
            }
    }
    private var pantry: [(item: ItemDefinition, count: Int)] {
        store.inventoryItems.filter { $0.item.kind == .dish }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                TownScreenHeader(
                    title: "Cottage Kitchen",
                    subtitle: "A warm stove, a well-thumbed recipe book, and a pantry full of possibilities.",
                    icon: "fork.knife",
                    accent: HHTheme.terracotta
                )

                kitchenScene
                buffCard
                recipeBrowser
                pantrySection
                kitchenTips
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(HHTheme.cream)
        .navigationTitle("Cottage Kitchen")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        #endif
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailSheet(recipe: recipe)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Scene

    private var kitchenScene: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                KitchenStoveScene(
                    accent: HHTheme.terracotta,
                    hasBuff: store.currentFoodBuff != nil
                )
                .frame(height: 175)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("The Hollow kitchen")
                            .font(.hhHeadline(17))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.22), radius: 3)
                        Text(store.currentFoodBuff == nil
                            ? "Something is always simmering."
                            : "\(store.currentFoodBuff?.name ?? "A meal") is still warm.")
                            .font(.hhCaption(10.5))
                            .foregroundStyle(.white.opacity(0.86))
                    }
                    Spacer(minLength: 4)
                    TagChip("\(store.uniqueRecipesCooked)/\(store.catalog.recipes.count) recipes", icon: "book.pages.fill", tint: .white)
                        .background(.black.opacity(0.18), in: Capsule())
                }
                .padding(13)
            }

            HStack(spacing: 0) {
                kitchenStat("\(store.dishesCookedCount)", "Cooked", "fork.knife", HHTheme.terracotta)
                Divider().frame(height: 26).overlay(HHTheme.ink.opacity(0.08))
                kitchenStat("\(state.activities.dishesEaten)", "Enjoyed", "heart.fill", HHTheme.rose)
                Divider().frame(height: 26).overlay(HHTheme.ink.opacity(0.08))
                kitchenStat("\(store.uniqueRecipesCooked)", "Discovered", "book.pages.fill", HHTheme.goldDeep)
            }
            .padding(.vertical, 9)
            .background(HHTheme.paper)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: HHTheme.soilDark.opacity(0.15), radius: 15, y: 7)
    }

    private func kitchenStat(_ value: String, _ label: String, _ icon: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
            }
            Text(label)
                .font(.hhCaption(9))
                .foregroundStyle(HHTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Buff

    @ViewBuilder
    private var buffCard: some View {
        if let buff = store.currentFoodBuff {
            CozyCard {
                VStack(spacing: 9) {
                    HStack(spacing: 9) {
                        Text(buff.emoji)
                            .font(.system(size: 24))
                            .frame(width: 43, height: 43)
                            .background(Color(hex: buff.kind.tintHex).opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(buff.name)
                                .font(.hhHeadline(14))
                                .foregroundStyle(HHTheme.ink)
                            Text("\(buff.kind.title) · +\(buff.percent)% · \(buff.kind.summary)")
                                .font(.hhCaption(10.5))
                                .foregroundStyle(HHTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 2)
                        Text(timeRemaining(buff))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: buff.kind.tintHex))
                            .monospacedDigit()
                    }
                    CozyProgressBar(
                        value: buff.secondsRemaining(at: Date()) / max(1, recipeBuffDuration(for: buff)),
                        tint: Color(hex: buff.kind.tintHex),
                        height: 5
                    )
                }
            }
        } else {
            NoticeBanner(
                icon: "sparkles",
                title: "No meal buff right now",
                message: "Cook a dish, then enjoy it from the pantry. Each recipe gives the farm a little boost.",
                tint: HHTheme.goldDeep
            )
        }
    }

    private func recipeBuffDuration(for buff: FoodBuff) -> Double {
        store.catalog.recipeForDish(ingredientDishID(buff.name))?.buff.duration ?? 600
    }

    private func ingredientDishID(_ name: String) -> String {
        store.catalog.recipes.first { $0.name == name }?.dishItemID ?? ""
    }

    private func timeRemaining(_ buff: FoodBuff) -> String {
        let seconds = max(0, Int(buff.secondsRemaining(at: Date())))
        if seconds >= 60 { return "\(seconds / 60)m left" }
        return "\(seconds)s left"
    }

    // MARK: Recipes

    private var recipeBrowser: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionHeader(
                    "Recipe book",
                    subtitle: "Cook with what you grow. Meals keep, sell, and grant buffs.",
                    icon: "book.pages.fill"
                )
                Spacer(minLength: 4)
                Text("\(recipes.count)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.terracotta)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HHTheme.terracotta.opacity(0.09), in: Capsule())
            }

            CozySegmentedPicker(
                items: ([nil] as [RecipeCategory?]) + RecipeCategory.allCases.map(Optional.some),
                selection: $category,
                tint: HHTheme.terracotta,
                icon: { $0?.icon ?? "square.grid.2x2.fill" },
                title: { $0?.title ?? "All" }
            )

            HStack {
                Toggle(isOn: $showOnlyCookable) {
                    Text("Only what I can cook now")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                }
                .toggleStyle(.switch)
                .tint(HHTheme.forest)
                Spacer(minLength: 4)
                Button {
                    store.cookAllPossible()
                } label: {
                    Text("Cook all possible")
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
            }

            if let last = lastCookedID, showCookedBanner,
               let recipe = store.catalog.recipe(last) {
                HStack(spacing: 8) {
                    if let sprite = SpriteLibrary.sprite(named: recipe.spriteKey) {
                        PixelSpriteView(sprite)
                            .frame(width: 38, height: 34)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(recipe.name) is ready")
                            .font(.hhHeadline(12))
                            .foregroundStyle(HHTheme.ink)
                        Text("Find it in the pantry below.")
                            .font(.hhCaption(9.5))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showCookedBanner = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(9)
                .background(HHTheme.leaf.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if recipes.isEmpty {
                TownEmptyCard(
                    icon: "fork.knife",
                    title: "Nothing on this page",
                    message: "Try another category, or turn off the cookable-only filter.",
                    accent: HHTheme.terracotta
                )
            } else {
                LazyVStack(spacing: 9) {
                    ForEach(recipes) { recipe in
                        recipeCard(recipe)
                    }
                }
            }
        }
    }

    private func recipeCard(_ recipe: RecipeDefinition) -> some View {
        let unlocked = state.level >= recipe.unlockLevel
        let cookable = store.canCook(recipe)
        let cooked = store.cookedCount(recipeID: recipe.id)
        let buffTint = Color(hex: recipe.buff.kind.tintHex)

        return CozyCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top, spacing: 9) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(buffTint.opacity(0.09))
                        if let sprite = SpriteLibrary.sprite(named: recipe.spriteKey) {
                            PixelSpriteView(sprite)
                                .frame(width: 52, height: 45)
                                .opacity(unlocked ? 1 : 0.35)
                        } else {
                            Text(recipe.emoji)
                                .font(.system(size: 26))
                        }
                    }
                    .frame(width: 58, height: 52)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(recipe.name)
                                .font(.hhHeadline(14))
                                .foregroundStyle(HHTheme.ink)
                            if cooked > 0 {
                                Text("×\(cooked)")
                                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(HHTheme.forest)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(HHTheme.forest.opacity(0.09), in: Capsule())
                            }
                        }
                        Text(recipe.blurb)
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 5) {
                            TagChip(recipe.category.title, icon: recipe.category.icon, tint: Color(hex: recipe.category.tintHex))
                            TagChip("+\(recipe.buff.percent)% \(recipe.buff.kind.title)", icon: recipe.buff.kind.icon, tint: buffTint)
                            TagChip("\(recipe.xp) XP", icon: "sparkles", tint: HHTheme.forest)
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 5) {
                    ForEach(Array(recipe.ingredients.keys.sorted().prefix(4)), id: \.self) { itemID in
                        if let item = store.catalog.item(itemID) {
                            IngredientChip(
                                itemID: itemID,
                                needed: recipe.ingredients[itemID] ?? 0,
                                owned: store.itemCount(itemID),
                                name: item.name,
                                spriteKey: item.spriteKey,
                                emoji: item.emoji
                            )
                        }
                    }
                    if recipe.ingredients.count > 4 {
                        Text("+\(recipe.ingredients.count - 4)")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    if unlocked {
                        Button {
                            store.cook(recipeID: recipe.id)
                            lastCookedID = recipe.id
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showCookedBanner = true
                            }
                        } label: {
                            Label(cookable ? "Cook" : "Missing ingredients", systemImage: "flame.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CozyPrimaryButtonStyle())
                        .disabled(!cookable)
                        .opacity(cookable ? 1 : 0.45)
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "lock.fill")
                            Text("Unlocks at level \(recipe.unlockLevel)")
                        }
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(HHTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        selectedRecipe = recipe
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HHTheme.terracotta)
                            .frame(width: 36, height: 34)
                            .background(HHTheme.terracotta.opacity(0.09), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Pantry

    @ViewBuilder
    private var pantrySection: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(
                        "The pantry",
                        subtitle: "Dishes keep until you eat or sell them.",
                        icon: "cabinet.fill"
                    )
                    Spacer(minLength: 4)
                    Text("\(pantry.reduce(0) { $0 + $1.count })")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.terracotta)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HHTheme.terracotta.opacity(0.09), in: Capsule())
                }

                if pantry.isEmpty {
                    TownEmptyCard(
                        icon: "fork.knife",
                        title: "The pantry is quiet",
                        message: "Cook something from the recipe book and it will appear here.",
                        accent: HHTheme.terracotta
                    )
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 145, maximum: 240), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(pantry, id: \.item.id) { entry in
                            pantryTile(entry.item, count: entry.count)
                        }
                    }
                }
            }
        }
    }

    private func pantryTile(_ item: ItemDefinition, count: Int) -> some View {
        let recipe = store.catalog.recipeForDish(item.id)
        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                ItemIconView(spriteKey: item.spriteKey, emoji: item.emoji, size: 36)
                    .padding(4)
                    .background(HHTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.hhHeadline(11))
                        .foregroundStyle(HHTheme.ink)
                        .lineLimit(1)
                    Text("×\(count)")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 0)
            }
            if let recipe {
                Text("+\(recipe.buff.percent)% \(recipe.buff.kind.title) · \(recipe.buff.durationText)")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: recipe.buff.kind.tintHex))
                    .lineLimit(1)
            }
            HStack(spacing: 4) {
                Button {
                    store.eatDish(itemID: item.id)
                } label: {
                    Text("Enjoy")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(HHTheme.forest, in: Capsule())
                }
                .buttonStyle(.plain)
                Button {
                    store.sell(itemID: item.id)
                } label: {
                    Text("\(store.sellPrice(for: item.id))c")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.goldDeep)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(HHTheme.gold.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
        }
        .padding(8)
        .background(HHTheme.cream.opacity(0.5), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(HHTheme.terracotta.opacity(0.09), lineWidth: 1)
        )
    }

    // MARK: Tips

    private var kitchenTips: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "Kitchen notes",
                subtitle: "The pantry, the buffs, and the little rituals of a farm kitchen.",
                icon: "lightbulb.fill"
            )
            tipRow("🥘", "Eating a dish replaces the current buff. Save the big feast for a busy day.")
            tipRow("🕰️", "Buffs run on real time, even while the game is closed.")
            tipRow("🍽️", "Dishes can be sold at market, but eating them usually pays back more.")
            tipRow("🌙", "The sturgeon feast needs a legendary fish. The pond keeper would be impressed.")
        }
    }

    private func tipRow(_ emoji: String, _ text: String) -> some View {
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

// MARK: - Stove scene

public struct KitchenStoveScene: View {
    public let accent: Color
    public let hasBuff: Bool

    public init(accent: Color = HHTheme.terracotta, hasBuff: Bool = false) {
        self.accent = accent
        self.hasBuff = hasBuff
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 18.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let background = CGRect(origin: .zero, size: size)
                context.fill(Path(background), with: .linearGradient(
                    Gradient(colors: [Color(hex: "F4D7B8"), Color(hex: "C98B5E")]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                ))

                let wall = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.6)
                context.fill(Path(wall), with: .color(Color(hex: "F7E9D2").opacity(0.45)))

                for index in 0..<8 {
                    let x = size.width * (0.08 + Double(index) * 0.12)
                    let h = size.height * (0.18 + (Double(index % 3) * 0.05))
                    let tile = CGRect(x: x, y: size.height * 0.08, width: size.width * 0.07, height: h)
                    context.fill(Path(roundedRect: tile, cornerRadius: 2), with: .color(.white.opacity(0.16)))
                }

                let counter = CGRect(
                    x: size.width * 0.06,
                    y: size.height * 0.62,
                    width: size.width * 0.88,
                    height: size.height * 0.2
                )
                context.fill(Path(roundedRect: counter, cornerRadius: 4), with: .color(Color(hex: "8A5A3A")))
                context.fill(
                    Path(roundedRect: counter.insetBy(dx: 0, dy: 4), cornerRadius: 3),
                    with: .color(Color(hex: "B57A47"))
                )

                let stove = CGRect(
                    x: size.width * 0.36,
                    y: size.height * 0.58,
                    width: size.width * 0.28,
                    height: size.height * 0.3
                )
                context.fill(Path(roundedRect: stove, cornerRadius: 5), with: .color(Color(hex: "3E3A38")))
                context.fill(
                    Path(roundedRect: stove.insetBy(dx: 5, dy: 5), cornerRadius: 4),
                    with: .color(Color(hex: "5A524D"))
                )

                let fire = CGRect(
                    x: stove.midX - stove.width * 0.14,
                    y: stove.midY - stove.height * 0.04,
                    width: stove.width * 0.28,
                    height: stove.height * 0.16
                )
                context.fill(Path(ellipseIn: fire), with: .color(accent.opacity(0.9)))
                context.fill(Path(ellipseIn: fire.insetBy(dx: 3, dy: 2)), with: .color(Color(hex: "F5C542")))

                let potWidth = stove.width * 0.52
                let pot = CGRect(
                    x: stove.midX - potWidth / 2,
                    y: stove.minY - potWidth * 0.32,
                    width: potWidth,
                    height: potWidth * 0.34
                )
                context.fill(Path(roundedRect: pot, cornerRadius: 5), with: .color(Color(hex: "4F5A5E")))
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: pot.minX - 2,
                        y: pot.minY - 3,
                        width: pot.width + 4,
                        height: pot.height * 0.35
                    )),
                    with: .color(Color(hex: "6E7A7E"))
                )

                if hasBuff {
                    for index in 0..<5 {
                        let seed = Double(index)
                        let x = pot.midX + sin(time * 0.8 + seed) * 9
                        let y = pot.minY - 5 - ((time * 16 + seed * 12).truncatingRemainder(dividingBy: 44))
                        let radius = 3 + (seed * 1.2)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                            with: .color(.white.opacity(0.28))
                        )
                    }
                }

                let shelf = CGRect(
                    x: size.width * 0.08,
                    y: size.height * 0.23,
                    width: size.width * 0.24,
                    height: 4
                )
                context.fill(Path(roundedRect: shelf, cornerRadius: 2), with: .color(Color(hex: "8A5A3A")))
                for index in 0..<4 {
                    let jar = CGRect(
                        x: shelf.minX + CGFloat(index) * 15 + 5,
                        y: shelf.minY - 16,
                        width: 9,
                        height: 14
                    )
                    context.fill(Path(roundedRect: jar, cornerRadius: 2), with: .color([
                        Color(hex: "E8C15A"), Color(hex: "E8754A"), Color(hex: "8E6BC4"), Color(hex: "7DBF5B")
                    ][index].opacity(0.75)))
                }

                let window = CGRect(
                    x: size.width * 0.7,
                    y: size.height * 0.16,
                    width: size.width * 0.2,
                    height: size.height * 0.25
                )
                context.fill(Path(roundedRect: window, cornerRadius: 4), with: .color(Color(hex: "BFE3EE")))
                context.stroke(Path(roundedRect: window, cornerRadius: 4), with: .color(Color(hex: "8A5A3A")), lineWidth: 3)
                var cross = Path()
                cross.move(to: CGPoint(x: window.midX, y: window.minY))
                cross.addLine(to: CGPoint(x: window.midX, y: window.maxY))
                cross.move(to: CGPoint(x: window.minX, y: window.midY))
                cross.addLine(to: CGPoint(x: window.maxX, y: window.midY))
                context.stroke(cross, with: .color(Color(hex: "8A5A3A")), lineWidth: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Recipe detail

public struct RecipeDetailSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    public let recipe: RecipeDefinition

    public init(recipe: RecipeDefinition) {
        self.recipe = recipe
    }

    private var unlocked: Bool { store.state.level >= recipe.unlockLevel }
    private var cookable: Bool { store.canCook(recipe) }
    private var cooked: Int { store.cookedCount(recipeID: recipe.id) }

    public var body: some View {
        ScrollView {
            VStack(spacing: 13) {
                HStack {
                    TagChip(recipe.category.title, icon: recipe.category.icon, tint: Color(hex: recipe.category.tintHex))
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

                if let sprite = SpriteLibrary.sprite(named: recipe.spriteKey) {
                    PixelSpriteView(sprite)
                        .frame(width: 160, height: 128)
                        .opacity(unlocked ? 1 : 0.35)
                } else {
                    Text(recipe.emoji)
                        .font(.system(size: 64))
                }

                VStack(spacing: 3) {
                    Text(recipe.name)
                        .font(.hhTitle(24))
                        .foregroundStyle(HHTheme.ink)
                    Text(recipe.blurb)
                        .font(.hhBody(12.5))
                        .foregroundStyle(HHTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 7) {
                    TagChip("Level \(recipe.unlockLevel)", icon: "lock.open.fill", tint: unlocked ? HHTheme.forest : HHTheme.terracotta)
                    TagChip("+\(recipe.xp) XP", icon: "sparkles", tint: HHTheme.goldDeep)
                    TagChip("×\(cooked) cooked", icon: "flame.fill", tint: HHTheme.terracotta)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    ForEach(Array(recipe.ingredients.keys.sorted()), id: \.self) { itemID in
                        if let item = store.catalog.item(itemID) {
                            HStack(spacing: 8) {
                                ItemIconView(spriteKey: item.spriteKey, emoji: item.emoji, size: 30)
                                Text(item.name)
                                    .font(.hhBody(12.5))
                                    .foregroundStyle(HHTheme.ink)
                                Spacer()
                                Text("\(store.itemCount(itemID))/\(recipe.ingredients[itemID] ?? 0)")
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(store.itemCount(itemID) >= (recipe.ingredients[itemID] ?? 0) ? HHTheme.forest : HHTheme.terracotta)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(13)
                .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    Text("Meal effect")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    HStack(spacing: 8) {
                        Image(systemName: recipe.buff.kind.icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: recipe.buff.kind.tintHex))
                            .frame(width: 34, height: 34)
                            .background(Color(hex: recipe.buff.kind.tintHex).opacity(0.1), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("+\(recipe.buff.percent)% \(recipe.buff.kind.title)")
                                .font(.hhHeadline(12.5))
                                .foregroundStyle(HHTheme.ink)
                            Text("\(recipe.buff.kind.summary) Lasts \(recipe.buff.durationText).")
                                .font(.hhCaption(10.5))
                                .foregroundStyle(HHTheme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(13)
                .background(Color(hex: recipe.buff.kind.tintHex).opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    store.cook(recipeID: recipe.id)
                    dismiss()
                } label: {
                    Label(cookable ? "Cook \(recipe.name)" : (unlocked ? "Missing ingredients" : "Unlocks at level \(recipe.unlockLevel)"), systemImage: "flame.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())
                .disabled(!cookable)
                .opacity(cookable ? 1 : 0.45)
            }
            .padding(17)
        }
        .background(HHTheme.cream)
    }
}
#endif
