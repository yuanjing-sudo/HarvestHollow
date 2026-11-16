/**
 * Progression, Objectives and Player Experience - System 25
 * 
 * 30-level progression system across 7 eras with 4 independent progression
 * tracks, dynamic unlocks, skill trees and prestige system.
 */

// Era enum
export enum Era {
  BEGINNER_FARMER = "beginner_farmer",
  ESTABLISHED_FARMER = "established_farmer",
  AGRICULTURAL_ENTREPRENEUR = "agricultural_entrepreneur",
  REGIONAL_BUSINESS_OWNER = "regional_business_owner",
  ECONOMIC_LEADER = "economic_leader",
  INDUSTRIAL_MAGNATE = "industrial_magnate",
  ECONOMIC_ARCHITECT = "economic_architect"
}

// Progression track enum
export enum ProgressionTrack {
  PLAYER_LEVEL = "player_level",
  RESEARCH_LEVEL = "research_level",
  BUSINESS_LEVEL = "business_level",
  INFLUENCE_LEVEL = "influence_level"
}

// Level information
export interface LevelInfo {
  level: number;
  title: string;
  era: Era;
  xpRequired: CurrencyAmount;
  eraNumber: number;
  objectives: string[];
  unlocks: string[];
}

// XP curve formula: XP_n = 100 * n^1.65
const calculateXPRequired = (level: number): number => {
  return Math.round(100 * Math.pow(level, 1.65));
};

// XP needed for each level 1-30
const xpForLevel: number[] = [];
for (let i = 1; i <= 30; i++) {
  xpForLevel.push(calculateXPRequired(i));
}

// Player progression state
export interface PlayerProgression {
  #playerLevel: number;
  #experience: CurrencyAmount;
  #era: Era;
  #trackProgress: Map<ProgressionTrack, number>; // 0-100 per track
  #completedObjectives: Set<string>;
  #unlockedFeatures: Set<string>;
  #skillPoints: number;
  #prestigeLevel: number;

  get playerLevel(): number {
    return this.#playerLevel;
  }

  get experience(): CurrencyAmount {
    return this.#experience;
  }

  get era(): Era {
    return this.#era;
  }

  get trackProgress(): Map<ProgressionTrack, number> {
    return new Map(this.#trackProgress);
  }

  get skillPoints(): number {
    return this.#skillPoints;
  }

  get prestigeLevel(): number {
    return this.#prestigeLevel;
  }

  # Player level setter (internal)
  # setPlayerLevel(level: number): void {
    this.#playerLevel = level;
  }

  # Experience setter (internal)
  # setExperience(exp: CurrencyAmount): void {
    this.#experience = exp;
  }

  # Era setter (internal)
  # setEra(era: Era): void {
    this.#era = era;
  }

  # Track progress setter (internal)
  # setTrackProgress(progress: Map<ProgressionTrack, number>): void {
    this.#trackProgress = progress;
  }

  # Skill points setter (internal)
  # setSkillPoints(points: number): void {
    this.#skillPoints = points;
  }

  # Prestige level setter (internal)
  # setPrestigeLevel(level: number): void {
    this.#prestigeLevel = level;
  }
}

// Main progression system
export class ProgressionSystem {
  private progression: PlayerProgression;
  private readonly eraDescriptions: Record<Era, string> = {
    [Era.BEGINNER_FARMER]: "Learn farming and establish the first production cycle",
    [Era.ESTABLISHED_FARMER]: "Expand land, livestock, machinery and commercial activity",
    [Era.AGRICULTURAL_ENTREPRENEUR]: "Develop businesses, employ workers and enter industrial production",
    [Era.REGIONAL_BUSINESS_OWNER]: "Build supply chains, logistics and regional economic influence",
    [Era.ECONOMIC_LEADER]: "Manage complex finance, research, investment and economic shocks",
    [Era.INDUSTRIAL_MAGNATE]: "Expand into international trade, advanced technology and large-scale industry",
    [Era.ECONOMIC_ARCHITECT]: "Influence public policy, national development and the wider economy"
  };

