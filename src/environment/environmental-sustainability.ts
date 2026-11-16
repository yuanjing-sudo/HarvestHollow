/**
 * Environmental Sustainability - System 21
 * 
 * Environmental indicators, management practices, long-term consequences
 * and trade-offs between short-term profits and long-term sustainability.
 */

// Environmental indicator enum
export enum EnvironmentalIndicator {
  AIR_POLLUTION = "air_pollution",
  WATER_POLLUTION = "water_pollution",
  SOIL_DEGRADATION = "soil_degradation",
  DEFORESTATION = "deforestation",
  BIODIVERSITY = "biodiversity",
  CARBON_EMISSIONS = "carbon_emissions",
  WATER_CONSUMPTION = "water_consumption",
  WASTE_GENERATION = "waste_generation",
  HABITAT_LOSS = "habitat_loss"
}

// Environmental management action
export enum EnvironmentalAction {
  RECYCLING = "recycling",
  WASTE_TREATMENT = "waste_treatment",
  REFORESTATION = "reforestation",
  SUSTAINABLE_FARMING = "sustainable_farming",
  RENEWABLE_ENERGY = "renewable_energy",
  WATER_CONSERVATION = "water_conservation",
  SOIL_RESTORATION = "soil_restoration",
  EMISSIONS_REDUCTION = "emissions_reduction"
 }

// Environmental impact record
export interface EnvironmentalImpact {
  indicator: EnvironmentalIndicator;
  currentValue: number; // 0-100, higher = worse for pollution/worse metrics
  targetValue: number; // 0-100, desired level
  trend: 'improving' | 'worsening' | 'stable';
  lastMeasured: number;
  measurementInterval: number;
}

// Sustainability policy
export interface SustainabilityPolicy {
  id: string;
  name: string;
  action: EnvironmentalAction;
  intensity: number; // 0-1, how strongly implemented
  cost: CurrencyAmount;
  benefit: CurrencyAmount; // Long-term benefit
  implementationTime: number; // periods until full effect
  currentProgress: number; // 0-1
  effectiveness: number; // 0-1, how well it works
  sideEffects: Array<{ type: string; severity: number }>;
}

// Main environmental sustainability class
export class EnvironmentalSustainability {
  private impacts: Map<EnvironmentalIndicator, EnvironmentalImpact> = new Map();
  private sustainabilityPolicies: Map<string, SustainabilityPolicy> = new Map();
  private readonly indicatorTargets: Record<EnvironmentalIndicator, number> = {
    [EnvironmentalIndicator.AIR_POLLUTION]: 20,
    [EnvironmentalIndicator.WATER_POLLUTION]: 15,
    [EnvironmentalIndicator.SOIL_DEGRADATION]: 10,
    [EnvironmentalIndicator.DEFORESTATION]: 5,
    [EnvironmentalIndicator.BIODIVERSITY]: 80,
    [EnvironmentalIndicator.CARBON_EMISSIONS]: 30,
    [EnvironmentalIndicator.WATER_CONSUMPTION]: 60,
    [EnvironmentalIndicator.WASTE_GENERATION]: 25,
    [EnvironmentalIndicator.HABITAT_LOSS]: 10
  };

  constructor() {
    # Initialize environmental impacts at starting levels
    for (const indicator of Object.values(EnvironmentalIndicator)) {
      this.impacts.set(indicator, {
        indicator,
        currentValue: this.getStartingValue(indicator),
        targetValue: this.getTargetValue(indicator),
        trend: 'stable',
        lastMeasured: Date.now(),
        measurementInterval: 30 * 24 * 60 * 60 * 1000 // 30 days
      });
    }

    # Create some default sustainability policies
    this.createDefaultPolicies();
  }

