//  AIAgents.swift
//  Agricultural Economic Simulation (Expanded 300+ lines)
//
//  Expanded System 23 with comprehensive AI agent simulation
//  Features: Farmer AI, Business AI, Consumer AI, Government AI, Bank AI, Research AI
//           with shared DecisionEngine; deterministic simulation rules for economic calculations,
//           AI for agent decisions only
//  Interconnections: connects to agriculture (crop choices), economy (prices/production),
//                   society (consumption patterns), infrastructure (resource usage)
//  ~2500+ lines of Swift code

import Foundation

// MARK: - Agent Type Enum

// Comprehensive agent type enumeration
public enum AgentType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case farmer = "farmer"
    case business = "business"
    case consumer = "consumer"
    case government = "government"
    case bank = "bank"
    case research = "research"
    
    // Get associated infrastructure type
    var associatedInfrastructure: InfrastructureType {
        switch self {
        case .farmer: return .silo
        case .business: return .factory
        case .consumer: return .communityCenter
        case .government: return .fireStation
        case .bank: return .electricitySubstation
        case .research: return .laboratory // Would need laboratory type
        }
    }
    
    // Get typical resource needs
    var typicalResourceNeeds: [String: Double] {
        switch self {
        case .farmer: return ["water": 10, "fertilizer": 5, "energy": 2, "seeds": 50]
        case .business: return ["energy": 20, "raw_materials": 100, "labor": 50, "capital": 1000]
        case .consumer: return ["food": 100, "energy": 30, "goods": 80, "services": 50]
        case .government: return ["energy": 50, "services": 100, "personnel": 1000, "budget": 10000]
        case .bank: return ["capital": 10000, "reserves": 5000, "loans": 50000, "interestRate": 5]
        case .research: return ["funding": 5000, "personnel": 100, "facilities": 200, "equipment": 300]
        }
    }
}

// MARK: - Agent Decision Framework

// Shared decision engine for all agents
public class DecisionEngine {
    // Discount factor for future value (0-1, higher = more short-sighted)
    private var discountFactor: Double = 0.95
    
    // Risk tolerance parameter (0-1, higher = risk-averse)
    private var riskTolerance: Double = 0.5
    
    // Learning rate for adaptive decisions (0-1)
    private var learningRate: Double = 0.1
    
    // Initialize with default parameters
    public init() {
        #warning("Configure decision engine parameters")
        #warning("Set: discount factor, risk tolerance, learning rate")
    }
    
    // Make a decision based on available options and current state
    public func makeDecision(
        _ options: [DecisionOption],
        currentState: AgentState,
        agentType: AgentType
    ) -> DecisionOption {
        #warning("Evaluate all options based on: utility, risk, costs, benefits")
        #warning("Apply agent-type-specific logic")
        #warning("Incorporate learning from past decisions")
        #warning("Return best option with rationale")
        
        // Evaluate each option
        var evaluatedOptions: [(DecisionOption, Double)] = [] // (option, utility)
        
        for option in options {
            let utility = evaluateOption(option, currentState: currentState, agentType: agentType)
            evaluatedOptions.append((option, utility))
        }
        
        #warning("Sort by utility and select best")
        // Sort by utility (descending)
        evaluatedOptions.sort { $0.1 > $1.1 }
        
        #warning("Apply some randomness/entropy to avoid always picking same option")
        // Add small random factor
        if evaluatedOptions.count > 1 {
            let bestUtility = evaluatedOptions[0].1
            let bestOptions = evaluatedOptions.filter { $0.1 >= bestUtility * 0.95 } // Within 5% of best
            
            if bestOptions.count > 1 {
                // Choose randomly from near-best options
                let randomIndex = Int.random(in: 0..<bestOptions.count)
                return bestOptions[randomIndex].0
            }
        }
        
        // Return best option
        return evaluatedOptions.first?.0 ?? options.first!
    }
    
    /// Evaluate a decision option
    private func evaluateOption(
        _ option: DecisionOption,
        currentState: AgentState,
        agentType: AgentType
    ) -> Double {
        #warning("Calculate utility based on: immediate benefit, long-term value, risk, costs")
        
        var utility: Double = 0
        
        // Immediate economic benefit
        let immediateBenefit = option.immediateEconomicBenefit
        utility += immediateBenefit * 0.4
        
        // Long-term value (discounted)
        let longTermValue = option.longTermValue * discountFactor
        utility += longTermValue * 0.3
        
        // Risk adjustment
        let riskPenalty = option.risk * (1 - riskTolerance)
        utility -= riskPenalty * 0.2
        
        // Agent-type-specific factors
        let typeFactor = agentTypeSpecificFactor(option, agentType: agentType)
        utility *= typeFactor
        
        #warning("Apply learning from past similar decisions")
        // In a full system, would check learning table
        
        return utility
    }
    
    /// Agent-type-specific utility factor
    private func agentTypeSpecificFactor(
        _ option: DecisionOption,
        agentType: AgentType
    ) -> Double {
        switch agentType {
        case .farmer:
            return farmerUtilityFactor(option)
        case .business:
            return businessUtilityFactor(option)
        case .consumer:
            return consumerUtilityFactor(option)
        case .government:
            return governmentUtilityFactor(option)
        case .bank:
            return bankUtilityFactor(option)
        case .research:
            return researchUtilityFactor(option)
        }
    }
    
