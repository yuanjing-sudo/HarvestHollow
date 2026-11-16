/**
 * Resources and Utilities - System 5
 * 
 * Models availability, production, consumption and cost of essential resources.
 * Water, electricity, fuel, fertiliser, seeds, animal feed, timber, stone, metal,
 * construction materials, machinery parts, medicines, packaging, storage capacity,
 * and renewable energy.
 */

// Resource type enumeration
export enum ResourceType {
  WATER = "water",
  ELECTRICITY = "electricity",
  FUEL = "fuel",
  FERTILISER = "fertiliser",
  SEEDS = "seeds",
  ANIMAL_FEED = "animal_feed",
  TIMBER = "timber",
  STONE = "stone",
  METAL = "metal",
  CONSTRUCTION_MATERIALS = "construction_materials",
  MACHINERY_PARTS = "machinery_parts",
  MEDICINES = "medicines",
  PACKAGING = "packaging",
  STORAGE_CAPACITY = "storage_capacity",
  RENEWABLE_ENERGY = "renewable_energy"
}

// Resource unit types
export type ResourceAmount = number; // Amount in base units
export type ResourcePrice = number; // Price per unit

// Resource inventory item
export interface ResourceInventoryItem {
  resourceType: ResourceType;
  amount: ResourceAmount;
  maximumCapacity: ResourceAmount;
  lastRestocked: number;
  spoilageRate: number; // 0-1 per month
  isPerishable: boolean;
}

// Resource market listing
export interface ResourceMarketListing {
  resourceType: ResourceType;
  price: ResourcePrice;
  quantityAvailable: ResourceAmount;
  quantityDemanded: ResourceAmount;
  source: 'local' | 'regional' | 'imported';
  expiry: number; // When price data expires
}

// Resource supply info
export interface ResourceSupplyInfo {
  resourceType: ResourceType;
  productionRate: ResourceAmount; // per day
  consumptionRate: ResourceAmount; // per day
  inventoryLevel: ResourceAmount;
  marketPrice: ResourcePrice;
  shortageLevel: 'none' | 'low' | 'medium' | 'high';
  lastUpdated: number;
}

// Base resource definitions with default properties
export interface ResourceDefinition {
  resourceType: ResourceType;
  baseName: string;
  baseAmount: ResourceAmount; // Starting amount per entity
  maximumStorage: ResourceAmount;
  spoilageRate: number; // per day (0 = non-perishable)
  isPerishable: boolean;
  basePrice: ResourcePrice;
  productionComplexity: number; // 1-10, how complex to produce
  consumptionPriority: number; // 1-10, how critical for survival
}

// Specific resource instances
export class WaterResource {
  private amount: ResourceAmount;
  private maxCapacity: ResourceAmount;
  private readonly spoilageRate = 0.001; // Very slow spoilage

  constructor(initialAmount: ResourceAmount = 100, maxCapacity: ResourceAmount = 500) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  /**
   * Get current water amount
   */
  getAmount(): ResourceAmount {
    return this.amount;
  }

  /**
   * Set water amount (with bounds checking)
   */
  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  /**
   * Add water to inventory
   */
  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  /**
   * Remove water from inventory
   */
  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  /**
   * Get maximum capacity
   */
  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  /**
   * Consume water for use
   * @param amount Amount to consume
   * @returns true if successful, false if insufficient water
   */
  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }

  /**
   * Evaporative loss over time
   */
  evaporate(deltaDays: number): void {
    const loss = this.amount * this.spoilageRate * deltaDays;
    this.amount = Math.max(0, this.amount - loss);
  }
 }

// Electricity resource
export class ElectricityResource {
  private amount: ResourceAmount; // kWh
  private maxCapacity: ResourceAmount;
  private productionRate: ResourceAmount; // kWh per day from own generation

  constructor(initialAmount: ResourceAmount = 100, maxCapacity: ResourceAmount = 500, productionRate: ResourceAmount = 0) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
    this.productionRate = productionRate;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }

  addProduction(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  setProductionRate(rate: ResourceAmount): void {
    this.productionRate = rate;
  }

  getProductionRate(): ResourceAmount {
    return this.productionRate;
  }
 }

// Fuel resource
export class FuelResource {
  private amount: ResourceAmount; // Litres
  private maxCapacity: ResourceAmount;
  private readonly energyContent = 33; // MJ per litre (approximate)

  constructor(initialAmount: ResourceAmount = 200, maxCapacity: ResourceAmount = 1000) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }

  getEnergyValue(): number {
    return this.amount * this.energyContent; // Total MJ available
  }
 }

