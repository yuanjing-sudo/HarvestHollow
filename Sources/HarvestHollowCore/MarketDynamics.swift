import Foundation

// MARK: - Candles and price bars

/// One day of trading for a listing or for the valley index. The exchange draws
/// candles from these, so a day is a real open/high/low/close with volume
/// rather than a single moving number.
public struct PriceBar: Codable, Equatable, Sendable, Identifiable {
    public var day: Int
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var volume: Double

    public var id: Int { day }

    public init(day: Int, open: Double, high: Double, low: Double, close: Double, volume: Double = 0) {
        self.day = day
        self.open = max(0, open)
        self.high = max(open, high, close, low)
        self.low = min(open, high, close, low)
        self.close = max(0, close)
        self.volume = max(0, volume)
    }

    public var isUp: Bool { close >= open }
    public var body: Double { abs(close - open) }
    public var range: Double { max(0.0001, high - low) }
    public var midpoint: Double { (high + low) / 2 }
    public var changePercent: Double {
        open > 0 ? (close - open) / open : 0
    }
}

// MARK: - Bar statistics

extension Array where Element == PriceBar {
    public var lastClose: Double { last?.close ?? 0 }

    public func movingAverage(_ window: Int) -> Double {
        guard !isEmpty, window > 0 else { return lastClose }
        let slice = suffix(Swift.min(window, count))
        return slice.map(\.close).reduce(0, +) / Double(slice.count)
    }

    /// Compound return over the last `window` bars, as a fraction.
    public func returnOver(_ window: Int) -> Double {
        guard count > 1 else { return 0 }
        let slice = suffix(Swift.min(window + 1, count))
        guard let first = slice.first?.close, first > 0, let last = slice.last?.close else { return 0 }
        return last / first - 1
    }

    /// Daily standard deviation of close-to-close returns.
    public func volatility(_ window: Int = 20) -> Double {
        guard count > 2 else { return 0.01 }
        let slice = Array(suffix(Swift.min(window + 1, count)))
        var returns: [Double] = []
        returns.reserveCapacity(slice.count - 1)
        for index in 1..<slice.count {
            let previous = slice[index - 1].close
            guard previous > 0 else { continue }
            returns.append(slice[index].close / previous - 1)
        }
        guard returns.count > 1 else { return 0.01 }
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(returns.count - 1)
        return Swift.max(0.001, sqrt(variance))
    }

    /// Wilder-style RSI on closes, 0...100.
    public func relativeStrengthIndex(_ window: Int = 14) -> Double {
        guard count > 2 else { return 50 }
        let slice = Array(suffix(Swift.min(window + 1, count)))
        var gains = 0.0
        var losses = 0.0
        for index in 1..<slice.count {
            let delta = slice[index].close - slice[index - 1].close
            if delta >= 0 { gains += delta } else { losses -= delta }
        }
        let periods = Double(slice.count - 1)
        let averageGain = gains / periods
        let averageLoss = losses / periods
        guard averageLoss > 0 else { return averageGain > 0 ? 100 : 50 }
        let rs = averageGain / averageLoss
        return 100 - 100 / (1 + rs)
    }

    /// How many standard deviations the last close sits above its own mean.
    public func zScore(_ window: Int = 20) -> Double {
        guard count > 2 else { return 0 }
        let slice = Array(suffix(Swift.min(window, count))).map(\.close)
        let mean = slice.reduce(0, +) / Double(slice.count)
        let variance = slice.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(slice.count)
        let deviation = sqrt(Swift.max(0.0000001, variance))
        guard let lastValue = slice.last else { return 0 }
        return (lastValue - mean) / deviation
    }

    /// Decline from the highest close in the window, as a positive fraction.
    public func drawdown(_ window: Int = 20) -> Double {
        let recent = suffix(Swift.min(window, count)).map(\.close)
        guard let peak = recent.max(), peak > 0 else { return 0 }
        return Swift.max(0, 1 - lastClose / peak)
    }

    public func averageClosingPrice(_ window: Int = 30) -> Double {
        guard !isEmpty else { return 0 }
        let slice = suffix(Swift.min(window, count))
        return slice.map(\.close).reduce(0, +) / Double(slice.count)
    }

    public func averageVolume(_ window: Int = 10) -> Double {
        guard !isEmpty else { return 0 }
        let slice = suffix(Swift.min(window, count))
        return slice.map(\.volume).reduce(0, +) / Double(slice.count)
    }
}

// MARK: - Regimes

public enum MarketRegime: String, Codable, CaseIterable, Sendable, Identifiable {
    case crash
    case bear
    case choppy
    case bull
    case mania

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .crash: return "Capitulation"
        case .bear: return "Bear market"
        case .choppy: return "Choppy tape"
        case .bull: return "Bull market"
        case .mania: return "Euphoria"
        }
    }

    public var blurb: String {
        switch self {
        case .crash:
            return "Forced sellers are in charge. Every bounce is sold."
        case .bear:
            return "Buyers are cautious and rallies fade quickly."
        case .choppy:
            return "No clear trend. Prices bounce between support and resistance."
        case .bull:
            return "Dip buyers show up and the index grinds higher."
        case .mania:
            return "Leverage and rumour are doing the pricing. Corrections bite hard."
        }
    }

    public var icon: String {
        switch self {
        case .crash: return "arrow.down.right.circle.fill"
        case .bear: return "chart.line.downtrend.xyaxis"
        case .choppy: return "waveform.path.ecg"
        case .bull: return "chart.line.uptrend.xyaxis"
        case .mania: return "flame.fill"
        }
    }

    public static func classify(indexChange: Double, volatility: Double, sentiment: Double) -> MarketRegime {
        if indexChange < -0.035 || (volatility > 0.045 && sentiment < 0.3) { return .crash }
        if indexChange < -0.008 || sentiment < 0.38 { return .bear }
        if volatility > 0.032 { return .choppy }
        if sentiment > 0.78 && indexChange > 0.015 { return .mania }
        if indexChange > 0.006 || sentiment > 0.6 { return .bull }
        return .choppy
    }
}

// MARK: - Factor catalogue

public enum MarketFactorGroup: String, Codable, CaseIterable, Sendable, Identifiable {
    case macro
    case rates
    case policy
    case earnings
    case supply
    case trade
    case flows
    case technicals
    case derivatives
    case peers
    case global

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .macro: return "Macro & activity"
        case .rates: return "Rates & money"
        case .policy: return "Tax, politics & policy"
        case .earnings: return "Earnings & balance sheets"
        case .supply: return "Supply & real economy"
        case .trade: return "Trade & currency"
        case .flows: return "Flows & sentiment"
        case .technicals: return "Technicals & structure"
        case .derivatives: return "Derivatives & positioning"
        case .peers: return "Competitors & sectors"
        case .global: return "Global & risk"
        }
    }

    public var icon: String {
        switch self {
        case .macro: return "chart.bar.xaxis"
        case .rates: return "percent"
        case .policy: return "building.columns.fill"
        case .earnings: return "doc.text.fill"
        case .supply: return "shippingbox.fill"
        case .trade: return "ferry.fill"
        case .flows: return "arrow.left.arrow.right"
        case .technicals: return "chart.xyaxis.line"
        case .derivatives: return "square.stack.3d.up.fill"
        case .peers: return "person.3.fill"
        case .global: return "globe.americas.fill"
        }
    }
}

public struct MarketFactorReadout: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var group: MarketFactorGroup
    public var valueText: String
    public var score: Double
    public var impactBps: Double
    public var note: String

    public init(
        id: String,
        title: String,
        group: MarketFactorGroup,
        valueText: String,
        score: Double,
        impactBps: Double,
        note: String
    ) {
        self.id = id
        self.title = title
        self.group = group
        self.valueText = valueText
        self.score = hhClamp(score, 0, 100)
        self.impactBps = impactBps
        self.note = note
    }

    public var isBullish: Bool { impactBps >= 0 }
    public var impactLabel: String {
        let sign = impactBps >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", impactBps))bp"
    }
}

public struct MarketFactorBook: Codable, Equatable, Sendable {
    public var day: Int
    public var readouts: [MarketFactorReadout]
    public var indexImpactBps: Double
    public var regime: MarketRegime
    public var updatedAt: Int

    public init(
        day: Int,
        readouts: [MarketFactorReadout] = [],
        indexImpactBps: Double = 0,
        regime: MarketRegime = .choppy,
        updatedAt: Int = 0
    ) {
        self.day = day
        self.readouts = readouts
        self.indexImpactBps = indexImpactBps
        self.regime = regime
        self.updatedAt = updatedAt
    }

    public var isEmpty: Bool { readouts.isEmpty }

    public var bulls: Int { readouts.filter { $0.impactBps > 0.4 }.count }
    public var bears: Int { readouts.filter { $0.impactBps < -0.4 }.count }

    public func readouts(in group: MarketFactorGroup) -> [MarketFactorReadout] {
        readouts.filter { $0.group == group }
    }

    /// The factors pushing hardest on today's tape, in either direction.
    public var strongestDrivers: [MarketFactorReadout] {
        readouts
            .filter { abs($0.impactBps) > 0.05 }
            .sorted { abs($0.impactBps) > abs($1.impactBps) }
            .prefix(8)
            .map { $0 }
    }

    public func groupTilt(_ group: MarketFactorGroup) -> Double {
        readouts(in: group).reduce(0) { $0 + $1.impactBps }
    }
}

// MARK: - Factor plumbing

public struct MarketFactorOutcome: Sendable {
    public var value: String
    public var score: Double
    public var impactBps: Double
    public var note: String

    public init(_ value: String, _ score: Double, _ impactBps: Double, _ note: String) {
        self.value = value
        self.score = score
        self.impactBps = impactBps
        self.note = note
    }
}

public struct MarketFactorContext: Sendable {
    public var economy: ValleyEconomy
    public var sentiment: Double
    public var volatility: Double
    public var indexChange: Double
    public var breadth: Double
    public var shortInterest: Double
    public var worstShortInterest: Double
    public var liquidity: Double
    public var day: Int

    public init(
        economy: ValleyEconomy,
        sentiment: Double,
        volatility: Double,
        indexChange: Double,
        breadth: Double,
        shortInterest: Double,
        worstShortInterest: Double,
        liquidity: Double,
        day: Int
    ) {
        self.economy = economy
        self.sentiment = sentiment
        self.volatility = volatility
        self.indexChange = indexChange
        self.breadth = breadth
        self.shortInterest = shortInterest
        self.worstShortInterest = worstShortInterest
        self.liquidity = liquidity
        self.day = day
    }
}

public struct MarketFactorSpec {
    public var id: String
    public var title: String
    public var group: MarketFactorGroup
    public var probe: (MarketFactorContext) -> MarketFactorOutcome

