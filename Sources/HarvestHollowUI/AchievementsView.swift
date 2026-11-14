#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Achievements

public struct AchievementsView: View {
    @EnvironmentObject private var store: GameStore
    @State private var category: AchievementCategory?

    private var allProgress: [AchievementProgress] { store.achievementProgressList }
    private var filtered: [AchievementProgress] {
        allProgress
            .filter { category == nil || $0.definition.category == category }
            .sorted { lhs, rhs in
                if lhs.isClaimed != rhs.isClaimed { return !lhs.isClaimed }
                if lhs.canClaim != rhs.canClaim { return lhs.canClaim }
                if lhs.definition.category != rhs.definition.category {
                    return lhs.definition.category.rawValue < rhs.definition.category.rawValue
                }
                return lhs.fraction > rhs.fraction
            }
    }
    private var claimed: Int { allProgress.filter(\.isClaimed).count }
    private var ready: Int { allProgress.filter(\.canClaim).count }
    private var total: Int { allProgress.count }
    private var overall: Double {
        guard total > 0 else { return 0 }
        return Double(claimed) / Double(total)
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                TownScreenHeader(
                    title: "Achievement Journal",
                    subtitle: "A record of small mornings, big harvests, and the occasional legendary fish.",
                    icon: "rosette",
                    accent: HHTheme.forest
                )

                summaryCard
                categoryPicker
                progressGrid
                journalNotes
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(HHTheme.cream)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    // MARK: Summary

    private var summaryCard: some View {
        CozyCard {
            VStack(spacing: 13) {
                HStack(spacing: 13) {
                    ProgressRing(
                        value: overall,
                        tint: HHTheme.forest,
                        lineWidth: 8,
                        label: "\(Int(overall * 100))%",
                        detail: "done"
                    )
                    .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(ready > 0 ? "\(ready) reward\(ready == 1 ? "" : "s") waiting" : "The journal is up to date")
                            .font(.hhTitle(21))
                            .foregroundStyle(HHTheme.ink)
                        Text("\(claimed) of \(total) badges claimed · \(store.collectionProgress > 0 ? "the valley is taking notes" : "every journey starts with one seed")")
                            .font(.hhBody(12))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 7) {
                    TagChip("\(ready) ready", icon: "sparkles", tint: HHTheme.goldDeep)
                    TagChip("\(claimed) claimed", icon: "checkmark.seal.fill", tint: HHTheme.forest)
                    TagChip("\(max(0, total - claimed)) to go", icon: "hourglass", tint: HHTheme.muted)
                    Spacer(minLength: 0)
                }

                Button {
                    store.claimAllAchievements()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "gift.fill")
                        Text(ready > 0 ? "Claim all \(ready) rewards" : "Nothing to claim yet")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ready > 0 ? CozyPrimaryButtonStyle() : CozySecondaryButtonStyle())
                .disabled(ready == 0)
                .opacity(ready > 0 ? 1 : 0.55)
            }
        }
    }

    private var categoryPicker: some View {
        CozySegmentedPicker(
            items: ([nil] as [AchievementCategory?]) + AchievementCategory.allCases.map(Optional.some),
            selection: $category,
            tint: HHTheme.forest,
            icon: { $0?.icon ?? "square.grid.2x2.fill" },
            title: { category in
                guard let category else { return "All" }
                let count = allProgress.filter { $0.definition.category == category }.count
                return "\(category.title) \(count)"
            }
        )
    }

    // MARK: Grid

    private var progressGrid: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionHeader(
                    category?.title ?? "All achievements",
                    subtitle: subtitle,
                    icon: category?.icon ?? "rosette",
                    accent: category.map { Color(hex: $0.tintHex) } ?? HHTheme.forest
                )
                Spacer(minLength: 4)
                Text("\(filtered.count)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HHTheme.ink.opacity(0.05), in: Capsule())
            }

            if filtered.isEmpty {
                TownEmptyCard(
                    icon: "rosette",
                    title: "No badges on this page",
                    message: "Try another category. Every part of the farm has its own small goals.",
                    accent: category.map { Color(hex: $0.tintHex) } ?? HHTheme.forest
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filtered) { progress in
                        achievementRow(progress)
                    }
                }
            }
        }
    }

    private var subtitle: String {
        if let category {
            switch category {
            case .farming: return "Seeds, soil, and the slow satisfaction of a full basket."
            case .barn: return "Every scratch behind the ears counts for something."
            case .market: return "Goods sold, meals shared, and a name the valley knows."
            case .fishing: return "Patience, weather, and the odd very large fish."
            case .home: return "A comfortable cottage is its own kind of harvest."
            case .story: return "The long arc of Hollowmere, one chapter at a time."
            }
        }
        return "Long-term goals across every corner of the farm."
    }

    private func achievementRow(_ progress: AchievementProgress) -> some View {
        let definition = progress.definition
        let tint = Color(hex: definition.category.tintHex)
        let claimed = progress.isClaimed
        let complete = progress.isComplete

        return CozyCard(padding: 11) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(tint.opacity(claimed ? 0.16 : 0.08))
                    Image(systemName: claimed ? "checkmark.seal.fill" : definition.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(claimed ? HHTheme.forest : tint)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(definition.title)
                            .font(.hhHeadline(13.5))
                            .foregroundStyle(HHTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        TagChip(definition.category.title, icon: definition.category.icon, tint: tint)
                        Spacer(minLength: 0)
                    }

                    Text(definition.blurb)
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        CozyProgressBar(
                            value: progress.fraction,
                            tint: claimed ? HHTheme.forest : tint,
                            height: 5
                        )
                        Text("\(min(progress.current, progress.target))/\(progress.target)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                            .monospacedDigit()
                            .frame(width: 42, alignment: .trailing)
                    }
                    .padding(.top, 1)

                    HStack(spacing: 5) {
                        TagChip("+\(definition.rewardCoins)c", icon: "circle.fill", tint: HHTheme.goldDeep)
                        TagChip("+\(definition.rewardXP) XP", icon: "sparkles", tint: HHTheme.forest)
                        ForEach(Array(definition.rewardItems.keys.sorted().prefix(2)), id: \.self) { itemID in
                            if let item = store.catalog.item(itemID) {
                                TagChip("\(item.emoji) ×\(definition.rewardItems[itemID] ?? 1)", tint: HHTheme.rose)
                            }
                        }
                        Spacer(minLength: 0)

                        if claimed {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark")
                                Text("Claimed")
                            }
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(HHTheme.forest)
                        } else if complete {
                            Button {
                                store.claimAchievement(id: definition.id)
                            } label: {
                                Text("Claim")
                            }
                            .buttonStyle(MiniActionStyle(tint: tint))
                        } else {
                            Text("\(progress.remaining) to go")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(HHTheme.muted)
                        }
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    progress.canClaim ? tint.opacity(0.32) : HHTheme.ink.opacity(0.04),
                    lineWidth: progress.canClaim ? 1.5 : 1
                )
        )
    }

    private var journalNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "How the journal works",
                subtitle: "A few notes from the keeper of the town records.",
                icon: "text.book.closed.fill"
            )
            noteRow("📓", "Progress counts automatically. Come back whenever a badge is ready and claim the reward.")
            noteRow("🗓️", "Some badges take a full season. The long ones are meant to be lived with.")
            noteRow("🎁", "Reward items arrive in your inventory immediately, even if the barn is full.")
            noteRow("🏅", "Every category counts toward the same journal. Claimed badges stay forever.")
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