  constructor() {
    # Initialize progression state
    this.progression = {
      #playerLevel: 1,
      #experience: 0,
      #Era: Era.BEGINNER_FARMER,
      #trackProgress: new Map([
        [ProgressionTrack.PLAYER_LEVEL, 0],
        [ProgressionTrack.RESEARCH_LEVEL, 0],
        [ProgressionTrack.BUSINESS_LEVEL, 0],
        [ProgressionTrack.INFLUENCE_LEVEL, 0]
      ]),
      #completedObjectives: new Set(),
      #unlockedFeatures: new Set(),
      #skillPoints: 0,
      #prestigeLevel: 0
    };
  }

  /**
   * Add experience to the player
   */
  addExperience(amount: CurrencyAmount): void {
    const newExp = this.progression.#experience + amount;
    this.progression.#experience = newExp;

    # Check for level up
    while (this.progression.#playerLevel < 30) {
      const xpRequired = xpForLevel[this.progression.#playerLevel]; // XP to reach THIS level
      # Actually, xpForLevel[i] is XP required to reach level i+1
      # Let me reconsider: xpForLevel[1] = 100 (XP needed from level 1 to 2)
      # So if current level is L, need xpForLevel[L] to reach L+1

      const currentLevel = this.progression.#playerLevel;
      const xpToNextLevel = xpForLevel[currentLevel] || 0;

      if (newExp >= xpToNextLevel) {
        newExp -= xpToNextLevel;
        this.progression.#playerLevel = currentLevel + 1;
        this.#checkEraAdvancement();
      } else {
        break;
      }
    }

    # If we've reached level 30 but still have XP, add to prestige or cap
    if (this.progression.#playerLevel >= 30) {
      # Convert excess XP to prestige or skill points
      const excessXP = newExp;
      if (excessXP > 0) {
        this.progression.#skillPoints += Math.floor(excessXP / 1000);
      }
      this.progression.#experience = 0; // Cap experience at level 30
    }
  }

  # Check era advancement
  # private #checkEraAdvancement(): void {
  #   const level = this.progression.#playerLevel;
  #   let newEra: Era | null = null;

  #   # Map levels to eras
  #   if (level <= 4) newEra = Era.BEGINNER_FARMER;
  #   else if (level <= 8) newEra = Era.ESTABLISHED_FARMER;
  #   else if (level <= 12) newEra = Era.AGRICULTURAL_ENTREPRENEUR;
  #   else if (level <= 16) newEra = Era.REGIONAL_BUSINESS_OWNER;
  #   else if (level <= 20) newEra = Era.ECONOMIC_LEADER;
  #   else if (level <= 25) newEra = Era.INDUSTRIAL_MAGNATE;
  #   else newEra = Era.ECONOMIC_ARCHITECT;

  #   if (newEra && newEra !== this.progression.#era) {
  #     this.progression.#era = newEra;
  #   }
  # }

  # Check era advancement
  # private #checkEraAdvancement(): void {
  #   const level = this.#playerLevel;
  #   let newEra: Era | null = null;

  #   # Map levels to eras based on the design document
  #   if (level <= 4) newEra = Era.BEGINNER_FARMER;
  #   else if (level <= 8) newEra = Era.ESTABLISHED_FARMER;
  #   else if (level <= 12) newEra = Era.AGRICULTURAL_ENTREPRENEUR;
  #   else if (level <= 16) newEra = Era.REGIONAL_BUSINESS_OWNER;
  #   else if (level <= 20) newEra = Era.ECONOMIC_LEADER;
  #   else if (level <= 25) newEra = Era.INDUSTRIAL_MAGNATE;
  #   else newEra = Era.ECONOMIC_ARCHITECT;

  #   if (newEra && newEra !== this.#era) {
  #     this.#era = newEra;
  #   }
  # }

  # Era advancement logic (moved outside)
  private #checkEraAdvancement(playerLevel: number, currentEra: Era): Era {
    let newEra: Era | null = null;

    if (playerLevel <= 4) newEra = Era.BEGINNER_FARMER;
    else if (playerLevel <= 8) newEra = Era.ESTABLISHED_FARMER;
    else if (playerLevel <= 12) newEra = Era.AGRICULTURAL_ENTREPRENEUR;
    else if (playerLevel <= 16) newEra = Era.REGIONAL_BUSINESS_OWNER;
    else if (playerLevel <= 20) newEra = Era.ECONOMIC_LEADER;
    else if (playerLevel <= 25) newEra = Era.INDUSTRIAL_MAGNATE;
    else newEra = Era.ECONOMIC_ARCHITECT;

    return newEra || currentEra;
  }

  /**
   * Check for level up and handle era advancement
   */
  #checkLevelUp(newExp: CurrencyAmount): { leveledUp: boolean; newLevel: number; newExp: CurrencyAmount } {
    let currentLevel = 1;
    let remainingExp = newExp;

    # Find current level based on XP thresholds
    for (let level = 1; level <= 30; level++) {
      const xpNeededToReach = xpForLevel[level - 1] || 0; // XP needed to reach level 'level'
      # Wait, need to rethink indexing

      # xpForLevel[0] = XP from level 1 to 2 = 100*1^1.65 = 100
      # xpForLevel[1] = XP from level 2 to 3 = 100*2^1.65 ≈ 314
      # So cumulative XP to reach level N is sum of xpForLevel[0..N-2]

      # Simpler: find the highest level where cumulative XP <= remainingExp
      # Actually, let me just build cumulative XP
    }

    # Rebuild: calculate cumulative XP to reach each level
    const cumulativeXP = new Array(31).fill(0); // cumulativeXP[level] = XP needed to reach that level
    for (let level = 1; level <= 30; level++) {
      cumulativeXP[level] = cumulativeXP[level - 1] + (xpForLevel[level - 1] || 0);
    }

    # Find current level
    let currentLevel = 1;
    for (let level = 30; level >= 1; level--) {
      if (remainingExp >= cumulativeXP[level]) {
        currentLevel = level;
        break;
      }
    }

    # Calculate XP needed for next level
    const xpForNext = cumulativeXP[currentLevel + 1] - remainingExp;

    return {
      leveledUp: currentLevel < 30 && remainingExp >= cumulativeXP[currentLevel + 1] || currentLevel === 30,
      newLevel: currentLevel + (remainingExp >= cumulativeXP[currentLevel + 1] ? 1 : 0),
      newExp: remainingExp - cumulativeXP[currentLevel] // XP within current level
    };
  }

  # Actually, let me simplify the whole approach. Let me rewrite the progression system with cleaner logic.
  addExperienceSimple(amount: CurrencyAmount): void {
    const newExp = this.progression.#experience + amount;
    
    # Calculate cumulative XP needed for each level
    const cumulativeXP = new Array(31).fill(0);
    for (let level = 1; level <= 30; level++) {
      cumulativeXP[level] = cumulativeXP[level - 1] + xpForLevel[level - 1];
    }

    # Find current level (highest level where cumulativeXP[level] <= newExp)
    let currentLevel = 1;
    for (let level = 30; level >= 1; level--) {
      if (newExp >= cumulativeXP[level]) {
        currentLevel = level;
        break;
      }
    }

    # Determine new level after adding experience
    const expAfterLevelUp = newExp - cumulativeXP[currentLevel];
    let newLevel = currentLevel;

    # Keep leveling up while there's enough XP
    while (newLevel < 30) {
      const xpNeededForNext = xpForLevel[newLevel]; // XP from newLevel to newLevel+1
      if (expAfterLevelUp >= xpNeededForNext) {
        expAfterLevelUp -= xpNeededForNext;
        newLevel++;
      } else {
        break;
      }
    }

    # Update progression state
    this.progression.#experience = newLevel < 30 ? cumulativeXP[newLevel] + expAfterLevelUp : cumulativeXP[30];
    this.progression.#playerLevel = newLevel;

    # Check era advancement
    const newEra = this.#checkEraAdvancement(newLevel, this.progression.#era);
    if (newEra !== this.progression.#era) {
      this.progression.#era = newEra;
    }

    # Award skill points at certain milestones
    if (newLevel === 8 || newLevel === 12 || newLevel === 20 || newLevel === 30) {
      this.progression.#skillPoints++;
    }
  }

  /**
   * Complete an objective
   */
  completeObjective(objectiveId: string): void {
    this.progression.#completedObjectives.add(objectiveId);

    # Award XP for completing objectives
    this.addExperienceSimple(500); // Base objective XP
  }

  /**
   * Unlock a feature
   */
  unlockFeature(featureId: string): boolean {
    if (this.#isFeatureUnlocked(featureId)) return true;

    # Check requirements
    const levelReq = this#getLevelRequirement(featureId);
    const trackReq = this#getTrackRequirement(featureId);
    const resourceReq = this#getResourceRequirement(featureId);

    const levelMet = this.progression.#playerLevel >= levelReq;
    const trackMet = this.#trackProgress.get(ProgressionTrack.PLAYER_LEVEL) >= trackReq;
    const resourceMet = this.progression.#experience >= resourceReq; // Simplified

    if (levelMet && trackMet && resourceMet) {
      this.progression.#unlockedFeatures.add(featureId);
      return true;
    }

    return false;
  }

  #isFeatureUnlocked(featureId: string): boolean {
    return this.progression.#unlockedFeatures.has(featureId);
  }

  #getLevelRequirement(featureId: string): number {
    # Simplified: most features require player level >= some value
    const requirements: Record<string, number> = {
      "flour_mill": 10,
      "dairy_processing": 11,
      "warehouse_2": 14,
      "factory": 17,
      "bank": 18,
      "research_lab": 19,
      "international_trade": 21,
      "advanced_irrigation": 9,
      "irrigation_system": 10,
      "greenhouse": 12,
      "cold_storage": 11
    };
    return requirements[featureId] || 1;
  }

  #getTrackRequirement(featureId: string): number {
    # Track requirements are based on progression track level
    # For simplicity, use player level divided by 4 (each track unlocks every 4 levels)
    return Math.ceil(this.progression.#playerLevel / 4);
  }

  #getResourceRequirement(featureId: string): CurrencyAmount {
    const requirements: Record<string, CurrencyAmount> = {
      "flour_mill": 5000,
      "dairy_processing": 8000,
      "warehouse_2": 10000,
      "factory": 50000,
      "bank": 20000,
      "research_lab": 15000,
      "international_trade": 30000,
      "advanced_irrigation": 3000,
      "irrigation_system": 5000,
      "greenhouse": 10000,
      "cold_storage": 7000
    };
    return requirements[featureId] || 0;
  }

  /**
   * Gain progress in a track
   */
  gainTrackProgress(track: ProgressionTrack, amount: number): void {
    const current = this.progression.#trackProgress.get(track) || 0;
    const newProgress = Math.min(100, current + amount);
    this.progression.#trackProgress.set(track, newProgress);

    # Check for level up via track
    if (newProgress >= 100) {
      this.addExperienceSimple(1000); # Award XP for track completion
      this.progression.#trackProgress.set(track, 0); # Reset track progress
    }
  }

  /**
   * Spend skill points
   */
  spendSkillPoints(amount: number): number {
    const current = this.progression.#skillPoints;
    const newAmount = Math.max(0, current - amount);
    const spent = current - newAmount;
    this.progression.#skillPoints = newAmount;
    return spent;
  }

  /**
   * Gain skill point
   */
  gainSkillPoint(): void {
    this.progression.#skillPoints++;
  }

  /**
   * Get progression summary
   */
  getProgressionSummary(): {
    playerLevel: number;
    experience: CurrencyAmount;
    era: Era;
    trackProgress: Map<ProgressionTrack, number>;
    skillPoints: number;
    prestigeLevel: number;
    unlockedFeatureCount: number;
    totalFeatures: number;
  } {
    const totalFeatures = 50; // Would be dynamically determined
    const unlockedCount = this.progression.#unlockedFeatures.size;

    return {
      playerLevel: this.progression.#playerLevel,
      experience: this.progression.#experience,
      era: this.progression.#era,
      trackProgress: new Map(this.progression.#trackProgress),
      skillPoints: this.progression.#skillPoints,
      prestigeLevel: this.progression.#prestigeLevel,
      unlockedFeatureCount: unlockedCount,
      totalFeatures
    };
  }

  /**
   * Get level information
   */
  getLevelInfo(level?: number): LevelInfo {
    const targetLevel = level || this.progression.#playerLevel;

    # Determine era
    let era: Era;
    if (targetLevel <= 4) era = Era.BEGINNER_FARMER;
    else if (targetLevel <= 8) era = Era.ESTABLISHED_FARMER;
    else if (targetLevel <= 12) era = Era.AGRICULTURAL_ENTREPRENEUR;
    else if (targetLevel <= 16) era = Era.REGIONAL_BUSINESS_OWNER;
    else if (targetLevel <= 20) era = Era.ECONOMIC_LEADER;
    else if (targetLevel <= 25) era = Era.INDUSTRIAL_MAGNATE;
    else era = Era.ECONOMIC_ARCHITECT;

    # Determine title
    const titles: Record<number, string> = {
      1: "Newcomer",
      2: "Gardener",
      3: "Smallholder",
      4: "Local Farmer",
      5: "Farm Operator",
      6: "Livestock Keeper",
      7: "Agricultural Specialist",
      8: "Commercial Farmer",
      9: "Entrepreneur",
      10: "Producer",
      11: "Business Owner",
      12: "Market Competitor",
      13: "Industrialist",
      14: "Regional Trader",
      15: "Infrastructure Investor",
      16: "Regional Tycoon",
      17: "Financial Strategist",
      18: "Economic Analyst",
      19: "Financial Powerhouse",
      20: "Economic Influencer",
      21: "Technology Investor",
      22: "Industrial Leader",
      23: "International Entrepreneur",
      24: "Corporate Conglomerate",
      25: "Global Magnate",
      26: "Public Policy Advisor",
      27: "National Development Leader",
      28: "Economic Architect",
      29: "World Economic Leader",
      30: "Master Architect"
    };

    const title = titles[targetLevel] || "Player";

    # Objectives for this level
    const objectives = this#getLevelObjectives(targetLevel);

    # Unlocks for this level
    const unlocks = this#getLevelUnlocks(targetLevel);

    const xpRequired = targetLevel <= 30 ? xpForLevel[targetLevel - 1] : 0;

    return {
      level: targetLevel,
      title,
      era,
      xpRequired,
      eraNumber: Math.ceil(targetLevel / 4),
      objectives,
      unlocks
    };
  }

  #getLevelObjectives(level: number): string[] {
    const objectivesByLevel: Record<number, string[]> = {
      1: ["Establish basic farm", "Plant first crops", "Build animal enclosure"],
      2: ["Improve crop quality", "Learn crop rotation", "Sell first produce"],
      3: ["Breed first livestock", "Set up feeding system", "Basic animal care"],
      4: ["Market stall setup", "Earn first meaningful profit", "Complete first season"],
      5: ["Purchase additional land", "Build storage buildings", "Set up milk production"],
      6: ["Breed livestock", "Veterinary care", "Advanced animal genetics"],
      7: ["Advanced seeds", "Soil nutrients", "Irrigation setup", "Weather forecasts"],
      8: ["Tractors and machinery", "Hired workers", "Farm loans", "Supply contracts"],
      9: ["Hire permanent workers", "Farm company setup", "Basic accounting"],
      10: ["Flour mills", "Dairy processing", "Food production", "Manufacturing chains"],
      11: ["Multiple farms", "Business ownership", "Employee wages", "Business expenses"],
      12: ["Supply-demand pricing", "Market competition", "Inventory speculation", "Consumer demand"],
      13: ["Large factories", "Industrial workers", "Advanced production"],
      14: ["Regional markets", "Imports", "Exports", "Transport networks"],
      15: ["Roads, railways, warehouses", "Electricity and water infrastructure"],
      16: ["Regional economic indicators", "Competitors", "Population simulation"],
      17: ["Banking, business credit", "Investment portfolios", "Interest rates"],
      18: ["Inflation, GDP", "Unemployment", "Consumer price index", "Economic forecasts"],
      19: ["Advanced financing", "Mergers", "Acquisitions", "Bankruptcy and restructuring"],
      20: ["Government contracts", "Policy consultations", "Economic lobbying"],
      21: ["Research centres", "Automation", "Agricultural robotics"],
      22: ["Advanced manufacturing", "Technology licensing", "Intellectual property"],
      23: ["Foreign markets", "Global supply chains", "Foreign investment"],
      24: ["Holding companies", "Subsidiaries", "Complex financial statements"],
      25: ["Global economic shocks", "International competition", "Major infrastructure projects"],
      26: ["Government policy proposals", "Public economic reports"],
      27: ["Large-scale infrastructure", "National development projects"],
      28: ["Advanced policy simulations", "Fiscal planning", "National economic scenarios"],
      29: ["International development partnerships", "Global trade", "Environmental agreements"],
      30: ["Full sandbox governance", "Advanced economic control", "Custom world scenarios"]
    };

    return objectivesByLevel[level] || ["Continue progression"];
  }

  #getLevelUnlocks(level: number): string[] {
    const unlocksByLevel: Record<number, string[]> = {
      1: ["Basic crop seeds", "Simple tools", "Basic enclosure"],
      2: ["Tomato seeds", "Potato seeds", "Fertiliser", "Crop rotation"],
      3: ["Chickens", "Eggs", "Animal feeding", "Animal care"],
      4: ["Market stalls", "Selling produce", "Basic market prices"],
      5: ["Larger plots", "Land purchases", "Cows", "Milk production"],
      6: ["Pigs", "Sheep", "Breeding", "Animal genetics"],
      7: ["Advanced seeds", "Soil nutrients", "Irrigation", "Weather forecasts"],
      8: ["Tractors", "Harvesting machinery", "Hired workers", "Farm loans"],
      9: ["Farm company", "Basic accounting", "Permanent workers"],
      10: ["Flour mills", "Dairy processing", "Food production"],
      11: ["Multiple farms", "Business ownership", "Employee wages"],
      12: ["Supply-demand pricing", "Market competition"],
      13: ["Large factories", "Industrial workers", "Advanced production"],
      14: ["Regional markets", "Imports", "Exports", "Transport networks"],
      15: ["Infrastructure construction"],
      16: ["Regional economic indicators"],
      17: ["Banking institutions", "Corporate borrowing"],
      18: ["Comprehensive economic dashboard"],
      19: ["Mergers", "Acquisitions", "Bankruptcy"],
      20: ["Government contracts"],
      21: ["Research centres", "Automation", "Agricultural robotics"],
      22: ["Advanced manufacturing", "Technology licensing"],
      23: ["Foreign markets", "Global supply chains"],
      24: ["Holding companies", "Subsidiaries"],
      25: ["Global economic shocks"],
      26: ["Government policy simulations"],
      27: ["National development projects"],
      28: ["Advanced policy simulations"],
      29: ["International development partnerships"],
      30: ["Full sandbox governance"]
    };

    return unlocksByLevel[level] || [];
  }
}