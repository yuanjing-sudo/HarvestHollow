/**
 * Livestock Simulation - System 4
 * 
 * Animal characteristics, health, production, and behaviour modelling.
 * Connects to crop production through feed and waste integration.
 */

// Animal species enumeration
export enum AnimalSpecies {
  CHICKEN = "chicken",
  COW = "cow",
  SHEEP = "sheep",
  PIG = "pig",
  GOAT = "goat",
  HORSE = "horse",
  DUCK = "duck",
  GOOSE = "goose",
  TURKEY = "turkey"
}

// Breed types per species
export type Breed = string;

// Animal characteristics
export interface AnimalCharacteristics {
  species: AnimalSpecies;
  breed: Breed;
  age: number; // Days
  sex: 'male' | 'female';
  geneticQuality: number; // 0-100, heritability factor
  weight: number; // kg
  productivity: number; // 0-100, overall productivity index
  fertility: number; // 0-100, breeding fertility
  lifespan: number; // Maximum days
  growthRate: number; // Days to reach full size
}

// Animal health status
export interface AnimalHealth {
  nutrition: number; // 0-100, nutrition level
  hydration: number; // 0-100, water availability
  diseaseRisk: number; // 0-100, probability of disease
  hygiene: number; // 0-100, cleanliness
  stress: number; // 0-100, stress level
  vaccinationStatus: number; // 0-100, vaccine protection
  injuryRisk: number; // 0-100, probability of injury
}

// Animal production outputs
export interface AnimalProduction {
  milkProduction: number; // Litres per day (cows, goats)
  eggProduction: number; // Eggs per day (poultry)
  woolProduction: number; // kg per shearing (sheep)
  meatYield: number; // kg available at slaughter
  breedingOutput: number; // Potential offspring per breeding cycle
  feedConsumption: number; // kg feed per day
  waterConsumption: number; // Litres per day
  wasteProduction: number; // kg waste per day
}

// Animal behaviour state
export interface AnimalBehaviour {
  hunger: number; // 0-100
  thirst: number; // 0-100
  rest: number; // 0-100, how much rest they've gotten
  socialInteraction: number; // 0-100
  movement: number; // 0-100
  environmentalComfort: number; // 0-100
  reproductiveBehaviour: number; // 0-100
}

// Complete animal state
export interface AnimalState {
  characteristics: AnimalCharacteristics;
  health: AnimalHealth;
  production: AnimalProduction;
  behaviour: AnimalBehaviour;
}

// Main Animal class
export class Animal {
  private readonly id: string;
  public readonly characteristics: AnimalCharacteristics;
  public readonly health: AnimalHealth;
  public readonly production: AnimalProduction;
  public readonly behaviour: AnimalBehaviour;
  private readonly birthTime: number;
  private readonly fieldX: number;
  private readonly fieldY: number;
  private breedingEligibilityTimer: number = 0;

  constructor(
    characteristics: AnimalCharacteristics,
    fieldX: number,
    fieldY: number
  ) {
    this.id = `${characteristics.species}-${characteristics.breed}-${Date.now()}`;
    this.characteristics = characteristics;
    this.health = {
      nutrition: 50,
      hydration: 50,
      diseaseRisk: 10,
      hygiene: 75,
      stress: 20,
      vaccinationStatus: 0,
      injuryRisk: 5
    };
    this.production = {
      milkProduction: 0,
      eggProduction: 0,
      woolProduction: 0,
      meatYield: 0,
      breedingOutput: 0,
      feedConsumption: 0,
      waterConsumption: 0,
      wasteProduction: 0
    };
    this.behaviour = {
      hunger: 0,
      thirst: 0,
      rest: 50,
      socialInteraction: 30,
      movement: 30,
      environmentalComfort: 50,
      reproductiveBehaviour: 0
    };
    this.birthTime = Date.now();
    this.fieldX = fieldX;
    this.fieldY = fieldY;
  }

  /**
   * Get animal ID
   */
  getId(): string {
    return this.id;
  }

  /**
   * Get field position
   */
  getFieldPosition(): { x: number; y: number } {
    return { x: this.fieldX, y: this.fieldY };
  }

  /**
   * Get species
   */
  getSpecies(): AnimalSpecies {
    return this.characteristics.species;
  }

