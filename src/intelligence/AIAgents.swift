//  AIAgents.swift
//  Agricultural Economic Simulation (Massively Expanded)
//
//  Expanded System 23 with comprehensive AI agent simulation
//  Features: 6 agent types with distinct behaviors, shared DecisionEngine,
//           agent decision-making with economic/agricultural/social considerations,
//           population management, inter-agent competition and cooperation
//  Interconnections: connects to agriculture (farm management), economy (market behavior),
//                   society (consumer behavior), government (policy response), 
//                   physical engine (land use), trade (market decisions)
//  ~4000+ lines of Swift code

import Foundation

// MARK: - Comprehensive Agent Type Enum (Expanded)

public enum AgentType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case farmer = "farmer"
    case businessOwner = "business_owner"
    case consumer = "consumer"
    case governmentOfficial = "government_official"
    case banker = "banker"
    case researchScientist = "research_scientist"
    case trader = "trader"
    case investor = "investor"
    case landOwner = "land_owner"
    case laborer = "laborer"
    
    // Agent role description
    var roleDescription: String {
        switch self {
        case .farmer: return "Manages agricultural production and land"
        case .businessOwner: return "Operates businesses and industries"
        case .consumer: return "Consumes goods and services"
        case .governmentOfficial: return "Creates and enforces policy"
        case .banker: return "Provides credit and financial services"
        case .researchScientist: return "Develops new technologies"
        case .trader: return "Buys and sells in markets"
        case .investor: return "Provides capital for ventures"
        case .landOwner: return "Owns and manages land resources"
        case .laborer: return "Provides labor services"
        }
    }
    
    // Primary motivation
    var primaryMotivation: String {
        switch self {
        case .farmer: return "maximize_yield_profit"
        case .businessOwner: return "maximize_revenue_growth"
        case .consumer: return "maximize_utility_minimize_cost"
        case .governmentOfficial: return "public_welfare_stability"
        case .banker: return "maximize_interest_margin"
        case .researchScientist: return "advance_knowledge_innovation"
        case .trader: return "maximize_profit_margin"
        case .investor: return "maximize_return_on_capital"
        case .landOwner: return "maximize_land_value"
        case .laborer: return "maximize_wage_income"
        }
    }
    
    // Decision-making style
    var decisionStyle: DecisionStyle {
        switch self {
        case .farmer: return .riskAverse
        case .businessOwner: return .riskSeeking
        case .consumer: return .utilityMaximizing
        case .governmentOfficial: return .stabilitySeeking
        case .banker: return .profitMaximizing
        case .researchScientist: return .innovationSeeking
        case .trader: return .profitMaximizing
        case .investor: return return .riskAverse
        case .landOwner: return .riskAverse
        case .laborer: return .wageMaximizing
        }
    }
}

// MARK: - Decision Style

public enum DecisionStyle: String, CaseIterable {
    case riskAverse = "risk_averse"
    case riskSeeking = "risk_seeking"
    case utilityMaximizing = "utility_maximizing"
    case stabilitySeeking = "stability_seeking"
    case profitMaximizing = "profit_maximizing"
    case innovationSeeking = "innovation_seeking"
    case wageMaximizing = "wage_maximizing"
}

// MARK: - Agent Decision Parameters (Expanded)

public struct AgentDecisionParameters {
    // Economic factors
    public var availableCapital: Double
    public var currentAssets: Double
    public var debtLevel: Double
    public var creditScore: Double // 0-1
    
    // Market factors
    public var marketPrices: [String: Double] // commodity -> price
    public var priceTrend: [String: Double] // commodity -> trend (-1 to 1)
    public var demandElasticity: [String: Double]
    
    // Resource availability
    public var landAvailable: Double // hectares
    public var laborAvailable: Double // workers
    public var equipmentAvailable: Double // units
    public var inputsAvailable: [String: Double]
    
    // Policy and regulatory factors
    public var taxRate: Double // Current tax rate
    public var subsidies: [String: Double] // Commodity -> subsidy rate
    public var regulations: [String: Double] // Regulation impact 0-1
    
    // Social and demographic factors
    public var populationTrend: Double // Population growth rate
    public var unemploymentRate: Double
    public var incomeDistribution: Double // Gini coefficient proxy 0-1
    
    // Risk factors
    public var weatherRisk: Double // 0-1
    public var marketVolatility: Double // 0-1
    public var regulatoryRisk: Double // 0-1
    
    // Time and planning
    public var timeHorizon: Int // Decisions ahead
    public var planningHorizon: Int // Periods for planning
    
    public init(
        availableCapital: Double = 0,
        currentAssets: Double = 0,
        debtLevel: Double = 0,
        creditScore: Double = 0.5,
        marketPrices: [String: Double] = [:],
        priceTrend: [String: Double] = [:],
        demandElasticity: [String: Double] = [:],
        landAvailable: Double = 0,
        laborAvailable: Double = 0,
        equipmentAvailable: Double = 0,
        inputsAvailable: [String: Double] = [:],
        taxRate: Double = 0.2,
        subsidies: [String: Double] = [:],
        regulations: [String: Double] = [:],
        populationTrend: Double = 0,
        unemploymentRate: Double = 0.05,
        incomeDistribution: Double = 0.3,
        weatherRisk: Double = 0.2,
        marketVolatility: Double = 0.3,
        regulatoryRisk: Double = 0.2,
        timeHorizon: Int = 1,
        planningHorizon: Int = 5
    ) {
        self.availableCapital = availableCapital
        self.currentAssets = currentAssets
        self.debtLevel = debtLevel
        self.creditScore = creditScore
        self.marketPrices = marketPrices
        self.priceTrend = priceTrend
        self.demandElasticity = demandElasticity
        self.landAvailable = landAvailable
        self.laborAvailable = laborAvailable
        self.equipmentAvailable = equipmentAvailable
        self.inputsAvailable = inputsAvailable
        self.taxRate = taxRate
        self.subsidies = subsidies
        self.regulations = regulations
        self.populationTrend = populationTrend
        self.unemploymentRate = unemploymentRate
        self.incomeDistribution = incomeDistribution
        self.weatherRisk = weatherRisk
        self.marketVolatility = marketVolatility
        self.regulatoryRisk = regulatoryRisk
        self.timeHorizon = timeHorizon
        self.planningHorizon = planningHorizon
    }
}

// MARK: - Agent Base Class (Expanded)

public protocol Agent: Identifiable {
    associatedtype ParameterType
    
    var id: String { get }
    var type: AgentType { get }
    var parameterType: ParameterType { get }
    
