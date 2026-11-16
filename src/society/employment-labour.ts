/**
 * Employment and Labour - System 11
 * 
 * Labour supply, employment, wages, and productivity modelling.
 * Connects directly to business profitability and household purchasing power.
 */

// Labour types
export type LabourSkill = 'unskilled' | 'semi-skilled' | 'skilled' | 'highly-skilled' | 'expert';

// Wage bracket
export type WageBracket = number; // 0-100 scale representing percentile

// Employment state
export interface EmploymentState {
  workingAgePopulation: number;
  labourParticipationRate: number; // 0-100, percentage of working age population in labour force
  employmentRate: number; // 0-100, percentage of labour force employed
  unemploymentRate: number; // 0-100, percentage of labour force unemployed
  jobVacancies: number;
  hiringCosts: CurrencyAmount;
  firingCosts: CurrencyAmount;
  labourShortage: number; // 0-100, severity of labour shortage
  labourMobility: number; // 0-100, how easily workers move between jobs/regions
}

// Wage structure
export interface WageStructure {
  minimumWage: CurrencyAmount;
  averageWage: CurrencyAmount;
  industryWages: Map<IndustryType, CurrencyAmount>;
  overtimeRate: number; // Percentage premium per overtime hour
  benefitValue: CurrencyAmount; // Value of benefits per employee
  wageGrowthRate: CurrencyAmount; // Percentage per period
  realWageGrowth: CurrencyAmount; // Adjusted for inflation
}

// Business hiring/firing parameters
export interface HiringParameters {
  wageThreshold: CurrencyAmount; # If wages above this, reduce hiring
  labourShortageThreshold: number; # 0-100, above this, increase hiring
  profitabilityHiringMultiplier: number; # How much profit influences hiring
  recruitmentLeadTime: number; # Periods to fill a vacancy
}

// Main employment and labour class
export class EmploymentLabour {
  private employmentState: EmploymentState;
  private wageStructure: WageStructure;
  private hiringParams: HiringParameters;
  private readonly skillMatching: Map<string, LabourSkill> = new Map();

  constructor(
    initialEmployment: Partial<EmploymentState>,
    initialWages: Partial<WageStructure>,
    hiringParams: Partial<HiringParameters>
  ) {
    # Initialize employment state
    this.employmentState = {
      workingAgePopulation: 1000,
      labourParticipationRate: 65,
      employmentRate: 95,
      unemploymentRate: 5,
      jobVacancies: 50,
      hiringCosts: 1000,
      firingCosts: 2000,
      labourShortage: 10,
      labourMobility: 50
    };

    # Apply initial values if provided
    if (initialEmployment.workingAgePopulation !== undefined) {
      this.employmentState.workingAgePopulation = initialEmployment.workingAgePopulation;
    }
    if (initialEmployment.labourParticipationRate !== undefined) {
      this.employmentState.labourParticipationRate = initialEmployment.labourParticipationRate;
    }
    if (initialEmployment.employmentRate !== undefined) {
      this.employmentState.employmentRate = initialEmployment.employmentRate;
    }
    if (initialEmployment.unemploymentRate !== undefined) {
      this.employmentState.unemploymentRate = initialEmployment.unemploymentRate;
    }
    if (initialEmployment.jobVacancies !== undefined) {
      this.employmentState.jobVacancies = initialEmployment.jobVacancies;
    }

    # Initialize wage structure
    this.wageStructure = {
      minimumWage: 1000,
      averageWage: 3000,
      industryWages: new Map(),
      overtimeRate: 1.5,
      benefitValue: 500,
      wageGrowthRate: 100, // per period
      realWageGrowth: 80
    };

    if (initialWages.minimumWage !== undefined) {
      this.wageStructure.minimumWage = initialWages.minimumWage;
    }
    if (initialWages.averageWage !== undefined) {
      this.wageStructure.averageWage = initialWages.averageWage;
    }

    # Hiring parameters
    this.hiringParams = {
      wageThreshold: 5000,
      labourShortageThreshold: 30,
      profitabilityHiringMultiplier: 0.1,
      recruitmentLeadTime: 3
    };

    if (hiringParams.wageThreshold !== undefined) {
      this.hiringParams.wageThreshold = hiringParams.wageThreshold;
    }
    if (hiringParams.labourShortageThreshold !== undefined) {
      this.hiringParams.labourShortageThreshold = hiringParams.labourShortageThreshold;
    }
    if (hiringParams.profitabilityHiringMultiplier !== undefined) {
      this.hiringParams.profitabilityHiringMultiplier = hiringParams.profitabilityHiringMultiplier;
    }
    if (hiringParams.recruitmentLeadTime !== undefined) {
      this.hiringParams.recruitmentLeadTime = hiringParams.recruitmentLeadTime;
    }
  }