  /**
   * Get age in days
   */
  getAge(): number {
    return Math.floor((Date.now() - this.birthTime) / 86400000);
  }

  /**
   * Get age as fraction of lifespan
   */
  getAgeFraction(): number {
    const maxAge = this.characteristics.lifespan;
    if (maxAge <= 0) return 0;
    return Math.min(1, this.getAge() / maxAge);
  }

  /**
   * Get sex
   */
  getSex(): 'male' | 'female' {
    return this.characteristics.sex;
  }

  /**
   * Get genetic quality
   */
  getGeneticQuality(): number {
    return this.characteristics.geneticQuality;
  }

  /**
   * Advance the animal state by one time step
   */
  advance(deltaDays: number, environment: {
    temperature: number;
    availableFeed: number;
    availableWater: number;
    hygieneLevel: number;
    spaceAvailability: number;
  }): void {
    const days = deltaDays / 86400000;

    # Update age fraction
    const ageFraction = this.getAgeFraction();

    # Update behaviours
    this.updateBehaviours(days, environment);

    # Update health
    this.updateHealth(days, environment);

    # Update production
    this.updateProduction(days, environment);

    # Check mortality and life events
    this.checkLifeEvents(ageFraction, environment);

    # Check breeding eligibility
    this.checkBreedingEligibility(days);
  }

  /**
   * Update animal behaviours
   */
  private updateBehaviours(days: number, env: {
    temperature: number;
    availableFeed: number;
    availableWater: number;
    hygieneLevel: number;
    spaceAvailability: number;
  }): void {
    # Hunger: decreases with feed availability
    const feedFactor = Math.min(1, env.availableFeed / 50); // 50 units = fully sated
    const hungerChange = (1 - feedFactor) * 5 * days;
    this.behaviour.hunger = Math.min(100, this.behaviour.hunger + hungerChange);

    # Thirst: decreases with water availability
    const waterFactor = Math.min(1, env.availableWater / 20); // 20 units = fully hydrated
    const thirstChange = (1 - waterFactor) * 5 * days;
    this.behaviour.thirst = Math.min(100, this.behaviour.thirst + thirstChange);

    # Rest: influenced by comfort and time
    const comfortFactor = env.hygieneLevel / 100;
    const restChange = (comfortFactor - this.behaviour.rest / 100) * 2 * days;
    this.behaviour.rest = Math.max(0, Math.min(100, this.behaviour.rest + restChange));

    # Social interaction: herd animals prefer company
    // Simplified: social behavior based on available space and other animals
    const socialFactor = Math.min(1, env.spaceAvailability / 30);
    this.behaviour.socialInteraction = Math.max(0, Math.min(100, socialFactor * 80));

    # Movement: animals move to find resources
    const resourceScarcity = 1 - Math.min(feedFactor, waterFactor);
    this.behaviour.movement = Math.max(0, Math.min(100, resourceScarcity * 60));

    # Environmental comfort
    const tempOptimal = 20;
    const tempDiff = Math.abs(env.temperature - tempOptimal);
    const tempComfort = Math.max(0, 100 - tempDiff);
    const hygieneFactor = env.hygieneLevel / 100;
    this.behaviour.environmentalComfort = Math.max(0, Math.min(100, (tempComfort + hygieneFactor) / 2));

    # Reproductive behaviour
    this.behaviour.reproductiveBehaviour = this.calculateReproductiveBehaviour(env);
  }

  /**
   * Calculate reproductive behaviour based on conditions
   */
  private calculateReproductiveBehaviour(env: {
    temperature: number;
    availableFeed: number;
    availableWater: number;
    hygieneLevel: number;
    spaceAvailability: number;
  }): number {
    # Base reproductive drive decreases with age
    const ageFraction = this.getAgeFraction();
    const ageFactor = Math.max(0, 1 - ageFraction * 0.5); // 50% reduction at end of life

    # Nutrition factor
    const nutritionFactor = env.availableFeed / 50;

    # Water factor
    const waterFactor = env.availableWater / 20;

    # Hygiene factor
    const hygieneFactor = env.hygieneLevel / 100;

    # Space factor
    const spaceFactor = env.spaceAvailability / 50;

    # Combine factors
    const baseDrive = 0.6 * ageFactor + 0.2 * nutritionFactor + 0.1 * waterFactor;
    const fullConditions = hygieneFactor * spaceFactor;

    return Math.max(0, Math.min(100, baseDrive * fullConditions * 80));
  }