    public init(
        id: String,
        title: String,
        group: MarketFactorGroup,
        probe: @escaping (MarketFactorContext) -> MarketFactorOutcome
    ) {
        self.id = id
        self.title = title
        self.group = group
        self.probe = probe
    }
}

// MARK: - The factor model

/// The Hollow Exchange prices every firm from a large, interconnected factor
/// set instead of a single random walk. Each factor contributes basis points to
/// the day's move, so a tax rise or a price war is visible in the tape the next
/// morning. The catalogue is intentionally long: the exchange should be legible
/// without being simple.
public enum MarketFactorModel {
    private static func outcome(_ value: String, _ score: Double, _ impact: Double, _ note: String) -> MarketFactorOutcome {
        MarketFactorOutcome(value, score, impact, note)
    }

    private static func bps(_ value: Double, _ limit: Double = 14) -> Double {
        hhClamp(value, -limit, limit)
    }

    private static func pctText(_ value: Double) -> String {
        let rounded = (value * 1000).rounded() / 10
        return "\(String(format: "%.1f", rounded))%"
    }

    private static func coinText(_ value: Double) -> String {
        "\(Int(value.rounded()))c"
    }

    public static let catalogue: [MarketFactorSpec] = {
        var specs: [MarketFactorSpec] = []
        specs.reserveCapacity(200)
        specs.append(contentsOf: macroFactors)
        specs.append(contentsOf: rateFactors)
        specs.append(contentsOf: policyFactors)
        specs.append(contentsOf: earningsFactors)
        specs.append(contentsOf: supplyFactors)
        specs.append(contentsOf: tradeFactors)
        specs.append(contentsOf: flowFactors)
        specs.append(contentsOf: technicalFactors)
        specs.append(contentsOf: derivativeFactors)
        specs.append(contentsOf: peerFactors)
        specs.append(contentsOf: globalFactors)
        specs.append(contentsOf: extendedGlobalFactors)
        specs.append(contentsOf: extendedFactors)
        return specs
    }()

    public static var factorCount: Int { catalogue.count }

    // MARK: Macro

