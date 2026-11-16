/**
 * Population and Demographics - System 10
 * 
 * Households with different economic circumstances, demographics, and consumer behaviour.
 * Multiple household classes with distinct spending patterns.
 */

// Household class
export interface Household {
  id: string;
  members: number; // Number of people
  income: CurrencyAmount; // Monthly income
  savings: CurrencyAmount; // Current savings
  debt: CurrencyAmount; // Current debt
  employmentStatus: 'employed' | 'unemployed' | 'retired' | 'student' | 'homemaker';
  householdClass: 'low-income' | 'middle-income' | 'high-income';
  ageDistribution: Array<{ age: number; count: number }>; // Age groups
  location: { x: number; y: number }; // Where they live
  consumptionPreferences: Map<ResourceType, number>; // Preferred resource types (0-100)
  spendingHabits: {
    food: number; // Percentage of income spent on food
    housing: number; // Percentage spent on housing
    transport: number; // Percentage spent on transport
    healthcare: number; // Percentage spent on healthcare
    education: number; // Percentage spent on education
    discretionary: number; // Percentage spent on discretionary items
  };
  lastIncomeUpdate: number;
}

// Demographic indicators
export interface DemographicIndicators {
  populationSize: number;
  birthRate: number; // per 1000 per year
  deathRate: number; // per 1000 per year
  ageDistribution: Map<number, number>; // Age -> count
  householdSizeDistribution: Map<number, number>; // Household size -> count
  migrationRate: number; // Net migration per period
  urbanisationRate: number; // Percentage moving to urban areas
  educationLevels: {
    primary: number; // Percentage with primary education
    secondary: number; // Percentage with secondary education
    tertiary: number; // Percentage with tertiary education
  };
  dependencyRatio: number; // Non-working / working age ratio
}

// Consumer behaviour indicators
export interface ConsumerBehaviour {
  priceSensitivity: number; // 0-100, higher = more price sensitive
  qualityPreference: number; // 0-100, higher = prefer quality
  brandLoyalty: number; // 0-100, higher = loyal to brands
  savingsRate: number; // 0-100, percentage of income saved
  foodSpendingPriority: number; // 0-100, priority for food spending
  consumptionConfidence: number; // 0-100, confidence to spend
}

// Population simulation class
export class PopulationSimulation {
  private households: Map<string, Household> = new Map();
  private indicators: DemographicIndicators;
  private consumerBehaviour: ConsumerBehaviour;
  private readonly householdClasses: Map<string, { minIncome: number; maxIncome: number; spendingMultiplier: number }>;

  constructor() {
    # Initialize demographic indicators
    this.indicators = {
      populationSize: 1000,
      birthRate: 15, // per 1000 per year
      deathRate: 8, // per 1000 per year
      ageDistribution: new Map(),
      householdSizeDistribution: new Map(),
      migrationRate: 2, // per period
      urbanisationRate: 0.5, // 0.5% per period
      educationLevels: {
        primary: 80,
        secondary: 60,
        tertiary: 30
      },
      dependencyRatio: 0.2
    };

    # Initialize consumer behaviour (default/average)
    this.consumerBehaviour = {
      priceSensitivity: 50,
      qualityPreference: 50,
      brandLoyalty: 50,
      savingsRate: 20,
      foodSpendingPriority: 30,
      consumptionConfidence: 50
    };

    # Household class definitions based on income thresholds
    this.householdClasses = new Map([
      ['low-income', { minIncome: 0, maxIncome: 2000, spendingMultiplier: 0.8 }],
      ['middle-income', { minIncome: 2001, maxIncome: 5000, spendingMultiplier: 1.0 }],
      ['high-income', { minIncome: 5001, maxIncome: 100000, spendingMultiplier: 1.3 }]
    ]);

    # Initialize sample households
    this.initializeHouseholds(200);
  }