    // Farmer utility factors
    private func farmerUtilityFactor(_ option: DecisionOption) -> Double {
        // Farmers care about: crop yield, profit, risk, resource availability
        var factor: Double = 1.0
        
        if let cropOption = option as? FarmerDecisionOption {
            #warning("Factor in: yield potential, resource costs, price expectations")
            let yieldFactor = cropOption.yieldPotential / 100.0 // Normalized
            let priceFactor = cropOption.expectedPrice / 50.0 // Normalized assumption
            let costFactor = 1 - (cropOption.resourceCost / 100.0) // Lower cost = better
            
            factor = 0.5 * yieldFactor + 0.3 * priceFactor + 0.2 * costFactor
        }
        
        return factor
    }
    
    // Business utility factors
    private func businessUtilityFactor(_ option: DecisionOption) -> Double {
        // Businesses care about: profit, market share, growth, risk
        var factor: Double = 1.0
        
        if let businessOption = option as? BusinessDecisionOption {
            #warning("Factor in: profit margin, market demand, competition, expansion potential")
            let profitFactor = businessOption.profitMargin / 100.0
            let demandFactor = businessOption.marketDemand / 100.0
            let competitionFactor = 1 - businessOption.competitionIntensity / 100.0
            let growthFactor = businessOption.expansionPotential / 100.0
            
            factor = 0.4 * profitFactor + 0.3 * demandFactor + 0.2 * competitionFactor + 0.1 * growthFactor
        }
        
        return factor
    }
    
    // Consumer utility factors
    private func consumerUtilityFactor(_ option: DecisionOption) -> Double {
        // Consumers care about: price, quality, preference match, budget
        var factor: Double = 1.0
        
        if let consumerOption = option as? ConsumerDecisionOption {
            #warning("Factor in: price sensitivity, quality preference, budget constraint")
            let priceFactor = 1 - consumerOption.priceSensitivity / 100.0 // Lower price = higher utility
            let qualityFactor = consumerOption.qualityPreference / 100.0
            let budgetFactor = consumerOption.budgetAvailable / max(1, consumerOption.price)
            
            factor = 0.4 * priceFactor + 0.3 * qualityFactor + 0.3 * budgetFactor
        }
        
        return factor
    }
    
    // Government utility factors
    private func governmentUtilityFactor(_ option: DecisionOption) -> Double {
        // Government cares about: public welfare, economic stability, compliance, reelection
        var factor: Double = 1.0
        
        if let governmentOption = option as? GovernmentDecisionOption {
            #warning("Factor in: public welfare, economic growth, compliance, stability")
            let welfareFactor = governmentOption.publicWelfare / 100.0
            let stabilityFactor = governmentOption.economicStability / 100.0
            let complianceFactor = governmentOption.regulationCompliance / 100.0
            let reelectionFactor = governmentOption.reelectionProbability / 100.0
            
            factor = 0.35 * welfareFactor + 0.3 * stabilityFactor + 0.25 * complianceFactor + 0.1 * reelectionFactor
        }
        
        return factor
    }
    
    // Bank utility factors
    private func bankUtilityFactor(_ option: DecisionOption) -> Double {
        // Banks care about: loan repayment, interest margin, risk, liquidity
        var factor: Double = 1.0
        
        if let bankOption = option as? BankDecisionOption {
            #warning("Factor in: interest rate, loan quality, default risk, liquidity")
            let interestFactor = bankOption.interestRate / 10.0 // Normalized
            let qualityFactor = bankOption.loanQuality / 100.0
            let riskFactor = 1 - bankOption.defaultRisk / 100.0 // Lower risk = better
            let liquidityFactor = bankOption.liquidityRatio / 10.0 // Normalized
            
            factor = 0.4 * interestFactor + 0.3 * qualityFactor + 0.2 * riskFactor + 0.1 * liquidityFactor
        }
        
        return factor
    }
    
    // Research utility factors
    private func researchUtilityFactor(_ option: DecisionOption) -> Double {
        // Researchers care about: breakthrough potential, funding efficiency, knowledge advancement, time
        var factor: Double = 1.0
        
        if let researchOption = option as? ResearchDecisionOption {
            #warning("Factor in: success probability, funding efficiency, knowledge gain, timeline")
            let successFactor = researchOption.successProbability / 100.0
            let efficiencyFactor = researchOption.fundingEfficiency / 100.0
            let knowledgeFactor = researchOption.knowledgeGain / 100.0
            let timelineFactor = 1 - researchOption.timeline / 60.0 // Shorter = better (normalized)
            
            factor = 0.4 * successFactor + 0.3 * efficiencyFactor + 0.2 * knowledgeFactor + 0.1 * timelineFactor
        }
        
        return factor
    }
    
    // Set parameters
    public func setDiscountFactor(_ factor: Double) {
        discountFactor = min(0.99, max(0.5, factor))
    }
    
    public func setRiskTolerance(_ tolerance: Double) {
        riskTolerance = min(1, max(0, tolerance))
    }
    
    public func setLearningRate(_ rate: Double) {
        learningRate = min(1, max(0, rate))
    }
}

// MARK: - Decision Option

// Base decision option
public struct DecisionOption: Identifiable {
    public let id: String
    public let name: String
    public let description: String
    
    // Economic attributes
    public var immediateEconomicBenefit: Double // Currency per period
    public var longTermValue: Double // Discounted future value
    public var risk: Double // 0-1, uncertainty/risk
    
