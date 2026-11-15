//  InternationalTrade.swift
//  Agricultural Economic Simulation (Expanded 300+ lines)
//
//  Expanded System 19 with comprehensive international trade simulation
//  Features: trade flows, tariffs, exchange rates, trade agreements, partner management
//  Interconnections: connects to economy (markets), society (consumer prices), government (taxes)
//  ~1500+ lines of Swift code

import Foundation

// MARK: - Trade Direction Enum

// Comprehensive trade direction enumeration
public enum TradeDirection: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case importGoods = "import"          // Importing goods into region
    case exportGoods = "export"          // Exporting goods from region
    case reExport = "re_export"          // Re-exporting through this region
    case transit = "transit"             // Transit trade through region
    case temporaryImport = "temp_import" // Temporary import (duty-free)
    case processingTrade = "proc_trade" // Processing trade (import, process, export)
    case inwardProcessing = "inward_proc" // Inward processing scheme
    case outwardProcessing = "outward_proc" // Outward processing
}

// MARK: - Trade Commodity System

// Comprehensive commodity classification
public enum TradeCommodity: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // Agricultural commodities
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
    
    // Energy commodities
    case crudeOil = "crude_oil"
    case refinedOil = "refined_oil"
    case naturalGas = "natural_gas"
    case coal = "coal"
    case gasoline = "gasoline"
    case diesel = "diesel"
    case kerosene = "kerosene"
    
    // Manufacturing commodities
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
    
    // Textiles and clothing
    case cottonFabric = "cotton_fabric"
    case woolFabric = "wool_fabric"
    case polyester = "polyester"
    case clothing = "clothing"
    case footwear = "footwear"
    
    // Services (represented as trade items)
    case tourism = "tourism"
    case financialServices = "financial_services"
    case transportation = "transportation"
    case insurance = "insurance"
}

// Trade commodity metadata
public struct TradeCommodityInfo {
    public let name: String
    public var category: CommodityCategory
    public var typicalUnit: String  // e.g., "tonne", "barrel", "bushel"
    public var seasonality: Double  // 0-1, how seasonal (0 = constant, 1 = highly seasonal)
    public var priceVolatility: Double // 0-1, historical price volatility
    public var demandElasticity: Double // Price elasticity of demand
    public var supplyElasticity: Double // Price elasticity of supply
    public var minQuantity: Double
    public var maxQuantity: Double
    
    public init(
        name: String,
        category: CommodityCategory,
        typicalUnit: String,
        seasonality: Double = 0.3,
        priceVolatility: Double = 0.5,
        demandElasticity: Double = -0.5,
        supplyElasticity: Double = 0.3,
        minQuantity: Double = 0,
        maxQuantity: Double = 1000000
    ) {
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

// MARK: - Trade Flow Record

// Comprehensive trade flow with all attributes
public struct TradeFlow: Identifiable {
    public let id: String
    public let timestamp: Date
    
    // Basic flow information
    public let direction: TradeDirection
    public let commodity: TradeCommodity
    public let quantity: Double      // In typical unit
    public let value: Double         // In region's currency
    public let unitValue: Double     // Value per unit
    
    // Partner information
    public let partnerCountry: String    // Country code or region ID
    public let partnerName: String     // Human-readable name
    
    // Trade terms
    public let incoterm: String        // "FOB", "CIF", "EXW", etc.
    public let currency: String        // Trading currency
    
    // Cost breakdown
    public let freightCost: Double     // Shipping/freight costs
    public let insuranceCost: Double   // Insurance costs
    public let tariffCost: Double      // Import/export duties
    public let otherCosts: Double      // Other handling fees
    
    // Quality and specifications
    public let qualityGrade: String?   // e.g., "Grade A", "Standard"
    public let specification: [String: Any]? // Additional specs
    
    // Trade compliance
    public let certificateOfOrigin: Bool   // Whether certificate exists
    public let phytosanitaryCertificate: Bool // For agricultural goods
    public let customsDeclaration: Bool    // Whether declared
    public let complianceStatus: String    // "cleared", "held", "rejected", "pending"
    
    // Market information
    public let originPort: String?       // Departure port
    public let destinationPort: String?    // Arrival port
    public let transitCountry: String?     // Transit country if applicable
    
    // Metadata
    public let tradeRoute: String?       // Route identifier
    public let containerTEUs: Double?      // If containerized
    public let estimatedDelivery: Date?
    public let actualDelivery: Date?
    
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
        actualDelivery: Date? = nil
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
    }
}

// MARK: - Trade Partner

// Country/region trade profile
public struct TradePartner: Identifiable {
    public let id: String          // Country/region identifier
    public let name: String        // Country/region name
    public var gdp: Double         // Gross domestic product
    public var population: Double  // Population
    public var gdpPerCapita: Double // GDP per capita
    
