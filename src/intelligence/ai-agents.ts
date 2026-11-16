/**
 * AI Agents and Autonomous Decision-Making - System 23
 * 
 * Separate agent types with shared decision framework, planning and evaluation.
 * Farmer AI, Business AI, Consumer AI, Government AI, Bank AI, Research AI.
 * Deterministic simulation rules for economic calculations, AI for decisions.
 */

// AI Decision Framework components
export interface AIDecisionFramework {
  objectives: string[];
  availableResources: Map<string, number>;
  constraints: Map<string, number>;
  currentInformation: Map<string, number>;
  preferences: Map<string, number>;
  riskTolerance: number;
  decisionMakingRules: string[];
  memoryOfPreviousDecisions: Array<{ decision: string; outcome: string; timestamp: number }>;
  expectedOutcomes: Map<string, number>;
  evaluationMethod: string;
}

// Base AI Agent
export interface AIAgent {
  id: string;
  type: string;
  objectives: string[];
  decisionFramework: AIDecisionFramework;
  lastDecision: string | null;
  decisionHistory: Array<{ decision: string; outcome: string; timestamp: number }>;
  memory: Map<string, number>;
  riskTolerance: number;
  performanceScore: number; // 0-1, how well they've been performing
}

// Farmer AI - crop choices, planting, investment, resource allocation
export interface FarmerDecision {
  cropType: string;
  areaToPlant: number; // m²
  investment: CurrencyAmount;
  resourceAllocation: Map<ResourceType, number>;
  expectedRevenue: CurrencyAmount;
  riskAssessment: number; // 0-1
}

// Business AI - pricing, production, hiring, expansion
export interface BusinessDecision as AIAgent {
  pricing: number; // price change percentage
  productionLevel: number; // change percentage
  hiring: number; // number to hire (positive) or fire (negative)
  expansion: CurrencyAmount; // investment amount
  marketEntry: boolean;
  marketExit: boolean;
  supplierSelection: ResourceType;
}

// Consumer AI - purchasing, saving, preferences
export interface ConsumerDecision {
  purchases: Map<ResourceType, CurrencyAmount>;
  savings: CurrencyAmount; // amount saved
  spendingConfidence: number; // 0-1
  priceSensitivity: number; // 0-1
  qualityPreference: number; // 0-1
}

// Government AI - policy selection, spending, economic priorities
export interface GovernmentDecision {
  policyPriorities: string[];
  spendingAllocations: Map<string, CurrencyAmount>;
  taxChanges: Map<string, number>; // rate changes
  regulatoryActions: string[];
  infrastructureInvestment: CurrencyAmount;
  monetaryPolicy: string;
}

// Bank AI - credit evaluation, lending, risk management
export interface BankDecision {
  loanEvaluation: {
    borrowerRisk: number; // 0-1
    approved: boolean;
    interestRate: number;
    loanAmount: CurrencyAmount;
  };
  riskManagement: {
    portfolioRisk: number; // 0-1
    recommendedActions: string[];
  };
}

// Research AI - research priorities and technological adoption
export interface ResearchDecision {
  researchPriorities: ResearchArea[];
  technologyAdoption: {
    area: ResearchArea;
    adopt: boolean;
    timing: number; // periods until adoption
  }[];
  fundingAllocation: Map<ResearchArea, CurrencyAmount>;
}

// Shared decision engine
export class DecisionEngine {
  #evaluateOptions(options: Array<{ id: string; score: number; risk: number; alignment: number }>): string {
    # Sort by weighted combination of score, risk (negative), and alignment
    return options
      .sort((a, b) => {
        const scoreDiff = b.score - a.score;
        const riskDiff = a.risk - b.risk; # Lower risk is better
        const alignmentDiff = b.alignment - a.alignment;
        return scoreDiff !== 0 ? scoreDiff : riskDiff !== 0 ? riskDiff : alignmentDiff;
      })[0]?.id || "";
  }

  #calculateAlignment(objective: string, context: Map<string, number>): number {
    # How well a decision aligns with the stated objective given current context
    const baseAlignment = 0.5; # Neutral
    # In a full implementation, would analyze context against objective
    return baseAlignment;
  }

  #calculateRisk(decision: string, context: Map<string, number>): number {
    # Risk assessment based on current conditions
    # Higher risk when conditions are uncertain or adverse
    const uncertainty = context.get('uncertainty') || 0.5;
    return uncertainty;
  }

  makeDecision(agent: AIAgent, options: Array<{ id: string; description: string }>): string {
    # Evaluate each option
    const evaluatedOptions = options.map(option => ({
      id: option.id,
      score: this.#calculateAlignment(option.id, agent.decisionFramework.currentInformation),
      risk: this.#calculateRisk(option.id, agent.decisionFramework.currentInformation),
      alignment: this.#calculateAlignment(option.id, agent.decisionFramework.currentInformation)
    }));

    return this.#evaluateOptions(evaluatedOptions);
  }
 }

