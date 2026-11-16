/**
 * Happiness and Quality of Life - System 16
 * 
 * Multidimensional happiness modelling with individual and societal indicators.
 * Economic consequences modelled through intermediate effects, not direct multipliers.
 */

// Happiness factor enum
export enum HappinessFactor {
  INCOME_SECURITY = "income_security",
  FOOD_AFFORDABILITY = "food_affordability",
  HOUSING_QUALITY = "housing_quality",
  HEALTH = "health",
  EDUCATION = "education",
  EMPLOYMENT = "employment",
  LEISURE = "leisure",
  SOCIAL_RELATIONSHIPS = "social_relationships",
  SAFETY = "safety",
  ENVIRONMENTAL_QUALITY = "environmental_quality",
  PERSONAL_FREEDOM = "personal_freedom",
  PUBLIC_SERVICES = "public_services"
}

// Individual happiness composite
export interface IndividualHappiness {
  factorScores: Map<HappinessFactor, number>; // 0-100 per factor
  overallScore: number; // 0-100
  lastCalculated: number;
  changeFromPrevious: number; // positive or negative
}

// Societal happiness indicators
export interface SocietalHappiness {
  averageHappiness: number; // 0-100
  incomeInequality: number; // Gini coefficient 0-1, converted to 0-100
  povertyRate: number; // percentage
  socialMobility: number; // 0-100, mobility score
  publicTrust: number; // 0-100
  communityStability: number; // 0-100
  lifeSatisfaction: number; // 0-100
  economicSecurity: number; // 0-100
}

// Happiness change drivers
export interface HappinessDrivers {
  incomeChange: number; // Percentage change in income
  employmentChange: number; // -50 to +50, employment status change
  foodPriceChange: number; // Percentage change in food prices
  housingCostChange: number; // Percentage change in housing costs
  healthStatusChange: number; // -50 to +50, health change
  educationAccessChange: number; // -50 to +50, education access change
  socialConnectionChange: number; // -50 to +50, social connections change
  safetyChange: number; // -50 to +50, safety perception change
  environmentalChange: number; // -50 to +50, environmental quality change
}

// Main happiness class
export class HappinessQualityOfLife {
  private individualHappiness: Map<string, IndividualHappiness> = new Map();
  private societalIndicators: SocietalHappiness;
  private readonly happinessFactorWeights: Record<HappinessFactor, number> = {
    [HappinessFactor.INCOME_SECURITY]: 0.15,
    [HappinessFactor.FOOD_AFFORDABILITY]: 0.12,
    [HappinessFactor.HOUSING_QUALITY]: 0.12,
    [HappinessFactor.HEALTH]: 0.18,
    [HappinessFactor.EDUCATION]: 0.10,
    [HappinessFactor.EMPLOYMENT]: 0.12,
    [HappinessFactor.LEISURE]: 0.05,
    [HappinessFactor.SOCIAL_RELATIONSHIPS]: 0.08,
    [HappinessFactor.SAFETY]: 0.06,
    [HappinessFactor.ENVIRONMENTAL_QUALITY]: 0.04,
    [HappinessFactor.PERSONAL_FREEDOM]: 0.04,
    [HappinessFactor.PUBLIC_SERVICES]: 0.06
  };

  constructor() {
    # Initialize societal indicators
    this.societalIndicators = {
      averageHappiness: 50,
      incomeInequality: 30, // Gini-like, lower = better
      povertyRate: 15,
      socialMobility: 60,
      publicTrust: 55,
      communityStability: 65,
      lifeSatisfaction: 50,
      economicSecurity: 60
    };

    # Initialize sample individuals
    this.initializeSampleIndividuals(100);
  }

  # Initialize sample individuals
  private initializeSampleIndividuals(count: number): void {
    for (let i = 0; i < count; i++) {
      const individual: IndividualHappiness = {
        factorScores: new Map<HappinessFactor, number>(),
        overallScore: 50,
        lastCalculated: Date.now(),
        changeFromPrevious: 0
      };

      # Initialize factor scores based on realistic distributions
      // Some factors default higher, some lower
      individual.factorScores.set(HappinessFactor.INCOME_SECURITY, 40 + Math.random() * 40);
      individual.factorScores.set(HappinessFactor.FOOD_AFFORDABILITY, 50 + Math.random() * 30);
      individual.factorScores.set(HappinessFactor.HOUSING_QUALITY, 45 + Math.random() * 35);
      individual.factorScores.set(HappinessFactor.HEALTH, 55 + Math.random() * 30);
      individual.factorScores.set(HappinessFactor.EDUCATION, 60 + Math.random() * 30);
      individual.factorScores.set(HappinessFactor.EMPLOYMENT, 50 + Math.random() * 35);
      individual.factorScores.set(HappinessFactor.LEISURE, 55 + Math.random() * 30);
      individual.factorScores.set(HappinessFactor.SOCIAL_RELATIONSHIPS, 50 + Math.random() * 40);
      individual.factorScores.set(HappinessFactor.SAFETY, 70 + Math.random() * 20);
      individual.factorScores.set(HappinessFactor.ENVIRONMENTAL_QUALITY, 50 + Math.random() * 30);
      individual.factorScores.set(HappinessFactor.PERSONAL_FREEDOM, 65 + Math.random() * 25);
      individual.factorScores.set(HappinessFactor.PUBLIC_SERVICES, 50 + Math.random() * 35);

      # Calculate overall score
      individual.overallScore = this.calculateOverallHappiness(individual.factorScores);

      individual.lastCalculated = Date.now();
      individual.changeFromPrevious = 0;

      this.individualHappiness.set(`individual-${i}`, individual);
    }
  }