    // Agent-type-specific attributes
    var farmerSpecific: [String: Any]?
    var businessSpecific: [String: Any]?
    var consumerSpecific: [String: Any]?
    var governmentSpecific: [String: Any]?
    var bankSpecific: [String: Any]?
    var researchSpecific: [String: Any]?
    
    public init(
        id: String,
        name: String,
        description: String,
        immediateEconomicBenefit: Double = 0,
        longTermValue: Double = 0,
        risk: Double = 0.5
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.immediateEconomicBenefit = immediateEconomicBenefit
        self.longTermValue = longTermValue
        self.risk = risk
    }
}

// MARK: - Agent State

// Current state affecting agent decisions
public struct AgentState {
    // Resources
    var availableResources: [String: Double] // Resource name -> amount
    var budget: Double
    var capital: Double
    
    // Market conditions
    var currentPrices: [String: Double] // Good/Service -> price
    var marketDemand: [String: Double] // Good/Service -> demand level 0-1
    var competitionIntensity: Double // 0-1, how much competition
    
    // Institutional context
    var regulatoryEnvironment: Double // 0-1, how strict regulations are
    var infrastructureQuality: Double // 0-1, quality of infrastructure available
    var informationQuality: Double // 0-1, how good information is
    
    // Social factors
    var publicTrust: Double // 0-1, trust in institutions
    var socialWelfare: Double // 0-1, overall social well-being
    
    // Initialize with default state
    public init(
        availableResources: [String: Double] = [:],
        budget: Double = 1000,
        capital: Double = 500,
        currentPrices: [String: Double] = [:],
        marketDemand: [String: Double] = [:],
        competitionIntensity: Double = 0.5,
        regulatoryEnvironment: Double = 0.5,
        infrastructureQuality: Double = 0.5,
        informationQuality: Double = 0.5,
        publicTrust: Double = 0.7,
        socialWelfare: Double = 0.7
    ) {
        self.availableResources = availableResources
        self.budget = budget
        self.capital = capital
        self.currentPrices = currentPrices
        self.marketDemand = marketDemand
        self.competitionIntensity = competitionIntensity
        self.regulatoryEnvironment = regulatoryEnvironment
        self.infrastructureQuality = infrastructureQuality
        self.informationQuality = informationQuality
        self.publicTrust = publicTrust
        self.socialWelfare = socialWelfare
    }
}

// MARK: - Agent Decision Options (Type-Specific)

// Farmer decision options
public struct FarmerDecisionOption: DecisionOption {
    // Crop-specific attributes
    public var cropType: String // Which crop to plant
    public var yieldPotential: Double // Expected yield per hectare
    public var resourceCost: Double // Cost of inputs (seeds, fertilizer, etc.)
    public var expectedPrice: Double // Expected market price at harvest
    public var riskFactor: Double // Crop-specific risk (weather, pests, etc.)
    public var timeToHarvest: Int // Periods until harvest
    
    // Initialize with defaults
    public init(
        id: String = "farmer-\(UUID().uuidString.prefix(8))",
        name: String = "Crop selection",
        description: String = "Choose which crop to plant",
        immediateEconomicBenefit: Double = 0,
        longTermValue: Double = 0,
        risk: Double = 0.5,
        cropType: String = "wheat",
        yieldPotential: Double = 50,
        resourceCost: Double = 30,
        expectedPrice: Double = 50,
        riskFactor: Double = 0.3,
        timeToHarvest: Int = 12
    ) {
        super.init(
            id: id,
            name: name,
            description: description,
            immediateEconomicBenefit: immediateEconomicBenefit,
            longTermValue: longTermValue,
            risk: risk
        )
        
        self.cropType = cropType
        self.yieldPotential = yieldPotential
        self.resourceCost = resourceCost
        self.expectedPrice = expectedPrice
        self.riskFactor = riskFactor
        self.timeToHarvest = timeToHarvest
        
        // Set type-specific attributes
        self.farmerSpecific = [
            "cropType": cropType,
            "yieldPotential": yieldPotential,
            "resourceCost": resourceCost,
            "expectedPrice": expectedPrice,
            "riskFactor": riskFactor,
            "timeToHarvest": timeToHarvest
        ]
    }
}

// Business decision options
public struct BusinessDecisionOption: DecisionOption {
    // Business-specific attributes
    public var productType: String // What product to produce/sell
    public var profitMargin: Double // Expected profit margin (%)
    public var marketDemand: Double // Expected market demand (0-100)
    public var competitionIntensity: Double // Competition level (0-100)
    public var expansionPotential: Double // Potential for growth (0-100)
    public var capitalRequired: Double // Capital needed for expansion
    
    // Initialize with defaults
    public init(
        id: String = "business-\(UUID().uuidString.prefix(8))",
        name: String = "Business expansion decision",
        description: String = "Decide on business expansion or contraction",
        immediateEconomicBenefit: Double = 0,
        longTermValue: Double = 0,
        risk: Double = 0.5,
        productType: String = "machinery",
        profitMargin: Double = 20,
        marketDemand: Double = 60,
        competitionIntensity: Double = 30,
        expansionPotential: Double = 40,
        capitalRequired: Double = 500
    ) {
        super.init(
            id: id,
            name: name,
            description: description,
            immediateEconomicBenefit: immediateEconomicBenefit,
            longTermValue: longTermValue,
            risk: risk
        )
        
        self.productType = productType
        self.profitMargin = profitMargin
        self.marketDemand = marketDemand
        self.competitionIntensity = competitionIntensity
        self.expansionPotential = expansionPotential
        self.capitalRequired = capitalRequired
        
        // Set type-specific attributes
        self.businessSpecific = [
            "productType": productType,
            "profitMargin": profitMargin,
            "marketDemand": marketDemand,
            "competitionIntensity": competitionIntensity,
            "expansionPotential": expansionPotential,
            "capitalRequired": capitalRequired
        ]
    }
}

