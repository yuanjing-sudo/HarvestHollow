/**
 * Business Simulation - System 9
 * 
 * Independent business entities with financial records and decision-making.
 * Respond to market signals rather than randomly changing behaviour.
 */

// Industry type enum
export enum IndustryType {
  AGRICULTURE = "agriculture",
  MANUFACTURING = "manufacturing",
  RETAIL = "retail",
  SERVICES = "services",
  TECHNOLOGY = "technology",
  ENERGY = "energy",
  CONSTRUCTION = "construction",
  FINANCE = "finance",
  HEALTHCARE = "healthcare",
  EDUCATION = "education",
  FOOD_PROCESSING = "food_processing",
  LOGISTICS = "logistics"
}

// Business ownership type
export type Ownership = 'sole_proprietor' | 'partnership' | 'corporation' | 'cooperative' | 'state_owned';

// Business characteristics
export interface BusinessCharacteristics {
  id: string;
  name: string;
  industry: IndustryType;
  ownership: Ownership;
  employees: number;
  capital: CurrencyAmount;
  assets: CurrencyAmount;
  liabilities: CurrencyAmount;
  revenue: CurrencyAmount;
  expenses: CurrencyAmount;
  profit: CurrencyAmount;
  marketShare: number; // 0-100
  productivity: number; // 0-100, output per employee
  reputation: number; // 0-100, customer/stakeholder trust
  creditworthiness: number; // 0-100, ability to borrow
}

// Business operational factors
export interface BusinessOperationalFactors {
  productionCapacity: number; // 0-100, utilized capacity
  labourEfficiency: number; // 0-100, output per labour hour
  machineryUtilization: number; // 0-100, machine usage rate
  maintenanceQuality: number; // 0-100, upkeep standard
  inputCosts: number; // 0-100, competitiveness of input prices
  inventoryLevel: number; // 0-100, stock days on hand
  productQuality: number; // 0-100, quality rating
  marketingEffectiveness: number; // 0-100, marketing ROI
  distributionEfficiency: number; // 0-100, distribution cost efficiency
  customerRetention: number; // 0-100, repeat customer rate
}

// Business decision results
export interface BusinessDecision {
  hiring: number; // Number of new hires (positive) or firings (negative)
  expansion: number; // Investment amount for expansion
  pricing: number; // Price change percentage
  productionChange: number; // Production level change percentage
  borrowing: CurrencyAmount; // Amount borrowed
  debtRepayment: CurrencyAmount; // Amount repaid
  supplierSelection: ResourceType; // Preferred supplier resource type
  marketEntry: boolean; // Whether entering new market
  marketExit: boolean; // Whether exiting market
}

// Main business class
export class Business {
  private readonly characteristics: BusinessCharacteristics;
  private operationalFactors: BusinessOperationalFactors;
  private readonly decisionEngine: DecisionEngine;

  constructor(characteristics: BusinessCharacteristics) {
    this.characteristics = characteristics;
    this.operationalFactors = {
      productionCapacity: 70,
      labourEfficiency: 75,
      machineryUtilization: 60,
      maintenanceQuality: 70,
      inputCosts: 70,
      inventoryLevel: 50,
      productQuality: 75,
      marketingEffectiveness: 70,
      distributionEfficiency: 70,
      customerRetention: 70
    };

    # Initialize decision engine with business-specific parameters
    this.decisionEngine = new DecisionEngine(characteristics, this.operationalFactors);
  }

  /**
   * Get business characteristics
   */
  getCharacteristics(): BusinessCharacteristics {
    return { ...this.characteristics };
  }

  /**
   * Get operational factors
   */
  getOperationalFactors(): BusinessOperationalFactors {
    return { ...this.operationalFactors };
  }

  /**
   * Advance business state by one period
   */
  advancePeriod(marketData: {
    commodityPrices: Map<string, number>;
    wageRate: number;
    inflationRate: number;
    demandIndicators: Map<string, number>;
  }): BusinessDecision {
    # Update operational factors based on market conditions
    this.updateOperationalFactors(marketData);

    # Generate business decisions using the decision engine
    const decision = this.decisionEngine.makeDecisions(marketData);

    # Apply the decision to business characteristics
    this.applyDecision(decision, marketData);

    # Return the decision taken
    return decision;
  }

