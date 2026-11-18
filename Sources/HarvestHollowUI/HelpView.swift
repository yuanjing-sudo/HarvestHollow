#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Help

public struct HelpView: View {
    @State private var expandedID: String? = "start"

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                TownScreenHeader(
                    title: "How to Play",
                    subtitle: "Everything you need to make a small farm feel like home.",
                    icon: "questionmark.circle.fill",
                    accent: HHTheme.forest
                )

                quickStart
                systems
                controls
                faq
                credits
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(HHTheme.cream)
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    // MARK: Quick start

    private var quickStart: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    "Your first morning",
                    subtitle: "A five-minute start that leaves plenty of room to wander.",
                    icon: "sunrise.fill"
                )

                stepRow("1", "Plant a seed", "Open the Farm tab, tap an empty plot, choose a seed, and plant it.", HHTheme.forest)
                stepRow("2", "Water it", "Tap the plot again and choose Water. Rainy days do this for you overnight.", Color(hex: "4F6D8A"))
                stepRow("3", "Wait and harvest", "Crops grow in real time. The little progress ring fills as the day passes.", HHTheme.goldDeep)
                stepRow("4", "Sell at market", "Take produce to the Market tab. Prices drift a little each day.", HHTheme.terracotta)
                stepRow("5", "Meet the town", "The Town tab holds the pond, kitchen, almanac, collection, and achievements.", HHTheme.lavender)
            }
        }
    }

    private func stepRow(_ number: String, _ title: String, _ detail: String, _ tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(tint, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.hhHeadline(12.5))
                    .foregroundStyle(HHTheme.ink)
                Text(detail)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Systems

    private var systems: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "The farm, one corner at a time",
                subtitle: "Tap a card to read more. Nothing here is timed or missable.",
                icon: "map.fill"
            )

            ForEach(helpTopics) { topic in
                topicCard(topic)
            }
        }
    }

    private var helpTopics: [HelpTopic] {
        [
            HelpTopic(
                id: "farm",
                icon: "leaf.fill",
                tint: HHTheme.forest,
                title: "Fields & crops",
                summary: "Plant, water, fertilize, and harvest across 24 plots.",
                bullets: [
                    "Six plots start unlocked. Buy the rest from the farm header when you can afford them.",
                    "Watered crops grow continuously, even while the game is closed for up to eight hours.",
                    "Fertilizer speeds growth by half and adds one extra item to the harvest.",
                    "Rain waters every growing crop overnight.",
                    "Crop mastery adds a small sale bonus and never resets."
                ]
            ),
            HelpTopic(
                id: "barn",
                icon: "pawprint.fill",
                tint: HHTheme.terracotta,
                title: "Barn & animals",
                summary: "Adopt animals, keep them fed, and collect their gifts.",
                bullets: [
                    "Each animal eats one feed cycle and then produces for a while.",
                    "Happiness affects production speed. A comfortable animal works faster.",
                    "Pet animals for affection. Affection gives a small production bonus.",
                    "Animals wait in a cozy queue when their storage is full.",
                    "There are eight pens in total, two unlocked from the start."
                ]
            ),
            HelpTopic(
                id: "market",
                icon: "cart.fill",
                tint: HHTheme.goldDeep,
                title: "Market & orders",
                summary: "Sell goods, buy supplies, and fill the daily order.",
                bullets: [
                    "Prices drift every in-game day, but never below a fair floor.",
                    "Coins earned count toward achievements and levels.",
                    "The daily order asks for one item and pays a bonus.",
                    "Furniture and house themes are also sold at market.",
                    "Seeds and furniture cannot be sold back; everything else can."
                ]
            ),
            HelpTopic(
                id: "home",
                icon: "sofa.fill",
                tint: HHTheme.lavender,
                title: "Cottage & comfort",
                summary: "Place furniture, change themes, and make the house yours.",
                bullets: [
                    "Comfort slowly improves the price of everything you sell.",
                    "Furniture can be moved and stored without being destroyed.",
                    "House themes change the floor, walls, and mood of the room.",
                    "The kitchen is reached through the Town tab and uses crops, fish, and barn goods."
                ]
            ),
            HelpTopic(
                id: "pond",
                icon: "fish.fill",
                tint: Color(hex: "4F6D8A"),
                title: "Hollow Pond",
                summary: "Cast a line, fill the fish journal, and upgrade your rod.",
                bullets: [
                    "Each cast uses one pond bait, sold at market.",
                    "Rod upgrades unlock new fish and improve rare chances.",
                    "Weather, time of day, and a fishing meal all matter.",
                    "Some fish are legendary. The journal keeps your best weight.",
                    "A perfect cast is a small random bonus to weight and XP.",
                    "The pond sits in Town. A shortcut card on the Farm takes you straight there."
                ]
            ),
            HelpTopic(
                id: "kitchen",
                icon: "fork.knife",
                tint: HHTheme.terracotta,
                title: "Cottage Kitchen",
                summary: "Cook recipes for buffs, coins, and collection pages.",
                bullets: [
                    "Recipes unlock with farmer levels.",
                    "Cooking consumes ingredients and puts a dish in the pantry.",
                    "Eat a dish to gain a timed growth, market, or fishing buff.",
                    "Dishes can also be sold, but eating usually pays back more.",
                    "The biggest feast requires a legendary fish and rare crops."
                ]
            ),
            HelpTopic(
                id: "almanac",
                icon: "calendar",
                tint: HHTheme.goldDeep,
                title: "Almanac & seasons",
                summary: "Read the sky, the calendar, and the market board.",
                bullets: [
                    "A season lasts seven in-game days. The last day is a festival.",
                    "Tomorrow's weather is always shown, so you can plan.",
                    "Weather changes crop growth speed and fishing odds.",
                    "Crop mastery and current market prices live here.",
                    "The calendar is cosmetic: crops are never locked out by season."
                ]
            ),
            HelpTopic(
                id: "achievements",
                icon: "rosette",
                tint: HHTheme.forest,
                title: "Achievements & gifts",
                summary: "Long-term goals and a little parcel on the doorstep.",
                bullets: [
                    "Achievements track farming, barn, market, pond, home, and story progress.",
                    "Claim each reward manually when it is ready.",
                    "There are thirty achievements in total.",
                    "The daily gift cycles through seven days and rewards a streak.",
                    "Missing a day resets the streak to one."
                ]
            ),
            HelpTopic(
                id: "economy",
                icon: "chart.line.uptrend.xyaxis",
                tint: HHTheme.forest,
                title: "The Valley Ledger",
                summary: "A living economy that grows more complex as you level.",
                bullets: [
                    "Level 1 shows only the basics: soil, crops, weather, demand, prices, and your progress.",
                    "New factors unlock at levels 4, 8, 12, 16, and 20.",
                    "Soil and weather feed yields; yields and imports feed supply; supply and demand set prices.",
                    "Prices feed wages, confidence, interest, migration, and public policy.",
                    "At level 8 you can set taxes, subsidies, spending, tariffs, and the policy rate.",
                    "Eight investments and credit let you reshape the valley; debt compounds daily.",
                    "The Hollow Exchange lists every AI firm. Share prices move with profit, debt, growth, reputation, and fraud risk.",
                    "Buy or sell shares from a firm's books. Margin unlocks at level 4 (2x) and level 8 (3x); interest accrues daily.",
                    "A margin call forces a sale when equity falls below 25% of the position value.",
                    "Crime and fraud create court cases, damage firm capital, and move share prices. Fund audits at level 8.",
                    "AI firms hire, invest, pollute, and can fail. Elections change policy biases.",
                    "Every shock is recorded in the ledger and can echo for many days."
                ]
            ),
            HelpTopic(
                id: "saving",
                icon: "externaldrive.fill",
                tint: HHTheme.muted,
                title: "Saving & backups",
                summary: "The farm saves itself and can be exported.",
                bullets: [
                    "Autosave runs after every action and when the app goes to the background.",
                    "Offline progress is simulated for up to eight hours.",
                    "Settings has a backup save slot and a reset option.",
                    "Export a base64 code to move the farm to another device.",
                    "Import codes are validated before replacing the current farm."
                ]
            )
        ]
    }

    private func topicCard(_ topic: HelpTopic) -> some View {
        let expanded = expandedID == topic.id
        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                    expandedID = expanded ? nil : topic.id
                }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: topic.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(topic.tint)
                        .frame(width: 28, height: 28)
                        .background(topic.tint.opacity(0.1), in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(topic.title)
                            .font(.hhHeadline(13))
                            .foregroundStyle(HHTheme.ink)
                        Text(topic.summary)
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(HHTheme.muted)
                }
                .padding(11)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(topic.bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: 7) {
                            Circle()
                                .fill(topic.tint)
                                .frame(width: 4, height: 4)
                                .padding(.top, 5)
                            Text(bullet)
                                .font(.hhBody(11.5))
                                .foregroundStyle(HHTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 13)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(HHTheme.paper.opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(topic.tint.opacity(expanded ? 0.18 : 0.07), lineWidth: 1)
        )
    }

    // MARK: Controls

    private var controls: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    "Controls & navigation",
                    subtitle: "Everything is a tap. There are no hidden gestures.",
                    icon: "hand.tap.fill"
                )
                TownInfoRow(icon: "square.grid.3x3.fill", title: "Farm plots", value: "Tap to select", tint: HHTheme.forest)
                TownInfoRow(icon: "arrow.left.arrow.right", title: "Tabs", value: "Bottom bar", tint: HHTheme.terracotta)
                TownInfoRow(icon: "building.columns.fill", title: "Town", value: "Hub of activities", tint: HHTheme.lavender)
                TownInfoRow(icon: "cloud.sun.fill", title: "Weather", value: "Tap the header chip", tint: HHTheme.goldDeep)
                TownInfoRow(icon: "gearshape.fill", title: "Settings", value: "Top-right gear", tint: HHTheme.muted)
            }
        }
    }

    // MARK: FAQ

    private var faq: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "Small questions",
                subtitle: "The things most farmers ask in the first week.",
                icon: "text.bubble.fill"
            )
            faqRow("Will my crops die if I stop playing?", "No. They wait. Growth and animal production are simulated for up to eight hours while the game is closed.")
            faqRow("Can I lose a save?", "The game keeps a primary save and a backup. Settings also lets you export a code.")
            faqRow("Do seasons lock crops?", "No. Seasons are flavour and festival days. Every crop can be grown in every season.")
            faqRow("What happens when a dish buff expires?", "The effect simply ends. Nothing else is lost, and another meal can replace it at any time.")
            faqRow("How do I get the legendary fish?", "Upgrade the rod to level five, fish in the right weather and time, and bring bait. A fishing meal helps.")
            faqRow("Is there an ending?", "The ten-chapter story has a conclusion, but the farm keeps going afterward.")
        }
    }

    private func faqRow(_ question: String, _ answer: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(question)
                .font(.hhHeadline(12.5))
                .foregroundStyle(HHTheme.ink)
            Text(answer)
                .font(.hhBody(11.5))
                .foregroundStyle(HHTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(HHTheme.paper.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Credits

    private var credits: some View {
        VStack(spacing: 4) {
            Text("Harvest Hollow")
                .font(.hhHeadline(15))
                .foregroundStyle(HHTheme.ink)
            Text("A cozy farming game written entirely in Swift.")
                .font(.hhCaption(10.5))
                .foregroundStyle(HHTheme.muted)
            Text("Pixel art is drawn from individual coloured squares. No external game engine.")
                .font(.hhCaption(9.5))
                .foregroundStyle(HHTheme.muted.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Help topic model

public struct HelpTopic: Identifiable {
    public let id: String
    public let icon: String
    public let tint: Color
    public let title: String
    public let summary: String
    public let bullets: [String]

    public init(
        id: String,
        icon: String,
        tint: Color,
        title: String,
        summary: String,
        bullets: [String]
    ) {
        self.id = id
        self.icon = icon
        self.tint = tint
        self.title = title
        self.summary = summary
        self.bullets = bullets
    }
}
#endif
