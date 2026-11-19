import Foundation

// MARK: - Rivals

public enum CompetitorStrategy: String, Codable, CaseIterable, Sendable, Identifiable {
    case undercut
    case premium
    case volume
    case niche
    case innovator
    case consolidator

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .undercut: return "Price cutter"
        case .premium: return "Premium brand"
        case .volume: return "Volume player"
        case .niche: return "Niche specialist"
        case .innovator: return "Innovator"
        case .consolidator: return "Consolidator"
        }
    }

    public var blurb: String {
        switch self {
        case .undercut:
            return "Chases market share with cheaper prices, even at the cost of margin."
        case .premium:
            return "Protects price and reputation, and spends on quality instead of discounts."
        case .volume:
            return "Runs the sheds full and wins on throughput, vulnerable to input costs."
        case .niche:
            return "Small, loyal customer base and unusually steady takings."
        case .innovator:
            return "Reinvests every coin into technology and new products."
        case .consolidator:
            return "Buys weak rivals and grows by acquisition more than by trade."
        }
    }

    public var icon: String {
        switch self {
        case .undercut: return "scissors"
        case .premium: return "crown.fill"
        case .volume: return "shippingbox.fill"
        case .niche: return "leaf.circle.fill"
        case .innovator: return "lightbulb.fill"
        case .consolidator: return "building.2.crop.circle"
        }
    }

    public var pricingBias: Double {
        switch self {
        case .undercut: return 0.9
        case .premium: return 1.15
        case .volume: return 0.97
        case .niche: return 1.05
        case .innovator: return 1.08
        case .consolidator: return 1.02
        }
    }

    public var rndBias: Double {
        switch self {
        case .innovator: return 2.2
        case .premium: return 1.2
        case .volume: return 0.9
        case .undercut: return 0.6
        case .niche: return 1.0
        case .consolidator: return 1.3
        }
    }

    public var hiringBias: Double {
        switch self {
        case .volume: return 1.8
        case .consolidator: return 1.2
        case .undercut: return 1.1
        case .premium: return 1.0
        case .niche: return 0.7
        case .innovator: return 0.9
        }
    }

    public var shortBlurb: String {
        switch self {
        case .undercut: return "Cheap prices, thin margin"
        case .premium: return "Brand over volume"
        case .volume: return "Throughput at any cost"
        case .niche: return "Small and loyal"
        case .innovator: return "R&D first"
        case .consolidator: return "Grows by buying"
        }
    }
}

public enum CompetitorActionKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case priceCut
    case priceRise
    case hiring
    case layoffs
    case productLaunch
    case marketingBlitz
    case supplierDeal
    case debtRaise
    case buyback
    case hostileBid
    case auditDefence
    case expansion
    case retreat

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .priceCut: return "Price cut"
        case .priceRise: return "Price rise"
        case .hiring: return "Hiring spree"
        case .layoffs: return "Layoffs"
        case .productLaunch: return "Product launch"
        case .marketingBlitz: return "Marketing blitz"
        case .supplierDeal: return "Supplier deal"
        case .debtRaise: return "Debt raise"
        case .buyback: return "Share buyback"
        case .hostileBid: return "Hostile bid"
        case .auditDefence: return "Audit defence"
        case .expansion: return "Expansion"
        case .retreat: return "Retreat"
        }
    }

    public var icon: String {
        switch self {
        case .priceCut: return "arrow.down.forward"
        case .priceRise: return "arrow.up.forward"
        case .hiring: return "person.badge.plus"
        case .layoffs: return "person.badge.minus"
        case .productLaunch: return "sparkles"
        case .marketingBlitz: return "megaphone.fill"
        case .supplierDeal: return "handshake.fill"
        case .debtRaise: return "creditcard.fill"
        case .buyback: return "arrow.triangle.2.circlepath"
        case .hostileBid: return "bolt.fill"
        case .auditDefence: return "checkmark.shield.fill"
        case .expansion: return "arrow.up.right.square.fill"
        case .retreat: return "arrow.down.left.square.fill"
        }
    }

    /// Rough price effect of the action on the firm that took it, in percent.
    public var priceImpact: Double {
        switch self {
        case .priceCut: return -1.6
        case .priceRise: return 0.9
        case .hiring: return 0.5
        case .layoffs: return 0.3
        case .productLaunch: return 2.2
        case .marketingBlitz: return 0.7
        case .supplierDeal: return 1.1
        case .debtRaise: return -1.2
        case .buyback: return 1.8
        case .hostileBid: return 3.4
        case .auditDefence: return -0.6
        case .expansion: return 1.4
        case .retreat: return -2.4
        }
    }
}