  /**
   * Update operational factors based on market conditions
   */
  private updateOperationalFactors(marketData: {
    commodityPrices: Map<string, number>;
    wageRate: number;
    inflationRate: number;
    demandIndicators: Map<string, number>;
  }): void {
    const { commodityPrices, wageRate, inflationRate, demandIndicators } = marketData;
    const { marketShare, productivity, reputation } = this.characteristics;

    # Input costs affect profitability
    # Average cost of key commodities
    let avgInputCost = 0;
    let inputCount = 0;
    for (const [, price] of commodityPrices.entries()) {
      avgInputCost += price;
      inputCount++;
    }
    if (inputCount > 0) {
      avgInputCost /= inputCount;
    }

    # Adjust input cost factor (0-100 scale, higher = worse/ more expensive)
    const costFactor = Math.max(0, Math.min(100, 100 - avgInputCost * 0.1));
    this.operationalFactors.inputCosts = 0.8 * this.operationalFactors.inputCosts + 0.2 * costFactor;

    # Wage rate affects labour costs
    const wageFactor = Math.max(0, Math.min(100, wageRate * 5)); # Scale wage to 0-100
    this.operationalFactors.inputCosts = 0.7 * this.operationalFactors.inputCosts + 0.3 * wageFactor;

    # Inflation affects cost pressures
    const inflationFactor = inflationRate * 10; # Convert % to scale factor
    this.operationalFactors.inputCosts = 0.7 * this.operationalFactors.inputCosts + 0.3 * Math.max(0, Math.min(100, 50 + inflationFactor));

    # Demand indicators affect production capacity utilization
    const demandSignal = demandIndicators.get('overall') || 50; # 50 = neutral
    this.operationalFactors.productionCapacity = 50 + 0.5 * demandSignal; # Scale 50-100

    # Labour efficiency slightly affected by wage rates (higher wages -> possibly better motivation or turnover)
    const wageEfficiencyImpact = (wageRate - 50) * 0.3; # Deviation from median
    this.operationalFactors.labourEfficiency = Math.max(0, Math.min(100, 75 + wageEfficiencyImpact));

    # Marketing effectiveness affected by demand
    this.operationalFactors.marketingEffectiveness = 0.8 * this.operationalFactors.marketingEffectiveness + 0.2 * Math.max(0, Math.min(100, demandSignal));

    # Customer retention affected by overall conditions
    this.operationalFactors.customerRetention = 0.85 * this.operationalFactors.customerRetention + 0.15 * Math.max(0, Math.min(100, demandSignal));
  }

  /**
   * Apply a business decision to characteristics
   */
  private applyDecision(decision: BusinessDecision, marketData: {
    commodityPrices: Map<string, number>;
    wageRate: number;
    inflationRate: number;
    demandIndicators: Map<string, number>;
  }): void {
    const { revenue, expenses, profit } = this.characteristics;

    # Hiring/firing
    if (decision.hiring > 0) {
      # Hiring new employees
      this.characteristics.employees = Math.max(0, this.characteristics.employees + decision.hiring);
      # Increase capital investment for new hires
      this.characteristics.capital = Math.max(0, this.characteristics.capital - decision.hiring * 5000);
    } else if (decision.hiring < 0) {
      # Firing employees (layoffs)
      this.characteristics.employees = Math.max(1, this.characteristics.employees + decision.hiring);
      # Some capital freed up
      this.characteristics.capital = this.characteristics.capital + Math.abs(decision.hiring) * 2000;
    }

    # Expansion investment
    if (decision.expansion > 0) {
      # Investment increases assets and capital
      this.characteristics.assets = Math.max(0, this.characteristics.assets + decision.expansion * 0.5);
      this.characteristics.capital = Math.max(0, this.characteristics.capital + decision.expansion * 0.5);
      # Investment reduces cash but builds for future
    }

    # Pricing adjustment
    if (decision.pricing !== 0) {
      # Price change affects revenue
      const priceChangePct = decision.pricing / 100;
      # Simple revenue adjustment based on price elasticity (assumed -0.5)
      const revenueEffect = priceChangePct * -0.5;
      this.characteristics.revenue = Math.max(0, this.characteristics.revenue * (1 + revenueEffect));
    }

    # Production change
    if (decision.productionChange !== 0) {
      const productionPct = decision.productionChange / 100;
      # Adjust capacity utilization
      this.operationalFactors.productionCapacity = Math.max(10, Math.min(100, this.operationalFactors.productionCapacity * (1 + productionPct)));
    }

    # Borrowing
    if (decision.borrowing > 0) {
      # Take on debt
      this.characteristics.liabilities = Math.max(0, this.characteristics.liabilities + decision.borrowing);
      this.characteristics.capital = Math.max(0, this.characteristics.capital + decision.borrowing * 0.8); # 80% available as cash
      # Creditworthiness may be affected
      this.updateCreditworthiness();
    }

    # Debt repayment
    if (decision.debtRepayment > 0) {
      this.characteristics.liabilities = Math.max(0, this.characteristics.liabilities - decision.debtRepayment);
      this.characteristics.capital = Math.max(0, this.characteristics.capital - decision.debtRepayment * 0.5);
    }

    # Update profit/loss based on operations
    this.updateProfitLoss(marketData);
  }