    private static var macroFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "macro.gdpGrowth", title: "GDP momentum", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let growth = e.history.count >= 2
                    ? (e.history[e.history.count - 1].gdp - e.history[e.history.count - 2].gdp) / max(1, e.history[e.history.count - 2].gdp)
                    : 0
                // Factor in 4-period trend: accelerating or decelerating growth
                let trend: Double = e.history.count >= 4
                    ? (e.history[e.history.count - 1].gdp - e.history[e.history.count - 4].gdp) / max(1, e.history[e.history.count - 4].gdp) / 4.0
                    : 0
                // Momentum: recent trend amplifies or dampens current reading
                let momentum = growth + trend * 0.5
                return outcome(pctText(growth) + " [\\(String(format: \"%+.1f\", trend * 100))% trend]", 50 + momentum * 900, bps(momentum * 620), "Output is the tide every share price floats on. Recent trend amplifies or dampens the current reading.")
            },
            MarketFactorSpec(id: "macro.outputGap", title: "Output gap", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let gap = hhClamp((e.gdp - Double(e.population) * e.averageWage * 0.9) / max(1, e.gdp), -0.5, 0.5)
                return outcome(pctText(gap), 50 + gap * 120, bps(gap * 9), "A positive gap means the valley is producing above its usual pace.")
            },
            MarketFactorSpec(id: "macro.consumerConfidence", title: "Consumer confidence", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.consumerConfidence), e.consumerConfidence * 100, bps((e.consumerConfidence - 0.5) * 40), "Households buy more when they feel secure, which feeds firm revenue.")
            },
            MarketFactorSpec(id: "macro.householdDemand", title: "Household demand", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let ratio = e.demand / max(1, e.supply)
                return outcome(String(format: "%.2f× supply", ratio), hhClamp(ratio, 0, 1.6) / 1.6 * 100, bps((ratio - 1) * 30), "Demand above supply lets firms raise prices and protect margins.")
            },
            MarketFactorSpec(id: "macro.retailSales", title: "Retail sales pulse", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let pulse = e.demand * 0.6 + Double(e.population) * 0.1
                return outcome(String(format: "%.0f units", pulse), hhClamp(pulse / 60, 0, 1) * 100, bps((pulse - 30) * 0.35), "Market-stall takings are the first hard number of the morning.")
            },
            MarketFactorSpec(id: "macro.industrialOutput", title: "Industrial output", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.manufacturing), e.manufacturing * 100, bps((e.manufacturing - 0.2) * 40), "Mills and workshops convert harvests into tradable goods.")
            },
            MarketFactorSpec(id: "macro.capacity", title: "Capacity utilisation", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.energyCapacity), e.energyCapacity / 1.3 * 100, bps((e.energyCapacity - 0.5) * 16), "Full capacity lifts profits but invites bottlenecks and inflation.")
            },
            MarketFactorSpec(id: "macro.inventoryCycle", title: "Inventory cycle", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let cover = e.supply / max(1, e.demand)
                return outcome(String(format: "%.2f× cover", cover), hhClamp(cover, 0, 1.5) / 1.5 * 100, bps((cover - 1) * -14), "Heavy stock cover means discounts; thin cover means pricing power.")
            },
            MarketFactorSpec(id: "macro.unemployment", title: "Unemployment", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.unemployment), (1 - e.unemployment) * 100, bps((0.08 - e.unemployment) * 90), "Rising joblessness trims demand and hardens lenders.")
            },
            MarketFactorSpec(id: "macro.participation", title: "Labour participation", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let rate = Double(e.workforce) / Double(max(1, e.population))
                return outcome(pctText(rate), hhClamp(rate, 0, 1) * 100, bps((rate - 0.58) * 30), "More residents working means a wider base for wages and taxes.")
            },
            MarketFactorSpec(id: "macro.productivity", title: "Productivity", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.productivity / 1.5), e.productivity / 1.5 * 100, bps((e.productivity - 0.35) * 30), "Output per worker is the long-run engine of every valuation.")
            },
            MarketFactorSpec(id: "macro.unitLabourCost", title: "Unit labour cost", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let cost = e.averageWage / max(0.1, e.productivity)
                return outcome(String(format: "%.0f per unit", cost), hhClamp(160 - cost, 0, 100), bps((60 - cost) * 0.12), "Wages rising faster than output squeeze margins.")
            },
            MarketFactorSpec(id: "macro.realWages", title: "Real wages", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(coinText(e.realWage), hhClamp(e.realWage / 60, 0, 1) * 100, bps((e.realWage - 26) * 0.5), "Real take-home pay decides whether the square keeps spending.")
            },
            MarketFactorSpec(id: "macro.population", title: "Population growth", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome("\(e.population) residents", hhClamp(Double(e.population) / 160, 0, 1) * 100, bps(e.populationMomentum * 900), "Migration follows opportunity and housing, then creates both.")
            },
            MarketFactorSpec(id: "macro.migration", title: "Migration flow", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let flow = (e.happiness - 0.45) + (e.health - 0.5) - e.pollution * 0.5
                return outcome(pctText(flow / 10), hhClamp(50 + flow * 40, 0, 100), bps(flow * 6), "Families drift toward clean, happy, well-served valleys.")
            },
            MarketFactorSpec(id: "macro.firmFormation", title: "Business formation", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome("\(e.aiBusinesses.count) firms trading", hhClamp(Double(e.aiBusinesses.count) / 12, 0, 1) * 100, bps((Double(e.aiBusinesses.count) - 5) * 1.4), "New firms widen the exchange and deepen competition.")
            }
        ]
    }

    // MARK: Rates

    private static var rateFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "rates.policyRate", title: "Policy rate", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.interestRate), hhClamp(100 - e.interestRate * 260, 0, 100), bps((0.045 - e.interestRate) * 120), "Higher rates discount future profits harder.")
            },
            MarketFactorSpec(id: "rates.realRate", title: "Real interest rate", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let real = e.interestRate - e.inflation
                return outcome(pctText(real), hhClamp(60 - real * 200, 0, 100), bps((0.01 - real) * 90), "Money is tight when the real rate is high.")
            },
            MarketFactorSpec(id: "rates.termSpread", title: "Term spread", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let spread = e.interestRate * 1.65 - e.interestRate
                return outcome(pctText(spread), hhClamp(50 + spread * 500, 0, 100), bps(spread * 40), "A steep curve signals growth; a flat one signals caution.")
            },
            MarketFactorSpec(id: "rates.creditSpread", title: "Credit spread", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let spread = 0.015 + e.bankruptcyRisk * 0.09 + e.corruption * 0.02
                return outcome(pctText(spread), hhClamp(100 - spread * 400, 0, 100), bps(-spread * 60), "Widening spreads make borrowing dear for every firm at once.")
            },
            MarketFactorSpec(id: "rates.curveInversion", title: "Curve inversion risk", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let inverted = max(0, e.inflation - e.interestRate) * 3
                return outcome(pctText(inverted), hhClamp(100 - inverted * 300, 0, 100), bps(-inverted * 30), "Inversions have preceded every valley slowdown on record.")
            },
            MarketFactorSpec(id: "rates.loanRate", title: "Household loan rate", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let rate = e.interestRate + 0.045
                return outcome(pctText(rate), hhClamp(100 - rate * 200, 0, 100), bps((0.07 - rate) * 40), "What the farm pays to borrow is what firms pay too.")
            },
            MarketFactorSpec(id: "rates.depositRate", title: "Deposit rate", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let rate = max(0, e.interestRate - 0.012)
                return outcome(pctText(rate), hhClamp(rate * 900, 0, 100), bps(rate * 35), "Cash in the bank competes with shares for household savings.")
            },
            MarketFactorSpec(id: "rates.moneySupply", title: "Money in circulation", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let supply = e.gdp / max(0.4, e.priceIndex)
                return outcome(coinText(supply), hhClamp(supply / 25, 0, 100), bps((supply - 90) * 0.06), "Loose money lifts nominal prices before it lifts real output.")
            },
            MarketFactorSpec(id: "rates.liquidity", title: "Market liquidity", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                outcome(pctText(context.liquidity), context.liquidity * 100, bps((context.liquidity - 0.5) * 22), "Thin books exaggerate every order, in both directions.")
            },
            MarketFactorSpec(id: "rates.bankLending", title: "Bank lending appetite", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let appetite = hhClamp(Double(e.creditScore) / 850, 0, 1)
                return outcome("\(e.creditScore) score", appetite * 100, bps((appetite - 0.7) * 30), "When the bank stops calling, expansion stops with it.")
            },
            MarketFactorSpec(id: "rates.corporateBorrowCost", title: "Corporate borrowing cost", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let cost = e.interestRate + e.bankruptcyRisk * 0.1 + 0.02
                return outcome(pctText(cost), hhClamp(100 - cost * 240, 0, 100), bps((0.06 - cost) * 70), "Debt-heavy firms feel this line before anyone else.")
            },
            MarketFactorSpec(id: "rates.discountEffect", title: "Valuation discount", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let discount = 1 / (1 + max(0.005, e.interestRate + e.bankruptcyRisk * 0.08))
                return outcome(String(format: "%.2f×", discount * 20), hhClamp(discount * 180, 0, 100), bps((discount - 0.96) * 260), "Every future coin is worth less when rates are high.")
            }
        ]
    }

    // MARK: Policy

    private static var policyFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "policy.taxTake", title: "Tax take", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.taxRate) + " of output", hhClamp(100 - e.taxRate * 220, 0, 100), bps((0.17 - e.taxRate) * 190), "Every point of tax comes out of after-tax profit, dividends, and hiring.")
            },
            MarketFactorSpec(id: "policy.taxDelta", title: "Tax change this session", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let baseline = e.market?.policyReport?.baseline.taxRate ?? 0.17
                let delta = e.taxRate - baseline
                return outcome(pctText(delta) + " vs baseline", hhClamp(50 - delta * 600, 0, 100), bps(-delta * 700), "The market prices the change, not the level.")
            },
            MarketFactorSpec(id: "policy.corporateTaxDrag", title: "Corporate tax drag", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let drag = e.aiBusinesses.reduce(0.0) { total, firm in
                    total + max(0, firm.output * 6.5) * e.taxRate * 0.55
                }
                return outcome(coinText(drag) + " a day", hhClamp(100 - drag * 0.5, 0, 100), bps(-drag * 0.22), "This is real coin leaving the firms' books every morning.")
            },
            MarketFactorSpec(id: "policy.dividendTax", title: "Dividend taxation", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let rate = e.taxRate * 0.8
                return outcome(pctText(rate), hhClamp(100 - rate * 260, 0, 100), bps((0.13 - rate) * 110), "Shareholders pay again on the way out, so they bid less.")
            },
            MarketFactorSpec(id: "policy.subsidySupport", title: "Subsidy support", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.subsidyRate) + " of output", hhClamp(e.subsidyRate * 800, 0, 100), bps((e.subsidyRate - 0.035) * 220), "Grants land directly on farm and firm margins.")
            },
            MarketFactorSpec(id: "policy.subsidyDelta", title: "Subsidy change", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let baseline = e.market?.policyReport?.baseline.subsidyRate ?? 0.035
                let delta = e.subsidyRate - baseline
                return outcome(pctText(delta) + " vs baseline", hhClamp(50 + delta * 700, 0, 100), bps(delta * 380), "New grants are bought on the rumour and sold on the detail.")
            },
            MarketFactorSpec(id: "policy.publicSpending", title: "Public spending", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.publicSpending) + " of output", hhClamp(e.publicSpending * 260, 0, 100), bps((e.publicSpending - 0.16) * 90), "Roads, schools and clinics raise firm productivity and demand.")
            },
            MarketFactorSpec(id: "policy.budgetBalance", title: "Budget balance", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let balance = e.governmentBalance / max(1, e.gdp)
                return outcome(pctText(balance), hhClamp(50 + balance * 400, 0, 100), bps(balance * 180), "Surpluses buy credibility; deficits buy inflation risk.")
            },
            MarketFactorSpec(id: "policy.debtToGDP", title: "Public debt", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.debtToGDP), hhClamp(100 - e.debtToGDP * 70, 0, 100), bps(-e.debtToGDP * 9), "Heavy public debt crowds out private borrowers.")
            },
            MarketFactorSpec(id: "policy.sovereignRisk", title: "Sovereign risk premium", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let premium = max(0, e.debtToGDP - 0.8) * 0.03 + (1 - e.politicalStability) * 0.02
                return outcome(pctText(premium), hhClamp(100 - premium * 900, 0, 100), bps(-premium * 220), "A valley that might not pay its debts pays more for everything.")
            },
            MarketFactorSpec(id: "policy.regulationBurden", title: "Regulation & permits", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let burden = hhClamp(e.publicSpending * 0.4 + e.corruption * 0.8, 0, 1)
                return outcome(pctText(burden), hhClamp(100 - burden * 80, 0, 100), bps(-burden * 9), "Paperwork is a tax that never shows up in the tax line.")
            },
            MarketFactorSpec(id: "policy.complianceCost", title: "Compliance & audit cost", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let cost = e.aiBusinesses.count * (2 + Int(e.corruption * 20))
                return outcome(coinText(Double(cost)), hhClamp(100 - Double(cost), 0, 100), bps(-Double(cost) * 0.2), "Clean books cost money; the market pays for them anyway.")
            },
            MarketFactorSpec(id: "policy.tariffProtection", title: "Tariff protection", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.tariffRate), hhClamp(e.tariffRate * 380, 0, 100), bps((e.tariffRate - 0.04) * 80), "Protected firms keep margin, until their customers notice prices.")
            },
            MarketFactorSpec(id: "policy.tariffInflation", title: "Tariff price pass-through", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let added = e.tariffRate * e.priceIndex * 0.6
                return outcome(pctText(-added / max(0.5, e.priceIndex)), hhClamp(100 - e.tariffRate * 400, 0, 100), bps(-e.tariffRate * 130), "The consumer pays the tariff at the stall, not at the border.")
            },
            MarketFactorSpec(id: "policy.electionProximity", title: "Election proximity", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let proximity = hhClamp(1 - Double(e.electionInDays) / 36, 0, 1)
                return outcome("\(e.electionInDays) days", 50 + proximity * 25, bps(-proximity * 7), "Markets hate uncertainty more than they hate any one party.")
            },
            MarketFactorSpec(id: "policy.partyBias", title: "Governing party tilt", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bias = e.rulingParty.taxBias
                return outcome("\(e.rulingParty.shortTitle) · \(pctText(bias))", hhClamp(100 - bias * 220, 0, 100), bps((0.17 - bias) * 170), "The party in office sets the drift of tax, subsidy and spending.")
            },
            MarketFactorSpec(id: "policy.approval", title: "Approval rating", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.politicalStability), e.politicalStability * 100, bps((e.politicalStability - 0.6) * 32), "A stable government can plan; a wobbling one cannot.")
            },
            MarketFactorSpec(id: "policy.policyVolatility", title: "Policy volatility", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let drift = abs(e.taxRate - e.rulingParty.taxBias)
                    + abs(e.publicSpending - e.rulingParty.spendingBias)
                    + abs(e.tariffRate - e.rulingParty.tariffBias)
                return outcome(pctText(drift), hhClamp(100 - drift * 400, 0, 100), bps(-drift * 90), "Every reversal adds a risk premium that outlives the policy.")
            }
        ]
    }

    // MARK: Earnings

    private static var earningsFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "earn.revenueGrowth", title: "Revenue growth", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let growth = e.aiBusinesses.isEmpty
                    ? 0
                    : e.aiBusinesses.map(\.productivity).reduce(0, +) / Double(e.aiBusinesses.count) - 0.35
                return outcome(pctText(growth), hhClamp(50 + growth * 500, 0, 100), bps(growth * 220), "Top-line growth is what analysts chase first.")
            },
            MarketFactorSpec(id: "earn.margin", title: "Average operating margin", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let margin = hhClamp((e.productivity - e.averageWage / 120) * 0.5, -0.2, 0.4)
                return outcome(pctText(margin), hhClamp(50 + margin * 260, 0, 100), bps(margin * 60), "Margin is the cushion that survives a bad harvest.")
            },
            MarketFactorSpec(id: "earn.earningsYield", title: "Earnings yield", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let yield = max(0.005, e.productivity * 0.12 + 0.02)
                return outcome(pctText(yield), hhClamp(yield * 900, 0, 100), bps((yield - 0.05) * 260), "Compared with the deposit rate, this is the whole buy/sell decision.")
            },
            MarketFactorSpec(id: "earn.returnOnEquity", title: "Return on capital", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let roe = hhClamp(e.productivity * 0.4 + e.technology * 0.1, 0, 0.8)
                return outcome(pctText(roe), roe * 160, bps(roe * 45), "Capital that compounds attracts capital.")
            },
            MarketFactorSpec(id: "earn.assetTurnover", title: "Asset turnover", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let turnover = hhClamp(e.demand / max(1, e.supply) * e.manufacturing + 0.2, 0, 1.5)
                return outcome(String(format: "%.2f×", turnover), hhClamp(turnover / 1.2, 0, 1) * 100, bps((turnover - 0.5) * 18), "How hard each coin of capital works across the year.")
            },
            MarketFactorSpec(id: "earn.interestCoverage", title: "Interest coverage", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let coverage = hhClamp((e.productivity * 8) / max(0.005, e.interestRate * 4 + e.bankruptcyRisk), 0, 40)
                return outcome(String(format: "%.1f×", coverage), hhClamp(coverage * 5, 0, 100), bps(coverage - 12), "Thin cover turns a small rate rise into a solvency event.")
            },
            MarketFactorSpec(id: "earn.leverage", title: "Debt to equity", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let ratio = hhClamp(0.2 + e.bankruptcyRisk * 2.2 + max(0, e.debtToGDP - 0.8), 0, 4)
                return outcome(String(format: "%.2f×", ratio), hhClamp(100 - ratio * 30, 0, 100), bps(-ratio * 8), "Borrowed capital magnifies every outcome, including failure.")
            },
            MarketFactorSpec(id: "earn.freeCashFlow", title: "Free cash flow", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let flow = e.gdp * (e.taxRate - e.publicSpending) * 0.4 + e.exports * 0.3
                return outcome(coinText(flow), hhClamp(50 + flow * 0.4, 0, 100), bps(flow * 0.03), "Cash after spending is what funds buybacks and dividends.")
            },
            MarketFactorSpec(id: "earn.dividendYield", title: "Index dividend yield", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let yield = hhClamp(e.productivity * 0.06 + 0.008, 0, 0.2)
                return outcome(pctText(yield), hhClamp(yield * 1400, 0, 100), bps((yield - 0.03) * 220), "Income buyers step in when yield beats the bank.")
            },
            MarketFactorSpec(id: "earn.payoutRatio", title: "Payout ratio", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let payout = hhClamp(0.25 + e.taxRate * 0.9, 0, 0.9)
                return outcome(pctText(payout), hhClamp(100 - payout * 70, 0, 100), bps((0.42 - payout) * 40), "Paying it out pleases today; retaining it builds tomorrow.")
            },
            MarketFactorSpec(id: "earn.buyback", title: "Buyback capacity", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let capacity = hhClamp((e.consumerConfidence - 0.4) * 2 + e.productivity, 0, 2)
                return outcome(pctText(capacity / 4), hhClamp(capacity * 45, 0, 100), bps(capacity * 8), "Firms with spare cash become their own best customer.")
            },
            MarketFactorSpec(id: "earn.impairmentRisk", title: "Goodwill impairment risk", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let risk = hhClamp(e.corruption * 0.5 + e.bankruptcyRisk * 0.7, 0, 1)
                return outcome(pctText(risk), hhClamp(100 - risk * 90, 0, 100), bps(-risk * 22), "Written-down goodwill is a confession with a delay.")
            },
            MarketFactorSpec(id: "earn.surprise", title: "Earnings surprise", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let surprise = hhClamp((e.consumerConfidence - 0.55) * 0.3 + (e.exports - e.imports) * 0.004, -0.15, 0.15)
                return outcome(pctText(surprise), hhClamp(50 + surprise * 240, 0, 100), bps(surprise * 300), "The gap between whisper and report is where the money is made.")
            },
            MarketFactorSpec(id: "earn.guidance", title: "Guidance risk", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let risk = hhClamp(1 - e.consumerConfidence + e.tariffRate, 0, 1)
                return outcome(pctText(risk), hhClamp(100 - risk * 80, 0, 100), bps(-risk * 10), "Firms that cannot see next season stop hiring.")
            }
        ]
    }

    // MARK: Supply

    private static var supplyFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "supply.harvest", title: "Harvest outlook", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.farmYield), hhClamp(e.farmYield / 1.4, 0, 1) * 100, bps((e.farmYield - 0.7) * 28), "A good harvest is cheap food and busy mills.")
            },
            MarketFactorSpec(id: "supply.soil", title: "Soil health", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.soilFertility), e.soilFertility * 100, bps((e.soilFertility - 0.6) * 24), "Fertility is capital that takes seasons to rebuild.")
            },
            MarketFactorSpec(id: "supply.irrigation", title: "Irrigation coverage", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.irrigation), e.irrigation * 100, bps((e.irrigation - 0.25) * 20), "Water security is yield insurance.")
            },
            MarketFactorSpec(id: "supply.livestock", title: "Livestock output", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let output = e.livestockHealth * (0.6 + e.livestockBreeding)
                return outcome(pctText(output), hhClamp(output, 0, 1) * 100, bps((output - 0.6) * 22), "Dairy and eggs are the steady cash flow of the valley.")
            },
            MarketFactorSpec(id: "supply.coldChain", title: "Cold chain & waste", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let waste = hhClamp(0.22 - e.logistics * 0.2, 0.01, 0.3)
                return outcome(pctText(waste) + " lost", hhClamp(100 - waste * 300, 0, 100), bps((0.12 - waste) * 45), "Spoiled goods are profit that never reaches the stall.")
            },
            MarketFactorSpec(id: "supply.freight", title: "Freight cost", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let cost = hhClamp(1.4 - e.logistics, 0.1, 2)
                return outcome(String(format: "%.2f× base", cost), hhClamp(100 - cost * 60, 0, 100), bps((0.8 - cost) * 16), "Every cart on the river road carries this cost into prices.")
            },
            MarketFactorSpec(id: "supply.energy", title: "Energy price", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let price = hhClamp(1.2 - e.energyCapacity * 0.5 + e.pollution * 0.4, 0.2, 2.5)
                return outcome(String(format: "%.2f× base", price), hhClamp(100 - price * 50, 0, 100), bps((0.9 - price) * 14), "Kilns and pumps stop when power is dear.")
            },
            MarketFactorSpec(id: "supply.waterStress", title: "Water stress", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(1 - e.waterAvailability), (1 - e.waterAvailability) * 100, bps(-(0.3 - e.waterAvailability) * 40), "Shared water is the valley's most political input.")
            },
            MarketFactorSpec(id: "supply.fertiliser", title: "Fertiliser & input cost", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let cost = hhClamp(1 + e.inflation * 3 - e.subsidyRate, 0.4, 3)
                return outcome(String(format: "%.2f× base", cost), hhClamp(100 - cost * 40, 0, 100), bps((1 - cost) * 12), "Input costs decide whether the next field is worth planting.")
            },
            MarketFactorSpec(id: "supply.inputShortage", title: "Input shortage", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let shortage = hhClamp(e.imports / max(1, e.supply) + (1 - e.waterAvailability) * 0.5, 0, 1.5)
                return outcome(pctText(shortage), hhClamp(100 - shortage * 70, 0, 100), bps((0.6 - shortage) * 14), "Shortages show up as queues, then as prices.")
            },
            MarketFactorSpec(id: "supply.capacityGrowth", title: "Capacity growth", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let growth = hhClamp(e.manufacturing * 0.2 + e.technology * 0.1, 0, 0.4)
                return outcome(pctText(growth), hhClamp(growth * 300, 0, 100), bps(growth * 40), "New sheds and presses raise what the valley can sell.")
            },
            MarketFactorSpec(id: "supply.labourAvailability", title: "Labour availability", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.unemployment), e.unemployment * 200, bps(e.unemployment * 18), "Slack in the workforce is room to grow without wage pressure.")
            },
            MarketFactorSpec(id: "supply.strikeRisk", title: "Strike risk", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let risk = hhClamp((0.5 - e.happiness) * 2 + e.poverty, 0, 1)
                return outcome(pctText(risk), hhClamp(100 - risk * 60, 0, 100), bps(-risk * 12), "Unhappy workers can stop the whole supply chain at once.")
            },
            MarketFactorSpec(id: "supply.seasonal", title: "Seasonal factor", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let seasonal: Double
                switch e.lastWeather {
                case .sunny: seasonal = 0.03
                case .rainy: seasonal = 0.05
                case .breezy: seasonal = 0.02
                case .heatwave: seasonal = -0.04
                case .storm: seasonal = -0.06
                }
                return outcome(e.lastWeather.title, hhClamp(50 + seasonal * 400, 0, 100), bps(seasonal * 30), "Weather on the day the books are struck.")
            }
        ]
    }

    // MARK: Trade

    private static var tradeFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "trade.exportOrders", title: "Export orders", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(String(format: "%.1f a day", e.exports), hhClamp(e.exports * 8, 0, 100), bps((e.exports - 5) * 1.6), "Outside coin is the cleanest growth the valley can buy.")
            },
            MarketFactorSpec(id: "trade.importCompetition", title: "Import competition", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(String(format: "%.1f a day", e.imports), hhClamp(100 - e.imports * 6, 0, 100), bps((e.imports - 6) * -1.6), "Cheap imports keep prices low and local margins thin.")
            },
            MarketFactorSpec(id: "trade.balance", title: "Trade balance", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(String(format: "%+.1f", e.tradeBalance), hhClamp(50 + e.tradeBalance * 3, 0, 100), bps(e.tradeBalance * 1.4), "A surplus builds reserves and a currency worth holding.")
            },
            MarketFactorSpec(id: "trade.currency", title: "Currency strength", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.currencyStrength), e.currencyStrength * 100, bps((e.currencyStrength - 0.55) * -16), "A strong valley coin buys cheap imports and discourages buyers abroad.")
            },
            MarketFactorSpec(id: "trade.terms", title: "Terms of trade", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let terms = hhClamp(0.5 + (e.exports - e.imports) / 40, 0, 1)
                return outcome(String(format: "%.2f", terms), terms * 100, bps((terms - 0.5) * 22), "What the valley pays for what it brings in versus what it sells.")
            },
            MarketFactorSpec(id: "trade.tariffBarrier", title: "Tariff barrier", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.tariffRate), hhClamp(100 - e.tariffRate * 260, 0, 100), bps(-e.tariffRate * 55), "Barriers are sticky; buyers move elsewhere and stay there.")
            },
            MarketFactorSpec(id: "trade.shipping", title: "Shipping lanes", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                return outcome(pctText(e.logistics), e.logistics * 100, bps((e.logistics - 0.3) * 16), "Open roads and river docks shorten every delivery.")
            },
            MarketFactorSpec(id: "trade.borderRisk", title: "Border risk", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let risk = hhClamp(1 - e.politicalStability + e.tariffRate, 0, 1)
                return outcome(pctText(risk), hhClamp(100 - risk * 70, 0, 100), bps(-risk * 13), "Every closed border surprises exactly half the market.")
            },
            MarketFactorSpec(id: "trade.foreignDemand", title: "Foreign appetite", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let appetite = hhClamp(e.exports / max(1, e.manufacturing * 30), 0, 2)
                return outcome(String(format: "%.2f× local", appetite), hhClamp(appetite * 50, 0, 100), bps((appetite - 1) * 18), "Distant buyers pay more when local supply is tight.")
            },
            MarketFactorSpec(id: "trade.repatriation", title: "Profit repatriation risk", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let risk = hhClamp(e.corruption * 1.4 + e.tariffRate, 0, 1)
                return outcome(pctText(risk), hhClamp(100 - risk * 90, 0, 100), bps(-risk * 10), "Investors price the chance they cannot take the money home.")
            }
        ]
    }

    // MARK: Flows

    private static var flowFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "flow.sentiment", title: "Market sentiment", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                outcome(pctText(context.sentiment), context.sentiment * 100, bps((context.sentiment - 0.5) * 36), "Sentiment is the amplifier; fundamentals are the signal.")
            },
            MarketFactorSpec(id: "flow.fearGreed", title: "Fear & greed", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                outcome(String(format: "%+.0f", (context.sentiment - 0.5) * 200), hhClamp(context.sentiment * 100, 0, 100), bps((context.sentiment - 0.55) * 22), "Crowded optimism is its own kind of risk.")
            },
            MarketFactorSpec(id: "flow.retailInflows", title: "Retail inflows", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let inflows = e.aiCitizens.reduce(0) { $0 + $1.savings } * 0.002 * e.consumerConfidence
                return outcome(coinText(inflows), hhClamp(inflows * 2, 0, 100), bps((inflows - 3) * 1.8), "Village savings trickle into the exchange when confidence rises.")
            },
            MarketFactorSpec(id: "flow.institutionalBid", title: "Institutional bid", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bid = hhClamp(Double(e.creditScore) / 850 * e.consumerConfidence, 0, 1)
                return outcome(pctText(bid), bid * 100, bps((bid - 0.6) * 26), "Whoever is buying in size sets the price of everything else.")
            },
            MarketFactorSpec(id: "flow.marginDebt", title: "Margin debt", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let debt = e.market?.marginDebt ?? 0
                return outcome(coinText(debt), hhClamp(100 - debt * 0.6, 0, 100), bps(-debt * 0.14), "Borrowed positions turn a dip into a cascade.")
            },
            MarketFactorSpec(id: "flow.shortInterest", title: "Short interest", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                outcome(pctText(context.shortInterest), hhClamp(100 - context.shortInterest * 400, 0, 100), bps(-context.shortInterest * 60), "Heavy shorts press prices down until the squeeze starts.")
            },
            MarketFactorSpec(id: "flow.putCall", title: "Put-to-call skew", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let skew = hhClamp(1 + (1 - context.sentiment) * 0.8 + context.worstShortInterest, 0, 3)
                return outcome(String(format: "%.2f", skew), hhClamp(50 - (skew - 1) * 40, 0, 100), bps(-(skew - 1) * 12), "Hedging demand shows where the fear is concentrated.")
            },
            MarketFactorSpec(id: "flow.crashRisk", title: "Crash risk", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let risk = hhClamp(context.volatility * 8 + max(0, -context.indexChange) * 6, 0, 1)
                return outcome(pctText(risk), hhClamp(100 - risk * 100, 0, 100), bps(-risk * 14), "Fat tails are always larger than the model says.")
            },
            MarketFactorSpec(id: "flow.momentumChasers", title: "Momentum chasing", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let five = (e.market?.marketHistory ?? []).suffix(5)
                let change = five.count >= 2
                    ? (five.last! - five.first!) / max(0.5, five.first!)
                    : context.indexChange
                return outcome(pctText(change), hhClamp(50 + change * 500, 0, 100), bps(change * 90), "Trend followers pile in late and leave late.")
            },
            MarketFactorSpec(id: "flow.capitulation", title: "Capitulation pressure", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let pressure = hhClamp(max(0, -context.indexChange) * 4 + (1 - context.sentiment) * 0.3, 0, 1)
                return outcome(pctText(pressure), hhClamp(pressure * 100, 0, 100), bps(pressure * 10), "Panic selling creates the best entry of the season.")
            },
            MarketFactorSpec(id: "flow.newsTone", title: "News tone", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                guard let event = e.activeEvent else {
                    return outcome("Quiet news day", 55, 0.6, "No headline is moving the tape today.")
                }
                return outcome(event.kind.title, event.kind.isPositive ? 72 : 30, bps(event.impact * 240), event.detail)
            },
            MarketFactorSpec(id: "flow.breadthDivergence", title: "Breadth divergence", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let divergence = context.indexChange - (context.breadth - 0.5) * 0.06
                return outcome(pctText(divergence), hhClamp(50 - divergence * 600, 0, 100), bps(-divergence * 80), "An index held up by two firms is a fragile index.")
            }
        ]
    }

    // MARK: Technicals

    private static var technicalFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "tech.trend5", title: "Five-day trend", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let trend = bars.returnOver(5)
                return outcome(pctText(trend), hhClamp(50 + trend * 600, 0, 100), bps(trend * 70), "Short trend: where the tape actually is.")
            },
            MarketFactorSpec(id: "tech.trend20", title: "Twenty-day trend", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let trend = bars.returnOver(20)
                return outcome(pctText(trend), hhClamp(50 + trend * 300, 0, 100), bps(trend * 45), "Medium trend: the one most traders actually follow.")
            },
            MarketFactorSpec(id: "tech.meanReversion", title: "Mean reversion pull", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let z = (e.market?.indexBars ?? []).zScore(20)
                return outcome(String(format: "%+.2fσ", z), hhClamp(50 - z * 22, 0, 100), bps(-z * 7), "Stretched prices snap back — this is the bounce in the chart.")
            },
            MarketFactorSpec(id: "tech.rsi", title: "RSI (14)", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let rsi = (e.market?.indexBars ?? []).relativeStrengthIndex(14)
                return outcome(String(format: "%.0f", rsi), hhClamp(rsi, 0, 100), bps((50 - rsi) * 0.5), "Above 70 is overbought; below 30 is oversold.")
            },
            MarketFactorSpec(id: "tech.macd", title: "MACD histogram", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let fast = bars.movingAverage(5)
                let slow = bars.movingAverage(20)
                let hist = slow > 0 ? (fast - slow) / slow : 0
                return outcome(pctText(hist), hhClamp(50 + hist * 900, 0, 100), bps(hist * 150), "Momentum of the momentum.")
            },
            MarketFactorSpec(id: "tech.bollinger", title: "Bollinger position", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let z = bars.zScore(20)
                return outcome(String(format: "%.2fσ", z), hhClamp(50 + z * 20, 0, 100), bps(z * 5), "How far outside the normal band the index has strayed.")
            },
            MarketFactorSpec(id: "tech.volatility", title: "Realised volatility", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                outcome(pctText(context.volatility), hhClamp(100 - context.volatility * 1400, 0, 100), bps((0.018 - context.volatility) * 260), "Quiet tape lifts valuations; wild tape cuts them.")
            },
            MarketFactorSpec(id: "tech.volumeTrend", title: "Volume trend", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let recent = bars.averageVolume(5)
                let older = bars.averageVolume(15)
                let trend = older > 0 ? recent / older - 1 : 0
                return outcome(pctText(trend), hhClamp(50 + trend * 120, 0, 100), bps(trend * context.indexChange >= 0 ? trend * 30 : -trend * 30), "Volume confirms a move; without it, the move is a rumour.")
            },
            MarketFactorSpec(id: "tech.gapRisk", title: "Overnight gap risk", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let risk = hhClamp(context.volatility * 3 + (1 - context.liquidity) * 0.2, 0, 1)
                return outcome(pctText(risk), hhClamp(100 - risk * 80, 0, 100), bps(-risk * 11), "Thin books gap through stops while the valley sleeps.")
            },
            MarketFactorSpec(id: "tech.support", title: "Distance to support", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let low = bars.suffix(10).map(\.low).min() ?? 0
                let price = bars.lastClose
                let distance = price > 0 ? (price - low) / price : 0
                return outcome(pctText(distance), hhClamp(distance * 700, 0, 100), bps((0.03 - distance) * 25), "Near support, buyers defend; near resistance, sellers arrive.")
            },
            MarketFactorSpec(id: "tech.resistance", title: "Distance to resistance", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let high = bars.suffix(10).map(\.high).max() ?? 0
                let price = bars.lastClose
                let distance = high > 0 ? (high - price) / high : 0
                return outcome(pctText(distance), hhClamp(distance * 700, 0, 100), bps((distance - 0.03) * 22), "Room to the ceiling is room to run.")
            },
            MarketFactorSpec(id: "tech.breakout", title: "Breakout probability", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bars = e.market?.indexBars ?? []
                let high = bars.suffix(20).map(\.high).max() ?? 0
                let price = bars.lastClose
                let near = high > 0 ? hhClamp(1 - (high - price) / high / 0.05, 0, 1) : 0
                return outcome(pctText(near), near * 100, bps(near * 7), "Coiled prices resolve violently in one direction.")
            },
            MarketFactorSpec(id: "tech.drawdown", title: "Drawdown from peak", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let drawdown = (e.market?.indexBars ?? []).drawdown(30)
                return outcome(pctText(drawdown), hhClamp(100 - drawdown * 400, 0, 100), bps(-drawdown * 30), "Deep drawdowns create bargains and margin calls together.")
            },
            MarketFactorSpec(id: "tech.betaDispersion", title: "Beta dispersion", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let betas = e.market?.listings.map(\.beta) ?? []
                let mean = betas.isEmpty ? 1 : betas.reduce(0, +) / Double(betas.count)
                let dispersion = betas.map { abs($0 - mean) }.reduce(0, +) / Double(max(1, betas.count))
                return outcome(String(format: "%.2f", dispersion), hhClamp(100 - dispersion * 100, 0, 100), bps(-dispersion * 12), "Wide dispersion means stock picking pays and index buying does not.")
            }
        ]
    }

    // MARK: Derivatives

    private static var derivativeFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "deriv.impliedVol", title: "Implied volatility", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let vol = e.market?.volatilityIndex ?? context.volatility * 100
                return outcome(String(format: "%.0f", vol), hhClamp(100 - vol, 0, 100), bps((22 - vol) * 0.6), "Option sellers charge more when they are scared.")
            },
            MarketFactorSpec(id: "deriv.skew", title: "Volatility skew", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let skew = hhClamp((1 - context.sentiment) * 1.6 + context.shortInterest * 2, 0, 2)
                return outcome(String(format: "%.2f", skew), hhClamp(100 - skew * 45, 0, 100), bps(-skew * 6), "Puts cost more than calls when the crowd is hedging.")
            },
            MarketFactorSpec(id: "deriv.borrowFee", title: "Short borrow fee", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let fee = 0.04 + context.worstShortInterest * 0.9
                return outcome(pctText(fee) + " a year", hhClamp(100 - fee * 300, 0, 100), bps(-fee * 25), "Crowded shorts pay rent for the privilege.")
            },
            MarketFactorSpec(id: "deriv.squeeze", title: "Squeeze risk", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let risk = hhClamp(context.worstShortInterest * 4.5, 0, 1)
                return outcome(pctText(risk), risk * 100, bps(risk * 16), "A crowded short book is fuel for a violent rally.")
            },
            MarketFactorSpec(id: "deriv.leveragedFlows", title: "Leveraged flows", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let leveraged = e.market?.holdings.filter { $0.marginDebt > 0 }.count ?? 0
                return outcome("\(leveraged) margined", hhClamp(100 - Double(leveraged) * 8, 0, 100), bps(Double(leveraged) * 1.4), "Leverage adds buyers on the way up and sellers on the way down.")
            },
            MarketFactorSpec(id: "deriv.gamma", title: "Dealer gamma", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let gamma = hhClamp(1 - context.volatility * 12, 0, 1)
                return outcome(pctText(gamma), gamma * 100, bps((gamma - 0.5) * 12), "Dealers hedging dampen moves — until they amplify them.")
            },
            MarketFactorSpec(id: "deriv.liquidationCascade", title: "Liquidation cascade risk", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let exposure = e.market?.leverage ?? 1
                let risk = hhClamp((exposure - 1) * 0.35, 0, 1)
                return outcome(String(format: "%.2fx book", exposure), hhClamp(100 - risk * 110, 0, 100), bps(-risk * 18), "One forced seller becomes five when everyone borrowed together.")
            },
            MarketFactorSpec(id: "deriv.hedging", title: "Hedging demand", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let demand = hhClamp((1 - context.sentiment) * 2 + (context.worstShortInterest), 0, 2)
                return outcome(String(format: "%.2f× normal", demand), hhClamp(100 - demand * 40, 0, 100), bps(-demand * 5), "Insurance buying is bearish in the short run.")
            },
            MarketFactorSpec(id: "deriv.volOfVol", title: "Volatility of volatility", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let volOfVol = hhClamp(context.volatility * 22, 0, 1)
                return outcome(pctText(volOfVol), hhClamp(100 - volOfVol * 80, 0, 100), bps(-volOfVol * 12), "Unstable volatility makes every model unreliable.")
            },
            MarketFactorSpec(id: "deriv.retailLeverage", title: "Household leverage", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let leverage = hhClamp(e.market?.leverage ?? 1, 1, 10)
                return outcome(String(format: "%.1fx", leverage), hhClamp(110 - leverage * 22, 0, 100), bps((1.5 - leverage) * 6), "The valley's own margin book is now part of the tape.")
            }
        ]
    }

    // MARK: Peers

    private static var peerFactors: [MarketFactorSpec] {
        [
            MarketFactorSpec(id: "peer.sectorBreadth", title: "Sector breadth", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                outcome(pctText(context.breadth), context.breadth * 100, bps((context.breadth - 0.5) * 40), "A rally where most firms rise is a real rally.")
            },
            MarketFactorSpec(id: "peer.priceWar", title: "Price war intensity", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let war = e.market?.competitionHeat ?? 0
                return outcome(pctText(war), hhClamp(100 - war * 90, 0, 100), bps(-war * 18), "Undercutting rivals wins customers and destroys margin.")
            },
            MarketFactorSpec(id: "peer.hiringRace", title: "Hiring race", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let open = e.market?.openRoles ?? 0
                return outcome("\(open) open roles", hhClamp(100 - Double(open) * 2, 0, 100), bps(Double(open) * 0.3), "Everyone hiring at once pushes wages up and margins down.")
            },
            MarketFactorSpec(id: "peer.rndRace", title: "R&D race", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let spend = e.market?.competitorRnd ?? 0
                return outcome(coinText(spend), hhClamp(spend * 2, 0, 100), bps(spend * 0.25), "Technology investment is a cost now and a moat later.")
            },
            MarketFactorSpec(id: "peer.marketing", title: "Marketing spend", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let spend = e.market?.competitorMarketing ?? 0
                return outcome(coinText(spend), hhClamp(spend * 1.6, 0, 100), bps(spend * 0.2), "Brands are bought one market day at a time.")
            },
            MarketFactorSpec(id: "peer.supplierDeals", title: "Supplier deals", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let deals = e.market?.supplierAgreements ?? 0
                return outcome("\(deals) contracts", hhClamp(Double(deals) * 12, 0, 100), bps(Double(deals) * 0.8), "Locked-in inputs are margin nobody can undercut.")
            },
            MarketFactorSpec(id: "peer.newEntrants", title: "New entrants", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let recent = e.aiBusinesses.filter { e.day - $0.foundedDay <= 10 }.count
                return outcome("\(recent) this season", hhClamp(100 - Double(recent) * 18, 0, 100), bps(-Double(recent) * 2.2), "New firms split the same demand into more hands.")
            },
            MarketFactorSpec(id: "peer.bankruptcies", title: "Recent failures", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let failed = e.market?.listings.filter(\.isBankrupt).count ?? 0
                return outcome("\(failed) delisted", hhClamp(100 - Double(failed) * 20, 0, 100), bps(-Double(failed) * 1.6), "Failures free up market share and frighten lenders.")
            },
            MarketFactorSpec(id: "peer.concentration", title: "Market concentration", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let shares = e.market?.listings.map { max(0, $0.fundamentals.marketShare) } ?? []
                let hhi = shares.reduce(0) { $0 + $1 * $1 }
                return outcome(String(format: "%.2f", hhi), hhClamp(100 - hhi * 120, 0, 100), bps((0.25 - hhi) * 40), "Concentrated markets price higher and regulate harder.")
            },
            MarketFactorSpec(id: "peer.downgrades", title: "Analyst downgrades", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let warnings = e.market?.listings.filter { $0.fundamentals.profit < 0 }.count ?? 0
                return outcome("\(warnings) loss-making", hhClamp(100 - Double(warnings) * 14, 0, 100), bps(-Double(warnings) * 1.8), "Downgrades arrive after the price has already fallen.")
            },
            MarketFactorSpec(id: "peer.insiderSelling", title: "Insider selling", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let selling = e.market?.listings.filter { $0.insiderSales > 0.25 }.count ?? 0
                return outcome("\(selling) firms", hhClamp(100 - Double(selling) * 16, 0, 100), bps(-Double(selling) * 2.4), "Founders selling their own shares is a signal nobody ignores.")
            },
            MarketFactorSpec(id: "peer.hostileBids", title: "Takeover speculation", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
                let e = context.economy
                let bids = e.market?.takeoverTalk ?? 0
                return outcome("\(bids) in the square", hhClamp(Double(bids) * 20, 0, 100), bps(Double(bids) * 2.6), "A rumoured bid puts a floor under a falling price.")
            }
        ]
    }

    // MARK: Global

    private static var globalFactors: [MarketFactorSpec] {
        var specs: [MarketFactorSpec] = []
        specs.append(MarketFactorSpec(id: "global.commodityCycle", title: "Commodity cycle", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let cycle = sin(Double(e.day) * 0.19) * 0.4 + (e.inflation - 0.02) * 3
            return outcome(pctText(cycle), hhClamp(50 + cycle * 90, 0, 100), bps(cycle * 12), "Commodity swings hit the valley twice: costs in, prices out.")
        })
        specs.append(MarketFactorSpec(id: "global.freightIndex", title: "Global freight index", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let index = hhClamp(1.2 - e.logistics * 0.6 + e.tariffRate, 0.3, 2)
            return outcome(String(format: "%.2f", index), hhClamp(100 - index * 45, 0, 100), bps((0.9 - index) * 10), "Freight is the tax on distance.")
        })
        specs.append(MarketFactorSpec(id: "global.riskAppetite", title: "Global risk appetite", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let appetite = hhClamp(context.sentiment * 0.6 + (1 - context.volatility * 20) * 0.4, 0, 1)
            return outcome(pctText(appetite), appetite * 100, bps((appetite - 0.5) * 24), "When the wider world is brave, the valley gets visitors.")
        })
        specs.append(MarketFactorSpec(id: "global.centralBankTone", title: "Central bank tone", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let hawkish = hhClamp(e.interestRate * 6 + e.inflation * 2, 0, 1)
            return outcome(hawkish > 0.5 ? "Hawkish" : "Dovish", hhClamp(100 - hawkish * 90, 0, 100), bps(-hawkish * 12), "The valley's rate setters read the same inflation board as everyone else.")
        })
        specs.append(MarketFactorSpec(id: "global.geopolitics", title: "Geopolitical risk", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let risk = hhClamp((1 - e.politicalStability) * 0.6 + e.tariffRate * 0.8 + e.corruption * 0.4, 0, 1)
            return outcome(pctText(risk), hhClamp(100 - risk * 70, 0, 100), bps(-risk * 14), "Distant quarrels raise insurance on every shipment.")
        })
        specs.append(MarketFactorSpec(id: "global.weatherAnomaly", title: "Weather anomaly", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            var anomaly = 0.0
            switch e.lastWeather {
            case .heatwave: anomaly = 0.5
            case .storm: anomaly = 0.6
            case .rainy: anomaly = -0.2
            default: anomaly = 0
            }
            return outcome(e.lastWeather.title, hhClamp(100 - anomaly * 80, 0, 100), bps(-anomaly * 9), "Climate is now a line item in every forecast.")
        })
        specs.append(MarketFactorSpec(id: "global.techCycle", title: "Technology cycle", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let cycle = hhClamp(e.technology * 0.7 + Double(e.researchLevel) / 12, 0, 1)
            return outcome(pctText(cycle), cycle * 100, bps((cycle - 0.4) * 18), "New tools re-rate the firms that own them.")
        })
        specs.append(MarketFactorSpec(id: "global.contagion", title: "Contagion index", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let failed = e.market?.listings.filter { $0.isBankrupt }.count ?? 0
            let pressure = hhClamp(Double(failed) * 0.08 + e.bankruptcyRisk * 0.6, 0, 1)
            return outcome(pctText(pressure), hhClamp(100 - pressure * 110, 0, 100), bps(-pressure * 16), "One valley's credit event is its neighbour's funding cost.")
        })
        return specs
    }


    // MARK: Extended Global

    private static var extendedGlobalFactors: [MarketFactorSpec] {
        var specs: [MarketFactorSpec] = []
        specs.append(MarketFactorSpec(id: "global.foreignCapital", title: "Foreign capital pull", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let books = hhClamp(e.netWorth / max(1, e.gdp) / 3, 0, 1)
            let pull = hhClamp(e.currencyStrength * 0.6 + books * 0.4, 0, 1)
            return outcome(pctText(pull), pull * 100, bps((pull - 0.5) * 10), "Outside money buys the valley only when its coin and books both look sound.")
        })
        specs.append(MarketFactorSpec(id: "global.marketLiquidity", title: "World liquidity", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let liquidity = hhClamp(context.liquidity * 0.8 + context.shortInterest * 0.2, 0, 1)
            return outcome(pctText(liquidity), hhClamp(100 - liquidity * 100, 0, 100), bps((liquidity - 0.5) * 22), "Global liquidity sets the baseline for all pricing.")
        })
        specs.append(MarketFactorSpec(id: "global.policyDivergence", title: "Policy divergence", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let divergence = abs(e.taxRate - e.rulingParty.taxBias) + abs(e.publicSpending - e.rulingParty.spendingBias) + abs(e.tariffRate - e.rulingParty.tariffBias)
            return outcome(pctText(divergence), hhClamp(100 - divergence * 200, 0, 100), bps(-divergence * 18), "When tax and spending drift from the party platform, markets price the risk.")
        })
        specs.append(MarketFactorSpec(id: "global.interestRateSpread", title: "Interest rate spread", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let spread = e.interestRate - e.inflation
            return outcome(pctText(spread), hhClamp(50 + spread * 400, 0, 100), bps(spread * 30), "Currency carry trades follow the spread.")
        })
        specs.append(MarketFactorSpec(id: "global.currencyWar", title: "Currency war", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let pressure = hhClamp(e.tariffRate * 1.2 + (1 - e.currencyStrength) * 0.6, 0, 1)
            return outcome(pctText(pressure), hhClamp(100 - pressure * 85, 0, 100), bps(-pressure * 13), "Cheapening a currency exports the problem to a neighbour.")
        })
        specs.append(MarketFactorSpec(id: "global.supplyChainStress", title: "Supply chain stress", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let stress = hhClamp((1 - e.logistics) * 0.7 + e.imports / max(1, e.supply) * 0.5, 0, 1)
            return outcome(pctText(stress), hhClamp(100 - stress * 80, 0, 100), bps(-stress * 12), "A single blocked road re-routes an entire season of goods.")
        })
        specs.append(MarketFactorSpec(id: "global.pandemicRisk", title: "Public health shock risk", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let risk = hhClamp((1 - e.health) * 0.7 + e.poverty * 0.3, 0, 1)
            return outcome(pctText(risk), hhClamp(100 - risk * 90, 0, 100), bps(-risk * 15), "Illness removes workers before it removes demand.")
        })
        specs.append(MarketFactorSpec(id: "global.energyTransition", title: "Energy transition", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let progress = hhClamp(e.renewableShare * 0.6 + e.infrastructure * 0.4, 0, 1)
            return outcome(pctText(progress), progress * 100, bps((progress - 0.4) * 14), "Cheap clean power is the newest comparative advantage.")
        })
        specs.append(MarketFactorSpec(id: "global.regulatoryWave", title: "Regulatory wave", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let burden = hhClamp(e.corruption * 0.5 + (1 - e.publicServices) * 0.5, 0, 1)
            return outcome(pctText(burden), hhClamp(100 - burden * 75, 0, 100), bps(-burden * 11), "Rules written for a scandal tax everyone who did not cause it.")
        })
        specs.append(MarketFactorSpec(id: "global.demographicDrag", title: "Demographic drag", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let workers = Double(e.workforce) / Double(max(1, e.population))
            let drag = hhClamp(0.6 - workers + max(0, -e.populationMomentum), -0.3, 0.6)
            return outcome(pctText(drag), hhClamp(60 - drag * 100, 0, 100), bps(-drag * 12), "Fewer workers per resident means a smaller base for every tax and sale.")
        })
        return specs
    }


    // MARK: Extended catalogue (second wave)

    /// A second pass over every group: the numbers a serious desk watches once
    /// the headline factors are already priced in.
    private static var extendedFactors: [MarketFactorSpec] {
        var specs: [MarketFactorSpec] = []

        // Macro & activity
        specs.append(MarketFactorSpec(id: "macro.productivityTrend", title: "Productivity trend", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(String(format: "%.2f pts", e.productivity), hhClamp(e.productivity * 100, 0, 100), bps((e.productivity - 0.5) * 22), "Output per worker decides which firms can pay wages and still profit.")
        })
        specs.append(MarketFactorSpec(id: "macro.populationMomentum", title: "Population momentum", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let momentum = e.populationMomentum
            return outcome(pctText(momentum), hhClamp(50 + momentum * 400, 0, 100), bps(momentum * 160), "A growing valley widens every market by itself.")
        })
        specs.append(MarketFactorSpec(id: "macro.creditStanding", title: "Valley credit standing", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let score = Double(e.creditScore)
            return outcome("\(e.creditScore)", hhClamp(score / 8.5, 0, 100), bps((score - 600) * 0.08), "Borrowing costs fall for a valley lenders trust.")
        })
        specs.append(MarketFactorSpec(id: "macro.publicServices", title: "Public service quality", group: .macro) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.publicServices), e.publicServices * 100, bps((e.publicServices - 0.5) * 18), "Good services lower the friction on every transaction.")
        })

        // Rates & money
        specs.append(MarketFactorSpec(id: "rates.realBorrowCost", title: "Real cost of borrowing", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let real = e.interestRate - e.inflation
            return outcome(pctText(real), hhClamp(60 - real * 500, 0, 100), bps(-real * 150), "Money only stays cheap while the real rate is low.")
        })
        specs.append(MarketFactorSpec(id: "rates.currencyStrength", title: "Valley currency strength", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.currencyStrength), hhClamp(e.currencyStrength, 0, 1) * 100, bps((e.currencyStrength - 0.5) * 26), "A firm currency buys imports cheaply and frightens exporters.")
        })
        specs.append(MarketFactorSpec(id: "rates.priceIndex", title: "Price index level", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(String(format: "%.2f", e.priceIndex), hhClamp(100 - (e.priceIndex - 1) * 90, 0, 100), bps((1 - e.priceIndex) * 9), "A rising index squeezes margins before it lifts revenue.")
        })
        specs.append(MarketFactorSpec(id: "rates.loanBook", title: "Outstanding loan book", group: .rates) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let book = Double(e.loans.count)
            return outcome("\(e.loans.count) loans", hhClamp(100 - book * 4, 0, 100), bps(-book * 0.8), "Every loan on the book is a claim that must be serviced.")
        })

        // Tax, politics & policy
        specs.append(MarketFactorSpec(id: "policy.subsidyReach", title: "Subsidy reach", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.subsidyRate), hhClamp(e.subsidyRate * 400, 0, 100), bps(e.subsidyRate * 40), "Subsidies move costs off the firm and onto the treasury.")
        })
        specs.append(MarketFactorSpec(id: "policy.publicDebtLoad", title: "Public debt load", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let load = e.publicDebt / max(1, e.gdp)
            return outcome(String(format: "%.0f%% of GDP", load * 100), hhClamp(100 - load * 45, 0, 100), bps(-load * 6), "Heavy debt crowds private borrowers out of the market.")
        })
        specs.append(MarketFactorSpec(id: "policy.electionClock", title: "Election countdown", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let soon = e.electionInDays <= 0 ? 0.0 : hhClamp(1 - Double(e.electionInDays) / 120, 0, 1)
            return outcome("\(e.electionInDays) days", hhClamp(70 - soon * 40, 0, 100), bps(-soon * 7), "Markets price promises badly when the ballot is close.")
        })
        specs.append(MarketFactorSpec(id: "policy.institutionalTrust", title: "Institutional trust", group: .policy) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let trust = hhClamp(e.politicalStability * 0.6 + (1 - e.corruption) * 0.4, 0, 1)
            return outcome(pctText(trust), trust * 100, bps((trust - 0.5) * 20), "Contracts are only worth what the courts will enforce.")
        })

        // Earnings & balance sheets
        specs.append(MarketFactorSpec(id: "earnings.netWorthMomentum", title: "Valley net worth", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let worth = e.netWorth / max(1, e.gdp)
            return outcome(String(format: "%.2f× GDP", worth), hhClamp(worth * 18, 0, 100), bps((worth - 2) * 3), "Balance sheets, not opinions, decide who survives a bad quarter.")
        })
        specs.append(MarketFactorSpec(id: "earnings.wagePressure", title: "Wage pressure", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let pressure = hhClamp(e.averageWage / max(0.01, e.priceIndex * 30) - 1, -0.4, 0.4)
            return outcome(pctText(pressure) + " vs budget", hhClamp(55 - pressure * 60, 0, 100), bps(-pressure * 30), "Wages outrunning prices are a cost line before they are a demand line.")
        })
        specs.append(MarketFactorSpec(id: "earnings.marginSpread", title: "Margin spread", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let spread = e.priceIndex - e.averageWage / 30
            return outcome(pctText(spread), hhClamp(50 + spread * 250, 0, 100), bps(spread * 40), "Selling prices above unit costs is the whole game.")
        })
        specs.append(MarketFactorSpec(id: "earnings.researchPipeline", title: "Research pipeline", group: .earnings) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(String(format: "%.0f pts", e.researchPoints), hhClamp(Double(e.researchLevel) * 7 + e.researchPoints * 0.2, 0, 100), bps((Double(e.researchLevel) - 5) * 1.5), "Unfinished research is a promise the market discounts early.")
        })

        // Supply & real economy
        specs.append(MarketFactorSpec(id: "supply.farmYield", title: "Farm yields", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(String(format: "%.2f×", e.farmYield), hhClamp(e.farmYield * 60, 0, 100), bps((e.farmYield - 1) * 24), "The harvest is the valley's original earnings season.")
        })
        specs.append(MarketFactorSpec(id: "supply.waterSecurity", title: "Water security", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.waterAvailability), e.waterAvailability * 100, bps((e.waterAvailability - 0.5) * 16), "Irrigation decides whether a dry spell is a headline or a crisis.")
        })
        specs.append(MarketFactorSpec(id: "supply.soilHealth", title: "Soil degradation", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let damage = hhClamp(e.soilDegradation, 0, 1)
            return outcome(pctText(damage), (1 - damage) * 100, bps(-damage * 12), "Erosion is a slow tax on every future harvest.")
        })
        specs.append(MarketFactorSpec(id: "supply.energyMix", title: "Renewable energy share", group: .supply) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.renewableShare), e.renewableShare * 100, bps((e.renewableShare - 0.3) * 12), "Cheaper power widens margins where the work is heaviest.")
        })

        // Trade & currency
        specs.append(MarketFactorSpec(id: "trade.exportMomentum", title: "Export momentum", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(String(format: "%.0f units", e.exports), hhClamp(e.exports / max(1, e.demand) * 80, 0, 100), bps((e.exports / max(1, e.demand) - 0.3) * 26), "Foreign buyers pay in hard currency and steady the whole valley.")
        })
        specs.append(MarketFactorSpec(id: "trade.importDependence", title: "Import dependence", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let dependence = e.imports / max(1, e.supply)
            return outcome(String(format: "%.2f× supply", dependence), hhClamp(100 - dependence * 80, 0, 100), bps(-(dependence - 0.3) * 20), "Every import is a price the valley does not control.")
        })
        specs.append(MarketFactorSpec(id: "trade.balanceOfTrade", title: "Balance of trade", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let balance = (e.exports - e.imports) / max(1, e.gdp)
            return outcome(pctText(balance), hhClamp(50 + balance * 200, 0, 100), bps(balance * 90), "A surplus builds reserves; a deficit builds obligations.")
        })
        specs.append(MarketFactorSpec(id: "trade.logisticsCost", title: "Logistics cost", group: .trade) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(1 - e.logistics), hhClamp(e.logistics * 100, 0, 100), bps((e.logistics - 0.5) * 20), "Every mile of bad road shows up in the delivered price.")
        })

        // Flows & sentiment
        specs.append(MarketFactorSpec(id: "flows.breadthThrust", title: "Market breadth", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
            return outcome(pctText(context.breadth), hhClamp(context.breadth, 0, 1) * 100, bps((context.breadth - 0.5) * 18), "A rally carried by a few names is a rally nobody trusts.")
        })
        specs.append(MarketFactorSpec(id: "flows.volatilityRegime", title: "Volatility regime", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
            return outcome(pctText(context.volatility), hhClamp(100 - context.volatility * 90, 0, 100), bps(-context.volatility * 90), "Calm markets let leverage grow; violent ones collect it back.")
        })
        specs.append(MarketFactorSpec(id: "flows.shortCrowding", title: "Short crowding", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let worst = context.worstShortInterest
            return outcome(pctText(worst), hhClamp(100 - worst * 120, 0, 100), bps(-worst * 10), "Crowded shorts are fuel for a squeeze in the other direction.")
        })
        specs.append(MarketFactorSpec(id: "flows.indexMomentum", title: "Index momentum", group: .flows) { (context: MarketFactorContext) -> MarketFactorOutcome in
            return outcome(pctText(context.indexChange), hhClamp(50 + context.indexChange * 400, 0, 100), bps(context.indexChange * 120), "Yesterday's move is the cheapest input every trader has.")
        })

        // Technicals & structure
        specs.append(MarketFactorSpec(id: "technicals.seasonalDrift", title: "Seasonal drift", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let season = sin(Double(e.day) * 0.05) * 0.5
            return outcome(String(format: "%+.2f", season), hhClamp(50 + season * 60, 0, 100), bps(season * 8), "Markets keep a calendar even when the news does not.")
        })
        specs.append(MarketFactorSpec(id: "technicals.liquidityDepth", title: "Liquidity depth", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
            return outcome(pctText(context.liquidity), hhClamp(context.liquidity, 0, 1) * 100, bps((context.liquidity - 0.5) * 16), "Thin books turn ordinary orders into accidents.")
        })
        specs.append(MarketFactorSpec(id: "technicals.sentimentSpread", title: "Sentiment spread", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let gap = context.sentiment - context.breadth
            return outcome(String(format: "%+.2f", gap), hhClamp(50 + gap * 110, 0, 100), bps(gap * 30), "When mood runs ahead of participation, positioning is stretched.")
        })
        specs.append(MarketFactorSpec(id: "technicals.volatilityCompression", title: "Volatility compression", group: .technicals) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let squeeze = hhClamp(1 - context.volatility * 30, 0, 1)
            return outcome(pctText(squeeze), hhClamp(squeeze * 100, 0, 100), bps((squeeze - 0.5) * 18), "Compressed ranges resolve violently in one direction.")
        })

        // Derivatives & positioning
        specs.append(MarketFactorSpec(id: "derivatives.shortSkew", title: "Short interest skew", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let skew = context.worstShortInterest - context.shortInterest
            return outcome(pctText(skew), hhClamp(70 - skew * 80, 0, 100), bps(-skew * 35), "Where the bears concentrate is where the pain would be largest.")
        })
        specs.append(MarketFactorSpec(id: "derivatives.tailRisk", title: "Tail risk premium", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let tail = hhClamp(context.volatility * (1 + context.worstShortInterest), 0, 2)
            return outcome(pctText(tail), hhClamp(100 - tail * 60, 0, 100), bps(-tail * 9), "Insurance is cheapest exactly when nobody wants it.")
        })
        specs.append(MarketFactorSpec(id: "derivatives.carryCurve", title: "Carry curve", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let carry = e.interestRate - e.inflation * 0.8
            return outcome(pctText(carry), hhClamp(55 + carry * 500, 0, 100), bps(carry * 150), "Whoever borrows short and lends long earns the curve, until it inverts.")
        })
        specs.append(MarketFactorSpec(id: "derivatives.crowdingIndex", title: "Positioning crowding", group: .derivatives) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let crowd = hhClamp(context.shortInterest * 0.6 + (1 - context.breadth) * 0.4, 0, 1)
            return outcome(pctText(crowd), hhClamp(100 - crowd * 90, 0, 100), bps(-crowd * 12), "Uniform positioning makes the exit door narrower than the entrance.")
        })

        // Competitors & sectors
        specs.append(MarketFactorSpec(id: "peers.competitionIntensity", title: "Competition intensity", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.competition), hhClamp(100 - e.competition * 140, 0, 100), bps(-e.competition * 14), "Crowded markets split the same demand across more hands.")
        })
        specs.append(MarketFactorSpec(id: "peers.aiBusinessCount", title: "Rival firm count", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let count = Double(e.aiBusinesses.count)
            return outcome("\(e.aiBusinesses.count) firms", hhClamp(100 - count * 3, 0, 100), bps(-count * 0.7), "Every new competitor lowers the value of an existing franchise.")
        })
        specs.append(MarketFactorSpec(id: "peers.distressCluster", title: "Peer distress", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.bankruptcyRisk), hhClamp(100 - e.bankruptcyRisk * 130, 0, 100), bps(-e.bankruptcyRisk * 15), "A neighbour's failure frees its customers and scares its lenders.")
        })
        specs.append(MarketFactorSpec(id: "peers.marketConcentration", title: "Listing depth", group: .peers) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let listed = Double(e.market?.listings.count ?? 0)
            let concentration = hhClamp(1 / max(1, listed) * 4, 0, 1)
            return outcome("\(Int(listed)) listed", hhClamp(100 - concentration * 70, 0, 100), bps((0.4 - concentration) * 12), "Few listings mean crowded ownership of too little choice.")
        })

        // Global & risk
        specs.append(MarketFactorSpec(id: "global.inequalityGap", title: "Inequality gap", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.inequality), hhClamp(100 - e.inequality * 110, 0, 100), bps(-e.inequality * 10), "Concentrated income narrows the customer base every firm needs.")
        })
        specs.append(MarketFactorSpec(id: "global.environmentalRisk", title: "Environmental risk", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let risk = hhClamp(e.pollution * 0.7 + (1 - e.biodiversity) * 0.3, 0, 1)
            return outcome(pctText(risk), hhClamp(100 - risk * 70, 0, 100), bps(-risk * 11), "Pollution is a liability that eventually reaches the income statement.")
        })
        specs.append(MarketFactorSpec(id: "global.publicHealth", title: "Public health", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.health), e.health * 100, bps((e.health - 0.6) * 14), "Healthy workers miss fewer shifts and learn faster.")
        })
        specs.append(MarketFactorSpec(id: "global.biodiversityBuffer", title: "Biodiversity buffer", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            let buffer = hhClamp(e.biodiversity * 0.6 + e.cropDiversity * 0.4, 0, 1)
            return outcome(pctText(buffer), buffer * 100, bps((buffer - 0.5) * 10), "Variety is the valley's insurance against a single bad season.")
        })
        specs.append(MarketFactorSpec(id: "global.crimeDrag", title: "Crime drag", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.crime), hhClamp(100 - e.crime * 120, 0, 100), bps(-e.crime * 12), "Every unit of crime is a cost the honest businesses absorb.")
        })
        specs.append(MarketFactorSpec(id: "global.infrastructureGap", title: "Infrastructure gap", group: .global) { (context: MarketFactorContext) -> MarketFactorOutcome in
            let e = context.economy
            return outcome(pctText(e.infrastructure), e.infrastructure * 100, bps((e.infrastructure - 0.5) * 13), "Roads, power and water pricing underneath every trade.")
        })
        return specs
    }


}