// Fertiliser resource
export class FertiliserResource {
  private amount: ResourceAmount; // kg
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 500) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Seeds resource
export class SeedsResource {
  private amount: ResourceAmount; // kg or seed units
  private maxCapacity: ResourceAmount;
  private readonly viabilityRate = 0.0001; // Very slow degradation/year

  constructor(initialAmount: ResourceAmount = 50, maxCapacity: ResourceAmount = 200) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }

  #degrade(deltaDays: number): void {
    const degradation = this.amount * this.viabilityRate * (deltaDays / 365); // Annual rate
    this.amount = Math.max(0, this.amount - degradation);
  }
 }

// Animal feed resource
export class AnimalFeedResource {
  private amount: ResourceAmount; // kg
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 1000) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Timber resource
export class TimberResource {
  private amount: ResourceAmount; // cubic meters
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 500) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Stone resource
export class StoneResource {
  private amount: ResourceAmount; // tonnes
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 500) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Metal resource
export class MetalResource {
  private amount: ResourceAmount; // tonnes
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 500) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Construction materials resource
export class ConstructionMaterialsResource {
  private amount: ResourceAmount; // tonnes or units
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 500) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Machinery parts resource
export class MachineryPartsResource {
  private amount: ResourceAmount; // units
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 200) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Medicines resource
export class MedicinesResource {
  private amount: ResourceAmount; // units or doses
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 200) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Packaging resource
export class PackagingResource {
  private amount: ResourceAmount; // units
  private maxCapacity: ResourceAmount;

  constructor(initialAmount: ResourceAmount = 0, maxCapacity: ResourceAmount = 500) {
    this.amount = initialAmount;
    this.maxCapacity = maxCapacity;
  }

  getAmount(): ResourceAmount {
    return this.amount;
  }

  setAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, Math.min(this.maxCapacity, amount));
  }

  addAmount(amount: ResourceAmount): void {
    this.amount = Math.min(this.maxCapacity, this.amount + amount);
  }

  removeAmount(amount: ResourceAmount): void {
    this.amount = Math.max(0, this.amount - amount);
  }

  getMaxCapacity(): ResourceAmount {
    return this.maxCapacity;
  }

  consume(amount: ResourceAmount): boolean {
    if (this.amount >= amount) {
      this.amount -= amount;
      return true;
    }
    return false;
  }
 }

// Storage capacity resource (tracks total available storage)
export class StorageCapacityResource {
  private totalCapacity: ResourceAmount; // Maximum storage across all resources
  private usedCapacity: ResourceAmount; // Currently used storage

  constructor(totalCapacity: ResourceAmount = 1000, usedCapacity: ResourceAmount = 0) {
    this.totalCapacity = totalCapacity;
    this.usedCapacity = Math.max(0, Math.min(totalCapacity, usedCapacity));
  }

  getTotalCapacity(): ResourceAmount {
    return this.totalCapacity;
  }

  getUsedCapacity(): ResourceAmount {
    return this.usedCapacity;
  }

  getAvailableCapacity(): ResourceAmount {
    return this.totalCapacity - this.usedCapacity;
  }

  setTotalCapacity(capacity: ResourceAmount): void {
    this.totalCapacity = capacity;
    // Adjust used capacity if it exceeds new total
    this.usedCapacity = Math.max(0, Math.min(capacity, this.usedCapacity));
  }

  addUsedCapacity(amount: ResourceAmount): void {
    this.usedCapacity = Math.min(this.totalCapacity, this.usedCapacity + amount);
  }

  reduceUsedCapacity(amount: ResourceAmount): void {
    this.usedCapacity = Math.max(0, this.usedCapacity - amount);
  }
}

// Resource manager - handles all resource types
export class ResourceManager {
  private water: WaterResource;
  private electricity: ElectricityResource;
  private fuel: FuelResource;
  private fertiliser: FertiliserResource;
  private seeds: SeedsResource;
  private animalFeed: AnimalFeedResource;
  private timber: TimberResource;
  private stone: StoneResource;
  private metal: MetalResource;
  private constructionMaterials: ConstructionMaterialsResource;
  private machineryParts: MachineryPartsResource;
  private medicines: MedicinesResource;
  private packaging: PackagingResource;
  private storage: StorageCapacityResource;

  constructor() {
    this.water = new WaterResource();
    this.electricity = new ElectricityResource();
    this.fuel = new FuelResource();
    this.fertiliser = new FertiliserResource();
    this.seeds = new SeedsResource();
    this.animalFeed = new AnimalFeedResource();
    this.timber = new TimberResource();
    this.stone = new StoneResource();
    this.metal = new MetalResource();
    this.constructionMaterials = new ConstructionMaterialsResource();
    this.machineryParts = new MachineryPartsResource();
    this.medicines = new MedicinesResource();
    this.packaging = new PackagingResource();
    this.storage = new StorageCapacityResource();
  }

