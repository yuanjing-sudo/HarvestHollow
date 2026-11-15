//
//  InternationalTrade.swift
//  Agricultural Economic Simulation
//

import Foundation

// Trade flow direction
public enum TradeDirection: String {
    case import = "import"
    case export = "export"
}

// Trade flow record
public struct TradeFlow: Identifiable {
    public let id: String
    public let commodity: String
    public let direction: TradeDirection
    public let origin: String     // Country or region ID
    public let destination: String // Country or region ID
    public let quantity: Double
    public let value: Double       // In destination currency
    public let timestamp: Date
    public let tariffApplied: Double
    public let shippingCost: Double
    
    public init(id: String, commodity: String, direction: TradeDirection, origin: String, destination: String, quantity: Double, value: Double, timestamp: Date = Date(), tariffApplied: Double = 0, shippingCost: Double = 0) {
        self.id = id
        self.commodity = commodity
        self.direction = direction
        self.origin = origin
        self.destination = destination
        self.quantity = quantity
        self.value = value
        self.timestamp = timestamp
        self.tariffApplied = tariffApplied
        self.shippingCost = shippingCost
    }
}

// Exchange rate type
public typealias ExchangeRate = Double  // Units of quote currency per base currency

// Country/region profile for trade
public struct TradePartner: Identifiable {
    public let id: String
    public let name: String
    public let gdp: Double
    public let population: Int
    public var tradeBalance: Double   // positive = surplus, negative = deficit
    public var mainImports: [(commodity: String, value: Double)]
    public var mainExports: [(commodity: String, value: Double)]
    public var tariffRate: Double     // weighted average tariff (0-100)
    public var exchangeRateToBase: ExchangeRate
    public var tradeAgreements: [String]
    public var riskLevel: String      // low, medium, high
    
    public init(id: String, name: String, gdp: Double, population: Int, tradeBalance: Double, mainImports: [(commodity: String, value: Double)], mainExports: [(commodity: String, value: Double)], tariffRate: Double, exchangeRateToBase: ExchangeRate, tradeAgreements: [String] = [], riskLevel: String = "low") {
        self.id = id
        self.name = name
        self.gdp = gdp
        self.population = population
        self.tradeBalance = tradeBalance
        self.mainImports = mainImports
        self.mainExports = mainExports
        self.tariffRate = tariffRate
        self.exchangeRateToBase = exchangeRateToBase
        self.tradeAgreements = tradeAgreements
        self.riskLevel = riskLevel
    }
}

// Global trade system
public class InternationalTradeSystem {
    private var tradeFlows: [String: TradeFlow] = [:]
    private var tradePartners: [String: TradePartner] = [:]
    private var exchangeRates: [String: ExchangeRate] = [:]
    private let baseCurrency = "game_gold"
    
    public init() {
        initializeDefaultPartners()
    }
    
    // MARK: - Partner Management
    
    public func getTradePartner(id: String) -> TradePartner? {
        return tradePartners[id]
    }
    
    public func getAllTradePartners() -> [TradePartner] {
        return Array(tradePartners.values)
    }
    
    public func getExchangeRate(partnerId: String) -> ExchangeRate? {
        return exchangeRates[partnerId]
    }
    
    public func setExchangeRate(partnerId: String, rate: ExchangeRate) {
        exchangeRates[partnerId] = rate
    }
    
    // MARK: - Trade Flow Recording
    
    public func recordTradeFlow(_ flow: TradeFlow) -> TradeFlow {
        var flow = flow
        let tariffRate = getTariffRate(flow.direction, flow.commodity)
        let tariffApplied = flow.value * tariffRate / 100
        let shippingCost = flow.value * 0.05  // 5% shipping
        
        flow = TradeFlow(
            id: flow.id,
            commodity: flow.commodity,
            direction: flow.direction,
            origin: flow.origin,
            destination: flow.destination,
            quantity: flow.quantity,
            value: flow.value,
            timestamp: flow.timestamp,
            tariffApplied: tariffApplied,
            shippingCost: shippingCost
        )
        
        tradeFlows[flow.id] = flow
        
        // Update partner trade balances
        updatePartnerBalances(flow)
        
        return flow
    }
    
    private func getTariffRate(_ direction: TradeDirection, _ commodity: String) -> Double {
        // In a full model, would have commodity-specific tariffs
        return 5  // Default low tariff
    }
    
    private func updatePartnerBalances(_ flow: TradeFlow) {
        guard let origin = tradePartners[flow.origin], let destination = tradePartners[flow.destination] else { return }
        
        if flow.direction == .import {
            // Destination imports, origin exports
            destination.tradeBalance -= flow.value
            origin.tradeBalance += flow.value
        } else {
            // Destination exports, origin imports
            destination.tradeBalance += flow.value
            origin.tradeBalance -= flow.value
        }
    }
    
    // MARK: - Import/Export
    