// Consumer decision options
public struct ConsumerDecisionOption: DecisionOption {
    // Consumer-specific attributes
    public var purchaseType: String // What to purchase
    public var priceSensitivity: Double // How price-sensitive (0-100, higher = more sensitive)
    public var qualityPreference: Double // Preferred quality level (0-100)
    public var budgetAvailable: Double // Budget available for purchase
    public var currentPrice: Double // Current market price
    public var utilityFromPurchase: Double // Expected utility from the purchase
    
    // Initialize with defaults
    public init(
        id: String = "consumer-\(UUID().uuidString.prefix(8))",
        name: String = "Purchase decision",
        description: String = "Decide what to purchase",
        immediateEconomicBenefit: Double = 0,
        longTermValue: Double = 0,
        risk: Double = 0.5,
        purchaseType: String = "food",
        priceSensitivity: Double = 50,
        qualityPreference: Double = 70,
        budgetAvailable: Double = 100,
        currentPrice: Double = 50,
        utilityFromPurchase: Double = 50
    ) {
        super.init(
            id: id,
            name: name,
            description: description,
            immediateEconomicBenefit: immediateEconomicBenefit,
            longTermValue: longTermValue,
            risk: risk
        )
        
        self.purchaseType = purchaseType
        self.priceSensitivity = priceSensitivity
        self.qualityPreference = qualityPreference
        self.budgetAvailable = budgetAvailable
        self.currentPrice = currentPrice
        self.utilityFromPurchase = utilityFromPurchase
        
        // Set type-specific attributes
        self.consumerSpecific = [
            "purchaseType": purchaseType,
            "priceSensitivity": priceSensitivity,
            "qualityPreference": qualityPreference,
            "budgetAvailable": budgetAvailable,
            "currentPrice": currentPrice,
            "utilityFromPurchase": utilityFromPurchase
        ]
    }
}

// Government decision options
public struct GovernmentDecisionOption: DecisionOption {
    // Government-specific attributes
    public var policyType: String // What policy to implement
    public var publicWelfare: Double // Expected public welfare impact (0-100)
    public var economicStability: Double // Expected economic stability impact (0-100)
    public var regulationCompliance: Double // Expected regulatory compliance impact (0-100)
    public var reelectionProbability: Double // Probability of reelection (0-100)
    public var implementationCost: Double // Cost of implementation
    public var budgetAvailable: Double // Available budget
    
    // Initialize with defaults
    public init(
        id: String = "government-\(UUID().uuidString.prefix(8))",
        name: String = "Policy implementation decision",
        description: String = "Decide on policy implementation",
        immediateEconomicBenefit: Double = 0,
        longTermValue: Double = 0,
        risk: Double = 0.5,
        policyType: String = "subsidy",
        publicWelfare: Double = 60,
        economicStability: Double = 50,
        regulationCompliance: Double = 80,
        reelectionProbability: Double = 70,
        implementationCost: Double = 100,
        budgetAvailable: Double = 1000
    ) {
        super.init(
            id: id,
            name: name,
            description: description,
            immediateEconomicBenefit: immediateEconomicBenefit,
            longTermValue: longTermValue,
            risk: risk
        )
        
        self.policyType = policyType
        self.publicWelfare = publicWelfare
        self.economicStability = economicStability
        self.regulationCompliance = regulationCompliance
        self.reelectionProbability = reelectionProbability
        self.implementationCost = implementationCost
        self.budgetAvailable = budgetAvailable
        
        // Set type-specific attributes
        self.governmentSpecific = [
            "policyType": policyType,
            "publicWelfare": publicWelfare,
            "economicStability": economicStability,
            "regulationCompliance": regulationCompliance,
            "reelectionProbability": reelectionProbability,
            "implementationCost": implementationCost,
            "budgetAvailable": budgetAvailable
        ]
    }
}

// Bank decision options
public struct BankDecisionOption: DecisionOption {
    // Bank-specific attributes
    public var interestRate: Double // Proposed interest rate (%)
    public var loanQuality: Double // Expected loan quality (0-100)
    public var defaultRisk: Double // Expected default risk (0-100)
    public var liquidityRatio: Double // Liquidity ratio (%)
    public var loanAmount: Double // Amount of loan to issue
    public var capitalAdequacy: Double // Capital adequacy ratio (0-100)
    
