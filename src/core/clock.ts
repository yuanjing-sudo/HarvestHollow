/**
 * Simulation Clock - Core Infrastructure Layer 1
 * 
 * Manages multiple simulation frequencies for the game world.
 * Frequencies range from per-frame to annual updates.
 */

// Simulation frequency tiers
export enum SimulationFrequency {
  FRAME = "frame",       // Graphics, animations, player controls
  SECONDS = "seconds",   // NPC movement, immediate interactions
  HOURLY = "hourly",     // Weather, selected production processes
  DAILY = "daily",       // Crop growth, consumption, wages, market updates
  WEEKLY = "weekly",     // Business performance, employment, supply chains
  MONTHLY = "monthly",   // Inflation, taxation, population and government budgets
  QUARTERLY = "quarterly", // Economic growth, investment, interest rates
  ANNUALLY = "annually"  // Elections, demographic changes, long-term policies
}

// Frequency intervals in milliseconds
const FREQUENCY_INTERVALS: Record<SimulationFrequency, number> = {
  [SimulationFrequency.FRAME]: 1000 / 60,     // 60 FPS
  [SimulationFrequency.SECONDS]: 1000,          // Every second
  [SimulationFrequency.HOURLY]: 3600000,        // Every hour (real ms, but in-game hour)
  [SimulationFrequency.DAILY]: 86400000,        // Every day
  [SimulationFrequency.WEEKLY]: 604800000,      // Every week
  [SimulationFrequency.MONTHLY]: 2592000000,    // Every month (30 days)
  [SimulationFrequency.QUARTERLY]: 7776000000,  // Every quarter (90 days)
  [SimulationFrequency.ANNUALLY]: 31536000000   // Every year
};

// Get the interval in milliseconds for a frequency
export function getFrequencyInterval(frequency: SimulationFrequency): number {
  return FREQUENCY_INTERVALS[frequency] || 0;
}

// Simulation time tracking
export class SimulationClock {
  private currentTime: number = 0; // in-game milliseconds
  private realTime: number = 0;    // real milliseconds elapsed
  private lastUpdate: { [key: SimulationFrequency]: number } = {};
  private frequencyCallbacks: { [key: SimulationFrequency]: ((delta: number) => void)[] } = {};
  private isPaused: boolean = false;
  private speedMultiplier: number = 1; // 1x normal, 2x fast, 0.5x slow

  constructor() {
    // Initialize lastUpdate for all frequencies
    Object.values(SimulationFrequency).forEach(freq => {
      this.lastUpdate[freq] = this.currentTime;
    });
  }

  /**
   * Advance the simulation clock by the given delta time
   */
  advance(delta: number): void {
    if (this.isPaused) return;

    this.realTime += delta;
    this.currentTime += delta * this.speedMultiplier;

    // Update all frequencies
    const timeSinceLast: { [key: SimulationFrequency]: number } = {};

    Object.values(SimulationFrequency).forEach(freq => {
      const interval = getFrequencyInterval(freq);
      const timePassed = this.currentTime - (timeSinceLast[freq] || this.lastUpdate[freq]);

      if (timePassed >= interval) {
        // How many times should we trigger this frequency?
        const triggers = Math.floor(timePassed / interval);
        timeSinceLast[freq] = this.currentTime - (timePassed % interval);

        // Trigger callbacks
        if (this.frequencyCallbacks[freq]) {
          this.frequencyCallbacks[freq].forEach(callback => {
            for (let i = 0; i < triggers; i++) {
              callback(interval);
            }
          });
        }
      } else {
        timeSinceLast[freq] = this.lastUpdate[freq];
      }
    });

    // Update last update times
    Object.assign(this.lastUpdate, timeSinceLast);
  }

  /**
   * Pause or resume the simulation
   */
  setPaused(paused: boolean): void {
    this.isPaused = paused;
  }

  /**
   * Set the speed multiplier
   */
  setSpeed(speed: number): void {
    this.speedMultiplier = speed;
  }

  /**
   * Register a callback for a specific simulation frequency
   */
  on(frequency: SimulationFrequency, callback: (delta: number) => void): () => void {
    if (!this.frequencyCallbacks[frequency]) {
      this.frequencyCallbacks[frequency] = [];
    }
    this.frequencyCallbacks[frequency].push(callback);

    // Return an unsubscribe function
    return () => {
      const callbacks = this.frequencyCallbacks[frequency];
      if (callbacks) {
        const index = callbacks.indexOf(callback);
        if (index > -1) {
          callbacks.splice(index, 1);
        }
      }
    };
  }

  /**
   * Get the current in-game time
   */
  getCurrentTime(): number {
    return this.currentTime;
  }

  /**
   * Get the real time elapsed
   */
  getRealTime(): number {
    return this.realTime;
  }
}

/**
 * Factor Update Scheduler
 * 
 * Schedules factor updates based on their required frequency
 */
export class FactorScheduler {
  private clock: SimulationClock;
  private factorUpdates: Map<string, { frequency: SimulationFrequency; callback: () => void }> = new Map();

  constructor(clock: SimulationClock) {
    this.clock = clock;
  }

  /**
   * Register a factor for updating at a specific frequency
   */
  registerFactor(
    factorId: string,
    frequency: SimulationFrequency,
    callback: () => void
  ): void {
    this.factorUpdates.set(factorId, { frequency, callback });
    this.clock.on(frequency, () => {
      const registration = this.factorUpdates.get(factorId);
      if (registration) {
        registration.callback();
      }
    });
  }

  /**
   * Unregister a factor
   */
  unregisterFactor(factorId: string): void {
    this.factorUpdates.delete(factorId);
  }
}