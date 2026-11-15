//
//  EnvironmentalSustainability.swift
//  Agricultural Economic Simulation
//

import Foundation

// Environmental indicator enum
public enum EnvironmentalIndicator: String, CaseIterable {
    case airPollution = "air_pollution"
    case waterPollution = "water_pollution"
    case soilDegradation = "soil_degradation"
    case deforestation = "deforestation"
    case biodiversity = "biodiversity"
    case carbonEmissions = "carbon_emissions"
    case waterConsumption = "water_consumption"
    case wasteGeneration = "waste_generation"
    case habitatLoss = "habitat_loss"
}

// Environmental management action
public enum EnvironmentalAction: String {
    case recycling = "recycling"
    case wasteTreatment = "waste_treatment"
    case reforestation = "reforestation"
    case sustainableFarming = "sustainable_farming"
    case renewableEnergy = "renewable_energy"
    case waterConservation = "water_conservation"
    case soilRestoration = "soil_restoration"
    case emissionsReduction = "emissions_reduction"
}

// Environmental impact record
public struct EnvironmentalImpact {
    public let indicator: EnvironmentalIndicator
    public var currentValue: Double  // 0-100, higher = worse for pollution metrics
    public let targetValue: Double  // 0-100, desired level
    public var trend: String  // improving, worsening, stable
    public let lastMeasured: Date
    public let measurementInterval: TimeInterval
    
    public init(indicator: EnvironmentalIndicator, currentValue: Double, targetValue: Double, trend: String, lastMeasured: Date = Date(), measurementInterval: TimeInterval = 30 * 24 * 60 * 60 * 1000) {
        self.indicator = indicator
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.trend = trend
        self.lastMeasured = lastMeasured
        self.measurementInterval = measurementInterval
    }
}

// Sustainability policy
public struct SustainabilityPolicy {
    public let id: String
    public let name: String
    public let action: EnvironmentalAction
    public var intensity: Double  // 0-1, how strongly implemented
    public let cost: Double
    public let benefit: Double  // Long-term benefit
    public var implementationTime: Int  // periods until full effect
    public var currentProgress: Double  // 0-1
    public var effectiveness: Double  // 0-1, how well it works
    public var sideEffects: [(type: String, severity: Double)]
    
    public init(id: String, name: String, action: EnvironmentalAction, intensity: Double, cost: Double, benefit: Double, implementationTime: Int, currentProgress: Double = 0, effectiveness: Double = 0.7, sideEffects: [(type: String, severity: Double)] = []) {
        self.id = id
        self.name = name
        self.action = action
        self.intensity = intensity
        self.cost = cost
        self.benefit = benefit
        self.implementationTime = implementationTime
        self.currentProgress = currentProgress
        self.effectiveness = effectiveness
        self.sideEffects = sideEffects
    }
}

// Main environmental sustainability class
public class EnvironmentalSustainability {
    private var impacts: [EnvironmentalIndicator: EnvironmentalImpact] = [:]
    private var sustainabilityPolicies: [String: SustainabilityPolicy] = [:]
    private var indicatorTargets: [EnvironmentalIndicator: Double] = [
        .airPollution: 20, .waterPollution: 15, .soilDegradation: 10, .deforestation: 5,
        .biodiversity: 80, .carbonEmissions: 30, .waterConsumption: 60, .wasteGeneration: 25, .habitatLoss: 10
    ]
    
    public init() {
        // Initialize environmental impacts at starting levels
        for indicator in EnvironmentalIndicator.allCases {
            impacts[indicator] = EnvironmentalImpact(
                indicator: indicator,
                currentValue: startingValue(indicator),
                targetValue: targetValue(indicator),
                trend: "stable"
            )
        }
        
        createDefaultPolicies()
    }
    
    // MARK: - Starting/Target Values
    
