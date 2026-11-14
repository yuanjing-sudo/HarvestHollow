#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Quests

public struct QuestsView: View {
    @EnvironmentObject private var store: GameStore

    private var state: GameState { store.state }
    private var quests: [QuestDefinition] { store.catalog.quests }
    private var currentIndex: Int { state.quests.storyIndex }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                progressHeader
                activeQuestCard
                dailyOrderCard
                storyTimeline
                statsCard
                questTip
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

    private var progressHeader: some View {
        CozyCard {
            VStack(spacing: 11) {
                HStack(alignment: .top, spacing: 12) {
                    Text("📖")
                        .font(.system(size: 27))
                        .frame(width: 50, height: 50)
                        .background(HHTheme.gold.opacity(0.16), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("The Hollow story")
                            .font(.hhHeadline(18))
                            .foregroundStyle(HHTheme.ink)
                        Text("Quests finish on their own as you play. Each one leaves a little something behind.")
                            .font(.hhBody(12.5))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    LevelBadge(
                        level: state.level,
                        progress: state.levelProgress,
                        showXP: false
                    )
                }

                HStack(spacing: 6) {
                    Text("Level \(state.level)")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.forest)
                    CozyProgressBar(value: state.levelProgress, tint: HHTheme.forest, height: 7)
                    Text("\(state.xp)/\(state.xpForNextLevel) XP")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                        .monospacedDigit()
                }

                HStack(spacing: 9) {
                    StatTile(
                        title: "Quests",
                        value: "\(state.stats.questsCompleted)/\(quests.count)",
                        icon: "checkmark.seal.fill",
                        tint: HHTheme.forest
                    )
                    StatTile(
                        title: "Coins earned",
                        value: "\(state.stats.coinsEarned)",
                        icon: "circle.fill",
                        tint: HHTheme.goldDeep
                    )
                    StatTile(
                        title: "Days",
                        value: "\(state.flags.totalDaysPlayed)",
                        icon: "sun.max.fill",
                        tint: HHTheme.terracotta
                    )
                }

                HStack(spacing: 7) {
                    TownQuickLink(
                        title: store.claimableAchievementCount > 0
                            ? "\(store.claimableAchievementCount) achievement rewards"
                            : "Achievement journal",
                        icon: "rosette",
                        tint: HHTheme.lavender
                    ) {
                        store.openTown(.achievements)
                    }
                    if store.canClaimDailyGift {
                        TownQuickLink(title: "Daily gift", icon: "gift.fill", tint: HHTheme.rose) {
                            store.openTown()
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Active quest

    @ViewBuilder
    private var activeQuestCard: some View {
        if let quest = store.activeQuest {
            CozyCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Chapter \(currentIndex + 1)")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.terracotta)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(HHTheme.terracotta.opacity(0.1), in: Capsule())
                        Spacer(minLength: 4)
                        TagChip("In progress", icon: "hourglass", tint: HHTheme.goldDeep)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(quest.title)
                            .font(.hhTitle(23))
                            .foregroundStyle(HHTheme.ink)
                        Text(quest.blurb)
                            .font(.hhBody(13))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 9) {
                        ForEach(Array(quest.objectives.enumerated()), id: \.offset) { index, objective in
                            objectiveRow(objective, index: index)
                        }
                    }

                    Divider()
                        .overlay(HHTheme.ink.opacity(0.08))

                    HStack(spacing: 7) {
                        Text("Reward")
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                        TagChip("+\(quest.reward.coins) coins", icon: "circle.fill", tint: HHTheme.goldDeep)
                        TagChip("+\(quest.reward.xp) XP", icon: "sparkles", tint: HHTheme.forest)
                        Spacer(minLength: 0)
                    }

                    if !quest.reward.items.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(Array(quest.reward.items.keys.sorted()), id: \.self) { itemID in
                                if let item = store.catalog.item(itemID), let quantity = quest.reward.items[itemID] {
                                    TagChip(
                                        "\(item.emoji) \(item.name) ×\(quantity)",
                                        tint: HHTheme.rose
                                    )
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        } else {
            EmptyStateView(
                icon: "checkmark.seal.fill",
                title: "The story is complete",
                message: "You have finished every chapter of the Hollow. The farm is yours to enjoy, forever.",
                accent: HHTheme.forest
            )
        }
    }

    private func objectiveRow(_ objective: QuestObjective, index: Int) -> some View {
        let progress = store.questProgress(objective)
        let complete = progress >= objective.target
        let fraction = min(1, Double(progress) / Double(max(1, objective.target)))

        return HStack(alignment: .top, spacing: 9) {
            ZStack {
                Circle()
                    .fill(complete ? HHTheme.forest : HHTheme.paperDeep)
                if complete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
            }
            .frame(width: 19, height: 19)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(objective.metric.title)
                        .font(.hhHeadline(12))
                        .foregroundStyle(complete ? HHTheme.forest : HHTheme.ink)
                    Spacer(minLength: 4)
                    Text("\(min(progress, objective.target))/\(objective.target)")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(complete ? HHTheme.forest : HHTheme.muted)
                        .monospacedDigit()
                }
                CozyProgressBar(
                    value: fraction,
                    tint: complete ? HHTheme.forest : HHTheme.goldDeep,
                    height: 5
                )
            }
        }
    }

    // MARK: Daily order

    @ViewBuilder
    private var dailyOrderCard: some View {
        if let order = state.dailyOrder {
            let item = store.catalog.item(order.itemID)
            let fraction = min(1, Double(order.progress) / Double(max(1, order.target)))

            CozyCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ItemIconView(
                            spriteKey: item?.spriteKey,
                            emoji: item?.emoji ?? "📦",
                            size: 36
                        )
                        .frame(width: 46, height: 46)
                        .background(HHTheme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.completed ? "Delivered" : "Daily market order")
                                .font(.hhHeadline(14.5))
                                .foregroundStyle(HHTheme.ink)
                            Text(order.completed
                                ? "A fresh order arrives tomorrow."
                                : "Sell \(order.target) \(item?.name.lowercased() ?? "goods") before the day ends.")
                                .font(.hhCaption(10.5))
                                .foregroundStyle(HHTheme.muted)
                        }
                        Spacer(minLength: 4)
                        Text("\(order.progress)/\(order.target)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(order.completed ? HHTheme.forest : HHTheme.muted)
                            .monospacedDigit()
                    }

                    CozyProgressBar(
                        value: fraction,
                        tint: order.completed ? HHTheme.forest : HHTheme.goldDeep,
                        height: 6
                    )

                    HStack(spacing: 7) {
                        TagChip("+\(order.rewardCoins) coins", icon: "circle.fill", tint: HHTheme.goldDeep)
                        TagChip("+\(order.rewardXP) XP", icon: "sparkles", tint: HHTheme.forest)
                        Spacer(minLength: 0)
                        if !order.completed {
                            Button {
                                store.selectedTab = .market
                            } label: {
                                Text("Go to market")
                                    .font(.hhHeadline(11))
                            }
                            .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))
                        }
                    }
                }
            }
        }
    }

