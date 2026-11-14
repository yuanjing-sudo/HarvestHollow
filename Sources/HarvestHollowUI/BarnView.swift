#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Barn

public struct BarnView: View {
    @EnvironmentObject private var store: GameStore
    @State private var pendingPen: Pen?
    @State private var renamePen: Pen?

    private var state: GameState { store.state }
    private var animals: [AnimalInstance] { state.pens.compactMap(\.animal) }
    private var storedGoods: Int { animals.reduce(0) { $0 + $1.stored } }
    private var feedCount: Int { store.itemCount("supply.feed") }
    private var adoptBinding: Binding<Bool> {
        Binding(
            get: { store.adoptPenID != nil },
            set: { if !$0 { store.adoptPenID = nil } }
        )
    }
    private var purchaseBinding: Binding<Bool> {
        Binding(
            get: { pendingPen != nil },
            set: { if !$0 { pendingPen = nil } }
        )
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                barnSummary
                quickActions
                pensGrid
                barnTip
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: adoptBinding) {
            if let penID = store.adoptPenID {
                AdoptSheet(penID: penID)
                    .environmentObject(store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $renamePen) { pen in
            RenameAnimalSheet(penID: pen.id, currentName: pen.animal?.name ?? "")
                .environmentObject(store)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Open this pen?",
            isPresented: purchaseBinding,
            titleVisibility: .visible,
            presenting: pendingPen
        ) { pen in
            Button("Open for \(store.penPrice()) coins") {
                store.buyPen(pen.id)
                pendingPen = nil
            }
            Button("Not yet", role: .cancel) {
                pendingPen = nil
            }
        } message: { pen in
            Text("Pen \(pen.id + 1) needs level \(store.penUnlockLevel(pen.id)). You have \(state.coins) coins.")
        }
    }

    // MARK: Summary

    private var barnSummary: some View {
        CozyCard {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("🐾")
                        .font(.system(size: 27))
                        .frame(width: 50, height: 50)
                        .background(HHTheme.leaf.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("The barn")
                            .font(.hhHeadline(18))
                            .foregroundStyle(HHTheme.ink)
                        Text("Feed your friends, then collect what they leave behind. Happy animals work a little faster.")
                            .font(.hhBody(12.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 9) {
                    StatTile(
                        title: "Animals",
                        value: "\(animals.count)/\(state.unlockedPens)",
                        icon: "pawprint.fill",
                        tint: HHTheme.forest
                    )
                    StatTile(
                        title: "Goods ready",
                        value: "\(storedGoods)",
                        icon: "shippingbox.fill",
                        tint: HHTheme.goldDeep
                    )
                    StatTile(
                        title: "Feed bags",
                        value: "\(feedCount)",
                        icon: "leaf.fill",
                        tint: HHTheme.terracotta
                    )
                }
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 9) {
            FarmQuickAction(title: "Feed all", icon: "leaf.fill", tint: HHTheme.forest) {
                store.feedAll()
            }
            FarmQuickAction(title: "Collect all", icon: "shippingbox.fill", tint: HHTheme.goldDeep) {
                store.collectAll()
            }
            FarmQuickAction(title: "Get feed", icon: "cart.fill", tint: HHTheme.terracotta) {
                store.buySupply("supply.feed", quantity: 1)
            }
        }
    }

    // MARK: Pens

    private var pensGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                "Pens",
                subtitle: "Tap an empty pen to meet a new friend.",
                icon: "house.lodge.fill"
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 250, maximum: 410), spacing: 12)],
                spacing: 12
            ) {
                ForEach(state.pens) { pen in
                    PenCard(pen: pen) {
                        if !pen.unlocked {
                            pendingPen = pen
                        } else if pen.animal == nil {
                            store.adoptPenID = pen.id
                        }
                    } onRename: {
                        renamePen = pen
                    }
                    .contextMenu {
                        penMenu(pen)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func penMenu(_ pen: Pen) -> some View {
        if !pen.unlocked {
            Button {
                pendingPen = pen
            } label: {
                Label("Open pen", systemImage: "hammer.fill")
            }
        } else if let animal = pen.animal {
            Button {
                store.feed(penID: pen.id)
            } label: {
                Label("Feed \(animal.name)", systemImage: "leaf.fill")
            }
            if animal.stored > 0 {
                Button {
                    store.collect(penID: pen.id)
                } label: {
                    Label("Collect", systemImage: "shippingbox.fill")
                }
            }
            Button {
                renamePen = pen
            } label: {
                Label("Rename", systemImage: "pencil")
            }
        } else {
            Button {
                store.adoptPenID = pen.id
            } label: {
                Label("Adopt an animal", systemImage: "plus")
            }
        }
    }

    private var barnTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🥛")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 3) {
                Text("Barn notes")
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                Text("One bag of feed keeps an animal producing for two cycles. Goods wait safely in the pen until you collect them, and new animals arrive with two free cycles.")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.terracotta.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.terracotta.opacity(0.16), lineWidth: 1)
        )
    }
}

// MARK: - Pen card

struct PenCard: View {
    @EnvironmentObject private var store: GameStore

