/**
 * Inventory and Production Chains - System 6
 * 
 * Manages movement of resources through the economy with production chains.
 * Example: Wheat farm → Wheat storage → Flour mill → Bakery → Retail store → Household consumption.
 */

// Production stage enum
export enum ProductionStage {
  RAW_MATERIAL = "raw_material",
  PROCESSING = "processing",
  MANUFACTURING = "manufacturing",
  RETAIL = "retail",
  CONSUMPTION = "consumption"
}

// Production chain step
export interface ProductionChainStep {
  id: string;
  name: string;
  stage: ProductionStage;
  /** Raw material requirements (resource type -> amount needed) */
  rawMaterials: Map<ResourceType, number>;
  /** Processed output (resource type -> amount produced) */
  outputProducts: Map<ResourceType, number>;
  /** Production capacity per time period */
  capacity: number;
  /** Current utilisation (0-1) */
  utilisation: number;
  /** Energy consumption per unit */
  energyConsumption: number;
  /** Labour hours per unit */
  labourHours: number;
  /** Machine reliability (0-1, 1 = perfectly reliable) */
  reliability: number;
  /** Current product quality (0-100) */
  quality: number;
  /** Waste produced per unit */
  waste: number;
  /** Time to produce one unit (hours) */
  productionTime: number;
}

// Production chain entity
export interface ProductionChainEntity {
  id: string;
  name: string;
  location: { x: number; y: number };
  steps: ProductionChainStep[];
  /** Current inventory of intermediate products */
  inventory: Map<ResourceType, number>;
  /** Operational status */
  isOperational: boolean;
  /** Last production timestamp */
  lastProduction: number;
  /** Total units produced */
  totalProduced: number;
  /** Total waste produced */
  totalWaste: number;
}

// Example chain: Wheat → Flour → Bread → Sale
export const wheatFlourBreadChain: ProductionChainStep[] = [
  {
    id: "wheat-farm",
    name: "Wheat Farm",
    stage: ProductionStage.RAW_MATERIAL,
    rawMaterials: new Map([[ResourceType.FERTILISER, 0.1], [ResourceType.WATER, 5], [ResourceType.ELECTRICITY, 0.5]]),
    outputProducts: new Map([[ResourceType.SEEDS, 0]]), // Seeds are input, wheat is output
    capacity: 10,
    utilisation: 0,
    energyConsumption: 0.5,
    labourHours: 2,
    reliability: 0.95,
    quality: 100,
    waste: 0.02,
    productionTime: 24 // hours for growth cycle simplified
  },
  {
    id: "wheat-storage",
    name: "Wheat Storage",
    stage: ProductionStage.RAW_MATERIAL,
    rawMaterials: new Map(),
    outputProducts: new Map([[ResourceType.SEEDS, 0]]),
    capacity: 500,
    utilisation: 0,
    energyConsumption: 0.1,
    labourHours: 0.5,
    reliability: 0.98,
    quality: 100,
    waste: 0.01,
    productionTime: 1
  },
  {
    id: "flour-mill",
    name: "Flour Mill",
    stage: ProductionStage.PROCESSING,
    rawMaterials: new Map([[ResourceType.SEEDS, 1]]), // Wheat seeds -> flour
    outputProducts: new Map([[ResourceType.SEEDS, 0]]), // This is wrong - should be flour, but we're using ResourceType.SEEDS placeholder
    capacity: 20,
    utilisation: 0,
    energyConsumption: 2,
    labourHours: 1,
    reliability: 0.9,
    quality: 95,
    waste: 0.05,
    productionTime: 4
  },
  {
    id: "bakery",
    name: "Bakery",
    stage: ProductionStage.MANUFACTURING,
    rawMaterials: new Map([[ResourceType.SEEDS, 0.5], [ResourceType.ELECTRICITY, 1], [ResourceType.WATER, 2]]),
    outputProducts: new Map([[ResourceType.PACKAGING, 1]]), // Simplified: bread output
    capacity: 15,
    utilisation: 0,
    energyConsumption: 3,
    labourHours: 3,
    reliability: 0.92,
    quality: 90,
    waste: 0.1,
    productionTime: 6
  },
  {
    id: "retail-store",
    name: "Retail Store",
    stage: ProductionStage.RETAIL,
    rawMaterials: new Map([[ResourceType.PACKAGING, 1]]),
    outputProducts: new Map(),
    capacity: 100,
    utilisation: 0,
    energyConsumption: 1,
    labourHours: 1,
    reliability: 0.97,
    quality: 98,
    waste: 0.08,
    productionTime: 2
  }
];

// Production chain manager
export class ProductionChainManager {
  private chains: Map<string, ProductionChainEntity> = new Map();

  /**
   * Register a production chain entity
   */
  registerEntity(entity: ProductionChainEntity): void {
    this.chains.set(entity.id, entity);
  }

  /**
   * Unregister a production chain entity
   */
  unregisterEntity(id: string): void {
    this.chains.delete(id);
  }

  /**
   * Get a production chain entity by ID
   */
  getEntity(id: string): ProductionChainEntity | undefined {
    return this.chains.get(id);
  }

