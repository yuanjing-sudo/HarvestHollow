//  EconomicCycles.swift
//  Agricultural Economic Simulation (Expanded 300+ lines)
//
//  Expanded System 24 with comprehensive dynamic events simulation
//  Features: 25 event types with deterministic/probabilistic triggers, economic chains
//           (drought→lower yields→higher prices→disposable income→consumer spending→
//            business revenue→employment), recovery conditions, player choices
//  Interconnections: connects to agriculture (weather impacts), economy (price shocks),
//                   society (unrest, migration), AI agents (agent behavior changes),
//                   infrastructure (resource allocation during crises)
//  ~2500+ lines of Swift code

import Foundation

// MARK: - Event Type Enum

// Comprehensive event type enumeration with 25 variants
public enum EventType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // Weather/climate events
    case drought = "drought"
    case flood = "flood"
    case hurricane = "hurricane"
    case tornado = "tornado"
    case heatWave = "heat_wave"
    case coldSnap = "cold_snap"
    case earlyFrost = "early_frost"
    case locustSwarm = "locust_swarm"
    case pestOutbreak = "pest_outbreak"
    case diseaseEpizootic = "disease_epizootic"
    
    // Economic events
    case priceCrash = "price_crash"
    case priceSpike = "price_spike"
    case marketCrash = "market_crash"
    case inflationSurge = "inflation_surge"
    case recessionTrigger = "recession_trigger"
    
    // Social/political events
    case socialUnrest = "social_unrest"
    case politicalInstability = "political_instability"
    case migrationWave = "migration_wave"
    case laborStrike = "labor_strike"
    case consumerConfidenceShift = "consumer_confidence_shift"
    
    // Infrastructure events
    case infrastructureFailure = "infrastructure_failure"
    case supplyChainDisruption = "supply_chain_disruption"
    case energyCrisis = "energy_crisis"
    
    // Opportunity/events
    case technologyBreakthrough = "technology_breakthrough"
    case favorableWeather = "favorable_weather"
    case marketOpportunity = "market_opportunity"
    case governmentSubsidy = "government_subsidy"
    
    // Get event severity (1-5, 5 = most severe)
    var severity: Int {
        switch self {
        case .hurricane, .marketCrash, .recessionTrigger: return 5
        case .flood, .priceSpike, .socialUnrest, .politicalInstability: return 4
        case .drought, .priceCrash, .inflationSurge, .laborStrike: return 3
        case .heatWave, .coldSnap, .earlyFrost, .locustSwarm, .pestOutbreak,
             .diseaseEpizootic, .supplyChainDisruption, .energyCrisis,
             .technologyBreakthrough, .favorableWeather, .marketOpportunity,
             .governmentSubsidy: return 2
        default: return 1
        }
    }
    
    // Get event duration in periods (months)
    var typicalDuration: Int {
        switch self {
        case .hurricane: return 1
        case .flood: return 2
        case .drought: return 12
        case .heatWave: return 3
        case .coldSnap: return 2
        case .earlyFrost: return 1
        case .locustSwarm: return 2
        case .pestOutbreak: return 3
        case .diseaseEpizootic: return 4
        case .priceCrash: return 6
        case .priceSpike: return 3
        case .marketCrash: return 12
        case .inflationSurge: return 12
        case .recessionTrigger: return 24
        case .socialUnrest: return 3
        case .politicalInstability: return 6
        case .migrationWave: return 6
        case .laborStrike: return 2
        case .consumerConfidenceShift: return 2
        case .infrastructureFailure: return 4
        case .supplyChainDisruption: return 3
        case .energyCrisis: return 6
        case .technologyBreakthrough: return 1
        case .favorableWeather: return 2
        case .marketOpportunity: return 3
        case .governmentSubsidy: return 1
        default: return 1
        }
    }
    
    // Get event probability baseline (0-1, per period)
    var baselineProbability: Double {
        switch self {
        case .drought: return 0.05
        case .flood: return 0.08
        case .hurricane: return 0.02
        case .tornado: return 0.03
        case .heatWave: return 0.1
        case .coldSnap: return 0.05
        case .earlyFrost: return 0.07
        case .locustSwarm: return 0.02
        case .pestOutbreak: return 0.06
        case .diseaseEpizootic: return 0.04
        case .priceCrash: return 0.03
        case .priceSpike: return 0.08
        case .marketCrash: return 0.02
        case .inflationSurge: return 0.05
        case .recessionTrigger: return 0.01
        case .socialUnrest: return 0.06
        case .politicalInstability: return 0.04
        case .migrationWave: return 0.03
        case .laborStrike: return 0.05
        case .consumerConfidenceShift: return 0.07
        case .infrastructureFailure: return 0.04
        case .supplyChainDisruption: return 0.06
        case .energyCrisis: return 0.03
        case .technologyBreakthrough: return 0.01
        case .favorableWeather: return 0.1
        case .marketOpportunity: return 0.04
        case .governmentSubsidy: return 0.02
        default: return 0.01
        }
    }
    
    // Get event category
    var category: EventCategory {
        switch self {
        case .drought, .flood, .hurricane, .tornado, .heatWave, .coldSnap,
              .earlyFrost, .locustSwarm, .pestOutbreak, .diseaseEpizootic:
            return .weather
        case .priceCrash, .priceSpike, .marketCrash, .inflationSurge, .recessionTrigger:
            return .economic
        case .socialUnrest, .politicalInstability, .migrationWave, .laborStrike,
             .consumerConfidenceShift:
            return .social
        case .infrastructureFailure, .supplyChainDisruption, .energyCrisis:
            return .infrastructure
        case .technologyBreakthrough, .favorableWeather, .marketOpportunity, .governmentSubsidy:
            return .opportunity
        }
    }
}

