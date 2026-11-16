/**
 * Currency and Monetary Economy - System 8
 * 
 * Simulates the financial environment: currency, inflation, interest rates,
 * monetary policy and fiscal factors with differentiated inflation rates.
 */

// Currency type
export type CurrencyAmount = number;
export type InflationRate = number; // percentage per period
export type InterestRate = number; // percentage per period

// Money supply measures
export enum MoneySupplyMeasure {
  M0 = "m0",     # Physical currency in circulation
  M1 = "m1",     # M0 + demand deposits
  M2 = "m2",     # M1 + savings deposits + small time deposits
  M3 = "m3"      # M2 + large time deposits + institutional money market funds
}

// Inflation indicators
export enum InflationIndicator {
  CPI = "cpi",         # Consumer Price Index
  PPI = "ppi",         # Producer Price Index
  FOOD = "food",       # Food inflation
  ENERGY = "energy",   # Energy inflation
  HOUSING = "housing", # Housing inflation
  WAGES = "wages",     # Wage inflation
  IMPORT = "import",   # Import-driven inflation
  DOMESTIC = "domestic" # Demand-driven inflation
}

// Monetary policy tools
export enum MonetaryTool {
  INTEREST_RATE = "interest_rate",
  OPEN_MARKET_OPERATIONS = "open_market_operations",
  RESERVE_REQUIREMENTS = "reserve_requirements",
  FORWARD_GUIDANCE = "forward_guidance",
  QUANTITATIVE_EASING = "quantitative_easing",
  QUANTITATIVE_TIGHTENING = "quantitative_tightening"
}

// Central bank policy state
export interface CentralBankPolicy {
  policyRate: InterestRate;         # Base interest rate
  reserveRequirements: number;      # Required reserve ratio (%)
  balanceSheetSize: CurrencyAmount; # Size of central bank balance sheet
  targetInflation: InflationRate;   # Target inflation rate (%)
  inflationTargetBand: { lower: number; upper: number }; # Tolerance band
  quantitativeEasing: boolean;      # QE active
  lastPolicyChange: number;         # When policy was last changed
}

// Fiscal policy state
export interface FiscalPolicy {
  governmentBudget: CurrencyAmount;
  taxRevenue: CurrencyAmount;
  governmentSpending: CurrencyAmount;
  budgetDeficit: CurrencyAmount;
  publicDebt: CurrencyAmount;
  debtToGDPRatio: number;
}

// Currency and monetary state
export interface MonetaryState {
  moneySupply: { [key in MoneySupplyMeasure]: CurrencyAmount };
  inflationRate: InflationRate;           # Current inflation (%)
  inflationExpectations: InflationRate;   # Expected inflation (%)
  interestRate: InterestRate;             # Current policy rate (%)
  cpi: number;                            # Consumer Price Index base = 100
  realInterestRate: InterestRate;         # Interest rate adjusted for inflation
  moneyMultiplier: number;                # Money creation multiplier
}

// Main monetary economy class
export class MonetaryEconomy {
  private monetaryState: MonetaryState;
  private centralBankPolicy: CentralBankPolicy;
  private fiscalPolicy: FiscalPolicy;
  private inflationHistory: Array<{ rate: InflationRate; timestamp: number }> = [];

  constructor(initialState?: Partial<MonetaryState>, initialPolicy?: Partial<CentralBankPolicy>) {
    # Initialize monetary state
    this.monetaryState = {
      moneySupply: {
        [MoneySupplyMeasure.M0]: 1000,
        [MoneySupplyMeasure.M1]: 5000,
        [MoneySupplyMeasure.M2]: 20000,
        [MoneySupplyMeasure.M3]: 50000
      },
      inflationRate: 2.0,
      inflationExpectations: 2.0,
      interestRate: 5.0,
      cpi: 100,
      realInterestRate: 3.0,
      moneyMultiplier: 5.0
    };

    # Initialize central bank policy
    this.centralBankPolicy = {
      policyRate: 5.0,
      reserveRequirements: 10,
      balanceSheetSize: 10000,
      targetInflation: 2.0,
      inflationTargetBand: { lower: 1.0, upper: 3.0 },
      quantitativeEasing: false,
      lastPolicyChange: Date.now()
    };

    # Initialize fiscal policy
    this.fiscalPolicy = {
      governmentBudget: 0,
      taxRevenue: 0,
      governmentSpending: 0,
      budgetDeficit: 0,
      publicDebt: 0,
      debtToGDPRatio: 0.5
    };

    # Apply initial state if provided
    if (initialState) {
      if (initialState.inflationRate !== undefined) this.monetaryState.inflationRate = initialState.inflationRate;
      if (initialState.interestRate !== undefined) this.monetaryState.interestRate = initialState.interestRate;
      if (initialState.cpi !== undefined) this.monetaryState.cpi = initialState.cpi;
    }

    if (initialPolicy) {
      if (initialPolicy.policyRate !== undefined) this.centralBankPolicy.policyRate = initialPolicy.policyRate;
      if (initialPolicy.targetInflation !== undefined) this.centralBankPolicy.targetInflation = initialPolicy.targetInflation;
    }

    # Record initial state
    this.recordInflation();
  }