  /**
   * Update animal health status
   */
  private updateHealth(days: number, env: {
    temperature: number;
    availableFeed: number;
    availableWater: number;
    hygieneLevel: number;
    spaceAvailability: number;
  }): void {
    # Nutrition update
    const feedFactor = Math.min(1, env.availableFeed / 50);
    const nutritionChange = (feedFactor - 0.5) * 3 * days; // Improves with good feed, declines with poor
    this.health.nutrition = Math.max(0, Math.min(100, this.health.nutrition + nutritionChange));

    # Hydration update
    const waterFactor = Math.min(1, env.availableWater / 20);
    const hydrationChange = (waterFactor - 0.5) * 3 * days;
    this.health.hydration = Math.max(0, Math.min(100, this.health.hydration + hydrationChange));

    # Disease risk: increases with poor nutrition/hygiene, decreases with vaccination
    const nutritionPenalty = (1 - feedFactor) * 2;
    const hygienePenalty = (1 - env.hygieneLevel / 100) * 1;
    const vaccinationProtection = this.health.vaccinationStatus * 0.1;
    const diseaseChange = (nutritionPenalty + hygienePenalty - vaccinationProtection) * 2 * days;
    this.health.diseaseRisk = Math.max(0, Math.min(100, this.health.diseaseRisk + diseaseChange));

    # Hygiene: improves with cleaning, degrades naturally
    const cleaningFactor = 0.1;
    const hygieneChange = (env.hygieneLevel - this.health.hygiene) * cleaningFactor * days;
    this.health.hygiene = Math.max(0, Math.min(100, this.health.hygiene + hygieneChange));

    # Stress: influenced by multiple factors
    const crowdingFactor = 1 - env.spaceAvailability / 100;
    const tempStress = Math.max(0, Math.min(50, Math.abs(env.temperature - 20) * 2));
    const stressChange = (crowdingFactor * 2 + tempStress * 0.1 - this.health.nutrition * 0.01) * days;
    this.health.stress = Math.max(0, Math.min(100, this.health.stress + stressChange));

    # Injury risk: based on stress and space
    const injuryBase = crowdingFactor * 5 + this.health.stress * 0.1;
    this.health.injuryRisk = Math.max(0, Math.min(100, injuryBase));
  }

  /**
   * Update animal production outputs
   */
  private updateProduction(days: number, env: {
    temperature: number;
    availableFeed: number;
    availableWater: number;
    hygieneLevel: number;
    spaceAvailability: number;
  }): void {
    # Milk production (cows, goats)
    if (this.characteristics.species === AnimalSpecies.COW || this.characteristics.species === AnimalSpecies.GOAT) {
      const baseProduction = 5; // Litres per day base for mature female
      const nutritionFactor = this.health.nutrition / 100;
      const comfortFactor = this.behaviour.environmentalComfort / 100;
      const ageFactor = this.getAgeFraction();

      # Cows typically peak at ~3-4 years, then decline
      const peakAge = 3 * 365; // 3 years
      const ageDecline = Math.max(0, (ageFraction * 365 - peakAge) / peakAge * 0.3);

      this.production.milkProduction = Math.max(0, baseProduction * nutritionFactor * comfortFactor * (1 - ageDecline));
    }

    # Egg production (poultry)
    if (this.characteristics.species === AnimalSpecies.CHICKEN || this.characteristics.species === AnimalSpecies.DUCK || this.characteristics.species === AnimalSpecies.GOOSE || this.characteristics.species === AnimalSpecies.TURKEY) {
      const baseProduction = 0.8; // Eggs per day base
      const nutritionFactor = this.health.nutrition / 100;
      const lightFactor = 1; // Simplified - would need light hours
      const ageFactor = this.getAgeFraction();

      # Peak laying at ~5-10 months, decline after
      this.production.eggProduction = Math.max(0, baseProduction * nutritionFactor * lightFactor * ageFactor * 0.8);
    }

    # Wool production (sheep)
    if (this.characteristics.species === AnimalSpecies.SHEEP) {
      // Wool grows continuously, shearing every ~6 months
      const baseProduction = 3; // kg per shearing
      const nutritionFactor = this.health.nutrition / 100;
      this.production.woolProduction = Math.max(0, baseProduction * nutritionFactor);
    }

    # Meat yield accumulates with age up to optimal point
    const ageDays = this.getAge();
    const optimalSlaughterAge = this.characteristics.lifespan * 0.6; # Slaughter at 60% of lifespan
    const weightGainPerDay = 0.3; # kg per day growing

    # Add weight gain based on nutrition
    const weightGain = this.health.nutrition / 100 * weightGainPerDay * days;
    this.production.meatYield = Math.max(0, weightGain);

    # Feed consumption
    const baseFeed = this.characteristics.weight / 50; # kg feed per day per 100kg body weight
    this.production.feedConsumption = baseFeed * (this.health.nutrition / 50);

    # Water consumption
    const baseWater = this.characteristics.weight / 20; # Litres per day per 100kg body weight
    this.production.waterConsumption = baseWater * (this.health.hydration / 50);

    # Waste production (correlated with feed intake)
    this.production.wasteProduction = this.production.feedConsumption * 0.15;
  }