// Farmer AI implementation
export class FarmerAI {
  private readonly decisionEngine = new DecisionEngine();

  #makeFarmerDecision(
    currentCrops: Map<string, number>, // crop type -> area planted
    soilFactors: Map<string, number>, // nitrogen, phosphorus, etc.
    marketPrices: Map<string, number>, // current prices
    resources: Map<ResourceType, number>, // available water, fertilizer, etc.
    farmerObj: AIDecisionFramework
  ): FarmerDecision {
    # Options: continue current crops, switch to different crops, expand, reduce
    const options: Array<{ id: string; description: string; score: number; risk: number; alignment: number }> = [];

    # Option 1: Plant current best crop
    const currentBest = this.#findBestCrop(currentCrops, soilFactors, marketPrices);
    options.push({
      id: "continue_current",
      description: `Continue planting ${currentBest.cropType}`,
      score: this.#calculateAlignment("continue_current", farmerObj.currentInformation),
      risk: 0.2,
      alignment: 0.8
    });

    # Option 2: Switch to more profitable crop
    const switchOption = this.#evaluateSwitchCrop(currentCrops, soilFactors, marketPrices);
    options.push({
      id: "switch_crop",
      description: `Switch to ${switchOption.betterCrop}`,
      score: switchOption.score,
      risk: switchOption.risk,
      alignment: switchOption.alignment
    });

    # Option 3: Invest in irrigation/improvements
    options.push({
      id: "invest_improvements",
      description: "Invest in soil improvements and irrigation",
      score: this.#calculateAlignment("invest_improvements", farmerObj.currentInformation),
      risk: 0.3,
      alignment: 0.6
    });

    # Option 4: Diversify crops
    options.push({
      id: "diversify",
      description: "Plant mixed crops to spread risk",
      score: this.#calculateAlignment("diversify", farmerObj.currentInformation),
      risk: 0.1,
      alignment: 0.7
    });

    # Make decision
    const chosenId = this.decisionEngine.makeDecision(agent as AIAgent, options.map(o => ({ id: o.id, description: o.description })));

    # Return appropriate decision based on choice
    switch (chosenId) {
      case "continue_current":
        return {
          cropType: currentBest.cropType,
          areaToPlant: (currentCrops.get(currentBest.cropType) || 0) * 1.01, # Slight expansion
          investment: 0,
          resourceAllocation: this.#allocateResources(currentBest.cropType, soilFactors),
          expectedRevenue: this.#estimateRevenue(currentBest.cropType, marketPrices),
          riskAssessment: 0.2
        };
      case "switch_crop":
        return {
          cropType: switchOption.betterCrop,
          areaToPlant: (currentCrops.values().reduce((a, b) => a + b, 0) || 1) * 0.8, # Reduce total area
          investment: 0,
          resourceAllocation: this.#allocateResources(switchOption.betterCrop, soilFactors),
          expectedRevenue: this.#estimateRevenue(switchOption.betterCrop, marketPrices),
          riskAssessment: switchOption.risk
        };
      case "invest_improvements":
        return {
          cropType: currentCrops.keys().next().value || "wheat",
          areaToPlant: Object.values(currentCrops).reduce((a, b) => a + b, 0) || 100,
          investment: 5000,
          resourceAllocation: this.#allocateResourcesForImprovements(soilFactors),
          expectedRevenue: 0,
          riskAssessment: 0.3
        };
      case "diversify":
        return {
          cropType: this.#selectDiverseCrop(currentCrops, soilFactors),
          areaToPlant: 20,
          investment: 0,
          resourceAllocation: this.#allocateResourcesForDiversification(soilFactors),
          expectedRevenue: 0,
          riskAssessment: 0.1
        };
      default:
        return {
          cropType: "wheat",
          areaToPlant: 50,
          investment: 0,
          resourceAllocation: new Map(),
          expectedRevenue: 500,
          riskAssessment: 0.3
        };
    }
  }

  #findBestCrop(currentCrops: Map<string, number>, soilFactors: Map<string, number>, marketPrices: Map<string, number>): { cropType: string; score: number } {
    # Simple: look at market prices and soil suitability
    const cropScores: Array<{ cropType: string; score: number }> = [];

    for (const crop of ["wheat", "corn", "potato", "tomato", "lettuce"]) {
      let score = 0;

      # Market price factor (higher price = higher score)
      const price = marketPrices.get(crop) || 100;
      score += price * 0.5;

      # Soil suitability (simplified)
      const nitrogen = soilFactors.get('nitrogen') || 50;
      const phosphorus = soilFactors.get('phosphorus') || 50;
      const potassium = soilFactors.get('potassium') || 50;

      if (crop === "wheat") score += (nitrogen + phosphorus) * 0.1;
      if (crop === "corn") score += nitrogen * 0.15;
      if (crop === "potato") score += (nitrogen + potassium) * 0.1;
      if (crop === "tomato") score += (phosphorus + potassium) * 0.12;
      if (crop === "lettuce") score += nitrogen * 0.1;

      cropScores.push({ cropType: crop, score });
    }

    return cropScores.reduce((best, current) =>
      current.score > best.score ? current : best
    );
  }

  #evaluateSwitchCrop(currentCrops: Map<string, number>, soilFactors: Map<string, number>, marketPrices: Map<string, number>):
    { betterCrop: string; score: number; risk: number; alignment: number } {
    # Find current worst crop and better alternative
    const currentWorst = this.#findWorstCrop(currentCrops, marketPrices);

    # Evaluate alternatives
    const alternatives = ["wheat", "corn", "potato", "tomato", "lettuce"]
      .filter(c => c !== currentWorst.cropType);

    let bestAlternative = alternatives[0];
    let bestScore = 0;

    for (const alt of alternatives) {
      const price = marketPrices.get(alt) || 100;
      const score = price * 0.5; # Simple price-based scoring

      if (score > bestScore) {
        bestScore = score;
        bestAlternative = alt;
      }
    }

    return {
      betterCrop: bestAlternative,
      score: bestScore,
      risk: 0.3,
      alignment: 0.7
    };
  }

  #findWorstCrop(currentCrops: Map<string, number>, marketPrices: Map<string, number>): { cropType: string; score: number } {
    const cropScores: Array<{ cropType: string; score: number }> = [];

    for (const crop of currentCrops.keys()) {
      const price = marketPrices.get(crop) || 100;
      const score = price; # Lower price = worse score (worst crop)
      cropScores.push({ cropType: crop, score });
    }

    return cropScores.reduce((worst, current) =>
      current.score < worst.score ? current : worst
  );
  }

  #selectDiverseCrop(currentCrops: Map<string, number>, soilFactors: Map<string, number>): string {
    # Select a crop not currently planted, considering soil
    const currentlyPlanted = Array.from(currentCrops.keys());

    const alternatives = ["wheat", "corn", "potato", "tomato", "lettuce"]
      .filter(c => !currentlyPlanted.includes(c));

    if (alternatives.length === 0) return "wheat";

    # Simple: pick first alternative
    return alternatives[0];
  }

  #allocateResources(cropType: string, soilFactors: Map<string, number>): Map<ResourceType, number> {
    const resources = new Map<ResourceType, number>();

    # Base resource needs by crop
    const baseNeeds: Record<string, Map<ResourceType, number>> = {
      wheat: new Map([[ResourceType.FERTILISER, 10], [ResourceType.WATER, 30], [ResourceType.ELECTRICITY, 2]]),
      corn: new Map([[ResourceType.FERTILISER, 15], [ResourceType.WATER, 40], [ResourceType.ELECTRICITY, 3]]),
      potato: new Map([[ResourceType.FERTILISER, 12], [ResourceType.WATER, 35], [ResourceType.ELECTRICITY, 2]]),
      tomato: new Map([[ResourceType.FERTILISER, 15], [ResourceType.WATER, 45], [ResourceType.ELECTRICITY, 3]]),
      lettuce: new Map([[ResourceType.FERTILISER, 8], [ResourceType.WATER, 25], [ResourceType.ELECTRICITY, 1]])
    };

    const needs = baseNeeds[cropType] || new Map();
    for (const [type, amount] of needs.entries()) {
      resources.set(type, amount);
    }

    # Adjust based on soil quality
    const nitrogen = soilFactors.get('nitrogen') || 50;
    if (nitrogen > 70) {
      # Reduce fertilizer need
      resources.forEach((amount, type) => {
        if (type === ResourceType.FERTILISER) {
          resources.set(type, amount * 0.8);
        }
      });
    }

    return resources;
  }

  #allocateResourcesForImprovements(soilFactors: Map<string, number>): Map<ResourceType, number> {
    return this.#allocateResources("wheat", soilFactors); # Simplified
  }

  #allocateResourcesForDiversification(soilFactors: Map<string, number>): Map<ResourceType, number> {
    return new Map([[ResourceType.FERTILISER, 10], [ResourceType.WATER, 30]]);
  }

  #estimateRevenue(cropType: string, marketPrices: Map<string, number>): CurrencyAmount {
    const price = marketPrices.get(cropType) || 100;
    return price * 10; # Simple estimation
  }
 }