public struct CompetitorAction: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var day: Int
    public var kind: CompetitorActionKind
    public var title: String
    public var detail: String
    public var priceImpact: Double

    public init(
        id: UUID = UUID(),
        day: Int,
        kind: CompetitorActionKind,
        title: String,
        detail: String,
        priceImpact: Double
    ) {
        self.id = id
        self.day = day
        self.kind = kind
        self.title = title
        self.detail = detail
        self.priceImpact = priceImpact
    }
}

public struct CompetitorProfile: Codable, Identifiable, Equatable, Sendable {
    public var businessID: UUID
    public var name: String
    public var kind: AIBusinessKind
    public var strategy: CompetitorStrategy
    public var threat: Double
    public var brand: Double
    public var priceAggression: Double
    public var wageOffer: Double
    public var rndFocus: Double
    public var debtLoad: Double
    public var supplySecurity: Double
    public var staffMorale: Double
    public var marketShare: Double
    public var shareTrend: Double
    public var employees: Int
    public var openRoles: Int
    public var marketingSpend: Double
    public var recentActions: [CompetitorAction]
    public var headline: String
    public var lastUpdatedDay: Int

    public var id: UUID { businessID }

    public init(
        businessID: UUID,
        name: String,
        kind: AIBusinessKind,
        strategy: CompetitorStrategy,
        threat: Double = 0.4,
        brand: Double = 0.45,
        priceAggression: Double = 0.5,
        wageOffer: Double = 1,
        rndFocus: Double = 0.4,
        debtLoad: Double = 0.2,
        supplySecurity: Double = 0.5,
        staffMorale: Double = 0.6,
        marketShare: Double = 0.2,
        shareTrend: Double = 0,
        employees: Int = 2,
        openRoles: Int = 0,
        marketingSpend: Double = 4,
        recentActions: [CompetitorAction] = [],
        headline: String = "",
        lastUpdatedDay: Int = 1
    ) {
        self.businessID = businessID
        self.name = name
        self.kind = kind
        self.strategy = strategy
        self.threat = threat
        self.brand = brand
        self.priceAggression = priceAggression
        self.wageOffer = wageOffer
        self.rndFocus = rndFocus
        self.debtLoad = debtLoad
        self.supplySecurity = supplySecurity
        self.staffMorale = staffMorale
        self.marketShare = marketShare
        self.shareTrend = shareTrend
        self.employees = employees
        self.openRoles = openRoles
        self.marketingSpend = marketingSpend
        self.recentActions = recentActions
        self.headline = headline
        self.lastUpdatedDay = lastUpdatedDay
    }

    public var threatLabel: String {
        switch threat {
        case ..<0.25: return "Harmless"
        case ..<0.45: return "Watch"
        case ..<0.65: return "Serious"
        case ..<0.82: return "Dangerous"
        default: return "Dominant"
        }
    }

    /// A paragraph the exchange shows on the competitor board: enough to judge
    /// whether the rival or the firm you hold is winning.
    public var dossier: String {
        "\(strategy.blurb) \(Int((marketShare * 100).rounded()))% of the local \(kind.title.lowercased()) trade, \(employees) staff and \(openRoles) open roles. \(supplyNote) \(debtNote)"
    }

