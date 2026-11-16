/**
 * International Trade and Global Economy - System 19
 * 
 * Imports, exports, trade balance, tariffs, trade agreements, exchange rates,
 * foreign demand/supply and regional relationships.
 */

// Trade flow direction
export enum TradeDirection {
  IMPORT = "import",
  EXPORT = "export"
}

// Trade flow record
export interface TradeFlow {
  id: string;
  commodity: string;
  direction: TradeDirection;
  origin: string; // Country or region ID
  destination: string; // Country or region ID
  quantity: CurrencyAmount;
  value: CurrencyAmount; // In destination currency
  timestamp: number;
  tariffApplied: CurrencyAmount;
  shippingCost: CurrencyAmount;
}

// Exchange rate
export type ExchangeRate = number; // Units of quote currency per base currency

// Country/region profile for trade
export interface TradePartner {
  id: string;
  name: string;
  gdp: CurrencyAmount;
  population: number;
  tradeBalance: CurrencyAmount; // positive = surplus, negative = deficit
  mainImports: Array<{ commodity: string; value: CurrencyAmount }>;
  mainExports: Array<{ commodity: string; value: CurrencyAmount }>;
  tariffRate: number; // weighted average tariff (0-100)
  exchangeRateToBase: ExchangeRate;
  tradeAgreements: string[]; // Agreement IDs
  riskLevel: 'low' | 'medium' | 'high';
}

// Global trade system
export class InternationalTradeSystem {
  private tradeFlows: Map<string, TradeFlow> = new Map();
  private tradePartners: Map<string, TradePartner> = new Map();
  private exchangeRates: Map<string, ExchangeRate> = new Map();
  private readonly baseCurrency = "game_gold";

  constructor() {
    # Initialize with some default trade partners
    this.initializeDefaultPartners();
  }

  # Initialize default trade partners
  private initializeDefaultPartners(): void {
    # Create several trade partners with different economic profiles
    const partners: TradePartner[] = [
      {
        id: "region-north",
        name: "Northern Region",
        gdp: 50000,
        population: 2000,
        tradeBalance: 1000,
        mainImports: [
          { commodity: "grain", value: 2000 },
          { commodity: "machinery", value: 1500 }
        ],
        mainExports: [
          { commodity: "livestock", value: 3000 },
          { commodity: "timber", value: 2500 }
        ],
        tariffRate: 5,
        exchangeRateToBase: 1.0,
        tradeAgreements: ["free-trade-1"],
        riskLevel: "low"
      },
      {
        id: "region-south",
        name: "Southern Region",
        gdp: 45000,
        population: 1800,
        tradeBalance: -500,
        mainImports: [
          { commodity: "fuels", value: 2500 },
          { commodity: "luxury_goods", value: 1200 }
        ],
        mainExports: [
          { commodity: "citrus_fruit", value: 3500 },
          { commodity: "textiles", value: 2000 }
        ],
        tariffRate: 8,
        exchangeRateToBase: 0.9,
        tradeAgreements: ["free-trade-1", "regional-pact-1"],
        riskLevel: "medium"
      },
      {
        id: "region-east",
        name: "Eastern Region",
        gdp: 60000,
        population: 2500,
        tradeBalance: -2000,
        mainImports: [
          { commodity: "electronics", value: 4000 },
          { commodity: "metals", value: 3000 }
        ],
        mainExports: [
          { commodity: "electronics_manufacturing", value: 5000 },
          { commodity: "food_processing", value: 2500 }
        ],
        tariffRate: 3,
        exchangeRateToBase: 1.1,
        tradeAgreements: ["free-trade-2"],
        riskLevel: "medium"
      },
      {
        id: "region-west",
        name: "Western Region",
        gdp: 55000,
        population: 2200,
        tradeBalance: 800,
        mainImports: [
          { commodity: "chemicals", value: 2000 },
          { commodity: "vehicles", value: 3500 }
        ],
        mainExports: [
          { commodity: "aviation", value: 4000 },
          { commodity: "pharmaceuticals", value: 3000 }
        ],
        tariffRate: 6,
        exchangeRateToBase: 1.0,
        tradeAgreements: ["free-trade-1", "free-trade-2"],
        riskLevel: "low"
      },
      {
        id: "region-center",
        name: "Central Region",
        gdp: 35000,
        population: 1500,
        tradeBalance: -1000,
        mainImports: [
          { commodity: "grain", value: 1500 },
          { commodity: "fuels", value: 1800 }
        ],
        mainExports: [
          { commodity: "manufactured_goods", value: 2500 }
        ],
        tariffRate: 10,
        exchangeRateToBase: 0.8,
        tradeAgreements: ["regional-pact-1"],
        riskLevel: "high"
      }
    ];

    for (const partner of partners) {
      this.tradePartners.set(partner.id, partner);
      this.exchangeRates.set(partner.id, partner.exchangeRateToBase);
    }
  }