// Business AI implementation
export class BusinessAI {
  private readonly decisionEngine = new DecisionEngine();

  #makeBusinessDecision(
    business: {
      id: string;
      industry: IndustryType;
      employees: number;
      revenue: CurrencyAmount;
      profit: CurrencyAmount;
      marketShare: number;
      creditworthiness: number;
    },
    marketData: {
      commodityPrices: Map<string, number>;
      wageRate: number;
      inflationRate: number;
      demandIndicators: Map<string, number>;
    },
    businessObj: AIDecisionFramework
  ): BusinessDecision {
    # Options to evaluate
    const options: Array<{ id: string; description: string; score: number; risk: number; alignment: number }> = [];

    # Option 1: Adjust prices based on costs and demand
    options.push({
      id: "adjust_prices",
      description: "Adjust prices based on cost pressures and demand",
      score: this.#calculateAlignment("adjust_prices", businessObj.currentInformation),
      risk: 0.2,
      alignment: 0.7
    });

    # Option 2: Expand production
    options.push({
      id: "expand_production",
      description: "Increase production capacity",
      score: this.#calculateAlignment("expand_production", businessObj.currentInformation),
      risk: 0.3,
      alignment: 0.6
    });

    # Option 3: Hire workers
    options.push({
      id: "hire_workers",
      description: "Hire additional workers",
      score: this.#calculateAlignment("hire_workers", businessObj.currentInformation),
      risk: 0.2,
      alignment: 0.5
    });

    # Option 4: Reduce costs
    options.push({
      id: "reduce_costs",
      description: "Implement cost-cutting measures",
      score: this.#calculateAlignment("reduce_costs", businessObj.currentInformation),
      risk: 0.1,
      alignment: 0.8
    });

    # Option 5: Borrow for expansion
    options.push({
      id: "borrow_expansion",
      description: "Take on debt for expansion",
      score: this.#calculateAlignment("borrow_expansion", businessObj.currentInformation),
      risk: 0.4,
      alignment: 0.5
    });

    # Make decision
    const chosenId = this.decisionEngine.makeDecision(agent as AIAgent, options.map(o => ({ id: o.id, description: o.description })));

    # Return decision based on choice
    switch (chosenId) {
      case "adjust_prices":
        return {
          pricing: 5, # 5% price increase
          productionLevel: 0,
          hiring: 0,
          expansion: 0,
          marketEntry: false,
          marketExit: false,
          supplierSelection: ResourceType.WATER
        };
      case "expand_production":
        return {
          pricing: 0,
          productionLevel: 10,
          hiring: 2,
          expansion: 1000,
          marketEntry: false,
          marketExit: false,
          supplierSelection: ResourceType.WATER
        };
      case "hire_workers":
        return {
          pricing: 0,
          productionLevel: 0,
          hiring: 3,
          expansion: 0,
          marketEntry: false,
          marketExit: false,
          supplierSelection: ResourceType.WATER
        };
      case "reduce_costs":
        return {
          pricing: -3,
          productionLevel: -5,
          hiring: -1,
          expansion: 0,
          marketEntry: false,
          marketExit: false,
          supplierSelection: ResourceType.WATER
        };
      case "borrow_expansion":
        return {
          pricing: 2,
          productionLevel: 0,
          hiring: 1,
          expansion: 2000,
          marketEntry: false,
          marketExit: false,
          supplierSelection: ResourceType.WATER
        };
      default:
        return {
          pricing: 0,
          productionLevel: 0,
          hiring: 0,
          expansion: 0,
          marketEntry: false,
          marketExit: false,
          supplierSelection: ResourceType.WATER
        };
    }
  }
 }

