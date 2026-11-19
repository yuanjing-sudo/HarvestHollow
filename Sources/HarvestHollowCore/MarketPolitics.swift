import Foundation

// MARK: - Policy baseline

/// The policy settings the exchange has already priced in. Any difference
/// between this snapshot and the current desk settings is what produces a real
/// market reaction, so a tax rise is not a cosmetic slider.
public struct PolicyBaseline: Codable, Equatable, Sendable {
    public var day: Int
    public var taxRate: Double
    public var subsidyRate: Double
    public var publicSpending: Double
    public var tariffRate: Double
    public var interestRate: Double
    public var party: PoliticalParty

    /// The starting settings of a new valley. Factor readouts compare against
    /// this so "tax change" stays meaningful day after day.
    public static let steady = PolicyBaseline(
        day: 0,
        taxRate: 0.17,
        subsidyRate: 0.035,
        publicSpending: 0.16,
        tariffRate: 0.04,
        interestRate: 0.045,
        party: .green
    )

    public init(
        day: Int,
        taxRate: Double,
        subsidyRate: Double,
        publicSpending: Double,
        tariffRate: Double,
        interestRate: Double,
        party: PoliticalParty
    ) {
        self.day = day
        self.taxRate = taxRate
        self.subsidyRate = subsidyRate
        self.publicSpending = publicSpending
        self.tariffRate = tariffRate
        self.interestRate = interestRate
        self.party = party
    }

    public init(economy: ValleyEconomy) {
        self.init(
            day: economy.day,
            taxRate: economy.taxRate,
            subsidyRate: economy.subsidyRate,
            publicSpending: economy.publicSpending,
            tariffRate: economy.tariffRate,
            interestRate: economy.interestRate,
            party: economy.rulingParty
        )
    }

    public var isClean: Bool {
        abs(taxRate - PolicyBaseline.steady.taxRate) < 0.0005
            && abs(subsidyRate - PolicyBaseline.steady.subsidyRate) < 0.0005
            && abs(publicSpending - PolicyBaseline.steady.publicSpending) < 0.0005
            && abs(tariffRate - PolicyBaseline.steady.tariffRate) < 0.0005
    }

    public func differs(from other: PolicyBaseline) -> Double {
        abs(taxRate - other.taxRate) * 4
            + abs(subsidyRate - other.subsidyRate) * 3
            + abs(publicSpending - other.publicSpending) * 2
            + abs(tariffRate - other.tariffRate) * 2
            + abs(interestRate - other.interestRate) * 3
            + (party == other.party ? 0 : 0.4)
    }
}

// MARK: - Policy impact

public enum PolicyImpactKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case incomeTax
    case corporateTax
    case dividendTax
    case subsidy
    case publicSpending
    case tariff
    case interestRate
    case election
    case regulation
    case debtService

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .incomeTax: return "Income & land tax"
        case .corporateTax: return "Corporate tax"
        case .dividendTax: return "Dividend tax"
        case .subsidy: return "Farm & firm subsidies"
        case .publicSpending: return "Public spending"
        case .tariff: return "Import tariffs"
        case .interestRate: return "Policy interest rate"
        case .election: return "Election result"
        case .regulation: return "Regulation & compliance"
        case .debtService: return "Public debt service"
        }
    }

    public var icon: String {
        switch self {
        case .incomeTax: return "percent"
        case .corporateTax: return "building.2.fill"
        case .dividendTax: return "banknote.fill"
        case .subsidy: return "gift.fill"
        case .publicSpending: return "road.lanes"
        case .tariff: return "shippingbox.fill"
        case .interestRate: return "arrow.up.arrow.down"
        case .election: return "checkmark.seal.fill"
        case .regulation: return "doc.text.fill"
        case .debtService: return "creditcard.fill"
        }
    }
}

public struct PolicyImpact: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var kind: PolicyImpactKind
    public var title: String
    public var valueText: String
    /// Coins added to or taken from firms and households each day.
    public var dailyCoins: Double
    /// Estimated effect on the exchange index for the change, in percent.
    public var pricePercent: Double
    public var score: Double
    public var detail: String

    public init(
        id: UUID = UUID(),
        kind: PolicyImpactKind,
        title: String,
        valueText: String,
        dailyCoins: Double,
        pricePercent: Double,
        score: Double,
        detail: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.valueText = valueText
        self.dailyCoins = dailyCoins
        self.pricePercent = pricePercent
        self.score = hhClamp(score, 0, 100)
        self.detail = detail
    }

    public var isBenefit: Bool { pricePercent >= 0 }
}