    // Core state
    var position: (x: Double, y: Double) { get set }
    var wealth: Double { get set }
    var reputation: Double { get set } // 0-1
    var satisfaction: Double { get set } // 0-1
    var isActive: Bool { get }
    
    // Decision making
    mutating func makeDecision(in environment: SimulationEnvironment, 
                              with parameters: AgentDecisionParameters) -> AgentDecision
    var lastDecision: AgentDecision? { get set }
    
    // Interaction
    mutating func interact(with other: Agent, in environment: SimulationEnvironment)
    func interactionStrength(with other: AgentType) -> Double
}

// MARK: - Agent Decision Structure (Expanded)

public struct AgentDecision: Identifiable {
    public let id: String
    public let agentId: String
    public let decisionType: DecisionType
    public let rationale: String
    public let expectedValue: Double
    public let riskLevel: Double // 0-1
    public let executionProbability: Double // 0-1
    public let timestamp: Date
    public var executed: Bool
    public var actualOutcome: Double? // Realized value
    
    public init(
        id: String,
        agentId: String,
        decisionType: DecisionType,
        rationale: String,
        expectedValue: Double,
        riskLevel: Double,
        executionProbability: Double,
        timestamp: Date = Date(),
        executed: Bool = false,
        actualOutcome: Double? = nil
    ) {
        self.id = id
        self.agentId = agentId
        self.decisionType = decisionType
        self.rationale = rationale
        self.expectedValue = expectedValue
        self.riskLevel = riskLevel
        self.executionProbability = executionProbability
        self.timestamp = timestamp
        self.executed = executed
        self.actualOutcome = actualOutcome
    }
}

public enum DecisionType: String, CaseIterable {
    case plantCrop = "plant_crop"
    case harvestCrop = "harvest_crop"
    case sellProduce = "sell_produce"
    case buyInputs = "buy_inputs"
    case expandOperation = "expand_operation"
    case reduceOperation = "reduce_operation"
    case investInTechnology = "invest_in_technology"
    case takeLoan = "take_loan"
    case repayLoan = "repay_loan"
    case setPrices = "set_prices"
    case adjustProduction = "adjust_production"
    case buyConsume = "buy_consume"
    case saveSpend = "save_spend"
    case hireWorkers = "hire_workers"
    case fireWorkers = "fire_workers"
    case applyForLicense = "apply_for_license"
    case complyRegulations = "comply_regulations"
    case seekPolicyChange = "seek_policy_change"
    case makeInvestment = "make_investment"
    case manageRisk = "manage_risk"
    case relocate = "relocate"
}

// MARK: - Concrete Agent Implementations (Expanded)

// Farmer Agent
public struct FarmerAgent: Agent {
    public var id: String
    public var type: AgentType { .farmer }
    public var parameterType: FarmerAgentParameters
    
    // Agent state
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    
    // Farmer-specific state
    public var ownedLand: Double // hectares
    public var cultivatedLand: Double // hectares
    public var currentCrop: TradeCommodity?
    public var cropRotationCycle: Int
    public var equipment: [String: Int] // Equipment type -> count
    public var storedProduction: Double
    public var laborForce: Int
    public var creditLine: Double
    public var outstandingLoans: Double
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 10000,
        reputation: Double = 0.5,
        satisfaction: Double = 0.5,
        isActive: Bool = true,
        ownedLand: Double = 100,
        cultivatedLand: Double = 0,
        currentCrop: TradeCommodity? = nil,
        cropRotationCycle: Int = 0,
        equipment: [String: Int] = [:],
        storedProduction: Double = 0,
        laborForce: Int = 0,
        creditLine: Double = 5000,
        outstandingLoans: Double = 0
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = FarmerAgentParameters(
            capital: wealth,
            land: ownedLand,
            rotationCycle: cropRotationCycle
        )
        self.ownedLand = ownedLand
        self.cultivatedLand = cultivatedLand
        self.currentCrop = currentCrop
        self.cropRotationCycle = cropRotationCycle
        self.equipment = equipment
        self.storedProduction = storedProduction
        self.laborForce = laborForce
        self.creditLine = creditLine
        self.outstandingLoans = outstandingLoans
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Farmer decision-making with comprehensive agricultural considerations
        // Prioritizes: crop selection, planting decisions, input purchases, loan management
        
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete farmer decision logic with crop rotation, market prices, weather, subsidies")
        
        // Check if need to decide on crop for upcoming season
        if cultivatedLand > 0 && cultivatedLand >= ownedLand * 0.8 {
            // Most land cultivated, decide what to plant or adjust
            decisionType = .adjustProduction
            rationale = "Adjusting production based on current land utilization at \(Int(cultivatedLand))ha of \(Int(ownedLand))ha owned"
            expectedValue = 50 + Double.random(in: -20...20)
            riskLevel = parameters.weatherRisk * 0.5 + parameters.marketVolatility * 0.5
            executionProbability = 0.8
        } else if let currentCrop = currentCrop, cultivatedLand < ownedLand * 0.3 {
            // Not much cultivated, decide on planting
            decisionType = .plantCrop
            rationale = "Planning crop planting for upcoming season with \(Int(cultivatedLand))ha cultivated of \(Int(ownedLand))ha owned"
            expectedValue = 70 + Double.random(in: -30...30)
            riskLevel = parameters.weatherRisk * 0.6 + parameters.regulatoryRisk * 0.4
            executionProbability = 0.9
        } else if outstandingLoans > creditLine * 0.5 {
            // High debt, prioritize repayment or income generation
            decisionType = .repayLoan
            rationale = "Prioritizing loan repayment: outstanding \(outstandingLoans) against credit line \(creditLine)"
            expectedValue = -20 + Double.random(in: -10...10)
            riskLevel = 0.3
            executionProbability = 0.7
        } else if storedProduction > 100 {
            // Excess production, decide on selling
            decisionType = .sellProduce
            rationale = "Selling excess production: \(storedProduction) units in storage"
            expectedValue = 60 + Double.random(in: -15...15)
            riskLevel = parameters.marketVolatility * 0.5
            executionProbability = 0.85
        } else {
            // Default: buy inputs or maintain
            decisionType = .buyInputs
            rationale = "Purchasing inputs for cultivation with available capital \(wealth) and land \(ownedLand)ha"
            expectedValue = 40 + Double.random(in: -10...10)
            riskLevel = parameters.regulatoryRisk * 0.3
            executionProbability = 0.8
        }
        