// Consumer AI implementation
export class ConsumerAI {
  private readonly decisionEngine = new DecisionEngine();

  #makeConsumerDecision(
    household: {
      id: string;
      income: CurrencyAmount;
      savings: CurrencyAmount;
      debt: CurrencyAmount;
      employmentStatus: string;
      householdClass: string;
    },
    marketConditions: {
      priceLevels: Map<string, number>;
      incomeLevels: Map<string, number>;
    },
    consumerObj: AIDecisionFramework
  ): ConsumerDecision {
    # Determine budget available for spending
    const disposableIncome = household.income - household.debt * 0.02; # Small debt service
    const spendBudget = Math.max(0, disposableIncome * 0.8); # Spend 80% of disposable

    # Options for spending
    const options: Array<{ id: string; description: string; score: number; risk: number; alignment: number }> = [];

    # Option 1: Buy essentials (food, etc.)
    options.push({
      id: "buy_essentials",
      description: "Purchase essential goods and services",
      score: this.#calculateAlignment("buy_essentials", consumerObj.currentInformation),
      risk: 0.1,
      alignment: 0.9
    });

    # Option 2: Save money
    options.push({
      id: "save_money",
      description: "Increase savings",
      score: this.#calculateAlignment("save_money", consumerObj.currentInformation),
      risk: 0.05,
      alignment: 0.7
    });

    # Option 3: Discretionary spending
    options.push({
      id: "discretionary",
      description: "Purchase discretionary/non-essential items",
      score: this.#calculateAlignment("discretionary", consumerObj.currentInformation),
      risk: 0.15,
      alignment: 0.5
    });

    # Option 4: Pay down debt
    options.push({
      id: "pay_debt",
      description: "Reduce outstanding debt",
      score: this.#calculateAlignment("pay_debt", consumerObj.currentInformation),
      risk: 0.1,
      alignment: 0.8
    });

    # Make decision
    const chosenId = this.decisionEngine.makeDecision(agent as AIAgent, options.map(o => ({ id: o.id, description: o.description })));

    # Return decision based on choice
    switch (chosenId) {
      case "buy_essentials":
        return {
          purchases: new Map([[ResourceType.SEEDS, spendBudget * 0.3]]), # Simplified: food
          savings: 0,
          spendingConfidence: 0.8,
          priceSensitivity: 0.5,
          qualityPreference: 0.6
        };
      case "save_money":
        return {
          purchases: new Map(),
          savings: spendBudget * 0.5,
          spendingConfidence: 0.9,
          priceSensitivity: 0.7,
          qualityPreference: 0.5
        };
      case "discretionary":
        return {
          purchases: new Map([[ResourceType.TIMBER, spendBudget * 0.2]]), # Simplified
          savings: 0,
          spendingConfidence: 0.5,
          priceSensitivity: 0.4,
          qualityPreference: 0.8
        };
      case "pay_debt":
        return {
          purchases: new Map(),
          savings: 0,
          spendingConfidence: 0.9,
          priceSensitivity: 0.6,
          qualityPreference: 0.5
        };
      default:
        return {
          purchases: new Map(),
          savings: 0,
          spendingConfidence: 0.5,
          priceSensitivity: 0.5,
          qualityPreference: 0.5
        };
    }
  }
 }

