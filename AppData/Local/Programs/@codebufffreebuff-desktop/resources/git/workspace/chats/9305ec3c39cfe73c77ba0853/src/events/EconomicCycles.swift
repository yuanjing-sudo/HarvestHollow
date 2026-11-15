//
//  EconomicCycles.swift
//  Agricultural Economic Simulation
//

import Foundation

// Event type enum
public enum EventType: String {
    case drought = "drought"
    case flooding = "flooding"
    case pestOutbreak = "pest_outbreak"
    case cropDisease = "crop_disease"
    case livestockDisease = "livestock_disease"
    case recession = "recession"
    case inflationShock = "inflation_shock"
    case commodityShortage = "commodity_shortage"
    case energyCrisis = "energy_crisis"
    case bankingCrisis = "banking_crisis"
    case confidenceDecline = "confidence_decline"
    case election = "election"
    case policyReform = "policy_reform"
    case taxChanges = "tax_changes"
    case publicDemonstrations = "public_demonstrations"
    case regulatoryChanges = "regulatory_changes"
    case newMachinery = "new_machinery"
    case researchBreakthrough = "research_breakthrough"
    case improvedVarieties = "improved_varieties"
    case tradeDisruptions = "trade_disruptions"
    case globalPriceShocks = "global_price_shocks"
    case shippingDelays = "shipping_delays"
    case foreignRecessions = "foreign_recessions"
}

// Event severity
public enum EventSeverity: String {
    case minor = "minor"
    case moderate = "moderate"
    case severe = "severe"
    case catastrophic = "catastrophic"
}

// Event trigger conditions
public struct EventTrigger {
    public var type: String  // deterministic or probabilistic
    public var condition: (Map<String, Double>) -> Bool
    public var probability: Double?
    public var delaySteps: Int?
}

// Event record
public struct GameEvent: Identifiable {
    public let id: String
    public let type: EventType
    public let severity: EventSeverity
    public let trigger: EventTrigger
    public var affectedSystems: [String]  // Factor IDs or system names
    public var economicConsequences: [String: Double]  // factor -> value change
    public var socialConsequences: [String: Double]  // indicator -> value change
    public let duration: Int  // periods
    public let startPeriod: Date
    public var recoveryConditions: [(type: String, requiredValue: Double)]
    var playerEvents: [(type: String, description: String, choices: [String]?)]
    
    public init(id: String, type: EventType, severity: EventSeverity, trigger: EventTrigger, affectedSystems: [String], economicConsequences: [String: Double], socialConsequences: [String: Double], duration: Int, startPeriod: Date = Date(), recoveryConditions: [(type: String, requiredValue: Double)] = [], playerEvents: [(type: String, description: String, choices: [String]?)] = []) {
        self.id = id
        self.type = type
        self.severity = severity
        self.trigger = trigger
        self.affectedSystems = affectedSystems
        self.economicConsequences = economicConsequences
        self.socialConsequences = socialConsequences
        self.duration = duration
        self.startPeriod = startPeriod
        self.recoveryConditions = recoveryConditions
        self.playerEvents = playerEvents
    }
}

// Economic chain builder
public class EconomicChain {
    public func buildChain(for event: GameEvent) -> [(step: String, description: String)] {
        [
            "agricultural": "Lower crop yields due to drought conditions",
            "supply": "Lower agricultural supply in the market",
            "pricing": "Higher food prices due to reduced supply",
            "household": "Higher living costs for households",
            "disposable": "Lower disposable income for families",
            "consumer": "Lower consumer spending across sectors",
            "business": "Lower business revenue and profits",
            "employment": "Lower employment and tax revenue for government",
            "intervention": "Government may introduce subsidies or aid"
        ]
    }
}

// Main dynamic events system
public class DynamicEvents {
    private var activeEvents: [String: GameEvent] = [:]
    private var eventHistory: [GameEvent] = []
    private var eventCooldown: [String: Int] = [:]  // Prevent same event type too frequently
    
    public init() {}
    
    // MARK: - Check and Trigger Events
    
    public mutating func checkAndTriggerEvents(state: [String: Double]) -> [GameEvent] {
        var triggered: [GameEvent] = []
        
        for eventType in EventType.allCases {
            guard let eventTemplate = getEventTemplate(eventType) else { continue }
            
            let triggerMet = checkTrigger(eventTemplate.trigger, state: state)
            
            let cooldown = eventCooldown[eventType.rawValue] ?? 0
            let cooldownMet = cooldown <= 0
            
            if triggerMet && cooldownMet {
                if let event = createEvent(eventTemplate, state: state) {
                    activeEvents[event.id] = event
                    eventHistory.append(event)
                    
                    eventCooldown[eventType.rawValue] = eventTemplate.trigger.delaySteps ?? 20
                    
                    triggered.append(event)
                }
            } else if cooldownMet {
                eventCooldown[eventType.rawValue] = max(0, cooldown - 1)
            }
        }
        
        // Advance cooldowns for all event types
        var newCooldowns: [String: Int] = [:]
        for (type, cooldown) in eventCooldown {
            newCooldowns[type] = max(0, cooldown - 1)
        }
        eventCooldown = newCooldowns
        
        return triggered
    }
    