  /**
   * Get current monetary state
   */
  getMonetaryState(): MonetaryState {
    return { ...this.monetaryState };
  }

  /**
   * Get central bank policy
   */
  getCentralBankPolicy(): CentralBankPolicy {
    return { ...this.centralBankPolicy };
  }

  # Fiscal policy accessors
  getFiscalPolicy(): FiscalPolicy {
    return { ...this.fiscalPolicy };
  }

  # Update real interest rate (nominal - inflation)
  #realInterestRate(): void {
  this.monetaryState.realInterestRate = this.monetaryState.interestRate - this.monetaryState.inflationRate;
  #}

  /**
   * Advance monetary economy by one period
   */
  advancePeriod(deltaDays: number): void {
    const periods = deltaDays / 30; # Monthly periods approximate

    for (let i = 0; i < periods; i++) {
      this.advanceMonthly();
    }
  }

  /**
   * Advance one monthly period
   */
  private advanceMonthly(): void {
    # 1. Update inflation based on economic factors
    this.updateInflation();

    # 2. Adjust interest rate if needed (monetary policy response)
    this.adjustInterestRate();

    # 3. Update money supply
    this.updateMoneySupply();

    # 4. Update fiscal indicators
    this.updateFiscalIndicators();

    # 5. Record inflation history
    this.recordInflation();
  }

  /**
   * Update inflation rate based on various factors
   */
  private updateInflation(): void {
    const { inflationRate, cpi, moneyMultiplier, interestRate } = this.monetaryState;
    const { targetInflation, inflationTargetBand } = this.centralBankPolicy;

    # Base inflation change from money supply growth
    const moneyGrowth = 2.0; # Simulated money supply growth rate (%)
    const moneyImpact = (moneyGrowth - inflationRate) * 0.5; # Partial pass-through

    # Demand-pull inflation factor
    # (Simplified: if economy "overheating", higher inflation)
    # In a full model, this would use GDP gap, output gap, etc.

    # Cost-push inflation
    # (Simplified cost pressures)
    const costPush = 0.5; # Base cost-push inflation

    # Net inflation change
    const inflationChange = moneyImpact + costPush;

    # Adjust toward target (mean reversion)
    const deviationFromTarget = inflationRate - targetInflation;
    const meanReversion = -deviationFromTarget * 0.1; # Slow adjustment

    # Total change
    const totalChange = inflationChange + meanReversion;

    # Apply change
    let newInflation = inflationRate + totalChange;

    # Keep within reasonable bounds
    newInflation = Math.max(-10, Math.min(50, newInflation)); # -10% to +50%

    # Apply inflation target band guidance
    if (newInflation < inflationTargetBand.lower) {
      newInflation = inflationTargetBand.lower;
    } else if (newInflation > inflationTargetBand.upper) {
      newInflation = inflationTargetBand.upper;
    }

    # Smoothing - don't let inflation jump wildly
    const smoothedInflation = inflationRate + (newInflation - inflationRate) * 0.5;
    this.monetaryState.inflationRate = smoothedInflation;

    # Update CPI
    const cpiChange = this.monetaryState.inflationRate / 100; # Monthly CPI change
    this.monetaryState.cpi = Math.max(1, this.monetaryState.cpi * (1 + cpiChange));

    # Update inflation expectations (adaptive expectations)
    const expectationChange = (this.monetaryState.inflationRate - this.monetaryState.inflationExpectations) * 0.1;
    this.monetaryState.inflationExpectations = this.monetaryState.inflationExpectations + expectationChange;

    # Update real interest rate
    this.monetaryState.realInterestRate = this.monetaryState.interestRate - this.monetaryState.inflationRate;
  }

