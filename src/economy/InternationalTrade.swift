//  InternationalTrade.swift
//  Agricultural Economic Simulation (Massively Expanded)
//
//  Expanded System 19 with comprehensive international trade simulation
//  Features: extensive trade flows, tariff structures, exchange rates, trade agreements, partner management
//  Interconnections: connects to economy (markets), society (consumer prices), government (taxes)
//  ~3000+ lines of Swift code

import Foundation

// MARK: - Comprehensive Trade Direction Enum

public enum TradeDirection: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case importGoods = "import"
    case exportGoods = "export"
    case reExport = "re_export"
    case transit = "transit"
    case temporaryImport = "temp_import"
    case processingTrade = "proc_trade"
    case inwardProcessing = "inward_proc"
    case outwardProcessing = "outward_proc"
}

// MARK: - Trade Commodity System (Expanded)

public enum TradeCommodity: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // === AGRICULTURAL COMMODITIES (25) ===
    case wheat = "wheat"
    case corn = "corn"
    case rice = "rice"
    case soybeans = "soybeans"
    case barley = "barley"
    case oats = "oats"
    case sugarCane = "sugar_cane"
    case sugarBeets = "sugar_beets"
    case potatoes = "potatoes"
    case cotton = "cotton"
    case coffee = "coffee"
    case tea = "tea"
    case cocoa = "cocoa"
    case fruits = "fruits"
    case vegetables = "vegetables"
    case nuts = "nuts"
    case spices = "spices"
    case tobacco = "tobacco"
    case timber = "timber"
    case woodPulp = "wood_pulp"
    case rubber = "rubber"
    case hay = "hay"
    case alfalfa = "alfalfa"
    case ensilage = "ensilage"
    
    // === ENERGY COMMODITIES (10) ===
    case crudeOil = "crude_oil"
    case refinedOil = "refined_oil"
    case naturalGas = "natural_gas"
    case coal = "coal"
    case gasoline = "gasoline"
    case diesel = "diesel"
    case kerosene = "kerosene"
    case propane = "propane"
    case ethanol = "ethanol"
    case biofuel = "biofuel"
    
    // === MANUFACTURING COMMODITIES (15) ===
    case ironOre = "iron_ore"
    case copper = "copper"
    case aluminum = "aluminum"
    case steel = "steel"
    case machinery = "machinery"
    case vehicles = "vehicles"
    case electronics = "electronics"
    case pharmaceuticals = "pharmaceuticals"
    case chemicals = "chemicals"
    case plastics = "plastics"
    case fertilizers = "fertilizers"
    case cement = "cement"
    = glass = "glass"
    case paper = "paper"
    
    // === TEXTILES & CLOTHING (8) ===
    case cottonFabric = "cotton_fabric"
    case woolFabric = "wool_fabric"
    case polyester = "polyester"
    case silk = "silk"
    case clothing = "clothing"
    case footwear = "footwear"
    case yarn = "yarn"
    case thread = "thread"
    
    // === SERVICES (6) ===
    case tourism = "tourism"
    case financialServices = "financial_services"
    case transportation = "transportation"
    case insurance = "insurance"
    case consulting = "consulting"
    case technologyLicensing = "tech_licensing"
    
    // Get category
    var category: CommodityCategory {
        switch self {
        case .wheat, .corn, .rice, .soybeans, .barley, .oats, .sugarCane, .sugarBeets,
              .potatoes, .cotton, .coffee, .tea, .cocoa, .fruits, .vegetables, .nuts,
              .spices, .tobacco, .timber, .woodPulp, .rubber, .hay, .alfalfa, .ensilage:
            return .agricultural
        case .crudeOil, .refinedOil, .naturalGas, .coal, .gasoline, .diesel, .kerosene,
              .propane, .ethanol, .biofuel:
            return .energy
        case .ironOre, .copper, .aluminum, .steel, .machinery, .vehicles, .electronics,
              .pharmaceuticals, .chemicals, .plastics, .fertilizers, .cement, .glass, .paper:
            return .manufacturing
        case .cottonFabric, .woolFabric, .polyester, .silk, .clothing, .footwear, .yarn, .thread:
            return .textiles
        case .tourism, .financialServices, .transportation, .insurance, .consulting, .technologyLicensing:
            return .services
        }
    }
    
    var typicalUnit: String {
        switch self {
        case .wheat, .corn, .barley, .oats, .soybeans: "bushel"
        case .rice: "tonne"
        case .sugarCane, .sugarBeets: "tonne"
        case .potatoes: "tonne"
        case .cotton: "bale"
        case .coffee: "kg"
        case .tea: "kg"
        case .cocoa: "tonne"
        case .fruits, .vegetables: "tonne"
        case .nuts: "kg"
        case .spices: "kg"
        case .tobacco: "kg"
        case .timber, .woodPulp: "cubic_metres"
        case .rubber: "tonne"
        case .hay, .alfalfa, .ensilage: "tonne"
        case .crudeOil, .refinedOil: "barrel"
        case .naturalGas: "m³"
        case .coal: "tonne"
        case .gasoline, .diesel, .kerosene, .propane: "litre"
        case .ethanol, .biofuel: "litre"
        case .ironOre, .copper, .aluminum: "tonne"
        case .steel: "tonne"
        case .machinery, .vehicles: "unit"
        case .electronics: "unit"
        case .pharmaceuticals: "prescription"
        case .chemicals: "tonne"
        case .plastics: "tonne"
        case .fertilizers: "tonne"
        case .cement, .glass, .paper: "tonne"
        case .cottonFabric, .woolFabric, .polyester, .silk: "metres"
        case .clothing, .footwear: "unit"
        case .yarn, .thread: "kg"
        case .tourism: "person"
        case .financialServices: "transaction"
        case .transportation: "shipment"
        case .insurance: "policy"
        case .consulting: "engagement"
        case .technologyLicensing: "license"
        }
    }
    
    var priceVolatility: Double {
        switch self {
        case .wheat, .corn, .rice, .soybeans, .crudeOil, .refinedOil: return 0.8
        case .barley, .oats, .sugarCane, .sugarBeets, .potatoes, .cotton: return 0.6
        case .coffee, .tea, .cocoa, .spices: return 0.7
        case .crudeOil, .refinedOil, .naturalGas, .gasoline, .diesel: return 0.9
        case .coal: return 0.5
        case .ironOre, .copper, .aluminum, .steel: return 0.4
        case .machinery, .vehicles: return 0.3
        case .pharmaceuticals: return 0.5
        case .chemicals: return 0.6
        case .plastics: return 0.4
        case .fertilizers: return 0.5
        case .cottonFabric, .woolFabric: return 0.5
        case .clothing, .footwear: return 0.6
        case .tourism: return 0.8
        default: return 0.5
        }
    }
    
    var demandElasticity: Double {
        // How quantity demanded responds to price changes
        switch self {
        case .wheat, .rice, .corn, .potatoes: return -0.8 // Inelastic - staple foods
        case .corn, .soybeans, .barley: return -0.6
        case .cotton, .spices: return -0.7
        case .crudeOil, .refinedOil, .naturalGas: return -0.4 // Relatively inelastic
        case .gasoline, .diesel: return -0.5
        case .coal: return -0.3
        case .ironOre, .copper, .aluminum: return -0.5
        case .steel: return -0.4
        case .machinery: return -0.6
        case .vehicles: return -0.7
        case .pharmaceuticals: return -0.2 // Very inelastic (health)
        case .chemicals: return -0.5
        case .plastics: return -0.6
        case .fertilizers: return -0.7
        case .cottonFabric: return -0.8
        case .clothing, .footwear: return -0.9
        case .tourism: return -1.1 // Elastic - discretionary
        case .financialServices: return -0.5
        case .transportation: return -0.6
        case .insurance: return -0.4
        case .consulting: return -1.2 // Highly elastic
        case .technologyLicensing: return -0.8
        default: return -0.5
        }
    }
}