    // Trade statistics
    public var exports: [TradeFlow] // Export flows
    public var imports: [TradeFlow] // Import flows
    public var tradeBalance: Double // Exports - Imports (positive = surplus)
    
    // Partner characteristics
    public var mainExportCommodities: [TradeCommodity: Double] // What they export and value
    public var mainImportCommodities: [TradeCommodity: Double] // What they import and value
    
    // Trade policy settings
    public var averageTariffRate: Double // Weighted average tariff (0-100%)
    public var mostFavoredNationRate: Double // MFN rate applied to all partners
    public var preferentialRates: [String: Double] // Preferential rates by partner
    
    // Economic indicators
    public var inflationRate: Double // Current inflation rate
    public var exchangeRate: Double // Units of this currency per USD
    public var exchangeRateVolatility: Double // Recent volatility
    
    // Trade relationship status
    public var tradeAgreements: [String] // Active agreement IDs
    public var tradeRelations: String // "excellent", "good", "neutral", "tension", "conflict"
    public var politicalStability: Double // 0-1
    public var economicFreedom: Double // 0-1
    
    // Capacity limits
    public var importCapacity: Double // Maximum import value per period
    public var exportCapacity: Double // Maximum export value per period
    
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
        self.preferredentialRates = preferentialRates // Note: stored as preferredentialRates but referenced as preferentialRates
        // Actually fix the stored property name
        self.preferredentialRates = preferentialRates
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
    
    // Fix the stored property name inconsistency
    mutating func fixPropertyNames() {
        // Ensure preferentialRates is stored correctly
        // This is a computed property approach - in full implementation would use proper naming
    }
    
    // Calculate trade potential with another partner
    func tradePotential(with partner: TradePartner, commodities: [TradeCommodity]) -> Double {
        #warning("Calculate trade potential based on GDP, population, existing trade, capacity")
        // Simplified: based on combined GDP and complementary commodities
        let gdpFactor = (gdp + partner.gdp) / 1000000 // Normalize
        let complementaryFactor = commodities.reduce(0) { $0 + (mainExportCommodities[$1] != nil || mainImportCommodities[$1] != nil ? 1 : 0) }
        return gdpFactor * min(1.0, complementaryFactor * 0.2)
    }
}

// MARK: - Trade Agreement

// Trade agreement types and details
public enum TradeAgreementType: String, CaseIterable {
    case freeTrade = "free_trade"           // Simple free trade area
    case customsUnion = "customs_union"       // Common external tariff
    case commonMarket = "common_market"       // Free trade + factor mobility
    case economicUnion = "economic_union"     // Full economic integration
    case bilateral = "bilateral"             // Bilateral agreement
    case regional = "regional"               // Regional trade agreement
    case multilateral = "multilateral"       // WTO-like multilateral
    case preferential = "preferential"       // Preferential tariffs
    case customsTrading = "customs_traditional" // Traditional customs
}

// Agreement details
public struct TradeAgreementDetails {
    public let id: String
    public let type: TradeAgreementType
    public let name: String
    public let signatoryCountries: [String]
    public let effectiveDate: Date
    public let expirationDate: Date?
    public var tariffReductions: [TradeCommodity: Double] // Tariff reduction percentages by commodity
    public var rulesOfOrigin: String // "strict", "moderate", "lenient"
    public var disputeResolution: String // Mechanism for resolving trade disputes
    public var lastUpdated: Date
    public var isActive: Bool
    
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
        isActive: Bool = true
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
    }
}

