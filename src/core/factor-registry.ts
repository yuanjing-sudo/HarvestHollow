/**
 * Factor Registry - Core Infrastructure Layer 1
 * 
 * Central registry for all simulation factors with consistent data structures.
 * Separates: State, Parameters, and Events for each factor.
 */

// Type definitions for factor attributes
export interface FactorBase {
  /** Unique identifier for the factor */
  id: string;
  /** Current value of the factor */
  currentValue: number;
  /** Minimum possible value */
  minimum: number;
  /** Maximum possible value */
  maximum: number;
  /** Base/starting value */
  baseValue: number;
  /** How often this factor updates */
  updateFrequency: SimulationFrequency;
  /** Factors that influence this one */
  dependencies: string[];
  /** Factors that this one influences */
  influences: string[];
  /** Calculation method name or function */
  calculationMethod: string;
  /** Recovery/deterioration mechanism */
  recoveryMechanism?: string;
  /** Decay mechanism */
  decayMechanism?: string;
  /** Uncertainty/randomness parameter (0-1) */
  uncertainty?: number;
  /** Historical value tracking */
  historicalTracking: boolean;
  /** Whether factor is visible to player */
  playerVisible: boolean;
  /** Event history */
  eventHistory?: Array<{
    timestamp: number;
    oldValue: number;
    newValue: number;
    cause: string;
  }>;
}

/**
 * Separation of concerns:
 * - State: What is currently happening? (e.g., inflation is 4.2%)
 * - Parameters: What determines how it behaves? (e.g., monetary-policy sensitivity)
 * - Events: What happened to change it? (e.g., an energy shortage)
 */

// Type for factor state
export type FactorState = {
  [key: string]: number | boolean | string | null;
};

// Type for factor parameters
export type FactorParameters = {
  [key: string]: number | boolean | string | null;
};

// Type for factor events
export type FactorEvent = {
  id: string;
  timestamp: number;
  factorId: string;
  oldValue: number;
  newValue: number;
  cause: string;
  type: 'recovery' | 'decay' | 'shock' | 'policy';
};

// Core Factor class
export class Factor {
  public readonly base: FactorBase;
  public current: number;
  private history: FactorEvent[] = [];
  private parameters: FactorParameters = {};

  constructor(base: FactorBase) {
    this.base = base;
    this.current = base.baseValue;

    // Validate bounds
    if (this.current < base.minimum) {
      this.current = base.minimum;
    }
    if (this.current > base.maximum) {
      this.current = base.maximum;
    }
  }

  /**
   * Get the current state of the factor
   */
  getState(): number {
    return this.current;
  }

  /**
   * Get the base value
   */
  getBaseValue(): number {
    return this.base.baseValue;
  }

  /**
   * Get the minimum limit
   */
  getMinimum(): number {
    return this.base.minimum;
  }

  /**
   * Get the maximum limit
   */
  getMaximum(): number {
    return this.base.maximum;
  }

  /**
   * Get the factor ID
   */
  getId(): string {
    return this.base.id;
  }

  /**
   * Get the update frequency
   */
  getFrequency(): SimulationFrequency {
    return this.base.updateFrequency;
  }

  /**
   * Update the factor value with proper clamping and event tracking
   */
  update(newValue: number, cause: string): void {
    const oldValue = this.current;

    // Clamp to bounds
    const clampedValue = Math.max(this.base.minimum, Math.min(this.base.maximum, newValue));

    if (clampedValue !== oldValue) {
      this.current = clampedValue;

      // Record event
      const event: FactorEvent = {
        id: `${this.base.id}-${Date.now()}`,
        timestamp: Date.now(),
        factorId: this.base.id,
        oldValue,
        newValue: clampedValue,
        cause,
        type: this.determineEventType(oldValue, clampedValue)
      };

      this.history.push(event);

      // Keep history manageable (max 100 events)
      if (this.history.length > 100) {
        this.history = this.history.slice(-100);
      }

      // Notify registry of change
      FactorRegistry.notifyFactorChange(this.base.id, event);
    }
  }

  /**
   * Determine the type of event based on value change
   */
  private determineEventType(oldValue: number, newValue: number): string {
    if (newValue > oldValue) {
      return 'recovery';
    } else if (newValue < oldValue) {
      return 'decay';
    }
    return 'shock';
  }

  /**
   * Get the event history
   */
  getHistory(): FactorEvent[] {
    return [...this.history];
  }

  /**
   * Update parameters
   */
  setParameter(key: string, value: number | boolean | string | null): void {
    this.parameters[key] = value;
  }

  /**
   * Get a parameter
   */
  getParameter(key: string): number | boolean | string | null {
    return this.parameters[key];
  }