public struct PolicyImpactReport: Codable, Equatable, Sendable {
    public var day: Int
    public var lines: [PolicyImpact]
    public var dailyCoinImpact: Double
    public var indexPercent: Double
    public var headline: String
    public var verdict: String
    public var baseline: PolicyBaseline

    public init(
        day: Int,
        lines: [PolicyImpact] = [],
        dailyCoinImpact: Double = 0,
        indexPercent: Double = 0,
        headline: String = "",
        verdict: String = "",
        baseline: PolicyBaseline = .steady
    ) {
        self.day = day
        self.lines = lines
        self.dailyCoinImpact = dailyCoinImpact
        self.indexPercent = indexPercent
        self.headline = headline
        self.verdict = verdict
        self.baseline = baseline
    }

    public var isEmpty: Bool { lines.isEmpty }

    public var winners: [PolicyImpact] { lines.filter { $0.pricePercent > 0.05 } }
    public var losers: [PolicyImpact] { lines.filter { $0.pricePercent < -0.05 } }

    public var biggestMover: PolicyImpact? {
        lines.max { abs($0.pricePercent) < abs($1.pricePercent) }
    }
}

// MARK: - Elections

public struct ElectionForecast: Codable, Equatable, Sendable {
    public var shares: [String: Double]
    public var leader: PoliticalParty
    public var daysToVote: Int
    public var note: String

    public init(shares: [String: Double], leader: PoliticalParty, daysToVote: Int, note: String) {
        self.shares = shares
        self.leader = leader
        self.daysToVote = daysToVote
        self.note = note
    }

    public func share(for party: PoliticalParty) -> Double {
        shares[party.rawValue] ?? 0
    }

    public var ordered: [(party: PoliticalParty, share: Double)] {
        PoliticalParty.allCases
            .map { ($0, share(for: $0)) }
            .sorted { $0.1 > $1.1 }
    }
}

// MARK: - Computing the effect of policy

extension ValleyEconomy {
    public var currentPolicy: PolicyBaseline {
        PolicyBaseline(economy: self)
    }

    public var pricedPolicy: PolicyBaseline {
        policyBaseline ?? PolicyBaseline.steady
    }

    /// A live forecast of the next valley vote, based on jobs, prices, services
    /// and the incumbent's record. The exchange reads this and so can the player.
    public var electionForecast: ElectionForecast {
        let green = 0.16 + sustainability * 0.26 + education * 0.08
        let merchants = 0.16 + hhClamp(tradeBalance / 40, -0.2, 0.3) + (1 - taxRate) * 0.24
        let workers = 0.16 + (1 - unemployment) * 0.14 + poverty * 0.22 + (1 - inequality) * 0.05
        let stewards = 0.16 + politicalStability * 0.26
        let total = max(0.2, green + merchants + workers + stewards)
        let shares: [String: Double] = [
            PoliticalParty.green.rawValue: green / total,
            PoliticalParty.merchants.rawValue: merchants / total,
            PoliticalParty.workers.rawValue: workers / total,
            PoliticalParty.stewards.rawValue: stewards / total
        ]
        let leader = PoliticalParty.allCases.max { lhs, rhs in
            (shares[lhs.rawValue] ?? 0) < (shares[rhs.rawValue] ?? 0)
        } ?? .green
        let note: String
        if leader == rulingParty {
            note = "\(leader.shortTitle) is favoured to hold the valley."
        } else {
            note = "\(leader.shortTitle) is challenging \(rulingParty.shortTitle) on jobs and prices."
        }
        return ElectionForecast(shares: shares, leader: leader, daysToVote: electionInDays, note: note)
    }