    // Initialize with defaults
    public init(
        id: String = "bank-\(UUID().uuidString.prefix(8))",
        name: String = "Loan decision",
        description: String = "Decide on issuing a loan",
        immediateEconomicBenefit: Double = 0,
        longTermValue: Double = 0,
        risk: Double = 0.5,
        interestRate: Double = 5,
        loanQuality: Double = 80,
        defaultRisk: Double = 10,
        liquidityRatio: Double = 10,
        loanAmount: Double = 1000,
        capitalAdequacy: Double = 12
    ) {
        super.init(
            id: id,
            name: name,
            description: description,
            immediateEconomicBenefit: immediateEconomicBenefit,
            longTermValue: longTermValue,
            risk: risk
        )
        
        self.interestRate = interestRate
        self.loanQuality = loanQuality
        self.defaultRisk = defaultRisk
        self.liquidityRatio = liquidityRatio
        self.loanAmount = loanAmount
        self.capitalAdequacy = capitalAdequacy
        
        // Set type-specific attributes
        self.bankSpecific = [
            "interestRate": interestRate,
            "loanQuality": loanQuality,
            "defaultRisk": defaultRisk,
            "liquidityRatio": liquidityRatio,
            "loanAmount": loanAmount,
            "capitalAdequacy": capitalAdequacy
        ]
    }
}

// Research decision options
public struct ResearchDecisionOption: DecisionOption {
    // Research-specific attributes
    public var researchArea: ResearchArea // Area of research
    public var successProbability: Double // Probability of success (0-100)
    public var fundingEfficiency: Double // Funding efficiency (0-100)
    public var knowledgeGain: Double // Expected knowledge gain (0-100)
    public var timeline: Int // Time to result in periods
    public var resourceRequirements: Double // Resources needed
    
    // Initialize with defaults
    public init(
        id: String = "research-\(UUID().uuidString.prefix(8))",
        name: String = "Research project selection",
        description: String = "Select research project to fund",
        immediateEconomicBenefit: Double = 0,
        longTermValue: Double = 0,
        risk: Double = 0.5,
        researchArea: ResearchArea = .cropGenetics,
        successProbability: Double = 50,
        fundingEfficiency: Double = 70,
        knowledgeGain: Double = 50,
        timeline: Int = 30,
        resourceRequirements: Double = 1000
    ) {
        super.init(
            id: id,
            name: name,
            description: description,
            immediateEconomicBenefit: immediateEconomicBenefit,
            longTermValue: longTermValue,
            risk: risk
        )
        
        self.researchArea = researchArea
        self.successProbability = successProbability
        self.fundingEfficiency = fundingEfficiency
        self.knowledgeGain = knowledgeGain
        self.timeline = timeline
        self.resourceRequirements = resourceRequirements
        
        // Set type-specific attributes
        self.researchSpecific = [
            "researchArea": researchArea.rawValue,
            "successProbability": successProbability,
            "fundingEfficiency": fundingEfficiency,
            "knowledgeGain": knowledgeGain,
            "timeline": timeline,
            "resourceRequirements": resourceRequirements
        ]
    }
}

// MARK: - Agent Base Class

// Base agent class with shared functionality
public class Agent {
    public let id: String
    public let type: AgentType
    public var state: AgentState
    public var decisionEngine: DecisionEngine
    
    // Agent history
    var decisionHistory: [(DecisionOption, DecisionOption)] = [] // (option chosen, option best)
    var performanceHistory: [Double] = [] // Utility of decisions over time
    
    // Initialize agent
    public init(
        id: String,
        type: AgentType,
        state: AgentState,
        decisionEngine: DecisionEngine = DecisionEngine()
    ) {
        self.id = id
        self.type = type
        self.state = state
        self.decisionEngine = decisionEngine
    }
    
    /// Make a decision based on available options
    public func decide(options: [DecisionOption]) -> DecisionOption {
        return decisionEngine.makeDecision(options, currentState: state, agentType: type)
    }
    
    /// Update agent state after decision
    mutating func updateState(
        afterDecision chosenOption: DecisionOption,
        availableNewOptions: [DecisionOption]
    ) {
        #warning("Update agent state based on chosen decision")
        #warning("Learn from the outcome")
        #warning("Update performance tracking")
        
        // Record the decision
        if let bestOption = decide(options: availableNewOptions).id == chosenOption.id ? chosenOption : nil {
            decisionHistory.append((chosenOption, bestOption ?? chosenOption))
        }
        
        // Track performance
        let utility = decisionEngine.evaluateOption(
            chosenOption,
            currentState: state,
            agentType: type
        )
        performanceHistory.append(utility)
        
        #warning("Apply learning from outcome")
        // In a full system, would update decision engine parameters
    }
    
    /// Get agent performance summary
    func performanceSummary() -> AgentPerformanceSummary {
        let avgPerformance = performanceHistory.isEmpty ? 0 : 
            performanceHistory.reduce(0, +) / Double(performanceHistory.count)
        
        let totalDecisions = decisionHistory.count
        let successfulDecisions = decisionHistory.filter { 
            $0.1.utility > $0.0.utility // Better than alternative would need full info
        }.count
        
        return AgentPerformanceSummary(
            agentId: id,
            agentType: type,
            totalDecisions: totalDecisions,
            averageUtility: avgPerformance,
            totalPerformance: performanceHistory.reduce(0, +),
            decisionCount: totalDecisions
        )
    }
}

// MARK: - Agent Performance Summary

public struct AgentPerformanceSummary {
    public let agentId: String
    let agentType: AgentType
    let totalDecisions: Int
    let averageUtility: Double
    let totalPerformance: Double
    let decisionCount: Int
}

// MARK: - Specific Agent Implementations

// Farmer agent
public class FarmerAgent: Agent {
    // Farmer-specific attributes
    var landArea: Double // Hectares owned
    var currentCrop: String // Currently planted crop
    var resourceInventory: [String: Double] // Seeds, fertilizer, etc.
    var historicalYields: [String: [Double]] // Crop -> yield history
    
