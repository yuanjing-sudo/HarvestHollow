#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Almanac

public struct AlmanacView: View {
    @EnvironmentObject private var store: GameStore

    private var state: GameState { store.state }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                TownScreenHeader(
                    title: "Valley Almanac",
                    subtitle: "Weather patterns, the season calendar, crop mastery, and what the market is paying today.",
                    icon: "calendar",
                    accent: HHTheme.goldDeep
                )

                seasonHero
                weatherSection
                festivalSection
                masterySection
                marketSection
                almanacNotes
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(HHTheme.cream)
        .navigationTitle("Almanac")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        #endif
    }

    // MARK: Season

    private var seasonHero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                WeatherDiorama(
                    weather: state.weather,
                    timeOfDay: state.timeOfDay,
                    compact: false
                )
                .frame(height: 158)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(state.season.emoji) \(state.season.title) · Year \(GameCalendar.year(forDay: state.day))")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Day \(state.seasonDay) of \(GameCalendar.daysPerSeason)")
                        .font(.hhTitle(26))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.16), radius: 3)
                    Text(state.season.blurb)
                        .font(.hhBody(11.5))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(state.weather.emoji).font(.system(size: 25))
                    Text(state.weather.title)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(Int(state.timeOfDay * 100))% of day")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(13)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            calendarStrip
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(HHTheme.ink.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: HHTheme.soilDark.opacity(0.15), radius: 14, y: 7)
    }

    private var calendarStrip: some View {
        let seasonStart = state.day - (state.seasonDay - 1)
        return HStack(spacing: 4) {
            ForEach(1...GameCalendar.daysPerSeason, id: \.self) { index in
                let dayNumber = seasonStart + index - 1
                let isToday = index == state.seasonDay
                let isPast = index < state.seasonDay
                let isFestival = index == GameCalendar.daysPerSeason
                VStack(spacing: 2) {
                    Text(dayLabel(index))
                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                        .foregroundStyle(isToday ? .white.opacity(0.8) : HHTheme.muted)
                        .lineLimit(1)
                    Text("\(index)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(isToday ? .white : HHTheme.ink)
                    Text(isFestival ? "🎉" : isPast ? "·" : " ")
                        .font(.system(size: 7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isToday ? HHTheme.forest : HHTheme.cream.opacity(0.5))
                )
                .accessibilityLabel("Day \(dayNumber)\(isToday ? ", today" : "")\(isFestival ? ", festival day" : "")")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(HHTheme.paper)
    }

    private func dayLabel(_ index: Int) -> String {
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        return letters[(index - 1) % letters.count]
    }

    // MARK: Weather

    private var weatherSection: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 11) {
                SectionHeader(
                    "The sky this week",
                    subtitle: "Weather changes growth speed and the mood at the pond.",
                    icon: "cloud.sun.fill"
                )

                HStack(spacing: 8) {
                    weatherTile(state.weather, title: "Today", tint: HHTheme.goldDeep)
                    weatherTile(state.nextWeather, title: "Tomorrow", tint: Color(hex: "4F6D8A"))
                }

                let history = Array(state.activities.weatherHistory.suffix(7))
                if history.count > 1 {
                    MiniBarChart(
                        values: history.map { $0.growthMultiplier * 100 },
                        labels: history.map { $0.emoji },
                        tint: HHTheme.forest
                    )
                    .padding(.top, 2)

                    HStack {
                        Text("Growth rate by day")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                        Spacer()
                        Text("\(Int(state.weather.growthMultiplier * 100))% today")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.forest)
                    }
                } else {
                    HStack(spacing: 7) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(HHTheme.forest)
                        Text("The seven-day weather ledger starts filling tomorrow.")
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        TagChip("\(Int(state.weather.growthMultiplier * 100))% growth", tint: HHTheme.forest)
                    }
                    .padding(.top, 2)
                }

                HStack(spacing: 6) {
                    TagChip("\(Int(state.weather.growthMultiplier * 100))% growth", icon: "leaf.fill", tint: HHTheme.forest)
                    TagChip(fishingTag, icon: "fish.fill", tint: Color(hex: "4F6D8A"))
                    TagChip(state.weather.marketHint, icon: "cart.fill", tint: HHTheme.goldDeep)
                }
                .lineLimit(1)
            }
        }
    }

    private var fishingTag: String {
        let value = Int((state.weather.fishingBonus * 100).rounded())
        return value >= 0 ? "+\(value)% rare fish" : "\(value)% rare fish"
    }

    private func weatherTile(_ weather: Weather, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Text(weather.emoji).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.hhCaption(9.5))
                    .foregroundStyle(HHTheme.muted)
                Text(weather.title)
                    .font(.hhHeadline(12.5))
                    .foregroundStyle(HHTheme.ink)
                Text(weather.marketHint)
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .frame(maxWidth: .infinity)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    // MARK: Festival

    @ViewBuilder
    private var festivalSection: some View {
        if let festival = state.festival {
            HStack(spacing: 10) {
                Text(festival.emoji)
                    .font(.system(size: 26))
                    .frame(width: 46, height: 46)
                    .background(HHTheme.gold.opacity(0.2), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Festival day · \(festival.name)")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    Text(festival.blurb)
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HHTheme.gold.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(HHTheme.goldDeep.opacity(0.16), lineWidth: 1)
            )
        } else if let next = GameCalendar.nextFestival(afterDay: state.day) {
            let daysAway = max(1, (GameCalendar.daysPerYear - state.day % GameCalendar.daysPerYear) % GameCalendar.daysPerYear)
            HStack(spacing: 10) {
                Text(next.emoji)
                    .font(.system(size: 24))
                    .frame(width: 42, height: 42)
                    .background(HHTheme.lavender.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next festival · \(next.name)")
                        .font(.hhHeadline(13.5))
                        .foregroundStyle(HHTheme.ink)
                    Text("The square is already planning. \(daysAway) day\(daysAway == 1 ? "" : "s") of the season left.")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(HHTheme.paper.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: Crop mastery

    private var masterySection: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(
                        "Crop mastery",
                        subtitle: "Every harvest teaches the field something. Mastery adds value when you sell.",
                        icon: "star.fill"
                    )
                    Spacer(minLength: 4)
                    Text("\(masteredCropCount)/\(store.catalog.crops.count)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.goldDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HHTheme.gold.opacity(0.14), in: Capsule())
                }

                ForEach(store.catalog.crops) { crop in
                    masteryRow(crop)
                    if crop.id != store.catalog.crops.last?.id {
                        CozyDivider()
                    }
                }
            }
        }
    }

    private var masteredCropCount: Int {
        store.catalog.crops.filter { store.cropMasteryLevel($0.id) >= 4 }.count
    }

    private func masteryRow(_ crop: CropDefinition) -> some View {
        let harvests = store.cropHarvestCount(crop.id)
        let tier = store.cropMasteryTier(crop.id)
        let next = CropMastery.nextTier(for: harvests)
        let progress = store.cropMasteryProgress(crop.id)
        let bonus = Int(CropMastery.saleBonus(for: harvests) * 100)

        return HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HHTheme.cream.opacity(0.6))
                if let sprite = SpriteLibrary.crop(crop.id) {
                    PixelSpriteView(sprite)
                        .frame(width: 35, height: 35)
                } else {
                    Text(crop.emoji).font(.system(size: 22))
                }
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(crop.name)
                        .font(.hhHeadline(12.5))
                        .foregroundStyle(HHTheme.ink)
                    Text(tier.emoji)
                        .font(.system(size: 9))
                    Text(tier.title)
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.goldDeep)
                    Spacer(minLength: 0)
                    Text("\(harvests) harvested")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
                HStack(spacing: 6) {
                    Text(CropMastery.stars(for: harvests))
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(HHTheme.goldDeep)
                    CozyProgressBar(value: progress, tint: HHTheme.goldDeep, height: 4)
                    if let next {
                        Text("\(max(0, next.threshold - harvests)) to \(next.title)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                            .lineLimit(1)
                    } else {
                        Text("maxed")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(HHTheme.forest)
                    }
                }
            }

            Text("+\(bonus)%")
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(bonus > 0 ? HHTheme.forest : HHTheme.muted)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    // MARK: Market

    private var marketSection: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(
                        "Market board",
                        subtitle: "Today's crop prices compared with the usual rate.",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    Spacer(minLength: 4)
                    Button {
                        store.selectedTab = .market
                    } label: {
                        Text("Sell")
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
                }

                ForEach(store.catalog.crops) { crop in
                    marketRow(crop)
                    if crop.id != store.catalog.crops.last?.id {
                        CozyDivider()
                    }
                }
            }
        }
    }

    private func marketRow(_ crop: CropDefinition) -> some View {
        let itemID = crop.produceItemID
        let item = store.catalog.item(itemID)
        let base = item?.sellPrice ?? 0
        let price = store.sellPrice(for: itemID)
        let fraction = base > 0 ? Double(price) / (Double(base) * 1.28) : 0
        let trendUp = price >= base
        return HStack(spacing: 8) {
            Text(item?.emoji ?? crop.emoji)
                .font(.system(size: 17))
                .frame(width: 26)
            Text(crop.name)
                .font(.hhBody(11.5))
                .foregroundStyle(HHTheme.ink)
                .frame(width: 64, alignment: .leading)
                .lineLimit(1)
            MiniTrendBar(value: fraction, tint: trendUp ? HHTheme.forest : HHTheme.terracotta)
            Text("\(price)c")
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
            Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(trendUp ? HHTheme.forest : HHTheme.terracotta)
            Text("\(store.itemCount(itemID))")
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundStyle(HHTheme.muted)
                .monospacedDigit()
                .frame(width: 18, alignment: .trailing)
        }
        .padding(.vertical, 1)
    }

    private var almanacNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Almanac notes", subtitle: "Small patterns worth remembering.", icon: "text.book.closed.fill")
            noteRow("🌧️", "Rain waters every growing crop overnight. A rainy evening can save a whole field.")
            noteRow("📈", "Prices drift each day. A few coins of patience often beats a rushed sale.")
            noteRow("⭐", "Mastery is per crop. Ten moonberry harvests matter just as much as ten wheat harvests.")
            noteRow("🎉", "The last day of each season is a festival. The square is worth a visit.")
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
#endif
