#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Inventory

public struct InventorySheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var filter: InventoryFilter = .all

    public init() {}

    private var state: GameState { store.state }

    private var totalItems: Int {
        store.inventoryItems.reduce(0) { $0 + $1.count }
    }

    private var sellableValue: Int {
        store.inventoryItems.reduce(0) { total, entry in
            switch entry.item.kind {
            case .produce, .animalProduct, .supply:
                return total + store.sellPrice(for: entry.item.id) * entry.count
            default:
                return total
            }
        }
    }

    private var groups: [(kind: ItemKind, items: [(item: ItemDefinition, count: Int)])] {
        ItemKind.allCases.compactMap { kind in
            let items = store.inventoryItems.filter { $0.item.kind == kind }
            return items.isEmpty ? nil : (kind, items)
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                filterStrip

                if filter == .all {
                    if groups.isEmpty {
                        emptyState
                    } else {
                        ForEach(groups, id: \.kind) { group in
                            inventorySection(kind: group.kind, items: group.items)
                        }
                    }
                } else if let kind = filter.kind {
                    let items = store.inventoryItems.filter { $0.item.kind == kind }
                    if items.isEmpty {
                        emptyState
                    } else {
                        inventorySection(kind: kind, items: items)
                    }
                }
            }
            .padding(18)
        }
        .background(HHTheme.cream)
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Satchel")
                    .font(.hhTitle(25))
                    .foregroundStyle(HHTheme.ink)
                Text("\(totalItems) items · about \(sellableValue) coins of sellable goods")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 6)
            CoinPill(state.coins)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 23))
                    .foregroundStyle(HHTheme.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close inventory")
        }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                ForEach(InventoryFilter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.title)
                            .font(.hhHeadline(11))
                            .foregroundStyle(filter == option ? .white : HHTheme.ink)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                filter == option ? HHTheme.forest : HHTheme.paper,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(filter == option ? .clear : HHTheme.ink.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func inventorySection(
        kind: ItemKind,
        items: [(item: ItemDefinition, count: Int)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(kind.title)
                    .font(.hhHeadline(15))
                    .foregroundStyle(HHTheme.ink)
                Text("\(items.count)")
                    .font(.hhCaption(10))
                    .foregroundStyle(HHTheme.muted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(HHTheme.paperDeep, in: Capsule())
                Spacer(minLength: 0)
            }

            VStack(spacing: 7) {
                ForEach(items, id: \.item.id) { entry in
                    inventoryRow(entry.item, count: entry.count)
                }
            }
        }
    }

    private func inventoryRow(_ item: ItemDefinition, count: Int) -> some View {
        HStack(spacing: 10) {
            ItemIconView(spriteKey: item.spriteKey, emoji: item.emoji, size: 36)
                .frame(width: 44, height: 44)
                .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .font(.hhHeadline(13.5))
                        .foregroundStyle(HHTheme.ink)
                        .lineLimit(1)
                    Text("×\(count)")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                }
                Text(item.detail)
                    .font(.hhCaption(10))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            actionButton(item)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HHTheme.paper.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func actionButton(_ item: ItemDefinition) -> some View {
        switch item.kind {
        case .seed:
            if let crop = store.catalog.crops.first(where: { $0.seedItemID == item.id }) {
                Button {
                    store.selectSeed(crop.id)
                    dismiss()
                } label: {
                    Text("Plant")
                        .font(.hhHeadline(10.5))
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.forest))
            }
        case .furniture:
            Button {
                store.selectedTab = .house
                dismiss()
            } label: {
                Text("Place")
                    .font(.hhHeadline(10.5))
            }
            .buttonStyle(MiniActionStyle(tint: HHTheme.rose))
        case .supply:
            if item.id == "supply.feed" {
                Button {
                    store.feedAll()
                } label: {
                    Text("Feed")
                        .font(.hhHeadline(10.5))
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.forest))
            } else {
                Button {
                    store.sell(itemID: item.id, quantity: 1)
                } label: {
                    Text("Sell 1")
                        .font(.hhHeadline(10.5))
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
            }
        case .produce, .animalProduct:
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(store.sellPrice(for: item.id))c")
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.goldDeep)
                Button {
                    store.sell(itemID: item.id, quantity: 1)
                } label: {
                    Text("Sell")
                        .font(.hhHeadline(10.5))
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "bag",
            title: "Nothing in this pocket",
            message: "Harvest crops, collect barn goods, or visit the market to fill up your satchel.",
            accent: HHTheme.terracotta
        )
        .padding(.top, 10)
    }
}

// MARK: - Filter

enum InventoryFilter: String, CaseIterable, Identifiable {
    case all
    case seeds
    case crops
    case goods
    case supplies
    case decor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .seeds: return "Seeds"
        case .crops: return "Crops"
        case .goods: return "Barn goods"
        case .supplies: return "Supplies"
        case .decor: return "Decor"
        }
    }

    var kind: ItemKind? {
        switch self {
        case .all: return nil
        case .seeds: return .seed
        case .crops: return .produce
        case .goods: return .animalProduct
        case .supplies: return .supply
        case .decor: return .furniture
        }
    }
}
#endif
