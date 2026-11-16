/**
 * Crop Simulation - System 3
 * 
 * Sophisticated crop growth subsystem with growth stages, health tracking,
 * and variety development through research and breeding.
 */

// Crop species enumeration
export enum CropSpecies {
  WHEAT = "wheat",
  RICE = "rice",
  CORN = "corn",
  POTATO = "potato",
  TOMATO = "tomato",
  CARROT = "carrot",
  LETTUCE = "lettuce",
  SOYBEAN = "soybean",
  BARLEY = "barley",
  OATS = "oats"
}

// Crop variety identifier
export type CropVariety = string;

// Growth stage enumeration
export enum GrowthStage {
  SEED_PREPARATION = "seed_preparation",
  GERMINATION = "germination",
  SEEDLING = "seedling",
  VEGETATIVE = "vegetative",
  FLOWERING = "flowering",
  FRUIT_FORMATION = "fruit_formation",
  MATURATION = "maturation",
  HARVEST = "harvest"
}

// Crop properties interface
export interface CropProperties {
  species: CropSpecies;
  variety: CropVariety;
  growthDuration: number; // Days from planting to maturity (ideal)
  idealTemperature: { min: number; opt: number; max: number }; // °C
  waterRequirements: { minimal: number; optimal: number; maximum: number }; // percentage soil moisture
  nutrientRequirements: { nitrogen: number; phosphorus: number; potassium: number }; // 0-100 scale
  sunlightRequirements: { minimal: number; optimal: number; maximum: number }; // hours per day
  diseaseResistance: number; // 0-100
  pestResistance: number; // 0-100
  yieldPotential: number; // kg per m² under ideal conditions
  marketDemand: number; // 0-100 current market demand index
  seedQuality: number; // 0-100, affects growth speed and yield
  shelfLife: number; // Days post-harvest before significant quality loss
}

// Crop health status
export interface CropHealth {
  growthStress: number; // 0-100, higher = stressed by growth conditions
  waterStress: number; // 0-100, water deficiency stress
  nutrientStress: number; // 0-100, nutrient deficiency stress
  temperatureStress: number; // 0-100, temperature outside optimal range
  pestDamage: number; // 0-100, percentage of area affected
  diseaseDamage: number; // 0-100, percentage of area affected
  weedCompetition: number; // 0-100, competition from weeds
  physicalDamage: number; // 0-100, damage from hail, wind, etc.
}

// Crop growth state
export interface CropGrowthState {
  stage: GrowthStage;
  stageStartTime: number; // When this stage began
  stageDuration: number; // How long this stage has lasted (days)
  daysUntilHarvest: number; // Estimated days from current state to harvest
  progress: number; // 0-1, progress within current stage
}

// Harvest results
export interface HarvestResult {
  expectedYield: number; // kg per m² based on potential
  actualYield: number; // kg per m² actually harvested
  harvestQuality: number; // 0-100, overall quality grade
  gradeClassification: 'prime' | 'standard' | 'substandard' | 'waste';
  harvestCosts: number; // Cost of harvesting (labor, fuel, etc.)
  labourRequirements: number; // Hours of labor per m²
  storageRequirements: {
    temperature: number; // °C
    humidity: number; // percentage
    duration: number; // days
  };
  postHarvestLosses: number; // Percentage lost in storage
}

// Main Crop class
export class Crop {
  public readonly properties: CropProperties;
  public readonly health: CropHealth;
  public growthState: CropGrowthState;
  private plantingTime: number;
  private lastUpdate: number = 0;
  private fieldX: number;
  private fieldY: number;

  constructor(
    properties: CropProperties,
    fieldX: number,
    fieldY: number
  ) {
    this.properties = properties;
    this.fieldX = fieldX;
    this.fieldY = fieldY;
    this.health = {
      growthStress: 0,
      waterStress: 0,
      nutrientStress: 0,
      temperatureStress: 0,
      pestDamage: 0,
      diseaseDamage: 0,
      weedCompetition: 0,
      physicalDamage: 0
    };

    // Initialize growth state
    this.growthState = {
      stage: GrowthStage.SEED_PREPARATION,
      stageStartTime: Date.now(),
      stageDuration: 0,
      daysUntilHarvest: properties.growthDuration,
      progress: 0
    };

    this.plantingTime = Date.now();
  }