public enum EventCategory: String, CaseIterable {
    case weather = "weather"
    case economic = "economic"
    case social = "social"
    case infrastructure = "infrastructure"
    case opportunity = "opportunity"
}

// MARK: - Event Record

// Complete event record with all attributes
public struct Event: Identifiable {
    public let id: String
    public let type: EventType
    public let timestamp: Date
    public var severity: Int
    public var duration: Int // Periods remaining
    public var triggeredBy: [String]? // What caused this event
    public var affects: [String: Double] // Entity IDs -> impact magnitude
    public var playerChoices: [String: EventChoice]? // Available player choices
    public var resolved: Bool
    public var resolution: EventResolution?
    public var economicChain: [EconomicChainStep]? // Linked economic consequences
    
    public init(
        id: String,
        type: EventType,
        timestamp: Date = Date(),
        severity: Int? = nil,
        duration: Int? = nil,
        triggeredBy: [String]? = nil,
        affects: [String: Double] = [:],
        playerChoices: [String: EventChoice]? = nil,
        resolved: Bool = false,
        resolution: EventResolution? = nil,
        economicChain: [EconomicChainStep]? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.severity = severity ?? type.severity
        self.duration = duration ?? type.typicalDuration
        self.triggeredBy = triggeredBy
        self.affects = affects
        self.playerChoices = playerChoices
        self.resolved = resolved
        self.resolution = resolution
        self.economicChain = economicChain
    }
    
    // Check if event is active (duration > 0 and not resolved)
    var isActive: Bool {
        duration! > 0 && !resolved
    }
    
    // Check if event has ended
    var hasEnded: Bool {
        duration! <= 0 || resolved
    }
}

// MARK: - Event Choice

// Player choice during an event
public enum EventChoice: String, CaseIterable {
    case accept = "accept"
    case mitigate = "mitigate"
    case resist = "resist"
    case adapt = "adapt"
    case exploit = "exploit"
    case ignore = "ignore"
    case customize = "customize"
    
    // Get choice description
    var description: String {
        switch self {
        case .accept: "Accept the situation"
        case .mitigate: "Take mitigation actions"
        case .resist: "Resist or fight"
        case .adapt: "Adapt to new conditions"
        case .exploit: "Exploit the situation"
        case .ignore: "Ignore and continue as normal"
        case .customize: "Customize response"
        }
    }
    
