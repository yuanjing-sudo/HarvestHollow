/**
 * Healthcare and Education - System 17
 * 
 * Hospital capacity, medical staff, disease prevalence, school capacity,
 * teacher availability and education spending.
 */

// Healthcare interface
export interface Healthcare {
  hospitalCapacity: number; // beds per 1000 population
  medicalStaff: number; // doctors/nurses per 1000 population
  healthcareSpending: CurrencyAmount;
  diseasePrevalence: Map<DiseaseType, number>; // disease -> prevalence (0-100)
  accessToTreatment: number; // 0-1, how easy to access
  healthcareCosts: CurrencyAmount;
  lifeExpectancy: number; // years
}

// Disease types
export enum DiseaseType {
  INFLUENZA = "influenza",
  MALARIA = "malaria",
  TUBERCULOSIS = "tuberculosis",
  DIABETES = "diabetes",
  HEART_DISEASE = "heart_disease",
  CANCER = "cancer",
  CHOLERA = "cholera",
  DENGUE = "dengue",
  COVID19 = "covid19"
}

// Education interface
export interface Education {
  schoolCapacity: number; // schools per 1000 children
  teacherAvailability: number; // teachers per 1000 population
  educationSpending: CurrencyAmount;
  literacyRate: number; // 0-100 percentage
  technicalSkills: number; // 0-100, percentage with technical/vocational training
  higherEducationRate: number; // 0-100, percentage in higher education
  researchCapability: number; // 0-100, research institutions and output
  vocationalTraining: number; // 0-100, vocational training availability
}

// Public health indicators
export interface PublicHealthIndicators {
  infantMortality: number; // per 1000 live births
  maternalMortality: number; // per 100,000 live births
  vaccinationRate: number; // 0-100 percentage
  averageLifeExpectancy: number; // years
  healthAdjustedLifeExpectancy: number; // years in good health
}

// Main healthcare-education class
export class HealthcareEducation {
  private healthcare: Healthcare;
  private education: Education;
  private publicHealth: PublicHealthIndicators;
  private readonly diseaseProgressionRates: Record<DiseaseType, number> = {
    [DiseaseType.INFLUENZA]: 0.1,      // 10% daily progression rate
    [DiseaseType.MALARIA]: 0.05,       // 5% daily
    [DiseaseType.TUBERCULOSIS]: 0.02,  // 2% daily
    [DiseaseType.DIABETES]: 0.001,     // 0.1% daily (chronic)
    [DiseaseType.HEART_DISEASE]: 0.002, // 0.2% daily (chronic)
    [DiseaseType.CANCER]: 0.0005,      // 0.05% daily (chronic)
    [DiseaseType.CHOLERA]: 0.2,        // 20% daily (acute)
    [DiseaseType.DENGUE]: 0.1,         // 10% daily
    [DiseaseType.COVID19]: 0.08        // 8% daily
  };

  constructor() {
    # Initialize healthcare
    this.healthcare = {
      hospitalCapacity: 2.5, // beds per 1000
      medicalStaff: 3.0, // per 1000
      healthcareSpending: 0,
      diseasePrevalence: new Map(),
      accessToTreatment: 0.8,
      healthcareCosts: 0,
      lifeExpectancy: 75
    };

    # Initialize disease prevalence
    for (const disease of Object.values(DiseaseType)) {
      this.healthcare.diseasePrevalence.set(disease, 0);
    }

    # Initialize education
    this.education = {
      schoolCapacity: 1.5, // schools per 1000 children
      teacherAvailability: 2.0, // per 1000
      educationSpending: 0,
      literacyRate: 90,
      technicalSkills: 40,
      higherEducationRate: 30,
      researchCapability: 50,
      vocationalTraining: 35
    };

    # Initialize public health
    this.publicHealth = {
      infantMortality: 10,
      maternalMortality: 20,
      vaccinationRate: 85,
      averageLifeExpectancy: 75,
      healthAdjustedLifeExpectancy: 65
    };

    # Initialize common diseases
    for (const disease of Object.values(DiseaseType)) {
      this.healthcare.diseasePrevalence.set(disease, 0.1); // 0.1% baseline
    }
  }

  /**
   * Advance healthcare and education by one period
   */
  advancePeriod(deltaDays: number, economicData: {
    gdpGrowth: number;
    inflationRate: number;
    governmentBudget: CurrencyAmount;
  }): void {
    # 1. Update disease progression
    this.updateDiseaseProgression(deltaDays);

    # 2. Update healthcare spending and outcomes
    this.updateHealthcareSpending(economicData);

    # 3. Update education spending and outcomes
    this.updateEducationSpending(economicData);

    # 4. Update public health indicators
    this.updatePublicHealthIndicators();

    # 5. Advance life expectancy based on outcomes
    this.updateLifeExpectancy();
  }