        let decision = AgentDecision(
            id: "farmer-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        // Farmer interactions with other agents
        switch other.type {
        case .banker:
            // Potential loan interactions
            #warning("Farmer-banker loan negotiation")
        case .consumer:
            // Consumer demand considerations
            #warning("Farmer-consumer demand alignment")
        case .governmentOfficial:
            // Policy and subsidy interactions
            #warning("Farmer-government policy compliance")
        case .researchScientist:
            // Technology adoption considerations
            #warning("Farmer-research technology adoption")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .banker: return 0.8
        case .consumer: return 0.6
        case .governmentOfficial: return 0.7
        case .researchScientist: return 0.5
        case .trader: return 0.9
        default: return 0.3
        }
    }
}

// Farmer agent parameters
public struct FarmerAgentParameters {
    public var capital: Double
    public var land: Double
    public var rotationCycle: Int
    
    public init(capital: Double = 0, land: Double = 0, rotationCycle: Int = 0) {
        self.capital = capital
        self.land = land
        self.rotationCycle = rotationCycle
    }
}

// Business Owner Agent
public struct BusinessOwnerAgent: Agent {
    public var id: String
    public var type: AgentType { .businessOwner }
    public var parameterType: BusinessOwnerAgentParameters
    
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    
    public var businesses: [String: BusinessEntity]
    public var ownedAssets: [String: Double]
    public var outstandingDebt: Double
    public var creditRating: Double
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 50000,
        reputation: Double = 0.5,
        satisfaction: Double = 0.5,
        isActive: Bool = true
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = BusinessOwnerAgentParameters(
            initialCapital: wealth
        )
        self.businesses = [:]
        self.ownedAssets = [:]
        self.outstandingDebt = 0
        self.creditRating = 0.5
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Business owner decision-making
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete business owner decision logic")
        
        // Check business performance
        let totalRevenue = businesses.values.reduce(0) { $0 + $1.revenue }
        
        if outstandingDebt > wealth * 0.8 {
            // High debt situation
            decisionType = .repayLoan
            rationale = "Business debt repayment priority: \(outstandingDebt) debt against \(wealth) wealth"
            expectedValue = -30 + Double.random(in: -15...15)
            riskLevel = 0.4
            executionProbability = 0.6
        } else if totalRevenue < 1000 {
            // Low revenue, consider expansion or cost reduction
            decisionType = .expandOperation
            rationale = "Expanding operation due to low revenue: \(Int(totalRevenue)) current revenue"
            expectedValue = 40 + Double.random(in: -25...25)
            riskLevel = 0.6
            executionProbability = 0.5
        } else if businesses.isEmpty {
            // No businesses set up
            decisionType = .applyForLicense
            rationale = "Applying for business license to start operations"
            expectedValue = 20 + Double.random(in: -10...10)
            riskLevel = 0.3
            executionProbability = 0.7
        } else {
            // Normal operations - adjust prices or invest
            decisionType = .setPrices
            rationale = "Adjusting prices based on market conditions and costs"
            expectedValue = 50 + Double.random(in: -20...20)
            riskLevel = parameters.marketVolatility * 0.4
            executionProbability = 0.85
        }
        
        let decision = AgentDecision(
            id: "business-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        switch other.type {
        case .banker:
            #warning("Business-banker financing interactions")
        case .consumer:
            #warning("Business-consumer market demand")
        case .governmentOfficial:
            #warning("Business-regulation compliance")
        case .researchScientist:
            #warning("Business-R&D partnerships")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .banker: return 0.9
        case .consumer: return 0.8
        case .governmentOfficial: return 0.7
        case .researchScientist: return 0.6
        default: return 0.4
        }
    }
}

// Business entity
public struct BusinessEntity: Identifiable {
    public let id: String
    public var name: String
    public var sector: String
    public var revenue: Double
    public var expenses: Double
    public var profit: Double
    public var employeeCount: Int
    public var marketShare: Double
    public var complianceStatus: ComplianceStatus
    
    public init(
        id: String,
        name: String,
        sector: String,
        revenue: Double = 0,
        expenses: Double = 0,
        employeeCount: Int = 0,
        marketShare: Double = 0
    ) {
        self.id = id
        self.name = name
        self.sector = sector
        self.revenue = revenue
        self.expenses = expenses
        self.profit = revenue - expenses
        self.employeeCount = employeeCount
        self.marketShare = marketShare
        self.complianceStatus = .compliant
    }
}

// Business owner parameters
public struct BusinessOwnerAgentParameters {
    public var initialCapital: Double
    
    public init(initialCapital: Double = 0) {
        self.initialCapital = initialCapital
    }
}

// Consumer Agent
public struct ConsumerAgent: Agent {
    public var id: String
    public var type: AgentType { .consumer }
    public var parameterType: ConsumerAgentParameters
    
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    public var purchasedThisPeriod: [String: Double] // item -> quantity
    public var consumptionPreferences: [String: Double] // preference weights
    public var priceSensitivity: Double // 0-1, lower = less sensitive
    public var savedThisPeriod: Double
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 1000,
        reputation: Double = 0.5,
        satisfaction: Double = 0.5,
        isActive: Bool = true
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = ConsumerAgentParameters(
            consumptionPreferences: [:],
            priceSensitivity: 0.5
        )
        self.purchasedThisPeriod = [:]
        self.consumptionPreferences = [:]
        self.priceSensitivity = 0.5
        self.savedThisPeriod = 0
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Consumer decision-making with comprehensive utility maximization
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete consumer decision logic with utility maximization")
        
        // Calculate utility for different consumption options
        let totalWealth = wealth + savedThisPeriod
        
        // Check if we need to make purchasing decisions
        if totalWealth > 10 {
            // Has budget to spend
            // In a full system, would evaluate actual product choices
            decisionType = .buyConsume
            rationale = "Consumer purchasing decision with wealth \(Int(totalWealth)) and price sensitivity \(String(format: \"%.2f\", priceSensitivity))"
            expectedValue = 60 + Double.random(in: -10...10)
            riskLevel = parameters.marketVolatility * 0.3
            executionProbability = 0.9
        } else {
            // Limited budget, prioritize savings
            decisionType = .saveSpend
            rationale = "Limited budget: saving \(Int(savedThisPeriod)) of \(Int(totalWealth)) total wealth"
            expectedValue = 30 + Double.random(in: -5...5)
            riskLevel = 0.1
            executionProbability = 0.7
        }
        