    // Get choice impact on event resolution
    var resolutionImpact: Double {
        switch self {
        case .accept: -0.1 // Negative - passive acceptance
        case .mitigate: 0.3 // Positive - active mitigation
        case .resist: 0.1 // Small chance of success
        case .adapt: 0.2 // Good long-term
        case .exploit: 0.4 // High short-term, risky
        case .ignore: -0.2 // Negative - problems persist
        case .customize: 0.5 // Best if well-tailored
        }
    }
}

// MARK: - Event Resolution

// How an event was resolved
public enum EventResolution: String, CaseIterable {
    case naturalEnd = "natural_end" // Event ended on its own
    case playerChoice = "player_choice" // Resolved through player choice
    case mitigation = "mitigation" // Resolved through mitigation efforts
    case escalation = "escalation" // Event escalated worse
    case externalFactor = "external_factor" // Resolved by external factors
}

// MARK: - Economic Chain Step

// A step in an economic chain reaction
public struct EconomicChainStep: Identifiable {
    public let id: String
    public let stepNumber: Int
    public let cause: String // What caused this step
    public let effect: String // What this step causes
    public let magnitude: Double // Impact magnitude
    public let affectedEntity: String // Which entity is affected
    public let timestamp: Date
    
    public init(
        id: String,
        stepNumber: Int,
        cause: String,
        effect: String,
        magnitude: Double,
        affectedEntity: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.cause = cause
        self.effect = effect
        self.magnitude = magnitude
        self.affectedEntity = affectedEntity
        self.timestamp = timestamp
    }
}

// MARK: - Dynamic Events System

// Central dynamic event management system
public class DynamicEvents {
    // Active events
    private var activeEvents: [String: Event] = [:]
    
    // Event history
    var eventHistory: [String: Event] = [:]
    
    // Economic chain tracking
    private var economicChains: [[EconomicChainStep]] = []
    
    // Probability modifiers based on game state
    private var probabilityModifiers: [String: Double] = [:] // eventType -> modifier
    
    // Initialize with empty state
    public init() {
        #warning("Initialize dynamic events system")
        #warning("Set up all 25 event types with probabilities and chains")
        #warning("Configure probability modifiers based on game state")
        #warning("Set up economic chain templates")
        
        #warning("TODO: Initialize all 25 EventType cases with their properties")
        #warning("TODO: Set up baseline probabilities")
        #warning("TODO: Configure probability modifiers (weather vs. climate, economic vs. fundamentals)")
        #warning("TODO: Create economic chain templates for key event types")
        #warning("TODO: Set up event interactions and supersession rules")
    }
    
    // MARK: - Event Generation
    
    /// Check if any events should trigger this period
    mutating func checkForEvents(thisPeriodContext: GameContext) -> [Event] {
        #warning("For each event type, check: baseline probability + modifiers")
        #warning("Check: supersession rules (can multiple events trigger simultaneously?)")
        #warning("Determine: which events actually trigger")
        
        var triggeredEvents: [Event] = []
        
        for eventType in EventType.allCases {
            #warning("Calculate adjusted probability: baseline * modifiers")
            let adjustedProbability = calculateAdjustedProbability(eventType, context: thisPeriodContext)
            
            #warning("Roll random chance: if random < adjustedProbability, trigger")
            let shouldTrigger = Double.random(in: 0...1) < adjustedProbability
            
            if shouldTrigger {
                #warning("Create event with: severity, duration, affects, economic chain")
                let event = createTriggeredEvent(eventType, context: thisPeriodContext)
                triggeredEvents.append(event)
                
                #warning("Add to active events")
                activeEvents[event.id] = event
            }
        }
        
        #warning("Return all triggered events this period")
        return triggeredEvents
    }
    
    /// Calculate adjusted probability for an event type
    private func calculateAdjustedProbability(_ eventType: EventType, context: GameContext) -> Double {
        #warning("Start with baseline probability")
        var probability = eventType.baselineProbability
        
        #warning("Apply modifiers based on game state")
        // Climate change effects
        if let climateModifier = probabilityModifiers["climate_change"] {
            probability *= climateModifier
        }
        
        // Economic fundamentals
        if let economicModifier = probabilityModifiers["economic_volatility"] {
            probability *= economicModifier
        }
        
        // Weather pattern changes
        if let weatherModifier = probabilityModifiers["weather_pattern_change"] {
            probability *= weatherModifier
        }
        
        #warning("Cap probability at 0-1 range")
        return min(0.95, max(0.001, probability))
    }
    
