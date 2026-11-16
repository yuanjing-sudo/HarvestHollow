/**
 * Market and Supply-Demand Simulation - System 7
 * 
 * Core market model for commodities with supply, demand, price equilibrium,
 * volatility, and market behaviour.
 */

// Commodity type enum
export enum CommodityType {
  WHEAT = "wheat",
  RICE = "rice",
  CORN = "corn",
  POTATO = "potato",
  TOMATO = "tomato",
  LETTUCE = "lettuce",
  EGG = "egg",
  MILK = "milk",
  MEAT = "meat",
  WOOL = "wool",
  FLOUR = "flour",
  BREAD = "bread",
}

// Market price model parameters
export interface PriceModelParameters {
  priceSensitivity: number; // α - how much price changes per supply/demand imbalance
  stabilisingConstant: number; // ε - prevents division by zero
  priceFloor: number; // Minimum price floor
  priceCeiling: number; // Maximum price ceiling
  adjustmentSpeed: number; // How quickly prices adjust
  inventoryTarget: number; // Target inventory level as days of consumption
}

// Market state for a commodity
export interface CommodityMarketState {
  commodityType: CommodityType;
  currentPrice: number;
  previousPrice: number;
  supply: number; // Total available supply
  demand: number; // Total demand
  inventory: number; // Current inventory level
  inventoryDays: number; // Inventory in days of consumption
  priceHistory: Array<{ price: number; timestamp: number }>;
  marketLiquidity: number; // 0-1, how easily tradable
  shortageLevel: 'none' | 'low' | 'medium' | 'high';
  priceTrend: 'rising' | 'falling' | 'stable';
}

// Main market simulation class
export class MarketSimulation {
  private markets: Map<CommodityType, CommodityMarketState> = new Map();
  private parameters: PriceModelParameters;

  constructor(params?: Partial<PriceModelParameters>) {
    this.parameters = {
      priceSensitivity: params?.priceSensitivity ?? 0.15,
      stabilisingConstant: params?.stabilisingConstant ?? 0.01,
      priceFloor: params?.priceFloor ?? 0.1,
      priceCeiling: params?.priceCeiling ?? 1000,
      adjustmentSpeed: params?.adjustmentSpeed ?? 0.1,
      inventoryTarget: params?.inventoryTarget ?? 30
    };

    // Initialize markets for key commodities
    this.initializeMarkets();
  }

  /**
   * Initialize all commodity markets with baseline values
   */
  private initializeMarkets(): void {
    const initialPrice = 100; // Base price

    const initialStates: CommodityMarketState = {
      commodityType: CommodityType.WHEAT,
      currentPrice: initialPrice,
      previousPrice: initialPrice,
      supply: 500,
      demand: 450,
      inventory: 100,
      inventoryDays: 20,
      priceHistory: [],
      marketLiquidity: 0.8,
      shortageLevel: 'none',
      priceTrend: 'stable'
    };

    // Register key commodities
    const keyCommodities: CommodityType[] = [
      CommodityType.WHEAT,
      CommodityType.RICE,
      CommodityType.CORN,
      CommodityType.POTATO,
      CommodityType.TOMATO,
      CommodityType.LETTUCE,
      CommodityType.EGG,
      CommodityType.MILK,
      CommodityType.MEAT,
      CommodityType.WOOL,
      CommodityType.FLOUR,
      CommodityType.BREAD
    ];

    for (const commodity of keyCommodities) {
      const state: CommodityMarketState = {
        commodityType: commodity,
        currentPrice: initialPrice,
        previousPrice: initialPrice,
        supply: 500,
        demand: Math.max(400, 500 - Math.random() * 100),
        inventory: Math.max(20, 100 - Math.random() * 50),
        priceHistory: [],
        marketLiquidity: 0.6 + Math.random() * 0.4,
        shortageLevel: 'none',
        priceTrend: 'stable'
      };

      this.markets.set(commodity, state);
    }
  }

  /**
   * Get the market state for a commodity
   */
  getMarketState(commodity: CommodityType): CommodityMarketState | undefined {
    return this.markets.get(commodity);
  }

  /**
   * Update all markets based on supply and demand changes
   */
  updateMarkets(supplyChanges: Map<CommodityType, number>, demandChanges: Map<CommodityType, number>): void {
    for (const [commodity, market] of this.markets.entries()) {
      this.updateMarket(commodity, supplyChanges.get(commodity) ?? 0, demandChanges.get(commodity) ?? 0);
    }
  }