// MARK: - Signals on a single listing

public struct MarketSignal: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var valueText: String
    public var score: Double
    public var isBullish: Bool
    public var detail: String

    public init(id: String, title: String, valueText: String, score: Double, isBullish: Bool, detail: String) {
        self.id = id
        self.title = title
        self.valueText = valueText
        self.score = hhClamp(score, 0, 100)
        self.isBullish = isBullish
        self.detail = detail
    }
}

extension BusinessListing {
    /// The quick-read research sheet the exchange shows before a trade: enough
    /// numbers to argue both the long and the short case.
    public var signals: [MarketSignal] {
        let bars = effectiveBars
        let momentum = bars.returnOver(10)
        let z = bars.zScore(20)
        let rsi = bars.relativeStrengthIndex(14)
        let vol = bars.volatility(20)
        let drawdown = bars.drawdown(30)
        let mean = bars.movingAverage(20)
        let versusMean = mean > 0 ? bars.lastClose / mean - 1 : 0
        var signalList: [MarketSignal] = []
        signalList.append(
            MarketSignal(
                id: "signal.momentum",
                title: "10-day momentum",
                valueText: String(format: "%+.1f%%", momentum * 100),
                score: 50 + momentum * 400,
                isBullish: momentum >= 0,
                detail: momentum >= 0 ? "Buyers still control the tape." : "Sellers have the tape; rallies are being sold."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.stretch",
                title: "Stretch vs average",
                valueText: String(format: "%+.2f sigma", z),
                score: 50 - z * 20,
                isBullish: z <= 0,
                detail: z > 1
                    ? "Price is well above its own average and can bounce down."
                    : z < -1
                        ? "Price is well below its average and can bounce up."
                        : "Price is near its average."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.rsi",
                title: "RSI (14)",
                valueText: String(format: "%.0f", rsi),
                score: rsi,
                isBullish: rsi < 70,
                detail: rsi >= 70
                    ? "Overbought: chasing here is expensive."
                    : rsi <= 30 ? "Oversold: the crowd has already sold." : "Neither stretched nor washed out."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.vol",
                title: "Realised volatility",
                valueText: String(format: "%.1f%%", vol * 100),
                score: 100 - vol * 1600,
                isBullish: vol < 0.04,
                detail: vol < 0.03 ? "Calm price action; tight stops survive here." : "Wide swings; smaller size is the only defence."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.drawdown",
                title: "Drawdown from high",
                valueText: String(format: "%.1f%%", drawdown * 100),
                score: 100 - drawdown * 350,
                isBullish: drawdown < 0.1,
                detail: drawdown > 0.2
                    ? "Deep drop: value or value trap, depending on the books."
                    : "Near its recent high."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.trend",
                title: "Price vs 20-day mean",
                valueText: String(format: "%+.1f%%", versusMean * 100),
                score: 50 + versusMean * 300,
                isBullish: versusMean >= 0,
                detail: "A simple trend filter: above the mean is up, below is down."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.short",
                title: "Short interest",
                valueText: String(format: "%.1f%%", shortInterest * 100),
                score: 100 - shortInterest * 350,
                isBullish: shortInterest > 0.12,
                detail: shortInterest > 0.12 ? "Crowded short: squeezes can be violent." : "Few shares are sold short."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.book",
                title: "Price to book",
                valueText: String(format: "%.2f x", priceToBook),
                score: 120 - priceToBook * 30,
                isBullish: priceToBook < 2,
                detail: priceToBook < 1 ? "Below book: the market doubts the assets." : "Above book: the market is paying for growth."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.yield",
                title: "Dividend yield",
                valueText: String(format: "%.1f%%", dividendYield * 100),
                score: dividendYield * 1400,
                isBullish: dividendYield > 0.02,
                detail: dividendYield > 0.02 ? "Income supports the price when growth stalls." : "Little income support here."
            )
        )
        signalList.append(
            MarketSignal(
                id: "signal.fraud",
                title: "Fraud risk",
                valueText: String(format: "%.0f%%", fundamentals.fraudRisk * 100),
                score: 100 - fundamentals.fraudRisk * 160,
                isBullish: fundamentals.fraudRisk < 0.2,
                detail: fundamentals.fraudRisk > 0.3 ? "Forensic audits exist for firms like this one." : "Books look ordinary."
            )
        )
        return signalList
    }

    public var bullishSignals: Int { signals.filter(\.isBullish).count }

    public var verdict: String {
        let bulls = bullishSignals
        if bulls >= 8 { return "Strong setup" }
        if bulls >= 6 { return "Leaning long" }
        if bulls >= 4 { return "Two-sided" }
        if bulls >= 2 { return "Leaning short" }
        return "Broken tape"
    }

    /// Old saves have candles built from the close series the first time the
    /// exchange wakes up.
    public var effectiveBars: [PriceBar] {
        if !bars.isEmpty { return bars }
        return priceHistory.enumerated().map { index, price in
            PriceBar(day: index + 1, open: price, high: price * 1.005, low: price * 0.995, close: price, volume: 100)
        }
    }
}

// MARK: - Random helpers

/// Box–Muller normal draw from the deterministic game RNG. Fat-tailed markets
/// need a real distribution, not a uniform nudge.
public func hhGaussian(_ rng: inout GameRNG) -> Double {
    let u1 = max(1e-9, rng.double01())
    let u2 = rng.double01()
    return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
}