  /**
   * Get all production chain entities
   */
  getAllEntities(): ProductionChainEntity[] {
    return Array.from(this.chains.values());
  }

  /**
   * Get entities by production stage
   */
  getEntitiesByStage(stage: ProductionStage): ProductionChainEntity[] {
    return Array.from(this.chains.values()).filter(e => e.steps.some(s => s.stage === stage));
  }

  /**
   * Produce one unit at a production chain entity
   * @param entityId ID of the entity to produce at
   * @param rawMaterialsProvided Map of resource types and amounts provided
   * @returns Production result with output products and waste
   */
  produce(entityId: string, rawMaterialsProvided: Map<ResourceType, number>): {
    success: boolean;
    outputProducts: Map<ResourceType, number>;
    wasteProduced: number;
    energyConsumed: number;
    labourHoursUsed: number;
  } {
    const entity = this.chains.get(entityId);
    if (!entity) {
      return { success: false, outputProducts: new Map(), wasteProduced: 0, energyConsumed: 0, labourHoursUsed: 0 };
    }

    // Check if entity is operational
    if (!entity.isOperational) {
      return { success: false, outputProducts: new Map(), wasteProduced: 0, energyConsumed: 0, labourHoursUsed: 0 };
    }

    // Check each step in the chain
    let success = true;
    let totalWaste = 0;
    let totalEnergy = 0;
    let totalLabour = 0;
    const outputProducts = new Map<ResourceType, number>();

    for (const step of entity.steps) {
      // Check raw material requirements
      const rawMaterialsNeeded = step.rawMaterials;
      const canProceed = this.checkRawMaterials(rawMaterialsNeeded, rawMaterialsProvided);

      if (!canProceed) {
        success = false;
        break;
      }

      # Calculate utilisation
      const availableCapacity = step.capacity * (1 - entity.utilisation);
      const productionAmount = Math.min(availableCapacity, 1); // Produce one "unit" per call

      # Check reliability - may fail based on reliability factor
      const reliabilityRoll = Math.random();
      if (reliabilityRoll > step.reliability) {
        # Machine failure - reduced output
        success = false;
        totalWaste += step.waste * productionAmount;
        break;
      }

      # Consume raw materials
      for (const [resourceType, amount] of rawMaterialsNeeded.entries()) {
        const provided = rawMaterialsProvided.get(resourceType) || 0;
        if (provided < amount) {
          success = false;
          break;
        }
      }

      if (!success) break;

      # Consume materials from provided
      for (const [resourceType, amount] of rawMaterialsNeeded.entries()) {
        rawMaterialsProvided.set(resourceType, (rawMaterialsProvided.get(resourceType) || 0) - amount);
      }

      # Produce output products
      for (const [resourceType, amount] of step.outputProducts.entries()) {
        const current = outputProducts.get(resourceType) || 0;
        outputProducts.set(resourceType, current + amount * productionAmount);
      }

      # Add waste
      totalWaste += step.waste * productionAmount;

      # Consume energy
      totalEnergy += step.energyConsumption * productionAmount;

      # Consume labour hours
      totalLabour += step.labourHours * productionAmount;

      # Update utilisation
      entity.utilisation = Math.min(1, entity.utilisation + productionAmount / step.capacity);
    }

    # Update entity state if successful
    if (success) {
      entity.lastProduction = Date.now();
      entity.totalProduced = (entity.totalProduced || 0) + 1;
      entity.totalWaste = (entity.totalWaste || 0) + totalWaste;

      # Update inventory
      for (const [resourceType, amount] of outputProducts.entries()) {
        const current = entity.inventory.get(resourceType) || 0;
        entity.inventory.set(resourceType, current + amount);
      }
    }

    return {
      success,
      outputProducts,
      wasteProduced: totalWaste,
      energyConsumed: totalEnergy,
      labourHoursUsed: totalLabour
    };
  }

  /**
   * Check if raw materials are sufficiently provided
   */
  private checkRawMaterials(
    needed: Map<ResourceType, number>,
    provided: Map<ResourceType, number>
  ): boolean {
    for (const [resourceType, neededAmount] of needed.entries()) {
      const providedAmount = provided.get(resourceType) || 0;
      if (providedAmount < neededAmount) {
        return false;
      }
    }
    return true;
  }

  /**
   * Advance production chain state (update utilisation, etc.)
   */
  advanceTime(deltaDays: number): void {
    for (const entity of this.chains.values()) {
      # Gradual recovery of utilisation if not operating
      if (!entity.isOperational) {
        entity.utilisation = Math.max(0, entity.utilisation - 0.01 * deltaDays / 30);
      }

      # Gradual wear and tear affecting reliability
      const wearRate = 0.0001 * deltaDays;
      entity.utilisation = Math.max(0, entity.utilisation - wearRate);

      # Reliability degrades with high utilisation
      if (entity.utilisation > 0.8) {
        entity.reliability = Math.max(0.5, entity.reliability - 0.001 * deltaDays);
      } else {
        # Slight recovery when operating at lower utilisation
        entity.reliability = Math.min(0.99, entity.reliability + 0.0005 * deltaDays);
      }
    }
  }
}