    public var supplyNote: String {
        if supplySecurity > 0.7 { return "Inputs are locked in with long contracts." }
        if supplySecurity > 0.45 { return "Inputs are mostly reliable but weather-exposed." }
        return "Inputs are bought hand to mouth and exposed to shortages."
    }

    public var debtNote: String {
        if debtLoad > 0.6 { return "Heavy borrowing makes it fragile if rates rise." }
        if debtLoad > 0.3 { return "Ordinary borrowing for its size." }
        return "Almost debt-free, so it can undercut for a long time."
    }

    public var momentumLine: String {
        let arrow = shareTrend >= 0 ? "gaining" : "losing"
        return "\(arrow.capitalized) \(String(format: "%.1f", abs(shareTrend) * 100))% share"
    }

    public var actions: [CompetitorAction] { recentActions }
}

// MARK: - Seeding rivals

extension CompetitorProfile {
    public static func seed(firm: AIBusiness, listing: BusinessListing, index: Int) -> CompetitorProfile {
        let seed = firm.name.unicodeScalars.reduce(UInt64(7)) { ($0 &* 31) &+ UInt64($1.value) }
        var rng = GameRNG(state: seed &+ 0x9E3779B97F4A7C15)
        let strategy = CompetitorStrategy.allCases[Int(seed % UInt64(CompetitorStrategy.allCases.count))]
        let brand = hhClamp(0.3 + rng.double01() * 0.5, 0.1, 0.95)
        let aggression = hhClamp(strategy.pricingBias - 1 + 0.5 + rng.double01() * 0.3, 0.1, 1)
        let share = hhClamp(listing.fundamentals.marketShare, 0.02, 1)
        return CompetitorProfile(
            businessID: firm.id,
            name: firm.name,
            kind: firm.kind,
            strategy: strategy,
            threat: hhClamp(share * 1.4 + brand * 0.3, 0.05, 1),
            brand: brand,
            priceAggression: aggression,
            wageOffer: 0.85 + rng.double01() * 0.4,
            rndFocus: hhClamp(0.2 + firm.technology * 0.8, 0.05, 1),
            debtLoad: hhClamp(0.12 + listing.fundamentals.debt / max(1, listing.fundamentals.bookValue), 0, 1),
            supplySecurity: hhClamp(0.35 + rng.double01() * 0.5, 0.1, 1),
            staffMorale: hhClamp(firm.mood, 0.05, 1),
            marketShare: share,
            shareTrend: 0,
            employees: firm.employees,
            openRoles: 0,
            marketingSpend: max(2, listing.fundamentals.revenue * 0.02),
            headline: "\(firm.name) runs a \(strategy.title.lowercased()) playbook.",
            lastUpdatedDay: firm.foundedDay
        )
    }
}

// MARK: - Daily rival behaviour