// Government AI implementation
export class GovernmentAI {
  private readonly decisionEngine = new DecisionEngine();

  #makeGovernmentDecision(
    economicIndicators: {
      inflation: number;
      unemployment: number;
      gdpGrowth: number;
      publicDebt: CurrencyAmount;
      taxRevenue: CurrencyAmount;
    },
    government: {
      ideology: GovernmentIdeology;
      budget: GovernmentBudget;
      approvalRating: number;
    },
    governmentObj: AIDecisionFramework
  ): GovernmentDecision {
    # Policy options based on ideology and conditions
    const options: Array<{ id: string; description: string; score: number; risk: number; alignment: number }> = [];

    # Option 1: Adjust interest rates (monetary policy)
    options.push({
      id: "adjust_interest_rates",
      description: "Central bank adjusts interest rates",
      score: this.#calculateAlignment("adjust_interest_rates", governmentObj.currentInformation),
      risk: 0.3,
      alignment: 0.7
    });

    # Option 2: Fiscal stimulus
    options.push({
      id: "fiscal_stimulus",
      description: "Government spending increase to stimulate economy",
      score: this.#calculateAlignment("fiscal_stimulus", governmentObj.currentInformation),
      risk: 0.4,
      alignment: 0.6
    });

    # Option 3: Tax reform
    options.push({
      id: "tax_reform",
      description: "Adjust tax rates and policies",
      score: this.#calculateAlignment("tax_reform", governmentObj.currentInformation),
      risk: 0.3,
      alignment: 0.5
    });

    # Option 4: Infrastructure investment
    options.push({
      id: "infrastructure_investment",
      description: "Invest in roads, utilities, infrastructure",
      score: this.#calculateAlignment("infrastructure_investment", governmentObj.currentInformation),
      risk: 0.2,
      alignment: 0.8
    });

    # Option 5: Environmental regulation
    options.push({
      id: "environmental_regulation",
      description: "Implement or adjust environmental regulations",
      score: this.#calculateAlignment("environmental_regulation", governmentObj.currentInformation),
      risk: 0.2,
      alignment: 0.5
    });

    # Make decision
    const chosenId = this.decisionEngine.makeDecision(agent as AIAgent, options.map(o => ({ id: o.id, description: o.description })));

    # Return decision based on choice
    switch (chosenId) {
      case "adjust_interest_rates":
        return {
          policyPriorities: ["price_stability", "economic_growth"],
          spendingAllocations: new Map(),
          taxChanges: { [PolicyArea.TAX_REFORM]: 0.5 },
          regulatoryActions: [],
          infrastructureInvestment: 0,
          monetaryPolicy: "tightening"
        };
      case "fiscal_stimulus":
        return {
          policyPriorities: ["economic_growth", "employment"],
          spendingAllocations: new Map([[PolicyArea.INFRASTRUCTURE_INVESTMENT, 5000]]),
          taxChanges: {},
          regulatoryActions: [],
          infrastructureInvestment: 5000,
          monetaryPolicy: "neutral"
        };
      case "tax_reform":
        return {
          policyPriorities: ["revenue", "fairness"],
          spendingAllocations: new Map(),
          taxChanges: { [PolicyArea.TAX_REFORM]: -2 }, # Reduce rates by 2%
          regulatoryActions: [],
          infrastructureInvestment: 0,
          monetaryPolicy: "neutral"
        };
      case "infrastructure_investment":
        return {
          policyPriorities: ["long_term_growth", "employment"],
          spendingAllocations: new Map([[PolicyArea.INFRASTRUCTURE_INVESTMENT, 10000]]),
          taxChanges: {},
          regulatoryActions: [],
          infrastructureInvestment: 10000,
          monetaryPolicy: "neutral"
        };
      case "environmental_regulation":
        return {
          policyPriorities: ["sustainability", "long_term_health"],
          spendingAllocations: new Map(),
          taxChanges: { [PolicyArea.ENVIRONMENTAL_REGULATION]: 1 }, # Increase environmental taxes
          regulatoryActions: ["new_environmental_standards"],
          infrastructureInvestment: 0,
          monetaryPolicy: "neutral"
        };
      default:
        return {
          policyPriorities: ["stability"],
          spendingAllocations: new Map(),
          taxChanges: {},
          regulatoryActions: [],
          infrastructureInvestment: 0,
          monetaryPolicy: "neutral"
        };
    }
  }
 }