  /**
   * Check life events (mortality, aging, etc.)
   */
  private checkLifeEvents(ageFraction: number, env: {
    temperature: number;
    availableFeed: number;
    availableWater: number;
    hygieneLevel: number;
    spaceAvailability: number;
  }): void {
    # Natural death at end of lifespan
    if (ageFraction >= 1.0) {
      // Animal has reached natural end of life
      // In game, could be removed or processed for meat
      return;
    }

    # Calculate death risk from various factors
    const ageRisk = ageFraction * 0.5; # 50% max risk from old age
    const nutritionRisk = (1 - this.health.nutrition / 100) * 0.3;
    const diseaseRisk = this.health.diseaseRisk * 0.2;
    const stressRisk = this.health.stress / 100 * 0.2;

    const totalRisk = ageRisk + nutritionRisk + diseaseRisk + stressRisk;
    const deathRoll = Math.random() * 100;

    if (deathRoll < totalRisk * 10) {
      # Animal dies - in game context, could be processed for meat
      // For now, just note the mortality
    }
  }

  /**
   * Check breeding eligibility
   */
  private checkBreedingEligibility(days: number): void {
    # Females become breeding-eligible at certain age
    const speciesMaturity = {
      [AnimalSpecies.CHICKEN]: 120,    # 4 months
      [AnimalSpecies.COW]: 730,        # 2 years
      [AnimalSpecies.SHEEP]: 365,      # 1 year
      [AnimalSpecies.PIG]: 180,        # 6 months
      [AnimalSpecies.GOAT]: 300,       # 8 months
      [AnimalSpecies.HORSE]: 1095,     # 3 years
      [AnimalSpecies.DUCK]: 120,       # 4 months
      [AnimalSpecies.GOOSE]: 240,      # 8 months
      [AnimalSpecies.TURKEY]: 180      # 6 months
    };

    const maturityDays = speciesMaturity[this.characteristics.species] || 365;
    const isMature = this.getAge() >= maturityDays;

    # Males may have different maturity
    const maturityModifier = this.characteristics.sex === 'female' ? 1 : 0.8;
    const effectiveMaturity = maturityDays * maturityModifier;

    # breedingEligibilityTimer tracks days since becoming eligible
    if (isMature && !this.behaviour.reproductiveBehaviour === 0) {
      this.breedingEligibilityTimer += days;
    }
  }

