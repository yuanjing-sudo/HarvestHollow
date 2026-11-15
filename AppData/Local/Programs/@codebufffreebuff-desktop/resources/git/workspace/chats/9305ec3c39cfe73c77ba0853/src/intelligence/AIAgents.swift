//
//  AIAgents.swift
//  Agricultural Economic Simulation
//

import Foundation

// AI Decision Framework components
public struct AIDecisionFramework {
    public var objectives: [String]
    public var availableResources: [String: Double]
    public var constraints: [String: Double]
    public var currentInformation: [String: Double]
    public var preferences: [String: Double]
    public var riskTolerance: Double
    public var decisionMakingRules: [String]
    public var memoryOfPreviousDecisions: [(decision: String, outcome: String, timestamp: Date)]
    public var expectedOutcomes: [String: Double]
    public var evaluationMethod: String
    
    public init(objectives: [String] = [], availableResources: [String: Double] = [:], constraints: [String: Double] = [:], currentInformation: [String: Double] = [:], preferences: [String: Double] = [:], riskTolerance: Double = 0.5, decisionMakingRules: [String] = [], memoryOfPreviousDecisions: [(decision: String, outcome: String, timestamp: Date)] = [], expectedOutcomes: [String: Double] = [:], evaluationMethod: String = "weighted_score") {
        self.objectives = objectives
        self.availableResources = availableResources
        self.constraints = constraints
        self.currentInformation = currentInformation
        self.preferences = preferences
        self.riskTolerance = riskTolerance
        self.decisionMakingRules = decisionMakingRules
        self.memoryOfPreviousDecisions = memoryOfPreviousDecisions
        self.expectedOutcomes = expectedOutcomes
        self.evaluationMethod = evaluationMethod
    }
}

// Base AI Agent
public protocol AIAgent {
    var id: String { get }
    var type: String { get }
    var objectives: [String] { get }
    var decisionFramework: AIDecisionFramework { get }
    var lastDecision: String? { get set }
    var decisionHistory: [(decision: String, outcome: String, timestamp: Date)] { get set }
    var memory: [String: Double] { get set }
    var riskTolerance: Double { get set }
    var performanceScore: Double { get set }
}

// Farmer AI - crop choices, planting, investment, resource allocation
public struct FarmerDecision {
    public var cropType: String
    public var areaToPlant: Double  // m²
    public var investment: Double
    public var resourceAllocation: [String: Double]  // ResourceType -> amount
    public var expectedRevenue: Double
    public var riskAssessment: Double  // 0-1
    
    public init(cropType: String, areaToPlant: Double, investment: Double, resourceAllocation: [String: Double] = [:], expectedRevenue: Double, riskAssessment: Double) {
        self.cropType = cropType
        self.areaToPlant = areaToPlant
        self.investment = investment
        self.resourceAllocation = resourceAllocation
        self.expectedRevenue = expectedRevenue
        self.riskAssessment = riskAssessment
    }
}

// Business AI - pricing, production, hiring, expansion
public struct BusinessDecision {
    public var pricing: Double  // price change percentage
    public var productionLevel: Double  // change percentage
    public var hiring: Double  // number to hire (positive) or fire (negative)
    public var expansion: Double  // investment amount
    public var marketEntry: Bool
    public var marketExit: Bool
    public var supplierSelection: String  // ResourceType
    
    public init(pricing: Double = 0, productionLevel: Double = 0, hiring: Double = 0, expansion: Double = 0, marketEntry: Bool = false, marketExit: Bool = false, supplierSelection: String = "water") {
        self.pricing = pricing
        self.productionLevel = productionLevel
        self.hiring = hiring
        self.expansion = expansion
        self.marketEntry = marketEntry
        self.marketExit = marketExit
        self.supplierSelection = supplierSelection
    }
}

// Consumer AI - purchasing, saving, preferences
public struct ConsumerDecision {
    public var purchases: [String: Double]  // ResourceType -> amount
    public var savings: Double
    public var spendingConfidence: Double  // 0-1
    public var priceSensitivity: Double  // 0-1
    public var qualityPreference: Double  // 0-1
    