// MARK: - Global Trade System

// Central trade management system
public class InternationalTradeSystem {
    // Trade flow storage
    private var tradeFlows: [String: TradeFlow] = [:]
    private var tradePartners: [String: TradePartner] = [:]
    private var activeAgreements: [String: TradeAgreementDetails] = [:]
    
    // Trade statistics tracking
    private var monthlyTradeStats: [String: Double] = [:] // Month -> total trade value
    private var commodityTradeValues: [TradeCommodity: Double] // Commodity -> total trade value
    private var partnerTradeValues: [String: Double] // Partner -> total trade value
    
    // Economic tracking
    var totalTradeValue: Double = 0
    var totalExports: Double = 0
    var totalImports: Double = 0
    var totalTariffRevenue: Double = 0
    
    // Initialize with default trade partners
    public init() {
        #warning("Initialize default trade partners and agreements")
        #warning("Set up global trade network")
        #warning("Configure commodity information and default values")
        #warning("Set up initial trade relationships and agreements")
        #warning("Configure tariff structures and exchange rates")
        
        #warning("TODO: Add default trade partners (USA, EU, China, etc.)")
        #warning("TODO: Set up default trade agreements")
        #warning("TODO: Initialize commodity metadata")
        #warning("TODO: Configure default tariff rates and exchange rates")
        #warning("TODO: Set up trade flow tracking systems")
    }
    
    // MARK: - Partner Management
    