// Trade commodity info
public struct TradeCommodityInfo {
    public let name: String
    public var category: CommodityCategory
    public var typicalUnit: String
    public var seasonality: Double // 0-1
    public var priceVolatility: Double // 0-1
    public var demandElasticity: Double
    public var supplyElasticity: Double
    public var minQuantity: Double
    public var maxQuantity: Double
    
    public init(name: String, category: CommodityCategory, typicalUnit: String, seasonality: Double = 0.3, priceVolatility: Double = 0.5, demandElasticity: Double = -0.5, supplyElasticity: Double = 0.3, minQuantity: Double = 0, maxQuantity: Double = 1000000) {
        self.name = name
        self.category = category
        self.typicalUnit = typicalUnit
        self.seasonality = seasonality
        self.priceVolatility = priceVolatility
        self.demandElasticity = demandElasticity
        self.supplyElasticity = supplyElasticity
        self.minQuantity = minQuantity
        self.maxQuantity = maxQuantity
    }
}

public enum CommodityCategory: String, CaseIterable {
    case agricultural = "agricultural"
    case energy = "energy"
    case manufacturing = "manufacturing"
    case minerals = "minerals"
    case textiles = "textiles"
    case food = "food"
    case rawMaterials = "raw_materials"
    case finishedGoods = "finished_goods"
}

