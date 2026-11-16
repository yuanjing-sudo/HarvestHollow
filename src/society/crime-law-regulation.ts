/**
 * Crime, Law and Regulation - System 22
 * 
 * Social and legal indicators, business regulation, consequences and
 * enforcement mechanics focused on abstract simulation outcomes.
 */

// Crime type enum
export enum CrimeType {
  THEFT = "theft",
  FRAUD = "fraud",
  VANDALISM = "vandalism",
  CORRUPTION = "corruption",
  SMUGGLING = "smuggling",
  ILLEGAL_WORKERS = "illegal_workers",
  COUNTERFEITING = "counterfeiting",
  ILLEGAL_GAMBLING = "illegal_gambling",
  DRUG_TRAFFICKING = "drug_trafficking"
}

// Regulatory compliance
export interface RegulatoryCompliance {
  businessId: string;
  complianceArea: keyof GovernmentBudget;
  complianceStatus: 'compliant' | 'under_review' | 'non_compliant' | 'penalised';
  violationCount: number;
  lastInspection: number;
  finesPaid: CurrencyAmount;
  penaltySeverity: 'warning' | 'fine' | 'license_suspension' | 'business_closure';
}

// Social and legal indicators
export interface SocialLegalIndicators {
  crimeRate: number; // per 1000 population per period
  fraudIncidents: number;
  corruptionLevel: number; // 0-100
  regulatoryComplianceRate: number; // 0-100, percentage of businesses compliant
  publicSafety: number; // 0-100
  lawEnforcementCapacity: number; // 0-100
  courtEfficiency: number; // 0-100
  inspectionCapacity: number; // 0-100
}

// Business regulation
export interface BusinessRegulation {
  licenceRequired: boolean;
  safetyStandards: number; // 0-100 compliance required
  environmentalStandards: number; // 0-100 compliance required
  labourProtections: number; // 0-100 compliance required
  productStandards: number; // 0-100 compliance required
  taxCompliance: number; // 0-100 compliance required
  competitionRegulation: number; // 0-100 compliance required
}

// Main crime-law class
export class CrimeLawRegulation {
  private crimeStats: SocialLegalIndicators;
  private regulations: Map<string, BusinessRegulation> = new Map();
  private complianceRegistry: Map<string, RegulatoryCompliance> = new Map();

  constructor() {
    # Initialize social/legal indicators
    this.crimeStats = {
      crimeRate: 5, // per 1000
      fraudIncidents: 10,
      corruptionLevel: 10,
      regulatoryComplianceRate: 85,
      publicSafety: 75,
      lawEnforcementCapacity: 70,
      courtEfficiency: 80,
      inspectionCapacity: 75
    };

    # Create some initial regulations
    this.createInitialRegulations();
  }

  # Create initial regulations
  private createInitialRegulations(): void {
    # Basic regulations for different business types
    const regulationAreas: Array<keyof GovernmentBudget> = [
      'healthcare',
      'education',
      'infrastructure',
      'agriculture',
      'environment'
    ];

    for (const area of regulationAreas) {
      const regulationId = `reg-${area}-${Date.now()}`;
      const regulation: BusinessRegulation = {
        licenceRequired: area !== 'environment', # Some need licences
        safetyStandards: 80,
        environmentalStandards: 70,
        labourProtections: 75,
        productStandards: 85,
        taxCompliance: 85,
        competitionRegulation: 80
      };

      this.regulations.set(regulationId, regulation);
    }
  }

  /**
   * Record a crime incident
   */
  recordCrime(crimeType: CrimeType, severity: 'low' | 'medium' | 'high', location: { x: number; y: number }, affectedEntities: string[]): void {
    # Update crime rate
    const severityMultiplier: Record<'low' | 'medium' | 'high', number> = { low: 1, medium: 3, high: 5 };
    const increase = crimeStats.crimeRate + (1 / 1000) * severityMultiplier[severity];

    this.crimeStats.crimeRate = Math.max(0, Math.min(50, increase));

    # Update fraud incidents if applicable
    if (crimeType === CrimeType.FRAUD) {
      this.crimeStats.fraudIncidents++;
    }

    # Update corruption level if applicable
    if (crimeType === CrimeType.CORRUPTION) {
      this.crimeStats.corruptionLevel = Math.min(100, this.crimeStats.corruptionLevel + 2);
    }

    # In a full model, would track by region, time, etc.
  }

  /**
   * Record regulatory violation
   */
  recordViolation(businessId: string, regulationArea: keyof GovernmentBudget, severity: 'low' | 'medium' | 'high'): void {
    # Create or update compliance record
    let compliance = this.complianceRegistry.get(businessId);

    if (!compliance) {
      compliance = {
        businessId,
        complianceArea: regulationArea,
        complianceStatus: 'under_review',
        violationCount: 1,
        lastInspection: Date.now(),
        finesPaid: 0,
        penaltySeverity: 'warning'
      };
    }

    # Increment violation count
    compliance.violationCount++;
    compliance.lastInspection = Date.now();

    # Update compliance status based on violations
    if (compliance.violationCount <= 3) {
      compliance.complianceStatus = 'under_review';
    } else if (compliance.violationCount <= 7) {
      compliance.complianceStatus = 'non_compliant';
    } else {
      compliance.complianceStatus = 'penalised';
    }

    # Determine penalty based on severity
    const severityMultiplier: Record<'low' | 'medium' | 'high', number> = { low: 100, medium: 500, high: 2000 };
    const fineAmount = severityMultiplier[severity];

    compliance.finesPaid = Math.max(0, compliance.finesPaid + fineAmount);

    # Escalate penalty severity
    if (compliance.violationCount >= 5) {
      compliance.penaltySeverity = 'fine';
    }
    if (compliance.violationCount >= 10) {
      compliance.penaltySeverity = 'license_suspension';
    }
    if (compliance.violationCount >= 15) {
      compliance.penaltySeverity = 'business_closure';
    }

    this.complianceRegistry.set(businessId, compliance);

    # Update regulatory compliance rate
    this.updateComplianceRate();
  }