  /**
   * Get the crop's field position
   */
  getFieldPosition(): { x: number; y: number } {
    return { x: this.fieldX, y: this.fieldY };
  }

  /**
   * Get the crop species
   */
  getSpecies(): CropSpecies {
    return this.properties.species;
  }

  /**
   * Get the crop variety
   */
  getVariety(): CropVariety {
    return this.properties.variety;
  }

  /**
   * Get the current growth stage
   */
  getStage(): GrowthStage {
    return this.growthState.stage;
  }

  /**
   * Get stage progress (0-1)
   */
  getStageProgress(): number {
    return this.growthState.progress;
  }

  /**
   * Get days until estimated harvest
   */
  getDaysUntilHarvest(): number {
    return this.growthState.daysUntilHarvest;
  }

  /**
   * Get time since planting in days
   */
  getDaysSincePlanting(): number {
    return (Date.now() - this.plantingTime) / 86400000;
  }

  /**
   * Advance the crop growth by one time step
   */
  advanceGrowth(deltaDays: number, environment: {
    temperature: number;
    moisture: number;
    nitrogen: number;
    phosphorus: number;
    potassium: number;
    sunlightHours: number;
  }): HarvestResult | null {
    const days = deltaDays / 86400000; // Convert to days
    if (days <= 0) return null;

    this.lastUpdate = Date.now();
    this.growthState.stageDuration += days;

    // Calculate stresses from environment
    const stresses = this.calculateStresses(environment);

    // Update health based on stresses
    this.updateHealth(stresses);

    // Progress through growth stages
    const stageProgressed = this.advanceStage(days);

    // Check if ready for harvest
    if (this.growthState.stage === GrowthStage.HARVEST) {
      return this.performHarvest();
    }

    // Return null if not yet harvestable
    return null;
  }

  /**
   * Calculate stresses from environmental conditions
   */
  private calculateStresses(env: {
    temperature: number;
    moisture: number;
    nitrogen: number;
    phosphorus: number;
    potassium: number;
    sunlightHours: number;
  }): {
    growthStress: number;
    waterStress: number;
    nutrientStress: number;
    temperatureStress: number;
  } {
    // Temperature stress
    const { min, opt, max } = this.properties.idealTemperature;
    let temperatureStress = 0;
    if (env.temperature < min || env.temperature > max) {
      temperatureStress = 50 + Math.abs(env.temperature - opt) * 2;
    } else if (env.temperature < opt) {
      temperatureStress = (opt - env.temperature) * 2;
    } else if (env.temperature > opt) {
      temperatureStress = (env.temperature - opt) * 2;
    }
    temperatureStress = Math.max(0, Math.min(100, temperatureStress));

    # Water stress
    const { minimal, optimal, maximum } = this.properties.waterRequirements;
    let waterStress = 0;
    if (env.moisture < minimal) {
      waterStress = 100; // Severe stress
    } else if (env.moisture < optimal) {
      waterStress = (optimal - env.moisture) * 2;
    } else if (env.moisture > maximum) {
      waterStress = (env.moisture - maximum) * 1.5;
    }
    waterStress = Math.max(0, Math.min(100, waterStress));

    # Nutrient stress
    const { nitrogen: reqN, phosphorus: reqP, potassium: reqK } = this.properties.nutrientRequirements;
    let nutrientStress = 0;
    const availableN = env.nitrogen || 0;
    const availableP = env.phosphorus || 0;
    const availableK = env.potassium || 0;

    if (availableN < reqN * 0.5) nutrientStress += 30;
    if (availableP < reqP * 0.5) nutrientStress += 20;
    if (availableK < reqK * 0.5) nutrientStress += 20;
    nutrientStress = Math.min(100, nutrientStress);

    # Growth stress combines all
    const growthStress = Math.min(100, temperatureStress + waterStress + nutrientStress);

    return { growthStress, waterStress, nutrientStress, temperatureStress };
  }

