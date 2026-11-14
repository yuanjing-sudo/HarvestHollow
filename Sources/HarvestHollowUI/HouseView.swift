#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - House

public struct HouseView: View {
    @EnvironmentObject private var store: GameStore

    @State private var selectedItemID: String?
    @State private var selectedPlacedID: UUID?

    private var state: GameState { store.state }
    private var theme: HouseTheme { store.currentTheme }
    private var ownedThemes: [HouseTheme] {
        store.catalog.themes.filter { state.themesOwned.contains($0.id) }
    }
    private var selectedPlaced: PlacedFurniture? {
        guard let selectedPlacedID else { return nil }
        return store.placedFurniture.first { $0.id == selectedPlacedID }
    }
    private var selectedInventoryItem: (item: ItemDefinition, count: Int)? {
        guard let selectedItemID else { return nil }
        return store.furnitureInventory.first { $0.item.id == selectedItemID }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                houseHeader
                themeStrip
                houseCanvas
                placementControls
                furnitureShelf
                houseTip
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .animation(.easeInOut(duration: 0.2), value: selectedPlacedID)
        .animation(.easeInOut(duration: 0.2), value: selectedItemID)
    }

    // MARK: Header

    private var houseHeader: some View {
        CozyCard {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("🏡")
                        .font(.system(size: 28))
                        .frame(width: 50, height: 50)
                        .background(HHTheme.rose.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("The farmhouse")
                            .font(.hhHeadline(18))
                            .foregroundStyle(HHTheme.ink)
                        Text("A cozy home is good for the soul — and for market prices. Every comfort point adds a little bonus.")
                            .font(.hhBody(12.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 9) {
                    StatTile(title: "Comfort", value: "\(store.comfort)", icon: "heart.fill", tint: HHTheme.rose)
                    StatTile(title: "Sale bonus", value: "+\(store.comfortBonusPercent)%", icon: "tag.fill", tint: HHTheme.goldDeep)
                    StatTile(title: "Pieces", value: "\(store.placedFurniture.count)", icon: "sofa.fill", tint: HHTheme.forest)
                }

                HStack(spacing: 8) {
                    Button {
                        store.openTown(.kitchen)
                    } label: {
                        Label("Open the kitchen", systemImage: "fork.knife")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozySecondaryButtonStyle())

                    if let buff = store.currentFoodBuff {
                        TagChip(buff.name, icon: buff.kind.icon, tint: Color(hex: buff.kind.tintHex))
                    } else {
                        TagChip("Pantry quiet", icon: "cabinet.fill", tint: HHTheme.muted)
                    }
                }
            }
        }
    }

    // MARK: Themes

    private var themeStrip: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionHeader(
                    "Room theme",
                    subtitle: "Owned themes can be applied any time.",
                    icon: "paintbrush.fill"
                )
                Spacer(minLength: 6)
                Button {
                    store.selectedTab = .market
                } label: {
                    Label("More themes", systemImage: "cart.fill")
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(ownedThemes) { ownedTheme in
                        themeChip(ownedTheme)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func themeChip(_ ownedTheme: HouseTheme) -> some View {
        let applied = state.house.themeID == ownedTheme.id
        return Button {
            store.applyTheme(ownedTheme.id)
        } label: {
            HStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(hex: ownedTheme.wallHex))
                    VStack(spacing: 0) {
                        Spacer()
                        Color(hex: ownedTheme.floorHex)
                            .frame(height: 11)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Circle()
                        .fill(Color(hex: ownedTheme.accentHex))
                        .frame(width: 7, height: 7)
                }
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.white.opacity(0.6), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(ownedTheme.name)
                        .font(.hhHeadline(12))
                        .foregroundStyle(HHTheme.ink)
                    Text(applied ? "Applied" : "Tap to apply")
                        .font(.hhCaption(9.5))
                        .foregroundStyle(applied ? HHTheme.forest : HHTheme.muted)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(applied ? HHTheme.forest.opacity(0.1) : HHTheme.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(applied ? HHTheme.forest.opacity(0.45) : HHTheme.ink.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Room

    private var houseCanvas: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionHeader(
                    "Living room",
                    subtitle: "Tap the floor to place a selected piece. Drag furniture to nudge it.",
                    icon: "square.grid.3x3.fill"
                )
                Spacer(minLength: 6)
                TagChip("\(GameConstants.houseWidth)×\(GameConstants.houseHeight)", icon: "grid", tint: HHTheme.muted)
            }

            GeometryReader { geometry in
                let cell = geometry.size.width / CGFloat(GameConstants.houseWidth)
                let roomHeight = cell * CGFloat(GameConstants.houseHeight)

                ZStack(alignment: .topLeading) {
                    Color(hex: theme.wallHex)

                    Canvas { context, size in
                        for y in 0..<GameConstants.houseHeight {
                            for x in 0..<GameConstants.houseWidth {
                                let rect = CGRect(
                                    x: CGFloat(x) * cell,
                                    y: CGFloat(y) * cell,
                                    width: cell + 0.5,
                                    height: cell + 0.5
                                )
                                context.fill(
                                    Path(rect),
                                    with: .color(Color(hex: theme.floorHex).opacity((x + y).isMultiple(of: 2) ? 0.94 : 0.78))
                                )
                                if (x + y).isMultiple(of: 2) {
                                    context.fill(
                                        Path(rect),
                                        with: .color(.white.opacity(0.06))
                                    )
                                }
                            }
                        }

                        var gridPath = Path()
                        for x in 0...GameConstants.houseWidth {
                            let px = CGFloat(x) * cell
                            gridPath.move(to: CGPoint(x: px, y: 0))
                            gridPath.addLine(to: CGPoint(x: px, y: roomHeight))
                        }
                        for y in 0...GameConstants.houseHeight {
                            let py = CGFloat(y) * cell
                            gridPath.move(to: CGPoint(x: 0, y: py))
                            gridPath.addLine(to: CGPoint(x: geometry.size.width, y: py))
                        }
                        context.stroke(gridPath, with: .color(.black.opacity(0.045)), lineWidth: 0.7)
                    }
                    .allowsHitTesting(false)

                    ForEach(0..<(GameConstants.houseWidth * GameConstants.houseHeight), id: \.self) { index in
                        let x = index % GameConstants.houseWidth
                        let y = index / GameConstants.houseWidth
                        Rectangle()
                            .fill(Color.white.opacity(0.001))
                            .frame(width: cell, height: cell)
                            .offset(x: CGFloat(x) * cell, y: CGFloat(y) * cell)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleTap(x: x, y: y)
                            }
                    }

                    ForEach(store.placedFurniture) { piece in
                        if let definition = store.placedDefinition(piece) {
                            placedPiece(piece, definition: definition, cell: cell)
                        }
                    }

                    if store.placedFurniture.isEmpty {
                        VStack(spacing: 5) {
                            Image(systemName: "sofa")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(HHTheme.ink.opacity(0.22))
                            Text("A blank canvas")
                                .font(.hhHeadline(13))
                                .foregroundStyle(HHTheme.ink.opacity(0.42))
                            Text("Pick a piece from the shelf below.")
                                .font(.hhCaption(10.5))
                                .foregroundStyle(HHTheme.ink.opacity(0.32))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                    }
                }
                .frame(width: geometry.size.width, height: roomHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: theme.wallHex), lineWidth: 7)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.black.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: HHTheme.soilDark.opacity(0.16), radius: 10, y: 5)
            }
            .aspectRatio(
                CGFloat(GameConstants.houseWidth) / CGFloat(GameConstants.houseHeight),
                contentMode: .fit
            )
        }
    }

    private func placedPiece(
        _ piece: PlacedFurniture,
        definition: FurnitureDefinition,
        cell: CGFloat
    ) -> some View {
        let isSelected = selectedPlacedID == piece.id
        let width = cell * CGFloat(definition.width)
        let height = cell * CGFloat(definition.height)
        let item = store.catalog.item(piece.itemID)

        return FurnitureSpriteView(itemID: piece.itemID, emoji: item?.emoji ?? "🪑")
            .padding(2)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isSelected ? HHTheme.gold.opacity(0.2) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isSelected ? HHTheme.goldDeep : .clear, lineWidth: 1.5)
            )
            .offset(x: CGFloat(piece.x) * cell, y: CGFloat(piece.y) * cell)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedPlacedID = isSelected ? nil : piece.id
                selectedItemID = nil
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onEnded { value in
                        let dx = Int((value.translation.width / cell).rounded())
                        let dy = Int((value.translation.height / cell).rounded())
                        guard dx != 0 || dy != 0 else { return }
                        store.nudgeFurniture(piece, dx: dx, dy: dy)
                        selectedPlacedID = piece.id
                        selectedItemID = nil
                    }
            )
            .contextMenu {
                Button {
                    store.nudgeFurniture(piece, dx: -1, dy: 0)
                } label: {
                    Label("Move left", systemImage: "arrow.left")
                }
                Button {
                    store.nudgeFurniture(piece, dx: 1, dy: 0)
                } label: {
                    Label("Move right", systemImage: "arrow.right")
                }
                Button {
                    store.nudgeFurniture(piece, dx: 0, dy: -1)
                } label: {
                    Label("Move up", systemImage: "arrow.up")
                }
                Button {
                    store.nudgeFurniture(piece, dx: 0, dy: 1)
                } label: {
                    Label("Move down", systemImage: "arrow.down")
                }
                Divider()
                Button {
                    store.removeFurniture(piece)
                    if selectedPlacedID == piece.id { selectedPlacedID = nil }
                } label: {
                    Label("Pick up", systemImage: "hand.raised.fill")
                }
            }
            .accessibilityLabel("\(definition.name) at column \(piece.x + 1), row \(piece.y + 1)")
    }

    // MARK: Controls

    private var placementControls: some View {
        Group {
            if let piece = selectedPlaced, let definition = store.placedDefinition(piece) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(definition.name)
                            .font(.hhHeadline(12.5))
                            .foregroundStyle(HHTheme.ink)
                        Text("Column \(piece.x + 1), row \(piece.y + 1)")
                            .font(.hhCaption(9.5))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 4)
                    nudgeButton("arrow.left") { store.nudgeFurniture(piece, dx: -1, dy: 0) }
                    nudgeButton("arrow.up") { store.nudgeFurniture(piece, dx: 0, dy: -1) }
                    nudgeButton("arrow.down") { store.nudgeFurniture(piece, dx: 0, dy: 1) }
                    nudgeButton("arrow.right") { store.nudgeFurniture(piece, dx: 1, dy: 0) }
                    Button {
                        store.removeFurniture(piece)
                        selectedPlacedID = nil
                    } label: {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 34, height: 30)
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(HHTheme.paper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HHTheme.goldDeep.opacity(0.25), lineWidth: 1)
                )
            } else if let selection = selectedInventoryItem {
                HStack(spacing: 9) {
                    FurnitureSpriteView(itemID: selection.item.id, emoji: selection.item.emoji)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Placing \(selection.item.name)")
                            .font(.hhHeadline(12.5))
                            .foregroundStyle(HHTheme.ink)
                        Text("Tap a tile in the room. \(selection.count) left.")
                            .font(.hhCaption(9.5))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 4)
                    Button("Cancel") {
                        selectedItemID = nil
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.muted))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(HHTheme.paper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HHTheme.forest.opacity(0.25), lineWidth: 1)
                )
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(HHTheme.forest)
                    Text(store.furnitureInventory.isEmpty
                        ? "Every piece is placed. Pick something up to rearrange it."
                        : "Choose a piece of furniture below, then tap the room to place it.")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(HHTheme.paper.opacity(0.7))
                )
            }
        }
    }

    private func nudgeButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 32, height: 30)
        }
        .buttonStyle(MiniActionStyle(tint: HHTheme.forest))
    }

    // MARK: Shelf

    private var furnitureShelf: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionHeader(
                    "Furniture shelf",
                    subtitle: "Pieces you own and have not placed yet.",
                    icon: "shippingbox.fill"
                )
                Spacer(minLength: 6)
                Button {
                    store.selectedTab = .market
                } label: {
                    Label("Shop", systemImage: "cart.fill")
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
            }

            if store.furnitureInventory.isEmpty {
                NoticeBanner(
                    icon: "sofa",
                    title: "The shelf is empty",
                    message: "Buy furniture at the market, or pick a placed piece back up.",
                    tint: HHTheme.rose
                )
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(store.furnitureInventory, id: \.item.id) { entry in
                            furnitureChip(entry.item, count: entry.count)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func furnitureChip(_ item: ItemDefinition, count: Int) -> some View {
        let isSelected = selectedItemID == item.id
        return Button {
            selectedItemID = isSelected ? nil : item.id
            selectedPlacedID = nil
        } label: {
            VStack(spacing: 5) {
                FurnitureSpriteView(itemID: item.id, emoji: item.emoji)
                    .frame(width: 48, height: 40)
                Text(item.name)
                    .font(.hhHeadline(10.5))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                Text("×\(count)")
                    .font(.hhCaption(9))
                    .foregroundStyle(HHTheme.muted)
            }
            .frame(width: 90)
            .padding(.vertical, 8)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isSelected ? HHTheme.forest.opacity(0.1) : HHTheme.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? HHTheme.forest : HHTheme.ink.opacity(0.07), lineWidth: isSelected ? 1.6 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name), \(count) available")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: Helpers

    private func handleTap(x: Int, y: Int) {
        if let selectedItemID {
            store.placeFurniture(itemID: selectedItemID, x: x, y: y)
            if store.itemCount(selectedItemID) == 0 {
                self.selectedItemID = nil
            }
            selectedPlacedID = nil
        } else {
            selectedPlacedID = nil
        }
    }

    private var houseTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🛋️")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 3) {
                Text("A home worth coming back to")
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                Text("Comfort from placed furniture raises market prices, up to +25%. Drag any piece to nudge it, or use the arrow buttons for precise placement.")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.rose.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.rose.opacity(0.16), lineWidth: 1)
        )
    }
}
#endif
