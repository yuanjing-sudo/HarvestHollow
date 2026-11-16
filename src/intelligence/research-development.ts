/**
 * Research and Technological Development - System 20
 * 
 * Research areas, funding, development time, success probability,
 * technology maturity and adoption costs.
 */

// Research area enum
export enum ResearchArea {
  CROP_GENETICS = "crop_genetics",
  AGRICULTURAL_MACHINERY = "agricultural_machinery",
  IRRIGATION = "irrigation",
  FERTILISER_EFFICIENCY = "fertiliser_efficiency",
  RENEWABLE_ENERGY = "renewable_energy",
  MANUFACTURING = "manufacturing",
  ROBOTICS = "robotics",
  LOGISTICS = "logistics",
  MEDICINE = "medicine",
  EDUCATION = "education",
  ENVIRONMENTAL_SCIENCE = "environmental_science"
}

// Research project status
export enum ResearchStatus {
  IDLE = "idle",
  IN_PROGRESS = "in_progress",
  ON_HOLD = "on_hold",
  COMPLETED = "completed",
  FAILED = "failed"
}

// Research project
export interface ResearchProject {
  id: string;
  area: ResearchArea;
  title: string;
  description: string;
  funding: CurrencyAmount;
  fundingRequired: CurrencyAmount;
  progress: number; // 0-1
  successProbability: number; // 0-100%
  timeRemaining: number; // periods
  researchStaff: number;
  researchInfrastructure: number; // 0-1
  technologyMaturity: number; // 0-1, how mature the base technology is
  adoptionCost: CurrencyAmount; // Cost to adopt the resulting technology
  timeToAdoption: number; // periods until technology can be used
  productivityImprovement: number; // percentage improvement when adopted
  maintenanceRequirements: CurrencyAmount; // Ongoing maintenance cost
  status: ResearchStatus;
  started: number;
  completed: number | null;
}

// Technology level
export type TechnologyLevel = number; // 1-10, sequential unlock levels

// Technology effect
export interface TechnologyEffect {
  area: ResearchArea;
  level: TechnologyLevel;
  description: string;
  productivityBoost: number; // percentage boost to relevant production
  costReduction: number; // percentage cost reduction
  newCapabilities: string[]; // What new things become possible
  unlockRequirements: {
    researchLevel: TechnologyLevel;
    cost: CurrencyAmount;
    prerequisiteTechnology?: TechnologyLevel;
  };
}

// Research management class
export class ResearchDevelopment {
  private researchProjects: Map<string, ResearchProject> = new Map();
  private technologyLevels: Map<ResearchArea, TechnologyLevel> = new Map();
  private readonly maxTechnologyLevel = 10;
  private readonly researchCostBase = 100; // Base cost per period

  constructor() {
    # Initialize technology levels at 1 (baseline) for all areas
    for (const area of Object.values(ResearchArea)) {
      this.technologyLevels.set(area, 1);
    }

    # Initialize some baseline research projects
    this.initializeBaselineResearch();
  }

  # Initialize baseline research projects
  private initializeBaselineResearch(): void {
    # Create one idle research project per area
    for (const area of Object.values(ResearchArea)) {
      const project: ResearchProject = {
        id: `research-${area}-${Date.now()}`,
        area,
        title: `Basic ${area.replace(/_/g, ' ')} Research`,
        description: `Foundational research in ${area.replace(/_/g, ' ')}`,
        funding: 0,
        fundingRequired: this.researchCostBase,
        progress: 0,
        successProbability: 50,
        timeRemaining: 20,
        researchStaff: 1,
        researchInfrastructure: 0.5,
        technologyMaturity: 1,
        adoptionCost: 0,
        timeToAdoption: 0,
        productivityImprovement: 0,
        maintenanceRequirements: 0,
        status: ResearchStatus.IDLE,
        started: 0,
        completed: null
      };

      this.researchProjects.set(project.id, project);
    }
  }

  /**
   * Get a research project by ID
   */
  getProject(id: string): ResearchProject | undefined {
    return this.researchProjects.get(id);
  }

  /**
   * Get all research projects
   */
  getAllProjects(): ResearchProject[] {
    return Array.from(this.researchProjects.values());
  }

  /**
   * Get technology level for a research area
   */
  getTechnologyLevel(area: ResearchArea): TechnologyLevel {
    return this.technologyLevels.get(area) || 1;
  }