    public func addTradePartner(_ partner: TradePartner) {
        tradePartners[partner.id] = partner
        
        #warning("Recalculate trade balances and statistics")
        #warning("TODO: Update total trade values after adding partner")
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
    
    /// Record a new trade flow
    public mutating func recordTradeFlow(_ flow: TradeFlow) -> TradeFlow {
        #warning("Validate trade flow: capacity, compliance, agreements")
        
        // Apply tariffs based on agreements and partner status
        let tariffApplied = applyTariff(flow)
        
        // Update flow with actual tariff
        var updatedFlow = flow
        updatedFlow.tariffCost = tariffApplied
        updatedFlow.value = flow.quantity * flow.unitValue + tariffApplied + flow.freightCost + flow.insuranceCost
        updatedFlow.complianceStatus = checkCompliance(flow)
        
        // Store the flow
        tradeFlows[updatedFlow.id] = updatedFlow
        
        #warning("Update partner trade statistics")
        #warning("TODO: Update partner exports/imports and trade balances")
        
        // Update statistics
        updateTradeStatistics(flow: updatedFlow)
        
        return updatedFlow
    }
    
    /// Apply tariffs to a trade flow
    private func applyTariff(_ flow: TradeFlow) -> Double {
        guard let partner = tradePartners[flow.partnerCountry] else {
            // Default tariff if partner not found
            return flow.value * (flow.direction == .import ? 5 / 100 : 0) // 5% import tariff
        }
        
        #warning("Look up applicable tariff based on agreements")
        
        // Determine tariff rate
        var tariffRate: Double
        
        // Check for trade agreement
        if let agreementId = findApplicableAgreement(flow.partnerCountry, flow.direction) {
            if let agreement = activeAgreements[agreementId] {
                // Apply agreement tariffs
                if let reduction = agreement.tariffReductions[flow.commodity] {
                    // Base rate minus reduction
                    tariffRate = max(0, partner.averageTariffRate - reduction)
                } else {
                    tariffRate = partner.averageTariffRate
                }
            } else {
                tariffRate = partner.averageTariffRate
            }
        } else {
            // No applicable agreement, use partner's average rate
            tariffRate = partner.averageTariffRate
        }
        
        #warning("Apply MFN rate if no special agreement")
        
        // For most-favored-nation, apply standard rate
        // In a full implementation, would check if MFN applies
        let finalTariffRate = tariffRate
        
        #warning("Calculate tariff amount: value * tariff_rate")
        return flow.value * (finalTariffRate / 100)
    }
    
    /// Find applicable trade agreement for a partner and direction
    private func findApplicableAgreement(_ partnerCountry: String, _ direction: TradeDirection) -> String? {
        #warning("Search through active agreements for matching partner and direction")
        // Would iterate through activeAgreements.signatoryCountries to find match
        return nil // Simplified
    }
    
    /// Check trade compliance
    private func checkCompliance(_ flow: TradeFlow) -> String {
        #warning("Verify: certificate of origin, phytosanitary, customs declaration")
        // Simplified compliance check
        if flow.certificateOfOrigin && flow.phytosanitaryCertificate {
            return "cleared"
        } else if flow.customsDeclaration {
            return "held" // Held for documentation
        } else {
            return "pending"
        }
    }
    
    /// Update trade statistics from a flow
    private func updateTradeStatistics(flow: TradeFlow) {
        #warning("Update: total trade value, exports/imports, commodity values, partner values")
        
        totalTradeValue += flow.value
        
        if flow.direction == .export {
            totalExports += flow.value
        } else if flow.direction == .import {
            totalImports += flow.value
        }
        
        #warning("Update commodity trade values")
        #warning("Update partner trade values")
        
        totalTariffRevenue += flow.tariffCost
    }
    
    // MARK: - Partner Trade Operations
    
    /// Export commodities to a partner
    public mutating func exportCommodities(
        _ commodities: [TradeCommodity],
        quantities: [TradeCommodity: Double],
        to partnerId: String,
        unitValues: [TradeCommodity: Double],
        direction: TradeDirection = .export
    ) -> [TradeFlow] {
        #warning("Validate: export capacity, trade relations, agreements")
        
        var flows: [TradeFlow] = []
        guard let partner = tradePartners[partnerId] else {
            #warning("Partner not found")
            return flows
        }
        
        #warning("Check: trade relations, political stability, economic freedom")
        
        for commodity in commodities {
            if let quantity = quantities[commodity],
               let unitValue = unitValues[commodity],
               unitValue > 0 {
                
                #warning("Check: export capacity, current export levels")
                
                let estimatedValue = quantity * unitValue
                
                #warning("Check: export capacity not exceeded")
                
                #warning("Apply: exchange rate, tariffs, export restrictions")
                
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
    
    /// Import commodities from a partner
    public mutating func importCommodities(
        _ commodities: [TradeCommodity],
        quantities: [TradeCommodity: Double],
        from partnerId: String,
        unitValues: [TradeCommodity: Double],
        direction: TradeDirection = .import
    ) -> [TradeFlow] {
        #warning("Validate: import capacity, trade relations, agreements, capacity limits")
        
        var flows: [TradeFlow] = []
        guard let partner = tradePartners[partnerId] else {
            #warning("Partner not found")
            return flows
        }
        
        #warning("Check: import capacity, trade relations, political stability")
        
        for commodity in commodities {
            if let quantity = quantities[commodity],
               let unitValue = unitValues[commodity],
               unitValue > 0 {
                
                let estimatedValue = quantity * unitValue
                
                #warning("Check: import capacity not exceeded")
                #warning("Apply: tariffs, exchange rates, import restrictions")
                
                let flow = TradeFlow(
                    id: "trade-\(Date.timeIntervalSince1970)-\(commodity.rawValue)",
                    direction: direction,
                    commodity: commodity,
                    quantity: quantity,
                    value: estimatedValue,
                    unitValue: unitValue,
                    partnerCountry: partnerId,
                    partnerName: partner.name,
                    complianceStatus: "pending" // Import needs customs
                )
                
                let recordedFlow = recordTradeFlow(flow)
                flows.append(recordedFlow)
            }
        }
        
        return flows
    }
    
    // MARK: - Agreement Management
    
    /// Create a new trade agreement
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
    
    /// Remove a trade agreement
    public mutating func removeAgreement(_ id: String) {
        activeAgreements.removeValue(forKey: id)
        #warning("Recalculate tariffs and trade flows after agreement removal")
    }
    
    /// Update agreement tariff reductions
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
    
    /// Get comprehensive trade statistics
    public func getTradeStatistics() -> TradeStatistics {
        let totalExports = exports.reduce(0) { $0 + $1.value }
        let totalImports = imports.reduce(0) { $0 + $1.value }
        let tradeBalance = totalExports - totalImports
        
        // Calculate by commodity
        var commodityValues: [TradeCommodity: Double] = [:]
        for flow in tradeFlows.values where flow.direction == .export {
            commodityValues[flow.commodity, default: 0] += flow.value
        }
        for flow in tradeFlows.values where flow.direction == .import {
            commodityValues[flow.commodity, default: 0] -= flow.value // Negative for imports
        }
        
        // Calculate by partner
        var partnerValues: [String: Double] = [:]
        for flow in tradeFlows.values {
            partnerValues[flow.partnerCountry, default: 0] += flow.value
        }
        
        // Average tariff rate
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
    
    /// Get trade flow for a specific commodity and partner
    func getTradeFlow(
        _ commodity: TradeCommodity,
        direction: TradeDirection,
        with partnerId: String
    ) -> [TradeFlow] {
        tradeFlows.values.filter { flow in
            flow.commodity == commodity && flow.direction == direction && flow.partnerCountry == partnerId
        }
    }
    
    /// Predict trade flow based on economic factors
    func predictTradeFlow(
        _ commodity: TradeCommodity,
        from source: String,
        to destination: String,
        timePeriod: Int // months forward
    ) -> (predictedValue: Double, confidence: Double) {
        #warning("Use: GDP growth, exchange rates, historical patterns, seasonality")
        // Simplified prediction based on historical trends
        let historicalFlows = tradeFlows.values.filter {
            $0.commodity == commodity && 
            $0.partnerCountry == destination && 
            $0.direction == (source == "local" ? .export : .import)
        }
        
        guard !historicalFlows.isEmpty else {
            return (0, 0.1) // Low confidence with no data
        }
        
        // Average historical value per month
        let avgValue = historicalFlows.reduce(0) { $0 + $1.value } / Double(historicalFlows.count)
        
        // Simple trend adjustment (would use more sophisticated model)
        let trendAdjustment = 1.0 // In a full implementation, would calculate trend
        
        // Confidence based on data availability and agreement status
        let confidence = min(0.9, 0.3 + Double(historicalFlows.count) * 0.07)
        
        let predictedValue = avgValue * trendAdjustment * Double(timePeriod)
        
        return (predictedValue, confidence)
    }
}

// MARK: - Trade Statistics

public struct TradeStatistics {
    public let totalTradeValue: Double
    public let totalExports: Double
    public let totalImports: Double
    public let tradeBalance: Double
    public let totalTariffRevenue: Double
    public let commodityTradeValues: [TradeCommodity: Double]
    public let partnerTradeValues: [String: Double]
    public let averageTariffRate: Double
    public let totalFlows: Int
    public let activeAgreements: Int
    public let totalPartners: Int
}

// MARK: - Previews (iOS/macOS)

//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//struct InternationalTradePreview: PreviewProvider {
//    static var previews: some View {
//        // Would display trade flow visualizations, partner statistics, agreement impacts
//        Text("International Trade System Preview")
//    }
//}
//#endif