  /**
   * Adjust interest rate based on inflation vs target
   */
  private adjustInterestRate(): void {
    const { inflationRate, inflationExpectations, interestRate } = this.monetaryState;
    const { targetInflation, policyRate } = this.centralBankPolicy;

    # Calculate Taylor rule-like adjustment
    # i = r* + π + 0.5(π - π*) + 0.5y + 0.5(π - π*)y
    # Simplified: adjust 0.5% for each 1% inflation deviation

    const inflationDeviation = inflationRate - targetInflation;
    const adjustmentSize = inflationDeviation * 0.5;

    # New policy rate
    let newRate = interestRate + adjustmentSize;

    # Keep within reasonable bounds (e.g., 0% to 15%)
    newRate = Math.max(0, Math.min(15, newRate));

    # Apply adjustment speed (smoothing)
    const smoothedRate = interestRate + (newRate - interestRate) * 0.25;
    this.centralBankPolicy.policyRate = smoothedRate;

    # Update monetary state interest rate
    this.monetaryState.interestRate = smoothedRate;
    this.monetaryState.realInterestRate = smoothedRate - inflationRate;
  }

  /**
   * Update money supply
   */
  private updateMoneySupply(): void {
    const { moneyMultiplier, inflationRate, interestRate } = this.monetaryState;
    const { policyRate } = this.centralBankPolicy;

    # Money creation based on interest rates (lower rates -> more lending -> more money)
    const rateEffect = Math.max(0.5, 5 - interestRate); # Higher effect when rates low
    const moneyCreationRate = 0.02 * rateEffect; # 2% base * rate factor

    # Change money supply
    const moneyChange = moneyMultiplier * moneyCreationRate;

    # Apply to M2 as primary measure
    const m2 = this.monetaryState.moneySupply[MoneySupplyMeasure.M2];
    const newM2 = m2 * (1 + moneyChange);

    # Update all measures (they grow at different rates)
    const m0Change = moneyChange * 0.5; # M0 grows slower
    const m1Change = moneyChange * 0.8; # M1 similar to M2
    const m3Change = moneyChange * 1.2; # M3 grows faster (includes institutional)

    this.monetaryState.moneySupply = {
      [MoneySupplyMeasure.M0]: this.monetaryState.moneySupply[MoneySupplyMeasure.M0] * (1 + m0Change),
      [MoneySupplyMeasure.M1]: this.monetaryState.moneySupply[MoneySupplyMeasure.M1] * (1 + m1Change),
      [MoneySupplyMeasure.M2]: newM2,
      [MoneySupplyMeasure.M3]: this.monetaryState.moneySupply[MoneySupplyMeasure.M3] * (1 + m3Change)
    };
  }

  /**
   * Update fiscal indicators
   */
  private updateFiscalIndicators(): void {
    # Calculate budget deficit/surplus
    # In a full model, this would track tax revenue vs spending
    # For now, simple simulation

    # Debt changes based on deficit
    const deficitFinancing = this.monetaryState.inflationRate * 0.1; # Inflation erodes real debt value
    const currentDebt = this.fiscalPolicy.publicDebt;
    const newDebt = currentDebt * (1 - deficitFinancing / 100); # Inflation reduces real debt

    this.fiscalPolicy.publicDebt = Math.max(0, newDebt);

    # Debt-to-GDP ratio (GDP grows modestly)
    const gdpGrowth = 3.0; # % per year / 12 ≈ 0.25% per month
    const newGDPRatio = (this.fiscalPolicy.publicDebt / (1 + gdpGrowth / 1200)) / 100 * 100;
    this.fiscalPolicy.debtToGDPRatio = Math.max(0, Math.min(500, newGDPRatio));

    # Tax revenue changes with economic activity and inflation
    const taxBaseEffect = this.monetaryState.inflationRate * 0.5;
    const currentTaxRevenue = this.fiscalPolicy.taxRevenue;
    const newTaxRevenue = currentTaxRevenue * (1 + taxBaseEffect / 100);
    this.fiscalPolicy.taxRevenue = Math.max(0, newTaxRevenue);

    # Government spending (simulated as growing with inflation)
    const currentSpending = this.fiscalPolicy.governmentSpending;
    const newSpending = currentSpending * (1 + this.monetaryState.inflationRate / 100);
    this.fiscalPolicy.governmentSpending = Math.max(0, newSpending);

    # Budget deficit
    this.fiscalPolicy.governmentBudget = this.fiscalPolicy.taxRevenue - this.fiscalPolicy.governmentSpending;
    this.fiscalPolicy.budgetDeficit = -this.fiscalPolicy.governmentBudget; # Positive = deficit
  }

