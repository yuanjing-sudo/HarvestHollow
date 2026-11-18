import Foundation

// MARK: - Tiers

/// The valley economy grows in tiers. A new farm begins with a handful of
/// subsistence-level signals; each tier layers on more markets, institutions,
/// and feedback loops.
public enum EconomyTier: Int, Codable, CaseIterable, Identifiable, Sendable {
    case subsistence = 0
    case village = 1
    case marketTown = 2
    case district = 3
    case regional = 4
    case global = 5

    public var id: Int { rawValue }

    public var unlockLevel: Int {
        switch self {
        case .subsistence: return 1
        case .village: return 4
        case .marketTown: return 8
        case .district: return 12
        case .regional: return 16
        case .global: return 20
        }
    }

    public var title: String {
        switch self {
        case .subsistence: return "Subsistence"
        case .village: return "Village"
        case .marketTown: return "Market Town"
        case .district: return "District"
        case .regional: return "Regional"
        case .global: return "Global"
        }
    }

    public var shortTitle: String {
        switch self {
        case .subsistence: return "Homestead"
        case .village: return "Village"
        case .marketTown: return "Market"
        case .district: return "District"
        case .regional: return "Region"
        case .global: return "Global"
        }
    }

    public var blurb: String {
        switch self {
        case .subsistence:
            return "Soil, weather, a few crops, and the first neighbours."
        case .village:
            return "Livestock, hired hands, households, and a weekly market."
        case .marketTown:
            return "Firms, credit, infrastructure, and public policy appear."
        case .district:
            return "Trade, elections, research, and environmental pressure."
        case .regional:
            return "Competition, inequality, AI firms, and systemic risk."
        case .global:
            return "Disasters, global shocks, and long-run consequences."
        }
    }

    public var icon: String {
        switch self {
        case .subsistence: return "house.fill"
        case .village: return "building.2.fill"
        case .marketTown: return "cart.fill"
        case .district: return "building.columns.fill"
        case .regional: return "map.fill"
        case .global: return "globe.americas.fill"
        }
    }

    public var maxFirms: Int {
        switch self {
        case .subsistence: return 2
        case .village: return 4
        case .marketTown: return 6
        case .district: return 9
        case .regional: return 12
        case .global: return 16
        }
    }

    public static func forLevel(_ level: Int) -> EconomyTier {
        allCases.reversed().first { level >= $0.unlockLevel } ?? .subsistence
    }

    public static func next(after tier: EconomyTier) -> EconomyTier? {
        allCases.first { $0.rawValue == tier.rawValue + 1 }
    }
}

// MARK: - Factor catalogue

public enum EconomyFactorCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case land
    case people
    case markets
    case finance
    case government
    case world
    case resilience

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .land: return "Land & Production"
        case .people: return "People & Work"
        case .markets: return "Markets & Money"
        case .finance: return "Credit & Business"
        case .government: return "Government & Services"
        case .world: return "Trade & the World"
        case .resilience: return "Resilience & Consequences"
        }
    }

    public var icon: String {
        switch self {
        case .land: return "leaf.fill"
        case .people: return "person.3.fill"
        case .markets: return "chart.line.uptrend.xyaxis"
        case .finance: return "banknote.fill"
        case .government: return "building.columns.fill"
        case .world: return "globe.americas.fill"
        case .resilience: return "shield.lefthalf.filled"
        }
    }

    public var blurb: String {
        switch self {
        case .land: return "Soil, water, crops, animals, weather, and energy."
        case .people: return "Labour, wages, population, health, and education."
        case .markets: return "Demand, supply, prices, inflation, and currency."
        case .finance: return "Firms, logistics, credit, debt, and competition."
        case .government: return "Elections, taxes, subsidies, and public goods."
        case .world: return "Exports, imports, tariffs, and global conditions."
        case .resilience: return "Pollution, crime, disasters, and inequality."
        }
    }
}