extension ValleyEconomy {
    /// Updates every competitor dossier and lets rivals act. Their choices feed
    /// the price of the firm they attack, the wage bill of the valley, and the
    /// running competition heat readout on the exchange.
    mutating func advanceCompetitors(
        market: inout InvestmentMarket,
        rng: inout GameRNG
    ) {
        var profiles = market.competitors ?? []
        let activeIDs = Set(market.listings.filter { !$0.isBankrupt }.map(\.businessID))
        profiles.removeAll { !activeIDs.contains($0.businessID) }

        let totalOutput = max(1, aiBusinesses.reduce(0) { $0 + $1.output })
        var heat = 0.0
        var roles = 0
        var rnd = 0.0
        var marketing = 0.0
        var supplierDeals = 0
        var takeover = 0

        for listingIndex in market.listings.indices {
            let listing = market.listings[listingIndex]
            guard !listing.isBankrupt,
                  let firm = aiBusinesses.first(where: { $0.id == listing.businessID }) else { continue }
            var profile: CompetitorProfile
            if let existing = profiles.first(where: { $0.businessID == firm.id }) {
                profile = existing
            } else {
                profile = CompetitorProfile.seed(firm: firm, listing: listing, index: listingIndex)
                profiles.append(profile)
            }

            let previousShare = profile.marketShare
            let share = hhClamp(firm.output / totalOutput, 0.005, 1)
            profile.marketShare = share
            profile.shareTrend = profile.shareTrend * 0.7 + (share - previousShare) * 0.3
            profile.employees = firm.employees
            profile.staffMorale = hhClamp(firm.mood, 0.05, 1)
            profile.brand = hhClamp(
                profile.brand + (firm.mood - 0.5) * 0.01 - listing.fundamentals.fraudRisk * 0.004,
                0.05, 1
            )
            profile.rndFocus = hhClamp(profile.rndFocus * 0.85 + firm.technology * 0.15, 0.05, 1)
            profile.debtLoad = hhClamp(
                0.1 + listing.fundamentals.debt / max(1, listing.fundamentals.bookValue),
                0, 1.2
            )
            profile.wageOffer = hhClamp(averageWage / max(4, firm.productivity * 60), 0.6, 2)
            profile.threat = hhClamp(
                share * 1.5 + profile.brand * 0.25 + profile.rndFocus * 0.15 + profile.priceAggression * 0.1,
                0.02, 1
            )
            profile.lastUpdatedDay = day

            if rng.chance(0.14) {
                let action = rivalAction(
                    profile: profile,
                    listing: listing,
                    firm: firm,
                    rng: &rng
                )
                profile.recentActions.insert(action, at: 0)
                if profile.recentActions.count > 6 {
                    profile.recentActions.removeLast(profile.recentActions.count - 6)
                }
                profile.headline = action.title
                if var updated = market.listings.first(where: { $0.businessID == listing.businessID }) {
                    let previous = updated.sharePrice
                    updated.sharePrice = hhClamp(previous * (1 + action.priceImpact / 100), 0.2, 999)
                    updated.dailyChange = updated.sharePrice - previous
                    updated.dailyChangePercent = previous > 0 ? updated.dailyChange / previous : 0
                    updated.fundamentals.reputation = hhClamp(
                        updated.fundamentals.reputation + (action.priceImpact > 0 ? 0.015 : -0.01),
                        0.03, 1
                    )
                    if let position = market.listings.firstIndex(where: { $0.businessID == listing.businessID }) {
                        if var last = updated.bars.last {
                            last.close = updated.sharePrice
                            last.high = max(last.high, updated.sharePrice)
                            last.low = min(last.low, updated.sharePrice)
                            updated.bars[updated.bars.count - 1] = last
                        }
                        market.listings[position] = updated
                    }
                }
                switch action.kind {
                case .hiring, .expansion:
                    profile.openRoles = min(6, profile.openRoles + 1)
                    roles += 1
                case .layoffs, .retreat:
                    profile.openRoles = max(0, profile.openRoles - 1)
                case .productLaunch:
                    rnd += profile.marketingSpend
                case .marketingBlitz:
                    marketing += profile.marketingSpend
                    profile.marketingSpend = min(40, profile.marketingSpend * 1.1)
                case .supplierDeal:
                    supplierDeals += 1
                    profile.supplySecurity = hhClamp(profile.supplySecurity + 0.08, 0.1, 1)
                case .hostileBid:
                    takeover += 1
                case .buyback:
                    profile.brand = hhClamp(profile.brand + 0.02, 0.05, 1)
                case .debtRaise:
                    profile.debtLoad = hhClamp(profile.debtLoad + 0.06, 0, 1.2)
                case .priceCut:
                    profile.priceAggression = hhClamp(profile.priceAggression + 0.06, 0, 1)
                case .priceRise, .auditDefence:
                    break
                }
            }

            roles += profile.openRoles
            rnd += profile.rndFocus * 6 * profile.strategy.rndBias
            marketing += profile.marketingSpend * 0.2
            heat += profile.priceAggression * (1 - profile.brand * 0.4) * competition
            if let index = profiles.firstIndex(where: { $0.businessID == profile.businessID }) {
                profiles[index] = profile
            }
        }

        market.competitors = Array(profiles.prefix(24))
        market.competitionHeat = hhClamp(heat / Double(max(1, market.listings.count)), 0, 1)
        market.openRoles = roles
        market.competitorRnd = rnd
        market.competitorMarketing = marketing
        market.supplierAgreements = supplierDeals
        market.takeoverTalk = takeover
    }

