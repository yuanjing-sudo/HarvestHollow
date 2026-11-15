import Foundation

/// The persistent state of the valley economy. The simulation is intentionally
/// dense: every number below participates in at least two feedback loops.
public struct ValleyEconomy: Codable, Equatable, Sendable {
    public var tier: EconomyTier
    public var lastKnownLevel: Int
    public var day: Int
    public var lastWeather: Weather

    // People & work
    public var population: Int
    public var populationMomentum: Double
    public var workforce: Int
    public var employed: Int
    public var unemployment: Double
    public var averageWage: Double
    public var education: Double
    public var health: Double
    public var happiness: Double
    public var poverty: Double
    public var inequality: Double
    public var crime: Double
    public var corruption: Double

    // Land & resources
    public var soilFertility: Double
    public var soilDegradation: Double
    public var irrigation: Double
    public var cropDiversity: Double
    public var livestockHealth: Double
    public var livestockBreeding: Double
    public var animalWelfare: Double
    public var waterAvailability: Double
    public var energyCapacity: Double
    public var renewableShare: Double
    public var pollution: Double
    public var biodiversity: Double

    // Markets
    public var demand: Double
    public var supply: Double
    public var farmYield: Double
    public var priceIndex: Double
    public var inflation: Double
    public var interestRate: Double
    public var currencyStrength: Double
    public var consumerConfidence: Double

    // Business, industry & technology
    public var productivity: Double
    public var technology: Double
    public var researchPoints: Double
    public var researchLevel: Int
    public var manufacturing: Double
    public var logistics: Double
    public var exports: Double
    public var imports: Double
    public var tariffRate: Double
    public var competition: Double

    // Government
    public var taxRate: Double
    public var subsidyRate: Double
    public var publicSpending: Double
    public var governmentBalance: Double
    public var publicDebt: Double
    public var politicalStability: Double
    public var rulingParty: PoliticalParty
    public var electionInDays: Int
    public var infrastructure: Double
    public var publicServices: Double

    // Finance
    public var creditScore: Int
    public var loans: [EconomyLoan]
    public var bankruptcyRisk: Double
    public var netWorth: Double

    // Agents
    public var aiBusinesses: [AIBusiness]
    public var aiCitizens: [AICitizen]

    // Memory
    public var activeEvent: EconomyEventRecord?
    public var eventHistory: [EconomyEventRecord]
    public var history: [EconomySnapshot]
    public var lastReport: EconomyReport?
    public var lastPolicyDay: Int

    public init(level: Int = 1) {
        tier = EconomyTier.forLevel(level)
        lastKnownLevel = level
        day = 1
        lastWeather = .sunny

        population = 48
        populationMomentum = 0.001
        workforce = 27
        employed = 25
        unemployment = 0.07
        averageWage = 28
        education = 0.36
        health = 0.58
        happiness = 0.62
        poverty = 0.23
        inequality = 0.34
        crime = 0.09
        corruption = 0.05

        soilFertility = 0.62
        soilDegradation = 0.18
        irrigation = 0.22
        cropDiversity = 0.28
        livestockHealth = 0.66
        livestockBreeding = 0.22
        animalWelfare = 0.6
        waterAvailability = 0.7
        energyCapacity = 0.45
        renewableShare = 0.12
        pollution = 0.15
        biodiversity = 0.58

        demand = 18
        supply = 21
        farmYield = 0.62
        priceIndex = 1
        inflation = 0.02
        interestRate = 0.045
        currencyStrength = 0.5
        consumerConfidence = 0.55

        productivity = 0.35
        technology = 0.2
        researchPoints = 0
        researchLevel = 1
        manufacturing = 0.16
        logistics = 0.24
        exports = 4.5
        imports = 5.5
        tariffRate = 0.04
        competition = 0.42

        taxRate = 0.17
        subsidyRate = 0.035
        publicSpending = 0.16
        governmentBalance = 0
        publicDebt = 80
        politicalStability = 0.68
        rulingParty = .green
        electionInDays = 26
        infrastructure = 0.34
        publicServices = 0.38

        creditScore = 620
        loans = []
        bankruptcyRisk = 0.04
        netWorth = 350

        aiBusinesses = ValleyEconomy.seedBusinesses(level: level)
        aiCitizens = ValleyEconomy.seedCitizens()
        activeEvent = nil
        eventHistory = []
        history = []
        lastReport = nil
        lastPolicyDay = 0

        history = [snapshot()]
    }