  /**
   * Get a trade partner by ID
   */
  getTradePartner(id: string): TradePartner | undefined {
    return this.tradePartners.get(id);
  }

  /**
   * Get all trade partners
   */
  getAllTrade Partners(): Map<string, TradePartner> {
    return new Map(this.tradePartners);
  }

  /**
   * Get exchange rate to base currency
   */
  getExchangeRate(partnerId: string): ExchangeRate | undefined {
    return this.exchangeRates.get(partnerId);
  }

  /**
   * Set exchange rate
   */
  setExchangeRate(partnerId: string, rate: ExchangeRate): void {
    this.exchangeRates.set(partnerId, rate);
  }

  /**
   * Record a trade flow
   */
  recordTradeFlow(flow: Omit<TradeFlow, 'id' | 'timestamp' | 'tariffApplied' | 'shippingCost'>): TradeFlow {
    const now = Date.now();
    const tariffRate = this.getTariffRate(flow.direction, flow.commodity);
    const tariffApplied = Math.round(flow.value * tariffRate / 100);
    const shippingCost = Math.round(flow.value * 0.05); // 5% shipping

    const tradeFlow: TradeFlow = {
      id: `trade-${Date.now()}-${Math.random().toString(36).slice(2)}`,
      commodity: flow.commodity,
      direction: flow.direction,
      origin: flow.origin,
      destination: flow.destination,
      quantity: flow.quantity,
      value: flow.value,
      timestamp: now,
      tariffApplied,
      shippingCost
    };

    this.tradeFlows.set(tradeFlow.id, tradeFlow);

    # Update partner trade balances
    this.updatePartnerBalances(tradeFlow);

    return tradeFlow;
  }

  # Get tariff rate for a commodity and direction
  private getTariffRate(direction: TradeDirection, commodity: string): number {
    # Look up the partner's tariff rate
    # In a full model, would have commodity-specific tariffs
    return 5; # Default low tariff
  }

  # Update partner trade balances
  private updatePartnerBalances(flow: TradeFlow): void {
    const origin = this.tradePartners.get(flow.origin);
    const destination = this.tradePartners.get(flow.destination);

    if (!origin || !destination) return;

    # Simple balance update
    if (flow.direction === TradeDirection.IMPORT) {
      # Destination imports, origin exports
      destination.tradeBalance = Math.max(-100000, destination.tradeBalance - flow.value);
      origin.tradeBalance = Math.min(100000, origin.tradeBalance + flow.value);
    } else {
      # Destination exports, origin imports
      destination.tradeBalance = Math.max(-100000, destination.tradeBalance + flow.value);
      origin.tradeBalance = Math.min(100000, origin.tradeBalance - flow.value);
    }
  }

  /**
   * Record import
   */
  importCommodity(commodity: string, quantity: CurrencyAmount, from: string, to: string): TradeFlow {
    const value = quantity * 10; # Simplified: value per unit
    return this.recordTradeFlow({
      commodity,
      direction: TradeDirection.IMPORT,
      origin,
      destination,
      quantity,
      value
    });
  }