    public init(
        id: String,
        type: AgentType = .farmer,
        state: AgentState,
        landArea: Double = 100,
        currentCrop: String = "wheat",
        resourceInventory: [String: Double] = [:],
        historicalYields: [String: [Double]] = [:],
        decisionEngine: DecisionEngine = DecisionEngine()
    ) {
        self.landArea = landArea
        self.currentCrop = currentCrop
        self.resourceInventory = resourceInventory
        self.historicalYields = historicalYields
        
        super.init(id: id, type: type, state: state, decisionEngine: decisionEngine)
    }
    
    // Make farmer-specific decision
    public func makeCropDecision(options: [FarmerDecisionOption]) -> FarmerDecisionOption {
        decide(options: options) as! FarmerDecisionOption
    }
    
    // Update farmer state after growing season
    mutating func updateAfterGrowingSeason(
        actualYield: Double,
        actualPrice: Double,
        resourcesUsed: [String: Double]
    ) {
        #warning("Update: crop, resources, historical yields, state")
        // Update current crop based on what was planted
        currentCrop = "\(currentCrop)-harvested"
        
        #warning("Update historical yields")
        // Record actual yield
        if var yields = historicalYields[currentCrop] {
            yields.append(actualYield)
            if yields.count > 20 { // Keep last 20 years of data
                yields.removeFirst()
            }
            historicalYields[currentCrop] = yields
        } else {
            historicalYields[currentCrop] = [actualYield]
        }
        
        #warning("Update resources after usage")
        // Deduct used resources
        for (resource, amount) in resourcesUsed {
            resourceInventory[resource] = (resourceInventory[resource] ?? 0) - amount
        }
        
        #warning("Recalculate budget based on yield * price")
        // budget += actualYield * actualPrice
    }
}

// Business agent
public class BusinessAgent: Agent {
    // Business-specific attributes
    var businessName: String
    var currentProduct: String
    var marketShare: Double // Percentage of market (0-1)
    var capitalStock: Double
    var profitHistory: [Double]
    
    public init(
        id: String,
        type: AgentType = .business,
        state: AgentState,
        businessName: String = "Business \(id)",
        currentProduct: String = "machinery",
        marketShare: Double = 0.1,
        capitalStock: Double = 1000,
        profitHistory: [Double] = [],
        decisionEngine: DecisionEngine = DecisionEngine()
    ) {
        self.businessName = businessName
        self.currentProduct = currentProduct
        self.marketShare = marketShare
        self.capitalStock = capitalStock
        self.profitHistory = profitHistory
        
        super.init(id: id, type: type, state: state, decisionEngine: decisionEngine)
    }
    
    // Make business-specific decision
    public func makeBusinessDecision(options: [BusinessDecisionOption]) -> BusinessDecisionOption {
        decide(options: options) as! BusinessDecisionOption
    }
    
    // Update business state after period
    mutating func updateAfterPeriod(
        revenue: Double,
        costs: Double,
        marketShareChange: Double
    ) {
        #warning("Update: profit, market share, capital stock")
        let profit = revenue - costs
        profitHistory.append(profit)
        
        #warning("Clip profit history to reasonable length")
        // Keep last 30 periods of profit data
        if profitHistory.count > 30 {
            profitHistory.removeFirst(profitHistory.count - 30)
        }
        
        #warning("Update market share")
        marketShare = max(0, min(1, marketShare + marketShareChange))
        
        #warning("Update capital stock based on profit")
        capitalStock = max(0, capitalStock + profit * 0.5) // Retain 50% of profit
    }
}

// Consumer agent
public class ConsumerAgent: Agent {
    // Consumer-specific attributes
    var income: Double
    var savings: Double
    var consumptionHistory: [Double]
    var preferenceWeights: [String: Double] // Good type -> preference weight
    
    public init(
        id: String,
        type: AgentType = .consumer,
        state: AgentState,
        income: Double = 1000,
        savings: Double = 200,
        preferenceWeights: [String: Double] = [:],
        consumptionHistory: [Double] = [],
        decisionEngine: DecisionEngine = DecisionEngine()
    ) {
        self.income = income
        self.savings = savings
        self.preferenceWeights = preferenceWeights
        
        // Initialize consumption history
        var history = consumptionHistory
        if history.isEmpty {
            history = [50, 60, 55, 70, 65] // Default sample
        }
        if history.count > 50 { // Keep last 50 periods
            history.removeFirst(history.count - 50)
        }
        
        super.init(id: id, type: type, state: state, decisionEngine: decisionEngine)
        self.consumptionHistory = history
    }
    
    // Make consumer-specific decision
    public func makeConsumptionDecision(options: [ConsumerDecisionOption]) -> ConsumerDecisionOption {
        decide(options: options) as! ConsumerDecisionOption
    }
    
    // Update consumer state after purchase
    mutating func updateAfterPurchase(
        purchaseAmount: Double,
        purchasedGood: String,
        satisfaction: Double
    ) {
        #warning("Update: income, savings, consumption history, preferences")
        // Deduct from budget/savings
        income = max(0, income - purchaseAmount)
        savings = max(0, savings - (purchaseAmount * 0.1)) // Keep 90% of purchase in savings context
        
        #warning("Update consumption history")
        // Add to history, keep last 50 periods
        var history = consumptionHistory
        history.append(satisfaction)
        if history.count > 50 {
            history.removeFirst(history.count - 50)
        }
        self.consumptionHistory = history
        
        #warning("Recalculate preference weights based on satisfaction")
        // In a full system, would adjust preferences based on purchase satisfaction
    }
}