    public init(purchases: [String: Double] = [:], savings: Double = 0, spendingConfidence: Double = 0.5, priceSensitivity: Double = 0.5, qualityPreference: Double = 0.5) {
        self.purchases = purchases
        self.savings = savings
        self.spendingConfidence = spendingConfidence
        self.priceSensitivity = priceSensitivity
        self.qualityPreference = qualityPreference
    }
}

// Government AI - policy selection, spending, economic priorities
public struct GovernmentDecision {
    public var policyPriorities: [String]
    public var spendingAllocations: [String: Double]  // area -> amount
    public var taxChanges: [String: Double]  // rate changes
    public var regulatoryActions: [String]
    public var infrastructureInvestment: Double
    public var monetaryPolicy: String
    
    public init(policyPriorities: [String] = [], spendingAllocations: [String: Double] = [:], taxChanges: [String: Double] = [:], regulatoryActions: [String] = [], infrastructureInvestment: Double = 0, monetaryPolicy: String = "neutral") {
        self.policyPriorities = policyPriorities
        self.spendingAllocations = spendingAllocations
        self.taxChanges = taxChanges
        self.regulatoryActions = regulatoryActions
        self.infrastructureInvestment = infrastructureInvestment
        self.monetaryPolicy = monetaryPolicy
    }
}

// Bank AI - credit evaluation, lending, risk management
public struct BankDecision {
    public var loanEvaluation: (borrowerRisk: Double, approved: Bool, interestRate: Double, loanAmount: Double)
    public var riskManagement: (portfolioRisk: Double, recommendedActions: [String])
    
    public init(borrowerRisk: Double, approved: Bool, interestRate: Double, loanAmount: Double, portfolioRisk: Double, recommendedActions: [String]) {
        self.loanEvaluation = (borrowerRisk, approved, interestRate, loanAmount)
        self.riskManagement = (portfolioRisk, recommendedActions)
    }
}

// Research AI - research priorities and technological adoption
public struct ResearchDecision {
    public var researchPriorities: [String]  // ResearchArea
    public var technologyAdoption: (area: String, adopt: Bool, timing: Int)[]
    public var fundingAllocation: [String: Double]
    
    public init(researchPriorities: [String] = [], technologyAdoption: [(area: String, adopt: Bool, timing: Int)] = [], fundingAllocation: [String: Double] = [:]) {
        self.researchPriorities = researchPriorities
        self.technologyAdoption = technologyAdoption
        self.fundingAllocation = fundingAllocation
    }
}

// Shared decision engine
public class DecisionEngine {
    public func evaluateOptions(options: [(id: String, score: Double, risk: Double, alignment: Double)]) -> String {
        options.sorted { a, b in
            let scoreDiff = b.score - a.score
            let riskDiff = a.risk - b.risk  // Lower risk is better
            let alignmentDiff = b.alignment - a.alignment
            return scoreDiff != 0 ? scoreDiff : riskDiff != 0 ? riskDiff : alignmentDiff
        }.first?.id ?? ""
    }
    
    public func calculateAlignment(_ objective: String, context: [String: Double]) -> Double {
        0.5  // Neutral base alignment
    }
    
    public func calculateRisk(_ decision: String, context: [String: Double]) -> Double {
        let uncertainty = context["uncertainty"] ?? 0.5
        return uncertainty
    }
    
    public func makeDecision(agent: any AIAgent, options: [(id: String, description: String)]) -> String {
        let evaluatedOptions = options.map { option in
            (
                id: option.id,
                score: calculateAlignment(option.id, agent.decisionFramework.currentInformation),
                risk: calculateRisk(option.id, agent.decisionFramework.currentInformation),
                alignment: calculateAlignment(option.id, agent.decisionFramework.currentInformation)
            )
        }
        
        return evaluateOptions(options: evaluatedOptions)
    }
}

// Farmer AI implementation
public class FarmerAI {
    private let decisionEngine = DecisionEngine()
    