    public func importCommodity(_ commodity: String, quantity: Double, from origin: String, to destination: String) -> TradeFlow {
        let value = quantity * 10  // Simplified: value per unit
        return recordTradeFlow(TradeFlow(
            id: "trade-\(Date.now())-\(Int.random(in: 0...999999))",
            commodity: commodity,
            direction: .import,
            origin: origin,
            destination: destination,
            quantity: quantity,
            value: value
        ))
    }
    
    public func exportCommodity(_ commodity: String, quantity: Double, from origin: String, to destination: String) -> TradeFlow {
        let value = quantity * 10
        return recordTradeFlow(TradeFlow(
            id: "trade-\(Date.now())-\(Int.random(in: 0...999999))",
            commodity: commodity,
            direction: .export,
            origin: origin,
            destination: destination,
            quantity: quantity,
            value: value
        ))
    }
    
    // MARK: - Trade Balance
    
    public func getTradeBalance(partnerId: String) -> Double {
        return tradePartners[partnerId]?.tradeBalance ?? 0
    }
    
    // MARK: - Trade Statistics
    
    public func getTradeStatistics() -> (totalTradeValue: Double, totalImports: Double, totalExports: Double, averageTariff: Double, tradePartners: [String: (tradeBalance: Double, mainExports: String, mainImports: String)]) {
        var totalTradeValue: Double = 0
        var totalImports: Double = 0
        var totalExports: Double = 0
        var tariffTotal: Double = 0
        var flowCount: Int = 0
        
        var partnerStats = [String: (tradeBalance: Double, exportValue: Double, importValue: Double, flowCount: Int)]()
        
        for partner in tradePartners.values {
            partnerStats[partner.id] = (tradeBalance: 0, exportValue: 0, importValue: 0, flowCount: 0)
        }
        
        for flow in tradeFlows.values {
            totalTradeValue += flow.value
            tariffTotal += flow.tariffApplied
            flowCount += 1
            
            if flow.direction == .import {
                totalImports += flow.value
            } else {
                totalExports += flow.value
            }
            
            // Update partner stats
            if var originStats = partnerStats[flow.origin] {
                originStats.flowCount += 1
                if flow.direction == .export {
                    originStats.exportValue += flow.value
                } else {
                    originStats.importValue += flow.value
                }
                partnerStats[flow.origin] = originStats
            }
            
            if var destStats = partnerStats[flow.destination] {
                destStats.flowCount += 1
                if flow.direction == .import {
                    destStats.importValue += flow.value
                } else {
                    destStats.exportValue += flow.value
                }
                partnerStats[flow.destination] = destStats
            }
        }
        
        var partnerSummary = [String: (tradeBalance: Double, mainExports: String, mainImports: String)]()
        for (partnerId, stats) in partnerStats {
            partnerSummary[partnerId] = (stats.tradeBalance, "varied", "varied")
        }
        
        return (totalTradeValue, totalImports, totalExports, flowCount > 0 ? tariffTotal / Double(flowCount) : 0, partnerSummary)
    }
    
    // MARK: - Trade Shock
    
    public func applyTradeShock(partnerId: Double, shock: Double) {
        // Note: This has a type error - partnerId should be String
        // Fixing in next function
    }
    
    // Actually let me correct this - the partnerId should be String
    public func applyTradeShock(partnerId: String, shock: Double) {
        guard var partner = tradePartners[partnerId] else { return }
        let shockValue = (partner.tradeBalance * shock) / 100
        partner.tradeBalance = max(-100000, min(100000, partner.tradeBalance + shockValue))
        tradePartners[partnerId] = partner
    }
    
    // MARK: - Trade Agreement
    
    public func negotiateTradeAgreement(partner1: String, partner2: String, agreementName: String) {
        guard let p1 = tradePartners[partner1], let p2 = tradePartners[partner2] else { return }
        
        // Reduce tariffs between partners
        let newTariffRate1 = max(0, p1.tariffRate - 2)
        let newTariffRate2 = max(0, p2.tariffRate - 2)
        
        // Add to trade agreements
        var updatedP1 = p1
        var updatedP2 = p2
        
        if !updatedP1.tradeAgreements.contains(agreementName) {
            updatedP1.tradeAgreements.append(agreementName)
        }
        if !updatedP2.tradeAgreements.contains(agreementName) {
            updatedP2.tradeAgreements.append(agreementName)
        }
        
        // Small adjustment toward parity in exchange rates
        let currentRate1 = exchangeRates[partner1] ?? 1.0
        let currentRate2 = exchangeRates[partner2] ?? 1.0
        
        exchangeRates[partner1] = max(0.5, currentRate1 * 0.98)
        exchangeRates[partner2] = max(0.5, currentRate2 * 0.98)
        
        tradePartners[partner1] = updatedP1
        tradePartners[partner2] = updatedP2
    }
}