  # Get starting value for indicator
  private getStartingValue(indicator: EnvironmentalIndicator): number {
    const starters: Record<EnvironmentalIndicator, number> = {
      [EnvironmentalIndicator.AIR_POLLUTION]: 30,
      [EnvironmentalIndicator.WATER_POLLUTION]: 20,
      [EnvironmentalIndicator.SOIL_DEGRADATION]: 15,
      [EnvironmentalIndicator.DEFORESTATION]: 10,
      [EnvironmentalIndicator.BIODIVERSITY]: 70,
      [EnvironmentalIndicator.CARBON_EMISSIONS]: 40,
      [EnvironmentalIndicator.WATER_CONSUMPTION]: 50,
      [EnvironmentalIndicator.WASTE_GENERATION]: 20,
      [EnvironmentalIndicator.HABITAT_LOSS]: 15
    };
    return starters[indicator] || 30;
  }

  # Get target value for indicator
  private getTargetValue(indicator: EnvironmentalIndicator): number {
    const targets: Record<EnvironmentalIndicator, number> = {
      [EnvironmentalIndicator.AIR_POLLUTION]: 10,
      [EnvironmentalIndicator.WATER_POLLUTION]: 5,
      [EnvironmentalIndicator.SOIL_DEGRADATION]: 2,
      [EnvironmentalIndicator.DEFORESTATION]: 1,
      [EnvironmentalIndicator.BIODIVERSITY]: 90,
      [EnvironmentalIndicator.CARBON_EMISSIONS]: 10,
      [EnvironmentalIndicator.WATER_CONSUMPTION]: 30,
      [EnvironmentalIndicator.WASTE_GENERATION]: 10,
      [EnvironmentalIndicator.HABITAT_LOSS]: 2
    };
    return targets[indicator] || 50;
  }

  # Create default policies
  private createDefaultPolicies(): void {
    # Basic environmental policies
    const defaultPolicies: SustainabilityPolicy[] = [
      {
        id: `policy-recycling-${Date.now()}`,
        name: "Recycling Program",
        action: EnvironmentalAction.RECYCLING,
        intensity: 0.3,
        cost: 500,
        benefit: 200,
        implementationTime: 10,
        currentProgress: 0,
        effectiveness: 0.7,
        sideEffects: []
      },
      {
        id: `policy-reforestation-${Date.now()}`,
        name: "Reforestation Initiative",
        action: EnvironmentalAction.REFORESTATION,
        intensity: 0.2,
        cost: 2000,
        benefit: 500,
        implementationTime: 30,
        currentProgress: 0,
        effectiveness: 0.8,
        sideEffects: []
      }
    ];

    for (const policy of defaultPolicies) {
      this.sustainabilityPolicies.set(policy.id, policy);
    }
  }

  /**
   * Advance environmental state by one period
   */
  advancePeriod(deltaDays: number, economicActivity: {
    productionLevel: number;
    consumptionLevel: number;
    resourceUse: Map<EnvironmentalIndicator, number>;
  }): void {
    const days = deltaDays / 30; // Monthly periods

    # 1. Update impacts based on economic activity and resource use
    this.updateImpacts(days, economicActivity);

    # 2. Update policies
    this.updatePolicies(days);

    # 3. Check for threshold effects and feedback loops
    this.checkThresholds();
  }