  /**
   * Initialize households with realistic distribution
   */
  private initializeHouseholds(count: number): void {
    // Income distribution: roughly normal-ish around middle
    const meanIncome = 3500;
    const stdDev = 1500;

    for (let i = 0; i < count; i++) {
      # Generate income with some randomization
      let income: number;
      let householdClass: 'low-income' | 'middle-income' | 'high-income';

      # Simple income generation - 60% middle, 25% low, 15% high
      const classRoll = Math.random();
      if (classRoll < 0.6) {
        householdClass = 'middle-income';
        # Centered around mean with some spread
        income = meanIncome + (Math.random() - 0.5) * stdDev * 0.8;
      } else if (classRoll < 0.85) {
        householdClass = 'low-income';
        income = Math.random() * 2000;
      } else {
        householdClass = 'high-income';
        income = meanIncome + Math.random() * 20000 + 5000;
      }

      # Ensure income is within class bounds
      const classBounds = this.householdClasses.get(householdClass)!;
      income = Math.max(classBounds.minIncome, Math.min(classBounds.maxIncome, income));

      # Household size varies by class
      let members: number;
      switch (householdClass) {
        case 'low-income':
          members = 1 + Math.floor(Math.random() * 3); // 1-3 people
          break;
        case 'middle-income':
          members = 2 + Math.floor(Math.random() * 3); // 2-4 people
          break;
        case 'high-income':
          members = 2 + Math.floor(Math.random() * 4); // 2-5 people, often smaller families
          break;
        default:
          members = 2;
      }

      # Age distribution within household
      const ageDistribution = this.generateAgeDistribution(members);

      # Location - spread across the world map
      const x = Math.floor(Math.random() * 200);
      const y = Math.floor(Math.random() * 200);

      # Consumption preferences (based on household class)
      const preferences = this.generateConsumptionPreferences(householdClass);

      # Spending habits based on class
      const spendingMultiplier = this.householdClasses.get(householdClass)!.spendingMultiplier;
      const spendingHabits = this.generateSpendingHabits(householdClass, spendingMultiplier);

      # Create household
      const household: Household = {
        id: `household-${i}`,
        members,
        income: Math.round(income),
        savings: Math.round(income * 0.1), # 10% initial savings
        debt: 0,
        employmentStatus: this.generateEmploymentStatus(householdClass),
        householdClass,
        ageDistribution,
        location: { x, y },
        consumptionPreferences: preferences,
        spendingHabits
      };

      this.households.set(household.id, household);
    }

    # Update demographic indicators after initialization
    this.updateIndicators();
  }

  # Generate age distribution for household members
  private generateAgeDistribution(members: number): Array<{ age: number; count: number }> {
    const distribution: Array<{ age: number; count: number }> = [];

    for (let i = 0; i < members; i++) {
      # Age 0-80 range, distribute somewhat realistically
      const age = Math.floor(Math.random() * 80); // 0-79
      # Check if this age already exists in distribution
      const existing = distribution.find(d => d.age === age);
      if (existing) {
        existing.count++;
      } else {
        distribution.push({ age, count: 1 });
      }
    }

    return distribution;
  }

  # Generate consumption preferences based on household class
  private generateConsumptionPreferences(householdClass: 'low-income' | 'middle-income' | 'high-income'): Map<ResourceType, number> {
    const preferences = new Map<ResourceType, number>();

    # Base preferences by class
    const basePreferences: Map<ResourceType, number> = new Map([
      [ResourceType.WATER, 100], # Everyone needs water
      [ResourceType.FUEL, 40],
      [ResourceType.FERTILISER, 10], # Only relevant for farming households
      [ResourceType.SEEDS, 5],
      [ResourceType.ANIMAL_FEED, 5],
      [ResourceType.TIMBER, 30],
      [ResourceType.STONE, 20],
      [ResourceType.METAL, 20],
      [ResourceType.CONSTRUCTION_MATERIALS, 30],
      [ResourceType.MACHINERY_PARTS, 5],
      [ResourceType.MEDICINES, 25],
      [ResourceType.PACKAGING, 15]
    ]);

    for (const [type, baseVal] of basePreferences.entries()) {
      let multiplier = 1.0;

      # Adjust based on household class
      switch (householdClass) {
        case 'low-income':
          # More price-sensitive, buy less overall
          multiplier = 0.6;
          break;
        case 'middle-income':
          multiplier = 1.0;
          break;
        case 'high-income':
          multiplier = 1.4;
          # High-income may prefer quality over quantity
          if (type === ResourceType.MEDICINES) multiplier = 1.6;
          if (type === ResourceType.FOOD_PROCESSING || type === ResourceType.SEEDS) multiplier = 1.2;
          break;
      }

      preferences.set(type, Math.max(0, Math.min(100, baseVal * multiplier)));
    }

    return preferences;
  }

