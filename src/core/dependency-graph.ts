/**
 * Dependency Graph - Core Infrastructure Layer 1
 * 
 * Manages causal dependencies between simulation factors and systems.
 * Supports direct, indirect, delayed, feedback, and conditional dependencies.
 */

// Dependency type enum
export enum DependencyType {
  DIRECT = "direct",
  INDIRECT = "indirect",
  DELAYED = "delayed",
  FEEDBACK = "feedback",
  CONDITIONAL = "conditional"
}

// Dependency metadata
export interface DependencyMetadata {
  type: DependencyType;
  /** How many time steps to delay (for delayed dependencies) */
  delaySteps?: number;
  /** Condition for conditional dependencies */
  condition?: (state: FactorState) => boolean;
  /** Weight for the dependency strength */
  weight?: number;
}

/**
 * Dependency record between factors
 */
export class Dependency {
  public readonly source: string; // factor ID that influences
  public readonly target: string; // factor ID that is influenced
  public readonly type: DependencyType;
  private delayCounter: number = 0;
  private metadata: DependencyMetadata;

  constructor(source: string, target: string, type: DependencyType, metadata: DependencyMetadata = {}) {
    this.source = source;
    this.target = target;
    this.type = type;
    this.metadata = metadata;
  }

  /**
   * Get the delay counter (for delayed dependencies)
   */
  getDelayCounter(): number {
    return this.delayCounter;
  }

  /**
   * Increment the delay counter
   */
  incrementDelay(): void {
    if (this.type === DependencyType.DELAYED && this.metadata.delaySteps) {
      this.delayCounter++;
      if (this.delayCounter >= this.metadata.delaySteps) {
        this.delayCounter = 0; // Reset after triggering
      }
    }
  }

  /**
   * Check if this dependency should trigger based on current state
   */
  shouldTrigger(currentState: Map<string, number>): boolean {
    switch (this.type) {
      case DependencyType.DIRECT:
        return true;

      case DependencyType.INDIRECT:
        // Indirect: check if intermediate factors have changed
        return this.checkIndirectTrigger(currentState);

      case DependencyType.DELAYED:
        // Will trigger after delaySteps have passed
        return this.delayCounter >= (this.metadata.delaySteps || 0);

      case DependencyType.FEEDBACK:
        // Feedback: trigger based on target's current state affecting source
        return this.checkFeedbackTrigger(currentState);

      case DependencyType.CONDITIONAL:
        // Check the condition function
        if (this.metadata.condition) {
          return this.metadata.condition(Array.from(currentState.entries()));
        }
        return false;

      default:
        return true;
    }
  }

  /**
   * Check indirect dependency trigger
   */
  private checkIndirectTrigger(currentState: Map<string, number>): boolean {
    // For indirect dependencies, check if any intermediate factors have changed significantly
    // This is a simplified implementation
    const sourceFactor = FactorRegistry.get(this.source);
    const targetFactor = FactorRegistry.get(this.target);

    if (!sourceFactor || !targetFactor) return false;

    // Check if source has recently changed
    const history = FactorRegistry.getFactorHistory(this.source);
    if (history.length === 0) return false;

    const lastChange = history[history.length - 1];
    return lastChange.cause !== undefined;
  }

  /**
   * Check feedback dependency trigger
   */
  private checkFeedbackTrigger(currentState: Map<string, number>): boolean {
    // Feedback: check if the target factor's state is influencing the source
    const targetFactor = FactorRegistry.get(this.target);
    const sourceFactor = FactorRegistry.get(this.source);

    if (!targetFactor || !sourceFactor) return false;

    // Simple feedback check: if target changed recently and source is in its influences
    const history = FactorRegistry.getFactorHistory(this.target);
    if (history.length === 0) return false;

    const lastChange = history[history.length - 1];
    // The target's change should affect factors that influence it or are influenced by it
    return true; // Simplified: always trigger for feedback
  }
 }

// Dependency graph management
export class DependencyGraph {
  private dependencies: Map<string, Dependency[]> = new Map(); // target -> [dependencies]

  /**
   * Add a dependency from source to target
   */
  addDependency(source: string, target: string, type: DependencyType, metadata: DependencyMetadata = {}): void {
    let deps = this.dependencies.get(target) || [];
    const dep = new Dependency(source, target, type, metadata);
    deps.push(dep);
    this.dependencies.set(target, deps);
  }

  /**
   * Get all dependencies for a target factor
   */
  getDependencies(target: string): Dependency[] {
    return this.dependencies.get(target) || [];
  }

  /**
   * Check all dependencies for a target and trigger appropriate updates
   */
  checkDependencies(target: string, currentState: Map<string, number>): Dependency[] {
    const deps = this.getDependencies(target);
    const triggered: Dependency[] = [];

    deps.forEach(dep => {
      if (dep.shouldTrigger(currentState)) {
        triggered.push(dep);
        // Increment delay counter for delayed dependencies
        dep.incrementDelay();
      }
    });

    return triggered;
  }

  /**
   * Get all factors that influence a given factor (direct and indirect)
   */
  getInfluencers(factorId: string): Set<string> {
    const influencers = new Set<string>();
    const visited = new Set<string>();

    const traverse = (id: string) => {
      if (visited.has(id)) return;
      visited.add(id);

      const deps = this.getDependencies(id);
      deps.forEach(dep => {
        influencers.add(dep.source);
        traverse(dep.source);
      });
    };

    traverse(factorId);
    return influencers;
  }

  /**
   * Get all factors influenced by a given factor (direct and indirect)
   */
  getInfluenced(factorId: string): Set<string> {
    const influenced = new Set<string>();
    const visited = new Set<string>();

    const traverse = (id: string) => {
      if (visited.has(id)) return;
      visited.add(id);

      const deps = this.getDependencies(id);
      deps.forEach(dep => {
        influenced.add(dep.target);
        traverse(dep.target);
      });
    };

    traverse(factorId);
    return influenced;
  }
}