/// Every factor listed in the valley ledger. The minimum level is deliberately
/// low for the subsistence loop and rises as the simulation becomes complex.
public enum EconomyFactor: String, Codable, CaseIterable, Identifiable, Sendable {
    case landSoil
    case cropTypesYields
    case seedsIrrigation
    case livestockHealth
    case weatherClimate
    case waterEnergy
    case labourWages
    case populationDemographics
    case consumerDemand
    case supplyDemandPrices
    case inflationDeflation
    case currencyInterest
    case farmingBusinesses
    case productionLogistics
    case importsExports
    case governmentElections
    case taxationSubsidies
    case infrastructureServices
    case happinessHealthEducation
    case productivityGrowth
    case loansCreditDebt
    case bankruptcyCompetition
    case wealthInequalityPoverty
    case crimeCorruptionJustice
    case pollutionSustainability
    case technologyResearch
    case aiCitizensBusinesses
    case disastersRecessions
    case randomEventsConsequences
    case playerProgression

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .landSoil: return "Land, terrain & soil fertility"
        case .cropTypesYields: return "Crop types, growth & yields"
        case .seedsIrrigation: return "Seeds, fertiliser & irrigation"
        case .livestockHealth: return "Livestock, breeding & animal health"
        case .weatherClimate: return "Weather, seasons & climate change"
        case .waterEnergy: return "Water, energy & natural resources"
        case .labourWages: return "Labour, wages & employment"
        case .populationDemographics: return "Population & demographics"
        case .consumerDemand: return "Consumer demand & preferences"
        case .supplyDemandPrices: return "Supply, demand & market prices"
        case .inflationDeflation: return "Inflation, deflation & interest"
        case .currencyInterest: return "Currency & monetary policy"
        case .farmingBusinesses: return "Farming businesses & industries"
        case .productionLogistics: return "Production, logistics & manufacturing"
        case .importsExports: return "Imports, exports & trade"
        case .governmentElections: return "Government, elections & policy"
        case .taxationSubsidies: return "Taxation, subsidies & spending"
        case .infrastructureServices: return "Infrastructure & public services"
        case .happinessHealthEducation: return "Happiness, health & education"
        case .productivityGrowth: return "Productivity & economic growth"
        case .loansCreditDebt: return "Loans, credit & debt"
        case .bankruptcyCompetition: return "Bankruptcy & business competition"
        case .wealthInequalityPoverty: return "Wealth inequality & poverty"
        case .crimeCorruptionJustice: return "Crime, corruption & legal penalties"
        case .pollutionSustainability: return "Pollution & sustainability"
        case .technologyResearch: return "Technology, innovation & research"
        case .aiCitizensBusinesses: return "AI citizens & businesses"
        case .disastersRecessions: return "Disasters, recessions & global events"
        case .randomEventsConsequences: return "Random events & long-term consequences"
        case .playerProgression: return "Player progression & consequences"
        }
    }

    public var shortTitle: String {
        switch self {
        case .landSoil: return "Soil"
        case .cropTypesYields: return "Crop yields"
        case .seedsIrrigation: return "Irrigation"
        case .livestockHealth: return "Livestock"
        case .weatherClimate: return "Weather"
        case .waterEnergy: return "Water & energy"
        case .labourWages: return "Labour"
        case .populationDemographics: return "Population"
        case .consumerDemand: return "Demand"
        case .supplyDemandPrices: return "Market prices"
        case .inflationDeflation: return "Inflation"
        case .currencyInterest: return "Currency"
        case .farmingBusinesses: return "Firms"
        case .productionLogistics: return "Production"
        case .importsExports: return "Trade"
        case .governmentElections: return "Government"
        case .taxationSubsidies: return "Tax & subsidies"
        case .infrastructureServices: return "Infrastructure"
        case .happinessHealthEducation: return "Wellbeing"
        case .productivityGrowth: return "Productivity"
        case .loansCreditDebt: return "Credit"
        case .bankruptcyCompetition: return "Competition"
        case .wealthInequalityPoverty: return "Inequality"
        case .crimeCorruptionJustice: return "Crime"
        case .pollutionSustainability: return "Environment"
        case .technologyResearch: return "Research"
        case .aiCitizensBusinesses: return "AI agents"
        case .disastersRecessions: return "Shocks"
        case .randomEventsConsequences: return "Echoes"
        case .playerProgression: return "Progression"
        }
    }

    public var icon: String {
        switch self {
        case .landSoil: return "square.3.layers.3d"
        case .cropTypesYields: return "carrot.fill"
        case .seedsIrrigation: return "drop.fill"
        case .livestockHealth: return "pawprint.fill"
        case .weatherClimate: return "cloud.sun.fill"
        case .waterEnergy: return "bolt.fill"
        case .labourWages: return "person.2.fill"
        case .populationDemographics: return "person.3.sequence.fill"
        case .consumerDemand: return "basket.fill"
        case .supplyDemandPrices: return "tag.fill"
        case .inflationDeflation: return "arrow.up.arrow.down"
        case .currencyInterest: return "banknote.fill"
        case .farmingBusinesses: return "building.2.fill"
        case .productionLogistics: return "shippingbox.fill"
        case .importsExports: return "ferry.fill"
        case .governmentElections: return "building.columns.fill"
        case .taxationSubsidies: return "percent"
        case .infrastructureServices: return "road.lanes"
        case .happinessHealthEducation: return "heart.text.square.fill"
        case .productivityGrowth: return "chart.line.uptrend.xyaxis"
        case .loansCreditDebt: return "creditcard.fill"
        case .bankruptcyCompetition: return "exclamationmark.triangle.fill"
        case .wealthInequalityPoverty: return "person.crop.circle.badge.exclamationmark"
        case .crimeCorruptionJustice: return "figure.stand.line.dotted.figure.stand"
        case .pollutionSustainability: return "smoke.fill"
        case .technologyResearch: return "lightbulb.fill"
        case .aiCitizensBusinesses: return "cpu.fill"
        case .disastersRecessions: return "tornado"
        case .randomEventsConsequences: return "clock.arrow.circlepath"
        case .playerProgression: return "star.fill"
        }
    }

    public var minimumLevel: Int {
        switch self {
        case .landSoil,
             .cropTypesYields,
             .weatherClimate,
             .consumerDemand,
             .supplyDemandPrices,
             .playerProgression:
            return 1
        case .seedsIrrigation,
             .livestockHealth,
             .labourWages,
             .populationDemographics,
             .happinessHealthEducation:
            return 4
        case .waterEnergy,
             .farmingBusinesses,
             .productionLogistics,
             .taxationSubsidies,
             .infrastructureServices,
             .inflationDeflation,
             .loansCreditDebt:
            return 8
        case .currencyInterest,
             .importsExports,
             .governmentElections,
             .productivityGrowth,
             .pollutionSustainability,
             .technologyResearch:
            return 12
        case .bankruptcyCompetition,
             .wealthInequalityPoverty,
             .crimeCorruptionJustice,
             .aiCitizensBusinesses:
            return 16
        case .randomEventsConsequences:
            return 4
        case .disastersRecessions:
            return 20
        }
    }

    public var category: EconomyFactorCategory {
        switch self {
        case .landSoil, .cropTypesYields, .seedsIrrigation,
             .livestockHealth, .weatherClimate, .waterEnergy:
            return .land
        case .labourWages, .populationDemographics, .happinessHealthEducation:
            return .people
        case .consumerDemand, .supplyDemandPrices, .inflationDeflation,
             .currencyInterest:
            return .markets
        case .farmingBusinesses, .productionLogistics, .loansCreditDebt,
             .bankruptcyCompetition, .productivityGrowth:
            return .finance
        case .governmentElections, .taxationSubsidies, .infrastructureServices:
            return .government
        case .importsExports:
            return .world
        case .wealthInequalityPoverty, .crimeCorruptionJustice,
             .pollutionSustainability, .technologyResearch,
             .aiCitizensBusinesses, .disastersRecessions,
             .randomEventsConsequences, .playerProgression:
            return .resilience
        }
    }

    public var isHigherBetter: Bool {
        switch self {
        case .inflationDeflation, .loansCreditDebt, .bankruptcyCompetition,
             .wealthInequalityPoverty, .crimeCorruptionJustice,
             .pollutionSustainability, .disastersRecessions,
             .landSoil, .cropTypesYields, .seedsIrrigation,
             .livestockHealth, .waterEnergy, .labourWages,
             .populationDemographics, .consumerDemand,
             .supplyDemandPrices, .currencyInterest, .farmingBusinesses,
             .productionLogistics, .importsExports, .governmentElections,
             .taxationSubsidies, .infrastructureServices,
             .happinessHealthEducation, .productivityGrowth,
             .technologyResearch, .aiCitizensBusinesses,
             .randomEventsConsequences, .playerProgression:
            return true
        case .weatherClimate:
            return true
        }
    }

    public var explanation: String {
        switch self {
        case .landSoil:
            return "Fertility feeds yields. Cropping, pollution, and storms wear it down; fallow fields, crop rotation, and subsidies rebuild it."
        case .cropTypesYields:
            return "Each crop has different value, growth speed, and resilience. Yields respond to soil, water, weather, technology, and animal manure."
        case .seedsIrrigation:
            return "Seed quality, fertiliser, and irrigation lift yields but cost coins and energy. Over-irrigation can salinise or deplete water."
        case .livestockHealth:
            return "Animal health and breeding set milk, eggs, and wool output. Feed, affection, pollution, and veterinary services all matter."
        case .weatherClimate:
            return "Weather swings each day. Long-run pollution changes the odds of heatwaves, storms, and droughts."
        case .waterEnergy:
            return "Water and energy are shared between households, farms, and firms. Shortages raise costs and slow production."
        case .labourWages:
            return "Firms and public services hire from the workforce. Wages respond to prices, productivity, and unemployment."
        case .populationDemographics:
            return "Residents move toward opportunity, health, and happiness. Population sets the labour force, demand, and tax base."
        case .consumerDemand:
            return "Households buy more when confident, employed, and healthy. Preferences shift toward fresh, local, and sustainable goods."
        case .supplyDemandPrices:
            return "Local harvests, imports, and firm output meet household and export demand. Scarcity raises prices; surplus lowers them."
        case .inflationDeflation:
            return "Prices feed wage demands and interest rates. Deflation can stall investment just as surely as high inflation erodes savings."
        case .currencyInterest:
            return "The valley's currency strengthens with trade and high rates. A strong currency makes imports cheaper and exports harder."
        case .farmingBusinesses:
            return "Farms, bakeries, mills, and workshops hire, invest, and compete. Their profits fund the next round of productivity."
        case .productionLogistics:
            return "Manufacturing and transport turn raw goods into higher-value products. Roads and ports reduce waste and delivery costs."
        case .importsExports:
            return "Exports earn foreign coin; imports fill gaps. Tariffs protect local firms but raise consumer prices and invite retaliation."
        case .governmentElections:
            return "Approval depends on jobs, prices, services, and corruption. Elections can change the ruling party and its policy biases."
        case .taxationSubsidies:
            return "Taxes fund services and reduce inequality. Subsidies support farms and clean energy but strain the budget."
        case .infrastructureServices:
            return "Roads, schools, clinics, and utilities raise productivity and wellbeing. Neglect shows up in decay and inequality."
        case .happinessHealthEducation:
            return "Health and education raise productivity; happiness supports consumption and population growth. Pollution and poverty pull them down."
        case .productivityGrowth:
            return "Output per worker compounds through education, technology, infrastructure, and competition. It is the main long-run growth engine."
        case .loansCreditDebt:
            return "Loans let the farm invest ahead of cash flow. Debt service competes with daily spending, and missed payments damage credit."
        case .bankruptcyCompetition:
            return "Weak firms fail; strong firms expand. Competition limits prices and monopoly profits but can also destroy fragile local capacity."
        case .wealthInequalityPoverty:
            return "Wage gaps, ownership, and inflation shape inequality. Poverty drags health, education, crime, and demand."
        case .crimeCorruptionJustice:
            return "Crime rises with poverty and inequality. Corruption wastes public money. Courts and services restore trust, at a cost."
        case .pollutionSustainability:
            return "Production creates pollution unless energy is clean and rules are enforced. Pollution damages soil, water, health, and biodiversity."
        case .technologyResearch:
            return "Research points accumulate from education and spending. Breakthroughs raise productivity, clean energy, and disaster resilience."
        case .aiCitizensBusinesses:
            return "Every resident and firm reacts to prices, jobs, taxes, and confidence. Their choices feed back into the whole system."
        case .disastersRecessions:
            return "Droughts, floods, epidemics, and global slowdowns hit different tiers. Reserves, infrastructure, and trust soften the blow."
        case .randomEventsConsequences:
            return "Every random shock is written into the ledger: lost soil, new debt, damaged trust, or a breakthrough that compounds for weeks."
        case .playerProgression:
            return "Your level unlocks new economic layers and grants influence over policy, credit, and investment. Every choice echoes through the ledger."
        }
    }

    public var dependencies: [EconomyFactor] {
        switch self {
        case .landSoil: return []
        case .cropTypesYields: return [.landSoil, .weatherClimate]
        case .seedsIrrigation: return [.landSoil, .waterEnergy, .technologyResearch]
        case .livestockHealth: return [.cropTypesYields, .waterEnergy, .happinessHealthEducation]
        case .weatherClimate: return [.pollutionSustainability]
        case .waterEnergy: return [.weatherClimate, .infrastructureServices, .pollutionSustainability]
        case .labourWages: return [.populationDemographics, .happinessHealthEducation, .farmingBusinesses]
        case .populationDemographics: return [.happinessHealthEducation, .infrastructureServices]
        case .consumerDemand: return [.populationDemographics, .labourWages, .supplyDemandPrices]
        case .supplyDemandPrices: return [.cropTypesYields, .livestockHealth, .importsExports, .consumerDemand]
        case .inflationDeflation: return [.supplyDemandPrices, .labourWages, .waterEnergy, .currencyInterest]
        case .currencyInterest: return [.inflationDeflation, .importsExports, .governmentElections]
        case .farmingBusinesses: return [.supplyDemandPrices, .labourWages, .loansCreditDebt, .technologyResearch]
        case .productionLogistics: return [.farmingBusinesses, .waterEnergy, .infrastructureServices]
        case .importsExports: return [.productionLogistics, .currencyInterest, .taxationSubsidies]
        case .governmentElections: return [.happinessHealthEducation, .taxationSubsidies, .crimeCorruptionJustice]
        case .taxationSubsidies: return [.farmingBusinesses, .labourWages, .governmentElections]
        case .infrastructureServices: return [.taxationSubsidies, .loansCreditDebt, .productivityGrowth]
        case .happinessHealthEducation: return [.pollutionSustainability, .wealthInequalityPoverty, .infrastructureServices]
        case .productivityGrowth: return [.happinessHealthEducation, .technologyResearch, .infrastructureServices, .bankruptcyCompetition]
        case .loansCreditDebt: return [.currencyInterest, .farmingBusinesses, .bankruptcyCompetition]
        case .bankruptcyCompetition: return [.loansCreditDebt, .consumerDemand, .wealthInequalityPoverty]
        case .wealthInequalityPoverty: return [.labourWages, .taxationSubsidies, .supplyDemandPrices, .happinessHealthEducation]
        case .crimeCorruptionJustice: return [.wealthInequalityPoverty, .labourWages, .governmentElections]
        case .pollutionSustainability: return [.productionLogistics, .waterEnergy, .taxationSubsidies]
        case .technologyResearch: return [.happinessHealthEducation, .farmingBusinesses, .infrastructureServices]
        case .aiCitizensBusinesses: return [.populationDemographics, .farmingBusinesses, .consumerDemand, .technologyResearch]
        case .disastersRecessions: return [.weatherClimate, .pollutionSustainability, .importsExports, .loansCreditDebt, .governmentElections]
        case .randomEventsConsequences: return [.weatherClimate, .pollutionSustainability, .supplyDemandPrices, .loansCreditDebt, .governmentElections]
        case .playerProgression: return EconomyFactor.allCases.filter { $0 != .playerProgression }
        }
    }

    public func isUnlocked(level: Int) -> Bool { level >= minimumLevel }

    public var unlockHint: String {
        minimumLevel <= 1 ? "Available from the first day" : "Unlocks at level \(minimumLevel)"
    }
}