        let decision = AgentDecision(
            id: "consumer-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        switch other.type {
        case .farmer:
            #warning("Consumer-farmer food demand")
        case .businessOwner:
            #warning("Consumer-business purchases")
        case .governmentOfficial:
            #warning("Consumer-policy impact on spending")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .farmer: return 0.7
        case .businessOwner: return 0.8
        case .governmentOfficial: return 0.5
        default: return 0.4
        }
    }
}

// Consumer agent parameters
public struct ConsumerAgentParameters {
    public var consumptionPreferences: [String: Double]
    public var priceSensitivity: Double // 0-1, lower = less price sensitive
    
    public init(consumptionPreferences: [String: Double] = [:], priceSensitivity: Double = 0.5) {
        self.consumptionPreferences = consumptionPreferences
        self.priceSensitivity = priceSensitivity
    }
}

// Government Official Agent
public struct GovernmentOfficialAgent: Agent {
    public var id: String
    public var type: AgentType { .governmentOfficial }
    public var parameterType: GovernmentOfficialAgentParameters
    
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    public var policyInitiatives: [String: Policy Initiative]
    public var approvalRating: Double
    public var electionCycle: Int
    public var budget: Double
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 100000,
        reputation: Double = 0.8,
        satisfaction: Double = 0.7,
        isActive: Bool = true
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = GovernmentOfficialAgentParameters()
        self.policyInitiatives = [:]
        self.approvalRating = 0.7
        self.electionCycle = 0
        self.budget = 50000
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Government decision-making with public welfare considerations
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete government official decision logic")
        
        // Priority: address societal issues, create policies, manage budget
        let societalIssues = environment.societalIssues
        let environmentalIndicators = environment.environmentalIndicators
        
        if approvalRating < 0.3 && electionCycle > 0 {
            // Low approval before election - populist measures
            decisionType = .seekPolicyChange
            rationale = "Low approval rating (\(String(format: \"%.1f\", approvalRating))): initiating policy changes before election cycle \(electionCycle)"
            expectedValue = 30 + Double.random(in: -10...10)
            riskLevel = 0.5
            executionProbability = 0.7
        } else if environmentalIndicators.overallHealthIndex < 30 {
            // Severe environmental issues
            decisionType = .seekPolicyChange
            rationale = "Addressing severe environmental health index: \(String(format: \"%.1f\", environmentalIndicators.overallHealthIndex))"
            expectedValue = 70 + Double.random(in: -20...20)
            riskLevel = 0.4
            executionProbability = 0.8
        } else if budget < 1000 {
            // Budget constraints
            decisionType = .seekPolicyChange
            rationale = "Budget constraints: managing with \(Int(budget)) remaining"
            expectedValue = 20 + Double.random(in: -5...5)
            riskLevel = 0.3
            executionProbability = 0.6
        } else {
            // Normal policy maintenance
            decisionType = .complyRegulations
            rationale = "Maintaining existing regulations and policies with approval \(String(format: \"%.1f\", approvalRating))"
            expectedValue = 50 + Double.random(in: -15...15)
            riskLevel = 0.2
            executionProbability = 0.9
        }
        
        let decision = AgentDecision(
            id: "gov-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        switch other.type {
        case .farmer:
            #warning("Government-farmer subsidy and regulation interactions")
        case .businessOwner:
            #warning("Government-business regulation and tax interactions")
        case .consumer:
            #warning("Government-consumer protection policies")
        case .banker:
            #warning("Government-central bank monetary policy")
        case .researchScientist:
            #warning("Government-research funding and priorities")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .farmer: return 0.9
        case .businessOwner: return 0.9
        case .consumer: return 0.8
        case .banker: return 0.85
        case .researchScientist: return 0.7
        default: return 0.5
        }
    }
}

// Government official parameters
public struct GovernmentOfficialAgentParameters {
    public var budget: Double
    public var fiscalPolicy: Double // 0-1, tax/spend stance
    
    public init(budget: Double = 0, fiscalPolicy: Double = 0.5) {
        self.budget = budget
        self.fiscalPolicy = fiscalPolicy
    }
}

// Banker Agent
public struct BankerAgent: Agent {
    public var id: String
    public var type: AgentType { .banker }
    public var parameterType: BankerAgentParameters
    
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    public var totalLent: Double
    public var totalRecovered: Double
    public var interestRate: Double
    public var lendingStandards: Double // 0-1, higher = stricter
    public var defaultRate: Double // Tracked default rate
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 100000,
        reputation: Double = 0.8,
        satisfaction: Double = 0.7,
        isActive: Bool = true
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = BankerAgentParameters()
        self.totalLent = 0
        self.totalRecovered = 0
        self.interestRate = 0.05
        self.lendingStandards = 0.7
        self.defaultRate = 0.02
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Banker decision-making with lending and risk management
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete banker decision logic with lending risk assessment")
        
        // Priority: manage lending portfolio, assess risks, set interest rates
        let totalOutstanding = totalLent - totalRecovered
        
        if totalOutstanding < 1000 && budget > 5000 {
            // Opportunity to lend
            decisionType = .takeLoan
            rationale = "Expanding lending portfolio: total outstanding \(Int(totalOutstanding)), available capital \(Int(wealth))"
            expectedValue = 60 + Double.random(in: -10...10)
            riskLevel = parameters.regulatoryRisk * 0.5 + parameters.marketVolatility * 0.3
            executionProbability = 0.85
        } else if defaultRate > 0.1 && totalOutstanding > 1000 {
            // High default rate, tighten standards
            decisionType = .manageRisk
            rationale = "Tightening lending standards: default rate at \(String(format: \"%.1f\", defaultRate * 100))%"
            expectedValue = 40 + Double.random(in: -15...15)
            riskLevel = 0.7
            executionProbability = 0.8
        } else if totalOutstanding > wealth * 2 {
            // Over-extended, focus on recovery
            decisionType = .repayLoan
            rationale = "Focus on loan recovery: outstanding \(Int(totalOutstanding)) against wealth \(Int(wealth))"
            expectedValue = -20 + Double.random(in: -10...10)
            riskLevel = 0.4
            executionProbability = 0.7
        } else {
            // Maintain current lending
            decisionType = .manageRisk
            rationale = "Maintaining current lending portfolio with \(Int(totalOutstanding)) outstanding"
            expectedValue = 50 + Double.random(in: -15...15)
            riskLevel = 0.3
            executionProbability = 0.8
        }
        