  # Calculate overall happiness from factor scores
  calculateOverallHappiness(factorScores: Map<HappinessFactor, number>): number {
    let weightedSum = 0;
    let totalWeight = 0;

    for (const [factor, weight] of Object.entries(this.happinessFactorWeights)) {
      const score = factorScores.get(factor as HappinessFactor) || 50;
      weightedSum += score * weight;
      totalWeight += weight;
    }

    # Normalize
    const overall = totalWeight > 0 ? weightedSum / totalWeight : 50;

    return Math.max(0, Math.min(100, overall));
  }

  /**
   * Update individual happiness based on drivers
   */
  updateHappiness(
    individualId: string,
    drivers: HappinessDrivers
  ): { overallScore: number; change: number; factorUpdates: Map<HappinessFactor, number> } {
    const individual = this.individualHappiness.get(individualId);
    if (!individual) {
      // Create default
      const newIndividual: IndividualHappiness = {
        factorScores: new Map(),
        overallScore: 50,
        lastCalculated: Date.now(),
        changeFromPrevious: 0
      };

      for (const factor of Object.keys(this.happinessFactorWeights) as HappinessFactor[]) {
        newIndividual.factorScores.set(factor, 50);
      }
      newIndividual.overallScore = 50;

      this.individualHappiness.set(individualId, newIndividual);
      return this.updateHappiness(individualId, drivers);
    }

    const factorUpdates = new Map<HappinessFactor, number>();
    let totalChange = 0;

    # Update each factor based on corresponding driver
    const factorUpdatesList: Array<{ factor: HappinessFactor; current: number; driver: number }> = [
      { factor: HappinessFactor.INCOME_SECURITY, current: individual.factorScores.get(HappinessFactor.INCOME_SECURITY) || 50, driver: drivers.incomeChange },
      { factor: HappinessFactor.FOOD_AFFORDABILITY, current: individual.factorScores.get(HappinessFactor.FOOD_AFFORDABILITY) || 50, driver: drivers.foodPriceChange },
      { factor: HappinessFactor.HOUSING_QUALITY, current: individual.factorScores.get(HappinessFactor.HOUSING_QUALITY) || 50, driver: drivers.housingCostChange },
      { factor: HappinessFactor.HEALTH, current: individual.factorScores.get(HappinessFactor.HEALTH) || 50, driver: drivers.healthStatusChange },
      { factor: HappinessFactor.EDUCATION, current: individual.factorScores.get(HappinessFactor.EDUCATION) || 50, driver: drivers.educationAccessChange },
      { factor: HappinessFactor.EMPLOYMENT, current: individual.factorScores.get(HappinessFactor.EMPLOYMENT) || 50, driver: drivers.employmentChange },
      { factor: HappinessFactor.LEISURE, current: individual.factorScores.get(HappinessFactor.LEISURE) || 50, driver: 0 }, // Not directly driven here
      { factor: HappinessFactor.SOCIAL_RELATIONSHIPS, current: individual.factorScores.get(HappinessFactor.SOCIAL_RELATIONSHIPS) || 50, driver: drivers.socialConnectionChange },
      { factor: HappinessFactor.SAFETY, current: individual.factorScores.get(HappinessFactor.SAFETY) || 50, driver: drivers.safetyChange },
      { factor: HappinessFactor.ENVIRONMENTAL_QUALITY, current: individual.factorScores.get(HappinessFactor.ENVIRONMENTAL_QUALITY) || 50, driver: drivers.environmentalChange },
      { factor: HappinessFactor.PERSONAL_FREEDOM, current: individual.factorScores.get(HappinessFactor.PERSONAL_FREEDOM) || 50, driver: 0 },
      { factor: HappinessFactor.PUBLIC_SERVICES, current: individual.factorScores.get(HappinessFactor.PUBLIC_SERVICES) || 50, driver: 0 }
    ];

    for (const { factor, current, driver } of factorUpdatesList) {
      # Calculate change based on driver
      # Driver is percentage change or -50 to +50 scale
      let change = 0;

      if (factor === HappinessFactor.INCOME_SECURITY) {
        # Income change directly affects security
        change = driver * 0.8; # 0.8x pass-through
      } else if (factor === HappinessFactor.FOOD_AFFORDABILITY) {
        # Food price change affects affordability (negative = prices go up = happiness down)
        change = -driver * 0.6;
      } else if (factor === HappinessFactor.HOUSING_QUALITY) {
        # Housing cost change (negative = costs go up)
        change = -driver * 0.7;
      } else if (factor === HappinessFactor.HEALTH) {
        # Health status change
        change = driver * 1.2; # Health has strong impact
      } else if (factor === HappinessFactor.EDUCATION) {
        # Education access change
        change = driver * 0.5;
      } else if (factor === HappinessFactor.EMPLOYMENT) {
        # Employment change (-50 to +50)
        change = driver * 1.0;
      } else if (factor === HappinessFactor.SOCIAL_RELATIONSHIPS) {
        # Social connections
        change = driver * 0.9;
      } else if (factor === HappinessFactor.SAFETY) {
        # Safety perception
        change = driver * 1.1;
      } else if (factor === HappinessFactor.ENVIRONMENTAL_QUALITY) {
        # Environmental quality
        change = driver * 0.7;
      } else {
        change = driver * 0.5; # Default
      }

      # Smooth the change (don't jump instantly)
      const smoothedChange = (change - (current - 50) * 0.1); # Toward 50 baseline
      const newValue = Math.max(0, Math.min(100, current + smoothedChange));

      factorUpdates.set(factor, newValue);
      totalChange += Math.abs(newValue - current);
    }

    # Recalculate overall happiness
    const newOverall = this.calculateOverallHappiness(factorUpdates);

    # Update individual
    individual.factorScores = factorUpdates;
    individual.overallScore = newOverall;

    # Calculate change from previous
    const previousOverall = individual.overallScore; # This would be stored previously
    individual.changeFromPrevious = newOverall - previousOverall; # Simplified

    individual.lastCalculated = Date.now();

    return { overallScore: newOverall, change: newOverall - 0, factorUpdates };
  }

