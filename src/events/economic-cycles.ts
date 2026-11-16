/**
 * Dynamic Events and Economic Cycles - System 24
 * 
 * Events emerging from simulation, not random. Agricultural, economic,
 * political, technological and international events with triggers,
 * severity, duration and consequences.
 */

// Event type enum
export enum EventType {
  DROUGHT = "drought",
  FLOODING = "flooding",
  PEST_OUTBREAK = "pest_outbreak",
  CROP_DISEASE = "crop_disease",
  LIVESTOCK_DISEASE = "livestock_disease",
  RECESSION = "recession",
  INFLATION_SHOCK = "inflation_shock",
  COMMODITY_SHORTAGE = "commodity_shortage",
  ENERGY_CRISIS = "energy_crisis",
  BANKING_CRISIS = "banking_crisis",
  CONFIDENCE_DECLINE = "confidence_decline",
  ELECTION = "election",
  POLICY_REFORM = "policy_reform",
  TAX_CHANGES = "tax_changes",
  PUBLIC_DEMONSTRATIONS = "public_demonstrations",
  REGULATORY_CHANGES = "regulatory_changes",
  NEW_MACHINERY = "new_machinery",
  RESEARCH_BREAKTHROUGH = "research_breakthrough",
  IMPROVED_VARIETIES = "improved_varieties",
  TRADE_DISRUPTIONS = "trade_disruptions",
  GLOBAL_PRICE_SHOCKS = "global_price_shocks",
  SHIPPING_DELAYS = "shipping_delays",
  FOREIGN_RECESSIONS = "foreign_recessions"
 }

// Event severity
export enum EventSeverity {
  MINOR = "minor",
  MODERATE = "moderate",
  SEVERE = "severe",
  CATASTROPHIC = "catastrophic"
}

// Event trigger conditions
export interface EventTrigger {
  type: 'deterministic' | 'probabilistic';
  condition: (state: Map<string, number>) => boolean;
  probability?: number; // For probabilistic triggers
  delaySteps?: number; // For delayed deterministic
}

// Event record
export interface GameEvent {
  id: string;
  type: EventType;
  severity: EventSeverity;
  trigger: EventTrigger;
  affectedSystems: string[]; // Factor IDs or system names
  economicConsequences: Map<string, number>; // factor -> value change
  socialConsequences: Map<string, number>; // indicator -> value change
  duration: number; // periods
  startPeriod: number;
  recoveryConditions: Array<{ type: string; requiredValue: number }>;
  playerEvents: Array<{ type: string; description: string; choices?: string[] }>;
}

// Economic chain example from the design
export class EconomicChain {
  #buildChain(event: GameEvent): Array<{ step: string; description: string }> {
    # Example: Drought -> Lower crop yields -> Lower agricultural supply -> Higher food prices ->
    # Higher household living costs -> Lower disposable income -> Lower consumer spending ->
    # Lower business revenue -> Lower employment and tax revenue -> Government intervention
    return [
      { step: "agricultural", description: "Lower crop yields due to drought conditions" },
      { step: "supply", description: "Lower agricultural supply in the market" },
      { step: "pricing", description: "Higher food prices due to reduced supply" },
      { step: "household", description: "Higher living costs for households" },
      { step: "disposable", description: "Lower disposable income for families" },
      { step: "consumer", description: "Lower consumer spending across sectors" },
      { step: "business", description: "Lower business revenue and profits" },
      { step: "employment", description: "Lower employment and tax revenue for government" },
      { step: "intervention", description: "Government may introduce subsidies or aid" }
    ];
  }
 }

// Main dynamic events system
export class DynamicEvents {
  private activeEvents: Map<string, GameEvent> = new Map();
  private eventHistory: GameEvent[] = [];
  private readonly eventCooldown: Map<string, number> = new Map(); // Prevent same event too frequently

  constructor() {}