  /**
   * Update profit/loss based on operational performance
   */
  private updateProfitLoss(marketData: {
    commodityPrices: Map<string, number>;
    wageRate: number;
    inflationRate: number;
    demandIndicators: Map<string, number>;
  }): void {
    const { productionCapacity, labourEfficiency, inputCosts, productQuality, customerRetention } = this.operationalFactors;
    const { wageRate } = marketData;

    # Revenue calculation
    # Base revenue influenced by market share, productivity, quality, demand
    const baseRevenue = this.characteristics.marketShare * this.characteristics.capital * 0.1;
    const productivityFactor = productivity / 100;
    const qualityFactor = productQuality / 100;
    const demandFactor = Math.max(0.5, Math.min(1.5, (marketData.demandIndicators.get('overall') || 50) / 50));

    let newRevenue = baseRevenue * productivityFactor * qualityFactor * demandFactor;

    # Cost calculation
    # Labour costs
    const labourCost = this.characteristics.employees * wageRate * 2;

    # Input/material costs
    const materialCost = this.characteristics.capital * (inputCosts / 100) * 0.1;

    # Other operational costs
    const operationalCost = newRevenue * 0.4; # 40% of revenue as other costs

    # Total costs
    const totalCosts = labourCost + materialCost + operationalCost;

    # Profit
    const newProfit = newRevenue - totalCosts;

    # Update characteristics
    this.characteristics.revenue = newRevenue;
    this.characteristics.expenses = totalCosts;
    this.characteristics.profit = Math.max(-newRevenue * 0.5, Math.min(newRevenue * 0.5, newProfit));

    # Reputation affected by profit performance
    if (this.characteristics.profit > 0) {
      this.characteristics.reputation = Math.min(100, this.characteristics.reputation + 0.5);
    } else if (this.characteristics.profit < 0) {
      this.characteristics.reputation = Math.max(0, this.characteristics.reputation - 1);
    }

    # Creditworthiness affected by profit consistency
    if (this.characteristics.profit > 0) {
      this.characteristics.creditworthiness = Math.min(100, this.characteristics.creditworthiness + 0.2);
    } else if (this.characteristics.profit < -newRevenue * 0.3) {
      # Significant losses hurt creditworthiness
      this.characteristics.creditworthiness = Math.max(0, this.characteristics.creditworthiness - 1);
    }
  }

  /**
   * Update creditworthiness based on financial health
   */
  private updateCreditworthiness(): void {
    const { profit, liabilities, revenue, employees } = this.characteristics;

    # Simple creditworthiness calculation
    const profitToRevenueRatio = profit / Math.max(1, revenue);
    const liabilityToRevenueRatio = liabilities / Math.max(1, revenue);
    const employeeCostFactor = employees * 5000 / Math.max(1, revenue);

    let newCreditworthiness = 50; # Base
    newCreditworthiness += profitToRevenueRatio * 30;
    newCreditworthiness -= liabilityToRevenueRatio * 20;
    newCreditworthiness -= Math.abs(employeeCostFactor - 0.2) * 15;

    this.characteristics.creditworthiness = Math.max(0, Math.min(100, newCreditworthiness));
  }

  /**
   * Get business decision for display
   */
  getDecisionSummary(): BusinessDecision {
    # Return current tendencies based on operational factors
    const { productionCapacity, labourEfficiency, inputCosts, productQuality, customerRetention } = this.operationalFactors;

    return {
      hiring: 0,
      expansion: 0,
      pricing: (inputCosts - 50) * 0.2, # Price increase if costs high
      productionChange: (productionCapacity - 50) * 0.1,
      borrowing: 0,
      debtRepayment: 0,
      supplierSelection: ResourceType.WATER,
      marketEntry: false,
      marketExit: false
    };
  }
 }