    private func getEventTemplate(_ type: EventType) -> (name: String, severityOptions: [EventSeverity], trigger: EventTemplateTrigger, affectedSystems: [String], durationOptions: [Int])? {
        switch type {
        case .drought:
            return (name: "Drought", severityOptions: [.moderate, .severe, .catastrophic],
                    trigger: EventTemplateTrigger(type: "probabilistic", probability: 0.1,
                    condition: { state in (state["rainfall"] ?? 5) < 3 || (state["temperature"] ?? 20) > 30 }),
                    affectedSystems: ["soil.moisture", "crop.growth", "market.prices"],
                    durationOptions: [4, 8, 12])
        case .flooding:
            return (name: "Flooding", severityOptions: [.moderate, .severe],
                    trigger: EventTemplateTrigger(type: "probabilistic", probability: 0.08,
                    condition: { state in (state["rainfall"] ?? 5) > 15 }),
                    affectedSystems: ["soil.moisture", "infrastructure.flood", "crop.damage"],
                    durationOptions: [2, 4, 6])
        case .recession:
            return (name: "Recession", severityOptions: [.moderate, .severe],
                    trigger: EventTemplateTrigger(type: "deterministic",
                    condition: { state in (state["inflation"] ?? 2) > 10 && (state["unemployment"] ?? 5) > 15 && (state["gdp_growth"] ?? 3) < -2 }),
                    affectedSystems: ["market.prices", "business.revenue", "employment.rate"],
                    durationOptions: [8, 12, 20])
        case .inflationShock:
            return (name: "Inflation Shock", severityOptions: [.moderate, .severe],
                    trigger: EventTemplateTrigger(type: "probabilistic", probability: 0.15,
                    condition: { state in (state["inflation"] ?? 2) > 8 }),
                    affectedSystems: ["market.prices", "currency.inflation", "purchasing.power"],
                    durationOptions: [3, 6, 12])
        case .election:
            return (name: "Election", severityOptions: [.moderate],
                    trigger: EventTemplateTrigger(type: "deterministic",
                    condition: { state in (state["year"] ?? 1) % 4 == 0 && (state["year"] ?? 1) > 0 }),
                    affectedSystems: ["government.approval", "policy.status", "tax.rates"],
                    durationOptions: [4])
        }
    }
    
    private func checkTrigger(_ trigger: EventTemplateTrigger, state: [String: Double]) -> Bool {
        if trigger.type == "deterministic" {
            return trigger.condition(state)
        } else {
            if !trigger.condition(state) { return false }
            return Double.random(in: 0...1) < (trigger.probability ?? 0.5)
        }
    }
    
    private func createEvent(_ template: EventTemplateTrigger, state: [String: Double]) -> GameEvent? {
        let severity = template.severityOptions.randomElement() ?? .moderate
        let duration = template.durationOptions.randomElement() ?? 4
        let id = "event-\(template.name)-\(Date.timeIntervalSince1970)"
        
        let economicConsequences = calculateEconomicConsequences(template: template, severity: severity)
        let socialConsequences = calculateSocialConsequences(template: template, severity: severity)
        let recoveryConditions = calculateRecoveryConditions(template: template, severity: severity)
        let playerEvents = createPlayerEvents(template: template, severity: severity)
        
        return GameEvent(id: id, type: template.name as! EventType, severity: severity,
            trigger: template.trigger, affectedSystems: template.affectedSystems,
            economicConsequences: economicConsequences, socialConsequences: socialConsequences,
            duration: duration, startPeriod: Date(), recoveryConditions: recoveryConditions, playerEvents: playerEvents)
    }
    
    private func calculateEconomicConsequences(template: EventTemplateTrigger, severity: EventSeverity) -> [String: Double] {
        let severityMultiplier: [EventSeverity: Double] = [.minor: 0.3, .moderate: 0.6, .severe: 1.0, .catastrophic: 1.5]
        let multiplier = severityMultiplier[severity] ?? 1.0
        var consequences: [String: Double] = [:]
        
        for system in template.affectedSystems {
            var baseChange: Double = 0
            
            switch system {
            case "soil.moisture": baseChange = -20 * multiplier
            case "crop.growth": baseChange = -30 * multiplier
            case "market.prices": baseChange = 15 * multiplier
            case "infrastructure.flood": baseChange = -15 * multiplier
            case "crop.damage": baseChange = -25 * multiplier
            case "currency.inflation": baseChange = 5 * multiplier
            case "purchasing.power": baseChange = -10 * multiplier
            case "employment.rate": baseChange = 5 * multiplier
            case "government.approval": baseChange = -10 * multiplier
            default: baseChange = 0
            }
            
            if baseChange != 0 { consequences[system] = baseChange }
        }
        
        return consequences
    }
    