    public func makeFarmerDecision(currentCrops: [String: Double], soilFactors: [String: Double], marketPrices: [String: Double], resources: [String: Double], farmerObj: AIDecisionFramework) -> FarmerDecision {
        var options: [(id: String, description: String, score: Double, risk: Double, alignment: Double)] = []
        
        // Option 1: Continue current crops
        let currentBest = findBestCrop(currentCrops, soilFactors, marketPrices)
        options.append(("continue_current", "Continue planting \(currentBest.cropType)", 
            decisionEngine.calculateAlignment("continue_current", farmerObj.currentInformation), 0.2, 0.8))
        
        // Option 2: Switch to better crop
        let switchOption = evaluateSwitchCrop(currentCrops, soilFactors, marketPrices)
        options.append(("switch_crop", "Switch to \(switchOption.betterCrop)", 
            switchOption.score, switchOption.risk, switchOption.alignment))
        
        // Option 3: Invest in improvements
        options.append(("invest_improvements", "Invest in soil improvements and irrigation",
            decisionEngine.calculateAlignment("invest_improvements", farmerObj.currentInformation), 0.3, 0.6))
        
        // Option 4: Diversify
        options.append(("diversify", "Plant mixed crops to spread risk",
            decisionEngine.calculateAlignment("diversify", farmerObj.currentInformation), 0.1, 0.7))
        
        let chosenId = decisionEngine.makeDecision(agent: FarmerAIAgent(), options: options.map { ($0.id, $0.description) })
        
        switch chosenId {
        case "continue_current":
            return FarmerDecision(
                cropType: currentBest.cropType,
                areaToPlant: (currentCrops.values.reduce(0, +) ?? 1) * 1.01,
                investment: 0,
                resourceAllocation: allocateResources(currentBest.cropType, soilFactors),
                expectedRevenue: estimateRevenue(currentBest.cropType, marketPrices),
                riskAssessment: 0.2
            )
        case "switch_crop":
            return FarmerDecision(
                cropType: switchOption.betterCrop,
                areaToPlant: (currentCrops.values.reduce(0, +) ?? 1) * 0.8,
                investment: 0,
                resourceAllocation: allocateResources(switchOption.betterCrop, soilFactors),
                expectedRevenue: estimateRevenue(switchOption.betterCrop, marketPrices),
                riskAssessment: switchOption.risk
            )
        case "invest_improvements":
            return FarmerDecision(
                cropType: currentCrops.keys.first ?? "wheat",
                areaToPlant: currentCrops.values.reduce(0, +) ?? 100,
                investment: 5000,
                resourceAllocation: allocateResourcesForImprovements(soilFactors),
                expectedRevenue: 0,
                riskAssessment: 0.3
            )
        case "diversify":
            return FarmerDecision(
                cropType: selectDiverseCrop(currentCrops, soilFactors),
                areaToPlant: 20,
                investment: 0,
                resourceAllocation: allocateResourcesForDiversification(soilFactors),
                expectedRevenue: 0,
                riskAssessment: 0.1
            )
        default:
            return FarmerDecision(cropType: "wheat", areaToPlant: 50, investment: 0, expectedRevenue: 500, riskAssessment: 0.3)
        }
    }
    
    private func findBestCrop(_ currentCrops: [String: Double], _ soilFactors: [String: Double], _ marketPrices: [String: Double]) -> (cropType: String, score: Double) {
        var cropScores: [(String, Double)] = []
        
        for crop in ["wheat", "corn", "potato", "tomato", "lettuce"] {
            var score: Double = 0
            let price = marketPrices[crop] ?? 100
            score += price * 0.5
            
            let nitrogen = soilFactors["nitrogen"] ?? 50
            let phosphorus = soilFactors["phosphorus"] ?? 50
            let potassium = soilFactors["potassium"] ?? 50
            
            if crop == "wheat" { score += (nitrogen + phosphorus) * 0.1 }
            if crop == "corn" { score += nitrogen * 0.15 }
            if crop == "potato" { score += (nitrogen + potassium) * 0.1 }
            if crop == "tomato" { score += (phosphorus + potassium) * 0.12 }
            if crop == "lettuce" { score += nitrogen * 0.1 }
            
            cropScores.append((crop, score))
        }
        
        return cropScores.reduce((currentBest: cropScores[0].0, score: cropScores[0].1)) { $0.score > $1.score ? $0 : $1 }
    }
    