    public static func seedBusinesses(level: Int) -> [AIBusiness] {
        let tier = EconomyTier.forLevel(level)
        let kinds: [AIBusinessKind] = [.bakery, .marketStall, .mill, .dairy, .workshop]
        let names = ["Hollow Bakery", "Clover Stall", "Mill on the Bend", "Daisy Dairy", "Bramble Workshop"]
        let count = min(tier.maxFirms, max(1, tier.rawValue + 2))
        var result: [AIBusiness] = []
        result.reserveCapacity(count)
        for index in 0..<count {
            let name = names[index % names.count]
            let kind = kinds[index % kinds.count]
            let employees = 2 + index % 2
            let capital = 24.0 + Double(index) * 6
            let productivity = 0.38 + Double(index) * 0.025
            let technology = 0.18 + Double(index) * 0.02
            result.append(AIBusiness(
                name: name,
                kind: kind,
                employees: employees,
                capital: capital,
                productivity: productivity,
                technology: technology,
                foundedDay: 1
            ))
        }
        return result
    }

    public static func seedCitizens() -> [AICitizen] {
        let names = ["Mara", "Tomas", "Elsie", "Bram", "Nell", "Oren"]
        let jobs = ["Baker", "Farmhand", "Teacher", "Carter", "Clerk", "Herbalist"]
        return names.enumerated().map { index, name in
            AICitizen(
                name: name,
                age: 22 + index * 7,
                job: jobs[index],
                income: 24 + Double(index) * 2,
                savings: 30 + Double(index) * 8,
                happiness: 0.58 + Double(index % 3) * 0.04,
                health: 0.62,
                education: 0.34 + Double(index % 4) * 0.04,
                employed: index < 5,
                consumption: 12 + Double(index)
            )
        }
    }

    // MARK: - Derived values

    public var gdp: Double {
        Double(population) * averageWage * (0.72 + productivity)
            + exports * 4.2
            + manufacturing * 110
            + aiBusinesses.reduce(0) { $0 + $1.output * 0.18 }
    }

    public var realWage: Double {
        averageWage / max(0.35, priceIndex)
    }

    public var taxRevenue: Double { gdp * taxRate }

    public var subsidyCost: Double { gdp * subsidyRate }

    public var publicSpendingAmount: Double { gdp * publicSpending }

    public var tradeBalance: Double { exports - imports }

    public var debtToGDP: Double { publicDebt / max(1, gdp) }

    public var businessCount: Int { aiBusinesses.count }

    public var totalLoanBalance: Double {
        loans.reduce(0) { $0 + $1.balance }
    }

    public var sustainability: Double {
        let clean = 1 - pollution
        return hhClamp(
            soilFertility * 0.3
                + biodiversity * 0.25
                + waterAvailability * 0.2
                + clean * 0.15
                + renewableShare * 0.1,
            0, 1
        )
    }

    public var nextTier: EconomyTier? { EconomyTier.next(after: tier) }

    public var nextTierLevel: Int? { nextTier?.unlockLevel }

    public var tierProgress: Double {
        guard let next = nextTier else { return 1 }
        let start = Double(tier.unlockLevel)
        let end = Double(next.unlockLevel)
        return hhClamp((Double(lastKnownLevel) - start) / max(1, end - start), 0, 1)
    }

    public var agentSummary: String {
        "\(aiBusinesses.count) firms · \(aiCitizens.filter(\.employed).count)/\(aiCitizens.count) residents employed"
    }

    public func isUnlocked(_ factor: EconomyFactor) -> Bool {
        factor.isUnlocked(level: lastKnownLevel)
    }

    public var unlockedFactorCount: Int {
        EconomyFactor.allCases.filter { isUnlocked($0) }.count
    }

    /// Updates the tier immediately, for level-up events that should not have to
    /// wait for the next in-game morning.
    @discardableResult
    public mutating func synchronize(level: Int) -> [EconomyFactor] {
        let oldLevel = lastKnownLevel
        lastKnownLevel = max(1, level)
        tier = EconomyTier.forLevel(lastKnownLevel)
        return EconomyFactor.allCases.filter {
            $0.minimumLevel > oldLevel && $0.minimumLevel <= lastKnownLevel
        }
    }

    public func snapshot() -> EconomySnapshot {
        EconomySnapshot(
            day: day,
            gdp: gdp,
            priceIndex: priceIndex,
            inflation: inflation,
            unemployment: unemployment,
            happiness: happiness,
            soil: soilFertility,
            pollution: pollution,
            population: population,
            productivity: productivity,
            tradeBalance: tradeBalance,
            debt: publicDebt,
            approval: politicalStability,
            education: education,
            crime: crime,
            biodiversity: biodiversity,
            farmYield: farmYield,
            irrigation: irrigation,
            livestockHealth: livestockHealth,
            renewable: renewableShare,
            infrastructure: infrastructure,
            inequality: inequality,
            wages: averageWage,
            tierRaw: tier.rawValue
        )
    }