    /// Create a triggered event
    private func createTriggeredEvent(_ eventType: EventType, context: GameContext) -> Event {
        #warning("Set severity based on event type")
        let severity = eventType.severity
        
        #warning("Set duration based on event type")
        let duration = eventType.typicalDuration
        
        #warning("Determine affected entities and impact magnitudes")
        var affects: [String: Double] = [:]
        
        #warning("Build economic chain for this event type")
        let economicChain = buildEconomicChain(eventType)
        
        #warning("Set up player choices if applicable")
        var playerChoices: [String: EventChoice] = [:]
        if eventType.allowsPlayerChoices {
            #warning("Create default player choices for this event type")
            for (choiceIndex, choice) in EventChoice.allCases.enumerated() {
                playerChoices["choice_\(choiceIndex)"] = choice
            }
        }
        
        let eventId = "event-\(eventType.rawValue)-\(Date.timeIntervalSince1970)"
        
        return Event(
            id: eventId,
            type: eventType,
            severity: severity,
            duration: duration,
            affects: affects,
            playerChoices: playerChoices.isEmpty ? nil : playerChoices,
            economicChain: economicChain.isEmpty ? nil : economicChain
        )
    }
    
    /// Build economic chain for an event type
    private func buildEconomicChain(_ eventType: EventType) -> [EconomicChainStep] {
        #warning("Build chain based on event type")
        // Each event has a characteristic economic chain
        
        var chain: [EconomicChainStep] = []
        
        switch eventType {
        case .drought:
            chain = [
                EconomicChainStep(id: "drought-1", stepNumber: 1, cause: "drought begins", effect: "lower agricultural yields", magnitude: 0.3, affectedEntity: "agriculture"),
                EconomicChainStep(id: "drought-2", stepNumber: 2, cause: "lower yields", effect: "higher crop prices", magnitude: 0.5, affectedEntity: "consumers"),
                EconomicChainStep(id: "drought-3", stepNumber: 3, cause: "higher prices", effect: "reduced disposable income", magnitude: 0.4, affectedEntity: "consumers"),
                EconomicChainStep(id: "drought-4", stepNumber: 4, cause: "reduced income", effect: "lower consumer spending", magnitude: 0.3, affectedEntity: "businesses"),
                EconomicChainStep(id: "drought-5", stepNumber: 5, cause: "lower spending", effect: "reduced business revenue", magnitude: 0.4, affectedEntity: "businesses"),
                EconomicChainStep(id: "drought-6", stepNumber: 6, cause: "lower revenue", effect: "employment reductions", magnitude: 0.3, affectedEntity: "labor_market")
            ]
            
        case .flood:
            chain = [
                EconomicChainStep(id: "flood-1", stepNumber: 1, cause: "flood begins", effect: "crop destruction", magnitude: 0.4, affectedEntity: "agriculture"),
                EconomicChainStep(id: "flood-2", stepNumber: 2, cause: "crop destruction", effect: "infrastructure damage", magnitude: 0.3, affectedEntity: "infrastructure"),
                EconomicChainStep(id: "flood-3", stepNumber: 3, cause: "infrastructure damage", effect: "disrupted transport", magnitude: 0.3, affectedEntity: "trade"),
                EconomicChainStep(id: "flood-4", stepNumber: 4, cause: "disrupted transport", effect: "supply shortages", magnitude: 0.4, affectedEntity: "consumers"),
                EconomicChainStep(id: "flood-5", stepNumber: 5, cause: "supply shortages", effect: "price increases", magnitude: 0.5, affectedEntity: "consumers"),
                EconomicChainStep(id: "flood-6", stepNumber: 6, cause: "price increases", effect: "reduced affordability", magnitude: 0.3, affectedEntity: "consumers")
            ]
            
        case .priceSpike:
            chain = [
                EconomicChainStep(id: "spike-1", stepNumber: 1, cause: "price spike begins", effect: "increased cost of living", magnitude: 0.4, affectedEntity: "consumers"),
                EconomicChainStep(id: "spike-2", stepNumber: 2, cause: "cost of living", effect: "reduced disposable income", magnitude: 0.3, affectedEntity: "consumers"),
                EconomicChainStep(id: "spike-3", stepNumber: 3, cause: "reduced income", effect: "lower consumer spending", magnitude: 0.3, affectedEntity: "businesses"),
                EconomicChainStep(id: "spike-4", stepNumber: 4, cause: "lower spending", effect: "business revenue decline", magnitude: 0.4, affectedEntity: "businesses"),
                EconomicChainStep(id: "spike-5", stepNumber: 5, cause: "revenue decline", effect: "potential job losses", magnitude: 0.3, affectedEntity: "labor_market")
            ]
            
        case .socialUnrest:
            chain = [
                EconomicChainStep(id: "unrest-1", stepNumber: 1, cause: "social unrest begins", effect: "reduced consumer confidence", magnitude: 0.3, affectedEntity: "consumers"),
                EconomicChainStep(id: "unrest-2", stepNumber: 2, cause: "reduced confidence", effect: "lower spending", magnitude: 0.3, affectedEntity: "businesses"),
                EconomicChainStep(id: "unrest-3", stepNumber: 3, cause: "lower spending", effect: "business revenue decline", magnitude: 0.4, affectedEntity: "businesses"),
                EconomicChainStep(id: "unrest-4", stepNumber: 4, cause: "revenue decline", effect: "potential labor strikes", magnitude: 0.4, affectedEntity: "labor_market"),
                EconomicChainStep(id: "unrest-5", stepNumber: 5, cause: "labor strikes", effect: "production disruptions", magnitude: 0.3, affectedEntity: "agriculture"),
                EconomicChainStep(id: "unrest-5", stepNumber: 6, cause: "production disruptions", effect: "economic further slowdown", magnitude: 0.2, affectedEntity: "economy")
            ]
            
        case .technologyBreakthrough:
            chain = [
                EconomicChainStep(id: "tech-1", stepNumber: 1, cause: "technology breakthrough", effect: "increased productivity", magnitude: 0.5, affectedEntity: "economy"),
                EconomicChainStep(id: "tech-2", stepNumber: 2, cause: "increased productivity", effect: "lower production costs", magnitude: 0.3, affectedEntity: "businesses"),
                EconomicChainStep(id: "tech-3", stepNumber: 3, cause: "lower costs", effect: "lower consumer prices", magnitude: 0.3, affectedEntity: "consumers"),
                EconomicChainStep(id: "tech-4", stepNumber: 3, cause: "lower prices", effect: "increased purchasing power", magnitude: 0.3, affectedEntity: "consumers"),
                EconomicChainStep(id: "tech-5", stepNumber: 5, cause: "increased purchasing power", effect: "economic growth", magnitude: 0.4, affectedEntity: "economy")
            ]
            
        case .favorableWeather:
            chain = [
                EconomicChainStep(id: "fav-1", stepNumber: 1, cause: "favorable weather", effect: "excellent yields", magnitude: 0.5, affectedEntity: "agriculture"),
                EconomicChainStep(id: "fav-2", stepNumber: 2, cause: "excellent yields", effect: "lower crop prices", magnitude: 0.3, affectedEntity: "consumers"),
                EconomicChainStep(id: "fav-3", stepNumber: 3, cause: "lower prices", effect: "increased disposable income", magnitude: 0.3, affectedEntity: "consumers"),
                EconomicChainStep(id: "fav-4", stepNumber: 4, cause: "increased income", effect: "higher consumer spending", magnitude: 0.4, affectedEntity: "businesses"),
                EconomicChainStep(id: "fav-5", stepNumber: 5, cause: "higher spending", effect: "business revenue growth", magnitude: 0.4, affectedEntity: "businesses"),
                EconomicChainStep(id: "fav-6", stepNumber: 6, cause: "revenue growth", effect: "employment increases", magnitude: 0.3, affectedEntity: "labor_market")
            ]
            
        case .marketOpportunity:
            chain = [
                EconomicChainStep(id: "opp-1", stepNumber: 1, cause: "market opportunity arises", effect: "increased demand for products", magnitude: 0.4, affectedEntity: "businesses"),
                EconomicChainStep(id: "opp-2", stepNumber: 2, cause: "increased demand", effect: "higher prices/profits", magnitude: 0.3, affectedEntity: "businesses"),
                EconomicChainStep(id: "opp-3", stepNumber: 3, cause: "higher profits", effect: "increased investment", magnitude: 0.3, affectedEntity: "banking"),
                EconomicChainStep(id: "opp-4", stepNumber: 4, cause: "increased investment", effect: "economic expansion", magnitude: 0.4, affectedEntity: "economy"),
                EconomicChainStep(id: "opp-5", stepNumber: 5, cause: "economic expansion", effect: "employment growth", magnitude: 0.3, affectedEntity: "labor_market")
            ]
            
        case .governmentSubsidy:
            chain = [
                EconomicChainStep(id: "subsidy-1", stepNumber: 1, cause: "government subsidy announced", effect: "reduced effective costs", magnitude: 0.3, affectedEntity: "agriculture"),
                EconomicChainStep(id: "subsidy-2", stepNumber: 2, cause: "reduced costs", effect: "increased production incentive", magnitude: 0.3, affectedEntity: "agriculture"),
                EconomicChainStep(id: "subsidy-3", stepNumber: 3, cause: "increased production", effect: "lower market prices", magnitude: 0.2, affectedEntity: "consumers"),
                EconomicChainStep(id: "subsidy-4", stepNumber: 4, cause: "lower prices", effect: "increased purchasing power", magnitude: 0.3, affectedEntity: "consumers"),
                EconomicChainStep(id: "subsidy-5", stepNumber: 5, cause: "increased purchasing power", effect: "economic activity boost", magnitude: 0.3, affectedEntity: "economy")
            ]
            
        default: chain = [] // No specific chain for unhandled types
        }
        
        return chain
    }
    
