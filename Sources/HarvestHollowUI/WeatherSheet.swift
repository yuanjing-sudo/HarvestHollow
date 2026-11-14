#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Weather sheet

public struct WeatherSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    private var state: GameState { store.state }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 13) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("The Hollow sky")
                            .font(.hhTitle(24))
                            .foregroundStyle(HHTheme.ink)
                        Text("Day \(state.day) · \(state.season.title) \(state.seasonDay) · \(state.weather.title)")
                            .font(.hhBody(12))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 4)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 23))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }

                WeatherDiorama(
                    weather: state.weather,
                    timeOfDay: state.timeOfDay,
                    compact: false
                )
                .frame(height: 160)

                HStack(spacing: 8) {
                    weatherEffect(
                        icon: "leaf.fill",
                        title: "Growth",
                        value: "\(Int(state.weather.growthMultiplier * 100))%",
                        tint: HHTheme.forest
                    )
                    weatherEffect(
                        icon: "fish.fill",
                        title: "Rare fish",
                        value: fishingValue,
                        tint: Color(hex: "4F6D8A")
                    )
                    weatherEffect(
                        icon: "cart.fill",
                        title: "Market",
                        value: "\(Int(Market.multiplier(itemID: "crop.wheat", day: state.day) * 100))%",
                        tint: HHTheme.goldDeep
                    )
                }

                CozyCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(
                            "Tomorrow's outlook",
                            subtitle: "The almanac is rarely wrong about the broad shape of things.",
                            icon: "cloud.sun.fill"
                        )
                        HStack(spacing: 9) {
                            Text(state.nextWeather.emoji)
                                .font(.system(size: 27))
                                .frame(width: 48, height: 48)
                                .background(HHTheme.gold.opacity(0.12), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(state.nextWeather.title)
                                    .font(.hhHeadline(15))
                                    .foregroundStyle(HHTheme.ink)
                                Text(state.nextWeather.marketHint)
                                    .font(.hhCaption(10.5))
                                    .foregroundStyle(HHTheme.muted)
                                Text("Fishing \(nextFishingText) · Growth \(Int(state.nextWeather.growthMultiplier * 100))%")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(HHTheme.muted)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }

                let history = Array(state.activities.weatherHistory.suffix(7))
                if history.count > 1 {
                    CozyCard {
                        VStack(alignment: .leading, spacing: 9) {
                            SectionHeader(
                                "Recent weather",
                                subtitle: "Seven days of sky, recorded by the farm ledger.",
                                icon: "clock.arrow.circlepath"
                            )
                            MiniBarChart(
                                values: history.map { $0.growthMultiplier * 100 },
                                labels: history.map { $0.emoji },
                                tint: HHTheme.forest
                            )
                            HStack(spacing: 5) {
                                ForEach(Array(history.enumerated()), id: \.offset) { _, weather in
                                    Text(weather.emoji)
                                        .font(.system(size: 11))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }

                NoticeBanner(
                    icon: state.weather.symbolName,
                    title: state.weather.title,
                    message: weatherAdvice,
                    tint: weatherTint
                )
            }
            .padding(.horizontal, 17)
            .padding(.top, 15)
            .padding(.bottom, 24)
        }
        .background(HHTheme.cream)
    }

    private var fishingValue: String {
        let value = Int((state.weather.fishingBonus * 100).rounded())
        return value >= 0 ? "+\(value)%" : "\(value)%"
    }

    private var nextFishingText: String {
        let value = Int((state.nextWeather.fishingBonus * 100).rounded())
        return value >= 0 ? "+\(value)% rare fish" : "\(value)% rare fish"
    }

    private var weatherTint: Color {
        switch state.weather {
        case .sunny: return HHTheme.goldDeep
        case .rainy: return Color(hex: "4F6D8A")
        case .breezy: return HHTheme.forest
        case .heatwave: return HHTheme.terracotta
        case .storm: return HHTheme.lavender
        }
    }

    private var weatherAdvice: String {
        switch state.weather {
        case .sunny:
            return "A steady, generous day. Crops grow at a normal pace and the market is calm."
        case .rainy:
            return "Every growing crop is watered overnight. The pond is lively, too."
        case .breezy:
            return "Mild and quick. The fields are comfortable and the fish are curious."
        case .heatwave:
            return "Crops grow quickly, but the pond is sluggish. Keep an eye on your water can."
        case .storm:
            return "The rarest fish come out in weather like this. The market square is quiet."
        }
    }

    private func weatherEffect(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(HHTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.hhCaption(8.5))
                .foregroundStyle(HHTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
#endif