    // MARK: - Factor ledger

    public var factorReadings: [EconomyFactorReading] {
        EconomyFactor.allCases.map { reading(for: $0) }
    }

    public func readings(in category: EconomyFactorCategory) -> [EconomyFactorReading] {
        factorReadings.filter { $0.category == category }
    }

    public func reading(for factor: EconomyFactor) -> EconomyFactorReading {
        let unlocked = factor.isUnlocked(level: lastKnownLevel)
        let pair = valueText(for: factor)
        return EconomyFactorReading(
            factor: factor,
            valueText: unlocked ? pair.value : factor.unlockHint,
            score: unlocked ? pair.score : 0,
            trend: unlocked ? trend(for: factor) : 0,
            isUnlocked: unlocked,
            status: unlocked ? status(for: factor, score: pair.score) : "Locked"
        )
    }

    private func valueText(for factor: EconomyFactor) -> (value: String, score: Double) {
        switch factor {
        case .landSoil:
            return ("\(pct(soilFertility)) fertile · \(pct(soilDegradation)) worn", soilFertility * 100)
        case .cropTypesYields:
            return ("\(pct(farmYield)) yield potential", hhClamp(farmYield / 1.4, 0, 1) * 100)
        case .seedsIrrigation:
            return ("\(pct(irrigation)) irrigated", irrigation * 100)
        case .livestockHealth:
            return ("\(pct(livestockHealth)) health · \(pct(livestockBreeding)) breeding", livestockHealth * 100)
        case .weatherClimate:
            return ("\(lastWeather.title) · climate stress \(pct(pollution))", (1 - pollution * 0.7) * 100)
        case .waterEnergy:
            return ("Water \(pct(waterAvailability)) · \(pct(renewableShare)) renewable", waterAvailability * 100)
        case .labourWages:
            return ("\(pct(unemployment)) idle · wage \(coin(averageWage))", (1 - unemployment) * 100)
        case .populationDemographics:
            return ("\(population) residents · \(workforce) workers", hhClamp(Double(population) / 160, 0, 1) * 100)
        case .consumerDemand:
            return ("Demand \(Int(demand)) · confidence \(pct(consumerConfidence))", consumerConfidence * 100)
        case .supplyDemandPrices:
            return ("Supply \(Int(supply)) · index \(String(format: "%.2f", priceIndex))", hhClamp(supply / max(1, demand), 0, 1.3) / 1.3 * 100)
        case .inflationDeflation:
            return ("\(pct(inflation)) inflation", (1 - min(1, abs(inflation - 0.02) * 5)) * 100)
        case .currencyInterest:
            return ("Rate \(pct(interestRate)) · strength \(pct(currencyStrength))", currencyStrength * 100)
        case .farmingBusinesses:
            return ("\(businessCount) active firms", hhClamp(Double(businessCount) / 10, 0, 1) * 100)
        case .productionLogistics:
            return ("\(pct(manufacturing)) output · \(pct(logistics)) logistics", (manufacturing * 0.6 + logistics * 0.4) * 100)
        case .importsExports:
            return ("Exports \(Int(exports)) · imports \(Int(imports))", hhClamp(0.5 + tradeBalance / 40, 0, 1) * 100)
        case .governmentElections:
            return ("\(rulingParty.shortTitle) · \(electionInDays)d to vote", politicalStability * 100)
        case .taxationSubsidies:
            return ("Tax \(pct(taxRate)) · subsidy \(pct(subsidyRate))", (1 - min(1, debtToGDP)) * 100)
        case .infrastructureServices:
            return ("Roads \(pct(infrastructure)) · services \(pct(publicServices))", (infrastructure * 0.5 + publicServices * 0.5) * 100)
        case .happinessHealthEducation:
            return ("Happy \(pct(happiness)) · health \(pct(health))", (happiness * 0.4 + health * 0.35 + education * 0.25) * 100)
        case .productivityGrowth:
            return ("Productivity \(pct(productivity / 1.5))", hhClamp(productivity / 1.5, 0, 1) * 100)
        case .loansCreditDebt:
            return ("Credit \(creditScore) · debt \(coin(totalLoanBalance))", hhClamp(Double(creditScore) / 850, 0, 1) * 100)
        case .bankruptcyCompetition:
            return ("Risk \(pct(bankruptcyRisk)) · competition \(pct(competition))", (1 - bankruptcyRisk) * 100)
        case .wealthInequalityPoverty:
            return ("Gini \(pct(inequality)) · poverty \(pct(poverty))", (1 - poverty) * 100)
        case .crimeCorruptionJustice:
            return ("Crime \(pct(crime)) · corruption \(pct(corruption))", (1 - crime * 0.7 - corruption * 0.3) * 100)
        case .pollutionSustainability:
            return ("Pollution \(pct(pollution)) · sustain \(pct(sustainability))", sustainability * 100)
        case .technologyResearch:
            return ("Tech \(pct(technology)) · research Lv \(researchLevel)", technology * 100)
        case .aiCitizensBusinesses:
            return (agentSummary, hhClamp(Double(aiBusinesses.count) / 12, 0, 1) * 100)
        case .disastersRecessions:
            return (activeEvent?.title ?? "No active shock", activeEvent == nil ? 80 : 35)
        case .randomEventsConsequences:
            let last = eventHistory.first?.kind.title ?? "No shocks yet"
            return ("\(eventHistory.count) remembered · \(last)", activeEvent == nil ? 82 : 42)
        case .playerProgression:
            return ("Level \(lastKnownLevel) · \(tier.shortTitle)", hhClamp(Double(lastKnownLevel) / 25, 0, 1) * 100)
        }
    }