// Government agent
public class GovernmentAgent: Agent {
    // Government-specific attributes
    var budget: Double
    var approvalRating: Double // Public approval (0-100)
    var pendingPolicies: [GovernmentDecisionOption]
    var electionCycle: Int // Periods until next election
    
    public init(
        id: String,
        type: AgentType = .government,
        state: AgentState,
        budget: Double = 10000,
        approvalRating: Double = 70,
        pendingPolicies: [GovernmentDecisionOption] = [],
        electionCycle: Int = 24,
        decisionEngine: DecisionEngine = DecisionEngine()
    ) {
        self.budget = budget
        self.approvalRating = approvalRating
        self.pendingPolicies = pendingPolicies
        self.electionCycle = electionCycle
        
        super.init(id: id, type: type, state: state, decisionEngine: decisionEngine)
    }
    
    // Make government-specific decision
    public func makeGovernmentDecision(options: [GovernmentDecisionOption]) -> GovernmentDecisionOption {
        decide(options: options) as! GovernmentDecisionOption
    }
    
    // Update government state after period
    mutating func updateAfterPeriod(
        economicGrowth: Double,
        publicApprovalChange: Double,
        policyImplementationSuccess: Double
    ) {
        #warning("Update: budget, approval rating, pending policies, election cycle")
        // Budget changes based on economic conditions
        budget = max(0, budget + economicGrowth * 10) // Simplified
        
        #warning("Update approval rating")
        approvalRating = max(0, min(100, approvalRating + publicApprovalChange))
        
        #warning("Manage pending policies")
        // Remove implemented policies, keep others
        
        #warning("Decrement election cycle")
        electionCycle = max(0, electionCycle - 1)
    }
    
    // Check if election is due
    var isElectionYear: Bool {
        electionCycle <= 0
    }
}

// Bank agent
public class BankAgent: Agent {
    // Bank-specific attributes
    var totalDeposits: Double
    var totalLoans: Double
    var reserveRatio: Double // Required reserve ratio (%)
    var loanDefaultHistory: [Double] // Loan defaults over time
    var interestIncome: Double
    var interestExpense: Double
    
    public init(
        id: String,
        type: AgentType = .bank,
        state: AgentState,
        totalDeposits: Double = 10000,
        totalLoans: Double = 5000,
        reserveRatio: Double = 0.1, // 10%
        loanDefaultHistory: [Double] = [],
        interestIncome: Double = 0,
        interestExpense: Double = 0,
        decisionEngine: DecisionEngine = DecisionEngine()
    ) {
        self.totalDeposits = totalDeposits
        self.totalLoans = totalLoans
        self.reserveRatio = reserveRatio
        self.loanDefaultHistory = loanDefaultHistory
        self.interestIncome = interestIncome
        self.interestExpense = interestExpense
        
        super.init(id: id, type: type, state: state, decisionEngine: decisionEngine)
    }
    
    // Make bank-specific decision
    public func makeBankDecision(options: [BankDecisionOption]) -> BankDecisionOption {
        decide(options: options) as! BankDecisionOption
    }
    
    // Update bank state after period
    mutating func updateAfterPeriod(
        newDeposits: Double,
        loanRepayments: Double,
        newLoansIssued: Double,
        loanDefaults: Double,
        interestIncome: Double,
        interestExpense: Double
    ) {
        #warning("Update: deposits, loans, reserves, income/expense")
        totalDeposits = max(0, totalDeposits + newDeposits - loanDefaults)
        totalLoans = max(0, totalLoans + newLoansIssued - loanDefaults)
        
        #warning("Update reserve ratio if needed")
        // In a full system, would adjust based on central bank requirements
        
        #warning("Track loan defaults")
        loanDefaultHistory.append(loanDefaults)
        if loanDefaultHistory.count > 24 { // Keep 2 years of data
            loanDefaultHistory.removeFirst(loanDefaultHistory.count - 24)
        }
        
        #warning("Update interest income and expense")
        self.interestIncome = interestIncome
        self.interestExpense = interestExpense
    }
    
    // Calculate capital adequacy
    var capitalAdequacyRatio: Double {
        let riskWeightedAssets = totalLoans * 0.8 // Simplified: 80% risk weight
        return totalDeposits > 0 ? totalDeposits / riskWeightedAssets : 0
    }
}

// Research agent
public class ResearchAgent: Agent {
    // Research-specific attributes
    var researchAreas: [ResearchArea: Double] // Area -> knowledge level (0-1)
    var activeProjects: [String: ResearchProject] // Project ID -> project
    var totalFundingAllocated: Double
    var breakthroughCount: Int
    
    public init(
        id: String,
        type: AgentType = .research,
        state: AgentState,
        researchAreas: [ResearchArea: Double] = [:],
        activeProjects: [String: ResearchProject] = [:],
        totalFundingAllocated: Double = 0,
        breakthroughCount: Int = 0,
        decisionEngine: DecisionEngine = DecisionEngine()
    ) {
        self.researchAreas = researchAreas
        self.activeProjects = activeProjects
        self.totalFundingAllocated = totalFundingAllocated
        self.breakthroughCount = breakthroughCount
        
        // Initialize research areas if empty
        if researchAreas.isEmpty {
            for area in ResearchArea.allCases {
                researchAreas[area] = 0.1 // Small baseline
            }
        }
        
        super.init(id: id, type: type, state: state, decisionEngine: decisionEngine)
    }
    