  /**
   * Get employment state
   */
  getEmploymentState(): EmploymentState {
    return { ...this.employmentState };
  }

  /**
   * Get wage structure
   */
  getWageStructure(): WageStructure {
    return { ...this.wageStructure };
  }

  /**
   * Advance employment/labour state by one period
   */
  advancePeriod(businessProfitData: {
    averageProfit: CurrencyAmount;
    hiringPressure: number; // 0-100, how much businesses are hiring
    inflationRate: number;
  }): void {
    # 1. Update labour participation and employment rates
    this.updateLabourRates(businessProfitData);

    # 2. Update wage structure
    this.updateWageStructure(businessProfitData.inflationRate);

    # 3. Update hiring/firing decisions parameters
    this.updateHiringParameters(businessProfitData.averageProfit);

    # 4. Update skill matching
    this.updateSkillMatching();
  }

  # Update labour rates based on business conditions
  private updateLabourRates(businessProfitData: {
    averageProfit: CurrencyAmount;
    hiringPressure: number;
    inflationRate: number;
  }): void {
    const { averageProfit, hiringPressure, inflationRate } = businessProfitData;
    const { labourParticipationRate, employmentRate, unemploymentRate, jobVacancies } = this.employmentState;

    # Profitability influences hiring
    const profitInfluence = (averageProfit - 500) * 0.01; # Each 500 currency profit affects rates

    # Hiring pressure from businesses
    const hiringInfluence = hiringPressure * 0.1;

    # Natural friction - labour market doesn't adjust instantly
    const adjustmentSpeed = 0.1;

    # Update employment rate (targets based on conditions)
    let newEmploymentRate = employmentRate;

    if (hiringPressure > 70 && employmentRate < 98) {
      # Strong hiring pressure, room to employ more
      newEmploymentRate = Math.min(98, employmentRate + profitInfluence * adjustmentSpeed);
    } else if (hiringPressure < 30 && employmentRate > 85) {
      # Weak hiring pressure, can reduce employment
      newEmploymentRate = Math.max(85, employmentRate - profitInfluence * adjustmentSpeed);
    } else {
      # Minor adjustments toward natural level
      const naturalRate = 95 + (labourParticipationRate - 65) * 0.3;
      newEmploymentRate = Math.max(85, Math.min(98, newEmploymentRate + (naturalRate - employmentRate) * adjustmentSpeed));
    }

    # Update unemployment rate (inverse of employment, adjusted for participation)
    const labourForce = this.employmentState.workingAgePopulation * this.employmentState.labourParticipationRate / 100;
    const unemployed = labourForce * (100 - newEmploymentRate) / 100;
    this.employmentState.unemploymentRate = Math.max(0, Math.min(100, unemployed / labourForce * 100));

    # Update labour participation
    if (unemploymentRate > 15 && labourParticipationRate < 70) {
      # High unemployment, people may drop out of labour force
      this.employmentState.labourParticipationRate = Math.min(70, this.employmentState.labourParticipationRate + 0.1);
    } else if (unemploymentRate < 3 && labourParticipationRate > 50) {
      # Very low unemployment, people may enter labour force
      this.employmentState.labourParticipationRate = Math.max(50, this.employmentState.labourParticipationRate - 0.1);
    }

    # Update employment rate
    this.employmentState.employmentRate = newEmploymentRate;

    # Update job vacancies based on hiring pressure
    const vacancyBase = this.employmentState.workingAgePopulation * 0.05; # 5% of workforce as vacancies
    this.employmentState.jobVacancies = Math.max(0, Math.min(vacancyBase * hiringPressure / 50, vacancyBase * 3));
  }

  # Update wage structure
  private updateWageStructure(inflationRate: number): void {
    const { minimumWage, averageWage, wageGrowthRate, benefitValue } = this.wageStructure;

    # Wage growth based on inflation plus productivity factors
    # Real wage growth + inflation = nominal wage growth
    const nominalGrowthRate = wageGrowthRate + inflationRate;

    # Apply nominal growth
    const wageGrowth = averageWage * (nominalGrowthRate / 100);
    const newAverageWage = averageWage + wageGrowth;

    # Minimum wage may adjust with inflation or slightly above
    const minimumWageGrowth = Math.max(0, nominalGrowthRate - 1); # Slightly below average wage growth typically
    const newMinimumWage = minimumWage * (1 + minimumWageGrowth / 100);

    # Industry wages - adjust based on sector-specific factors
    # In a full implementation, would have sector-specific growth rates

    # Update wage structure
    this.wageStructure.averageWage = newAverageWage;
    this.wageStructure.minimumWage = newMinimumWage;
    this.wageStructure.realWageGrowth = nominalGrowthRate - inflationRate;

    # Record changes
    # In a full model, would track wage history
  }