// MARK: - Parties and events

public enum PoliticalParty: String, Codable, CaseIterable, Identifiable, Sendable {
    case green
    case merchants
    case workers
    case stewards

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .green: return "Green Alliance"
        case .merchants: return "Merchant League"
        case .workers: return "Workers' Union"
        case .stewards: return "Stewards of the Hollow"
        }
    }

    public var shortTitle: String {
        switch self {
        case .green: return "Green"
        case .merchants: return "Merchants"
        case .workers: return "Workers"
        case .stewards: return "Stewards"
        }
    }

    public var icon: String {
        switch self {
        case .green: return "leaf.circle.fill"
        case .merchants: return "scalemass.fill"
        case .workers: return "hammer.fill"
        case .stewards: return "shield.checkered"
        }
    }

    public var blurb: String {
        switch self {
        case .green:
            return "Prefers clean energy, conservation, and steady subsidies."
        case .merchants:
            return "Prefers low taxes, open trade, and firm-friendly credit."
        case .workers:
            return "Prefers public services, wage support, and fair taxation."
        case .stewards:
            return "Prefers balanced books, infrastructure, and stability."
        }
    }

    public var taxBias: Double {
        switch self {
        case .green: return 0.19
        case .merchants: return 0.13
        case .workers: return 0.22
        case .stewards: return 0.17
        }
    }

    public var subsidyBias: Double {
        switch self {
        case .green: return 0.07
        case .merchants: return 0.03
        case .workers: return 0.055
        case .stewards: return 0.04
        }
    }

    public var tariffBias: Double {
        switch self {
        case .green: return 0.06
        case .merchants: return 0.02
        case .workers: return 0.09
        case .stewards: return 0.05
        }
    }

    public var spendingBias: Double {
        switch self {
        case .green: return 0.17
        case .merchants: return 0.13
        case .workers: return 0.21
        case .stewards: return 0.16
        }
    }
}