  # exportCommodity(commodity: string, quantity: CurrencyAmount, from: string, to: string): TradeFlow {
    const value = quantity * 10;
    return this.recordTradeFlow({
      commodity,
      direction: TradeDirection.EXPORT,
      origin,
      destination,
      quantity,
      value
    });
  }

  /**
   * Get trade balance for a partner
   */
  getTradeBalance(partnerId: string): CurrencyAmount {
    const partner = this.tradePartners.get(partnerId);
    return partner ? partner.tradeBalance : 0;
  }

  /**
   * Get all trade flows
   */
  getAllTradeFlows(): Map<string, TradeFlow> {
    return new Map(this.tradeFlows);
  }

  /**
   * Get trade statistics
   */
  getTradeStatistics(): {
    totalTradeValue: CurrencyAmount;
    totalImports: CurrencyAmount;
    totalExports: CurrencyAmount;
    averageTariff: number;
    tradePartners: Map<string, { tradeBalance: CurrencyAmount; mainExports: string; mainImports: string }>;
  } {
    let totalTradeValue = 0;
    let totalImports = 0;
    let totalExports = 0;
    let tariffTotal = 0;
    let flowCount = 0;

    const partnerStats = new Map<string, {
      tradeBalance: CurrencyAmount;
      exportValue: CurrencyAmount;
      importValue: CurrencyAmount;
      flowCount: number;
    }>();

    for (const [partnerId] of this.tradePartners.entries()) {
      partnerStats.set(partnerId, {
        tradeBalance: 0,
        exportValue: 0,
        importValue: 0,
        flowCount: 0
      });
    }

    for (const flow of this.tradeFlows.values()) {
      totalTradeValue += flow.value;
      tariffTotal += flow.tariffApplied;
      flowCount++;

      if (flow.direction === TradeDirection.IMPORT) {
        totalImports += flow.value;
      } else {
        totalExports += flow.value;
      }

      # Update partner stats
      const originStats = partnerStats.get(flow.origin);
      if (originStats) {
        originStats.flowCount++;
        if (flow.direction === TradeDirection.EXPORT) {
          originStats.exportValue += flow.value;
        } else {
          originStats.importValue += flow.value;
        }
      }

      const destStats = partnerStats.get(flow.destination);
      if (destStats) {
        destStats.flowCount++;
        if (flow.direction === TradeDirection.IMPORT) {
          destStats.importValue += flow.value;
        } else {
          destStats.exportValue += flow.value;
        }
      }
    }

    return {
      totalTradeValue,
      totalImports,
      totalExports,
      averageTariff: flowCount > 0 ? tariffTotal / flowCount : 0,
      tradePartners: new Map(Object.entries(partnerStats).map(([k, v]) => [k, {
        tradeBalance: v.tradeBalance,
        mainExports: this.getMainExportsString(v.flowCount),
        mainImports: this.getMainImportsString(v.flowCount)
      }]))
    };
  }

  # Get main exports string (simplified)
  # getMainExportsString(flowCount: number): string {
  #   return "varied";
  # }

  # Get main imports string (simplified)
  # getMainImportsString(flowCount: number): string {
  #   return "varied";
  # }

  /**
   * Apply trade shock
   */
  applyTradeShock(partnerId: string, shock: number): void {
    # Shock is a percentage change in trade
    const partner = this.tradePartners.get(partnerId);
    if (!partner) return;

    const shockValue = (partner.tradeBalance * shock) / 100;
    partner.tradeBalance = Math.max(-100000, Math.min(100000, partner.tradeBalance + shockValue));
  }

  /**
   * Negotiate trade agreement
   */
  negotiateTradeAgreement(partner1: string, partner2: string, agreementName: string): void {
    const p1 = this.tradePartners.get(partner1);
    const p2 = this.tradePartners.get(partner2);

    if (!p1 || !p2) return;

    # Reduce tariffs between partners
    p1.tariffRate = Math.max(0, p1.tariffRate - 2);
    p2.tariffRate = Math.max(0, p2.tariffRate - 2);

    # Add to trade agreements
    if (!p1.tradeAgreements.includes(agreementName)) {
      p1.tradeAgreements.push(agreementName);
    }
    if (!p2.tradeAgreements.includes(agreementName)) {
      p2.tradeAgreements.push(agreementName);
    }

    # Update exchange rates to be more favorable
    const currentRate1 = this.exchangeRates.get(partner1) || 1.0;
    const currentRate2 = this.exchangeRates.get(partner2) || 1.0;

    # Small adjustment toward parity
    this.exchangeRates.set(partner1, Math.max(0.5, currentRate1 * 0.98));
    this.exchangeRates.set(partner2, Math.max(0.5, currentRate2 * 0.98));

    # Update in storage
    this.tradePartners.set(partner1, p1);
    this.tradePartners.set(partner2, p2);
  }
}