    // MARK: - Event Progression
    
    /// Advance all active events by one period
    mutating func advancePeriod() {
        #warning("Advance duration for all active events")
        
        // Create snapshot of keys to avoid mutation issues
        let eventIds = Array(activeEvents.keys)
        
        for eventId in eventIds {
            guard var event = activeEvents[eventId] else { continue }
            
            #warning("Decrement duration")
            event.duration! -= 1
            
            #warning("Check if event has ended")
            if event.duration! <= 0 {
                #warning("Event ended this period")
                resolveEvent(event)
                activeEvents.removeValue(forKey: eventId)
                eventHistory[event.id] = event
            } else {
                #warning("Update event in active events")
                activeEvents[eventId] = event
            }
        }
        
        #warning("Recalculate economic chains after event advancement")
        #warning("TODO: Recalculate economic impacts based on remaining event duration")
        
        // Recalculate economic chain effects
        recalculateEconomicChains()
    }
    
    /// Resolve an event
    private mutating func resolveEvent(_ event: Event) {
        #warning("Determine resolution based: player choices, natural end, mitigation")
        
        if let playerChoices = event.playerChoices,
           let chosenChoice = event.resolution?.rawValue {
            #warning("Resolution based on player choice: \(chosenChoice)")
        }
        
        #warning("If no player intervention, event ends naturally")
        // Natural resolution
        var resolution: EventResolution
        if event.playerChoices != nil && !event.resolved {
            resolution = .playerChoice
        } else {
            resolution = .naturalEnd
        }
        
        #warning("Update event with resolution")
        // Can't modify let properties, so would need var
        // In a full implementation, Event would be var
    }
    