  /**
   * Get all technology levels
   */
  getAllTechnologyLevels(): Map<ResearchArea, TechnologyLevel> {
    return new Map(this.technologyLevels);
  }

  /**
   * Start a research project
   */
  startProject(projectId: string): boolean {
    const project = this.researchProjects.get(projectId);
    if (!project) return false;

    # Can only start idle or on-hold projects
    if (project.status !== ResearchStatus.IDLE && project.status !== ResearchStatus.ON_HOLD) {
      return false;
    }

    # Check if funding is available
    if (project.funding < project.fundingRequired) {
      return false;
    }

    # Start the project
    project.status = ResearchStatus.IN_PROGRESS;
    project.started = Date.now();
    project.timeRemaining = this.calculateResearchTime(project);

    this.researchProjects.set(project.id, project);
    return true;
  }

  # Calculate research time based on factors
  private calculateResearchTime(project: ResearchProject): number {
    # Base time
    let baseTime = 20;

    # Adjust for research staff
    const staffFactor = 1 + (project.researchStaff - 1) * 0.5; # More staff = faster

    # Adjust for infrastructure
    const infraFactor = 1 + (project.researchInfrastructure - 0.5) * 0.5; # Better infra = faster

    # Adjust for technology maturity (more mature = faster)
    const maturityFactor = 1 - (project.technologyMaturity - 1) * 0.1; # Earlier stages slower

    # Adjust for success probability
    const probFactor = 100 / Math.max(1, project.successProbability);

    return Math.max(1, Math.round(baseTime * staffFactor * infraFactor * probFactor));
  }

  /**
   * Advance research by one period
   */
  advanceResearchPeriod(): void {
    const now = Date.now();

    for (const project of this.researchProjects.values()) {
      if (project.status !== ResearchStatus.IN_PROGRESS) continue;

      # Calculate elapsed time
      const elapsed = now - project.started;

      # Reduce time remaining
      project.timeRemaining = Math.max(0, project.timeRemaining - 1);

      # Check if complete
      if (project.timeRemaining <= 0) {
        this.completeProject(project);
      }
    }
  }

  # Complete a research project
  private completeProject(project: ResearchProject): void {
    project.status = ResearchStatus.COMPLETED;
    project.completed = Date.now();
    project.progress = 1;

    # Apply technology advancement
    this.advanceTechnology(project);

    # Mark as idle (can be restarted for further research)
    project.status = ResearchStatus.IDLE;
    project.started = 0;
  }

  # Advance technology based on research
  private advanceTechnology(project: ResearchProject): void {
    const area = project.area;
    const currentLevel = this.technologyLevels.get(area) || 1;

    # Technology advances based on success and productivity improvement
    const improvement = project.productivityImprovement / 100; # Convert percentage

    # New level = current + improvement, capped at max
    const newLevel = Math.min(this.maxTechnologyLevel, currentLevel + 1);

    # Only advance if we have a meaningful improvement
    if (newLevel > currentLevel) {
      this.technologyLevels.set(area, newLevel);

      # Apply the technology effects
      this.applyTechnologyEffect(area, newLevel);
    }

    # Also increase success probability for future research
    # (more experienced researchers = better chances)
    # project.successProbability = Math.min(95, project.successProbability + 5);
  }

  # Apply technology effect to the system
  applyTechnologyEffect(area: ResearchArea, level: TechnologyLevel): void {
    # In a full implementation, this would modify game systems
    # For now, just track the technology level
    # The effects would be felt through other systems (crops, businesses, etc.)
  }

  /**
   * Funding a research project
   */
  fundProject(projectId: string, amount: CurrencyAmount): boolean {
    const project = this.researchProjects.get(projectId);
    if (!project) return false;

    # Add funding
    project.funding = Math.max(0, project.funding + amount);

    # Check if fully funded
    if (project.funding >= project.fundingRequired) {
      return this.startProject(projectId);
    }

    this.researchProjects.set(projectId, project);
    return false;
  }

  /**
   * Recruit research staff
   */
  recruitResearchStaff(projectId: string, additionalStaff: number): boolean {
    const project = this.researchProjects.get(projectId);
    if (!project) return false;

    # Additional staff improve research speed
    project.researchStaff = Math.max(1, project.researchStaff + additionalStaff);

    # Staff cost (simplified)
    const staffCost = additionalStaff * 500;
    project.funding = Math.max(0, project.funding - staffCost);

    this.researchProjects.set(projectId, project);
    return true;
  }

