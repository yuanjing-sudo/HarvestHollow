/**
 * Simulation State - Core Infrastructure Layer 1
 * 
 * Manages the overall simulation state, integrating clock, factors, and dependency graph.
 * Provides the authoritative world state for all systems to read from.
 */

import { SimulationClock } from "./clock";
import { FactorRegistry, Factor } from "./factor-registry";
import { DependencyGraph, DependencyType } from "./dependency-graph";

// Type for the complete simulation state
export interface SimulationState {
  /** Current in-game time */
  time: number;
  /** whether the simulation is paused */
  paused: boolean;
  /** Current simulation speed multiplier */
  speed: number;
  /** All registered factors and their current values */
  factors: Map<string, number>;
  /** Last tick timestamp */
  lastTick: number;
  /** World metadata */
  world: {
    /** Random seed for deterministic generation */
    seed: number;
    /** Current season */
    season: string;
    /** Current year */
    year: number;
  };
}

/**
 * Main Simulation State Manager
 */
export class SimulationStateManager {
  private clock: SimulationClock;
  private factorRegistry: FactorRegistry;
  private dependencyGraph: DependencyGraph;
  private currentState: SimulationState;

  constructor(
    clock: SimulationClock,
    factorRegistry: FactorRegistry,
    dependencyGraph: DependencyGraph
  ) {
    this.clock = clock;
    this.factorRegistry = factorRegistry;
    this.dependencyGraph = dependencyGraph;

    // Initialize state
    this.currentState = {
      time: 0,
      paused: false,
      speed: 1,
      factors: new Map(),
      lastTick: 0,
      world: {
        seed: Date.now(),
        season: "spring",
        year: 1
      }
    };

    // Sync clock events with factor updates
    this.setupClockIntegration();
  }

  /**
   * Set up integration between clock and factor registry
   */
  private setupClockIntegration(): void {
    // Register each factor's frequency with the clock
    const factors = this.factorRegistry.getAll();

    factors.forEach(factor => {
      const freq = factor.getFrequency();
      this.clock.on(freq, () => {
        // Trigger factor recalculation based on dependencies
        this.updateFactorFromDependencies(factor);
      });
    });
  }

  /**
   * Update a factor based on its dependencies
   */
  private updateFactorFromDependencies(factor: Factor): void {
    const factorId = factor.getId();
    const dependencies = this.dependencyGraph.getDependencies(factorId);

    if (dependencies.length === 0) {
      // No explicit dependencies, use base value
      FactorRegistry.updateFactor(factorId, factor.getBaseValue(), "initialization");
      return;
    }

    // Gather input values from dependent factors
    const inputFactors = new Map<string, number>();

    // Get current values of all influencing factors
    const influencers = this.dependencyGraph.getInfluencers(factorId);
    influencers.forEach(influencerId => {
      const influencer = FactorRegistry.get(influencerId);
      if (influencer) {
        inputFactors.set(influencerId, influencer.getState());
      }
    });

    // Also include direct dependencies
    dependencies.forEach(dep => {
      const sourceFactor = FactorRegistry.get(dep.source);
      if (sourceFactor) {
        inputFactors.set(dep.source, sourceFactor.getState());
      }
    });

    // Apply the factor's calculation method
    factor.applyCalculation(inputFactors);

    // Update the registry with the new value
    const newValue = factor.getState();
    FactorRegistry.updateFactor(factorId, newValue, "cyclical_update");
  }

  /**
   * Advance the simulation by one tick
   */
  advanceTick(): void {
    // Record the tick time
    const now = Date.now();
    this.currentState.lastTick = now;

    // Advance the clock (this will trigger frequency-based updates)
    const delta = 1000 / 60; // 60 FPS base
    this.clock.advance(delta);

    // Update world state
    this.updateWorldState();

    // Update the overall simulation state
    this.currentState.time = this.clock.getCurrentTime();
    this.currentState.paused = this.clock.isPaused();
    this.currentState.speed = this.clock.getSpeed();

    // Update factors map
    const factors = this.factorRegistry.getAll();
    factors.forEach(factor => {
      this.currentState.factors.set(factor.getId(), factor.getState());
    });
  }

  /**
   * Update world state (season, year, etc.)
   */
  private updateWorldState(): void {
    const time = this.clock.getCurrentTime();
    const year = Math.floor(time / 31536000000) + 1; // in-game years
    const month = Math.floor((time % 31536000000) / 2592000000) + 1;
    const day = Math.floor(((time % 2592000000) / 86400000) + 1);

    // Determine season based on month
    let season: string;
    switch (month) {
      case 12:
      case 1:
      case 2:
        season = "winter";
        break;
      case 3:
      case 4:
      case 5:
        season = "spring";
        break;
      case 6:
      case 7:
      case 8:
        season = "summer";
        break;
      case 9:
      case 10:
      case 11:
        season = "autumn";
        break;
      default:
        season = "spring";
    }

    this.currentState.world = {
      seed: this.currentState.world.seed,
      season: season,
      year: year
    };
  }

  /**
   * Get the current simulation state
   */
  getState(): SimulationState {
    return { ...this.currentState };
  }

  /**
   * Get a specific factor's current value
   */
  getFactorValue(factorId: string): number | undefined {
    const factor = FactorRegistry.get(factorId);
    return factor ? factor.getState() : undefined;
  }

  /**
   * Set a factor's value (with cause tracking)
   */
  setFactorValue(factorId: string, value: number, cause: string): void {
    FactorRegistry.updateFactor(factorId, value, cause);
    // Also update the current state
    const factor = FactorRegistry.get(factorId);
    if (factor) {
      this.currentState.factors.set(factorId, factor.getState());
    }
  }

  /**
   * Register a factor with the system
   */
  registerFactor(factor: Factor): void {
    this.factorRegistry.register(factor);
    // Also register dependencies if the factor has them
    if (factor.base.dependencies) {
      factor.base.dependencies.forEach(depId => {
        // Ensure the dependency is tracked
        // In a full implementation, this would be set up in the dependency graph
      });
    }
  }

  /**
   * Unregister a factor
   */
  unregisterFactor(factorId: string): void {
    this.factorRegistry.unregister(factorId);
    this.dependencyGraph.getDependencies(factorId).forEach(dep => {
      // Clean up dependency tracking
    });
  }
}