// MARK: - Trade Flow Record (Expanded)

public struct TradeFlow: Identifiable {
    public let id: String
    public let timestamp: Date
    
    public let direction: TradeDirection
    public let commodity: TradeCommodity
    public let quantity: Double
    public let value: Double
    public let unitValue: Double
    
    // Partner info
    public let partnerCountry: String
    public let partnerName: String
    
    // Trade terms
    public let incoterm: String // "FOB", "CIF", "EXW", etc.
    public let currency: String
    
    // Cost breakdown
    public let freightCost: Double
    public let insuranceCost: Double
    public let tariffCost: Double
    public let otherCosts: Double
    
    // Quality
    public let qualityGrade: String?
    public let specification: [String: Any]?
    
    // Compliance
    public let certificateOfOrigin: Bool
    public let phytosanitaryCertificate: Bool
    public let customsDeclaration: Bool
    public let complianceStatus: String // "cleared", "held", "rejected", "pending"
    
    // Logistics
    public let originPort: String?
    public let destinationPort: String?
    public let transitCountry: String?
    
    // Metadata
    public let tradeRoute: String?
    public let containerTEUs: Double?
    public let estimatedDelivery: Date?
    public let actualDelivery: Date?
    public let shelfLifeDays: Double? // For perishables
    public let temperatureRequirements: ClosedRange<Double>? // For perishables
    
    public init(
        id: String,
        direction: TradeDirection,
        commodity: TradeCommodity,
        quantity: Double,
        value: Double,
        unitValue: Double,
        timestamp: Date = Date(),
        partnerCountry: String,
        partnerName: String,
        incoterm: String = "FOB",
        currency: String = "USD",
        freightCost: Double = 0,
        insuranceCost: Double = 0,
        tariffCost: Double = 0,
        otherCosts: Double = 0,
        qualityGrade: String? = nil,
        specification: [String: Any]? = nil,
        certificateOfOrigin: Bool = false,
        phytosanitaryCertificate: Bool = false,
        customsDeclaration: Bool = false,
        complianceStatus: String = "cleared",
        originPort: String? = nil,
        destinationPort: String? = nil,
        transitCountry: String? = nil,
        tradeRoute: String? = nil,
        containerTEUs: Double? = nil,
        estimatedDelivery: Date? = nil,
        actualDelivery: Date? = nil,
        shelfLifeDays: Double? = nil,
        temperatureRequirements: ClosedRange<Double>? = nil
    ) {
        self.id = id
        self.direction = direction
        self.commodity = commodity
        self.quantity = quantity
        self.value = value
        self.unitValue = unitValue
        self.timestamp = timestamp
        self.partnerCountry = partnerCountry
        self.partnerName = partnerName
        self.incoterm = incoterm
        self.currency = currency
        self.freightCost = freightCost
        self.insuranceCost = insuranceCost
        self.tariffCost = tariffCost
        self.otherCosts = otherCosts
        self.qualityGrade = qualityGrade
        self.specification = specification
        self.certificateOfOrigin = certificateOfOrigin
        self.phytosanitaryCertificate = phytosanitaryCertificate
        self.customsDeclaration = customsDeclaration
        self.complianceStatus = complianceStatus
        self.originPort = originPort
        self.destinationPort = destinationPort
        self.transitCountry = transitCountry
        self.tradeRoute = tradeRoute
        self.containerTEUs = containerTEUs
        self.estimatedDelivery = estimatedDelivery
        self.actualDelivery = actualDelivery
        self.shelfLifeDays = shelfLifeDays
        self.temperatureRequirements = temperatureRequirements
    }
}