  /**
   * Update health status based on calculated stresses
   */
  private updateHealth(stresses: {
    growthStress: number;
    waterStress: number;
    nutrientStress: number;
    temperatureStress: number;
  }): void {
    // Health components update towards stress levels
    const smoothing = 0.15; // How quickly health adjusts

    this.health.growthStress = Math.min(100, this.health.growthStress + (stresses.growthStress - this.health.growthStress) * smoothing);
    this.health.waterStress = Math.min(100, this.health.waterStress + (stresses.waterStress - this.health.waterStress) * smoothing);
    this.health.nutrientStress = Math.min(100, this.health.nutrientStress + (stresses.nutrientStress - this.health.nutrientStress) * smoothing);
    this.health.temperatureStress = Math.min(100, this.health.temperatureStress + (stresses.temperatureStress - this.health.temperatureStress) * smoothing);
  }

  /**
   * Advance through growth stages
   */
  private advanceStage(days: number): boolean {
    // Days required to progress through each stage
    // These are ideal days, adjusted by stresses
    const stageDurations: Record<GrowthStage, number> = {
      [GrowthStage.SEED_PREPARATION]: 1,
      [GrowthStage.GERMINATION]: 5,
      [GrowthStage.SEEDLING]: 10,
      [GrowthStage.VEGETATIVE]: 30,
      [GrowthStage.FLOWERING]: 10,
      [GrowthStage.FRUIT_FORMATION]: 15,
      [GrowthStage.MATURATION]: 10,
      [GrowthStage.HARVEST]: 1
    };

    const idealDays = stageDurations[this.growthState.stage] || 1;

    // Adjust for stresses - stress slows growth
    const stressFactor = 1 + (this.health.growthStress / 100) * 0.5; // Up to 50% slower
    const adjustedDays = idealDays * stressFactor;

    this.growthState.stageDuration += days;
    this.growthState.progress = Math.min(1, this.growthState.stageDuration / adjustedDays);

    // Check if we've progressed to the next stage
    if (this.growthState.progress >= 1) {
      // Move to next stage
      const stages: GrowthStage[] = [
        GrowthStage.SEED_PREPARATION,
        GrowthStage.GERMINATION,
        GrowthStage.SEEDLING,
        GrowthStage.VEGETATIVE,
        GrowthStage.FLOWERING,
        GrowthStage.FRUIT_FORMATION,
        GrowthStage.MATURATION,
        GrowthStage.HARVEST
      ];

      const currentIndex = stages.indexOf(this.growthState.stage);
      if (currentIndex >= 0 && currentIndex < stages.length - 1) {
        this.growthState.stage = stages[currentIndex + 1];
        this.growthState.stageStartTime = Date.now();
        this.growthState.stageDuration = 0;
        this.growthState.progress = 0;

        // Check if we've reached harvest
        if (this.growthState.stage === GrowthStage.HARVEST) {
          return true;
        }
      }
    }

    return false;
  }

  /**
   * Perform harvest and calculate results
   */
  private performHarvest(): HarvestResult {
    // Base yield from potential, modified by health and stresses
    const baseYield = this.properties.yieldPotential;

    // Health modifications
    const healthFactor = 1 - (this.health.growthStress + this.health.waterStress + this.health.nutrientStress + this.health.pestDamage + this.health.diseaseDamage) / 500;

    # Pest and disease heavily impact yield
    const pestFactor = 1 - this.health.pestDamage / 100;
    const diseaseFactor = 1 - this.health.diseaseDamage / 100;

    # Weed competition also reduces yield
    const weedFactor = 1 - this.health.weedCompetition / 100;

    # Physical damage
    const physicalFactor = 1 - this.health.physicalDamage / 100;

    # Calculate actual yield
    const actualYield = baseYield * healthFactor * pestFactor * diseaseFactor * weedFactor * physicalFactor;

    # Quality classification
    let quality: 'prime' | 'standard' | 'substandard' | 'waste';
    const qualityScore = 100 - (this.health.growthStress + this.health.waterStress + this.health.nutrientStress + this.health.pestDamage + this.health.diseaseDamage + this.health.physicalDamage) / 2;

    if (qualityScore >= 80) quality = 'prime';
    else if (qualityScore >= 60) quality = 'standard';
    else if (qualityScore >= 40) quality = 'substandard';
    else quality = 'waste';

    # Harvest quality score (also factors in market demand alignment)
    const harvestQuality = Math.max(0, Math.min(100, qualityScore));

    # Grade classification
    let grade: 'prime' | 'standard' | 'substandard' | 'waste';
    if (harvestQuality >= 80) grade = 'prime';
    else if (harvestQuality >= 60) grade = 'standard';
    else if (harvestQuality >= 40) grade = 'substandard';
    else grade = 'waste';

    # Harvest costs (labor, fuel, etc.) based on crop size and complexity
    const laborPerUnit = 2; // hours per m² base
    const harvestCosts = actualYield * laborPerUnit * 0.5; // simplified cost calculation

    # Labour requirements
    const labourRequirements = actualYield * laborPerUnit;

    # Storage requirements (depends on crop type)
    const storageTemp = this.getStorageTemperature();
    const storageHumidity = this.getStorageHumidity();
    const maxStorageDays = this.getMaxStorageDays();

    # Post-harvest losses based on quality and storage
    const lossRate = (quality <= 40 ? 20 : quality <= 70 ? 10 : 3) / 100;
    const postHarvestLosses = lossRate;

    # Days until harvest completed
    const daysUntilHarvest = this.growthState.stageDuration;

    return {
      expectedYield: baseYield,
      actualYield: Math.max(0, actualYield),
      harvestQuality,
      gradeClassification: grade,
      harvestCosts,
      labourRequirements,
      storageRequirements: {
        temperature: storageTemp,
        humidity: storageHumidity,
        duration: maxStorageDays
      },
      postHarvestLosses
    };
  }

