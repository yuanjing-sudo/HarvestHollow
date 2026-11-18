#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Valley Ledger

/// A living dashboard for the whole valley economy. It starts with soil and
/// weather, then reveals labour, markets, credit, policy, trade, AI agents, and
/// systemic shocks as the player levels up.
public struct EconomyView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selectedFactor: EconomyFactor?
    @State private var selectedBusiness: BusinessListing?
    @State private var showGuide = false

    public init() {}

    private var economy: ValleyEconomy { store.state.economy }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                pulseGrid
                dailyReportCard
                LedgerExchangeSection(onSelect: { selectedBusiness = $0 })
                LedgerJusticeSection(onInspect: { selectedBusiness = $0 })
                unlockBanner
                if let report = economy.lastReport, !report.warnings.isEmpty {
                    warningCard(report)
                }
                factorSections
                policySection
                investmentSection
                financeSection
                agentSection
                eventSection
                guideFooter
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 34)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedFactor) { factor in
            EconomyFactorDetailView(factor: factor, economy: economy)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showGuide) {
            EconomyGuideView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedBusiness) { listing in
            BusinessDetailView(businessID: listing.businessID)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header

    private var header: some View {
        CozyCard(padding: 16) {
            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [HHTheme.forest, HHTheme.leaf],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 25, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 7) {
                            Text("Valley Ledger")
                                .font(.hhTitle(23))
                                .foregroundStyle(HHTheme.ink)
                            Text(economy.tier.shortTitle.uppercased())
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(HHTheme.leaf, in: Capsule())
                        }
                        Text(economy.tier.blurb)
                            .font(.hhCaption(12))
                            .foregroundStyle(HHTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button {
                        showGuide = true
                    } label: {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(HHTheme.forest)
                            .frame(width: 36, height: 36)
                            .background(HHTheme.forest.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    LedgerMetric(
                        title: "OUTPUT",
                        value: "\(Int(economy.gdp))c",
                        icon: "chart.bar.fill",
                        tint: HHTheme.forest
                    )
                    LedgerMetric(
                        title: "PRICES",
                        value: String(format: "%.2f", economy.priceIndex),
                        icon: "tag.fill",
                        tint: economy.inflation > 0.08 ? HHTheme.terracotta : HHTheme.goldDeep
                    )
                    LedgerMetric(
                        title: "JOBS",
                        value: "\(Int(((1 - economy.unemployment) * 100).rounded()))%",
                        icon: "person.3.fill",
                        tint: economy.unemployment > 0.12 ? HHTheme.terracotta : HHTheme.sky
                    )
                    LedgerMetric(
                        title: "HAPPY",
                        value: "\(Int((economy.happiness * 100).rounded()))%",
                        icon: "face.smiling.fill",
                        tint: economy.happiness < 0.4 ? HHTheme.terracotta : HHTheme.leaf
                    )
                }

                HStack(spacing: 8) {
                    LedgerMetric(
                        title: "HVI",
                        value: String(format: "%.1f", economy.investmentMarket.marketIndex),
                        icon: "chart.line.uptrend.xyaxis",
                        tint: HHTheme.goldDeep
                    )
                    LedgerMetric(
                        title: "PORTFOLIO",
                        value: "\(Int(economy.investmentMarket.equity.rounded()))c",
                        icon: "briefcase.fill",
                        tint: economy.investmentMarket.unrealizedProfit >= 0 ? HHTheme.forest : HHTheme.terracotta
                    )
                    LedgerMetric(
                        title: "P&L",
                        value: "\(economy.investmentMarket.unrealizedProfit >= 0 ? "+" : "")\(Int(economy.investmentMarket.unrealizedProfit.rounded()))c",
                        icon: economy.investmentMarket.unrealizedProfit >= 0 ? "arrow.up.right" : "arrow.down.right",
                        tint: economy.investmentMarket.unrealizedProfit >= 0 ? HHTheme.forest : HHTheme.terracotta
                    )
                    LedgerMetric(
                        title: "CRIME",
                        value: "\(Int((economy.crime * 100).rounded()))%",
                        icon: "shield.lefthalf.filled",
                        tint: economy.crime > 0.3 ? HHTheme.terracotta : HHTheme.forest
                    )
                }

                tierProgress
            }
        }
    }

    private var tierProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Level \(store.state.level) · \(economy.unlockedFactorCount)/\(EconomyFactor.allCases.count) factors")
                    .font(.hhCaption(11))
                    .foregroundStyle(HHTheme.muted)
                Spacer(minLength: 0)
                if let next = economy.nextTier, let level = economy.nextTierLevel {
                    Text("\(next.title) at Lv \(level)")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.forest)
                } else {
                    Text("Every layer is open")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.forest)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(HHTheme.paperDeep)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [HHTheme.leaf, HHTheme.forest],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * economy.tierProgress))
                }
            }
            .frame(height: 7)
        }
    }

    // MARK: Pulse

    private var pulseGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "Valley pulse",
                subtitle: "Four interlinked signals. None of them move alone.",
                icon: "waveform.path.ecg",
                accent: HHTheme.forest
            )
            HStack(spacing: 9) {
                EconomySparkCard(
                    title: "Output",
                    value: "\(Int(economy.gdp))c",
                    values: economy.history.map(\.gdp),
                    tint: HHTheme.forest,
                    icon: "chart.bar.fill"
                )
                EconomySparkCard(
                    title: "Prices",
                    value: String(format: "%.2f", economy.priceIndex),
                    values: economy.history.map(\.priceIndex),
                    tint: HHTheme.goldDeep,
                    icon: "tag.fill"
                )
                EconomySparkCard(
                    title: "Wellbeing",
                    value: "\(Int((economy.happiness * 100).rounded()))%",
                    values: economy.history.map { $0.happiness * 100 },
                    tint: HHTheme.leaf,
                    icon: "heart.fill"
                )
                EconomySparkCard(
                    title: "Pollution",
                    value: "\(Int((economy.pollution * 100).rounded()))%",
                    values: economy.history.map { $0.pollution * 100 },
                    tint: HHTheme.terracotta,
                    icon: "smoke.fill",
                    invert: true
                )
            }
        }
    }

    // MARK: Daily report

    private var dailyReportCard: some View {
        CozyCard(padding: 13) {
            if let report = economy.lastReport {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Image(systemName: report.event?.kind.icon ?? "newspaper.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(report.event?.kind.isPositive == false ? HHTheme.terracotta : HHTheme.forest)
                        Text(report.headline)
                            .font(.hhHeadline(14))
                            .foregroundStyle(HHTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                        Text("DAY \(report.day)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Text(report.summary)
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let event = report.event {
                        Text(event.detail)
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.ink.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 8) {
                        LedgerMiniStat(
                            title: "DEMAND",
                            value: "\(Int(report.demand))",
                            tint: HHTheme.terracotta
                        )
                        LedgerMiniStat(
                            title: "SUPPLY",
                            value: "\(Int(report.supply))",
                            tint: HHTheme.sky
                        )
                        LedgerMiniStat(
                            title: "BUDGET",
                            value: "\(report.governmentBalance >= 0 ? "+" : "")\(Int(report.governmentBalance))c",
                            tint: report.governmentBalance >= 0 ? HHTheme.forest : HHTheme.terracotta
                        )
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "sunrise.fill")
                        .foregroundStyle(HHTheme.goldDeep)
                    Text("The first ledger report arrives after the next in-game morning. Plant, water, and watch the pulse.")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: Unlocks & warnings

    private var unlockBanner: some View {
        CozyCard(padding: 13) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: economy.nextTier?.icon ?? "checkmark.seal.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(HHTheme.goldDeep)
                    .frame(width: 38, height: 38)
                    .background(HHTheme.gold.opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(economy.nextTier == nil ? "The whole ledger is open" : "Next economic layer")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    Text(unlockCopy)
                        .font(.hhCaption(12))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var unlockCopy: String {
        if let next = economy.nextTier, let level = economy.nextTierLevel {
            let locked = EconomyFactor.allCases.filter { !$0.isUnlocked(level: store.state.level) }
            let soon = locked.filter { $0.minimumLevel == level }.prefix(3).map(\.shortTitle)
            let hint = soon.isEmpty ? "" : " Opening: \(soon.joined(separator: ", "))."
            let days = max(0, level - store.state.level)
            return "Reach level \(level) to become a \(next.title). \(days) level\(days == 1 ? "" : "s") away." + hint
        }
        return "Every factor is unlocked. Your choices now set the long-run path of the valley."
    }

    private func warningCard(_ report: EconomyReport) -> some View {
        CozyCard(padding: 13) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(HHTheme.terracotta)
                    Text("Watchlist")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    Spacer(minLength: 0)
                    Text("DAY \(report.day)")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
                ForEach(Array(report.warnings.prefix(3).enumerated()), id: \.offset) { _, warning in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(HHTheme.terracotta)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        Text(warning)
                            .font(.hhCaption(12))
                            .foregroundStyle(HHTheme.terracottaDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: Factors

    private var factorSections: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                SectionHeader(
                    "Every factor",
                    subtitle: "Tap an unlocked tile to see what feeds it and what it feeds.",
                    icon: "square.grid.2x2.fill",
                    accent: HHTheme.terracotta
                )
                Spacer(minLength: 0)
                Text("\(economy.unlockedFactorCount)/\(EconomyFactor.allCases.count)")
                    .font(.hhCaption(11))
                    .foregroundStyle(HHTheme.muted)
            }
            ForEach(EconomyFactorCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Image(systemName: category.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(HHTheme.forest)
                        Text(category.title)
                            .font(.hhHeadline(15))
                            .foregroundStyle(HHTheme.ink)
                        Spacer(minLength: 0)
                        Text("\(economy.readings(in: category).filter(\.isUnlocked).count)/\(economy.readings(in: category).count)")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Text(category.blurb)
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(economy.readings(in: category)) { reading in
                            Button {
                                if reading.isUnlocked {
                                    selectedFactor = reading.factor
                                }
                            } label: {
                                EconomyFactorTile(reading: reading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

extension EconomyView {
    // MARK: Policy

    private var policySection: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 11) {
                SectionHeader(
                    "Policy desk",
                    subtitle: "Taxes, subsidies, services, trade, and money all pull on each other.",
                    icon: "building.columns.fill",
                    accent: HHTheme.forest
                )

                if economy.isUnlocked(.taxationSubsidies) {
                    LedgerPolicyRow(
                        title: "Income & land tax",
                        detail: "Funds services; reduces inequality, can slow firms.",
                        value: economy.taxRate,
                        tint: HHTheme.forest,
                        canDecrease: economy.taxRate > 0.05,
                        canIncrease: economy.taxRate < 0.4,
                        onDecrease: { store.setEconomyTaxRate(economy.taxRate - 0.01) },
                        onIncrease: { store.setEconomyTaxRate(economy.taxRate + 0.01) }
                    )
                    LedgerPolicyRow(
                        title: "Farm & clean-energy subsidy",
                        detail: "Supports yields and renewables; strains the budget.",
                        value: economy.subsidyRate,
                        tint: HHTheme.leaf,
                        canDecrease: economy.subsidyRate > 0,
                        canIncrease: economy.subsidyRate < 0.3,
                        onDecrease: { store.setEconomySubsidyRate(economy.subsidyRate - 0.01) },
                        onIncrease: { store.setEconomySubsidyRate(economy.subsidyRate + 0.01) }
                    )
                    LedgerPolicyRow(
                        title: "Public spending",
                        detail: "Builds roads, schools, clinics, and public jobs.",
                        value: economy.publicSpending,
                        tint: HHTheme.sky,
                        canDecrease: economy.publicSpending > 0.05,
                        canIncrease: economy.publicSpending < 0.4,
                        onDecrease: { store.setEconomyPublicSpending(economy.publicSpending - 0.01) },
                        onIncrease: { store.setEconomyPublicSpending(economy.publicSpending + 0.01) }
                    )
                } else {
                    lockedPolicyHint(
                        title: "Policy unlocks at level 8",
                        detail: "Village taxes, subsidies, and public services arrive with the Market Town tier."
                    )
                }

                if economy.isUnlocked(.importsExports) {
                    LedgerPolicyRow(
                        title: "Tariff on imports",
                        detail: "Protects local firms; raises prices and invites retaliation.",
                        value: economy.tariffRate,
                        tint: HHTheme.terracotta,
                        canDecrease: economy.tariffRate > 0,
                        canIncrease: economy.tariffRate < 0.35,
                        onDecrease: { store.setEconomyTariffRate(economy.tariffRate - 0.01) },
                        onIncrease: { store.setEconomyTariffRate(economy.tariffRate + 0.01) }
                    )
                }

                if economy.isUnlocked(.currencyInterest) {
                    LedgerPolicyRow(
                        title: "Valley policy rate",
                        detail: "Higher rates cool prices, strengthen coin, and squeeze borrowers.",
                        value: economy.interestRate,
                        tint: HHTheme.goldDeep,
                        canDecrease: economy.interestRate > -0.01,
                        canIncrease: economy.interestRate < 0.25,
                        onDecrease: { store.setEconomyInterestRate(economy.interestRate - 0.0025) },
                        onIncrease: { store.setEconomyInterestRate(economy.interestRate + 0.0025) }
                    )
                }

                HStack(spacing: 8) {
                    LedgerMiniStat(
                        title: "BUDGET",
                        value: "\(economy.governmentBalance >= 0 ? "+" : "")\(Int(economy.governmentBalance))c",
                        tint: economy.governmentBalance >= 0 ? HHTheme.forest : HHTheme.terracotta
                    )
                    LedgerMiniStat(
                        title: "PUBLIC DEBT",
                        value: "\(Int(economy.publicDebt))c",
                        tint: HHTheme.soil
                    )
                    LedgerMiniStat(
                        title: "STABILITY",
                        value: "\(Int((economy.politicalStability * 100).rounded()))%",
                        tint: HHTheme.lavender
                    )
                }
            }
        }
    }

    private func lockedPolicyHint(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "lock.fill")
                .foregroundStyle(HHTheme.muted)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hhHeadline(13))
                    .foregroundStyle(HHTheme.ink)
                Text(detail)
                    .font(.hhCaption(11))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(HHTheme.paperDeep.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Investments

    private var investmentSection: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom) {
                    SectionHeader(
                        "Invest in the valley",
                        subtitle: "Spend farm coins to shift the production function.",
                        icon: "hammer.fill",
                        accent: HHTheme.goldDeep
                    )
                    Spacer(minLength: 0)
                    Text("\(store.state.coins)c")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.goldDeep)
                }
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(EconomyInvestment.allCases) { investment in
                        Button {
                            store.investInEconomy(investment)
                        } label: {
                            LedgerInvestmentTile(
                                investment: investment,
                                unlocked: store.state.level >= investment.minimumLevel,
                                affordable: store.state.coins >= investment.cost
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Finance

    private var financeSection: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom) {
                    SectionHeader(
                        "Credit & debt",
                        subtitle: "Borrow to invest, but interest compounds every day.",
                        icon: "creditcard.fill",
                        accent: HHTheme.terracotta
                    )
                    Spacer(minLength: 0)
                    Text("\(economy.creditScore)")
                        .font(.hhTitle(20))
                        .foregroundStyle(economy.creditScore >= 650 ? HHTheme.forest : HHTheme.terracotta)
                }

                if economy.isUnlocked(.loansCreditDebt) {
                    HStack(spacing: 8) {
                        ForEach([100.0, 250.0, 500.0], id: \.self) { amount in
                            Button {
                                store.takeEconomyLoan(amount: amount)
                            } label: {
                                VStack(spacing: 2) {
                                    Text("Borrow")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    Text("\(Int(amount))c")
                                        .font(.hhHeadline(13))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    (economy.canBorrow(amount) ? HHTheme.forest : HHTheme.muted).opacity(0.9),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!economy.canBorrow(amount))
                        }
                    }

                    if economy.loans.isEmpty {
                        Text("No active loans. Credit is a tool, not a trophy.")
                            .font(.hhCaption(11))
                            .foregroundStyle(HHTheme.muted)
                    } else {
                        ForEach(economy.loans) { loan in
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(loan.purpose)
                                        .font(.hhCaption(12))
                                        .foregroundStyle(HHTheme.ink)
                                    Text("Balance \(Int(loan.balance))c · \(Int((loan.annualRate * 100).rounded()))% APR")
                                        .font(.hhCaption(10))
                                        .foregroundStyle(HHTheme.muted)
                                }
                                Spacer(minLength: 0)
                                Button("Repay") {
                                    store.repayEconomyLoan(
                                        id: loan.id,
                                        amount: min(loan.balance, Double(store.state.coins))
                                    )
                                }
                                .font(.hhCaption(11))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(HHTheme.forest, in: Capsule())
                                .buttonStyle(.plain)
                            }
                            .padding(9)
                            .background(HHTheme.paperDeep.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    HStack(spacing: 8) {
                        LedgerMiniStat(title: "OWED", value: "\(Int(economy.totalLoanBalance))c", tint: HHTheme.terracotta)
                        LedgerMiniStat(title: "RISK", value: "\(Int((economy.bankruptcyRisk * 100).rounded()))%", tint: HHTheme.goldDeep)
                        LedgerMiniStat(title: "NET WORTH", value: "\(Int(economy.netWorth))c", tint: HHTheme.forest)
                    }
                } else {
                    lockedPolicyHint(
                        title: "Credit opens at level 8",
                        detail: "Loans appear with the Market Town tier. Until then, invest from daily earnings."
                    )
                }
            }
        }
    }
}

extension EconomyView {
    // MARK: Agents

    private var agentSection: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    "AI residents & firms",
                    subtitle: "Every firm hires, prices, invests, and pollutes. Every resident reacts.",
                    icon: "cpu.fill",
                    accent: HHTheme.lavender
                )

                if economy.isUnlocked(.aiCitizensBusinesses) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(economy.aiBusinesses) { firm in
                                Button {
                                    if let listing = economy.investmentMarket.listing(for: firm.id) {
                                        selectedBusiness = listing
                                    }
                                } label: {
                                    LedgerFirmTile(
                                        firm: firm,
                                        listing: economy.investmentMarket.listing(for: firm.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(economy.aiCitizens) { citizen in
                                LedgerCitizenChip(citizen: citizen)
                            }
                        }
                    }
                } else {
                    lockedPolicyHint(
                        title: "Agent detail wakes at level 16",
                        detail: "Local traders still respond to prices now. The full AI roster and its decisions appear in the Regional tier."
                    )
                    HStack(spacing: 8) {
                        LedgerMiniStat(title: "FIRMS", value: "\(economy.businessCount)", tint: HHTheme.lavender)
                        LedgerMiniStat(title: "RESIDENTS", value: "\(economy.population)", tint: HHTheme.sky)
                        LedgerMiniStat(title: "EMPLOYED", value: "\(economy.employed)/\(economy.workforce)", tint: HHTheme.forest)
                    }
                }
            }
        }
    }

    // MARK: Events

    private var eventSection: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeader(
                    "Long memory",
                    subtitle: "Shocks leave traces in soil, debt, trust, and prices.",
                    icon: "clock.arrow.circlepath",
                    accent: HHTheme.terracotta
                )
                if economy.eventHistory.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(HHTheme.leaf)
                        Text("No shocks recorded yet. Quiet days build reserves for the noisy ones.")
                            .font(.hhCaption(11))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .padding(10)
                    .background(HHTheme.paperDeep.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(economy.eventHistory.prefix(5)) { event in
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: event.kind.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(event.kind.isPositive ? HHTheme.forest : HHTheme.terracotta)
                                .frame(width: 28, height: 28)
                                .background(
                                    (event.kind.isPositive ? HHTheme.forest : HHTheme.terracotta).opacity(0.1),
                                    in: Circle()
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text(event.title)
                                        .font(.hhCaption(12))
                                        .foregroundStyle(HHTheme.ink)
                                    Text("DAY \(event.day)")
                                        .font(.system(size: 7, weight: .black, design: .rounded))
                                        .foregroundStyle(HHTheme.muted)
                                }
                                Text(event.detail)
                                    .font(.hhCaption(10))
                                    .foregroundStyle(HHTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    // MARK: Footer

    private var guideFooter: some View {
        Button {
            showGuide = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HHTheme.forest)
                VStack(alignment: .leading, spacing: 2) {
                    Text("How the valley connects")
                        .font(.hhHeadline(14))
                        .foregroundStyle(HHTheme.ink)
                    Text("See the full dependency web and the unlock timeline.")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HHTheme.muted)
            }
            .padding(14)
            .background(HHTheme.paper.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(HHTheme.forest.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