    private func trend(for factor: EconomyFactor) -> Double {
        guard history.count >= 2 else { return 0 }
        let latest = history[history.count - 1]
        let prior = history[history.count - 2]
        func delta(_ new: Double, _ old: Double, scale: Double = 1) -> Double {
            (new - old) * scale
        }
        switch factor {
        case .landSoil: return delta(latest.soil, prior.soil)
        case .cropTypesYields: return delta(latest.farmYield, prior.farmYield)
        case .seedsIrrigation: return delta(latest.irrigation, prior.irrigation)
        case .livestockHealth: return delta(latest.livestockHealth, prior.livestockHealth)
        case .weatherClimate: return delta(latest.farmYield, prior.farmYield)
        case .waterEnergy: return delta(latest.renewable, prior.renewable)
        case .labourWages: return delta(prior.unemployment, latest.unemployment)
        case .populationDemographics: return Double(latest.population - prior.population) / 10
        case .consumerDemand: return delta(latest.gdp, prior.gdp, scale: 0.001)
        case .supplyDemandPrices: return delta(latest.priceIndex, prior.priceIndex, scale: -1)
        case .inflationDeflation: return delta(prior.inflation, latest.inflation, scale: 2)
        case .currencyInterest: return delta(latest.tradeBalance, prior.tradeBalance, scale: 0.01)
        case .farmingBusinesses: return delta(latest.gdp, prior.gdp, scale: 0.001)
        case .productionLogistics: return delta(latest.productivity, prior.productivity)
        case .importsExports: return delta(latest.tradeBalance, prior.tradeBalance, scale: 0.01)
        case .governmentElections: return delta(latest.approval, prior.approval)
        case .taxationSubsidies: return delta(prior.debt, latest.debt, scale: -0.001)
        case .infrastructureServices: return delta(latest.infrastructure, prior.infrastructure)
        case .happinessHealthEducation: return delta(latest.happiness, prior.happiness) + delta(latest.education, prior.education)
        case .productivityGrowth: return delta(latest.productivity, prior.productivity)
        case .loansCreditDebt: return delta(prior.debt, latest.debt, scale: -0.001)
        case .bankruptcyCompetition: return delta(prior.debt, latest.debt, scale: -0.001)
        case .wealthInequalityPoverty: return delta(prior.inequality, latest.inequality)
        case .crimeCorruptionJustice: return delta(prior.crime, latest.crime, scale: -1)
        case .pollutionSustainability: return delta(prior.pollution, latest.pollution, scale: 0.5)
        case .technologyResearch: return delta(latest.productivity, prior.productivity)
        case .aiCitizensBusinesses: return delta(latest.gdp, prior.gdp, scale: 0.001)
        case .disastersRecessions: return delta(latest.gdp, prior.gdp, scale: 0.001)
        case .randomEventsConsequences: return delta(latest.gdp, prior.gdp, scale: 0.001)
        case .playerProgression: return delta(latest.gdp, prior.gdp, scale: 0.001)
        }
    }

    private func status(for factor: EconomyFactor, score: Double) -> String {
        if !factor.isHigherBetter {
            return score >= 60 ? "Stable" : "Watch"
        }
        switch score {
        case 72...: return "Strong"
        case 45..<72: return "Steady"
        case 25..<45: return "Strained"
        default: return "Critical"
        }
    }
}

// MARK: - Small formatting helpers

public func hhClamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
    min(high, max(low, value))
}

private func pct(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
}

private func coin(_ value: Double) -> String {
    "\(Int(value.rounded()))c"
}