    /// The daily effect of the current policy mix, measured against the policy
    /// the exchange has already priced. Coin figures are real: they are the
    /// amounts leaving firm and household ledgers.
    public func policyImpact(since baseline: PolicyBaseline? = nil) -> PolicyImpactReport {
        let reference = baseline ?? pricedPolicy
        let current = currentPolicy
        var lines: [PolicyImpact] = []

        let firmRevenue = aiBusinesses.reduce(0.0) { $0 + max(0, $1.output * 6.5) }
        let taxTake = gdp * taxRate
        let referenceTaxTake = gdp * reference.taxRate
        let taxDelta = taxTake - referenceTaxTake
        lines.append(
            PolicyImpact(
                kind: .incomeTax,
                title: "Income & land tax at \(Int((taxRate * 100).rounded()))%",
                valueText: "\(Int(taxTake.rounded()))c a day",
                dailyCoins: -taxDelta,
                pricePercent: -taxDelta / max(1, gdp) * 160,
                score: hhClamp(100 - taxRate * 240, 0, 100),
                detail: "Every percentage point shifts \(Int((gdp / 100).rounded()))c a day from households and firms to the treasury."
            )
        )

        let corporateTake = firmRevenue * taxRate * 0.55
        let referenceCorporate = firmRevenue * reference.taxRate * 0.55
        lines.append(
            PolicyImpact(
                kind: .corporateTax,
                title: "Corporate tax on firm profit",
                valueText: "\(Int(corporateTake.rounded()))c a day",
                dailyCoins: -(corporateTake - referenceCorporate),
                pricePercent: -(taxRate - reference.taxRate) * 90,
                score: hhClamp(100 - taxRate * 300, 0, 100),
                detail: "Firms keep \(Int(((1 - taxRate * 0.55) * 100).rounded()))% of gross margin after this line."
            )
        )

        let dividends = investmentMarket.listings.reduce(0.0) {
            $0 + $1.fundamentals.dividendPerShare * $1.sharesOutstanding
        }
        let dividendTax = dividends * taxRate * 0.8
        let referenceDividendTax = dividends * reference.taxRate * 0.8
        lines.append(
            PolicyImpact(
                kind: .dividendTax,
                title: "Dividend tax",
                valueText: "\(Int(dividendTax.rounded()))c a day",
                dailyCoins: -(dividendTax - referenceDividendTax),
                pricePercent: -(taxRate - reference.taxRate) * 55,
                score: hhClamp(100 - taxRate * 220, 0, 100),
                detail: "Shareholders keep \(Int((100 - taxRate * 80).rounded()))c of every coin of dividend."
            )
        )

        let subsidy = gdp * subsidyRate
        let referenceSubsidy = gdp * reference.subsidyRate
        lines.append(
            PolicyImpact(
                kind: .subsidy,
                title: "Farm & firm subsidies",
                valueText: "\(Int(subsidy.rounded()))c a day",
                dailyCoins: subsidy - referenceSubsidy,
                pricePercent: (subsidyRate - reference.subsidyRate) * 260,
                score: hhClamp(subsidyRate * 700, 0, 100),
                detail: "Subsidies land on soil, irrigation and clean energy, lifting yields and firm margins."
            )
        )

        let spending = publicSpendingAmount
        let referenceSpending = gdp * reference.publicSpending
        lines.append(
            PolicyImpact(
                kind: .publicSpending,
                title: "Public spending & services",
                valueText: "\(Int(spending.rounded()))c a day",
                dailyCoins: spending - referenceSpending,
                pricePercent: (publicSpending - reference.publicSpending) * 150,
                score: hhClamp(publicSpending * 260, 0, 100),
                detail: "Public work becomes roads, schools and clinics, then productivity and demand."
            )
        )

        let consumerCost = imports * priceIndex * tariffRate * 0.6
        lines.append(
            PolicyImpact(
                kind: .tariff,
                title: "Tariffs at \(Int((tariffRate * 100).rounded()))%",
                valueText: "\(Int(consumerCost.rounded()))c a day on imports",
                dailyCoins: -consumerCost,
                pricePercent: (tariffRate - reference.tariffRate) * 70 - tariffRate * 22,
                score: hhClamp(100 - tariffRate * 260, 0, 100),
                detail: "Protected firms gain margin; every household pays more at the stall."
            )
        )

        let firmDebt = aiBusinesses.reduce(0.0) { $0 + max(0, $1.capital) * 0.22 }
        let debtCost = firmDebt * max(0, interestRate) / 12
        let referenceDebtCost = firmDebt * max(0, reference.interestRate) / 12
        lines.append(
            PolicyImpact(
                kind: .interestRate,
                title: "Policy rate at \(String(format: "%.1f", interestRate * 100))%",
                valueText: "\(Int(debtCost.rounded()))c a month in firm interest",
                dailyCoins: -(debtCost - referenceDebtCost) / 30,
                pricePercent: -(interestRate - reference.interestRate) * 420,
                score: hhClamp(100 - interestRate * 380, 0, 100),
                detail: "Higher rates raise borrowing costs and discount every future dividend."
            )
        )

        let compliance = Double(aiBusinesses.count) * (2 + corruption * 24 + publicSpending * 8)
        lines.append(
            PolicyImpact(
                kind: .regulation,
                title: "Regulation & compliance",
                valueText: "\(Int(compliance.rounded()))c a day across firms",
                dailyCoins: -compliance,
                pricePercent: -compliance * 0.02,
                score: hhClamp(100 - compliance, 0, 100),
                detail: "Rule-making is a cost, but it also lowers fraud and pollution risk."
            )
        )

        let debtService = publicDebt * max(0, interestRate) / 365
        lines.append(
            PolicyImpact(
                kind: .debtService,
                title: "Public debt service",
                valueText: "\(Int(debtService.rounded()))c a day",
                dailyCoins: -debtService,
                pricePercent: -max(0, debtToGDP - 0.8) * 3,
                score: hhClamp(100 - debtToGDP * 70, 0, 100),
                detail: "Interest on old borrowing competes with every new programme."
            )
        )

        if current.party != reference.party {
            let direction: Double = current.party == .merchants ? 1.4 : current.party == .workers ? -0.8 : 0.6
            lines.append(
                PolicyImpact(
                    kind: .election,
                    title: "\(current.party.shortTitle) takes office",
                    valueText: "Policy reset",
                    dailyCoins: 0,
                    pricePercent: direction,
                    score: 55,
                    detail: "A change of governing party re-prices tax, spending and trade in a single morning."
                )
            )
        }

        let objective = objectiveReaction(reference: reference, current: current)
        let indexPercent = hhClamp(lines.reduce(0) { $0 + $1.pricePercent } + objective, -6, 6)
        let coinImpact = lines.reduce(0) { $0 + $1.dailyCoins }
        let headline: String
        if abs(indexPercent) < 0.15 {
            headline = "Policy is broadly priced in"
        } else if indexPercent > 0 {
            headline = "Policy tailwind: firms gain \(String(format: "%.1f", indexPercent))%"
        } else {
            headline = "Policy headwind: firms lose \(String(format: "%.1f", abs(indexPercent)))%"
        }
        let verdict: String
        switch indexPercent {
        case 2...: verdict = "The exchange loves this budget."
        case 0.4..<2: verdict = "Firms are being treated kindly."
        case -0.4...0.4: verdict = "Markets are shrugging at this budget."
        case -2 ..< -0.4: verdict = "Firms are paying for this budget."
        default: verdict = "The exchange is punishing this budget."
        }

        return PolicyImpactReport(
            day: day,
            lines: lines,
            dailyCoinImpact: coinImpact,
            indexPercent: indexPercent,
            headline: headline,
            verdict: verdict,
            baseline: reference
        )
    }