// Bank AI implementation
export class BankAI {
  #makeBankDecision(
    borrower: {
      id: string;
      type: 'business' | 'household';
      creditScore: number;
      revenue: CurrencyAmount;
      liabilities: CurrencyAmount;
      collateral: CurrencyAmount;
    },
    bankState: {
      capital: CurrencyAmount;
      reserves: CurrencyAmount;
      riskExposure: number;
      defaultRate: number;
    },
    bankObj: AIDecisionFramework
  ): BankDecision {
    # Evaluate loan risk
    const creditRisk = 1 - borrower.creditScore / 100; # Lower credit score = higher risk
    const revenueToLiabilityRatio = borrower.revenue / Math.max(1, borrower.liabilities);
    const collateralCoverage = borrower.collateral / Math.max(1, borrower.liabilities * 0.8); # Ideal collateral coverage

    # Overall risk score
    const overallRisk = (creditRisk * 0.5 + (1 - revenueToLiabilityRatio) * 0.3 + (1 - Math.min(1, collateralCoverage)) * 0.2);

    # Decision thresholds
    const approvalThreshold = 0.4; # Approve if risk below 40%
    const approved = overallRisk < approvalThreshold;

    # Interest rate based on risk (higher risk = higher rate)
    const baseRate = 5; # % base interest rate
    const riskPremium = overallRisk * 10; # Up to 10% premium
    const interestRate = Math.max(baseRate, baseRate + riskPremium);

    # Loan amount based on bank capacity and borrower qualifications
    const maxLoan = bankState.capital * 0.1; # Banks can lend ~10% of capital
    const borrowerCapacity = borrower.revenue * 3; # Typical lending: 3x revenue
    const loanAmount = Math.min(maxLoan, borrowerCapacity, borrower.collateral * 0.8);

    # Risk management recommendations
    const recommendedActions: string[] = [];

    if (overallRisk > 0.5) {
      recommendedActions.push("Monitor closely");
      recommendedActions.push("Require additional collateral");
    }

    if (borrower.liabilities > borrower.revenue) {
      recommendedActions.push("Restructure debt");
    }

    return {
      loanEvaluation: {
        borrowerRisk: overallRisk,
        approved,
        interestRate,
        loanAmount
      },
      riskManagement: {
        portfolioRisk: overallRisk,
        recommendedActions
      }
    };
  }
 }