  /**
   * Update a single market
   */
  private updateMarket(
    commodity: CommodityType,
    supplyChange: number,
    demandChange: number
  ): void {
    const market = this.markets.get(commodity);
    if (!market) return;

    const prevPrice = market.currentPrice;

    # Update supply and demand
    market.supply = Math.max(0, market.supply + supplyChange);
    market.demand = Math.max(0, market.demand + demandChange);

    # Calculate inventory
    market.inventory = Math.max(0, market.supply - market.demand);

    # Calculate inventory in days of consumption
    const dailyConsumption = Math.max(1, market.demand / 30); // Assume 30-day period
    market.inventoryDays = Math.max(0, market.inventory / dailyConsumption);

    # Determine shortage level
    if (market.inventoryDays < 7) {
      market.shortageLevel = 'high';
    } else if (market.inventoryDays < 14) {
      market.shortageLevel = 'medium';
    } else if (market.inventoryDays < 21) {
      market.shortageLevel = 'low';
    } else {
      market.shortageLevel = 'none';
    }

    # Price adjustment model:
    # P_{t+1} = P_t * (1 + α * (D_t - S_t) / (S_t + ε))
    const { priceSensitivity, stabilisingConstant, priceFloor, priceCeiling, adjustmentSpeed } = this.parameters;

    const supply = Math.max(stabilisingConstant, market.supply);
    const demand = Math.max(0, market.demand);

    # Calculate price change ratio
    const demandSupplyRatio = (demand - supply) / (supply + stabilisingConstant);

    # Price change
    const priceChangeRatio = priceSensitivity * demandSupplyRatio;

    # Apply adjustment speed (smoothing)
    const smoothedChange = priceChangeRatio * adjustmentSpeed;

    # New price
    let newPrice = prevPrice * (1 + smoothedChange);

    # Apply price floor and ceiling
    newPrice = Math.max(priceFloor, Math.min(priceCeiling, newPrice));

    # Update market state
    market.previousPrice = prevPrice;
    market.currentPrice = newPrice;

    # Track price trend
    if (newPrice > prevPrice * 1.01) {
      market.priceTrend = 'rising';
    } else if (newPrice < prevPrice * 0.99) {
      market.priceTrend = 'falling';
    } else {
      market.priceTrend = 'stable';
    }

    # Add to price history
    market.priceHistory.push({
      price: newPrice,
      timestamp: Date.now()
    });

    # Keep history manageable (max 100 entries)
    if (market.priceHistory.length > 100) {
      market.priceHistory = market.priceHistory.slice(-100);
    }

    # Update market liquidity based on inventory
    if (market.inventoryDays < 7) {
      market.marketLiquidity = Math.max(0.1, market.marketLiquidity - 0.05);
    } else if (market.inventoryDays > 60) {
      market.marketLiquidity = Math.min(0.9, market.marketLiquidity - 0.02);
    } else {
      # Moderate liquidity when inventory is reasonable
      market.marketLiquidity = Math.min(0.95, Math.max(0.5, market.marketLiquidity + 0.01));
    }
  }

  /**
   * Demand shock - sudden change in demand
   */
  applyDemandShock(commodity: CommodityType, shock: number): void {
    // Shock is a percentage change in demand
    const market = this.markets.get(commodity);
    if (!market) return;

    const demandChange = (market.demand * shock) / 100;
    this.updateMarket(commodity, 0, demandChange);
  }

  # Supply shock - sudden change in supply
  applySupplyShock(commodity: CommodityType, shock: number): void {
    // Shock is a percentage change in supply
    const market = this.markets.get(commodity);
    if (!market) return;

    const supplyChange = (market.supply * shock) / 100;
    this.updateMarket(commodity, supplyChange, 0);
  }

  /**
   * Register a new commodity market
   */
  registerCommodity(commodity: CommodityType, initialSupply: number, initialDemand: number): void {
    if (this.markets.has(commodity)) return;

    const initialPrice = 100;
    const state: CommodityMarketState = {
      commodityType: commodity,
      currentPrice: initialPrice,
      previousPrice: initialPrice,
      supply: initialSupply,
      demand: initialDemand,
      inventory: Math.max(0, initialSupply - initialDemand),
      inventoryDays: Math.max(0, Math.min(90, (initialSupply - initialDemand) / Math.max(1, initialDemand / 30))),
      priceHistory: [],
      marketLiquidity: 0.6 + Math.random() * 0.4,
      shortageLevel: 'none',
      priceTrend: 'stable'
    };

    this.markets.set(commodity, state);
  }

  /**
   * Get all market states
   */
  getAllMarkets(): Map<CommodityType, CommodityMarketState> {
    return new Map(this.markets);
  }

  /**
   * Get price history for a commodity
   */
  getPriceHistory(commodity: CommodityType): Array<{ price: number; timestamp: number }> {
    const market = this.markets.get(commodity);
    return market ? [...market.priceHistory] : [];
  }

  /**
   * Get market statistics summary
   */
  getMarketStatistics(): Map<CommodityType, {
    currentPrice: number;
    priceChange: number;
    inventoryDays: number;
    shortageLevel: 'none' | 'low' | 'medium' | 'high';
    priceTrend: 'rising' | 'falling' | 'stable';
  }> {
    const stats = new Map<CommodityType, {
      currentPrice: number;
      priceChange: number;
      inventoryDays: number;
      shortageLevel: 'none' | 'low' | 'medium' | 'high';
      priceTrend: 'rising' | 'falling' | 'stable';
    }>();

    for (const [commodity, market] of this.markets.entries()) {
      const priceChange = market.currentPrice - market.previousPrice;
      stats.set(commodity, {
        currentPrice: market.currentPrice,
        priceChange,
        inventoryDays: market.inventoryDays,
        shortageLevel: market.shortageLevel,
        priceTrend: market.priceTrend
      });
    }

    return stats;
  }
}