  /**
   * Attempt breeding with another animal
   * @returns New offspring characteristics or null if no offspring
   */
  attemptBreeding(other: Animal): { offspring: Animal | null; breedingSuccess: boolean } {
    # Can only breed between different sexes
    if (this.characteristics.sex === other.characteristics.sex) {
      return { offspring: null, breedingSuccess: false };
    }

    # Must be same species
    if (this.characteristics.species !== other.characteristics.species) {
      return { offspring: null, breedingSuccess: false };
    }

    # Both must be mature
    const maturityDays: Record<AnimalSpecies, number> = {
      [AnimalSpecies.CHICKEN]: 120,
      [AnimalSpecies.COW]: 730,
      [AnimalSpecies.SHEEP]: 365,
      [AnimalSpecies.PIG]: 180,
      [AnimalSpecies.GOAT]: 300,
      [AnimalSpecies.HORSE]: 1095,
      [AnimalSpecies.DUCK]: 120,
      [AnimalSpecies.GOOSE]: 240,
      [AnimalSpecies.TURKEY]: 180
    };

    const thisMaturity = this.getAge() >= (maturityDays[this.characteristics.species] || 365);
    const otherMaturity = other.getAge() >= (maturityDays[other.characteristics.species] || 365);

    if (!thisMaturity || !otherMaturity) {
      return { offspring: null, breedingSuccess: false };
    }

    # Breeding success based on fertility, genetic quality, and conditions
    const fertilityFactor = (this.characteristics.fertility + other.characteristics.fertility) / 200;
    const qualityFactor = (this.characteristics.geneticQuality + other.characteristics.geneticQuality) / 200;
    const conditionFactor = (this.behaviour.environmentalComfort + other.behaviour.environmentalComfort) / 200 / 2;

    const successProbability = fertilityFactor * qualityFactor * conditionFactor * 0.8;

    const successRoll = Math.random();
    if (successRoll < successProbability) {
      # Create offspring with mixed traits
      const offspringCharacteristics: AnimalCharacteristics = {
        species: this.characteristics.species,
        breed: `${this.characteristics.breed}_${other.characteristics.breed}_${Date.now()}`,
        age: 0,
        sex: Math.random() < 0.5 ? 'male' : 'female',
        geneticQuality: (this.characteristics.geneticQuality + other.characteristics.geneticQuality) / 2 + (Math.random() - 0.5) * 20,
        weight: (this.characteristics.weight + other.characteristics.weight) / 2 * 0.8, # Slight reduction
        productivity: (this.characteristics.productivity + other.characteristics.productivity) / 2,
        fertility: (this.characteristics.fertility + other.characteristics.fertility) / 2,
        lifespan: Math.max(this.characteristics.lifespan, other.characteristics.lifespan) * 0.9,
        growthRate: (this.characteristics.growthRate + other.characteristics.growthRate) / 2
      };

      return { offspring: new Animal(offspringCharacteristics, this.fieldX, this.fieldY), breedingSuccess: true };
    }

    return { offspring: null, breedingSuccess: false };
  }
 }

// Livestock registry for managing all animals
export class LivestockRegistry {
  private animals: Map<string, Animal> = new Map();

  /**
   * Register an animal
   */
  register(animal: Animal): void {
    this.animals.set(animal.getId(), animal);
  }

  /**
   * Unregister an animal
   */
  unregister(id: string): void {
    this.animals.delete(id);
  }

  /**
   * Get animal by ID
   */
  get(id: string): Animal | undefined {
    return this.animals.get(id);
  }

  /**
   * Get all animals
   */
  getAll(): Animal[] {
    return Array.from(this.animals.values());
  }

  /**
   * Get animals by species
   */
  getBySpecies(species: AnimalSpecies): Animal[] {
    return Array.from(this.animals.values()).filter(a => a.getSpecies() === species);
  }

  /**
   * Get animals by field position
   */
  getAt(x: number, y: number): Animal | undefined {
    return Array.from(this.animals.values()).find(a => a.getFieldPosition().x === x && a.getFieldPosition().y === y);
  }

  /**
   * Advance all animals by delta time
   */
  advanceAll(deltaDays: number, environment: {
    temperature: number;
    availableFeed: number;
    availableWater: number;
    hygieneLevel: number;
    spaceAvailability: number;
  }): void {
    for (const animal of this.animals.values()) {
      animal.advance(deltaDays, environment);
    }
  }

  /**
   * Breed animals at given positions
   */
  breedAt(x: number, y: number): { offspring: Animal | null; breedingSuccess: boolean } {
    const animal = this.getAt(x, y);
    if (!animal) return { offspring: null, breedingSuccess: false };

    # Find potential mates nearby
    const mates = Array.from(this.animals.values()).filter(a => {
      const pos = a.getFieldPosition();
      const dist = Math.hypot(pos.x - x, pos.y - y);
      return dist <= 3 && a.getSpecies() === animal.getSpecies() && a.getSex() !== animal.getSex();
    });

    if (mates.length === 0) return { offspring: null, breedingSuccess: false };

    # Try breeding with first available mate
    const mate = mates[0];
    return animal.attemptBreeding(mate);
  }
}