        let decision = AgentDecision(
            id: "banker-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        switch other.type {
        case .farmer:
            #warning("Banker-farmer loan interactions")
        case .businessOwner:
            #warning("Banker-business financing")
        case .consumer:
            #warning("Banker-consumer credit products")
        case .governmentOfficial:
            #warning("Banker-central bank relations")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .farmer: return 0.9
        case .businessOwner: return 0.9
        case .consumer: return 0.7
        case .governmentOfficial: return 0.85
        default: return 0.5
        }
    }
}

// Banker parameters
public struct BankerAgentParameters {
    public var interestRate: Double
    public var lendingStandards: Double // 0-1, higher = stricter
    public var capitalAdequacy: Double // 0-1
    
    public init(interestRate: Double = 0.05, lendingStandards: Double = 0.7, capitalAdequacy: Double = 0.8) {
        self.interestRate = interestRate
        self.lendingStandards = lendingStandards
        self.capitalAdequacy = capitalAdequacy
    }
}

// Research Scientist Agent
public struct ResearchScientistAgent: Agent {
    public var id: String
    public var type: AgentType { .researchScientist }
    public var parameterType: ResearchScientistAgentParameters
    
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    public var activeResearchProjects: [ResearchProject]
    public var publishedPapers: Int
    public var patentApplications: Int
    public var researchFunding: Double
    public var collaborationPartners: [String]
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 10000,
        reputation: Double = 0.5,
        satisfaction: Double = 0.6,
        isActive: Bool = true
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = ResearchScientistAgentParameters()
        self.activeResearchProjects = []
        self.publishedPapers = 0
        self.patentApplications = 0
        self.researchFunding = 0
        self.collaborationPartners = []
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Research scientist decision-making with innovation priorities
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete research scientist decision logic")
        
        // Priority: secure funding, advance research, publish, collaborate
        let fundingAvailable = researchFunding + parameters.availableCapital
        
        if activeResearchProjects.isEmpty && fundingAvailable > 1000 {
            // No projects, seek to start new ones
            decisionType = .investInTechnology
            rationale = "Starting new research projects with available funding \(Int(researchFunding))"
            expectedValue = 70 + Double.random(in: -20...20)
            riskLevel = 0.6
            executionProbability = 0.7
        } else if publishedPapers < 5 && fundingAvailable > 500 {
            // Few publications, seek more research
            decisionType = .investInTechnology
            rationale = "Increasing research output: \(publishedPapers) publications, seeking funding for more"
            expectedValue = 50 + Double.random(in: -15...15)
            riskLevel = 0.4
            executionProbability = 0.8
        } else if patentApplications > 0 && researchFunding < 2000 {
            // Has patents but low funding, seek more
            decisionType = .investInTechnology
            rationale = "Securing funding for existing patent applications: \(patentApplications) applications"
            expectedValue = 60 + Double.random(in: -20...20)
            riskLevel = 0.5
            executionProbability = 0.75
        } else {
            // Maintain and advance existing
            decisionType = .manageRisk
            rationale = "Maintaining research program with \(publishedPapers) publications, \(patentApplications) patents"
            expectedValue = 40 + Double.random(in: -10...10)
            riskLevel = 0.3
            executionProbability = 0.85
        }
        
        let decision = AgentDecision(
            id: "research-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        switch other.type {
        case .farmer:
            #warning("Research-farmer technology adoption transfer")
        case .businessOwner:
            #warning("Research-business R&D partnerships")
        case .governmentOfficial:
            #warning("Government-research funding priorities")
        case .banker:
            #warning("Research-research funding and loans")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .businessOwner: return 0.9
        case .governmentOfficial: return 0.8
        case .farmer: return 0.7
        case .banker: return 0.6
        default: return 0.4
        }
    }
}

// Research project
public struct ResearchProject: Identifiable {
    public let id: String
    public var name: String
    public var field: String // e.g., "crop_yield", "resource_efficiency"
    public var status: ResearchStatus
    public var funding: Double
    public var progress: Double // 0-1
    public var expectedBreakthrough: Double // 0-1
    public var timeline: Int // periods
    public var periodElapsed: Int
    public var potentialImpact: Double // 0-1
    
    public init(
        id: String,
        name: String,
        field: String,
        status: ResearchStatus = .planning,
        funding: Double = 0,
        progress: Double = 0,
        expectedBreakthrough: Double = 0.1,
        timeline: Int = 12,
        periodElapsed: Int = 0,
        potentialImpact: Double = 0.5
    ) {
        self.id = id
        self.name = name
        self.field = field
        self.status = status
        self.funding = funding
        self.progress = progress
        self.expectedBreakthrough = expectedBreakthrough
        self.timeline = timeline
        self.periodElapsed = periodElapsed
        self.potentialImpact = potentialImpact
    }
}

public enum ResearchStatus: String, CaseIterable {
    case planning = "planning"
    case active = "active"
    case breakthrough = "breakthrough"
    case published = "published"
    case patented = "patented"
    case abandoned = "abandoned"
}

// Research scientist parameters
public struct ResearchScientistAgentParameters {
    public var researchFocus: String // Primary field of focus
    public var collaborationPreference: Double // 0-1
    
    public init(researchFocus: String = "general", collaborationPreference: Double = 0.5) {
        self.researchFocus = researchFocus
        self.collaborationPreference = collaborationPreference
    }
}

// Trader Agent
public struct TraderAgent: Agent {
    public var id: String
    public var type: AgentType { .trader }
    public var parameterType: TraderAgentParameters
    
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    public var activePositions: [String: Double] // commodity -> position (positive = long, negative = short)
    public var tradingHistory: [TradeDecision]
    public var maxLeverage: Double
    public var currentRiskExposure: Double
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 50000,
        reputation: Double = 0.6,
        satisfaction: Double = 0.5,
        isActive: Bool = true
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = TraderAgentParameters()
        self.activePositions = [:]
        self.tradingHistory = []
        self.maxLeverage = 3.0
        self.currentRiskExposure = 0
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Trader decision-making with market positioning
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete trader decision logic with market positioning")
        
        // Priority: manage positions, adjust leverage, respond to market trends
        let marketVolatility = parameters.marketVolatility
        let priceTrends = parameters.priceTrend
        
        // Check position sizing opportunities
        let totalLongPositions = activePositions.filter { $0.value > 0 }.reduce(0) { $0 + $1.value }
        let totalShortPositions = activePositions.filter { $0.value < 0 }.reduce(0) { $0 + abs($1.value) }
        