    private func evaluateSwitchCrop(_ currentCrops: [String: Double], _ soilFactors: [String: Double], _ marketPrices: [String: Double]) -> (betterCrop: String, score: Double, risk: Double, alignment: Double) {
        let currentWorst = findWorstCrop(currentCrops, marketPrices)
        let alternatives = ["wheat", "corn", "potato", "tomato", "lettuce"].filter { $0 != currentWorst.cropType }
        
        guard let bestAlternative = alternatives.first else { return ("wheat", 0, 0.3, 0.7) }
        let price = marketPrices[bestAlternative] ?? 100
        let score = price * 0.5
        
        return (bestAlternative, score, 0.3, 0.7)
    }
    
    private func findWorstCrop(_ currentCrops: [String: Double], _ marketPrices: [String: Double]) -> (cropType: String, score: Double) {
        var cropScores: [(String, Double)] = []
        
        for crop in currentCrops.keys {
            let price = marketPrices[crop] ?? 100
            cropScores.append((crop, price))
        }
        
        return cropScores.reduce((currentWorst: cropScores[0].0, score: cropScores[0].1)) { $0.score < $1.score ? $0 : $1 }
    }
    
    private func selectDiverseCrop(_ currentCrops: [String: Double], _ soilFactors: [String: Double]) -> String {
        let currentlyPlanted = Array(currentCrops.keys)
        let alternatives = ["wheat", "corn", "potato", "tomato", "lettuce"].filter { !currentlyPlanted.contains($0) }
        return alternatives.isEmpty ? "wheat" : alternatives[0]
    }
    
    private func allocateResources(_ cropType: String, _ soilFactors: [String: Double]) -> [String: Double] {
        var resources: [String: Double] = [:]
        
        let baseNeeds: [String: [String: Double]] = [
            "wheat": ["fertiliser": 10, "water": 30, "electricity": 2],
            "corn": ["fertiliser": 15, "water": 40, "electricity": 3],
            "potato": ["fertiliser": 12, "water": 35, "electricity": 2],
            "tomato": ["fertiliser": 15, "water": 45, "electricity": 3],
            "lettuce": ["fertiliser": 8, "water": 25, "electricity": 1]
        ]
        
        if let needs = baseNeeds[cropType] {
            resources = needs
        }
        
        let nitrogen = soilFactors["nitrogen"] ?? 50
        if nitrogen > 70 {
            resources = Dictionary(uniqueKeysWithValues: resources.map { key, value in
                if key == "fertiliser" { return (key, value * 0.8) }
                else { return (key, value) }
            })
        }
        
        return resources
    }
    
    private func allocateResourcesForImprovements(_ soilFactors: [String: Double]) -> [String: Double] { allocateResources("wheat", soilFactors) }
    private func allocateResourcesForDiversification(_ soilFactors: [String: Double]) -> [String: Double] { [:].merging(["fertiliser": 10, "water": 30]) { $1 }}
    
    private func estimateRevenue(_ cropType: String, _ marketPrices: [String: Double]) -> Double {
        let price = marketPrices[cropType] ?? 100
        return price * 10
    }
}

// Helper struct for switch crop evaluation
private struct SwitchCropEvaluation {
    var betterCrop: String
    var score: Double
    var risk: Double
    var alignment: Double
}

// Business AI implementation
public class BusinessAI {
    private let decisionEngine = DecisionEngine()
    