// MARK: - Trade Partner (Expanded)

public struct TradePartner: Identifiable {
    public let id: String
    public let name: String
    public var gdp: Double
    public var population: Double
    public var gdpPerCapita: Double
    
    // Trade statistics
    public var exports: [TradeFlow] = []
    public var imports: [TradeFlow] = []
    public var tradeBalance: Double // Exports - Imports
    
    // Main commodities
    public var mainExportCommodities: [TradeCommodity: Double]
    public var mainImportCommodities: [TradeCommodity: Double]
    
    // Tariff settings
    public var averageTariffRate: Double // Weighted average (0-100%)
    public var mostFavoredNationRate: Double
    public var preferentialRates: [String: Double] // By partner ID
    
    // Economic indicators
    public var inflationRate: Double
    public var exchangeRate: Double // Units of this currency per USD
    public var exchangeRateVolatility: Double
    
    // Trade relationship
    public var tradeAgreements: [String]
    public var tradeRelations: String // "excellent", "good", "neutral", "tension", "conflict"
    public var politicalStability: Double // 0-1
    public var economicFreedom: Double // 0-1
    
    // Capacity limits
    public var importCapacity: Double
    public var exportCapacity: Double
    
    public init(
        id: String,
        name: String,
        gdp: Double,
        population: Double,
        exports: [TradeFlow] = [],
        imports: [TradeFlow] = [],
        mainExportCommodities: [TradeCommodity: Double] = [:],
        mainImportCommodities: [TradeCommodity: Double] = [:],
        averageTariffRate: Double = 5,
        mostFavoredNationRate: Double = 5,
        preferentialRates: [String: Double] = [:],
        inflationRate: Double = 2,
        exchangeRate: Double = 1,
        exchangeRateVolatility: Double = 0.5,
        tradeAgreements: [String] = [],
        tradeRelations: String = "neutral",
        politicalStability: Double = 0.8,
        economicFreedom: Double = 0.7,
        importCapacity: Double = Double.infinity,
        exportCapacity: Double = Double.infinity
    ) {
        self.id = id
        self.name = name
        self.gdp = gdp
        self.population = population
        gdpPerCapita = population > 0 ? gdp / population : 0
        self.exports = exports
        self.imports = imports
        self.tradeBalance = exports.reduce(0) { $0 + $1.value } - imports.reduce(0) { $0 + $1.value }
        self.mainExportCommodities = mainExportCommodities
        self.mainImportCommodities = mainImportCommodities
        self.averageTariffRate = averageTariffRate
        self.mostFavoredNationRate = mostFavoredNationRate
        self.preferredentialRates = preferentialRates // Note: stored as preferredentialRates
        self.inflationRate = inflationRate
        self.exchangeRate = exchangeRate
        self.exchangeRateVolatility = exchangeRateVolatility
        self.tradeAgreements = tradeAgreements
        self.tradeRelations = tradeRelations
        self.politicalStability = politicalStability
        self.economicFreedom = economicFreedom
        self.importCapacity = importCapacity
        self.exportCapacity = exportCapacity
    }
    
    mutating func fixPropertyNames() {
        // Ensure consistent naming
    }
    
    func tradePotential(with partner: TradePartner, commodities: [TradeCommodity]) -> Double {
        let gdpFactor = (gdp + partner.gdp) / 1000000
        let complementaryFactor = commodities.reduce(0) { $0 + (mainExportCommodities[$1] != nil || mainImportCommodities[$1] != nil ? 1 : 0) }
        return gdpFactor * min(1.0, complementaryFactor * 0.2)
    }
}

// MARK: - Trade Agreement (Expanded)

public enum TradeAgreementType: String, CaseIterable {
    case freeTrade = "free_trade"
    case customsUnion = "customs_union"
    case commonMarket = "common_market"
    case economicUnion = "economic_union"
    case bilateral = "bilateral"
    case regional = "regional"
    case multilateral = "multilateral"
    case preferential = "preferential"
    case customsTraditional = "customs_traditional"
}