  /**
   * Update societal happiness indicators
   */
  updateSocietalIndicators(): void {
    # Calculate from individual happiness data
    const individuals = Array.from(this.individualHappiness.values());

    if (individuals.length === 0) {
      # No individuals, keep defaults
      return;
    }

    # Average happiness
    const avgHappiness = individuals.reduce((sum, ind) => sum + ind.overallScore, 0) / individuals.length;

    # Income inequality (simple: variance in income-related happiness)
    const incomeScores = individuals.map(ind => ind.factorScores.get(HappinessFactor.INCOME_SECURITY) || 50);
    const incomeMean = incomeScores.reduce((sum, s) => sum + s, 0) / incomeScores.length;
    const incomeVariance = incomeScores.reduce((sum, s) => sum + Math.pow(s - incomeMean, 2), 0) / incomeScores.length;
    const giniIndex = Math.sqrt(incomeVariance) / incomeMean; # Simplified Gini
    const inequalityScore = Math.max(0, Math.min(100, giniIndex * 100)); # Convert to 0-100

    # Poverty rate (based on low income security)
    const lowIncomeCount = incomeScores.filter(s => s < 30).length;
    const povertyRate = (lowIncomeCount / incomeScores.length) * 100;

    # Social mobility (based on education + employment factor correlations)
    const educationScores = individuals.map(ind => ind.factorScores.get(HappinessFactor.EDUCATION) || 50);
    const employmentScores = individuals.map(ind => ind.factorScores.get(HappinessFactor.EMPLOYMENT) || 50);
    const mobility = (educationScores.reduce((sum, s) => sum + s, 0) / educationScores.length +
      employmentScores.reduce((sum, s) => sum + s, 0) / employmentScores.length) / 2;
    const socialMobility = Math.max(0, Math.min(100, mobility));

    # Public trust (based on public services factor)
    const publicServiceScores = individuals.map(ind => ind.factorScores.get(HappinessFactor.PUBLIC_SERVICES) || 50);
    const publicTrust = publicServiceScores.reduce((sum, s) => sum + s, 0) / publicServiceScores.length;

    # Community stability (based on social relationships + economic security)
    const socialRelationshipScores = individuals.map(ind => ind.factorScores.get(HappinessFactor.SOCIAL_RELATIONSHIPS) || 50);
    const economicSecurityScores = individuals.map(ind => ind.factorScores.get(HappinessFactor.INCOME_SECURITY) || 50);
    const communityStability = (socialRelationshipScores.reduce((sum, s) => sum + s, 0) / socialRelationshipScores.length +
      economicSecurityScores.reduce((sum, s) => sum + s, 0) / economicSecurityScores.length) / 2;

    # Life satisfaction (almost same as overall happiness)
    const lifeSatisfaction = avgHappiness;

    # Economic security (based on income security)
    const economicSecurity = incomeScores.reduce((sum, s) => sum + s, 0) / incomeScores.length;

    # Update societal indicators
    this.societalIndicators = {
      averageHappiness: avgHappiness,
      incomeInequality: inequalityScore,
      povertyRate: Math.max(0, Math.min(100, povertyRate)),
      socialMobility: socialMobility,
      publicTrust: Math.max(0, Math.min(100, publicTrust)),
      communityStability: Math.max(0, Math.min(100, communityStability)),
      lifeSatisfaction: Math.max(0, Math.min(100, lifeSatisfaction)),
      economicSecurity: Math.max(0, Math.min(100, economicSecurity))
    };
  }