  /**
   * Check and trigger events based on current simulation state
   */
  checkAndTriggerEvents(state: Map<string, number>): GameEvent[] {
    const triggered: GameEvent[] = [];

    # Check each event type
    for (const eventType of Object.values(EventType)) {
      const eventTemplate = this#getEventTemplate(eventType);
      if (!eventTemplate) continue;

      # Check trigger conditions
      const triggerMet = this#checkTrigger(eventTemplate.trigger, state);

      # Check cooldown - don't trigger same event type too frequently
      const cooldown = this.eventCooldown.get(eventType) || 0;
      const cooldownMet = cooldown <= 0;

      if (triggerMet && cooldownMet) {
        # Trigger the event
        const event = this#createEvent(eventTemplate, state);
        if (event) {
          this.activeEvents.set(event.id, event);
          this.eventHistory.push(event);

          # Update cooldown
          this.eventCooldown.set(eventType, eventTemplate.trigger.delaySteps || 20);

          triggered.push(event);
        }
      } else if (cooldownMet) {
        # Decrease cooldown
        this.eventCooldown.set(eventType, Math.max(0, cooldown - 1));
      }
    }

    # Advance cooldowns for all event types
    const newCooldowns = new Map<string, number>();
    for (const [type, cooldown] of this.eventCooldown.entries()) {
      newCooldowns.set(type, Math.max(0, cooldown - 1));
    }
    this.eventCooldown = newCooldowns;

    return triggered;
  }

  #getEventTemplate(type: EventType): any {
    # Return event configuration based on type
    const templates: Record<EventType, any> = {
      [EventType.DROUGHT]: {
        name: "Drought",
        severityOptions: [EventSeverity.MODERATE, EventSeverity.SEVERE, EventSeverity.CATASTROPHIC],
        trigger: {
          type: 'probabilistic' as const,
          probability: 0.1,
          condition: (state: Map<string, number>) => {
            # Drought more likely with low rainfall, high temperatures
            const rainfall = state.get('rainfall') || 5;
            const temperature = state.get('temperature') || 20;
            return rainfall < 3 || temperature > 30;
          }
        },
        affectedSystems: ['soil.moisture', 'crop.growth', 'market.prices'],
        durationOptions: [4, 8, 12] // in-game months
      },
      [EventType.FLOODING]: {
        name: "Flooding",
        severityOptions: [EventSeverity.MODERATE, EventSeverity.SEVERE],
        trigger: {
          type: 'probabilistic' as const,
          probability: 0.08,
          condition: (state: Map<string, number>) => {
            const rainfall = state.get('rainfall') || 5;
            return rainfall > 15;
          }
        },
        affectedSystems: ['soil.moisture', 'infrastructure.flood', 'crop.damage'],
        durationOptions: [2, 4, 6]
      },
      [EventType.RECESSION]: {
        name: "Recession",
        severityOptions: [EventSeverity.MODERATE, EventSeverity.SEVERE],
        trigger: {
          type: 'deterministic' as const,
          condition: (state: Map<string, number>) => {
            # Recession triggered by economic indicators
            const inflation = state.get('inflation') || 2;
            const unemployment = state.get('unemployment') || 5;
            const gdpGrowth = state.get('gdp_growth') || 3;
            return inflation > 10 && unemployment > 15 && gdpGrowth < -2;
          }
        },
        affectedSystems: ['market.prices', 'business.revenue', 'employment.rate'],
        durationOptions: [8, 12, 20]
      },
      [EventType.INFLATION_SHOCK]: {
        name: "Inflation Shock",
        severityOptions: [EventSeverity.MODERATE, EventSeverity.SEVERE],
        trigger: {
          type: 'probabilistic' as const,
          probability: 0.15,
          condition: (state: Map<string, number>) => {
            const inflation = state.get('inflation') || 2;
            return inflation > 8 && Math.random() < 0.15;
          }
        },
        affectedSystems: ['market.prices', 'currency.inflation', 'purchasing.power'],
        durationOptions: [3, 6, 12]
      },
      [EventType.ELECTION]: {
        name: "Election",
        severityOptions: [EventSeverity.MODERATE],
        trigger: {
          type: 'deterministic' as const,
          condition: (state: Map<string, number>) => {
            # Election every 4 in-game years
            const year = state.get('year') || 1;
            return year % 4 === 0 && year > 0;
          }
        },
        affectedSystems: ['government.approval', 'policy.status', 'tax.rates'],
        durationOptions: [4] // election period
      }
    };