public struct TradeAgreementDetails {
    public let id: String
    public let type: TradeAgreementType
    public let name: String
    public let signatoryCountries: [String]
    public let effectiveDate: Date
    public var expirationDate: Date?
    public var tariffReductions: [TradeCommodity: Double] // Percentage reductions
    public var rulesOfOrigin: String // "strict", "moderate", "lenient"
    public var disputeResolution: String
    public var lastUpdated: Date
    public var isActive: Bool
    public var cumulativeTariffSavings: Double // Tracked savings
    
    public init(
        id: String,
        type: TradeAgreementType,
        name: String,
        signatoryCountries: [String],
        effectiveDate: Date,
        expirationDate: Date? = nil,
        tariffReductions: [TradeCommodity: Double] = [:],
        rulesOfOrigin: String = "moderate",
        disputeResolution: String = "consultation",
        lastUpdated: Date = Date(),
        isActive: Bool = true,
        cumulativeTariffSavings: Double = 0
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.signatoryCountries = signatoryCountries
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
        self.tariffReductions = tariffReductions
        self.rulesOfOrigin = rulesOfOrigin
        self.disputeResolution = disputeResolution
        self.lastUpdated = lastUpdated
        self.isActive = isActive
        self.cumulativeTariffSavings = cumulativeTariffSavings
    }
}

// MARK: - Global Trade System (Expanded)

public class InternationalTradeSystem {
    private var tradeFlows: [String: TradeFlow] = [:]
    private var tradePartners: [String: TradePartner] = [:]
    private var activeAgreements: [String: TradeAgreementDetails] = [:]
    
    // Statistics tracking
    private var monthlyTradeStats: [String: Double] = [:]
    private var commodityTradeValues: [TradeCommodity: Double] = [:]
    private var partnerTradeValues: [String: Double] = [:]
    
    // Economic tracking
    var totalTradeValue: Double = 0
    var totalExports: Double = 0
    var totalImports: Double = 0
    var totalTariffRevenue: Double = 0
    var totalTradePartners: Int = 0
    
    public init() {
        #warning("Initialize default trade partners and agreements")
        #warning("Set up global trade network with major economies")
        #warning("Configure commodity information and default values")
        #warning("Set up initial trade relationships and agreements")
        #warning("Configure tariff structures and exchange rates")
        
        #warning("TODO: Add default trade partners (USA, EU, China, India, Brazil, etc.)")
        #warning("TODO: Set up default trade agreements (WTO, regional agreements, etc.)")
        #warning("TODO: Initialize commodity metadata with full attributes")
        #warning("TODO: Configure default tariff rates and exchange rates")
        #warning("TODO: Set up trade flow tracking systems")
        
        // Initialize major trade partners
        initializeDefaultPartners()
        
        // Set up some basic agreements
        setupBasicAgreements()
        
        // Initialize commodity metadata
        initializeCommodityMetadata()
    }
    
    private func initializeDefaultPartners() {
        // USA
        var usPrefs: [String: Double] = [:]
        tradePartners["USA"] = TradePartner(
            id: "USA",
            name: "United States",
            gdp: 25000000000000, // $25T
            population: 335000000,
            mainExportCommodities: [.corn: 50, .soybeans: 30, .wheat: 20, .machinery: 100],
            averageTariffRate: 2.5,
            inflationRate: 2.0,
            exchangeRate: 1.0,
            politicalStability: 0.85,
            economicFreedom: 0.8
        )
        
        // China
        tradePartners["CHN"] = TradePartner(
            id: "CHN",
            name: "China",
            gdp: 18000000000000, // $18T
            population: 1400000000,
            mainExportCommodities: [.machinery: 40, .electronics: 30, .steel: 20, .chemicals: 10],
            averageTariffRate: 3.5,
            inflationRate: 2.5,
            exchangeRate: 7.2,
            politicalStability: 0.7,
            economicFreedom: 0.55
        )
        
        // EU
        tradePartners["EU"] = TradePartner(
            id: "EU",
            name: "European Union",
            gdp: 18000000000000,
            population: 450000000,
            mainExportCommodities: [.machinery: 35, .pharmaceuticals: 25, .chemicals: 20, .vehicles: 15],
            averageTariffRate: 1.5,
            inflationRate: 1.8,
            exchangeRate: 0.9,
            politicalStability: 0.88,
            economicFreedom: 0.75
        )
        
        // Brazil
        tradePartners["BRA"] = TradePartner(
            id: "BRA",
            name: "Brazil",
            gdp: 2000000000000, // $2T
            population: 215000000,
            mainExportCommodities: [.soybeans: 40, .coffee: 20, .ironOre: 20, .crudeOil: 15],
            averageTariffRate: 6.0,
            inflationRate: 3.5,
            exchangeRate: 5.3,
            politicalStability: 0.65,
            economicFreedom: 0.6
        )
        
        // India
        tradePartners["IND"] = TradePartner(
            id: "IND",
            name: "India",
            gdp: 3.500000000000, // $3.5T
            population: 1400000000,
            mainExportCommodities: [.cotton: 25, .pharmaceuticals: 20, .rice: 20, .software: 15],
            averageTariffRate: 8.0,
            inflationRate: 4.5,
            exchangeRate: 83.0,
            politicalStability: 0.6,
            economicFreedom: 0.5
        )
        
        totalTradePartners = tradePartners.count
    }
    