    public func makeBusinessDecision(business: (id: String, industry: String, employees: Int, revenue: Double, profit: Double, marketShare: Double, creditworthiness: Double), 
                                    marketData: (commodityPrices: [String: Double], wageRate: Double, inflationRate: Double, demandIndicators: [String: Double]),
                                    businessObj: AIDecisionFramework) -> BusinessDecision {
        var options: [(id: String, description: String, score: Double, risk: Double, alignment: Double)] = []
        
        options.append(("adjust_prices", "Adjust prices based on cost pressures and demand",
            decisionEngine.calculateAlignment("adjust_prices", businessObj.currentInformation), 0.2, 0.7))
        options.append(("expand_production", "Increase production capacity",
            decisionEngine.calculateAlignment("expand_production", businessObj.currentInformation), 0.3, 0.6))
        options.append(("hire_workers", "Hire additional workers",
            decisionEngine.calculateAlignment("hire_workers", businessObj.currentInformation), 0.2, 0.5))
        options.append(("reduce_costs", "Implement cost-cutting measures",
            decisionEngine.calculateAlignment("reduce_costs", businessObj.currentInformation), 0.1, 0.8))
        options.append(("borrow_expansion", "Take on debt for expansion",
            decisionEngine.calculateAlignment("borrow_expansion", businessObj.currentInformation), 0.4, 0.5))
        
        let chosenId = decisionEngine.makeDecision(agent: BusinessAIAgent(), options: options.map { ($0.id, $0.description) })
        
        switch chosenId {
        case "adjust_prices": return BusinessDecision(pricing: 5, productionLevel: 0, hiring: 0, expansion: 0)
        case "expand_production": return BusinessDecision(pricing: 0, productionLevel: 10, hiring: 2, expansion: 1000)
        case "hire_workers": return BusinessDecision(pricing: 0, productionLevel: 0, hiring: 3, expansion: 0)
        case "reduce_costs": return BusinessDecision(pricing: -3, productionLevel: -5, hiring: -1, expansion: 0)
        case "borrow_expansion": return BusinessDecision(pricing: 2, productionLevel: 0, hiring: 1, expansion: 2000)
        default: return BusinessDecision()
        }
    }
}

// Consumer AI implementation
public class ConsumerAI {
    private let decisionEngine = DecisionEngine()
    
    public func makeConsumerDecision(household: (id: String, income: Double, savings: Double, debt: Double, employmentStatus: String, householdClass: String), 
                                    marketConditions: (priceLevels: [String: Double], incomeLevels: [String: Double]),
                                    consumerObj: AIDecisionFramework) -> ConsumerDecision {
        let disposableIncome = household.income - household.debt * 0.02
        let spendBudget = max(0, disposableIncome * 0.8)
        
        var options: [(id: String, description: String, score: Double, risk: Double, alignment: Double)] = []
        
        options.append(("buy_essentials", "Purchase essential goods and services",
            decisionEngine.calculateAlignment("buy_essentials", consumerObj.currentInformation), 0.1, 0.9))
        options.append(("save_money", "Increase savings",
            decisionEngine.calculateAlignment("save_money", consumerObj.currentInformation), 0.05, 0.7))
        options.append(("discretionary", "Purchase discretionary items",
            decisionEngine.calculateAlignment("discretionary", consumerObj.currentInformation), 0.15, 0.5))
        options.append(("pay_debt", "Reduce outstanding debt",
            decisionEngine.calculateAlignment("pay_debt", consumerObj.currentInformation), 0.1, 0.8))
        
        let chosenId = decisionEngine.makeDecision(agent: ConsumerAIAgent(), options: options.map { ($0.id, $0.description) })
        
        switch chosenId {
        case "buy_essentials": return ConsumerDecision(purchases: ["seeds": spendBudget * 0.3], savings: 0, spendingConfidence: 0.8, priceSensitivity: 0.5, qualityPreference: 0.6)
        case "save_money": return ConsumerDecision(purchases: [:], savings: spendBudget * 0.5, spendingConfidence: 0.9, priceSensitivity: 0.7, qualityPreference: 0.5)
        case "discretionary": return ConsumerDecision(purchases: [:], savings: 0, spendingConfidence: 0.5, priceSensitivity: 0.4, qualityPreference: 0.8)
        case "pay_debt": return ConsumerDecision(purchases: [:], savings: 0, spendingConfidence: 0.9, priceSensitivity: 0.6, qualityPreference: 0.5)
        default: return ConsumerDecision()
        }
    }
}

// Government AI implementation
public class GovernmentAI {
    private let decisionEngine = DecisionEngine()
    