    return templates[type];
  }

  #checkTrigger(trigger: EventTrigger, state: Map<string, number>): boolean {
    if (trigger.type === 'deterministic') {
      return trigger.condition(state);
    } else {
      # Probabilistic: check condition AND random roll
      if (!trigger.condition(state)) return false;
      return Math.random() < (trigger.probability || 0.5);
    }
  }

  #createEvent(template: any, state: Map<string, number>): GameEvent | null {
    const severity = template.severityOptions[
      Math.floor(Math.random() * template.severityOptions.length)
    ];

    # Determine duration
    const duration = template.durationOptions[
      Math.floor(Math.random() * template.durationOptions.length)
    ];

    # Create event ID
    const id = `event-${template.name}-${Date.now()}`;

    # Economic consequences based on severity
    const economicConsequences = this#calculateEconomicConsequences(eventTemplate, severity);

    # Social consequences
    const socialConsequences = this#calculateSocialConsequences(eventTemplate, severity);

    # Recovery conditions
    const recoveryConditions = this#calculateRecoveryConditions(eventTemplate, severity);

    # Player events
    const playerEvents = this#createPlayerEvents(eventTemplate, severity);

    return {
      id,
      type: template.name as EventType,
      severity: severity,
      trigger: template.trigger,
      affectedSystems: template.affectedSystems,
      economicConsequences,
      socialConsequences,
      duration,
      startPeriod: Date.now(),
      recoveryConditions,
      playerEvents
    };
  }

  #calculateEconomicConsequences(template: any, severity: EventSeverity): Map<string, number> {
    # Base consequences scaled by severity
    const severityMultiplier: Record<EventSeverity, number> = {
      [EventSeverity.MINOR]: 0.3,
      [EventSeverity.MODERATE]: 0.6,
      [EventSeverity.SEVERE]: 1.0,
      [EventSeverity.CATASTROPHIC]: 1.5
    };

    const multiplier = severityMultiplier[severity];
    const consequences = new Map<string, number>();

    # Map affected systems to concrete value changes
    for (const system of template.affectedSystems) {
      let baseChange = 0;

      switch (system) {
        case 'soil.moisture':
          baseChange = -20 * multiplier;
          break;
        case 'crop.growth':
          baseChange = -30 * multiplier;
          break;
        case 'market.prices':
          baseChange = 15 * multiplier; # Prices increase
          break;
        case 'infrastructure.flood':
          baseChange = -15 * multiplier;
          break;
        case 'crop.damage':
          baseChange = -25 * multiplier;
          break;
        case 'market.prices':
          # Already handled, skip duplicate
          break;
        case 'currency.inflation':
          baseChange = 5 * multiplier;
          break;
        case 'purchasing.power':
          baseChange = -10 * multiplier;
          break;
        case 'employment.rate':
          baseChange = 5 * multiplier; # Unemployment increases
          break;
        case 'government.approval':
          baseChange = -10 * multiplier;
          break;
        case 'policy.status':
          baseChange = 0;
          break;
        case 'tax.rates':
          baseChange = 0;
          break;
        default:
          baseChange = 0;
      }

      if (baseChange !== 0) {
        consequences.set(system, baseChange);
      }
    }

    return consequences;
  }

  #calculateSocialConsequences(template: any, severity: EventSeverity): Map<string, number> {
    const severityMultiplier: Record<EventSeverity, number> = {
      [EventSeverity.MINOR]: 0.3,
      [EventSeverity.MODERATE]: 0.6,
      [EventSeverity.SEVERE]: 1.0,
      [EventSeverity.CATASTROPHIC]: 1.5
    };

    const multiplier = severityMultiplier[severity];
    const consequences = new Map<string, number>();

    for (const system of template.affectedSystems) {
      let baseChange = 0;

      switch (system) {
        case 'soil.moisture':
          # Not really a social indicator
          break;
        case 'crop.growth':
          # Food security impact
          baseChange = -15 * multiplier;
          break;
        case 'market.prices':
          # Affordability impact
          baseChange = -10 * multiplier;
          break;
        case 'infrastructure.flood':
          # Displacement, safety
          baseChange = -20 * multiplier;
          break;
        case 'crop.damage':
          # Food security
          baseChange = -15 * multiplier;
          break;
        case 'currency.inflation':
          # Purchasing power
          baseChange = -10 * multiplier;
          break;
        case 'purchasing.power':
          baseChange = -10 * multiplier;
          break;
        case 'employment.rate':
          # Job losses
          baseChange = -5 * multiplier;
          break;
        case 'government.approval':
          # Public satisfaction
          baseChange = -15 * multiplier;
          break;
        case 'policy.status':
          # Policy changes may result
          baseChange = 0;
          break;
        case 'tax.rates':
          # May change due to policy
          baseChange = 0;
          break;
        default:
          baseChange = 0;
      }

      if (baseChange !== 0) {
        consequences.set(system, baseChange);
      }
    }

    return consequences;
  }

  #calculateRecoveryConditions(template: any, severity: EventSeverity): Array<{ type: string; requiredValue: number }> {
    const severityMultiplier: Record<EventSeverity, number> = {
      [EventSeverity.MINOR]: 0.3,
      [EventSeverity.MODERATE]: 0.6,
      [EventSeverity.SEVERE]: 1.0,
      [EventSeverity.CATASTROPHIC]: 1.5
    };

    const multiplier = severityMultiplier[severity];
    const conditions: Array<{ type: string; requiredValue: number }> = [];

    # Base recovery conditions
    for (const system of template.affectedSystems) {
      let required = 50; # Default recovery threshold

      switch (system) {
        case 'soil.moisture':
          required = 70; # Need moisture above 70 to recover
          break;
        case 'crop.growth':
          required = 60; # Need growth conditions improved
          break;
        case 'market.prices':
          required = 40; # Prices need to stabilize below 40
          break;
        case 'infrastructure.flood':
          required = 80; # Infrastructure needs to be repaired
          break;
        case 'crop.damage':
          required = 65; # Crop conditions need to improve
          break;
        case 'currency.inflation':
          required = 40; # Inflation needs to come down
          break;
        case 'purchasing.power':
          required = 60; # Purchasing power needs to recover
          break;
        case 'employment.rate':
          required = 90; # Employment needs to be high
          break;
        case 'government.approval':
          required = 60; # Approval needs to recover
          break;
        default:
          required = 50;
      }

      conditions.push({ type: system, requiredValue: required });
    }

    return conditions;
  }

  #createPlayerEvents(template: any, severity: EventSeverity): Array<{ type: string; description: string; choices?: string[] }> {
    # Create player-facing events with choices
    const events: Array<{ type: string; description: string; choices?: string[] }> = [];

    # Based on event type and severity
    switch (template.name) {
      case "Drought":
        events.push({
          type: "resource_shortage",
          description: "Crop yields have declined due to drought. Reduce irrigation or wait for rain?",
          choices: ["Reduce irrigation and conserve water", "Invest in drought-resistant crops", "Import food from other regions", "Accept the losses"]
        });
        events.push({
          type: "economic_impact",
          description: "Food prices have risen significantly. How do you respond?",
          choices: ["Implement price controls", "Provide subsidies to farmers", "Accept market adjustments", "Export less food"]
        });
      case "Flooding":
        events.push({
          type: "damage_assessment",
          description: "Flooding has damaged infrastructure and crops. Prioritize repairs?",
          choices: ["Repair critical infrastructure first", "Focus on crop recovery", "Rebuild in safer locations", "Accept losses and wait for next season"]
        });
        events.push({
          type: "economic relief",
          description: "Many households are affected. Provide aid or let market adjust?",
          choices: ["Provide direct aid to affected households", "Tax the wealthy to fund recovery", "Let insurance and market handle it", "Delay non-essential spending"]
        });
      case "Recession":
        events.push({
          type: "business_challenges",
          description: "Economic recession affecting business revenues. Support or let fail?",
          choices: ["Provide low-interest loans to businesses", "Tax cuts to stimulate spending", "Allow natural selection", "Invest in new industries"]
        });
        events.push({
          type: "employment_impact",
          description: "Recession has caused job losses. Response?",
          choices: ["Expand unemployment benefits", "Create public works programs", "Retraining programs", "Wait for recovery"]
        });
      case "Inflation Shock":
        events.push({
          type: "price_adjustments",
          description: "Inflation has eroded purchasing power. Adjust wages or prices?",
          choices: ["Index wages to inflation", "Freeze prices on essentials", "Accept inflation", "Tighten monetary policy"]
        });
        events.push({
          type: "savings_protection",
          description: "Inflation eroding savings value. Protect savings or invest?",
          choices: ["Invest in real assets", "Diversify into foreign currency", "Accept erosion", "Increase savings rate"]
        });
      case "Election":
        events.push({
          type: "policy_choice",
          description: "Newly elected government. Priority policy?",
          choices: ["Focus on economic growth", "Focus on social services", "Focus on infrastructure", "Focus on environmental policy"]
        });
        events.push({
          type: "cabinet_appointments",
          description: "New administration appoints key officials. Who gets which role?",
          choices: ["Experts in economics", "Loyal supporters", "Balance both", "Technocratic government"]
        });
      default:
        # Generic event for unknown types
        events.push({
          type: "general_impact",
          description: "An event has affected your operations.",
          choices: ["Minimize impact", "Adapt and continue", "Seek external help", "Rebuild from scratch"]
        });
    }

    return events;
  }

  /**
   * Get active events
   */
  getActiveEvents(): GameEvent[] {
    return Array.from(this.activeEvents.values());
  }

  /**
   * Get event history
   */
  getEventHistory(): GameEvent[] {
    return [...this.eventHistory];
  }

  /**
   * Complete an event (recovery or end)
   */
  completeEvent(eventId: string): boolean {
    const event = this.activeEvents.get(eventId);
    if (!event) return false;

    # Remove from active
    this.activeEvents.delete(eventId);

    # Add to history if not already there
    if (!this.eventHistory.some(e => e.id === eventId)) {
      this.eventHistory.push(event);
    }

    return true;
  }

  /**
   * Apply event effects to simulation state
   */
  applyEventEffects(event: GameEvent, stateUpdater: (changes: Map<string, number>) => void): void {
    # Apply economic consequences
    const econChanges = new Map<string, number>(event.economicConsequences);
    stateUpdater(econChanges);

    # Apply social consequences
    const socialChanges = new Map<string, number>(event.socialConsequences);
    stateUpdater(socialChanges);
  }

  /**
   * Check if event is recovering
   */
  isEventRecovering(eventId: string, state: Map<string, number>): boolean {
    const event = this.activeEvents.get(eventId);
    if (!event) return false;

    # Check if recovery conditions are met
    for (const condition of event.recoveryConditions) {
      const currentValue = state.get(condition.type) || 0;
      if (currentValue < condition.requiredValue) {
        return false; # Condition not met
      }
    }

    return true; # All recovery conditions met
  }
}