/**
 * Taxation and Public Finance - System 13
 * 
 * Tax types, public spending, fiscal factors and government financial decisions.
 * Tax evasion and corruption represented as economic/legal mechanics.
 */

// Tax type enum
export enum TaxType {
  PERSONAL_INCOME = "personal_income",
  CORPORATE = "corporate",
  SALES = "sales",
  PROPERTY = "property",
  LAND = "land",
  IMPORT_DUTIES = "import_duties",
  EXPORT_DUTIES = "export_duties",
  PAYROLL = "payroll",
  CAPITAL_GAINS = "capital_gains",
  ENVIRONMENTAL = "environmental"
}

// Tax bracket
export type TaxBracket = {
  minIncome: CurrencyAmount;
  maxIncome: CurrencyAmount;
  rate: number; // percentage
};

// Tax assessment
export interface TaxAssessment {
  taxpayerId: string;
  taxType: TaxType;
  taxableAmount: CurrencyAmount;
  taxRate: number;
  taxDue: CurrencyAmount;
  taxesPaid: CurrencyAmount;
  filingStatus: 'single' | 'married' | 'head_of_household' | 'business';
  assessmentDate: number;
  complianceStatus: 'compliant' | 'under_review' | 'evaded' | 'fraudulent';
}

// Public spending area
export interface PublicSpendingArea {
  area: keyof GovernmentBudget;
  allocatedAmount: CurrencyAmount;
  spentAmount: CurrencyAmount;
  utilizationRate: number; // 0-1
  efficiencyRating: number; // 0-1, administrative efficiency
  lastAudit: number;
  auditFindings: Array<{ finding: string; severity: number; resolved: boolean }>;
}

// Fiscal factors
export interface FiscalFactors {
  governmentRevenue: CurrencyAmount;
  governmentExpenditure: CurrencyAmount;
  budgetDeficit: CurrencyAmount;
  budgetSurplus: CurrencyAmount;
  publicDebt: CurrencyAmount;
  debtServicing: CurrencyAmount; // Interest on debt
  taxCompliance: number; // 0-100, percentage of taxes collected
  taxEvasion: number; // 0-100, estimated evasion rate
  fiscalSustainability: number; // 0-1, score of long-term sustainability
}

// Tax evasion and corruption metadata
export interface TaxEvasionMetadata {
  evasionRate: number; // Estimated percentage of non-compliance
  corruptionLevel: number; // 0-100, systemic corruption
  enforcementEffort: number; // 0-100, resources devoted to enforcement
  lastEnforcementAction: number;
  convictedCases: number; // Recent tax crime convictions
}

// Main taxation system
export class TaxationPublicFinance {
  private fiscalFactors: FiscalFactors;
  private taxAssessments: Map<string, TaxAssessment> = new Map();
  private taxEvasionMetadata: TaxEvasionMetadata;
  private spendingAreas: Map<keyof GovernmentBudget, PublicSpendingArea> = new Map();

  constructor() {
    # Initialize fiscal factors
    this.fiscalFactors = {
      governmentRevenue: 0,
      governmentExpenditure: 0,
      budgetDeficit: 0,
      budgetSurplus: 0,
      publicDebt: 10000,
      debtServicing: 0,
      taxCompliance: 85,
      taxEvasion: 15,
      fiscalSustainability: 0.8
    };

    # Initialize tax evasion metadata
    this.taxEvasionMetadata = {
      evasionRate: 15,
      corruptionLevel: 10,
      enforcementEffort: 50,
      lastEnforcementAction: Date.now(),
      convictedCases: 0
    };

    # Initialize spending areas
    this.initializeSpendingAreas();
  }

  # Initialize spending areas
  private initializeSpendingAreas(): void {
    const areas: Array<keyof GovernmentBudget> = [
      'healthcare',
      'education',
      'infrastructure',
      'agriculture',
      'defence',
      'public_administration',
      'welfare',
      'environment'
    ];

    for (const area of areas) {
      this.spendingAreas.set(area, {
        area,
        allocatedAmount: 0,
        spentAmount: 0,
        utilizationRate: 0,
        efficiencyRating: 0.7,
        lastAudit: Date.now(),
        auditFindings: []
      });
    }
  }

  /**
   * Calculate tax revenue from a taxable amount
   */
  calculateTax(taxableAmount: CurrencyAmount, taxRate: number): CurrencyAmount {
    return Math.round(taxableAmount * taxRate / 100);
  }