    public func makeGovernmentDecision(economicIndicators: (inflation: Double, unemployment: Double, gdpGrowth: Double, publicDebt: Double, taxRevenue: Double), 
                                    government: (ideology: String, budget: [String: Double], approvalRating: Double),
                                    governmentObj: AIDecisionFramework) -> GovernmentDecision {
        var options: [(id: String, description: String, score: Double, risk: Double, alignment: Double)] = []
        
        options.append(("adjust_interest_rates", "Central bank adjusts interest rates",
            decisionEngine.calculateAlignment("adjust_interest_rates", governmentObj.currentInformation), 0.3, 0.7))
        options.append(("fiscal_stimulus", "Government spending increase to stimulate economy",
            decisionEngine.calculateAlignment("fiscal_stimulus", governmentObj.currentInformation), 0.4, 0.6))
        options.append(("tax_reform", "Adjust tax rates and policies",
            decisionEngine.calculateAlignment("tax_reform", governmentObj.currentInformation), 0.3, 0.5))
        options.append(("infrastructure_investment", "Invest in roads, utilities, infrastructure",
            decisionEngine.calculateAlignment("infrastructure_investment", governmentObj.currentInformation), 0.2, 0.8))
        options.append(("environmental_regulation", "Implement environmental regulations",
            decisionEngine.calculateAlignment("environmental_regulation", governmentObj.currentInformation), 0.2, 0.5))
        
        let chosenId = decisionEngine.makeDecision(agent: GovernmentAIAgent(), options: options.map { ($0.id, $0.description) })
        
        switch chosenId {
        case "adjust_interest_rates": return GovernmentDecision(policyPriorities: ["price_stability", "economic_growth"], taxChanges: [ "tax_reform": 0.5 ], infrastructureInvestment: 0, monetaryPolicy: "tightening")
        case "fiscal_stimulus": return GovernmentDecision(policyPriorities: ["economic_growth", "employment"], spendingAllocations: ["infrastructure_investment": 5000], infrastructureInvestment: 5000, monetaryPolicy: "neutral")
        case "tax_reform": return GovernmentDecision(policyPriorities: ["revenue", "fairness"], taxChanges: [ "tax_reform": -2 ], infrastructureInvestment: 0, monetaryPolicy: "neutral")
        case "infrastructure_investment": return GovernmentDecision(policyPriorities: ["long_term_growth", "employment"], spendingAllocations: ["infrastructure_investment": 10000], infrastructureInvestment: 10000, monetaryPolicy: "neutral")
        case "environmental_regulation": return GovernmentDecision(policyPriorities: ["sustainability", "long_term_health"], taxChanges: [ "environmental_regulations": 1 ], infrastructureInvestment: 0, monetaryPolicy: "neutral")
        default: return GovernmentDecision()
        }
    }
}

// Bank AI implementation
public class BankAI {
    public func makeBankDecision(borrower: (id: String, type: String, creditScore: Double, revenue: Double, liabilities: Double, collateral: Double), 
                                bankState: (capital: Double, reserves: Double, riskExposure: Double, defaultRate: Double),
                                bankObj: AIDecisionFramework) -> BankDecision {
        let creditRisk = 1 - borrower.creditScore / 100
        let revenueToLiabilityRatio = borrower.revenue / max(1, borrower.liabilities)
        let collateralCoverage = borrower.collateral / max(1, borrower.liabilities * 0.8)
        
        let overallRisk = (creditRisk * 0.5 + (1 - revenueToLiabilityRatio) * 0.3 + (1 - min(1, collateralCoverage)) * 0.2)
        let approvalThreshold = 0.4
        let approved = overallRisk < approvalThreshold
        
        let baseRate = 5
        let riskPremium = overallRisk * 10
        let interestRate = max(baseRate, baseRate + riskPremium)
        
        let maxLoan = bankState.capital * 0.1
        let borrowerCapacity = borrower.revenue * 3
        let loanAmount = min(maxLoan, borrowerCapacity, borrower.collateral * 0.8)
        
        let recommendedActions: [String] = []
        if overallRisk > 0.5 {
            recommendedActions.append("Monitor closely")
            recommendedActions.append("Require additional collateral")
        }
        if borrower.liabilities > borrower.revenue {
            recommendedActions.append("Restructure debt")
        }
        
        return BankDecision(borrowerRisk: overallRisk, approved: approved, interestRate: interestRate, loanAmount: loanAmount, portfolioRisk: overallRisk, recommendedActions: recommendedActions)
    }
}