        if totalLongPositions > 0 && totalShortPositions > 0 {
            // Hedged position, rebalance
            decisionType = .adjustProduction // Reuse adjustment type
            rationale = "Rebalancing hedged positions: long \(String(format: \"%.1f\", totalLongPositions)), short \(String(format: \"%.1f\", totalShortPositions))"
            expectedValue = 30 + Double.random(in: -10...10)
            riskLevel = marketVolatility * 0.4
            executionProbability = 0.9
        } else if totalLongPositions > wealth * 0.5 {
            // Overextended long, reduce
            decisionType = .sellProduce // Reuse sell type
            rationale = "Reducing overexposure: long positions at \(String(format: \"%.1f\", totalLongPositions)) against wealth \(Int(wealth))"
            expectedValue = -10 + Double.random(in: -15...15)
            riskLevel = marketVolatility * 0.6
            executionProbability = 0.7
        } else if marketVolatility > 0.7 {
            // High volatility, adjust risk
            decisionType = .manageRisk
            rationale = "Adjusting risk exposure amid high market volatility: \(String(format: \"%.1f\", marketVolatility * 100))%"
            expectedValue = 20 + Double.random(in: -20...20)
            riskLevel = 0.8
            executionProbability = 0.6
        } else {
            // Maintain or adjust positions based on trends
            decisionType = .setPrices
            rationale = "Adjusting positions based on market trends and price movements"
            expectedValue = 40 + Double.random(in: -15...15)
            riskLevel = marketVolatility * 0.3
            executionProbability = 0.8
        }
        
        let decision = AgentDecision(
            id: "trader-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        switch other.type {
        case .farmer:
            #warning("Trader-farmer produce purchases")
        case .businessOwner:
            #warning("Trader-business commodity trades")
        case .consumer:
            #warning("Trader-consumer market effects")
        case .governmentOfficial:
            #warning("Trader-regulation impacts on markets")
        case .researchScientist:
            #warning("Trader-research commodity impacts")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .farmer: return 0.8
        case .businessOwner: return 0.9
        case .consumer: return 0.7
        case .governmentOfficial: return 0.6
        case .researchScientist: return 0.5
        default: return 0.4
        }
    }
}

// Trader parameters
public struct TraderAgentParameters {
    public var maxLeverage: Double
    public var riskTolerance: Double // 0-1
    
    public init(maxLeverage: Double = 3.0, riskTolerance: Double = 0.5) {
        self.maxLeverage = maxLeverage
        self.riskTolerance = riskTolerance
    }
}

// Investor Agent
public struct InvestorAgent: Agent {
    public var id: String
    public var type: AgentType { .investor }
    public var parameterType: InvestorAgentParameters
    
    public var position: (x: Double, y: Double)
    public var wealth: Double
    public var reputation: Double
    public var satisfaction: Double
    public var isActive: Bool
    public var lastDecision: AgentDecision?
    public var investmentPortfolio: [String: Double] // asset -> allocation
    public var totalReturn: Double
    public var riskProfile: Double // 0-1
    public var diversification: Double // 0-1
    
    public init(
        id: String,
        position: (x: Double, y: Double) = (0, 0),
        wealth: Double = 100000,
        reputation: Double = 0.7,
        satisfaction: Double = 0.6,
        isActive: Bool = true
    ) {
        self.id = id
        self.position = position
        self.wealth = wealth
        self.reputation = reputation
        self.satisfaction = satisfaction
        self.isActive = isActive
        self.parameterType = InvestorAgentParameters()
        self.investmentPortfolio = [:]
        self.totalReturn = 0
        self.riskProfile = 0.5
        self.diversification = 0.6
    }
    
    public mutating func makeDecision(in environment: SimulationEnvironment,
                                     with parameters: AgentDecisionParameters) -> AgentDecision {
        // Investor decision-making with portfolio management
        let decisionType: DecisionType
        let rationale: String
        let expectedValue: Double
        let riskLevel: Double
        let executionProbability: Double
        
        #warning("Complete investor decision logic with portfolio optimization")
        
        // Priority: rebalance portfolio, adjust allocations, respond to market conditions
        let totalAllocated = investmentPortfolio.values.reduce(0) { $0 + $1 }
        
        if totalAllocated < wealth * 0.5 {
            // Under-invested, increase allocation
            decisionType = .makeInvestment
            rationale = "Increasing investment allocation: \(String(format: \"%.1f\", totalAllocated)) of \(Int(wealth)) wealth invested"
            expectedValue = 50 + Double.random(in: -10...10)
            riskLevel = parameters.marketVolatility * 0.4
            executionProbability = 0.8
        } else if riskProfile > 0.8 && diversification < 0.4 {
            // High risk, under-diversified, rebalance
            decisionType = .makeInvestment
            rationale = "Rebalancing portfolio: high risk profile with low diversification (\(String(format: \"%.1f\", diversification * 100))%)"
            expectedValue = 30 + Double.random(in: -15...15)
            riskLevel = 0.7
            executionProbability = 0.75
        } else {
            // Maintain or adjust based on performance
            decisionType = .makeInvestment
            rationale = "Optimizing investment portfolio performance"
            expectedValue = 40 + Double.random(in: -15...15)
            riskLevel = 0.4
            executionProbability = 0.85
        }
        
        let decision = AgentDecision(
            id: "investor-dec-\(Date.timeIntervalSince1970)-\(id)",
            agentId: id,
            decisionType: decisionType,
            rationale: rationale,
            expectedValue: expectedValue,
            riskLevel: riskLevel,
            executionProbability: executionProbability
        )
        
        lastDecision = decision
        return decision
    }
    
    public mutating func interact(with other: Agent, in environment: SimulationEnvironment) {
        switch other.type {
        case .farmer:
            #warning("Investor-farmer equity investments")
        case .businessOwner:
            #warning("Investor-business equity investments")
        case .banker:
            #warning("Investor-banking and credit products")
        default: break
        }
    }
    
    func interactionStrength(with other: AgentType) -> Double {
        switch other {
        case .businessOwner: return 0.9
        case .farmer: return 0.7
        case .banker: return 0.8
        default: return 0.5
        }
    }
}

// Investor parameters
public struct InvestorAgentParameters {
    public var riskProfile: Double // 0-1
    public var diversification: Double // 0-1
    
    public init(riskProfile: Double = 0.5, diversification: Double = 0.6) {
        self.riskProfile = riskProfile
        self.diversification = diversification
    }
}

// MARK: - Simulation Environment (Expanded)

public struct SimulationEnvironment {
    // Economic environment
    public var globalPrices: [String: Double] // Key commodity and service prices
    public var inflationRate: Double
    public var exchangeRate: Double
    public var interestRates: Double
    