// Research AI implementation
export class ResearchAI {
  #makeResearchDecision(
    availableResearch: Map<ResearchArea, { progress: number; funding: CurrencyAmount; staff: number }>,
    technologicalNeeds: Map<ResearchArea, number>, # Priority need per area (0-100)
    researchBudget: CurrencyAmount,
    researchObj: AIDecisionFramework
  ): ResearchDecision {
    # Evaluate research areas based on need, progress, and funding efficiency
    const options: Array<{ id: ResearchArea; score: number; risk: number; alignment: number }> = [];

    for (const [area, need] of technologicalNeeds.entries()) {
      const available = availableResearch.get(area) || { progress: 0, funding: 0, staff: 1 };

      # Score based on need, inverted (higher need = higher score)
      const needScore = need / 100;

      # Progress factor - areas less progressed get higher priority
      const progressScore = 1 - available.progress;

      # Funding efficiency - how much progress per funding
      const efficiencyScore = available.progress / Math.max(1, available.funding);

      # Combined score
      const totalScore = needScore * 0.5 + progressScore * 0.3 + efficiencyScore * 0.2;

      options.push({
        id: area,
        score: totalScore,
        risk: 0.3,
        alignment: totalScore
      });
    }

    # Sort by score and select top options
    options.sort((a, b) => b.score - a.score);

    # Select top 3 research areas
    const selectedAreas = options.slice(0, 3).map(o => o.id);

    # Allocate budget proportionally to selected areas
    const allocation: Map<ResearchArea, CurrencyAmount> = new Map();
    const perAreaBudget = researchBudget / Math.max(1, selectedAreas.length);

    for (const area of selectedAreas) {
      allocation.set(area, perAreaBudget);
    }

    # Technology adoption decisions
    const technologyAdoption: Array<{
      area: ResearchArea;
      adopt: boolean;
      timing: number;
    }> = [];

    # Simple: adopt technology if research progress is high enough
    for (const [area, need] of technologicalNeeds.entries()) {
      const threshold = 70; # 70% progress threshold
      const shouldAdapt = need > threshold;
      technologyAdoption.push({
        area,
        adopt: shouldAdapt,
        timing: shouldAdapt ? 2 : 0 # 2 periods until full adoption
      });
    }

    return {
      researchPriorities: selectedAreas,
      technologyAdoption,
      fundingAllocation: allocation
    };
  }
}