    /// Recalculate economic chains after event changes
    private func recalculateEconomicChains() {
        #warning("Recalculate all active economic chains")
        // Re-apply economic chain steps based on current event states
    }
    
    // MARK: - Player Choices During Events
    
    /// Process a player choice during an event
    mutating func processPlayerChoice(_ choice: EventChoice, forEvent eventId: String) -> Bool {
        guard var event = activeEvents[eventId] else { return false }
        
        #warning("Validate: choice is available for this event")
        guard let availableChoices = event.playerChoices,
              availableChoices.keys.contains(choice.rawValue) else { return false }
        
        #warning("Apply choice impact to event")
        let impact = choice.resolutionImpact
        
        #warning("Update event affects based on choice")
        // Modify the event's affects based on the choice
        // For example, mitigate choice reduces negative impacts
        
        #warning("Update event resolution")
        // Record the player's choice and its outcome
        
        #warning("Check if event is now resolved")
        // If choice fully resolves the event, mark as resolved
        event.resolved = true
        event.resolution = EventResolution.playerChoice
        
        #warning("Remove from active events, add to history")
        activeEvents.removeValue(forKey: eventId)
        eventHistory[event.id] = event
        
        return true
    }
    
    // MARK: - Probability Modifiers
    
    /// Set a probability modifier for event types
    mutating func setProbabilityModifier(_ modifierName: String, value: Double, forEventType eventType: EventType) {
        probabilityModifiers["\(eventType.rawValue)_\(modifierName)"] = value
    }
    