  # Generate spending habits based on household class
  private generateSpendingHabits(householdClass: 'low-income' | 'middle-income' | 'high-income', multiplier: number): {
    food: number;
    housing: number;
    transport: number;
    healthcare: number;
    education: number;
    discretionary: number;
  } {
    # Base spending percentages by class
    let baseFood, baseHousing, baseTransport, baseHealthcare, baseEducation, baseDiscretionary;

    switch (householdClass) {
      case 'low-income':
        baseFood = 40;    # Spend a lot on food
        baseHousing = 30; # Housing is major expense
        baseTransport = 15;
        baseHealthcare = 5;
        baseEducation = 3;
        baseDiscretionary = 7;
        break;
      case 'middle-income':
        baseFood = 25;    # Balanced spending
        baseHousing = 25;
        baseTransport = 20;
        baseHealthcare = 10;
        baseEducation = 8;
        baseDiscretionary = 22;
        break;
      case 'high-income':
        baseFood = 15;    # Food is smaller portion
        baseHousing = 20;
        baseTransport = 20;
        baseHealthcare = 15;
        baseEducation = 15;
        baseDiscretionary = 15;
        break;
      default:
        baseFood = 25;
        baseHousing = 25;
        baseTransport = 20;
        baseHealthcare = 10;
        baseEducation = 8;
        baseDiscretionary = 12;
    }

    # Apply multiplier and ensure they sum to ~100
    const totalBase = baseFood + baseHousing + baseTransport + baseHealthcare + baseEducation + baseDiscretionary;
    const adjustment = 100 / totalBase;

    return {
      food: Math.round(baseFood * adjustment * multiplier),
      housing: Math.round(baseHousing * adjustment * multiplier),
      transport: Math.round(baseTransport * adjustment * multiplier),
      healthcare: Math.round(baseHealthcare * adjustment * multiplier),
      education: Math.round(baseEducation * adjustment * multiplier),
      discretionary: Math.round(baseDiscretionary * adjustment * multiplier)
    };
  }

  # Generate employment status based on class
  private generateEmploymentStatus(householdClass: 'low-income' | 'middle-income' | 'high-income'): 'employed' | 'unemployed' | 'retired' | 'student' | 'homemaker' {
    const rolls = Math.random();

    switch (householdClass) {
      case 'low-income':
        # Higher unemployment risk
        if (rolls < 0.15) return 'unemployed';
        if (rolls < 0.7) return 'employed';
        return 'homemaker';
      case 'middle-income':
        if (rolls < 0.08) return 'unemployed';
        if (rolls < 0.8) return 'employed';
        return 'retired';
      case 'high-income':
        if (rolls < 0.03) return 'unemployed';
        if (rolls < 0.75) return 'employed';
        return 'retired';
      default:
        return 'employed';
    }
  }

  /**
   * Update household income based on employment and economic conditions
   */
  updateHouseholdIncome(householdId: string, newIncome: CurrencyAmount): void {
    const household = this.households.get(householdId);
    if (!household) return;

    # Keep savings and debt proportions somewhat stable
    const previousIncome = household.income;
    const savingsRatio = household.savings / Math.max(1, previousIncome);
    const debtRatio = household.debt / Math.max(1, previousIncome);

    # Update income
    household.income = newIncome;

    # Adjust savings to maintain ratio
    household.savings = Math.round(newIncome * savingsRatio);

    # Adjust debt similarly (may change if income changed significantly)
    household.debt = Math.round(newIncome * debtRatio);

    # Update employment status if income dropped significantly
    if (newIncome < 500 && household.employmentStatus === 'employed') {
      household.employmentStatus = 'unemployed';
    }
  }