// Decision engine for business AI
class DecisionEngine {
  private characteristics: BusinessCharacteristics;
  private operationalFactors: BusinessOperationalFactors;

  constructor(characteristics: BusinessCharacteristics, operationalFactors: BusinessOperationalFactors) {
    this.characteristics = characteristics;
    this.operationalFactors = operationalFactors;
  }

  /**
   * Make business decisions based on market conditions
   */
  makeDecisions(marketData: {
    commodityPrices: Map<string, number>;
    wageRate: number;
    inflationRate: number;
    demandIndicators: Map<string, number>;
  }): BusinessDecision {
    const { commodityPrices, wageRate, inflationRate, demandIndicators } = marketData;
    const { industry, creditworthiness, marketShare, profit } = this.characteristics;
    const { productionCapacity, labourEfficiency, inputCosts, productQuality, customerRetention } = this.operationalFactors;

    const decision: BusinessDecision = {
      hiring: 0,
      expansion: 0,
      pricing: 0,
      productionChange: 0,
      borrowing: 0,
      debtRepayment: 0,
      supplierSelection: ResourceType.WATER,
      marketEntry: false,
      marketExit: false
    };

    # 1. Pricing decision based on costs and demand
    const avgCost = (inputCosts + wageRate * 0.1) / 2;
    const demandSignal = demandIndicators.get('overall') || 50;

    # Price adjusts based on cost-pressure and demand
    let priceAdjustment = 0;

    if (inputCosts > 60 && demandSignal > 60) {
      # Costs high but demand strong -> can raise prices
      priceAdjustment = (inputCosts - 60) * 0.1 + (demandSignal - 60) * 0.05;
    } else if (inputCosts > 60) {
      # Costs high, demand weak -> must cut prices or maintain
      priceAdjustment = -((inputCosts - 60) * 0.05);
    } else if (demandSignal < 40) {
      # Weak demand -> cut prices
      priceAdjustment = (demandSignal - 50) * 0.1;
    } else {
      # Stable conditions
      priceAdjustment = (demandSignal - 50) * 0.05;
    }

    decision.pricing = priceAdjustment;

    # 2. Production change based on capacity and demand
    let productionAdjustment = 0;

    if (productionCapacity > 80 && demandSignal > 70) {
      # Over capacity but strong demand -> expand
      productionAdjustment = 5;
    } else if (productionCapacity < 40 && demandSignal > 60) {
      # Under capacity, strong demand -> ramp up
      productionAdjustment = 3;
    } else if (productionCapacity > 80 && demandSignal < 40) {
      # Over capacity, weak demand -> scale back
      productionAdjustment = -3;
    } else if (productionCapacity < 40 && demandSignal < 40) {
      # Under capacity, weak demand -> maintain
      productionAdjustment = 0;
    } else {
      # Minor adjustments based on demand
      productionAdjustment = (demandSignal - 50) * 0.1;
    }

    decision.productionChange = productionAdjustment;

    # 3. Hiring/firing based on production needs and profitability
    let hiringDecision = 0;

    if (profit > 0 && productionCapacity > 70) {
      # profitable and have capacity -> hire
      hiringDecision = 2;
    } else if (profit < -this.characteristics.revenue * 0.1 && productionCapacity < 50) {
      # Significant losses and limited capacity -> consider firing
      hiringDecision = -1;
    } else if (profit > 0 && productionCapacity < 40 && demandSignal > 60) {
      # Profitable but can't meet demand -> hire
      hiringDecision = 3;
    } else {
      # Small adjustments
      hiringDecision = (productionCapacity - 50) * 0.05;
    }

    decision.hiring = Math.round(hiringDecision);

    # 4. Borrowing/lending based on creditworthiness and profitability
    let borrowingDecision = 0;

    if (creditworthiness > 70 && profit > 0) {
      # Good credit and profitable -> can borrow for expansion
      borrowingDecision = this.characteristics.capital * 0.1; # 10% of capital
    } else if (creditworthiness < 30 && profit < 0) {
      # Poor credit and losses -> avoid borrowing
      borrowingDecision = -this.characteristics.capital * 0.05; # Repay small amount
    } else if (creditworthiness > 50 && demandSignal > 60) {
      # Moderate credit, strong demand -> borrow for inventory
      borrowingDecision = this.characteristics.capital * 0.05;
    }

    decision.borrowing = borrowingDecision;

    # 5. Debt repayment
    let repaymentDecision = 0;

    if (creditworthiness < 30) {
      # Desperate repayment
      repaymentDecision = Math.min(this.characteristics.liabilities * 0.1, this.characteristics.capital * 0.05);
    } else if (profit > 0 && this.characteristics.liabilities > 0) {
      # Profitable with debt -> regular repayment
      repaymentDecision = this.characteristics.liabilities * 0.02; # 2% of liabilities
    }

    decision.debtRepayment = repaymentDecision;

    # 6. Market entry/exit based on industry opportunities
    if (industry === IndustryType.TECHNOLOGY && profit > 0 && marketShare < 30) {
      decision.marketEntry = true;
    } else if (profit < -this.characteristics.revenue * 0.3 && marketShare < 10) {
      decision.marketExit = true;
    }

    # 7. Supplier selection based on input costs and quality
    # In a full implementation, would evaluate multiple suppliers
    decision.supplierSelection = this.selectSupplier(commodityPrices);

    # 8. Expansion investment based on profitability and market share
    if (profit > 0 && marketShare > 20) {
      decision.expansion = this.characteristics.capital * 0.1; # Reinvest 10% of capital
    } else if (profit > 0) {
      decision.expansion = this.characteristics.capital * 0.05; # Reinvest 5%
    }

    return decision;
  }

