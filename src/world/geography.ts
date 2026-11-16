/**
 * Geography and World Generation - System 1, Layer 2
 * 
 * Physical environment generation and terrain properties.
 * Influences agriculture, transport, construction and property prices.
 */

// Terrain property types
export type Elevation = number;  // 0-100 scale, 0=sea level, 100=mountain peak
export type Slope = number;      // Percentage (0-100)
export type Fertility = number;  // 0-100 soil fertility index

// Terrain cell properties
export interface TerrainCell {
  /** X coordinate in the world grid */
  x: number;
  /** Y coordinate in the world grid */
  y: number;
  /** Elevation height */
  elevation: Elevation;
  /** Slope steepness */
  slope: Slope;
  /** Soil depth percentage */
  soilDepth: number;
  /** Soil composition type (0-100) */
  soilComposition: number;
  /** Terrain stability (0-1, higher=more stable) */
  stability: number;
  /** Flood susceptibility (0-1, higher=more prone) */
  floodSusceptibility: number;
  /** Erosion susceptibility (0-1, higher=more erodible) */
  erosionSusceptibility: number;
  /** Land fertility index */
  fertility: Fertility;
  /** Whether this is valid farmland */
  isFarmland: boolean;
  /** Land ownership status */
  ownership: 'none' | 'player' | 'ai' | 'government';
  /** Land price per unit */
  price: number;
  /** Rental cost per period */
  rentalCost: number;
}

// World generation parameters
export interface WorldGenerationParams {
  /** Map width in cells */
  width: number;
  /** Map height in cells */
  height: number;
  /** Random seed for deterministic generation */
  seed: number;
  /** Size of generated towns */
  townSize: 'small' | 'medium' | 'large';
  /** Number of resource deposits */
  resourceDeposits: number;
  /** Climate zone type */
  climateZone: 'tropical' | 'temperate' | 'continental' | 'arid' | 'polar';
  /** Water coverage percentage (0-100) */
  waterCoverage: number;
}

// World geography data structure
export class WorldGeography {
  private terrain: TerrainCell[][];
  private width: number;
  private height: number;
  private generationParams: WorldGenerationParams;

  constructor(params: WorldGenerationParams) {
    this.width = params.width;
    this.height = params.height;
    this.generationParams = params;
    this.terrain = this.generateWorld();
  }

  /**
   * Generate the complete world terrain
   */
  private generateWorld(): TerrainCell[][] {
    const terrain: TerrainCell[][] = [];

    // Initialize with base values based on climate and water
    for (let y = 0; y < this.height; y++) {
      terrain[y] = [];
      for (let x = 0; x < this.width; x++) {
        terrain[y][x] = this.generateTerrainCell(x, y);
      }
    }

    // Post-process: place towns and resources
    this.placeTownsAndResources(terrain);

    return terrain;
  }

  /**
   * Generate a single terrain cell with procedural values
   */
  private generateTerrainCell(x: number, y: number): TerrainCell {
    const seedBase = this.generationParams.seed + x * 1000 + y * 100;

    // Base elevation using perlin-like noise (simplified)
    const elevation = this.noise2D(seedBase + 100, seedBase + 200) * 50 + 20;

    // Slope derived from elevation change
    const slope = Math.abs(this.noise2D(seedBase + 300, seedBase + 400)) * 30;

    // Soil depth inversely related to elevation (mountains have shallow soil)
    const soilDepth = Math.max(0, 80 - elevation * 0.6 + this.noise2D(seedBase + 500, seedBase + 600) * 20);

    // Soil composition (0-100, organic vs mineral)
    const soilComposition = this.noise2D(seedBase + 700, seedBase + 800) * 100;

    // Stability: higher ground less stable, flat more stable
    const stability = Math.max(0, 100 - Math.abs(elevation - 50) * 1.5 + this.noise2D(seedBase + 900, seedBase + 1000) * 20);

    // Flood susceptibility: low-lying areas
    const floodSusceptibility = elevation < 30 ? 80 + (30 - elevation) * 2 : this.noise2D(seedBase + 1100, seedBase + 1200) * 30;

    // Erosion susceptibility: moderate slopes, unconsolidated soil
    const erosionSusceptibility = (slope > 10 && slope < 40 && soilDepth < 50) ? 60 : this.noise2D(seedBase + 1300, seedBase + 1400) * 40;

    // Fertility: moderate elevations with good soil and water access
    const baseFertility = 30 + (elevation < 50 ? (50 - elevation) * 1.2 : 0) + (soilDepth > 40 ? 20 : 0);
    const fertility = Math.min(100, baseFertility + this.noise2D(seedBase + 1500, seedBase + 1600) * 20);

    // Farmland: areas with good fertility, moderate slope, adequate soil depth
    const isFarmland = fertility > 40 && slope < 30 && soilDepth > 20;

    // Ownership starts as none
    const ownership: 'none' | 'player' | 'ai' | 'government' = 'none';

    // Initial price based on fertility and accessibility
    const price = Math.max(1, Math.round(fertility * 2 + soilDepth * 3 - slope * 2 + this.noise2D(seedBase + 1700, seedBase + 1800) * 10));

    const rentalCost = Math.max(1, Math.round(price * 0.05));

    return {
      x,
      y,
      elevation: Math.max(0, Math.min(100, elevation)),
      slope: Math.max(0, Math.min(100, slope)),
      soilDepth: Math.max(0, Math.min(100, soilDepth)),
      soilComposition: Math.max(0, Math.min(100, soilComposition)),
      stability: Math.max(0, Math.min(100, stability)),
      floodSusceptibility: Math.max(0, Math.min(100, floodSusceptibility)),
      erosionSusceptibility: Math.max(0, Math.min(100, erosionSusceptibility)),
      fertility: Math.max(0, Math.min(100, fertility)),
      isFarmland,
      ownership,
      price,
      rentalCost
    };
  }