    // MARK: Timeline

    private var storyTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                "Chapters",
                subtitle: "Ten small stories from the old Hollow farm.",
                icon: "book.closed.fill"
            )

            VStack(spacing: 0) {
                ForEach(Array(quests.enumerated()), id: \.element.id) { index, quest in
                    storyRow(quest, index: index)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(HHTheme.paper.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(HHTheme.ink.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func storyRow(_ quest: QuestDefinition, index: Int) -> some View {
        let completed = index < currentIndex
        let current = index == currentIndex
        let isLast = index == quests.count - 1

        return HStack(alignment: .top, spacing: 11) {
            VStack(spacing: 0) {
                Circle()
                    .fill(completed ? HHTheme.forest : (current ? HHTheme.gold : HHTheme.paperDeep))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Group {
                            if completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(.white)
                            } else if current {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(HHTheme.forestDark)
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(HHTheme.muted.opacity(0.7))
                            }
                        }
                    )
                if !isLast {
                    Rectangle()
                        .fill(completed ? HHTheme.forest.opacity(0.35) : HHTheme.ink.opacity(0.1))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 2)
                }
            }
            .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(index + 1). \(quest.title)")
                        .font(.hhHeadline(13))
                        .foregroundStyle(completed || current ? HHTheme.ink : HHTheme.muted)
                    Spacer(minLength: 4)
                    if completed {
                        Text("Done")
                            .font(.hhCaption(9))
                            .foregroundStyle(HHTheme.forest)
                    } else if current {
                        Text("Now")
                            .font(.hhCaption(9))
                            .foregroundStyle(HHTheme.goldDeep)
                    }
                }
                if current {
                    Text(quest.blurb)
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, isLast ? 2 : 12)
        }
        .padding(.top, 5)
        .opacity(completed || current ? 1 : 0.72)
    }

    // MARK: Stats

    private var statsCard: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader("Farm records", subtitle: "The little numbers behind the story.", icon: "chart.bar.fill")

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 118, maximum: 220), spacing: 8)],
                    spacing: 8
                ) {
                    recordTile("Crops planted", "\(state.stats.cropsPlanted)", "leaf.fill", HHTheme.forest)
                    recordTile("Crops harvested", "\(state.stats.cropsHarvested)", "basket.fill", HHTheme.goldDeep)
                    recordTile("Animals adopted", "\(state.stats.animalsBought)", "pawprint.fill", HHTheme.terracotta)
                    recordTile("Barn goods", "\(state.stats.animalProducts)", "shippingbox.fill", HHTheme.rose)
                    recordTile("Goods sold", "\(state.stats.itemsSold)", "tag.fill", HHTheme.forest)
                    recordTile("Decorations", "\(state.stats.decorationsPlaced)", "sofa.fill", HHTheme.terracotta)
                }
            }
        }
    }

    private func recordTile(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 25, height: 25)
                .background(tint.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.ink)
                Text(title)
                    .font(.hhCaption(9.5))
                    .foregroundStyle(HHTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(HHTheme.cream.opacity(0.65), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var questTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("✨")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 3) {
                Text("Small steps, good stories")
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                Text("Quests complete automatically when their goals are met, and rewards land straight in your pockets. Daily orders are a quick way to earn extra coins before the day rolls over.")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HHTheme.gold.opacity(0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HHTheme.goldDeep.opacity(0.16), lineWidth: 1)
        )
    }
}
#endif