  // Water accessors
  getWaterAmount(): ResourceAmount { return this.water.getAmount(); }
  setWaterAmount(amount: ResourceAmount) { this.water.setAmount(amount); }
  addWater(amount: ResourceAmount) { this.water.addAmount(amount); }
  removeWater(amount: ResourceAmount) { this.water.removeAmount(amount); }
  consumeWater(amount: ResourceAmount): boolean { return this.water.consume(amount); }
  getWaterMax(): ResourceAmount { return this.water.getMaxCapacity(); }
  evaporateWater(deltaDays: number) { this.water.evaporate(deltaDays); }

  # Electricity accessors
  getElectricityAmount(): ResourceAmount { return this.electricity.getAmount(); }
  setElectricityAmount(amount: ResourceAmount) { this.electricity.setAmount(amount); }
  addElectricity(amount: ResourceAmount) { this.electricity.addAmount(amount); }
  removeElectricity(amount: ResourceAmount) { this.electricity.removeAmount(amount); }
  consumeElectricity(amount: ResourceAmount): boolean { return this.electricity.consume(amount); }
  getElectricityMax(): ResourceAmount { return this.electricity.getMaxCapacity(); }
  addProduction(amount: ResourceAmount) { this.electricity.addProduction(amount); }
  setProductionRate(rate: ResourceAmount) { this.electricity.setProductionRate(rate); }
  getProductionRate(): ResourceAmount { return this.electricity.getProductionRate(); }

  # Fuel accessors
  getFuelAmount(): ResourceAmount { return this.fuel.getAmount(); }
  setFuelAmount(amount: ResourceAmount) { this.fuel.setAmount(amount); }
  addFuel(amount: ResourceAmount) { this.fuel.addAmount(amount); }
  removeFuel(amount: ResourceAmount) { this.fuel.removeAmount(amount); }
  consumeFuel(amount: ResourceAmount): boolean { return this.fuel.consume(amount); }
  getFuelMax(): ResourceAmount { return this.fuel.getMaxCapacity(); }
  getEnergyValue(): number { return this.fuel.getEnergyValue(); }

  # Fertiliser accessors
  getFertiliserAmount(): ResourceAmount { return this.fertiliser.getAmount(); }
  setFertiliserAmount(amount: ResourceAmount) { this.fertiliser.setAmount(amount); }
  addFertiliser(amount: ResourceAmount) { this.fertiliser.addAmount(amount); }
  removeFertiliser(amount: ResourceAmount) { this.fertiliser.removeAmount(amount); }

  # Seeds accessors
  getSeedsAmount(): ResourceAmount { return this.seeds.getAmount(); }
  setSeedsAmount(amount: ResourceAmount) { this.seeds.setAmount(amount); }
  addSeeds(amount: ResourceAmount) { this.seeds.addAmount(amount); }
  removeSeeds(amount: ResourceAmount) { this.seeds.removeAmount(amount); }
  #degradeSeeds(deltaDays: number) { this.seeds.#degrade(deltaDays); }

  # Animal feed accessors
  getAnimalFeedAmount(): ResourceAmount { return this.animalFeed.getAmount(); }
  setAnimalFeedAmount(amount: ResourceAmount) { this.animalFeed.setAmount(amount); }
  addAnimalFeed(amount: ResourceAmount) { this.animalFeed.addAmount(amount); }
  removeAnimalFeed(amount: ResourceAmount) { this.animalFeed.removeAmount(amount); }

  # Timber accessors
  getTimberAmount(): ResourceAmount { return this.timber.getAmount(); }
  setTimberAmount(amount: ResourceAmount) { this.timber.setAmount(amount); }
  addTimber(amount: ResourceAmount) { this.timber.addAmount(amount); }
  removeTimber(amount: ResourceAmount) { this.timber.removeAmount(amount); }

  # Stone accessors
  getStoneAmount(): ResourceAmount { return this.stone.getAmount(); }
  setStoneAmount(amount: ResourceAmount) { this.stone.setAmount(amount); }
  addStone(amount: ResourceAmount) { this.stone.addAmount(amount); }
  removeStone(amount: ResourceAmount) { this.stone.removeAmount(amount); }

  # Metal accessors
  getMetalAmount(): ResourceAmount { return this.metal.getAmount(); }
  setMetalAmount(amount: ResourceAmount) { this.metal.setAmount(amount); }
  addMetal(amount: ResourceAmount) { this.metal.addAmount(amount); }
  removeMetal(amount: ResourceAmount) { this.metal.removeAmount(amount); }