  /**
   * Get individual happiness
   */
  getIndividualHappiness(individualId: string): IndividualHappiness | undefined {
    return this.individualHappiness.get(individualId);
  }

  /**
   * Get all individual happiness data
   */
  getAllIndividualHappiness(): Map<string, IndividualHappiness> {
    return new Map(this.individualHappiness);
  }

  /**
   * Get societal indicators
   */
  getSocietalIndicators(): SocietalHappiness {
    return { ...this.societalIndicators };
  }

  /**
   * Get happiness drivers explanation
   */
  getHappinessDriversExplanation(): Record<HappinessFactor, string> {
    return {
      [HappinessFactor.INCOME_SECURITY]: "Financial stability and ability to meet basic needs",
      [HappinessFactor.FOOD_AFFORDABILITY]: "Ability to afford adequate food without sacrifice",
      [HappinessFactor.HOUSING_QUALITY]: "Quality and affordability of living arrangements",
      [HappinessFactor.HEALTH]: "Physical and mental wellbeing, access to care",
      [HappinessFactor.EDUCATION]: "Access to learning and skill development",
      [HappinessFactor.EMPLOYMENT]: "Job security and meaningful work",
      [HappinessFactor.LEISURE]: "Time for recreation and personal interests",
      [HappinessFactor.SOCIAL_RELATIONSHIPS]: "Strength of family and community ties",
      [HappinessFactor.SAFETY]: "Perception of safety from crime and harm",
      [HappinessFactor.ENVIRONMENTAL_QUALITY]: "Air, water, green spaces quality",
      [HappinessFactor.PERSONAL_FREEDOM]: "Autonomy and choice in life decisions",
      [HappinessFactor.PUBLIC_SERVICES]: "Quality of government services and infrastructure"
    };
  }

  /**
   * Economic consequences of happiness (intermediate effects, not direct multipliers)
   */
  economicConsequences(happinessData: {
    averageHappiness: number;
    povertyRate: number;
    unemploymentRate: number;
  }): {
    workerProductivityChange: number; // Percentage point change
    employeeRetentionChange: number; // Percentage point change
    consumerConfidenceChange: number; // Percentage point change
    labourParticipationChange: number; // Percentage point change
    migrationRateChange: number; // Percentage point change
    socialStabilityRisk: number; // 0-1, risk of instability
  } {
    const { averageHappiness, povertyRate, unemploymentRate } = happinessData;

    # Worker productivity: happy workers are more productive, but with diminishing returns
    const productivityBase = 5 + (averageHappiness - 50) * 0.3; # Each happiness point = 0.3% productivity
    const productivityChange = Math.max(-20, Math.min(20, productivityBase));

    # Employee retention: higher happiness reduces turnover
    const retentionChange = Math.min(30, (averageHappiness - 50) * 0.5); # Up to 30% improvement

    # Consumer confidence: happier people spend more
    const consumerConfidenceChange = Math.min(30, (averageHappiness - 50) * 0.6);

    # Labour participation: economic security affects participation
    const labourParticipationChange = -5 + (100 - povertyRate) * 0.1 - unemploymentRate * 0.2;

    # Migration rate: people move away from unhappy areas
    const migrationRateChange = (50 - averageHappiness) * 0.2; # Negative = people leave

    # Social stability risk: low happiness + high poverty + high unemployment = risk
    const socialStabilityRisk = Math.max(0, Math.min(1,
      (100 - averageHappiness) / 100 * 0.5 + povertyRate / 100 * 0.3 + unemploymentRate / 100 * 0.2));

    return {
      workerProductivityChange: productivityChange,
      employeeRetentionChange: retentionChange,
      consumerConfidenceChange: consumerConfidenceChange,
      labourParticipationChange: labourParticipationChange,
      migrationRateChange: migrationRateChange,
      socialStabilityRisk: socialStabilityRisk
    };
  }
}