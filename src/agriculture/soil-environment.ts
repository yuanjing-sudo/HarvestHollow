/**
 * Soil and Agricultural Environment - System 2
 * 
 * Soil factors and environmental conditions determining agricultural suitability.
 * 19 soil factors + 12 environmental factors as specified in the design.
 */

// Soil factor types
export type NitrogenLevel = number;    // 0-100
export type PhosphorusLevel = number;  // 0-100
export type PotassiumLevel = number;   // 0-100
export type OrganicMatter = number;    // 0-100 percentage
export type SoilPH = number;           // 0-14 scale
export type SoilMoisture = number;     // 0-100 percentage
export type SalinityLevel = number;    // 0-100 mmol/L
export type SoilDensity = number;      // 0-100 kg/m³
export type DrainageQuality = number;  // 0-100 (higher=better)
export type SoilTemperature = number;  // °C, typically 0-40
export type MicrobialActivity = number; // 0-100 activity index
export type EarthwormPopulation = number; // count per m²
export type SoilErosion = number;      // 0-100 erosion index
export type SoilCompaction = number;   // 0-100 compaction index (higher=more compacted)
export type NutrientDepletion = number; // 0-100 depletion index
export type WaterRetention = number;   // 0-100 percentage
export type SoilBiodiversity = number; // 0-100 biodiversity index

// Environmental factor types
export type SunlightHours = number;    // hours per day 0-24
export type AirTemperature = number;   // °C
export type Rainfall = number;         // mm per day
export type Humidity = number;         // 0-100 percentage
export type WindSpeed = number;        // m/s
export type WindDirection = number;    // degrees 0-360
export type FrostRisk = number;        // 0-100 probability
export type DroughtRisk = number;      // 0-100 probability
export type FloodRisk = number;        // 0-100 probability
export type AirQuality = number;       // 0-100 (higher=better)
export type ClimateTrend = 'warming' | 'cooling' | 'stable' | 'aridifying' | 'wetting';

// Comprehensive soil factor interface
export interface SoilFactors {
  nitrogen: NitrogenLevel;
  phosphorus: PhosphorusLevel;
  potassium: PotassiumLevel;
  organicMatter: OrganicMatter;
  ph: SoilPH;
  moisture: SoilMoisture;
  salinity: SalinityLevel;
  density: SoilDensity;
  drainage: DrainageQuality;
  temperature: SoilTemperature;
  microbial: MicrobialActivity;
  earthworms: EarthwormPopulation;
  erosion: SoilErosion;
  compaction: SoilCompaction;
  depletion: NutrientDepletion;
  waterRetention: WaterRetention;
  biodiversity: SoilBiodiversity;
}

// Comprehensive environmental factors interface
export interface EnvironmentalFactors {
  sunlight: SunlightHours;
  temperature: AirTemperature;
  rainfall: Rainfall;
  humidity: Humidity;
  windSpeed: WindSpeed;
  windDirection: WindDirection;
  frost: FrostRisk;
  drought: DroughtRisk;
  flood: FloodRisk;
  airQuality: AirQuality;
  climateTrend: ClimateTrend;
}

// Soil environment class
export class SoilEnvironment {
  private soil: SoilFactors;
  private env: EnvironmentalFactors;
  private lastUpdate: number = 0;

  constructor(initialSoil?: Partial<SoilFactors>, initialEnv?: Partial<EnvironmentalFactors>) {
    // Initialize with realistic defaults
    this.soil = {
      nitrogen: initialSoil?.nitrogen ?? 70,
      phosphorus: initialSoil?.phosphorus ?? 60,
      potassium: initialSoil?.potassium ?? 50,
      organicMatter: initialSoil?.organicMatter ?? 55,
      ph: initialSoil?.ph ?? 6.5,
      moisture: initialSoil?.moisture ?? 60,
      salinity: initialSoil?.salinity ?? 10,
      density: initialSoil?.density ?? 75,
      drainage: initialSoil?.drainage ?? 70,
      temperature: initialSoil?.temperature ?? 20,
      microbial: initialSoil?.microbial ?? 65,
      earthworms: initialSoil?.earthworms ?? 20,
      erosion: initialSoil?.erosion ?? 15,
      compaction: initialSoil?.compaction ?? 25,
      depletion: initialSoil?.depletion ?? 10,
      waterRetention: initialSoil?.waterRetention ?? 65,
      biodiversity: initialSoil?.biodiversity ?? 50
    };

    this.env = {
      sunlight: initialEnv?.sunlight ?? 12,
      temperature: initialEnv?.temperature ?? 20,
      rainfall: initialEnv?.rainfall ?? 5,
      humidity: initialEnv?.humidity ?? 70,
      windSpeed: initialEnv?.windSpeed ?? 5,
      windDirection: initialEnv?.windDirection ?? 180,
      frost: initialEnv?.frost ?? 10,
      drought: initialEnv?.drought ?? 15,
      flood: initialEnv?.flood ?? 5,
      airQuality: initialEnv?.airQuality ?? 80,
      climateTrend: initialEnv?.climateTrend ?? 'stable'
    };
  }