    /// Picks a behaviour that fits the rival's playbook and the state of the
    /// valley. Aggressive firms cut prices in a downturn; innovators launch
    /// products; consolidators bid for weaker neighbours.
    private func rivalAction(
        profile: CompetitorProfile,
        listing: BusinessListing,
        firm: AIBusiness,
        rng: inout GameRNG
    ) -> CompetitorAction {
        var pool: [CompetitorActionKind] = [.marketingBlitz, .supplierDeal, .hiring]
        if profile.priceAggression > 0.55 { pool.append(contentsOf: [.priceCut, .priceCut]) }
        if profile.priceAggression < 0.4 { pool.append(.priceRise) }
        if profile.rndFocus > 0.5 { pool.append(contentsOf: [.productLaunch, .expansion]) }
        if profile.debtLoad > 0.5 { pool.append(.debtRaise) }
        if consumerConfidence > 0.6 { pool.append(.buyback) }
        if competition < 0.4, profile.strategy == .consolidator { pool.append(.hostileBid) }
        if listing.fundamentals.fraudRisk > 0.3 { pool.append(.auditDefence) }
        if firm.capital < 6 || consumerConfidence < 0.3 { pool.append(contentsOf: [.layoffs, .retreat]) }
        if tier.rawValue >= EconomyTier.district.rawValue { pool.append(.hostileBid) }

        let kind = pool[rng.int(in: 0...(pool.count - 1))]
        let name = profile.name
        let detail: String
        switch kind {
        case .priceCut:
            detail = "\(name) undercuts the square by \(Int((6 + rng.double01() * 10).rounded()))%, protecting customers and destroying margin."
        case .priceRise:
            detail = "\(name) lifts prices, betting that its brand survives the increase."
        case .hiring:
            detail = "\(name) hires \(1 + rng.int(in: 0...2)) more hands at \(Int((averageWage * profile.wageOffer).rounded()))c a day."
        case .layoffs:
            detail = "\(name) cuts staff as orders thin. Wages fall but the valley's mood sours."
        case .productLaunch:
            detail = "\(name) launches a new \(firm.kind.title.lowercased()) line built on \(Int((profile.rndFocus * 100).rounded()))% research focus."
        case .marketingBlitz:
            detail = "\(name) buys every poster in Hollowmere to push its brand."
        case .supplierDeal:
            detail = "\(name) signs a season-long supply contract, locking input costs."
        case .debtRaise:
            detail = "\(name) borrows again to fund expansion. Interest cover narrows."
        case .buyback:
            detail = "\(name) buys back its own shares, supporting the price."
        case .hostileBid:
            detail = "\(name) circles a weaker rival. Deal rumour runs through the exchange."
        case .auditDefence:
            detail = "\(name) hires lawyers to fight a tax case, and the market notices the cost."
        case .expansion:
            detail = "\(name) opens a second site and takes on new staff."
        case .retreat:
            detail = "\(name) retreats to its core trade, closing the outer stall."
        }
        return CompetitorAction(
            day: day,
            kind: kind,
            title: "\(kind.title) at \(name)",
            detail: detail,
            priceImpact: kind.priceImpact + (rng.double01() - 0.5) * 0.6
        )
    }
}