  /**
   * Consume resources based on household spending habits
   */
  consumeResources(householdId: string, availableResources: Map<ResourceType, CurrencyAmount>): Map<ResourceType, CurrencyAmount> {
    const household = this.households.get(householdId);
    if (!household) return availableResources;

    const { spendingHabits, consumptionPreferences, income } = household;
    const remainingResources = new Map<ResourceType, CurrencyAmount>(availableResources);

    # Calculate total spending capacity based on income and confidence
    const confidenceMultiplier = household.consumptionConfidence / 50; # Relative to average
    const effectiveIncome = income * confidenceMultiplier * 0.8; # Don't spend 100% of income

    # Allocate spending by category
    const foodBudget = effectiveIncome * (spendingHabits.food / 100);
    const housingBudget = effectiveIncome * (spendingHabits.housing / 100);
    const transportBudget = effectiveIncome * (spendingHabits.transport / 100);
    const healthcareBudget = effectiveIncome * (spendingHabits.healthcare / 100);
    const educationBudget = effectiveIncome * (spendingHabits.education / 100);
    const discretionaryBudget = effectiveIncome * (spendingHabits.discretionary / 100);

    # Food consumption (priority)
    const foodPreferences = household.consumptionPreferences.get(ResourceType.SEEDS) || 50;
    # In a full implementation, would map to actual food products
    const foodSpend = Math.min(foodBudget, remainingResources.get(ResourceType.SEEDS) || 0);
    remainingResources.set(ResourceType.SEEDS, (remainingResources.get(ResourceType.SEEDS) || 0) - foodSpend);

    # Other consumptions would continue similarly...

    return remainingResources;
  }

  /**
   * Update demographic indicators
   */
  private updateIndicators(): void {
    const householdCount = this.households.size;

    # Population size changes
    # Simple model: births - deaths + migration
    const births = Math.floor(this.indicators.populationSize * this.indicators.birthRate / 1000);
    const deaths = Math.floor(this.indicators.populationSize * this.indicators.deathRate / 1000);
    const migration = Math.floor(this.indicators.populationSize * this.indicators.migrationRate / 1000);

    this.indicators.populationSize += births - deaths + migration;

    # Update household size distribution
    const sizeDist = new Map<number, number>();
    for (const household of this.households.values()) {
      const size = household.members;
      sizeDist.set(size, (sizeDist.get(size) || 0) + 1);
    }
    this.indicators.householdSizeDistribution = sizeDist;

    # Update age distribution
    const ageDist = new Map<number, number>();
    for (const household of this.households.values()) {
      for (const ageEntry of household.ageDistribution) {
        ageDist.set(ageEntry.age, (ageDist.get(ageEntry.age) || 0) + ageEntry.count);
      }
    }
    this.indicators.ageDistribution = ageDist;

    # Dependency ratio: non-working (children + elderly) / working-age
    # Simplified: working age = 18-65
    let workingAgeCount = 0;
    let nonWorkingCount = 0;

    for (const household of this.households.values()) {
      for (const ageEntry of household.ageDistribution) {
        const age = ageEntry.age;
        if (age >= 18 && age <= 65) {
          workingAgeCount += ageEntry.count;
        } else {
          nonWorkingCount += ageEntry.count;
        }
      }
    }

    this.indicators.dependencyRatio = workingAgeCount > 0 ? nonWorkingCount / workingAgeCount : 0;
  }