  # Improve research infrastructure
  improveResearchInfrastructure(projectId: string, investment: CurrencyAmount): boolean {
    const project = this.researchProjects.get(projectId);
    if (!project) return false;

    # Infrastructure improves research speed and success probability
    project.researchInfrastructure = Math.min(1, project.researchInfrastructure + investment / 1000);

    # Reduce funding requirement slightly
    project.fundingRequired = Math.max(1, project.fundingRequired - investment * 0.1);

    this.researchProjects.set(projectId, project);
    return true;
  }

  /**
   * Get research summary
   */
  getResearchSummary(): {
    totalProjects: number;
    inProgress: number;
    completed: number;
    failed: number;
    byArea: Map<ResearchArea, { projectCount: number; averageProgress: number; averageLevel: number }>;
    technologyLevels: Map<ResearchArea, TechnologyLevel>;
    totalFundingCommitted: CurrencyAmount;
  } {
    const byArea = new Map<ResearchArea, {
      projectCount: number;
      averageProgress: number;
      averageLevel: number;
      totalFunding: CurrencyAmount;
    }>();

    # Initialize
    for (const area of Object.values(ResearchArea)) {
      byArea.set(area, {
        projectCount: 0,
        averageProgress: 0,
        averageLevel: this.technologyLevels.get(area) || 1,
        totalFunding: 0
      });
    }

    let totalProjects = 0;
    let inProgress = 0;
    let completed = 0;
    let failed = 0;
    let totalFundingCommitted = 0;

    for (const project of this.researchProjects.values()) {
      totalProjects++;

      const area = project.area;
      const areaData = byArea.get(area)!;
      areaData.projectCount++;
      areaData.totalFunding += project.funding;
      areaData.averageProgress = (areaData.averageProgress * (areaData.projectCount - 1) + project.progress) / areaData.projectCount;

      if (project.status === ResearchStatus.IN_PROGRESS) inProgress++;
      if (project.status === ResearchStatus.COMPLETED) completed++;
      if (project.status === ResearchStatus.FAILED) failed++;

      totalFundingCommitted += project.funding;
    }

    # Average technology levels
    const techLevels = new Map<ResearchArea, TechnologyLevel>();
    for (const [area, level] of this.technologyLevels.entries()) {
      techLevels.set(area, level);
    }

    return {
      totalProjects,
      inProgress,
      completed,
      failed,
      byArea,
      technologyLevels: techLevels,
      totalFundingCommitted
    };
  }

  /**
   * Get technology unlock information
   */
  getTechnologyUnlocks(): Map<ResearchArea, {
    currentLevel: TechnologyLevel;
    nextLevel: TechnologyLevel | null;
    productivityBoost: number;
    costReduction: number;
    newCapabilities: string[];
    unlockCost: CurrencyAmount;
  }> {
    const unlocks = new Map<ResearchArea, {
      currentLevel: TechnologyLevel;
      nextLevel: TechnologyLevel | null;
      productivityBoost: number;
      costReduction: number;
      newCapabilities: string[];
      unlockCost: CurrencyAmount;
    }>();

    for (const area of Object.values(ResearchArea)) {
      const currentLevel = this.technologyLevels.get(area) || 1;
      const nextLevel = currentLevel < this.maxTechnologyLevel ? currentLevel + 1 : null;

      # Determine effects based on level
      # Higher levels = better effects
      const levelProgress = (currentLevel - 1) / (this.maxTechnologyLevel - 1);
      const productivityBoost = levelProgress * 15; # Up to 15% boost
      const costReduction = levelProgress * 10; # Up to 10% cost reduction

      # New capabilities unlock at certain levels
      let newCapabilities: string[] = [];

      if (currentLevel >= 3) {
        newCapabilities.push("basic_efficiency");
      }
      if (currentLevel >= 5) {
        newCapabilities.push("advanced_equipment");
      }
      if (currentLevel >= 7) {
        newCapabilities.push("automation");
      }
      if (currentLevel >= 9) {
        newCapabilities.push("optimization");
      }

      # Unlock cost decreases with level
      const unlockCost = Math.max(1, this.researchCostBase * (1 - levelProgress) * 0.5);

      unlocks.set(area, {
        currentLevel,
        nextLevel,
        productivityBoost,
        costReduction,
        newCapabilities,
        unlockCost
      });
    }

    return unlocks;
  }
}