    let pen: Pen
    let onTap: () -> Void
    let onRename: () -> Void

    @State private var bobbing = false

    init(pen: Pen, onTap: @escaping () -> Void, onRename: @escaping () -> Void) {
        self.pen = pen
        self.onTap = onTap
        self.onRename = onRename
    }

    private var species: AnimalSpecies? {
        guard let animal = pen.animal else { return nil }
        return store.catalog.animal(animal.speciesID)
    }

    private var product: ItemDefinition? {
        guard let species else { return nil }
        return store.catalog.item(species.productItemID)
    }

    var body: some View {
        Group {
            if !pen.unlocked {
                lockedCard
            } else if let animal = pen.animal, let species {
                animalCard(animal: animal, species: species)
            } else {
                emptyCard
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(HHTheme.paper.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    pen.animal != nil ? HHTheme.forest.opacity(0.14) : HHTheme.ink.opacity(0.07),
                    lineWidth: 1
                )
        )
        .shadow(color: HHTheme.soilDark.opacity(0.1), radius: 10, y: 5)
    }

    // MARK: Locked

    private var lockedCard: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "A9B98D"), Color(hex: "7F9366")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pen \(pen.id + 1) · overgrown")
                        .font(.hhHeadline(15))
                        .foregroundStyle(HHTheme.ink)
                    Text("Level \(store.penUnlockLevel(pen.id)) · \(store.penPrice()) coins to open")
                        .font(.hhCaption(11.5))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HHTheme.muted)
            }
            .padding(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: Empty

    private var emptyCard: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(HHTheme.leaf.opacity(0.12))
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(HHTheme.forest)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("A quiet pen")
                        .font(.hhHeadline(15))
                        .foregroundStyle(HHTheme.ink)
                    Text("Adopt a chicken, duck, cow, sheep, pig, goat or bee.")
                        .font(.hhCaption(11.5))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text("Adopt")
                    .font(.hhHeadline(12))
                    .foregroundStyle(HHTheme.forest)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(HHTheme.forest.opacity(0.1), in: Capsule())
            }
            .padding(15)
        }
        .buttonStyle(.plain)
    }

    // MARK: Animal

    private func animalCard(animal: AnimalInstance, species: AnimalSpecies) -> some View {
        VStack(spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                AnimalSpriteView(speciesID: species.id, size: 88)
                    .offset(y: bobbing ? -1.5 : 1.5)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: bobbing
                    )
                    .onAppear { bobbing = true }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(animal.name)
                            .font(.hhHeadline(17))
                            .foregroundStyle(HHTheme.ink)
                            .lineLimit(1)
                        Button(action: onRename) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(HHTheme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(species.name)
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)

                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(HHTheme.rose)
                        CozyProgressBar(
                            value: max(0, min(1, animal.happiness / 100)),
                            tint: HHTheme.rose,
                            height: 5
                        )
                        Text("\(Int(animal.happiness))")
                            .font(.hhCaption(9.5))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .frame(maxWidth: 150)

                    fedBadge(animal: animal, species: species)
                }

                Spacer(minLength: 2)

                if let product {
                    VStack(spacing: 3) {
                        ItemIconView(
                            spriteKey: product.spriteKey,
                            emoji: product.emoji,
                            size: 28
                        )
                        Text("\(animal.stored)/\(species.capacity)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(animal.stored > 0 ? HHTheme.goldDeep : HHTheme.muted)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(animal.stored > 0 ? HHTheme.gold.opacity(0.18) : HHTheme.paperDeep)
                    )
                }
            }

            if let product {
                HStack(spacing: 7) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(HHTheme.muted)
                    Text(productionText(animal: animal, species: species, product: product))
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                    Spacer(minLength: 0)
                    if animal.stored > 0 {
                        Button {
                            store.collect(penID: pen.id)
                        } label: {
                            Label("Collect \(animal.stored)", systemImage: "shippingbox.fill")
                        }
                        .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
                    }
                }

                CozyProgressBar(
                    value: productionProgress(animal: animal, species: species),
                    tint: HHTheme.leaf,
                    height: 5
                )
            }

            HStack(spacing: 8) {
                Button {
                    store.feed(penID: pen.id)
                } label: {
                    Label("Feed", systemImage: "leaf.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozySecondaryButtonStyle())
                .disabled(store.itemCount("supply.feed") == 0 || animal.isFed(at: Date()))
                .opacity(store.itemCount("supply.feed") == 0 || animal.isFed(at: Date()) ? 0.5 : 1)

                Button {
                    store.collect(penID: pen.id)
                } label: {
                    Label("Collect", systemImage: "basket.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())
                .disabled(animal.stored == 0)
                .opacity(animal.stored == 0 ? 0.45 : 1)
            }
        }
        .padding(14)
    }

    private func fedBadge(animal: AnimalInstance, species: AnimalSpecies) -> some View {
        let remaining = animal.fedSecondsRemaining(at: Date())
        return HStack(spacing: 4) {
            Image(systemName: remaining > 0 ? "leaf.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 9, weight: .bold))
            Text(remaining > 0 ? "Fed · \(timeText(remaining))" : "Hungry")
                .font(.hhCaption(9.5))
        }
        .foregroundStyle(remaining > 0 ? HHTheme.forest : HHTheme.terracotta)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            (remaining > 0 ? HHTheme.forest : HHTheme.terracotta).opacity(0.1),
            in: Capsule()
        )
    }

    private func timeText(_ seconds: Double) -> String {
        if seconds >= 60 {
            return "\(Int(seconds / 60))m \(Int(seconds.truncatingRemainder(dividingBy: 60)))s"
        }
        return "\(max(1, Int(seconds)))s"
    }

    private func productionText(
        animal: AnimalInstance,
        species: AnimalSpecies,
        product: ItemDefinition
    ) -> String {
        if animal.stored >= species.capacity {
            return "The pen is full of \(product.name.lowercased())"
        }
        if !animal.isFed(at: Date()) {
            return "Feed to start producing \(product.name.lowercased())"
        }
        return "Produces \(product.name.lowercased()) every ~\(Int(species.produceSeconds))s"
    }

    private func productionProgress(animal: AnimalInstance, species: AnimalSpecies) -> Double {
        let interval = max(5, species.produceSeconds / (0.75 + max(20, animal.happiness) / 400))
        return min(1, max(0, animal.progress / interval))
    }
}

// MARK: - Adopt sheet

public struct AdoptSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    public let penID: Int

    public init(penID: Int) {
        self.penID = penID
    }

    private var speciesList: [AnimalSpecies] {
        store.catalog.animals.sorted {
            if $0.unlockLevel == $1.unlockLevel { return $0.price < $1.price }
            return $0.unlockLevel < $1.unlockLevel
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Choose a barn friend")
                            .font(.hhTitle(24))
                            .foregroundStyle(HHTheme.ink)
                        Text("Pen \(penID + 1) · every animal comes with two free feed cycles.")
                            .font(.hhBody(12.5))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 8)
                    CoinPill(store.state.coins)
                }

                ForEach(speciesList) { species in
                    adoptRow(species)
                }
            }
            .padding(18)
        }
        .background(HHTheme.cream)
    }

    private func adoptRow(_ species: AnimalSpecies) -> some View {
        let product = store.catalog.item(species.productItemID)
        let leveled = store.state.level >= species.unlockLevel
        let affordable = store.state.coins >= species.price

        return HStack(alignment: .top, spacing: 12) {
            AnimalSpriteView(speciesID: species.id, size: 74)
                .frame(width: 78)
                .opacity(leveled ? 1 : 0.4)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(species.name)
                        .font(.hhHeadline(16))
                        .foregroundStyle(HHTheme.ink)
                    if !leveled {
                        Text("Lv \(species.unlockLevel)")
                            .font(.hhCaption(9.5))
                            .foregroundStyle(HHTheme.terracotta)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HHTheme.terracotta.opacity(0.1), in: Capsule())
                    }
                }

                Text(species.blurb)
                    .font(.hhBody(11.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    if let product {
                        TagChip(
                            "\(product.name) every ~\(Int(species.produceSeconds))s",
                            icon: "clock.fill",
                            tint: HHTheme.forest
                        )
                    }
                    TagChip("Capacity \(species.capacity)", icon: "shippingbox.fill", tint: HHTheme.goldDeep)
                }
            }

            Spacer(minLength: 4)

            VStack(spacing: 5) {
                CoinPill(species.price, compact: true)
                Button {
                    store.adoptAnimal(speciesID: species.id, penID: penID)
                    if store.state.pens.first(where: { $0.id == penID })?.animal != nil {
                        dismiss()
                    }
                } label: {
                    Text(leveled ? (affordable ? "Adopt" : "Need \(species.price - store.state.coins)c") : "Level \(species.unlockLevel)")
                        .font(.hhHeadline(11.5))
                }
                .buttonStyle(MiniActionStyle(tint: leveled && affordable ? HHTheme.forest : HHTheme.muted))
                .disabled(!leveled || !affordable)
                .opacity(leveled && affordable ? 1 : 0.55)
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(HHTheme.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Rename sheet

public struct RenameAnimalSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    public let penID: Int
    public let currentName: String

    @State private var name: String

    public init(penID: Int, currentName: String) {
        self.penID = penID
        self.currentName = currentName
        _name = State(initialValue: currentName)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rename your friend")
                .font(.hhTitle(22))
                .foregroundStyle(HHTheme.ink)
            Text("A good name makes the barn feel like home.")
                .font(.hhBody(13))
                .foregroundStyle(HHTheme.muted)

            TextField("Name", text: $name)
                .textFieldStyle(.plain)
                .font(.hhHeadline(16))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(HHTheme.paper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(HHTheme.ink.opacity(0.12), lineWidth: 1)
                )

            HStack(spacing: 9) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(CozySecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button("Save name") {
                    store.renameAnimal(penID: penID, to: name)
                    dismiss()
                }
                .buttonStyle(CozyPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(HHTheme.cream)
    }
}
#endif