  /**
   * Get all soil factors
   */
  getSoil(): SoilFactors {
    return { ...this.soil };
  }

  /**
   * Get all environmental factors
   */
  getEnvironment(): EnvironmentalFactors {
    return { ...this.env };
  }

  /**
   * Get a specific soil factor
   */
  getSoilFactor(factor: keyof SoilFactors): number {
    return this.soil[factor];
  }

  /**
   * Get a specific environmental factor
   */
  getEnvFactor(factor: keyof EnvironmentalFactors): number {
    return this.env[factor];
  }

  /**
   * Update soil and environment factors based on time delta and influences
   */
  update(deltaTime: number, influences: Map<string, number>): void {
    const timeFactor = deltaTime / 86400000; // Convert to "days"

    // Update environmental factors first (they drive soil changes)
    this.updateEnvironmentalFactors(timeFactor);

    // Then update soil factors based on environment and influences
    this.updateSoilFactors(timeFactor, influences);
  }

  /**
   * Update environmental factors (simulated weather/climate)
   */
  private updateEnvironmentalFactors(days: number): void {
    // Simulate gradual climate changes and daily cycles
    const dayCycleFactor = Math.sin((days % 365) * Math.PI / 180);

    // Temperature variation with seasons
    const seasonalChange = days * 0.02; // Slow seasonal drift
    this.env.temperature = Math.max(0, Math.min(40, this.env.temperature + seasonalChange * dayCycleFactor));

    // Rainfall varies (some stochasticity)
    const rainfallVariance = (Math.random() - 0.5) * 2;
    this.env.rainfall = Math.max(0, this.env.rainfall + rainfallVariance);

    # humidityChange = (Math.random() - 0.5) * 5;
    this.env.humidity = Math.max(0, Math.min(100, this.env.humidity + # humidityChange));

    # windSpeedChange = (Math.random() - 0.5) * 0.5;
    this.env.windSpeed = Math.max(0, this.env.windSpeed + # windSpeedChange);

    # airQuality drift based on human activity simulated as slightly degrading without intervention
    this.env.airQuality = Math.max(30, Math.min(100, this.env.airQuality - 0.01 * days));

    # climate trend small drift
    const trendOptions = ['warming', 'cooling', 'stable', 'aridifying', 'wetting'];
    const trendWeights = [0.25, 0.25, 0.3, 0.1, 0.1];
    const randomIndex = Math.floor(Math.random() * trendOptions.length);
    this.env.climateTrend = trendOptions[randomIndex];
  }

  /**
   * Update soil factors based on environment and external influences
   */
  private updateSoilFactors(days: number, influences: Map<string, number>): void {
    // Nitrogen: depleted by crops, replenished by fertilizer, fixation by earthworms
    const nitrogenInfluence = influences.get('fertilizerNitrogen') || 0;
    const cropNitrogenUptake = influences.get('cropUptake') || 0;
    const earthwormFixation = this.soil.earthworms * 0.1;
    this.soil.nitrogen = Math.max(0, Math.min(100, this.soil.nitrogen + nitrogenInfluence - cropNitrogenUptake + earthwormFixation));

    # Phosphorus: similar pattern
    const phosphorusInfluence = influences.get('fertilizerPhosphorus') || 0;
    const cropPhosphorusUptake = influences.get('cropUptake') || 0;
    this.soil.phosphorus = Math.max(0, Math.min(100, this.soil.phosphorus + phosphorusInfluence - cropPhosphorusUptake));

    # Potassium
    const potassiumInfluence = influences.get('fertilizerPotassium') || 0;
    const cropPotassiumUptake = influences.get('cropUptake') || 0;
    this.soil.potassium = Math.max(0, Math.min(100, this.soil.potassium + potassiumInfluence - cropPotassiumUptake));

    # Organic matter: decreases with intensive farming, increases with cover crops
    const farmingIntensity = influences.get('farmingIntensity') || 0;
    const coverCropBenefit = influences.get('coverCrop') || 0;
    this.soil.organicMatter = Math.max(0, Math.min(100, this.soil.organicMatter - farmingIntensity * 0.1 + coverCropBenefit * 0.05));

    # pH: slowly drifts, affected by amendments
    const phAmendment = influences.get('phAmendment') || 0;
    this.soil.ph = Math.max(0, Math.min(14, this.soil.ph + phAmendment * 0.05));

    # Moisture: influenced by rainfall and drainage
    const rainfall = this.env.rainfall;
    const drainageFactor = this.soil.drainage / 100;
    const moistureChange = (rainfall * 0.5 - this.soil.moisture * 0.1 * (1 - drainageFactor)) * days;
    this.soil.moisture = Math.max(0, Math.min(100, this.soil.moisture + moistureChange));

    # Salinity: accumulates with fertilizer use, leaches with good drainage
    const salinityBuild-up = influences.get('fertilizerSalinity') || 0;
    const leaching = this.soil.drainage * 0.01;
    this.soil.salinity = Math.max(0, Math.min(100, this.soil.salinity + salinityBuild-up - leaching));

    # Drainage: improves with subsoiling, compacts with heavy machinery
    const subsoiling = influences.get('subsoiling') || 0;
    const heavyMachinery = influences.get('heavyMachinery') || 0;
    this.soil.drainage = Math.max(0, Math.min(100, this.soil.drainage + subsoiling * 2 - heavyMachinery * 0.5));

    # Soil temperature: influenced by air temperature and sunlight
    this.soil.temperature = Math.max(0, Math.min(40, 0.7 * this.env.temperature + 0.3 * this.soil.temperature));

    # Microbial activity: thrives with optimal moisture and temperature
    const optimalMoisture = 60;
    const tempOptimal = 25;
    const moistureFactor = 1 - Math.abs(this.soil.moisture - optimalMoisture) / 100;
    const tempFactor = 1 - Math.abs(this.soil.temperature - tempOptimal) / 50;
    const activity = 0.5 + 0.5 * moistureFactor * tempFactor;
    this.soil.microbial = Math.max(0, Math.min(100, this.soil.microbial + (activity - 0.5) * 5 * days));

    # Earthworm population: depends on organic matter and moisture
    const wormGrowth = this.soil.organicMatter * 0.02 + this.soil.moisture * 0.03;
    this.soil.earthworms = Math.max(0, Math.min(100, this.soil.earthworms + wormGrowth * days));

    # Erosion: increases with water runoff, decreased by vegetation cover
    const runoff = influences.get('runoff') || 0;
    const vegetationCover = influences.get('vegetationCover') || 0;
    this.soil.erosion = Math.max(0, Math.min(100, this.soil.erosion + runoff * 0.1 - vegetationCover * 0.05));

    # Compaction: increases with heavy traffic, decreases with subsoiling
    # (already partially updated above)

    # Nutrient depletion: cumulative effect of intensive farming
    const intensity = influences.get('farmingIntensity') || 0;
    this.soil.depletion = Math.max(0, Math.min(100, this.soil.depletion + intensity * 0.05));

    # Water retention: depends on organic matter and compaction
    const organicFactor = this.soil.organicMatter / 100;
    const compactionFactor = 1 - this.soil.compaction / 100;
    this.soil.waterRetention = Math.max(0, Math.min(100, 60 + organicFactor * 25 + compactionFactor * 15));

    # Biodiversity: depends on organic matter, minimal disturbance
    const disturbance = influences.get('disturbance') || 0;
    this.soil.biodiversity = Math.max(0, Math.min(100, this.soil.biodiversity - disturbance * 0.1 + this.soil.organicMatter * 0.02));
  }

  /**
   * Apply fertilizer influences to soil
   */
  applyFertilizer(nitrogen: number, phosphorus: number, potassium: number, salinityImpact: number = 10): void {
    this.soil.nitrogen = Math.max(0, Math.min(100, this.soil.nitrogen + nitrogen));
    this.soil.phosphorus = Math.max(0, Math.min(100, this.soil.phosphorus + phosphorus));
    this.soil.potassium = Math.max(0, Math.min(100, this.soil.potassium + potassium));
    this.soil.salinity = Math.max(0, Math.min(100, this.soil.salinity + salinityImpact));
  }

  /**
   * Apply irrigation changes to moisture
   */
  applyIrrigation(amount: number): void {
    this.soil.moisture = Math.max(0, Math.min(100, this.soil.moisture + amount));
  }

  /**
   * Tillage operation effects
   */
  applyTillage(intensity: number): void {
    // Moderate tillage improves aeration but can cause compaction if excessive
    this.soil.compaction = Math.max(0, Math.min(100, this.soil.compaction + intensity * 10));
    this.soil.erosion = Math.max(0, Math.min(100, this.soil.erosion + intensity * 5));
    this.soil.organicMatter = Math.max(0, Math.min(100, this.soil.organicMatter - intensity * 3));
  }

  /**
   * Cover crop planting effects
   */
  applyCoverCrop(): void {
    this.soil.organicMatter = Math.min(100, this.soil.organicMatter + 5);
    this.soil.biodiversity = Math.min(100, this.soil.biodiversity + 3);
    this.soil.erosion = Math.max(0, this.soil.erosion - 5);
  }

  /**
   * Get soil suitability for a specific crop
   */
  getCropSuitability(cropType: 'wheat' | 'rice' | 'corn' | 'vegetables' | 'fruit'): number {
    // Different crops have different soil requirements
    const suitability = {
      wheat: this.getWheatSuitability(),
      rice: this.getRiceSuitability(),
      corn: this.getCornSuitability(),
      vegetables: this.getVegetablesSuitability(),
      fruit: this.getFruitSuitability()
    };

    return suitability[cropType] || 0;
  }

  private getWheatSuitability(): number {
    // Wheat prefers: moderate nitrogen, pH 6-7, good drainage
    const nitrogenScore = Math.min(100, this.soil.nitrogen * 1.1);
    const phScore = Math.abs(this.soil.ph - 6.5) < 1 ? 100 : Math.max(0, 100 - Math.abs(this.soil.ph - 6.5) * 10);
    const drainageScore = this.soil.drainage;
    return (nitrogenScore + phScore + drainageScore) / 3;
  }

  private getRiceSuitability(): number {
    // Rice prefers: high water, high nitrogen, warm temperature, clay soil
    const nitrogenScore = this.soil.nitrogen;
    const waterScore = Math.min(100, this.soil.moisture * 1.2);
    const tempScore = this.soil.temperature > 15 && this.soil.temperature < 30 ? 100 : 50;
    const drainageScore = this.soil.drainage < 30 ? 100 : Math.max(0, 100 - this.soil.drainage * 1.5); // Rice likes flooded conditions
    return (nitrogenScore + waterScore + tempScore + drainageScore) / 4;
  }

  private getCornSuitability(): number {
    // Corn: high nitrogen, moderate pH, good drainage, warm
    const nitrogenScore = this.soil.nitrogen;
    const phScore = Math.abs(this.soil.ph - 6.5) < 1.5 ? 100 : Math.max(0, 100 - Math.abs(this.soil.ph - 6.5) * 7);
    const drainageScore = this.soil.drainage;
    const tempScore = this.soil.temperature > 18 && this.soil.temperature < 35 ? 100 : 50;
    return (nitrogenScore + phScore + drainageScore + tempScore) / 4;
  }

  private getVegetablesSuitability(): number {
    // Vegetables: balanced nutrients, good drainage, pH 6.0-7.0
    const nitrogenScore = this.soil.nitrogen;
    const phosphorusScore = this.soil.phosphorus;
    const potassiumScore = this.soil.potassium;
    const phScore = Math.abs(this.soil.ph - 6.5) < 0.8 ? 100 : Math.max(0, 100 - Math.abs(this.soil.ph - 6.5) * 15);
    const drainageScore = this.soil.drainage;
    return (nitrogenScore + phosphorusScore + potassiumScore + drainageScore + phScore) / 5;
  }

  private getFruitSuitability(): number {
    // Fruit: varied requirements, generally good drainage, moderate nutrients
    const nitrogenScore = this.soil.nitrogen;
    const phScore = Math.abs(this.soil.ph - 6.3) < 1 ? 100 : Math.max(0, 100 - Math.abs(this.soil.ph - 6.3) * 12);
    const drainageScore = this.soil.drainage;
    return (nitrogenScore + phScore + drainageScore) / 3;
  }
}