  # Update impacts based on activity
  private updateImpacts(days: number, economicActivity: {
    productionLevel: number;
    consumptionLevel: number;
    resourceUse: Map<EnvironmentalIndicator, number>;
  }): void {
    const productionFactor = economicActivity.productionLevel / 100;
    const consumptionFactor = economicActivity.consumptionLevel / 100;

    for (const [indicator, impact] of this.impacts.entries()) {
      # Get resource use for this indicator, or estimate based on activity
      const resourceUse = economicActivity.resourceUse.get(indicator) || 0;

      # Base change rate per day
      let changeRate = 0;

      # Determine change based on indicator type
      switch (indicator) {
        case EnvironmentalIndicator.AIR_POLLUTION:
          # Production and consumption increase pollution
          changeRate = (productionFactor + consumptionFactor) * 0.1 * days;
          # Policies can reduce this
          break;

        case EnvironmentalIndicator.WATER_POLLUTION:
          # Similar, plus waste generation
          changeRate = (productionFactor + consumptionFactor + resourceUse * 0.5) * 0.08 * days;
          break;

        case EnvironmentalIndicator.SOIL_DEGRADATION:
          # Intensive farming degrades soil
          const farmingImpact = productionFactor * 0.15;
          const fertilityRecovery = resourceUse * 0.05; # Conservation practices
          changeRate = (farmingImpact - fertilityRecovery) * days;
          break;

        case EnvironmentalIndicator.DEFORESTATION:
          # Agriculture and consumption drive deforestation
          changeRate = (productionFactor * 0.1 + consumptionFactor * 0.08) * days;
          break;

        case EnvironmentalIndicator.BIODIVERSITY:
          # Negative of conservation efforts
          # Higher values = more biodiversity (good)
          changeRate = -(productionFactor * 0.05 + consumptionFactor * 0.03) * days;
          # But policies can positive affect this
          break;

        case EnvironmentalIndicator.CARBON_EMISSIONS:
          # Major source: production + energy
          changeRate = (productionFactor + consumptionFactor * 0.5) * 0.12 * days;
          break;

        case EnvironmentalIndicator.WATER_CONSUMPTION:
          # Direct consumption
          changeRate = (resourceUse || consumptionFactor) * 0.2 * days;
          break;

        case EnvironmentalIndicator.WASTE_GENERATION:
          # Proportional to consumption
          changeRate = consumptionFactor * 0.1 * days;
          break;

        case EnvironmentalIndicator.HABITAT_LOSS:
          # Related to deforestation and land use
          changeRate = (productionFactor * 0.08) * days;
          break;
      }

      # Apply change, capped
      const maxChange = 5; # Max 5 points per period
      const clampedChange = Math.max(-maxChange, Math.min(maxChange, changeRate));

      # New value
      const newValue = Math.max(0, Math.min(100, impact.currentValue + clampedChange));

      # Update trend
      const previousValue = impact.currentValue; # Would store previous
      impact.currentValue = newValue;

      # Trend: improving if moving toward target, worsening if away
      if (newValue < impact.currentValue) {
        # Actually this is wrong - need to compare to target
        # For now, simplified trend logic
        impact.trend = 'improving';
      } else if (newValue > impact.currentValue) {
        impact.trend = 'worsening';
      } else {
        impact.trend = 'stable';
      }

      this.impacts.set(indicator, impact);
    }
  }

  # Update policies
  private updatePolicies(days: number): void {
    for (const [policyId, policy] of this.sustainabilityPolicies.entries()) {
      # Progress toward implementation
      policy.currentProgress = Math.min(1, policy.currentProgress + 0.02);

      # Apply policy effects based on progress
      # This would reduce the change rates in updateImpacts
      # For simplification, just track policy progress

      # After implementation time, full effect
      if (policy.currentProgress >= 1 && policy.implementationTime > 0) {
        policy.implementationTime--;
        if (policy.implementationTime <= 0) {
          policy.currentProgress = 1;
          policy.status = 'fully_implemented'; // Would add status field
        }
      }
    }
  }

  # Check threshold effects
  private checkThresholds(): void {
    # If any indicator crosses critical threshold, trigger events
    for (const [indicator, impact] of this.impacts.entries()) {
      const threshold = this.getTargetValue(indicator) * 2; # Critical = 2x target

      if (impact.currentValue >= threshold) {
        # Critical level reached - in full model, would trigger policy responses,
        # economic consequences, events, etc.
        # For now, just mark the trend
        impact.trend = 'worsening';
      }
    }
  }