    private func startingValue(_ indicator: EnvironmentalIndicator) -> Double {
        let starters: [EnvironmentalIndicator: Double] = [
            .airPollution: 30, .waterPollution: 20, .soilDegradation: 15, .deforestation: 10,
            .biodiversity: 70, .carbonEmissions: 40, .waterConsumption: 50, .wasteGeneration: 20, .habitatLoss: 15
        ]
        return starters[indicator] ?? 30
    }
    
    private func targetValue(_ indicator: EnvironmentalIndicator) -> Double {
        let targets: [EnvironmentalIndicator: Double] = [
            .airPollution: 10, .waterPollution: 5, .soilDegradation: 2, .deforestation: 1,
            .biodiversity: 90, .carbonEmissions: 10, .waterConsumption: 30, .wasteGeneration: 10, .habitatLoss: 2
        ]
        return targets[indicator] ?? 50
    }
    
    // MARK: - Default Policies
    
    private func createDefaultPolicies() {
        let defaultPolicies: [SustainabilityPolicy] = [
            SustainabilityPolicy(id: "policy-recycling", name: "Recycling Program", action: .recycling, intensity: 0.3, cost: 500, benefit: 200, implementationTime: 10),
            SustainabilityPolicy(id: "policy-reforestation", name: "Reforestation Initiative", action: .reforestation, intensity: 0.2, cost: 2000, benefit: 500, implementationTime: 30)
        ]
        
        for policy in defaultPolicies {
            sustainabilityPolicies[policy.id] = policy
        }
    }
    
    // MARK: - Period Advance
    
    public mutating func advancePeriod(deltaDays: Double, economicActivity: (productionLevel: Double, consumptionLevel: Double, resourceUse: [EnvironmentalIndicator: Double])) {
        let days = deltaDays / 30  // Monthly periods
        
        updateImpacts(days, economicActivity: economicActivity)
        updatePolicies(days)
        checkThresholds()
    }
    
    private mutating func updateImpacts(_ days: Double, economicActivity: (productionLevel: Double, consumptionLevel: Double, resourceUse: [EnvironmentalIndicator: Double])) {
        let productionFactor = economicActivity.productionLevel / 100
        let consumptionFactor = economicActivity.consumptionLevel / 100
        
        for indicator in EnvironmentalIndicator.allCases {
            guard var impact = impacts[indicator] else { continue }
            
            let resourceUse = economicActivity.resourceUse[indicator] ?? 0
            
            var changeRate: Double = 0
            
            switch indicator {
            case .airPollution:
                changeRate = (productionFactor + consumptionFactor) * 0.1 * days
            case .waterPollution:
                changeRate = (productionFactor + consumptionFactor + resourceUse * 0.5) * 0.08 * days
            case .soilDegradation:
                let farmingImpact = productionFactor * 0.15
                let fertilityRecovery = resourceUse * 0.05
                changeRate = (farmingImpact - fertilityRecovery) * days
            case .deforestation:
                changeRate = (productionFactor * 0.1 + consumptionFactor * 0.08) * days
            case .biodiversity:
                changeRate = -(productionFactor * 0.05 + consumptionFactor * 0.03) * days
            case .carbonEmissions:
                changeRate = (productionFactor + consumptionFactor * 0.5) * 0.12 * days
            case .waterConsumption:
                changeRate = (resourceUse ?? consumptionFactor) * 0.2 * days
            case .wasteGeneration:
                changeRate = consumptionFactor * 0.1 * days
            case .habitatLoss:
                changeRate = (productionFactor * 0.08) * days
            }
            
            let maxChange = 5
            let clampedChange = max(-maxChange, min(maxChange, changeRate))
            
            let newValue = max(0, min(100, impact.currentValue + clampedChange))
            
            // Update trend based on target
            let movingTowardsTarget = (newValue < impact.targetValue) == (impact.currentValue < impact.targetValue)
            impact.trend = movingTowardsTarget ? "improving" : "worsening"
            
            impact.currentValue = newValue
            impacts[indicator] = impact
        }
    }
    