  # Update regulatory compliance rate
  private updateComplianceRate(): void {
    const totalBusinesses = this.regulations.size;
    const compliantCount = Array.from(this.complianceRegistry.values()).filter(c => c.complianceStatus === 'compliant').length;

    this.crimeStats.regulatoryComplianceRate = totalBusinesses > 0
      ? Math.round((compliantCount / totalBusinesses) * 100)
      : 100;
  }

  /**
   * Check business regulation compliance
   */
  checkRegulationCompliance(business: {
    id: string;
    industry: string;
    fines: CurrencyAmount;
    violations: Array<{ area: keyof GovernmentBudget; severity: 'low' | 'medium' | 'high' }>;
  }): {
    compliant: boolean;
    violations: Array<{ area: keyof GovernmentBudget; severity: string; penalty: CurrencyAmount }>;
    recommendedActions: string[];
  } {
    const violations: Array<{ area: keyof GovernmentBudget; severity: string; penalty: CurrencyAmount }> = [];
    let totalPenalty = 0;

    # Check each violation
    for (const violation of business.violations) {
      const regulation = this.regulations.values().next().value; // Would look up specific regulation

      # Simple penalty calculation
      const severityMap: Record<'low' | 'medium' | 'high', number> = { low: 100, medium: 500, high: 2000 };
      const penalty = fineAmount || severityMap[violation.severity] || 100;

      violations.push({
        area: violation.area,
        severity: violation.severity,
        penalty
      });

      totalPenalty += penalty;
    }

    const compliant = totalPenalty === 0 || business.fines < totalPenalty * 0.1;

    # Recommended actions
    const recommendedActions: string[] = [];
    if (!compliant) {
      recommendedActions.push("Pay outstanding fines");
      recommendedActions.push("Improve compliance practices");
      recommendedActions.push("Schedule inspection");
    }

    return { compliant, violations, recommendedActions };
  }

  /**
   * Get crime statistics
   */
  getCrimeStats(): SocialLegalIndicators {
    return { ...this.crimeStats };
  }

  /**
   * Get regulatory compliance rate
   */
  getRegulatoryComplianceRate(): number {
    return this.crimeStats.regulatoryComplianceRate;
  }

  /**
   * Get all regulations
   */
  getAllRegulations(): Map<string, BusinessRegulation> {
    return new Map(this.regulations);
  }

  /**
   * Get compliance record for a business
   */
  getComplianceRecord(businessId: string): RegulatoryCompliance | undefined {
    return this.complianceRegistry.get(businessId);
  }

  /**
   * Enforce regulations (government action)
   */
  enforceRegulations(businessId: string, severity: 'low' | 'medium' | 'high'): boolean {
    const compliance = this.complianceRegistry.get(businessId);
    if (!compliance) return false;

    # Apply enforcement based on severity
    const enforcementFines: Record<'low' | 'medium' | 'high', number> = { low: 500, medium: 2000, high: 5000 };

    compliance.finesPaid = Math.max(0, compliance.finesPaid + enforcementFines[severity]);

    # Escalate status
    compliance.violationCount++;
    compliance.lastInspection = Date.now();

    if (compliance.violationCount >= 5) {
      compliance.complianceStatus = 'non_compliant';
    }
    if (compliance.violationCount >= 10) {
      compliance.penaltySeverity = 'fine';
    }
    if (compliance.violationCount >= 15) {
      compliance.penaltySeverity = 'license_suspension';
    }

    this.complianceRegistry.set(businessId, compliance);
    this.updateComplianceRate();

    return true;
  }

  /**
   * Corruption event
   */
  recordCorruptionEvent(severity: 'low' | 'medium' | 'high', area: string, amount: CurrencyAmount): void {
    this.crimeStats.corruptionLevel = Math.min(100, this.crimeStats.corruptionLevel + (severity === 'high' ? 10 : severity === 'medium' ? 5 : 2));

    # May reduce compliance
    this.crimeStats.regulatoryComplianceRate = Math.max(0, this.crimeStats.regulatoryComplianceRate - 5);

    # May increase crime rate
    this.crimeStats.crimeRate = Math.min(50, this.crimeStats.crimeRate + 2);
  }

  # anti-corruption action
  performAntiCorruptionAction(severity: 'low' | 'medium' | 'high'): void {
    const reduction = severity === 'high' ? 15 : severity === 'medium' ? 8 : 3;

    this.crimeStats.corruptionLevel = Math.max(0, this.crimeStats.corruptionLevel - reduction);
    this.crimeStats.regulatoryComplianceRate = Math.min(100, this.crimeStats.regulatoryComplianceRate + reduction);
    this.crimeStats.crimeRate = Math.max(0, this.crimeStats.crimeRate - 2);
  }
}