  /**
   * Assess tax for a taxpayer
   */
  assessTax(
    taxpayerId: string,
    taxType: TaxType,
    taxableAmount: CurrencyAmount,
    filingStatus: 'single' | 'married' | 'head_of_household' | 'business'
  ): TaxAssessment {
    # Determine tax rate based on type and existing rates
    const taxRate = this.getTaxRate(taxType);

    # Calculate tax due
    const taxDue = this.calculateTax(taxableAmount, taxRate);

    # Check for evasion (simplified: random compliance check)
    const complianceRoll = Math.random() * 100;
    const evasionThreshold = 100 - this.taxEvasionMetadata.evasionRate;
    const isEvasive = complianceRoll > evasionThreshold;

    const complianceStatus: 'compliant' | 'under_review' | 'evaded' | 'fraudulent' =
      isEvasive ? (taxDue > 1000 ? 'fraudulent' : 'evaded') : 'compliant';

    # Create assessment
    const assessment: TaxAssessment = {
      taxpayerId,
      taxType,
      taxableAmount,
      taxRate,
      taxDue,
      taxesPaid: isEvasive ? 0 : taxDue,
      filingStatus,
      assessmentDate: Date.now(),
      complianceStatus
    };

    # Store assessment
    this.taxAssessments.set(taxpayerId, assessment);

    # Update evasion metadata
    this.updateEvasionMetadata(isEvasive);

    return assessment;
  }

  # Get tax rate for a type
  private getTaxRate(taxType: TaxType): number {
    # Return rate from budget tax rates, or default
    const rate = this.fiscalFactors.governmentRevenue > 0
      ? Math.random() * 30 // Simplified: revenue influences rates
      : 20; # Default 20%

    # Specific rates by type
    const typeRates: Record<TaxType, number> = {
      [TaxType.PERSONAL_INCOME]: 20,
      [TaxType.CORPORATE]: 25,
      [TaxType.SALES]: 10,
      [TaxType.PROPERTY]: 1.5,
      [TaxType.LAND]: 2.0,
      [TaxType.IMPORT_DUTIES]: 5,
      [TaxType.EXPORT_DUTIES]: 5,
      [TaxType.PAYROLL]: 12,
      [TaxType.CAPITAL_GAINS]: 15,
      [TaxType.ENVIRONMENTAL]: 2
    };

    return typeRates[taxType] || 20;
  }

  # Update evasion metadata
  private updateEvasionMetadata(isEvasive: boolean): void {
    if (isEvasive) {
      this.taxEvasionMetadata.evasionRate = Math.min(100, this.taxEvasionMetadata.evasionRate + 0.5);
      this.taxEvasionMetadata.corruptionLevel = Math.min(100, this.taxEvasionMetadata.corruptionLevel + 1);
      this.taxEvasionMetadata.convictedCases++;
    } else {
      # Slow natural decrease in evasion
      this.taxEvasionMetadata.evasionRate = Math.max(0, this.taxEvasionMetadata.evasionRate - 0.1);
    }

    this.taxEvasionMetadata.lastEnforcementAction = Date.now();
  }

  /**
   * Collect tax revenue (simulated collection)
   */
  collectRevenue(): CurrencyAmount {
    # Calculate revenue from all assessments
    let totalRevenue = 0;
    const compliantAssessments = Array.from(this.taxAssessments.values()).filter(
      a => a.complianceStatus === 'compliant'
    );

    for (const assessment of compliantAssessments) {
      totalRevenue += assessment.taxDue;
    }

    # Update fiscal factors
    this.fiscalFactors.governmentRevenue = totalRevenue;

    # Update tax compliance rate
    const totalAssessments = this.taxAssessments.size;
    const compliantCount = compliantAssessments.length;
    if (totalAssessments > 0) {
      this.fiscalFactors.taxCompliance = Math.round((compliantCount / totalAssessments) * 100);
    }

    # Update evasion rate
    this.fiscalFactors.taxEvasion = 100 - this.fiscalFactors.taxCompliance;

    return totalRevenue;
  }

  # Allocate spending to government areas
  allocateSpending(area: keyof GovernmentBudget, amount: CurrencyAmount): void {
    const spendingArea = this.spendingAreas.get(area);
    if (!spendingArea) return;

    # Allocate the amount
    spendingArea.allocatedAmount += amount;

    # Update utilization (spent vs allocated)
    # In a full model, would track over time
    spendingArea.utilizationRate = Math.min(1, spendingArea.spentAmount / Math.max(1, spendingArea.allocatedAmount));

    # Update fiscal expenditure
    this.fiscalFactors.governmentExpenditure += amount;
    this.fiscalFactors.budgetDeficit += amount; # Deficit increases by spending
    this.fiscalFactors.publicDebt += amount * 0.5; # Debt increases by partial amount (some funded from revenue)

    # Update debt servicing
    this.updateDebtServicing();
  }