public enum EconomyEventKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case drought
    case flood
    case storm
    case recession
    case boom
    case epidemic
    case election
    case strike
    case exportBan
    case techBreakthrough
    case bankruptcyScare
    case crimeWave
    case heatwave
    case globalSlowdown
    case subsidyProgram
    case harvestFestival

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .drought: return "Drought"
        case .flood: return "Flood"
        case .storm: return "Storm Damage"
        case .recession: return "Recession"
        case .boom: return "Trade Boom"
        case .epidemic: return "Epidemic"
        case .election: return "Election"
        case .strike: return "Labour Strike"
        case .exportBan: return "Export Ban"
        case .techBreakthrough: return "Tech Breakthrough"
        case .bankruptcyScare: return "Credit Crunch"
        case .crimeWave: return "Crime Wave"
        case .heatwave: return "Heatwave"
        case .globalSlowdown: return "Global Slowdown"
        case .subsidyProgram: return "Subsidy Programme"
        case .harvestFestival: return "Harvest Festival"
        }
    }

    public var icon: String {
        switch self {
        case .drought: return "sun.max.fill"
        case .flood: return "cloud.heavyrain.fill"
        case .storm: return "tornado"
        case .recession: return "arrow.down.right.circle.fill"
        case .boom: return "arrow.up.right.circle.fill"
        case .epidemic: return "cross.case.fill"
        case .election: return "checkmark.seal.fill"
        case .strike: return "hand.raised.fill"
        case .exportBan: return "xmark.octagon.fill"
        case .techBreakthrough: return "lightbulb.fill"
        case .bankruptcyScare: return "exclamationmark.triangle.fill"
        case .crimeWave: return "lock.shield.fill"
        case .heatwave: return "thermometer.sun.fill"
        case .globalSlowdown: return "globe.americas.fill"
        case .subsidyProgram: return "gift.fill"
        case .harvestFestival: return "party.popper.fill"
        }
    }

    public var isPositive: Bool {
        switch self {
        case .boom, .techBreakthrough, .subsidyProgram, .harvestFestival,
             .election:
            return true
        default:
            return false
        }
    }
}

