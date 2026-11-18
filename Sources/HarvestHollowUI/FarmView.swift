#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Farm

public struct FarmView: View {
    @EnvironmentObject private var store: GameStore
    @State private var pendingPlot: Plot?

    private var state: GameState { store.state }
    private var readyCount: Int { state.plots.filter { $0.crop?.isReady == true }.count }
    private var thirstyCount: Int {
        state.plots.filter {
            guard let crop = $0.crop else { return false }
            return !crop.watered && !crop.isReady
        }.count
    }
    private var emptyCount: Int {
        state.plots.filter { $0.unlocked && $0.crop == nil }.count
    }
    private var activeCrop: CropDefinition? {
        store.activeSeedCropID.flatMap { store.catalog.crop($0) }
    }
    private var detailBinding: Binding<Bool> {
        Binding(
            get: { store.selectedPlotID != nil },
            set: { if !$0 { store.selectedPlotID = nil } }
        )
    }
    private var purchaseBinding: Binding<Bool> {
        Binding(
            get: { pendingPlot != nil },
            set: { if !$0 { pendingPlot = nil } }
        )
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                weatherCard
                seedSatchel
                quickActions
                pondCard
                fieldCard
                farmingTip
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: detailBinding) {
            if let plotID = store.selectedPlotID {
                PlotDetailSheet(plotID: plotID)
                    .environmentObject(store)
                    .presentationDetents([.height(470), .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .confirmationDialog(
            "Clear this plot?",
            isPresented: purchaseBinding,
            titleVisibility: .visible,
            presenting: pendingPlot
        ) { plot in
            Button("Clear for \(store.plotPrice()) coins") {
                store.buyPlot(plot.id)
                pendingPlot = nil
            }
            Button("Not yet", role: .cancel) {
                pendingPlot = nil
            }
        } message: { plot in
            Text("Plot \(plot.id + 1) needs level \(store.plotUnlockLevel(plot.id)). You have \(state.coins) coins.")
        }
    }

    // MARK: Weather

    private var weatherCard: some View {
        CozyCard {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text(state.weather.emoji)
                        .font(.system(size: 30))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle().fill(
                                LinearGradient(
                                    colors: [HHTheme.sky.opacity(0.55), HHTheme.paper],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.weather.title)
                            .font(.hhHeadline(18))
                            .foregroundStyle(HHTheme.ink)
                        Text(state.weather.blurb)
                            .font(.hhBody(12.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next day")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                        Text(dayRemainingText)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.terracotta)
                            .monospacedDigit()
                    }
                }

                HStack(spacing: 7) {
                    TagChip("\(readyCount) ready", icon: "sparkles", tint: HHTheme.goldDeep)
                    TagChip("\(thirstyCount) thirsty", icon: "drop.fill", tint: Color(hex: "4F8AAE"))
                    TagChip("\(emptyCount) empty", icon: "square.dashed", tint: HHTheme.muted)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var dayRemainingText: String {
        let seconds = max(0, Int(GameConstants.dayLength - state.clock))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: Seeds

    private var seedSatchel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center) {
                SectionHeader(
                    "Seed satchel",
                    subtitle: store.ownedSeedCrops.isEmpty
                        ? "Your pockets are empty. The market has fresh seeds."
                        : "Choose a seed, then tap any empty plot.",
                    icon: "leaf.fill"
                )
                Spacer(minLength: 8)
                Button {
                    store.selectedTab = .market
                } label: {
                    Label("Shop", systemImage: "cart.fill")
                }
                .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
            }

            if store.ownedSeedCrops.isEmpty {
                NoticeBanner(
                    icon: "bag",
                    title: "No seeds in the satchel",
                    message: "Wheat, carrots and tomatoes are a good place to start.",
                    tint: HHTheme.terracotta
                )
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(store.ownedSeedCrops) { crop in
                            SeedChip(
                                crop: crop,
                                count: store.seedCount(crop.id),
                                isSelected: store.activeSeedCropID == crop.id
                            ) {
                                store.selectedSeedCropID = crop.id
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: Quick actions

    private var quickActions: some View {
        HStack(spacing: 9) {
            FarmQuickAction(
                title: "Water all",
                icon: "drop.fill",
                tint: Color(hex: "4F8AAE")
            ) {
                store.waterAll()
            }
            FarmQuickAction(
                title: "Harvest all",
                icon: "basket.fill",
                tint: HHTheme.goldDeep
            ) {
                store.harvestAll()
            }
            FarmQuickAction(
                title: "Plant all",
                icon: "leaf.fill",
                tint: HHTheme.forest
            ) {
                store.plantAll()
            }
        }
    }

    // MARK: Pond shortcut

    private var pondCard: some View {
        CozyCard(padding: 13) {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "7FB7D6"), Color(hex: "4F6D8A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "fish.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Hollow Pond")
                            .font(.hhHeadline(14))
                            .foregroundStyle(HHTheme.ink)
                        Text("FISHING")
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: "4F6D8A"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "7FB7D6").opacity(0.18), in: Capsule())
                    }
                    Text("\(store.fishingRodName) · \(store.uniqueFishCaught) species · \(store.baitCount) bait")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                    Text("A short walk past the field. Cast a line, sell the catch, and fill the pond journal.")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button {
                    store.openTown(.fishing)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "figure.fishing")
                            .font(.system(size: 13, weight: .bold))
                        Text("Go")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color(hex: "4F6D8A"), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Field

    private var fieldCard: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(
                        "The field",
                        subtitle: "Tap a plot to tend it. Long-press for more actions.",
                        icon: "square.grid.3x3.fill"
                    )
                    Spacer(minLength: 8)
                    Text("\(state.unlockedPlots)/\(state.plots.count)")
                        .font(.hhHeadline(13))
                        .foregroundStyle(HHTheme.muted)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(HHTheme.paperDeep, in: Capsule())
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 66, maximum: 94), spacing: 9)],
                    spacing: 9
                ) {
                    ForEach(state.plots) { plot in
                        PlotCell(plot: plot, activeCrop: activeCrop, plotPrice: store.plotPrice())
                            .onTapGesture {
                                tap(plot)
                            }
                            .contextMenu {
                                plotMenu(plot)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(plotAccessibilityLabel(plot))
                    }
                }

                if let activeCrop {
                    HStack(spacing: 8) {
                        Image(systemName: "cursorarrow.click.2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(HHTheme.forest)
                        Text("Planting \(activeCrop.name). You have \(store.seedCount(activeCrop.id)) seeds.")
                            .font(.hhCaption(11.5))
                            .foregroundStyle(HHTheme.muted)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func plotMenu(_ plot: Plot) -> some View {
        if !plot.unlocked {
            Button {
                pendingPlot = plot
            } label: {
                Label("Clear plot", systemImage: "hammer.fill")
            }
        } else if let crop = plot.crop {
            if crop.isReady {
                Button {
                    store.harvest(plotID: plot.id)
                } label: {
                    Label("Harvest", systemImage: "basket.fill")
                }
            } else {
                Button {
                    store.water(plotID: plot.id)
                } label: {
                    Label("Water", systemImage: "drop.fill")
                }
                Button {
                    store.fertilize(plotID: plot.id)
                } label: {
                    Label("Fertilize", systemImage: "sparkles")
                }
            }
            Button {
                store.selectedPlotID = plot.id
            } label: {
                Label("Crop details", systemImage: "info.circle")
            }
        } else {
            Button {
                store.plantSelected(in: plot.id)
            } label: {
                Label(
                    activeCrop.map { "Plant \($0.name)" } ?? "Plant a seed",
                    systemImage: "leaf.fill"
                )
            }
            Button {
                store.selectedPlotID = plot.id
            } label: {
                Label("Plot details", systemImage: "info.circle")
            }
        }
    }

    private func plotAccessibilityLabel(_ plot: Plot) -> String {
        if !plot.unlocked { return "Locked plot \(plot.id + 1)" }
        if let crop = plot.crop {
            let name = store.catalog.crop(crop.cropID)?.name ?? "crop"
            return "\(name), \(crop.stage.label), \(Int(crop.growth * 100)) percent grown"
        }
        return "Empty plot \(plot.id + 1)"
    }

    private func tap(_ plot: Plot) {
        guard plot.unlocked else {
            pendingPlot = plot
            return
        }

        if let crop = plot.crop {
            if crop.isReady {
                store.harvest(plotID: plot.id)
            } else if !crop.watered {
                store.water(plotID: plot.id)
            } else {
                store.selectedPlotID = plot.id
            }
            return
        }

        if store.activeSeedCropID == nil {
            store.enqueueToast(
                title: "Pick a seed first",
                detail: "The market sells seeds for every level.",
                icon: "leaf",
                tint: HHTheme.terracotta
            )
            store.selectedTab = .market
        } else {
            store.plantSelected(in: plot.id)
        }
    }

    private var farmingTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🌱")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 3) {
                Text("A little farmer wisdom")
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                Text("Water starts the growth clock. Rainy days water everything for free, and fertilizer makes a crop grow 50% faster with a bigger harvest.")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.leaf.opacity(0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.leaf.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Seed chip

struct SeedChip: View {
    let crop: CropDefinition
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                CropSpriteView(cropID: crop.id, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(crop.name)
                        .font(.hhHeadline(12))
                        .foregroundStyle(HHTheme.ink)
                        .lineLimit(1)
                    Text("×\(count) · \(Int(crop.growSeconds))s")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                }
                .frame(width: 72, alignment: .leading)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? HHTheme.forest.opacity(0.12) : HHTheme.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? HHTheme.forest : HHTheme.ink.opacity(0.07),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(crop.name) seeds, \(count) left")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Quick action

struct FarmQuickAction: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HHTheme.paper.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plot cell

struct PlotCell: View {
    let plot: Plot
    let activeCrop: CropDefinition?
    let plotPrice: Int

    private var cropDefinition: CropDefinition? {
        guard let cropID = plot.crop?.cropID else { return nil }
        return GameCatalog.standard.crop(cropID)
    }

    var body: some View {
        ZStack {
            background
            content
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .overlay(alignment: .topLeading) {
            if plot.crop?.watered == true && plot.crop?.isReady == false {
                Image(systemName: "drop.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(Color(hex: "4F8AAE"), in: Circle())
                    .padding(5)
            }
        }
        .overlay(alignment: .topTrailing) {
            if plot.crop?.isReady == true {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(HHTheme.forestDark)
                    .frame(width: 18, height: 18)
                    .background(HHTheme.gold, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                    .padding(5)
            } else if plot.crop?.fertilized == true {
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(HHTheme.forestDark)
                    .frame(width: 17, height: 17)
                    .background(HHTheme.leafLight, in: Circle())
                    .padding(5)
            }
        }
        .shadow(
            color: plot.crop?.isReady == true ? HHTheme.gold.opacity(0.5) : HHTheme.soilDark.opacity(0.08),
            radius: plot.crop?.isReady == true ? 7 : 2,
            y: 2
        )
    }

    @ViewBuilder
    private var background: some View {
        if plot.unlocked {
            ZStack {
                LinearGradient(
                    colors: [HHTheme.soilLight, HHTheme.soil],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(HHTheme.soilDark.opacity(0.16))
                            .frame(height: 2.5)
                            .padding(.horizontal, 9)
                    }
                }
                .offset(y: 10)
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "A9B98D"), Color(hex: "7F9366")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "leaf.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.08))
                    .rotationEffect(.degrees(-20))
                    .offset(x: 12, y: -8)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !plot.unlocked {
            lockedContent
        } else if let crop = plot.crop, let definition = cropDefinition {
            cropContent(crop: crop, definition: definition)
        } else {
            emptyContent
        }
    }

    private var lockedContent: some View {
        VStack(spacing: 2) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
            Text("Lv \(GameBalance.plotUnlockLevel(for: plot.id))")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("\(plotPrice)c")
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(4)
    }

    private func cropContent(crop: CropInstance, definition: CropDefinition) -> some View {
        VStack(spacing: 3) {
            ZStack {
                if crop.growth < 0.28 {
                    SproutArtView()
                        .frame(width: 30, height: 30)
                } else {
                    CropSpriteView(cropID: crop.cropID, size: 52)
                        .scaleEffect(0.62 + 0.38 * min(1, crop.growth / 0.7))
                        .opacity(crop.watered || crop.growth >= 0.95 ? 1 : 0.72)
                }
            }
            .frame(height: 46)

            CozyProgressBar(
                value: crop.growth,
                tint: crop.isReady ? HHTheme.goldDeep : (crop.watered ? HHTheme.leaf : HHTheme.muted),
                height: 4
            )
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 3)
    }

    private var emptyContent: some View {
        VStack(spacing: 3) {
            Image(systemName: activeCrop == nil ? "bag" : "leaf")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
            Text(activeCrop == nil ? "Seeds" : "Plant")
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var borderColor: Color {
        if plot.crop?.isReady == true { return HHTheme.gold }
        if !plot.unlocked { return .white.opacity(0.22) }
        return HHTheme.soilDark.opacity(0.16)
    }

    private var borderWidth: CGFloat {
        plot.crop?.isReady == true ? 2 : 1
    }
}

// MARK: - Sprout

struct SproutArtView: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(HHTheme.forest)
                .frame(width: 3, height: 15)
                .offset(y: 6)
            Ellipse()
                .fill(HHTheme.leaf)
                .frame(width: 11, height: 6)
                .rotationEffect(.degrees(-32))
                .offset(x: -6, y: -1)
            Ellipse()
                .fill(HHTheme.leafLight)
                .frame(width: 11, height: 6)
                .rotationEffect(.degrees(30))
                .offset(x: 6, y: -3)
            Ellipse()
                .fill(HHTheme.leafLight)
                .frame(width: 9, height: 5)
                .rotationEffect(.degrees(-12))
                .offset(x: -3, y: -9)
        }
        .frame(width: 30, height: 32)
    }
}

// MARK: - Plot detail

public struct PlotDetailSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    public let plotID: Int

    public init(plotID: Int) {
        self.plotID = plotID
    }

    private var plot: Plot? {
        store.state.plots.first { $0.id == plotID }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Text("Plot \(plotID + 1)")
                        .font(.hhHeadline(17))
                        .foregroundStyle(HHTheme.ink)
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

                if let plot {
                    if !plot.unlocked {
                        lockedCard(plot: plot)
                    } else if let crop = plot.crop, let definition = store.catalog.crop(crop.cropID) {
                        cropCard(plot: plot, crop: crop, definition: definition)
                    } else {
                        emptyCard
                    }
                }
            }
            .padding(17)
        }
        .background(HHTheme.cream)
    }

    private func cropCard(
        plot: Plot,
        crop: CropInstance,
        definition: CropDefinition
    ) -> some View {
        VStack(spacing: 13) {
            CropSpriteView(cropID: crop.cropID, size: 100)
                .frame(height: 100)
                .padding(.top, 4)

            VStack(spacing: 3) {
                Text(definition.name)
                    .font(.hhTitle(24))
                    .foregroundStyle(HHTheme.ink)
                Text(crop.stage.label)
                    .font(.hhCaption(11.5))
                    .foregroundStyle(crop.isReady ? HHTheme.goldDeep : HHTheme.forest)
            }

            CozyProgressBar(
                value: crop.growth,
                tint: crop.isReady ? HHTheme.goldDeep : HHTheme.forest,
                height: 9
            )

            HStack(spacing: 7) {
                TagChip(crop.watered ? "Watered" : "Needs water", icon: "drop.fill", tint: crop.watered ? Color(hex: "4F8AAE") : HHTheme.terracotta)
                if crop.fertilized {
                    TagChip("Fertilized", icon: "sparkles", tint: HHTheme.leaf)
                }
                TagChip("\(Int(crop.growth * 100))%", icon: "chart.bar.fill", tint: HHTheme.muted)
            }

            NoticeBanner(
                icon: crop.isReady ? "checkmark.seal.fill" : (crop.watered ? "clock.fill" : "drop.fill"),
                title: crop.isReady ? "Ready to harvest" : (crop.watered ? "Growing nicely" : "This crop needs water"),
                message: growthMessage(crop: crop, definition: definition),
                tint: crop.isReady ? HHTheme.goldDeep : HHTheme.forest
            )

            HStack(spacing: 8) {
                Button {
                    store.water(plotID: plot.id)
                } label: {
                    Label("Water", systemImage: "drop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozySecondaryButtonStyle())
                .disabled(crop.watered || crop.isReady)
                .opacity(crop.watered || crop.isReady ? 0.45 : 1)

                Button {
                    store.fertilize(plotID: plot.id)
                } label: {
                    Label("Fertilize", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozySecondaryButtonStyle())
                .disabled(crop.fertilized || crop.isReady || store.itemCount("supply.fertilizer") == 0)
                .opacity(crop.fertilized || crop.isReady || store.itemCount("supply.fertilizer") == 0 ? 0.45 : 1)
            }

            Button {
                store.harvest(plotID: plot.id)
                dismiss()
            } label: {
                Label(crop.isReady ? "Harvest now" : "Not ready yet", systemImage: "basket.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CozyPrimaryButtonStyle())
            .disabled(!crop.isReady)
            .opacity(crop.isReady ? 1 : 0.45)

            HStack {
                Text("Seed \(store.catalog.item(definition.seedItemID)?.name ?? definition.seedName)")
                Spacer()
                Text("Yield \(definition.minYield)–\(definition.maxYield)\(crop.fertilized ? " +1" : "")")
            }
            .font(.hhCaption(11))
            .foregroundStyle(HHTheme.muted)
        }
    }

    private func growthMessage(crop: CropInstance, definition: CropDefinition) -> String {
        if crop.isReady {
            return "Harvest for \(definition.minYield)–\(definition.maxYield) \(definition.name.lowercased())\(crop.fertilized ? " plus the fertilizer bonus" : "")."
        }
        if !crop.watered {
            return "Tap Water to start the growth clock. Weather affects how fast it grows."
        }
        let speed = store.state.weather.growthMultiplier * (crop.fertilized ? 1.5 : 1)
        let seconds = max(1, definition.growSeconds * (1 - crop.growth) / speed)
        let timeText = seconds >= 60
            ? "\(Int(seconds / 60))m \(Int(seconds.truncatingRemainder(dividingBy: 60)))s"
            : "\(Int(seconds))s"
        return "About \(timeText) until harvest in this \(store.state.weather.title.lowercased()) weather."
    }

    private func lockedCard(plot: Plot) -> some View {
        VStack(spacing: 13) {
            Image(systemName: "lock.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 66, height: 66)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "A9B98D"), Color(hex: "7F9366")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
            Text("Wild meadow")
                .font(.hhTitle(22))
                .foregroundStyle(HHTheme.ink)
            Text("Clear this plot to make room for more crops.")
                .font(.hhBody(13))
                .foregroundStyle(HHTheme.muted)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                TagChip("Level \(store.plotUnlockLevel(plot.id))", icon: "person.fill", tint: HHTheme.terracotta)
                TagChip("\(store.plotPrice()) coins", icon: "circle.fill", tint: HHTheme.goldDeep)
            }
            Button {
                store.buyPlot(plot.id)
                dismiss()
            } label: {
                Label("Clear plot", systemImage: "hammer.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CozyPrimaryButtonStyle())
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 13) {
            SproutArtView()
                .frame(width: 70, height: 70)
                .scaleEffect(1.8)
                .frame(height: 100)
            Text("Good soil")
                .font(.hhTitle(22))
                .foregroundStyle(HHTheme.ink)
            Text("Pick a seed from the satchel, then tap this plot. Water starts the growth clock.")
                .font(.hhBody(13))
                .foregroundStyle(HHTheme.muted)
                .multilineTextAlignment(.center)
            if let active = store.activeSeedCropID.flatMap({ store.catalog.crop($0) }) {
                Button {
                    store.plant(cropID: active.id, in: plotID)
                    dismiss()
                } label: {
                    Label("Plant \(active.name)", systemImage: "leaf.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())
            } else {
                Button {
                    store.selectedTab = .market
                    dismiss()
                } label: {
                    Label("Buy seeds", systemImage: "cart.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())
            }
        }
    }
}
#endif