  /**
   * Advance population by one period
   */
  advancePeriod(): void {
    # 1. Natural population change (births and deaths)
    const birthRolls = Array.from({ length: this.indicators.populationSize }, () => Math.random());
    const deathRolls = Array.from({ length: this.indicators.populationSize }, () => Math.random());

    # Apply birth/death rates
    let newborns = 0;
    for (let i = 0; i < this.indicators.populationSize; i++) {
      if (birthRolls[i] < this.indicators.birthRate / 1000) {
        newborns++;
      }
      if (deathRolls[i] < this.indicators.deathRate / 1000) {
        # Remove a household or member
        this.removeRandomHouseholdMember();
      }
    }

    # Add newborn households (simplified: create new household with 2 members)
    for (let i = 0; i < newborns; i++) {
      const newHousehold: Household = {
        id: `household-new-${Date.now()}-${i}`,
        members: 2,
        income: 2000, # Starting income for new household
        savings: 100,
        debt: 0,
        employmentStatus: 'employed',
        householdClass: 'middle-income',
        ageDistribution: [{ age: 0, count: 1 }, { age: 0, count: 1 }],
        location: { x: Math.random() * 200, y: Math.random() * 200 },
        consumptionPreferences: this.generateConsumptionPreferences('middle-income'),
        spendingHabits: this.generateSpendingHabits('middle-income', 1.0)
      };
      this.households.set(newHousehold.id, newHousehold);
    }

    # 2. Migration
    const migrationCount = Math.floor(this.indicators.populationSize * this.indicators.migrationRate / 1000);
    for (let i = 0; i < migrationCount; i++) {
      # Simple migration - move existing household to new location
      const existingHouseholds = Array.from(this.households.values());
      if (existingHouseholds.length > 0) {
        const randomIndex = Math.floor(Math.random() * existingHouseholds.length);
        const movedHousehold = existingHouseholds[randomIndex];
        movedHousehold.location = {
          x: Math.random() * 200,
          y: Math.random() * 200
        };
      }
    }

    # 3. Update indicators
    this.updateIndicators();

    # 4. Update consumer behaviour based on conditions
    this.updateConsumerBehaviour();
  }

  # Remove a random household member (simplified mortality)
  private removeRandomHouseholdMember(): void {
    const households = Array.from(this.households.values());
    if (households.length === 0) return;

    const randomHousehold = households[Math.floor(Math.random() * households.length)];
    if (randomHousehold.members <= 1) {
      # Remove entire household
      this.households.delete(randomHousehold.id);
    } else {
      # Reduce members by 1
      randomHousehold.members--;
      # Also remove from age distribution
      const ageToRemove = Math.floor(Math.random() * 80);
      const ageEntry = randomHousehold.ageDistribution.find(a => a.age === ageToRemove);
      if (ageEntry) {
        ageEntry.count--;
        if (ageEntry.count <= 0) {
          randomHousehold.ageDistribution = randomHousehold.ageDistribution.filter(a => a.age !== ageToRemove);
        }
      }
    }
  }

  # Update consumer behaviour based on economic conditions
  private updateConsumerBehaviour(): void {
    # Adjust based on overall economic conditions
    const avgIncome = Array.from(this.households.values())
      .reduce((sum, h) => sum + h.income, 0) / Math.max(1, this.households.size);

    # Price sensitivity decreases with higher income
    const avgSpending = this.households.size > 0
      ? Array.from(this.households.values())
          .reduce((sum, h) => sum + (h.spendingHabits.food + h.spendingHabits.housing + h.spendingHabits.transport), 0)
          / this.households.size : 0;

    # Simple adjustments
    this.consumerBehaviour.priceSensitivity = Math.max(0, Math.min(100, 60 - (avgIncome - 3000) * 0.02));
    this.consumerBehaviour.consumptionConfidence = Math.max(0, Math.min(100, 50 + (avgIncome - 3000) * 0.03));
  }

  /**
   * Get demographic indicators
   */
  getIndicators(): DemographicIndicators {
    return { ...this.indicators };
  }

  /**
   * Get all households
   */
  getAllHouseholds(): Household[] {
    return Array.from(this.households.values());
  }

  /**
   * Get households by class
   */
  getHouseholdsByClass(className: 'low-income' | 'middle-income' | 'high-income'): Household[] {
    return Array.from(this.households.values()).filter(h => h.householdClass === className);
  }

  /**
   * Get consumer behaviour averages
   */
  getConsumerBehaviour(): ConsumerBehaviour {
    return { ...this.consumerBehaviour };
  }

  /**
   * Get income distribution by class
   */
  getIncomeDistribution(): Map<'low-income' | 'middle-income' | 'high-income', number> {
    const distribution = new Map<'low-income' | 'middle-income' | 'high-income', number>([
      ['low-income', 0],
      ['middle-income', 0],
      ['high-income', 0]
    ]);

    for (const household of this.households.values()) {
      distribution.set(household.householdClass, (distribution.get(household.householdClass) || 0) + 1);
    }

    return distribution;
  }
}