  private getStorageTemperature(): number {
    // Crop-specific storage temperatures
    switch (this.properties.species) {
      case CropSpecies.WHEAT:
      case CropSpecies.BARLEY:
      case CropSpecies.OATS:
        return 15;
      case CropSpecies.CORN:
        return 10;
      case CropSpecies.TOMATO:
      case CropSpecies.LETTUCE:
        return 4;
      case CropSpecies.POTATO:
        return 8;
      case CropSpecies.CARROT:
        return 1;
      default:
        return 10;
    }
  }

  private getStorageHumidity(): number {
    switch (this.properties.species) {
      case CropSpecies.WHEAT:
      case CropSpecies.BARLEY:
      case CropSpecies.OATS:
        return 60;
      case CropSpecies.CORN:
        return 70;
      case CropSpecies.TOMATO:
        return 90;
      case CropSpecies.POTATO:
        return 85;
      case CropSpecies.CARROT:
        return 95;
      case CropSpecies.LETTUCE:
        return 98;
      default:
        return 80;
    }
  }

  private getMaxStorageDays(): number {
    switch (this.properties.species) {
      case CropSpecies.WHEAT:
      case CropSpecies.BARLEY:
      case CropSpecies.OATS:
        return 365; // Can store a year
      case CropSpecies.CORN:
        return 180;
      case CropSpecies.TOMATO:
        return 14;
      case CropSpecies.POTATO:
        return 120;
      case CropSpecies.CARROT:
        return 210;
      case CropSpecies.LETTUCE:
        return 7;
      default:
        return 30;
    }
  }

  /**
   * Get current growth stage display name
   */
  getStageName(): string {
    return this.growthState.stage;
  }

  /**
   * Get crop health display
   */
  getHealthDisplay(): CropHealth {
    return { ...this.health };
  }

  /**
   * Get growth progress percentage
   */
  getProgressPercentage(): number {
    return this.growthState.progress * 100;
  }

  /**
   * Check if crop is ready for harvest
   */
  isReadyForHarvest(): boolean {
    return this.growthState.stage === GrowthStage.HARVEST;
  }

  /**
   * Get estimated yield before harvest
   */
  getEstimatedYield(): number {
    const baseYield = this.properties.yieldPotential;

    const healthFactor = 1 - (this.health.growthStress + this.health.waterStress + this.health.nutrientStress) / 500;

    return baseYield * healthFactor;
  }