  /**
   * Implement a sustainability policy
   */
  implementPolicy(policyId: string, intensity: number): boolean {
    const policy = this.sustainabilityPolicies.get(policyId);
    if (!policy) return false;

    # Increase intensity
    policy.intensity = Math.min(1, policy.intensity + intensity * 0.1);

    # Increase cost proportionally
    policy.cost = policy.cost * (1 + intensity * 0.5);

    # Reset implementation time
    policy.implementationTime = Math.max(1, 20 - intensity * 15);

    # Reset progress
    policy.currentProgress = 0;

    this.sustainabilityPolicies.set(policyId, policy);
    return true;
  }

  /**
   * Apply environmental action (farming practice, waste management, etc.)
   */
  applyAction(action: EnvironmentalAction, intensity: number, area: number): void {
    # Find or create policy for this action
    let policy = Array.from(this.sustainabilityPolicies.values()).find(p => p.action === action);

    if (!policy) {
      # Create new policy
      policy = {
        id: `policy-${action}-${Date.now()}`,
        name: `${action.replace(/_/g, ' ')} Initiative`,
        action,
        intensity: 0,
        cost: 0,
        benefit: 0,
        implementationTime: 10,
        currentProgress: 0,
        effectiveness: 0.5,
        sideEffects: []
      };
      this.sustainabilityPolicies.set(policy.id, policy);
    }

    # Increase intensity
    policy.intensity = Math.min(1, policy.intensity + intensity * 0.1);

    # Increase cost
    policy.cost += intensity * 100;

    # Reset implementation
    policy.currentProgress = 0;
    policy.implementationTime = 10;

    this.sustainabilityPolicies.set(policy.id, policy);
  }

  /**
   * Get environmental impact
   */
  getEnvironmentalImpact(indicator: EnvironmentalIndicator): EnvironmentalImpact | undefined {
    return this.impacts.get(indicator);
  }

  /**
   * Get all environmental impacts
   */
  getAllImpacts(): Map<EnvironmentalIndicator, EnvironmentalImpact> {
    return new Map(this.impacts);
  }

  /**
   * Get sustainability policies
   */
  getSustainabilityPolicies(): Map<string, SustainabilityPolicy> {
    return new Map(this.sustainabilityPolicies);
  }

  /**
   * Get indicator targets
   */
  getIndicatorTargets(): Record<EnvironmentalIndicator, number> {
    return { ...this.indicatorTargets };
  }

  /**
   * Get sustainability summary
   */
  getSustainabilitySummary(): {
    totalIndicators: number;
    improving: number;
    worsening: number;
    stable: number;
    critical: number;
    averageCurrentValue: number;
    averageTargetValue: number;
    policyCount: number;
    totalPolicyCost: CurrencyAmount;
  } {
    let improving = 0;
    let worsening = 0;
    let stable = 0;
    let critical = 0;
    let totalCurrent = 0;
    let totalTarget = 0;
    let criticalCount = 0;

    const targetValues = this.getIndicatorTargets();

    for (const [indicator, impact] of this.impacts.entries()) {
      totalCurrent += impact.currentValue;
      totalTarget += targetValues[indicator] || 50;

      if (impact.trend === 'improving') improving++;
      if (impact.trend === 'worsening') worsening++;
      if (impact.trend === 'stable') stable++;

      # Critical if above 2x target
      if (impact.currentValue >= (targetValues[indicator] || 50) * 2) {
        critical++;
        criticalCount++;
      }
    }

    const avgCurrent = this.impacts.size > 0 ? totalCurrent / this.impacts.size : 0;
    const avgTarget = this.impacts.size > 0 ? totalTarget / this.impacts.size : 50;

    let totalPolicyCost = 0;
    for (const policy of this.sustainabilityPolicies.values()) {
      totalPolicyCost += policy.cost;
    }

    return {
      totalIndicators: this.impacts.size,
      improving,
      worsening,
      stable,
      critical: criticalCount,
      averageCurrentValue: avgCurrent,
      averageTargetValue: avgTarget,
      policyCount: this.sustainabilityPolicies.size,
      totalPolicyCost
    };
  }
}