public struct EconomyEventRecord: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var day: Int
    public var kind: EconomyEventKind
    public var title: String
    public var detail: String
    public var impact: Double

    public init(
        id: UUID = UUID(),
        day: Int,
        kind: EconomyEventKind,
        title: String? = nil,
        detail: String,
        impact: Double
    ) {
        self.id = id
        self.day = day
        self.kind = kind
        self.title = title ?? kind.title
        self.detail = detail
        self.impact = impact
    }
}

// MARK: - Loans, firms, citizens

public struct EconomyLoan: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var principal: Double
    public var balance: Double
    public var annualRate: Double
    public var purpose: String
    public var takenDay: Int

    public init(
        id: UUID = UUID(),
        principal: Double,
        balance: Double,
        annualRate: Double,
        purpose: String,
        takenDay: Int
    ) {
        self.id = id
        self.principal = principal
        self.balance = balance
        self.annualRate = annualRate
        self.purpose = purpose
        self.takenDay = takenDay
    }

    public var dailyInterest: Double { balance * annualRate / 365 }
}

public enum AIBusinessKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case bakery
    case mill
    case dairy
    case workshop
    case marketStall
    case transport
    case techStudio
    case bank

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .bakery: return "Bakery"
        case .mill: return "Mill"
        case .dairy: return "Dairy"
        case .workshop: return "Workshop"
        case .marketStall: return "Market Stall"
        case .transport: return "Transport"
        case .techStudio: return "Tech Studio"
        case .bank: return "Savings Bank"
        }
    }

    public var icon: String {
        switch self {
        case .bakery: return "birthday.cake.fill"
        case .mill: return "wind"
        case .dairy: return "drop.triangle.fill"
        case .workshop: return "hammer.fill"
        case .marketStall: return "basket.fill"
        case .transport: return "truck.box.fill"
        case .techStudio: return "cpu.fill"
        case .bank: return "building.columns.fill"
        }
    }

    public var minimumTier: EconomyTier {
        switch self {
        case .bakery, .mill, .marketStall: return .subsistence
        case .dairy, .workshop: return .village
        case .transport, .bank: return .marketTown
        case .techStudio: return .district
        }
    }
}