  # Select best supplier based on commodity prices and factors
  private selectSupplier(commodityPrices: Map<string, number>): ResourceType {
    # Simple selection: return the resource type with lowest price
    if (commodityPrices.size === 0) return ResourceType.WATER;

    let lowestPrice = Infinity;
    let lowestType: ResourceType = ResourceType.WATER;

    for (const [type, price] of commodityPrices.entries()) {
      if (price < lowestPrice) {
        lowestPrice = price;
        lowestType = type;
      }
    }

    return lowestType;
  }
 }

// Business registry for managing all businesses
export class BusinessRegistry {
  private businesses: Map<string, Business> = new Map();

  /**
   * Register a business
   */
  register(business: Business): void {
    this.businesses.set(business.getCharacteristics().id, business);
  }

  /**
   * Unregister a business
   */
  unregister(id: string): void {
    this.businesses.delete(id);
  }

  /**
   * Get a business by ID
   */
  get(id: string): Business | undefined {
    return this.businesses.get(id);
  }

  /**
   * Get all businesses
   */
  getAll(): Business[] {
    return Array.from(this.businesses.values());
  }

  /**
   * Get businesses by industry
   */
  getByIndustry(industry: IndustryType): Business[] {
    return Array.from(this.businesses.values()).filter(b => b.getCharacteristics().industry === industry);
  }

  /**
   * Advance all businesses by one period
   */
  advanceAll(marketData: {
    commodityPrices: Map<string, number>;
    wageRate: number;
    inflationRate: number;
    demandIndicators: Map<string, number>;
  }): BusinessDecision[] {
    const decisions: BusinessDecision[] = [];

    for (const business of this.businesses.values()) {
      const decision = business.advancePeriod(marketData);
      decisions.push(decision);
    }

    return decisions;
  }

  /**
   * Get business summary statistics
   */
  getStatistics(): {
    totalBusinesses: number;
    totalRevenue: number;
    totalProfit: number;
    averageProfitMargin: number;
    totalEmployees: number;
    industryBreakdown: Map<IndustryType, number>;
  } {
    let totalRevenue = 0;
    let totalProfit = 0;
    let totalEmployees = 0;
    const industryCounts = new Map<IndustryType, number>();

    for (const business of this.businesses.values()) {
      totalRevenue += business.getCharacteristics().revenue;
      totalProfit += business.getCharacteristics().profit;
      totalEmployees += business.getCharacteristics().employees;

      const industry = business.getCharacteristics().industry;
      industryCounts.set(industry, (industryCounts.get(industry) || 0) + 1);
    }

    const averageProfitMargin = totalRevenue > 0 ? totalProfit / totalRevenue : 0;

    return {
      totalBusinesses: this.businesses.size,
      totalRevenue,
      totalProfit,
      averageProfitMargin,
      totalEmployees,
      industryBreakdown: industryCounts
    };
  }
}