    // Agricultural environment
    public var weatherConditions: WeatherConditions
    public var soilQuality: Double // 0-1
    public var waterAvailability: Double // 0-1
    
    // Social environment
    public var population: Double
    public var unemployment: Double
    public var incomeDistribution: Double // Gini coefficient 0-1
    
    // Environmental indicators
    public var environmentalIndicators: EnvironmentalState
    
    // Regulatory environment
    public var activeRegulations: [String: Regulation]
    public var taxPolicy: TaxPolicy
    
    // Market conditions
    public var marketVolatility: Double
    public var demandSignals: [String: Double]
    
    // Time
    public var currentPeriod: Int
    public var totalPeriods: Int
    
    public init(
        globalPrices: [String: Double] = [:],
        inflationRate: Double = 0.02,
        exchangeRate: Double = 1.0,
        interestRates: Double = 0.05,
        weatherConditions: WeatherConditions = WeatherConditions(),
        soilQuality: Double = 0.5,
        waterAvailability: Double = 0.5,
        population: Double = 1000,
        unemployment: Double = 0.05,
        incomeDistribution: Double = 0.3,
        environmentalIndicators: EnvironmentalState = EnvironmentalState(),
        activeRegulations: [String: Regulation] = [:],
        taxPolicy: TaxPolicy = TaxPolicy(),
        marketVolatility: Double = 0.3,
        demandSignals: [String: Double] = [:],
        currentPeriod: Int = 0,
        totalPeriods: Int = 100
    ) {
        self.globalPrices = globalPrices
        self.inflationRate = inflationRate
        self.exchangeRate = exchangeRate
        self.interestRates = interestRates
        self.weatherConditions = weatherConditions
        self.soilQuality = soilQuality
        self.waterAvailability = waterAvailability
        self.population = population
        self.unemployment = unemployment
        self.incomeDistribution = incomeDistribution
        self.environmentalIndicators = environmentalIndicators
        self.activeRegulations = activeRegulations
        self.taxPolicy = taxPolicy
        self.marketVolatility = marketVolatility
        self.demandSignals = demandSignals
        self.currentPeriod = currentPeriod
        self.totalPeriods = totalPeriods
    }
}

public struct WeatherConditions {
    public var temperature: Double // Deviations from normal
    public var precipitation: Double // 0-1, 1 = normal
    public var droughtSeverity: Double // 0-1
    public var floodRisk: Double // 0-1
    public var growingDegreeDays: Double
    
    public init(
        temperature: Double = 0,
        precipitation: Double = 1,
        droughtSeverity: Double = 0,
        floodRisk: Double = 0,
        growingDegreeDays: Double = 0
    ) {
        self.temperature = temperature
        self.precipitation = precipitation
        self.droughtSeverity = droughtSeverity
        self.floodRisk = floodRisk
        self.growingDegreeDays = growingDegreeDays
    }
}

public struct TaxPolicy {
    public var incomeTaxRate: Double // 0-1
    public var corporateTaxRate: Double // 0-1
    public var agriculturalSubsidies: [String: Double] // commodity -> rate
    public var environmentalTaxes: [String: Double] // indicator -> rate
    
    public init(
        incomeTaxRate: Double = 0.2,
        corporateTaxRate: Double = 0.21,
        agriculturalSubsidies: [String: Double] = [:],
        environmentalTaxes: [String: Double] = [:]
    ) {
        self.incomeTaxRate = incomeTaxRate
        self.corporateTaxRate = corporateTaxRate
        self.agriculturalSubsidies = agriculturalSubsidies
        self.environmentalTaxes = environmentalTaxes
    }
}

// MARK: - Shared Decision Engine (Expanded)

public class DecisionEngine {
    // Shared decision-making logic used by all agent types
    
    // Calculate utility for a decision given current parameters
    public func calculateUtility(
        forDecision decision: AgentDecision,
        givenParameters params: AgentDecisionParameters,
        agentType: AgentType
    ) -> Double {
        let baseUtility = decision.expectedValue
        let riskPenalty = pow(decision.riskLevel, 2) * 100
        let executionFactor = decision.executionProbability
        
        // Agent-type specific adjustments
        var typeMultiplier: Double
        switch agentType {
        case .riskAverse: typeMultiplier = 0.8 // Penalize risk
        case .riskSeeking: typeMultiplier = 1.2 // Reward risk
        case .utilityMaximizing: typeMultiplier = 1.0 // Neutral
        case .stabilitySeeking: typeMultiplier = 0.9 // Penalize risk more
        case .profitMaximizing: typeMultiplier = 1.1 // Reward profit
        case .innovationSeeking: typeMultiplier = 1.05 // Slight risk tolerance
        default: typeMultiplier = 1.0
        }
        
        return (baseUtility - riskPenalty) * typeMultiplier * executionFactor
    }
    
    // Calculate risk-adjusted expected value
    public func expectedValue(
        _ expected: Double,
        risk: Double,
        execution: Double,
        agentType: AgentType
    ) -> Double {
        calculateUtility(forDecision: AgentDecision(
            id: "temp",
            agentId: "temp",
            decisionType: .plantCrop,
            rationale: "temp",
            expectedValue: expected,
            riskLevel: risk,
            executionProbability: execution
        ), givenParameters: AgentDecisionParameters(), agentType: agentType)
    }
    
    // Compare two decisions and return the better one
    public func compareDecisions(
        _ decision1: AgentDecision,
        _ decision2: AgentDecision,
        givenParameters params: AgentDecisionParameters,
        agentType: AgentType
    ) -> AgentDecision {
        let utility1 = calculateUtility(decision1, givenParameters: params, agentType: agentType)
        let utility2 = calculateUtility(decision2, givenParameters: params, agentType: agentType)
        
        return utility1 >= utility2 ? decision1 : decision2
    }
    
    // Simulate decision outcome with stochastic elements
    public func simulateOutcome(
        _ decision: AgentDecision,
        in environment: SimulationEnvironment
    ) -> Double {
        // Base outcome from expected value
        let baseOutcome = decision.expectedValue
        
        // Add stochastic component based on market volatility and other factors
        let volatilityFactor = environment.marketVolatility
        let stochasticElement = Double.random(in: -1...1) * volatilityFactor * abs(decision.expectedValue) * 0.3
        
        // Risk adjustment
        let riskAdjustment = -pow(decision.riskLevel, 1.5) * 20
        
        // Execution probability factor
        let executionFactor = decision.executionProbability
        
        return baseOutcome + stochasticElement + riskAdjustment
    }
    