  # Update disease progression
  private updateDiseaseProgression(deltaDays: number): void {
    const days = deltaDays / 30; // Monthly periods

    for (const [disease, baseline] of this.healthcare.diseasePrevalence.entries()) {
      const progressionRate = this.diseaseProgressionRates[disease] || 0.05;

      # Disease spread/increase based on rate
      const change = baseline * progressionRate * days;

      # New prevalence (clamped)
      const newPrevalence = Math.max(0, Math.min(100, baseline + change));

      this.healthcare.diseasePrevalence.set(disease, newPrevalence);
    }
  }

  # Update healthcare spending
  private updateHealthcareSpending(economicData: {
    gdpGrowth: number;
    inflationRate: number;
    governmentBudget: CurrencyAmount;
  }): void {
    const { governmentBudget, inflationRate } = economicData;
    const previousSpending = this.healthcare.healthcareSpending;

    # Healthcare spending grows with GDP and inflation
    const gdpGrowthFactor = economicData.gdpGrowth / 100;
    const inflationFactor = inflationRate / 100;

    # Increase spending
    const spendingIncrease = previousSpending * (gdpGrowthFactor + inflationFactor);
    this.healthcare.healthcareSpending = previousSpending + spendingIncrease;

    # Update access to treatment based on spending per capita
    # Simplified: more spending = better access
    const spendingPerCapitaFactor = this.healthcare.healthcareSpending / Math.max(1, 10000);
    this.healthcare.accessToTreatment = Math.min(1, 0.5 + spendingPerCapitaFactor * 0.0001);

    # Healthcare costs
    this.healthcare.healthcareCosts = this.healthcare.healthcareSpending * 0.8;
  }

  # Update education spending
  private updateEducationSpending(economicData: {
    gdpGrowth: number;
    inflationRate: number;
    governmentBudget: CurrencyAmount;
  }): void {
    const { governmentBudget, inflationRate } = economicData;
    const previousSpending = this.education.educationSpending;

    # Education spending grows with GDP
    const gdpGrowthFactor = economicData.gdpGrowth / 100;

    # Increase spending (education often lagging slightly)
    const spendingIncrease = previousSpending * gdpGrowthFactor * 0.8;
    this.education.educationSpending = previousSpending + spendingIncrease;

    # Update education metrics
    # Literacy improves with spending
    const literacyChange = spendingIncrease * 0.01; # Small impact
    this.education.literacyRate = Math.min(100, this.education.literacyRate + literacyChange);

    # Teacher availability improves with spending
    const teacherChange = spendingIncrease * 0.005;
    this.education.teacherAvailability = Math.max(0, this.education.teacherAvailability + teacherChange);

    # Higher education access
    const higherEdChange = spendingIncrease * 0.003;
    this.education.higherEducationRate = Math.min(100, this.education.higherEducationRate + higherEdChange);

    # Technical skills
    const techChange = spendingIncrease * 0.004;
    this.education.technicalSkills = Math.max(0, Math.min(100, this.education.technicalSkills + techChange));

    # Research capability
    const researchChange = spendingIncrease * 0.008;
    this.education.researchCapability = Math.max(0, Math.min(100, this.education.researchCapability + researchChange));

    # Vocational training
    const vocationalChange = spendingIncrease * 0.006;
    this.education.vocationalTraining = Math.max(0, Math.min(100, this.education.vocationalTraining + vocationalChange));
  }

  # Update public health indicators
  private updatePublicHealthIndicators(): void {
    # Infant mortality influenced by healthcare access and disease prevalence
    const access = this.healthcare.accessToTreatment;
    const diseaseBurden = Array.from(this.healthcare.diseasePrevalence.values())
      .reduce((sum, prevalence) => sum + prevalence, 0) / Object.values(DiseaseType).length;

    # Base infant mortality ~10 per 1000, improved by access and worsened by disease
    const baseInfantMortality = 10;
    const accessImprovement = (1 - access) * 5; # Less access = higher mortality
    const diseaseImpact = diseaseBurden * 0.5; # Disease burden increases mortality

    const newInfantMortality = Math.max(0, baseInfantMortality - accessImprovement + diseaseImpact);
    this.publicHealth.infantMortality = newInfantMortality;

    # Maternal mortality similarly influenced
    const maternalBase = 20;
    const maternalImprovement = (1 - access) * 3;
    const maternalDiseaseImpact = diseaseBurden * 0.3;
    this.publicHealth.maternalMortality = Math.max(0, maternalBase - maternalImprovement + maternalDiseaseImpact);

    # Vaccination rate changes (simulated - slowly reverting to equilibrium)
    const equilibriumVaccination = 85;
    const vaccinationChange = (equilibriumVaccination - this.publicHealth.vaccinationRate) * 0.01;
    this.publicHealth.vaccinationRate = Math.max(0, Math.min(100, this.publicHealth.vaccinationRate + vaccinationChange));

    # Life expectancy influenced by healthcare and disease
    const baseLifeExpectancy = 75;
    const accessLifeYears = (1 - access) * 3; # Poor access reduces life years
    const diseaseLifeYears = diseaseBurden * 2; # Disease burden reduces life years
    const newLifeExpectancy = Math.max(40, Math.min(85, baseLifeExpectancy - diseaseLifeYears + accessLifeYears * 0.5));
    this.publicHealth.averageLifeExpectancy = newLifeExpectancy;

    # Health-adjusted life expectancy
    const haLEFactor = Math.max(0.5, Math.min(0.9, access));
    this.publicHealth.healthAdjustedLifeExpectancy = Math.round(newLifeExpectancy * haLEFactor);
  }