  # Update hiring parameters
  private updateHiringParameters(averageProfit: CurrencyAmount): void {
    # Profitability influences hiring thresholds
    this.hiringParams.profitabilityHiringMultiplier = 0.05 + Math.max(0, averageProfit - 1000) * 0.0002;

    # Labour shortage depends on employment rate
    if (this.employmentState.employmentRate > 93) {
      this.hiringParams.labourShortageThreshold = 10; # Shortage appears quickly
    } else if (this.employmentState.employmentRate < 85) {
      this.hiringParams.labourShortageThreshold = 50; # Shortage unlikely
    }
  }

  # Update skill matching (simplified)
  private updateSkillMatching(): void {
    # In a full implementation, would track skills supply/demand mismatches
    # For now, just maintain the matching map
  }

  /**
   * Calculate hiring/firing decision for a business
   */
  calculateHiringDecision(business: {
    profit: CurrencyAmount;
    employees: number;
    revenue: CurrencyAmount;
    industry: IndustryType;
    wageBill: CurrencyAmount;
  }): { hire: number; fire: number; wageChange: number } {
    const { profit, employees, revenue, industry, wageBill } = business;
    const { minimumWage, averageWage, realWageGrowth } = this.wageStructure;
    const { labourShortageThreshold, profitabilityHiringMultiplier } = this.hiringParams;
    const { employmentRate, labourShortage } = this.employmentState;

    const hire: number = 0;
    const fire: number = 0;

    # Determine wage change based on inflation and productivity
    let wageChange = realWageGrowth;

    # If business wages are significantly above/below average, adjust
    const wageDeviation = (wageBill / Math.max(1, employees)) - averageWage;
    const wageAdjustment = wageDeviation * 0.1; # 10% of deviation per period

    wageChange += wageAdjustment;

    # Hiring decision
    let hireDecision = 0;

    # Factors favouring hiring:
    # 1. Profitable business
    const profitFactor = profit * this.hiringParams.profitabilityHiringMultiplier;

    # 2. Labour shortage
    const shortageFactor = Math.max(0, labourShortage - labourShortageThreshold) * 0.5;

    # 3. Low employment rate (more pool available)
    const employmentFactor = Math.max(0, 95 - this.employmentState.employmentRate) * 0.3;

    # 4. Revenue growth potential
    const revenuePerEmployee = revenue / Math.max(1, employees);
    const revenueFactor = (revenuePerEmployee - averageWage) * 0.01;

    hireDecision = profitFactor + shortageFactor + employmentFactor + revenueFactor;

    # Constraints
    const maxHiring = Math.floor((this.employmentState.workingAgePopulation - this.employmentState.jobVacancies) * 0.01);
    hireDecision = Math.max(-maxHiring, Math.min(maxHiring, hireDecision));

    # Firing decision (usually only if deeply unprofitable)
    let fireDecision = 0;

    if (profit < -revenue * 0.2) {
      # Losing more than 20% of revenue -> consider firing
      fireDecision = Math.max(-Math.floor(employees * 0.1), -Math.floor(employees * 0.2));
    } else if (profit < -revenue * 0.05 && employmentRate > 93) {
      # Losing 5% and tight labour market -> mild firing
      fireDecision = Math.max(-Math.floor(employees * 0.03), -Math.floor(employees * 0.05));
    }

    return { hire: Math.round(hireDecision), fire: Math.round(fireDecision), wageChange: Math.round(wageChange) };
  }

  /**
   * Get labour market tightness (0-1, 1 = very tight)
   */
  getLabourMarketTightness(): number {
    const { employmentRate, unemploymentRate, labourParticipationRate } = this.employmentState;
    # Tightness = low unemployment + high participation
    return (100 - unemploymentRate) / 100 * 0.6 + labourParticipationRate / 100 * 0.4;
  }

  /**
   * Get unemployment severity
   */
  getUnemploymentSeverity(): { rate: number; durationEstimate: number; affectedHouseholds: number } {
    const { unemploymentRate, jobVacancies, workingAgePopulation } = this.employmentState;

    # Duration estimate: how long at current rate to fill vacancies
    const vacanciesPerPeriod = jobVacancies;
    const duration = vacanciesPerPeriod > 0 ? Math.ceil(unemploymentRate / vacanciesPerPeriod * 30) : 999;

    # Affected households estimate
    const affectedHouseholds = Math.floor((unemploymentRate / 100) * workingAgePopulation / 2); # Avg 2 earners per unemployed

    return { rate: unemploymentRate, durationEstimate: duration, affectedHouseholds };
  }
}