public struct AIBusiness: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: AIBusinessKind
    public var employees: Int
    public var capital: Double
    public var productivity: Double
    public var technology: Double
    public var price: Double
    public var mood: Double
    public var pollution: Double
    public var foundedDay: Int
    public var isPlayerOwned: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        kind: AIBusinessKind,
        employees: Int,
        capital: Double,
        productivity: Double,
        technology: Double,
        price: Double = 1,
        mood: Double = 0.55,
        pollution: Double = 0.04,
        foundedDay: Int,
        isPlayerOwned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.employees = employees
        self.capital = capital
        self.productivity = productivity
        self.technology = technology
        self.price = price
        self.mood = mood
        self.pollution = pollution
        self.foundedDay = foundedDay
        self.isPlayerOwned = isPlayerOwned
    }

    public var output: Double {
        capital * productivity * (0.65 + technology * 0.5) * price
    }

    public var payroll: Double {
        Double(employees) * 22
    }
}

public struct AICitizen: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var age: Int
    public var job: String
    public var income: Double
    public var savings: Double
    public var happiness: Double
    public var health: Double
    public var education: Double
    public var employed: Bool
    public var consumption: Double

    public init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        job: String,
        income: Double,
        savings: Double,
        happiness: Double,
        health: Double,
        education: Double,
        employed: Bool,
        consumption: Double
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.job = job
        self.income = income
        self.savings = savings
        self.happiness = happiness
        self.health = health
        self.education = education
        self.employed = employed
        self.consumption = consumption
    }
}