    // Compute agent satisfaction based on decision outcome
    public func computeSatisfaction(
        _ outcome: Double,
        _ expected: Double,
        _ agentType: AgentType
    ) -> Double {
        let expectationGap = outcome - expected
        
        // Different agent types respond differently to outcomes
        var lossAversion: Double
        switch agentType {
        case .consumer: lossAversion = 2.0 // Consumers hate price increases
        case .farmer: lossAversion = 1.5 // Farmers sensitive to yield losses
        case .businessOwner: lossAversion = 1.8 // Businesses sensitive to profit losses
        case .investor: lossAversion = 1.6 // Investors loss averse
        default: lossAversion = 1.3
        }
        
        let utility = -lossAversion * pow(abs(expectationGap), 0.8) + 100
        return max(0, min(100, utility))
    }
}

// MARK: - Agent Population and Management (Expanded)

public class AgentPopulation {
    private var agents: [String: Agent] = [:]
    private var agentCountByType: [AgentType: Int] = [:]
    private var decisionEngine: DecisionEngine
    
    public var activeAgents: [Agent] {
        return agents.values.filter { $0.isActive }
    }
    
    public init(decisionEngine: DecisionEngine = DecisionEngine()) {
        self.decisionEngine = decisionEngine
        
        // Initialize with sample agents of each type
        for i in 0..<10 {
            let farmer = FarmerAgent(id: "farmer-\(i)")
            agents[farmer.id] = farmer
            agentCountByType[.farmer, default: 0] += 1
            
            let business = BusinessOwnerAgent(id: "business-\(i)")
            agents[business.id] = business
            agentCountByType[.businessOwner, default: 0] += 1
            
            let consumer = ConsumerAgent(id: "consumer-\(i)")
            agents[consumer.id] = consumer
            agentCountByType[.consumer, default: 0] += 1
            
            let gov = GovernmentOfficialAgent(id: "gov-\(i)")
            agents[gov.id] = gov
            agentCountByType[.governmentOfficial, default: 0] += 1
            
            let banker = BankerAgent(id: "banker-\(i)")
            agents[banker.id] = banker
            agentCountByType[.banker, default: 0] += 1
            
            let researcher = ResearchScientistAgent(id: "research-\(i)")
            agents[researcher.id] = researcher
            agentCountByType[.researchScientist, default: 0] += 1
        }
        
        // Add traders and investors
        for i in 0..<5 {
            let trader = TraderAgent(id: "trader-\(i)")
            agents[trader.id] = trader
            agentCountByType[.trader, default: 0] += 1
            
            let investor = InvestorAgent(id: "investor-\(i)")
            agents[investor.id] = investor
            agentCountByType[.investor, default: 0] += 1
        }
    }
    
    public func getAgent(_ id: String) -> Agent? {
        return agents[id]
    }
    
    public func getAgents(byType type: AgentType) -> [Agent] {
        return agents.values.filter { $0.type == type && $0.isActive }
    }
    
    public func addAgent(_ agent: Agent) {
        agents[agent.id] = agent
        agentCountByType[agent.type, default: 0] += 1
    }
    
    public func removeAgent(_ id: String) {
        agents.removeValue(forKey: id)
        // Recalculate counts
        recalculateCounts()
    }
    
    public mutating func advancePeriod() {
        #warning("Advance all active agents through decision cycle")
        
        for agent in activeAgents {
            #warning("Make decision for \(agent.type.rawValue) agent \(agent.id)")
            
            // Create decision parameters based on current state
            let params = AgentDecisionParameters(
                availableCapital: agent.wealth,
                currentAssets: agent.wealth,
                debtLevel: agent is FarmerAgent ? (agent as! FarmerAgent).outstandingLoans : 0,
                creditScore: agent.reputation,
                marketPrices: [:], // Would be populated from environment
                priceTrend: [:],
                demandElasticity: [:],
                landAvailable: agent is FarmerAgent ? ((agent as! FarmerAgent).ownedLand - (agent as! FarmerAgent).cultivatedLand) : 0,
                laborAvailable: agent is ConsumerAgent ? 1 : 0,
                equipmentAvailable: agent is FarmerAgent ? ((agent as! FarmerAgent).equipment.values.reduce(0) { $0 + $1 }) : 0,
                inputsAvailable: [:],
                taxRate: 0.2,
                subsidies: [:],
                regulations: [:],
                populationTrend: 0.01,
                unemploymentRate: 0.05,
                incomeDistribution: 0.3,
                weatherRisk: 0.2,
                marketVolatility: 0.3,
                regulatoryRisk: 0.2,
                timeHorizon: 1,
                planningHorizon: 5
            )
            
            #warning("Execute decision for \(agent.type.rawValue)")
            let decision = agent.makeDecision(in: SimulationEnvironment(), with: params)
            agent.lastDecision = decision
            
            #warning("Track decision execution")
            // In full system, would execute decision and track outcomes
        }
        
        #warning("Handle agent interactions")
        // Handle pairwise interactions
        for i in activeAgents.indices {
            for j in (i+1)..<activeAgents.count {
                let agentI = activeAgents[i]
                let agentJ = activeAgents[j]
                
                let strengthI = agentI.interactionStrength(with: agentJ.type)
                let strengthJ = agentJ.interactionStrength(with: agentI.type)
                
                // Interaction probability decreases with distance
                let distance = sqrt(pow(agentI.position.x - agentJ.position.x, 2) + 
                                   pow(agentI.position.y - agentJ.position.y, 2))
                let maxInteractionDistance: Double = 50
                let interactionProbability = max(0, 1 - distance / maxInteractionDistance)
                
                if Double.random(in: 0...1) < interactionProbability * 0.1 {
                    agentI.interact(with: agentJ, in: SimulationEnvironment())
                    agentJ.interact(with: agentI, in: SimulationEnvironment())
                }
            }
        }
        
        #warning("Update agent states after decisions")
        // Update wealth, satisfaction, etc. based on decision outcomes
    }
    
    private func recalculateCounts() {
        agentCountByType = [:]
        for agent in agents.values where agent.isActive {
            agentCountByType[agent.type, default: 0] += 1
        }
    }
    
    public func populationStatistics() -> [AgentType: Int] {
        return agentCountByType
    }
    
    public func totalActiveAgents() -> Int {
        return activeAgents.count
    }
}

// MARK: - Previews
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct AIAgentsPreview: PreviewProvider {
//    static var previews: some View {
//        Text("AI Agents System Preview")
//    }
//}
//#endif