    /// Spending above the party's platform is a surprise, and surprises move
    /// prices more than levels do.
    private func objectiveReaction(reference: PolicyBaseline, current: PolicyBaseline) -> Double {
        let gap = (current.taxRate - current.party.taxBias) * 3
            + (current.publicSpending - current.party.spendingBias) * 2
            + (current.tariffRate - current.party.tariffBias) * 2
        return -gap * 12
    }

    /// Applies the priced policy change to the tape. Called once per morning,
    /// before prices are struck, so a tax rise is visible in the candles.
    @discardableResult
    mutating func applyPolicyShock(
        to market: inout InvestmentMarket,
        rng: inout GameRNG
    ) -> PolicyImpactReport {
        let reference = policyBaseline ?? PolicyBaseline.steady
        let report = policyImpact(since: reference)
        let material = abs(report.indexPercent) > 0.05
        if material {
            for index in market.listings.indices {
                var listing = market.listings[index]
                guard !listing.isBankrupt else { continue }
                let beta = hhClamp(listing.beta, 0.4, 2.4)
                let policyMove = hhClamp(report.indexPercent / 100 * beta, -0.07, 0.07)
                let move = policyMove + (rng.double01() * 2 - 1) * 0.004
                let previous = listing.sharePrice
                let price = hhClamp(previous * (1 + move), 0.2, 999)
                listing.sharePrice = price
                listing.dailyChange = price - previous
                listing.dailyChangePercent = previous > 0 ? (price - previous) / previous : 0
                listing.priceHistory.append(price)
                listing.priceHistory = Array(listing.priceHistory.suffix(40))
                if var last = listing.bars.last {
                    last.close = price
                    last.high = max(last.high, price)
                    last.low = min(last.low, price)
                    listing.bars[listing.bars.count - 1] = last
                }
                market.listings[index] = listing
            }
            market.lastNotice = "\(report.headline). \(report.verdict)"
        }
        market.policyReport = report
        market.rumour = report.headline
        policyBaseline = PolicyBaseline(economy: self)
        return report
    }
}