// Research AI implementation
public class ResearchAI {
    public func makeResearchDecision(availableResearch: [String: (progress: Double, funding: Double, staff: Double)], 
                                    technologicalNeeds: [String: Double], 
                                    researchBudget: Double,
                                    researchObj: AIDecisionFramework) -> ResearchDecision {
        var options: [(id: ResearchArea, score: Double, risk: Double, alignment: Double)] = []
        
        for (area, need) in technologicalNeeds {
            guard let available = availableResearch[area] else { continue }
            
            let needScore = need / 100
            let progressScore = 1 - available.progress
            let efficiencyScore = available.progress / max(1, available.funding)
            let totalScore = needScore * 0.5 + progressScore * 0.3 + efficiencyScore * 0.2
            
            options.append((area as! ResearchArea, totalScore, 0.3, totalScore))
        }
        
        options.sort { $0.score > $1.score }
        let selectedAreas = Array(options.prefix(3).map { $0.id })
        
        let perAreaBudget = researchBudget / max(1, selectedAreas.count)
        let allocation = Dictionary(uniqueKeysWithValues: selectedAreas.map { ($0, perAreaBudget) })
        
        var technologyAdoption: [(area: String, adopt: Bool, timing: Int)] = []
        for (area, need) in technologicalNeeds {
            let threshold = 70
            technologyAdoption.append((area, need > threshold, need > threshold ? 2 : 0))
        }
        
        return ResearchDecision(researchPriorities: selectedAreas, technologyAdoption: technologyAdoption, fundingAllocation: allocation)
    }
}

// Helper extensions
extension Dictionary {
    func merging<Key: Hashable>(_ other: [Key: Value], _ combine: (Value, Value) -> Value) -> [Key: Value] {
        var merged = self
        for (key, value) in other {
            if let existing = merged[key] {
                merged[key] = combine(existing, value)
            } else {
                merged[key] = value
            }
        }
        return merged
    }
}

// Agent agents (concrete types conforming to AIAgent protocol)
public class FarmerAIAgent: AIAgent {
    public let id = "farmer"
    public let type = "farmer"
    public var objectives: [String] = ["maximize_yield", "minimize_risk", "optimize_profit"]
    public var decisionFramework: AIDecisionFramework
    public var lastDecision: String?
    public var decisionHistory: [(decision: String, outcome: String, timestamp: Date)] = []
    public var memory: [String: Double] = [:]
    public var riskTolerance: Double = 0.5
    public var performanceScore: Double = 0.5
    
    public init(decisionFramework: AIDecisionFramework) { self.decisionFramework = decisionFramework }
}

public class BusinessAIAgent: AIAgent {
    public let id = "business"
    public let type = "business"
    public var objectives: [String] = ["maximize_profit", "minimize_risk", "growth"]
    public var decisionFramework: AIDecisionFramework
    public var lastDecision: String?
    public var decisionHistory: [(decision: String, outcome: String, timestamp: Date)] = []
    public var memory: [String: Double] = [:]
    public var riskTolerance: Double = 0.5
    public var performanceScore: Double = 0.5
    
    public init(decisionFramework: AIDecisionFramework) { self.decisionFramework = decisionFramework }
}

public class ConsumerAIAgent: AIAgent {
    public let id = "consumer"
    public let type = "consumer"
    public var objectives: [String] = ["maximize_utility", "minimize_cost", "maintain_stability"]
    public var decisionFramework: AIDecisionFramework
    public var lastDecision: String?
    public var decisionHistory: [(decision: String, outcome: String, timestamp: Date)] = []
    public var memory: [String: Double] = [:]
    public var riskTolerance: Double = 0.5
    public var performanceScore: Double = 0.5
    
    public init(decisionFramework: AIDecisionFramework) { self.decisionFramework = decisionFramework }
}

public class GovernmentAIAgent: AIAgent {
    public let id = "government"
    public let type = "government"
    public var objectives: [String] = ["stability", "growth", "public_approval"]
    public var decisionFramework: AIDecisionFramework
    public var lastDecision: String?
    public var decisionHistory: [(decision: String, outcome: String, timestamp: Date)] = []
    public var memory: [String: Double] = [:]
    public var riskTolerance: Double = 0.5
    public var performanceScore: Double = 0.5
    
    public init(decisionFramework: AIDecisionFramework) { self.decisionFramework = decisionFramework }
}