  /**
   * Simple 2D noise function for procedural generation
   */
  private noise2D(x: number, y: number): number {
    // Simple hash-based noise for deterministic generation
    const n = x + y * 127;
    n = (n << 13) ^ n;
    return (1.0 - ((n * (n * n * 15731 + 789221) + 1376312589) & 0x10000000) / 1073741824);
  }

  /**
   * Place towns and resource deposits on the generated world
   */
  private placeTownsAndResources(terrain: TerrainCell[][]): void {
    const { townSize, resourceDeposits, climateZone } = this.generationParams;

    // Place towns in suitable locations (moderate fertility, good accessibility)
    const townCount = townSize === 'small' ? 3 : townSize === 'medium' ? 5 : 8;
    const placedTowns: { x: number; y: number; size: string }[] = [];

    for (let i = 0; i < townCount; i++) {
      // Find suitable location
      let attempts = 0;
      let found = false;
      let targetX = 0,
        targetY = 0;

      while (attempts < 100 && !found) {
        const x = Math.floor(Math.random() * this.width);
        const y = Math.floor(Math.random() * this.height);
        const cell = terrain[y][x];

        // Towns need good fertility and not too flood-prone
        if (cell.fertility > 50 && cell.floodSusceptibility < 40 && !placedTowns.some(t => Math.abs(t.x - x) < 10 && Math.abs(t.y - y) < 10)) {
          targetX = x;
          targetY = y;
          found = true;
        }
        attempts++;
      }

      // Add town influence area
      if (found) {
        placedTowns.push({ x: targetX, y: targetY, size: townSize });

        // Influence area: improve fertility and lower prices around town
        const influenceRadius = townSize === 'small' ? 5 : townSize === 'medium' ? 8 : 12;
        for (let ry = -influenceRadius; ry <= influenceRadius; ry++) {
          for (let rx = -influenceRadius; rx <= influenceRadius; rx++) {
            const nx = targetX + rx;
            const ny = targetY + ry;
            if (nx >= 0 && nx < this.width && ny >= 0 && ny < this.height) {
              const cell = terrain[ny][nx];
              // Slight fertility boost near towns
              cell.fertility = Math.min(100, cell.fertility + 5);
              // Slight price increase
              cell.price = Math.round(cell.price * 1.1);
            }
          }
        }
      }
    }

    // Place resource deposits
    for (let i = 0; i < resourceDeposits; i++) {
      let attempts = 0;
      let found = false;
      let targetX = 0,
        targetY = 0;

      while (attempts < 100 && !found) {
        const x = Math.floor(Math.random() * this.width);
        const y = Math.floor(Math.random() * this.height);
        const cell = terrain[y][x];

        // Resources prefer specific conditions based on climate
        const isSuitable = climateZone === 'tropical'
          ? cell.fertility > 60 && cell.elevation < 60
          : climateZone === 'temperate'
            ? cell.fertility > 40 && cell.elevation < 80
            : cell.fertility > 30;

        if (isSuitable && !terrain.some(row => row.some(c => c.x === x && c.y === y))) {
          targetX = x;
          targetY = y;
          found = true;
        }
        attempts++;
      }

      if (found) {
        // Add resource deposit to cell
        terrain[targetY][targetX].soilComposition = terrain[targetY][targetX].soilComposition === 0
          ? 100 // Mark as resource area
          : terrain[targetY][targetX].soilComposition; // Keep existing

        // Boost fertility slightly for resource areas
        terrain[targetY][targetX].fertility = Math.min(100, terrain[targetY][targetX].fertility + 10);
      }
    }
  }

  /**
   * Get the terrain cell at world coordinates
   */
  getCell(x: number, y: number): TerrainCell | undefined {
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return undefined;
    return this.terrain[y][x];
  }

  /**
   * Get terrain cell by index
   */
  getCellIndex(x: number, y: number): TerrainCell | undefined {
    return this.getCell(x, y);
  }

  /**
   * Get world width
   */
  getWidth(): number {
    return this.width;
  }

  /**
   * Get world height
   */
  getHeight(): number {
    return this.height;
  }

  /**
   * Get all terrain cells
   */
  getAllCells(): TerrainCell[][] {
    return this.terrain;
  }

  /**
   * Get terrain statistics summary
   */
  getStatistics(): {
    avgFertility: number;
    avgElevation: number;
    farmlandPercentage: number;
    townCount: number;
    resourceCount: number;
  } {
    let totalFertility = 0;
    let totalElevation = 0;
    let farmlandCount = 0;

    for (const row of this.terrain) {
      for (const cell of row) {
        totalFertility += cell.fertility;
        totalElevation += cell.elevation;
        if (cell.isFarmland) farmlandCount++;
      }
    }

    const cellCount = this.width * this.height;

    return {
      avgFertility: totalFertility / cellCount,
      avgElevation: totalElevation / cellCount,
      farmlandPercentage: (farmlandCount / cellCount) * 100,
      townCount: this.countTowns(),
      resourceCount: this.countResources()
    };
  }

  private countTowns(): number {
    // Count unique town influence areas
    const centers = new Set<string>();
    for (const row of this.terrain) {
      for (const cell of row) {
        // Town centers identified by slightly elevated price and fertility
        if (cell.fertility > 70 && cell.price > 200) {
          centers.add(`${cell.x},${cell.y}`);
        }
      }
    }
    return centers.size;
  }

  private countResources(): number {
    let count = 0;
    for (const row of this.terrain) {
      for (const cell of row) {
        if (cell.soilComposition > 80) count++; // High soil composition = resource marker
      }
    }
    return count;
  }
}