// MARK: - Snapshots and report

public struct EconomySnapshot: Codable, Equatable, Sendable {
    public var day: Int
    public var gdp: Double
    public var priceIndex: Double
    public var inflation: Double
    public var unemployment: Double
    public var happiness: Double
    public var soil: Double
    public var pollution: Double
    public var population: Int
    public var productivity: Double
    public var tradeBalance: Double
    public var debt: Double
    public var approval: Double
    public var education: Double
    public var crime: Double
    public var biodiversity: Double
    public var farmYield: Double
    public var irrigation: Double
    public var livestockHealth: Double
    public var renewable: Double
    public var infrastructure: Double
    public var inequality: Double
    public var wages: Double
    public var tierRaw: Int

    public var tier: EconomyTier { EconomyTier(rawValue: tierRaw) ?? .subsistence }
}

public struct EconomyReport: Codable, Equatable, Sendable {
    public var day: Int
    public var tier: EconomyTier
    public var previousTier: EconomyTier
    public var headline: String
    public var summary: String
    public var warnings: [String]
    public var unlockedFactors: [EconomyFactor]
    public var event: EconomyEventRecord?
    public var gdp: Double
    public var demand: Double
    public var supply: Double
    public var priceIndex: Double
    public var governmentBalance: Double
    public var marketNotice: String? = nil
    public var crimeIncident: CrimeIncident? = nil

    public var tierChanged: Bool { previousTier != tier }
}

public struct EconomyFactorReading: Identifiable, Sendable {
    public var factor: EconomyFactor
    public var valueText: String
    public var score: Double
    public var trend: Double
    public var isUnlocked: Bool
    public var status: String

    public var id: String { factor.rawValue }
    public var title: String { factor.title }
    public var shortTitle: String { factor.shortTitle }
    public var icon: String { factor.icon }
    public var category: EconomyFactorCategory { factor.category }
    public var explanation: String { factor.explanation }
    public var dependencies: [EconomyFactor] { factor.dependencies }
    public var isHigherBetter: Bool { factor.isHigherBetter }
    public var minimumLevel: Int { factor.minimumLevel }
}