    private mutating func updatePolicies(_ days: Double) {
        for (policyId, policy) in sustainabilityPolicies {
            policy.currentProgress = min(1, policy.currentProgress + 0.02)
            
            if policy.currentProgress >= 1 && policy.implementationTime > 0 {
                policy.implementationTime -= 1
                if policy.implementationTime <= 0 {
                    // Policy fully implemented
                }
            }
        }
    }
    
    private mutating func checkThresholds() {
        for (indicator, impact) in impacts {
            let target = indicatorTargets[indicator] ?? 50
            let critical = target * 2
            
            if impact.currentValue >= critical {
                impact.trend = "worsening"
            }
        }
    }
    
    // MARK: - Policy Implementation
    
    public mutating func implementPolicy(_ policyId: String, intensity: Double) -> Bool {
        guard var policy = sustainabilityPolicies[policyId] else { return false }
        
        policy.intensity = min(1, policy.intensity + intensity * 0.1)
        policy.cost = policy.cost * (1 + intensity * 0.5)
        policy.implementationTime = max(1, 20 - Int(intensity * 15))
        policy.currentProgress = 0
        
        sustainabilityPolicies[policyId] = policy
        return true
    }
    
    public mutating func applyAction(_ action: EnvironmentalAction, intensity: Double, area: Double) {
        guard var policy = sustainabilityPolicies.values.first(where: { $0.action == action }) else {
            // Create new policy
            let newPolicy = SustainabilityPolicy(
                id: "policy-\(action.rawValue)-\(Date.timeIntervalSince1970)",
                name: "\(action.rawValue.replacingOccurrences(of: "_", with: " ")) Initiative",
                action: action,
                intensity: 0,
                cost: 0, benefit: 0, implementationTime: 10,
                currentProgress: 0, effectiveness: 0.5, sideEffects: []
            )
            sustainabilityPolicies[newPolicy.id] = newPolicy
            // Would need to reference this new policy
            return
        }
        
        policy.intensity = min(1, policy.intensity + intensity * 0.1)
        policy.cost += intensity * 100
        policy.currentProgress = 0
        policy.implementationTime = 10
        
        sustainabilityPolicies[policy.id] = policy
    }
    
    // MARK: - Getters
    
    public func getEnvironmentalImpact(_ indicator: EnvironmentalIndicator) -> EnvironmentalImpact? {
        return impacts[indicator]
    }
    
    public func getAllImpacts() -> [EnvironmentalIndicator: EnvironmentalImpact] {
        return impacts
    }
    
    public func getSustainabilityPolicies() -> [String: SustainabilityPolicy] {
        return sustainabilityPolicies
    }
    
    public func getIndicatorTargets() -> [EnvironmentalIndicator: Double] {
        return indicatorTargets
    }
    
    public func getSustainabilitySummary() -> (totalIndicators: Int, improving: Int, worsening: Int, stable: Int, critical: Int, averageCurrentValue: Double, averageTargetValue: Double, policyCount: Int, totalPolicyCost: Double) {
        var improving = 0, worsening = 0, stable = 0, critical = 0
        var totalCurrent: Double = 0, totalTarget: Double = 0
        
        for impact in impacts.values {
            totalCurrent += impact.currentValue
            totalTarget += indicatorTargets[impact.indicator] ?? 50
            
            switch impact.trend {
            case "improving": improving += 1
            case "worsening": worsening += 1
            default: stable += 1
            }
            
            if impact.currentValue >= (indicatorTargets[impact.indicator] ?? 50) * 2 {
                critical += 1
            }
        }
        
        let avgCurrent = impacts.isEmpty ? 0 : totalCurrent / Double(impacts.count)
        let avgTarget = impacts.isEmpty ? 50 : totalTarget / Double(impacts.count)
        
        var totalPolicyCost: Double = 0
        for policy in sustainabilityPolicies.values {
            totalPolicyCost += policy.cost
        }
        
        return (impacts.count, improving, worsening, stable, critical, avgCurrent, avgTarget, sustainabilityPolicies.count, totalPolicyCost)
    }
}