  # Update debt servicing costs
  private updateDebtServicing(): void {
    const { publicDebt, governmentRevenue } = this.fiscalFactors;

    # Debt servicing as percentage of revenue
    const interestRate = 5; % annual interest
    const annualServicing = publicDebt * interestRate / 100;

    # Monthly servicing
    this.fiscalFactors.debtServicing = annualServicing / 12;

    # Check fiscal sustainability
    const revenue = Math.max(1, governmentRevenue);
    const debtToRevenueRatio = publicDebt / revenue;

    # Sustainability score: lower is better
    let sustainability = Math.max(0, Math.min(1, 1 - (debtToRevenueRatio - 0.5) * 0.5));
    this.fiscalFactors.fiscalSustainability = sustainability;
  }

  # Public spending by area
  spendOnArea(area: keyof GovernmentBudget, amount: CurrencyAmount): void {
    # Allocate spending
    this.allocateSpending(area, amount);

    # Find the spending area record
    const spendingArea = this.spendingAreas.get(area);
    if (!spendingArea) return;

    # Update spent amount (simulate spending over time)
    spendingArea.spentAmount = Math.min(spendingArea.allocatedAmount, spendingArea.spentAmount + amount * 0.1); # 10% spent per call

    # Update efficiency based on utilization
    if (spendingArea.utilizationRate > 0) {
      spendingArea.efficiencyRating = Math.max(0.3, Math.min(1, 0.7 - spendingArea.utilizationRate * 0.2));
    }
  }

  /**
   * Tax policy adjustment
   */
  adjustTaxRate(taxType: TaxType, newRate: number): void {
    # In a full implementation, would update the tax rate structure
    # and recalculate revenue impacts

    # Simple: just note the change
    # The actual rate application happens in assessTax via getTaxRate
    # This method could update default rates for specific types
  }

  /**
   * Tax evasion/corruption event
   */
  recordEvasionEvent(severity: 'low' | 'medium' | 'high', amount: CurrencyAmount, cause: string): void {
    # Record a tax evasion or corruption event
    this.taxEvasionMetadata.evasionRate = Math.min(100, this.taxEvasionMetadata.evasionRate + 5);

    # Increased enforcement may follow
    const enforcementIncrease = severity === 'high' ? 10 : severity === 'medium' ? 5 : 2;
    this.taxEvasionMetadata.enforcementEffort = Math.min(100, this.taxEvasionMetadata.enforcementEffort + enforcementIncrease);

    # Corruption may increase if evasion is high and enforcement low
    const evasion = this.taxEvasionMetadata.evasionRate;
    const enforcement = this.taxEvasionMetadata.enforcementEffort;
    if (evasion > 40 && enforcement < 30) {
      this.taxEvasionMetadata.corruptionLevel = Math.min(100, this.taxEvasionMetadata.corruptionLevel + 3);
    }

    this.taxEvasionMetadata.lastEnforcementAction = Date.now();
  }

  /**
   * Anti-corruption enforcement action
   */
  performEnforcementAction(severity: 'low' | 'medium' | 'high'): void {
    # Crackdown on tax evasion/corruption
    const reduction = severity === 'high' ? 15 : severity === 'medium' ? 8 : 3;

    this.taxEvasionMetadata.evasionRate = Math.max(0, this.taxEvasionMetadata.evasionRate - reduction);
    this.taxEvasionMetadata.corruptionLevel = Math.max(0, this.taxEvasionMetadata.corruptionLevel - reduction);
    this.taxEvasionMetadata.convictedCases++;
    this.taxEvasionMetadata.enforcementEffort = Math.min(100, this.taxEvasionMetadata.enforcementEffort + 5);

    # May cause short-term political friction
    # In full model, would affect approval ratings
  }

  /**
   * Get fiscal factors
   */
  getFiscalFactors(): FiscalFactors {
    return { ...this.fiscalFactors };
  }

  /**
   * Get tax evasion metadata
   */
  getEvasionMetadata(): TaxEvasionMetadata {
    return { ...this.taxEvasionMetadata };
  }

  /**
   * Get all tax assessments
   */
  getTaxAssessments(): Map<string, TaxAssessment> {
    return new Map(this.taxAssessments);
  }

  /**
   * Get spending area info
   */
  getSpendingArea(area: keyof GovernmentBudget): PublicSpendingArea | undefined {
    return this.spendingAreas.get(area);
  }

  /**
   * Get all spending areas
   */
  getAllSpendingAreas(): Map<keyof GovernmentBudget, PublicSpendingArea> {
    return new Map(this.spendingAreas);
  }

  /**
   * Get tax compliance rate
   */
  getTaxComplianceRate(): number {
    return this.fiscalFactors.taxCompliance;
  }

  /**
   * Get tax evasion rate
   */
  getTaxEvasionRate(): number {
    return this.fiscalFactors.taxEvasion;
  }

  /**
   * Fiscal sustainability score
   */
  getFiscalSustainability(): number {
    return this.fiscalFactors.fiscalSustainability;
  }
}