  # Update life expectancy trends
  private updateLifeExpectancy(): void {
    # Slow trend toward higher life expectancy with improving conditions
    const current = this.publicHealth.averageLifeExpectancy;
    const trend = 0.1; # 0.1 years per period improvement

    this.publicHealth.averageLifeExpectancy = Math.min(90, current + trend);
    this.publicHealth.healthAdjustedLifeExpectancy = Math.round(this.publicHealth.averageLifeExpectancy * 0.85);
  }

  /**
   * Get healthcare state
   */
  getHealthcare(): Healthcare {
    return { ...this.healthcare };
  }

  /**
   * Get education state
   */
  getEducation(): Education {
    return { ...this.education };
  }

  /**
   * Get public health indicators
   */
  getPublicHealth(): PublicHealthIndicators {
    return { ...this.publicHealth };
  }

  /**
   * Get disease prevalence
   */
  getDiseasePrevalence(): Map<DiseaseType, number> {
    return new Map(this.healthcare.diseasePrevalence);
  }

  /**
   * Get specific disease prevalence
   */
  getDiseasePrevalenceForType(disease: DiseaseType): number | undefined {
    return this.healthcare.diseasePrevalence.get(disease);
  }

  /**
   * Set disease prevalence (for events, shocks, etc.)
   */
  setDiseasePrevalence(disease: DiseaseType, prevalence: number): void {
    this.healthcare.diseasePrevalence.set(disease, Math.max(0, Math.min(100, prevalence)));
  }

  /**
   * Outbreak simulation
   */
  simulateOutbreak(disease: DiseaseType, initialPrevalence: number, transmissionRate: number): void {
    # Set initial prevalence
    this.setDiseasePrevalence(disease, initialPrevalence);

    # In a full model, would model spread through population
    # For now, just record the outbreak
  }

  /**
   * Healthcare intervention (vaccination campaign, etc.)
   */
  healthcareIntervention(
    disease: DiseaseType,
    interventionType: 'vaccination' | 'treatment_campaign' | 'awareness',
    intensity: number // 0-1
  ): void {
    # Interventions reduce disease prevalence
    const reductionFactor = intensity * 0.3; # Up to 30% reduction

    const currentPrevalence = this.healthcare.diseasePrevalence.get(disease) || 0;
    const newPrevalence = Math.max(0, currentPrevalence * (1 - reductionFactor));

    this.setDiseasePrevalence(disease, newPrevalence);

    # Vaccination also improves vaccination rate
    if (interventionType === 'vaccination') {
      const currentVax = this.publicHealth.vaccinationRate;
      const newVax = Math.min(100, currentVax + intensity * 10);
      this.publicHealth.vaccinationRate = newVax;
    }
  }

  /**
   * Education policy intervention
   */
  educationIntervention(
    interventionType: 'curriculum_reform' | 'teacher_training' | 'infrastructure_investment',
    intensity: number // 0-1
  ): void {
    # Different interventions have different effects
    let metricChanges = { literacy: 0, technical: 0, higherEd: 0, vocational: 0, research: 0 };

    switch (interventionType) {
      case 'curriculum_reform':
        metricChanges = { literacy: intensity * 5, technical: intensity * 3, higherEd: intensity * 2, research: intensity * 2 };
        break;
      case 'teacher_training':
        metricChanges = { technical: intensity * 4, vocational: intensity * 3, research: intensity * 2 };
        break;
      case 'infrastructure_investment':
        metricChanges = { literacy: intensity * 3, technical: intensity * 2, vocational: intensity * 2, research: intensity * 1 };
        break;
    }

    # Apply changes with smoothing
    const currentLiteracy = this.education.literacyRate;
    this.education.literacyRate = Math.min(100, currentLiteracy + metricChanges.literacy);

    const currentTechnical = this.education.technicalSkills;
    this.education.technicalSkills = Math.max(0, Math.min(100, currentTechnical + metricChanges.technical));

    const currentHigherEd = this.education.higherEducationRate;
    this.education.higherEducationRate = Math.min(100, currentHigherEd + metricChanges.higherEd);

    const currentVocational = this.education.vocationalTraining;
    this.education.vocationalTraining = Math.max(0, Math.min(100, currentVocational + metricChanges.vocational));

    const currentResearch = this.education.researchCapability;
    this.education.researchCapability = Math.max(0, Math.min(100, currentResearch + metricChanges.research));
  }
}