  # Construction materials accessors
  getConstructionMaterialsAmount(): ResourceAmount { return this.constructionMaterials.getAmount(); }
  setConstructionMaterialsAmount(amount: ResourceAmount) { this.constructionMaterials.setAmount(amount); }
  addConstructionMaterials(amount: ResourceAmount) { this.constructionMaterials.addAmount(amount); }
  removeConstructionMaterials(amount: ResourceAmount) { this.constructionMaterials.removeAmount(amount); }

  # Machinery parts accessors
  getMachineryPartsAmount(): ResourceAmount { return this.machineryParts.getAmount(); }
  setMachineryPartsAmount(amount: ResourceAmount) { this.machineryParts.setAmount(amount); }
  addMachineryParts(amount: ResourceAmount) { this.machineryParts.addAmount(amount); }
  removeMachineryParts(amount: ResourceAmount) { this.machineryParts.removeAmount(amount); }

  # Medicines accessors
  getMedicinesAmount(): ResourceAmount { return this.medicines.getAmount(); }
  setMedicinesAmount(amount: ResourceAmount) { this.medicines.setAmount(amount); }
  addMedicines(amount: ResourceAmount) { this.medicines.addAmount(amount); }
  removeMedicines(amount: ResourceAmount) { this.medicines.removeAmount(amount); }

  # Packaging accessors
  getPackagingAmount(): ResourceAmount { return this.packaging.getAmount(); }
  setPackagingAmount(amount: ResourceAmount) { this.packaging.setAmount(amount); }
  addPackaging(amount: ResourceAmount) { this.packaging.addAmount(amount); }
  removePackaging(amount: ResourceAmount) { this.packaging.removeAmount(amount); }

  # Storage accessors
  getTotalCapacity(): ResourceAmount { return this.storage.getTotalCapacity(); }
  getUsedCapacity(): ResourceAmount { return this.storage.getUsedCapacity(); }
  getAvailableCapacity(): ResourceAmount { return this.storage.getAvailableCapacity(); }
  setTotalCapacity(capacity: ResourceAmount) { this.storage.setTotalCapacity(capacity); }
  addUsedCapacity(amount: ResourceAmount) { this.storage.addUsedCapacity(amount); }
  reduceUsedCapacity(amount: ResourceAmount) { this.storage.reduceUsedCapacity(amount); }

  # Resource summary
  getResourceSummary(): Map<ResourceType, ResourceAmount> {
    return new Map([
      [ResourceType.WATER, this.getWaterAmount()],
      [ResourceType.ELECTRICITY, this.getElectricityAmount()],
      [ResourceType.FUEL, this.getFuelAmount()],
      [ResourceType.FERTILISER, this.getFertiliserAmount()],
      [ResourceType.SEEDS, this.getSeedsAmount()],
      [ResourceType.ANIMAL_FEED, this.getAnimalFeedAmount()],
      [ResourceType.TIMBER, this.getTimberAmount()],
      [ResourceType.STONE, this.getStoneAmount()],
      [ResourceType.METAL, this.getMetalAmount()],
      [ResourceType.CONSTRUCTION_MATERIALS, this.getConstructionMaterialsAmount()],
      [ResourceType.MACHINERY_PARTS, this.getMachineryPartsAmount()],
      [ResourceType.MEDICINES, this.getMedicinesAmount()],
      [ResourceType.PACKAGING, this.getPackagingAmount()]
    ]);
  }

  # Resource price lookup (simplified market prices)
  getResourcePrice(resourceType: ResourceType): ResourcePrice {
    const basePrices: Record<ResourceType, ResourcePrice> = {
      [ResourceType.WATER]: 0.01,
      [ResourceType.ELECTRICITY]: 0.15,
      [ResourceType.FUEL]: 1.20,
      [ResourceType.FERTILISER]: 2.50,
      [ResourceType.SEEDS]: 3.75,
      [ResourceType.ANIMAL_FEED]: 1.80,
      [ResourceType.TIMBER]: 0.75,
      [ResourceType.STONE]: 1.10,
      [ResourceType.METAL]: 4.50,
      [ResourceType.CONSTRUCTION_MATERIALS]: 2.20,
      [ResourceType.MACHINERY_PARTS]: 12.00,
      [ResourceType.MEDICINES]: 8.30,
      [ResourceType.PACKAGING]: 0.45
    ];

    return basePrices[resourceType] || 0;
  }

  # Simulate resource price fluctuations based on supply/demand
  simulateMarketFluctuation(resourceType: ResourceType, supplyChange: number): void {
    // Simple price adjustment based on supply changes
    // Positive supplyChange = more supply = lower prices
    // Negative supplyChange = less supply = higher prices
    const price = this.getResourcePrice(resourceType);
    const sensitivity = 0.1; // 10% price change per unit supply
    const priceAdjustment = price * sensitivity * supplyChange;

    // In a full implementation, this would update market listings
    // For now, we just track the concept
  }
}