  /**
   * Apply a calculation based on the method name
   */
  applyCalculation(inputFactors: Map<string, number>): void {
    const method = this.base.calculationMethod;

    switch (method) {
      case 'soil_fertility_model':
        this.applySoilFertilityModel(inputFactors);
        break;
      case 'price_adjustment_model':
        this.applyPriceAdjustmentModel(inputFactors);
        break;
      case 'crop_growth_model':
        this.applyCropGrowthModel(inputFactors);
        break;
      default:
        // Default: simple linear update
        this.simpleUpdate(inputFactors);
        break;
    }
  }

  /**
   * Simple update based on influences
   */
  private simpleUpdate(inputFactors: Map<string, number>): void {
    let change = 0;

    // Calculate change based on influencing factors
    for (const dep of this.base.dependencies) {
      const input = inputFactors.get(dep);
      if (input !== undefined) {
        change += input * 0.1; // Weight factor
      }
    }

    this.current = Math.max(this.base.minimum, Math.min(this.base.maximum, this.current + change));
  }

  /**
   * Soil fertility model example
   */
  private applySoilFertilityModel(inputFactors: Map<string, number>): void {
    // base fertility + adjustments from inputs
    let fertility = this.base.baseValue;

    // Fertilizer effect
    const fertilizer = inputFactors.get('fertilizer') || 0;
    fertility += fertilizer * 0.5;

    // Crop rotation effect
    const rotation = inputFactors.get('cropRotation') || 0;
    fertility += rotation * 0.3;

    // Erosion effect
    const erosion = inputFactors.get('erosion') || 0;
    fertility -= erosion * 0.8;

    this.current = Math.max(this.base.minimum, Math.min(this.base.maximum, fertility));
  }

  /**
   * Price adjustment model based on supply/demand
   */
  private applyPriceAdjustmentModel(inputFactors: Map<string, number>): void {
    // Simple price model: price = base * (1 + (demand - supply) * sensitivity)
    const demand = inputFactors.get('demand') || 0;
    const supply = inputFactors.get('supply') || 0;
    const sensitivity = (inputFactors.get('sensitivity') || 0.1);

    const change = (demand - supply) * sensitivity;
    this.current = Math.max(this.base.minimum, Math.min(this.base.maximum, this.base.baseValue * (1 + change)));
  }

  /**
   * Crop growth model
   */
  private applyCropGrowthModel(inputFactors: Map<string, number>): void {
    // Growth based on water, nutrients, temperature, etc.
    const water = inputFactors.get('water') || 0;
    const nutrients = inputFactors.get('nutrients') || 0;
    const temperature = inputFactors.get('temperature') || 0;

    // Ideal conditions for growth
    const idealGrowth = (water + nutrients + temperature) / 3;
    const change = idealGrowth * 0.5;

    this.current = Math.max(this.base.minimum, Math.min(this.base.maximum, this.current + change));
  }
}

// Central factor registry
export class FactorRegistry {
  private static factors: Map<string, Factor> = new Map();
  private static listeners: Map<string, ((event: FactorEvent) => void)[]> = new Map();

  /**
   * Register a factor in the registry
   */
  static register(factor: Factor): void {
    this.factors.set(factor.getId(), factor);
    if (!this.listeners.has(factor.getId())) {
      this.listeners.set(factor.getId(), []);
    }
  }

  /**
   * Unregister a factor
   */
  static unregister(factorId: string): void {
    this.factors.delete(factorId);
    this.listeners.delete(factorId);
  }

  /**
   * Get a factor by ID
   */
  static get(factorId: string): Factor | undefined {
    return this.factors.get(factorId);
  }

  /**
   * Get all registered factors
   */
  static getAll(): Factor[] {
    return Array.from(this.factors.values());
  }

  /**
   * Notify listeners of a factor change
   */
  static notifyFactorChange(factorId: string, event: FactorEvent): void {
    const listeners = this.listeners.get(factorId) || [];
    listeners.forEach(listener => listener(event));

    // Also trigger dependent factors
    const factor = this.factors.get(factorId);
    if (factor && factor.base.influences) {
      factor.base.influences.forEach(depId => {
        const depFactor = this.factors.get(depId);
        if (depFactor) {
          // Schedule update based on dependency
          // In a full implementation, this would trigger the factor's recalculation
        }
      });
    }
  }

  /**
   * Add a listener for factor changes
   */
  static onFactorChange(factorId: string, listener: (event: FactorEvent) => void): () => void {
    const listeners = this.listeners.get(factorId) || [];
    listeners.push(listener);

    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * Update a factor (called by the simulation clock)
   */
  static updateFactor(factorId: string, newValue: number, cause: string): void {
    const factor = this.factors.get(factorId);
    if (factor) {
      factor.update(newValue, cause);
    }
  }

  /**
   * Get historical tracking for a factor
   */
  static getFactorHistory(factorId: string): FactorEvent[] {
    const factor = this.factors.get(factorId);
    return factor ? factor.getHistory() : [];
  }
}