  /**
   * Record inflation for history tracking
   */
  private recordInflation(): void {
    this.inflationHistory.push({
      rate: this.monetaryState.inflationRate,
      timestamp: Date.now()
    });

    # Keep history manageable
    if (this.inflationHistory.length > 240) { # 20 years monthly
      this.inflationHistory = this.inflationHistory.slice(-240);
    }
  }

  /**
   * Set policy rate directly
   */
  setPolicyRate(rate: InterestRate): void {
    this.centralBankPolicy.policyRate = rate;
    this.monetaryState.interestRate = rate;
    this.monetaryState.realInterestRate = rate - this.monetaryState.inflationRate;
  }

  /**
   * Set target inflation
   */
  setTargetInflation(rate: InflationRate): void {
    this.centralBankPolicy.targetInflation = rate;
  }

  /**
   * Apply quantitative easing
   */
  applyQuantitativeEasing(active: boolean): void {
    this.centralBankPolicy.quantitativeEasing = active;

    if (active) {
      # Increase money supply
      const m2 = this.monetaryState.moneySupply[MoneySupplyMeasure.M2];
      this.monetaryState.moneySupply[MoneySupplyMeasure.M2] = m2 * 1.1; # 10% increase
      this.monetaryState.moneySupply[MoneySupplyMeasure.M3] = this.monetaryState.moneySupply[MoneySupplyMeasure.M3] * 1.15;
      this.monetaryState.moneyMultiplier *= 1.1;
    } else {
      # Reduce money supply growth
      const m2 = this.monetaryState.moneySupply[MoneySupplyMeasure.M2];
      this.monetaryState.moneySupply[MoneySupplyMeasure.M2] = m2 * 0.95;
      this.monetaryState.moneySupply[MoneySupplyMeasure.M3] = this.monetaryState.moneySupply[MoneySupplyMeasure.M3] * 0.97;
      this.monetaryState.moneyMultiplier *= 0.95;
    }
  }

  /**
   # Set reserve requirements
   */
  setReserveRequirements(ratio: number): void {
    this.centralBankPolicy.reserveRequirements = Math.max(1, Math.min(50, ratio));

    # Lower reserve requirements -> more lending -> more money creation
    const currentMultiplier = this.monetaryState.moneyMultiplier;
    const newMultiplier = currentMultiplier * (50 / ratio) * 0.9; # Inverse relationship with cushion
    this.monetaryState.moneyMultiplier = Math.max(1, newMultiplier);
  }

  /**
   # Get inflation history
   */
  getInflationHistory(): Array<{ rate: InflationRate; timestamp: number }> {
    return [...this.inflationHistory];
  }

  /**
   # Get inflation by type (food, energy, etc.)
   */
  getInflationByType(type: InflationIndicator): InflationRate {
    # In a full implementation, would track separate CPI components
    # For now, return the general inflation rate
    return this.monetaryState.inflationRate;
  }

  /**
   # Calculate real value adjusting for inflation
   */
  realValue(nominalValue: CurrencyAmount, years: number): CurrencyAmount {
    const history = this.inflationHistory;
    if (years <= 0 || years >= history.length) return nominalValue;

    # Calculate cumulative inflation over the period
    let cumulativeInflation = 1;
    const startIndex = history.length - years;
    for (let i = startIndex; i < history.length; i++) {
      cumulativeInflation *= 1 + (history[i].rate / 100);
    }

    return nominalValue / cumulativeInflation;
  }

  /**
   # Calculate nominal value from real value adjusting for inflation
   */
  nominalValue(realValue: CurrencyAmount, years: number): CurrencyAmount {
    const history = this.inflationHistory;
    if (years <= 0 || years >= history.length) return realValue;

    # Calculate cumulative inflation over the period
    let cumulativeInflation = 1;
    const startIndex = history.length - years;
    for (let i = startIndex; i < history.length; i++) {
      cumulativeInflation *= 1 + (history[i].rate / 100);
    }

    return realValue * cumulativeInflation;
  }
}