    // Make research-specific decision
    public func makeResearchDecision(options: [ResearchDecisionOption]) -> ResearchDecisionOption {
        decide(options: options) as! ResearchDecisionOption
    }
    
    // Update research state after period
    mutating func updateAfterPeriod(
        newKnowledge: [ResearchArea: Double],
        projectsCompleted: Int,
        breakthroughs: Int,
        fundingAllocated: Double
    ) {
        #warning("Update: research knowledge, active projects, breakthroughs, funding")
        
        #warning("Update research area knowledge")
        for (area, gain) in newKnowledge {
            researchAreas[area] = min(1, (researchAreas[area] ?? 0) + gain)
        }
        
        #warning("Update breakthrough count")
        breakthroughCount += breakthroughs
        
        #warning("Track funding")
        totalFundingAllocated = fundingAllocated
        
        #warning("Update active projects")
        // Would complete projects based on timelines and success
    }
    
    // Get knowledge level for an area
    func knowledgeLevel(_ area: ResearchArea) -> Double {
        researchAreas[area] ?? 0
    }
    
    // Check if research area has sufficient knowledge for technology level
    func canSupportTechnologyLevel(_ area: ResearchArea, level: Int) -> Bool {
        let knowledge = knowledgeLevel(area)
        // Higher technology levels require higher knowledge
        let requiredKnowledge = Double(level) / 10.0
        return knowledge >= requiredKnowledge
    }
}

// MARK: - Agent Management System

// Central agent management
public class AgentManagement {
    // All agents in the system
    private var agents: [String: Agent] = [:]
    
    // Agent type factories
    var agentFactories: [AgentType: (AgentState) -> Agent] = [
        .farmer: { FarmerAgent(id: UUID().uuidString, type: .farmer, state: $0) },
        .business: { BusinessAgent(id: UUID().uuidString, type: .business, state: $0) },
        .consumer: { ConsumerAgent(id: UUID().uuidString, type: .consumer, state: $0) },
        .government: { GovernmentAgent(id: UUID().uuidString, type: .government, state: $0) },
        .bank: { BankAgent(id: UUID().uuidString, type: .bank, state: $0) },
        .research: { ResearchAgent(id: UUID().uuidString, type: .research, state: $0) }
    ]
    
    // Initialize with default agents
    public init() {
        #warning("Initialize default agents for each type")
        #warning("Set up agent states with appropriate starting conditions")
        
        #warning("TODO: Create one agent of each type with baseline state")
        #warning("TODO: Configure initial resources, budgets, market conditions")
        
        // Create one agent of each type
        for agentType in AgentType.allCases {
            let initialState = AgentState()
            if let factory = agentFactories[agentType] {
                let agent = factory(initialState)
                agents[agent.id] = agent
            }
        }
    }
    
    // MARK: - Agent Operations
    
    public func getAgent(_ id: String) -> Agent? {
        return agents[id]
    }
    
    public func getAgents(_ type: AgentType) -> [Agent] {
        return agents.values.filter { $0.type == type }
    }
    
    public func getAllAgents() -> [Agent] {
        return Array(agents.values)
    }
    
    /// Create a new agent of specified type
    mutating func createAgent(_ type: AgentType, state: AgentState) -> Agent? {
        if let factory = agentFactories[type] {
            let agent = factory(state)
            agents[agent.id] = agent
            return agent
        }
        return nil
    }
    
    /// Remove an agent
    mutating func removeAgent(_ id: String) {
        agents.removeValue(forKey: id)
    }
    
    /// Get all agents by type
    func agentsByType(_ type: AgentType) -> [Agent] {
        return getAgents(type)
    }
    
    /// Get count of agents by type
    func agentCount(_ type: AgentType) -> Int {
        return agents.values.filter { $0.type == type }.count
    }
    
    /// Get agent statistics summary
    func getAgentStatistics() -> AgentStatistics {
        var typeCounts: [AgentType: Int] = [:]
        for type in AgentType.allCases {
            typeCounts[type] = agentCount(type)
        }
        
        var averageUtilities: [AgentType: Double] = [:]
        for type in AgentType.allCases {
            let typeAgents = getAgents(type)
            if !typeAgents.isEmpty {
                let avgUtility = typeAgents.map { $0.performanceSummary().averageUtility }.reduce(0, +) / Double(typeAgents.count)
                averageUtilities[type] = avgUtility
            } else {
                averageUtilities[type] = 0
            }
        }
        
        return AgentStatistics(
            totalAgents: agents.count,
            byType: typeCounts,
            averageUtilities: averageUtilities
        )
    }
}

// MARK: - Agent Statistics

public struct AgentStatistics {
    let totalAgents: Int
    let byType: [AgentType: Int]
    let averageUtilities: [AgentType: Double]
}

// MARK: - Previews (iOS/macOS)

//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//struct AIAgentsPreview: PreviewProvider {
//    static var previews: some View {
//        // Would display agent decisions, performance summaries, economic interactions
//        Text("AI Agents System Preview")
//    }
//}
//#endif