    private func calculateSocialConsequences(template: EventTemplateTrigger, severity: EventSeverity) -> [String: Double] {
        let severityMultiplier: [EventSeverity: Double] = [.minor: 0.3, .moderate: 0.6, .severe: 1.0, .catastrophic: 1.5]
        let multiplier = severityMultiplier[severity] ?? 1.0
        var consequences: [String: Double] = [:]
        
        for system in template.affectedSystems {
            var baseChange: Double = 0
            
            switch system {
            case "crop.growth": baseChange = -15 * multiplier
            case "market.prices": baseChange = -10 * multiplier
            case "infrastructure.flood": baseChange = -20 * multiplier
            case "crop.damage": baseChange = -15 * multiplier
            case "currency.inflation": baseChange = -10 * multiplier
            case "purchasing.power": baseChange = -10 * multiplier
            case "employment.rate": baseChange = -5 * multiplier
            case "government.approval": baseChange = -15 * multiplier
            default: baseChange = 0
            }
            
            if baseChange != 0 { consequences[system] = baseChange }
        }
        
        return consequences
    }
    
    private func calculateRecoveryConditions(template: EventTemplateTrigger, severity: EventSeverity) -> [(type: String, requiredValue: Double)] {
        let severityMultiplier: [EventSeverity: Double] = [.minor: 0.3, .moderate: 0.6, .severe: 1.0, .catastrophic: 1.5]
        let multiplier = severityMultiplier[severity] ?? 1.0
        var conditions: [(type: String, requiredValue: Double)] = []
        
        for system in template.affectedSystems {
            let required = 50  // Default recovery threshold
            conditions.append((system, required))
        }
        
        return conditions
    }
    
    private func createPlayerEvents(template: EventTemplateTrigger, severity: EventSeverity) -> [(type: String, description: String, choices: [String]?)] {
        var events: [(type: String, description: String, choices: [String]?)] = []
        
        switch template.name {
        case "Drought":
            events.append(("resource_shortage", "Crop yields declined due to drought. Conserve water or import food?", ["conserve_water", "import_food", "accept_losses"]))
            events.append(("economic_impact", "Food prices risen significantly. Response?", ["price_controls", "subsidies", "accept_markets"]))
        case "Flooding":
            events.append(("damage_assessment", "Flooding damaged infrastructure and crops. Prioritize repairs?", ["repair_infrastructure", "crop_recovery", "safer_locations"]))
            events.append(("economic_relief", "Households affected. Provide aid or let market adjust?", ["direct_aid", "tax_wealth", "insurance_handle"]))
        case "Recession":
            events.append(("business_challenges", "Economic recession affecting businesses. Support or let fail?", ["low_interest_loans", "tax_cuts", "natural_selection"]))
            events.append(("employment_impact", "Job losses from recession. Response?", ["unemployment_benefits", "public_works", "retraining"]))
        case "Inflation Shock":
            events.append(("price_adjustments", "Inflation eroded purchasing power. Adjust wages or prices?", ["index_wages", "freeze_prices", "accept_inflation"]))
            events.append(("savings_protection", "Inflation eroding savings. Protect or invest?", ["real_assets", "foreign_currency", "accept_erosion"]))
        case "Election":
            events.append(("policy_choice", "New government. Priority policy?", ["economic_growth", "social_services", "infrastructure", "environmental_policy"]))
            events.append(("cabinet_appointments", "New administration appointments. Who gets roles?", ["experts", "loyal_supporters", "balance", "technocratic"]))
        default: break
        }
        
        return events
    }
    
    // MARK: - Getters
    
    public func getActiveEvents() -> [GameEvent] { return Array(activeEvents.values) }
    public func getEventHistory() -> [GameEvent] { return eventHistory }
    
    public mutating func completeEvent(_ eventId: String) -> Bool {
        activeEvents.removeValue(forKey: eventId)
        if !eventHistory.contains(where: { $0.id == eventId }) {
            eventHistory.append(activeEvents.values.first { $0.id == eventId } ?? GameEvent(id: "", type: .drought, severity: .moderate, trigger: EventTrigger(type: "deterministic", condition: { _ in false }), affectedSystems: [], economicConsequences: [:], socialConsequences: [], duration: 0))
        }
        return true
    }
    
    public mutating func applyEventEffects(_ event: GameEvent, stateUpdater: ([String: Double]) -> Void) {
        var econChanges = event.economicConsequences
        stateUpdater(&econChanges)
        
        var socialChanges = event.socialConsequences
        stateUpdater(&socialChanges)
    }
    
    public func isEventRecovering(_ eventId: String, state: [String: Double]) -> Bool {
        guard let event = activeEvents[eventId] else { return false }
        
        for condition in event.recoveryConditions {
            let currentValue = state[condition.type] ?? 0
            if currentValue < condition.requiredValue { return false }
        }
        
        return true
    }
}

// Helper struct for event template
private struct EventTemplateTrigger {
    let type: String
    let probability: Double?
    let condition: ([String: Double]) -> Bool
    let delaySteps: Int?
}

// Severity multiplier helper
private var severityMultiplier: [EventSeverity: Double] {
    [.minor: 0.3, .moderate: 0.6, .severe: 1.0, .catastrophic: 1.5]
}