  /**
   * Breed a new variety from this crop
   * Returns a new CropProperties with modified traits
   */
  breedWith(other: Crop): CropProperties {
    // Simple breeding: mix properties from both parents
    const newVariety = `${this.properties.variety}_${other.properties.variety}_${Date.now()}`;

    // Average ideal temperatures
    const avgTempMin = (this.properties.idealTemperature.min + other.properties.idealTemperature.min) / 2;
    const avgTempOpt = (this.properties.idealTemperature.opt + other.properties.idealTemperature.opt) / 2;
    const avgTempMax = (this.properties.idealTemperature.max + other.properties.idealTemperature.max) / 2;

    // Average growth duration
    const avgDuration = (this.properties.growthDuration + other.properties.growthDuration) / 2;

    // Average yield potential
    const avgYield = (this.properties.yieldPotential + other.properties.yieldPotential) / 2;

    // Average disease/pest resistance
    const avgResistance = (this.properties.diseaseResistance + other.properties.diseaseResistance) / 2;
    const avgPestResistance = (this.properties.pestResistance + other.properties.pestResistance) / 2;

    // New properties object
    const newProperties: CropProperties = {
      species: this.properties.species,
      variety: newVariety,
      growthDuration: Math.round(avgDuration),
      idealTemperature: { min: avgTempMin, opt: avgTempOpt, max: avgTempMax },
      waterRequirements: {
        minimal: (this.properties.waterRequirements.minimal + other.properties.waterRequirements.minimal) / 2,
        optimal: (this.properties.waterRequirements.optimal + other.properties.waterRequirements.optimal) / 2,
        maximum: (this.properties.waterRequirements.maximum + other.properties.waterRequirements.maximum) / 2
      },
      nutrientRequirements: {
        nitrogen: (this.properties.nutrientRequirements.nitrogen + other.properties.nutrientRequirements.nitrogen) / 2,
        phosphorus: (this.properties.nutrientRequirements.phosphorus + other.properties.nutrientRequirements.phosphorus) / 2,
        potassium: (this.properties.nutrientRequirements.potassium + other.properties.nutrientRequirements.potassium) / 2
      },
      sunlightRequirements: {
        minimal: (this.properties.sunlightRequirements.minimal + other.properties.sunlightRequirements.minimal) / 2,
        optimal: (this.properties.sunlightRequirements.optimal + other.properties.sunlightRequirements.optimal) / 2,
        maximum: (this.properties.sunlightRequirements.maximum + other.properties.sunlightRequirements.maximum) / 2
      },
      diseaseResistance: avgResistance,
      pestResistance: avgPestResistance,
      yieldPotential: avgYield,
      marketDemand: this.properties.marketDemand, // Keep original demand
      seedQuality: (this.properties.seedQuality + other.properties.seedQuality) / 2,
      shelfLife: (this.properties.shelfLife + other.properties.shelfLife) / 2
    };

    return newProperties;
  }
}

// Crop registry for managing all crops in the world
export class CropRegistry {
  private crops: Map<string, Crop> = new Map();

  /**
   * Register a crop
   */
  register(crop: Crop): void {
    this.crops.set(crop.getFieldPosition().x + "," + crop.getFieldPosition().y, crop);
  }

  /**
   * Unregister a crop
   */
  unregister(x: number, y: number): void {
    this.crops.delete(x + "," + y);
  }

  /**
   * Get crop at field position
   */
  getAt(x: number, y: number): Crop | undefined {
    return this.crops.get(x + "," + y);
  }

  /**
   * Get all crops
   */
  getAll(): Crop[] {
    return Array.from(this.crops.values());
  }

  /**
   * Get crops by species
   */
  getBySpecies(species: CropSpecies): Crop[] {
    return Array.from(this.crops.values()).filter(c => c.getSpecies() === species);
  }

  /**
   * Get crops by variety
   */
  getByVariety(variety: CropVariety): Crop[] {
    return Array.from(this.crops.values()).filter(c => c.getVariety() === variety);
  }

  /**
   * Plant a new crop at position
   */
  plantCrop(properties: CropProperties, x: number, y: number): Crop {
    const crop = new Crop(properties, x, y);
    this.register(crop);
    return crop;
  }

  /**
   * Harvest crop at position
   */
  harvestCrop(x: number, y: number): HarvestResult | null {
    const crop = this.getAt(x, y);
    if (!crop) return null;

    const result = crop.performHarvest();
    this.unregister(x, y);
    return result;
  }

  /**
   * Advance all crops by delta time
   */
  advanceAll(deltaDays: number, environment: {
    temperature: number;
    moisture: number;
    nitrogen: number;
    phosphorus: number;
    potassium: number;
    sunlightHours: number;
  }): Array<{ position: { x: number; y: number }; result: HarvestResult | null }> {
    const results = [];

    for (const [key, crop] of this.crops) {
      const [x, y] = key.split(",").map(Number);
      const result = crop.advanceGrowth(deltaDays, environment);
      results.push({
        position: { x, y },
        result
      });
    }

    return results;
  }
}