// MARK: - Inputs

public struct EconomyInputs: Sendable {
    public var day: Int
    public var level: Int
    public var weather: Weather
    public var season: FarmSeason
    public var coins: Int
    public var cropCount: Int
    public var readyCrops: Int
    public var wateredCrops: Int
    public var animalCount: Int
    public var animalHappiness: Double
    public var animalAffection: Double
    public var storedGoods: Int
    public var inventoryValue: Int

    public init(
        day: Int,
        level: Int,
        weather: Weather,
        season: FarmSeason,
        coins: Int,
        cropCount: Int,
        readyCrops: Int,
        wateredCrops: Int,
        animalCount: Int,
        animalHappiness: Double,
        animalAffection: Double,
        storedGoods: Int,
        inventoryValue: Int
    ) {
        self.day = day
        self.level = level
        self.weather = weather
        self.season = season
        self.coins = coins
        self.cropCount = cropCount
        self.readyCrops = readyCrops
        self.wateredCrops = wateredCrops
        self.animalCount = animalCount
        self.animalHappiness = animalHappiness
        self.animalAffection = animalAffection
        self.storedGoods = storedGoods
        self.inventoryValue = inventoryValue
    }

    public init(state: GameState) {
        let crops = state.plots.compactMap(\.crop)
        let animals = state.pens.compactMap(\.animal)
        let animalHappiness = animals.isEmpty
            ? 0.55
            : animals.map { $0.happiness / 100 }.reduce(0, +) / Double(animals.count)
        let animalAffection = animals.isEmpty
            ? 0.2
            : min(1, animals.map(\.affection).reduce(0, +) / Double(animals.count) / 600)
        self.init(
            day: state.day,
            level: state.level,
            weather: state.weather,
            season: state.season,
            coins: state.coins,
            cropCount: crops.count,
            readyCrops: crops.filter(\.isReady).count,
            wateredCrops: crops.filter(\.watered).count,
            animalCount: animals.count,
            animalHappiness: animalHappiness,
            animalAffection: animalAffection,
            storedGoods: animals.map(\.stored).reduce(0, +),
            inventoryValue: state.inventory.values.reduce(0, +)
        )
    }
}

// MARK: - Investments

public enum EconomyInvestment: String, Codable, CaseIterable, Identifiable, Sendable {
    case irrigation
    case renewableEnergy
    case roads
    case school
    case clinic
    case research
    case cleanup
    case digitalNetwork

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .irrigation: return "Irrigation Works"
        case .renewableEnergy: return "Renewable Energy"
        case .roads: return "Road & Bridge Fund"
        case .school: return "Village School"
        case .clinic: return "Health Clinic"
        case .research: return "Research Grant"
        case .cleanup: return "River Cleanup"
        case .digitalNetwork: return "Digital Network"
        }
    }

    public var icon: String {
        switch self {
        case .irrigation: return "drop.fill"
        case .renewableEnergy: return "bolt.fill"
        case .roads: return "road.lanes"
        case .school: return "graduationcap.fill"
        case .clinic: return "cross.case.fill"
        case .research: return "lightbulb.fill"
        case .cleanup: return "leaf.fill"
        case .digitalNetwork: return "antenna.radiowaves.left.and.right"
        }
    }

    public var blurb: String {
        switch self {
        case .irrigation: return "+ irrigation, + water security, + yields"
        case .renewableEnergy: return "+ clean energy, − pollution, + energy"
        case .roads: return "+ infrastructure, + logistics, + trade"
        case .school: return "+ education, + productivity, + innovation"
        case .clinic: return "+ health, + happiness, + population"
        case .research: return "+ research points, + technology"
        case .cleanup: return "− pollution, + biodiversity, + health"
        case .digitalNetwork: return "+ productivity, + services, + firm tech"
        }
    }

    public var cost: Int {
        switch self {
        case .irrigation: return 140
        case .renewableEnergy: return 260
        case .roads: return 220
        case .school: return 200
        case .clinic: return 200
        case .research: return 160
        case .cleanup: return 150
        case .digitalNetwork: return 300
        }
    }

    public var minimumLevel: Int {
        switch self {
        case .irrigation, .cleanup: return 4
        case .renewableEnergy, .roads, .school, .clinic, .research: return 8
        case .digitalNetwork: return 12
        }
    }
}