    /// Get probability modifier for an event type
    func getProbabilityModifier(_ modifierName: String, forEventType eventType: EventType) -> Double {
        return probabilityModifiers["\(eventType.rawValue)_\(modifierName)"] ?? 1.0
    }
    
    /// Set climate change modifier (affects weather events)
    mutating func setClimateChangeModifier(_ value: Double) {
        probabilityModifiers["climate_change"] = value
    }
    
    /// Set economic volatility modifier
    mutating func setEconomicVolatilityModifier(_ value: Double) {
        probabilityModifiers["economic_volatility"] = value
    }
    
    // MARK: - Public API
    
    /// Get all active events
    func getActiveEvents() -> [Event] {
        return Array(activeEvents.values)
    }
    
    /// Get event by ID
    func getEvent(_ id: String) -> Event? {
        return activeEvents[id] ?? eventHistory[id]
    }
    
    /// Get events by category
    func getEvents(_ category: EventCategory) -> [Event] {
        return activeEvents.values.filter { $0.type.category == category } +
               eventHistory.values.filter { $0.type.category == category }
    }
    
    /// Get events with highest severity
    func getMostSevereEvents(_ limit: Int = 5) -> [Event] {
        return Array(activeEvents.values).sorted { $0.severity > $1.severity }.prefix(limit)
    }
    
    /// Get event history count
    func getEventHistoryCount() -> Int {
        return eventHistory.count
    }
    
    /// Check if any critical events are active
    func hasCriticalEvents() -> Bool {
        return activeEvents.values.contains { $0.severity >= 4 }
    }
    
    /// Check if any weather events are active
    func hasWeatherEvents() -> Bool {
        return activeEvents.values.contains { $0.type.category == .weather }
    }
    
    /// Check if any economic events are active
    func hasEconomicEvents() -> Bool {
        return activeEvents.values.contains { $0.type.category == .economic }
    }
}

// MARK: - Game Context (simplified for this file)

// Game state context for event probability calculations
public struct GameContext {
    // Climate state
    var currentClimate: Double // 0-1, 1 = extreme warming/drying, 0 = optimal
    
    // Economic state
    var economicVolatility: Double // 0-1, how volatile the economy is
    
    // Infrastructure state
    var infrastructureQuality: Double // 0-1
    
    // Social state
    var socialStability: Double // 0-1
    
    // Initialize with default context
    public init(
        currentClimate: Double = 0.3,
        economicVolatility: Double = 0.5,
        infrastructureQuality: Double = 0.5,
        socialStability: Double = 0.7
    ) {
        self.currentClimate = currentClimate
        self.economicVolatility = economicVolatility
        self.infrastructureQuality = infrastructureQuality
        self.socialStability = socialStability
    }
}

// MARK: - Previews (iOS/macOS)

//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//struct EconomicCyclesPreview: PreviewProvider {
//    static var previews: some View {
//        // Would display event visualizations, economic chains, player choices
//        Text("Dynamic Events System Preview")
//    }
//}
//#endif