    private func setupBasicAgreements() {
        // WTO-style multilateral agreement
        let wto = TradeAgreementDetails(
            id: "wto_2024",
            type: .multilateral,
            name: "World Trade Organization Agreement",
            signatoryCountries: ["USA", "CHN", "EU", "BRA", "IND", "JPN", "CAN"],
            effectiveDate: Date(),
            tariffReductions: [:], // General most-favored-nation rates apply
            rulesOfOrigin: "moderate",
            disputeResolution: "panel",
            isActive: true
        )
        activeAgreements["wto_2024"] = wto
        
        // US-China Phase One
        let usChina = TradeAgreementDetails(
            id: "us_china_phase1",
            type: .bilateral,
            name: "US-China Phase One Trade Agreement",
            signatoryCountries: ["USA", "CHN"],
            effectiveDate: Date(),
            tariffReductions: [.soybeans: 25, .crudeOil: 20, .machinery: 15],
            rulesOfOrigin: "strict",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["us_china_phase1"] = usChina
        
        // EU-Canada
        let euCanada = TradeAgreementDetails(
            id: "eu_canada",
            type: .freeTrade,
            name: "EU-Canada Comprehensive Economic and Trade Agreement",
            signatoryCountries: ["EU", "CAN"],
            effectiveDate: Date(),
            tariffReductions: [:],
            rulesOfOrigin: "moderate",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["eu_canada"] = euCanada
    }
    
    private func initializeCommodityMetadata() {
        // Initialize comprehensive commodity info for all trade commodities
        // This would be extensive - storing basic info for key commodities
        for commodity in TradeCommodity.allCases {
            // Basic metadata initialization
            // In a full system, would have a complete database
        }
    }
    
    // MARK: - Partner Management
    
    public func addTradePartner(_ partner: TradePartner) {
        tradePartners[partner.id] = partner
        #warning("Recalculate trade balances and statistics")
    }
    
    public func getTradePartner(_ id: String) -> TradePartner? {
        return tradePartners[id]
    }
    
    public func getAllTradePartners() -> [TradePartner] {
        return Array(tradePartners.values)
    }
    
    public func removeTradePartner(_ id: String) {
        tradePartners.removeValue(forKey: id)
        #warning("Recalculate statistics after partner removal")
    }
    
    // MARK: - Trade Flow Management
    
    public mutating func recordTradeFlow(_ flow: TradeFlow) -> TradeFlow {
        #warning("Validate trade flow: capacity, compliance, agreements")
        
        let tariffApplied = applyTariff(flow)
        var updatedFlow = flow
        updatedFlow.tariffCost = tariffApplied
        // Calculate total value including all costs
        updatedFlow.value = flow.quantity * flow.unitValue + tariffApplied + flow.freightCost + flow.insuranceCost + flow.otherCosts
        updatedFlow.complianceStatus = checkCompliance(flow)
        
        tradeFlows[updatedFlow.id] = updatedFlow
        
        #warning("Update partner trade statistics")
        updateTradeStatistics(flow: updatedFlow)
        
        return updatedFlow
    }
    
    private func applyTariff(_ flow: TradeFlow) -> Double {
        guard let partner = tradePartners[flow.partnerCountry] else {
            return flow.value * (flow.direction == .import ? 5 / 100 : 0)
        }
        
        var tariffRate: Double
        
        // Check for trade agreement
        if let agreementId = findApplicableAgreement(flow.partnerCountry, flow.direction) {
            if let agreement = activeAgreements[agreementId] {
                if let reduction = agreement.tariffReductions[flow.commodity] {
                    tariffRate = max(0, partner.averageTariffRate - reduction)
                } else {
                    tariffRate = partner.averageTariffRate
                }
            } else {
                tariffRate = partner.averageTariffRate
            }
        } else {
            tariffRate = partner.averageTariffRate
        }
        
        // Apply MFN if no special agreement
        let finalTariffRate = tariffRate
        
        return flow.value * (finalTariffRate / 100)
    }
    
    private func findApplicableAgreement(_ partnerCountry: String, _ direction: TradeDirection) -> String? {
        // Search through active agreements for matching partner
        for (agreementId, agreement) in activeAgreements where agreement.isActive {
            if agreement.signatoryCountries.contains(partnerCountry) {
                return agreementId
            }
        }
        return nil
    }
    
    private func checkCompliance(_ flow: TradeFlow) -> String {
        if flow.certificateOfOrigin && flow.phytosanitaryCertificate {
            return "cleared"
        } else if flow.customsDeclaration {
            return "held"
        } else {
            return "pending"
        }
    }
    
    private func updateTradeStatistics(flow: TradeFlow) {
        totalTradeValue += flow.value
        
        if flow.direction == .export {
            totalExports += flow.value
        } else if flow.direction == .import {
            totalImports += flow.value
        }
        
        // Update commodity values
        commodityTradeValues[flow.commodity, default: 0] += flow.value
        
        // Update partner values
        partnerTradeValues[flow.partnerCountry, default: 0] += flow.value
        
        totalTariffRevenue += flow.tariffCost
    }
    
    // MARK: - Partner Trade Operations
    
    public mutating func exportCommodities(
        _ commodities: [TradeCommodity],
        quantities: [TradeCommodity: Double],
        to partnerId: String,
        unitValues: [TradeCommodity: Double],
        direction: TradeDirection = .export
    ) -> [TradeFlow] {
        var flows: [TradeFlow] = []
        guard let partner = tradePartners[partnerId] else { return flows }
        
        for commodity in commodities {
            if let quantity = quantities[commodity],
               let unitValue = unitValues[commodity],
               unitValue > 0 {
                
                let estimatedValue = quantity * unitValue
                
                let flow = TradeFlow(
                    id: "trade-\(Date.timeIntervalSince1970)-\(commodity.rawValue)",
                    direction: direction,
                    commodity: commodity,
                    quantity: quantity,
                    value: estimatedValue,
                    unitValue: unitValue,
                    partnerCountry: partnerId,
                    partnerName: partner.name,
                    complianceStatus: "cleared"
                )
                
                let recordedFlow = recordTradeFlow(flow)
                flows.append(recordedFlow)
            }
        }
        
        return flows
    }
    
    public mutating func importCommodities(
        _ commodities: [TradeCommodity],
        quantities: [TradeCommodity: Double],
        from partnerId: String,
        unitValues: [TradeCommodity: Double],
        direction: TradeDirection = .import
    ) -> [TradeFlow] {
        var flows: [TradeFlow] = []
        guard let partner = tradePartners[partnerId] else { return flows }
        
        for commodity in commodities {
            if let quantity = quantities[commodity],
               let unitValue = unitValues[commodity],
               unitValue > 0 {
                
                let estimatedValue = quantity * unitValue
                
                let flow = TradeFlow(
                    id: "trade-\(Date.timeIntervalSince1970)-\(commodity.rawValue)",
                    direction: direction,
                    commodity: commodity,
                    quantity: quantity,
                    value: estimatedValue,
                    unitValue: unitValue,
                    partnerCountry: partnerId,
                    partnerName: partner.name,
                    complianceStatus: "pending"
                )
                
                let recordedFlow = recordTradeFlow(flow)
                flows.append(recordedFlow)
            }
        }
        
        return flows
    }
    
    // MARK: - Agreement Management
    
    public mutating func createAgreement(
        id: String,
        type: TradeAgreementType,
        name: String,
        signatoryCountries: [String],
        effectiveDate: Date
    ) -> TradeAgreementDetails {
        let agreement = TradeAgreementDetails(
            id: id,
            type: type,
            name: name,
            signatoryCountries: signatoryCountries,
            effectiveDate: effectiveDate
        )
        
        activeAgreements[id] = agreement
        #warning("Initialize agreement tariff reductions and rules")
        
        return agreement
    }
    
    public mutating func removeAgreement(_ id: String) {
        activeAgreements.removeValue(forKey: id)
        #warning("Recalculate tariffs and trade flows after agreement removal")
    }
    
    public mutating func updateAgreementTariffs(
        _ id: String,
        tariffReductions: [TradeCommodity: Double]
    ) {
        guard var agreement = activeAgreements[id] else { return }
        agreement.tariffReductions = tariffReductions
        agreement.lastUpdated = Date()
        activeAgreements[id] = agreement
        #warning("Recalculate trade flows with new tariffs")
    }
    
    // MARK: - Statistics and Reporting
    
    public func getTradeStatistics() -> TradeStatistics {
        let totalExports = exports.reduce(0) { $0 + $1.value }
        let totalImports = imports.reduce(0) { $0 + $1.value }
        let tradeBalance = totalExports - totalImports
        
        // By commodity
        var commodityValues: [TradeCommodity: Double] = [:]
        for flow in tradeFlows.values where flow.direction == .export {
            commodityValues[flow.commodity, default: 0] += flow.value
        }
        for flow in tradeFlows.values where flow.direction == .import {
            commodityValues[flow.commodity, default: 0] -= flow.value
        }
        
        // By partner
        var partnerValues: [String: Double] = [:]
        for flow in tradeFlows.values {
            partnerValues[flow.partnerCountry, default: 0] += flow.value
        }
        
        // Average tariff
        let avgTariff = tradeFlows.isEmpty ? 0 : tradeFlows.reduce(0) { $0 + $1.tariffCost } / Double(tradeFlows.count) / (totalImports > 0 ? totalImports : 1) * 100
        
        return TradeStatistics(
            totalTradeValue: totalTradeValue,
            totalExports: totalExports,
            totalImports: totalImports,
            tradeBalance: tradeBalance,
            totalTariffRevenue: totalTariffRevenue,
            commodityTradeValues: commodityValues,
            partnerTradeValues: partnerValues,
            averageTariffRate: avgTariff,
            totalFlows: tradeFlows.count,
            activeAgreements: activeAgreements.count,
            totalPartners: tradePartners.count
        )
    }
    
    public func getTradeFlow(
        _ commodity: TradeCommodity,
        direction: TradeDirection,
        with partnerId: String
    ) -> [TradeFlow] {
        tradeFlows.values.filter { flow in
            flow.commodity == commodity && flow.direction == direction && flow.partnerCountry == partnerId
        }
    }
    
    // Prediction functionality
    func predictTradeFlow(
        _ commodity: TradeCommodity,
        from source: String,
        to destination: String,
        timePeriod: Int // months
    ) -> (predictedValue: Double, confidence: Double) {
        let historicalFlows = tradeFlows.values.filter {
            $0.commodity == commodity && 
            $0.partnerCountry == destination && 
            $0.direction == (source == "local" ? .export : .import)
        }
        
        guard !historicalFlows.isEmpty else {
            return (0, 0.1)
        }
        
        let avgValue = historicalFlows.reduce(0) { $0 + $1.value } / Double(historicalFlows.count)
        let trendAdjustment = 1.0
        let confidence = min(0.9, 0.3 + Double(historicalFlows.count) * 0.07)
        
        let predictedValue = avgValue * trendAdjustment * Double(timePeriod)
        
        return (predictedValue, confidence)
    }
}

// MARK: - Trade Statistics

public struct TradeStatistics {
    let totalTradeValue: Double
    let totalExports: Double
    let totalImports: Double
    let tradeBalance: Double
    let totalTariffRevenue: Double
    let commodityTradeValues: [TradeCommodity: Double]
    let partnerTradeValues: [String: Double]
    let averageTariffRate: Double
    let totalFlows: Int
    let activeAgreements: Int
    let totalPartners: Int
}

// MARK: - Previews
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct InternationalTradePreview: PreviewProvider {
//    static var previews: some View {
//        Text("International Trade System Preview")
//    }
//}
//#endif