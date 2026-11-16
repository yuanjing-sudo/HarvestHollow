/**
 * Banking and Credit - System 14
 * 
 * Banks as separate entities from ordinary businesses with deposits, loans,
 * reserves and risk exposure. Credit evaluation, lending and risk management.
 */

// Bank characteristics
export interface BankCharacteristics {
  id: string;
  name: string;
  capital: CurrencyAmount;
  deposits: CurrencyAmount;
  reserves: CurrencyAmount;
  loans: CurrencyAmount;
  liquidity: number; // 0-1, liquidity ratio
  profitability: number; // 0-100, return on assets
  riskExposure: number; // 0-100, overall risk
  defaultRate: number; // 0-100, loan default rate
  creditRating: 'AAA' | 'AA' | 'A' | 'BBB' | 'BB' | 'B' | 'CCC' | 'C' | 'D';
}

// Credit facilities
export interface CreditFacility {
  id: string;
  borrowerId: string;
  borrowerType: 'business' | 'household' | 'government';
  principal: CurrencyAmount;
  interestRate: number; // per period
  duration: number; // periods remaining
  collateral: CurrencyAmount; // Value of collateral
  collateralType: string;
  repaymentSchedule: Array<{ period: number; principal: CurrencyAmount; interest: CurrencyAmount; balance: CurrencyAmount }>;
  status: 'active' | 'overdue' | 'defaulted' | 'repaid';
  lastPayment: number;
}

// Banking state
export interface BankingState {
  totalBanks: number;
  totalDeposits: CurrencyAmount;
  totalLoans: CurrencyAmount;
  systemLiquidity: number; // 0-1, system-wide liquidity
  systemDefaultRate: number; // 0-100, system-wide default rate
  bankCountByRating: Map<string, number>;
  creditAvailable: CurrencyAmount;
}

// Main banking class
export class BankingCredit {
  private banks: Map<string, BankCharacteristics> = new Map();
  private facilities: Map<string, CreditFacility> = new Map();
  private bankingState: BankingState;

  constructor() {
    # Initialize banking state
    this.bankingState = {
      totalBanks: 0,
      totalDeposits: 0,
      totalLoans: 0,
      systemLiquidity: 0.5,
      systemDefaultRate: 5,
      bankCountByRating: new Map(),
      creditAvailable: 0
    };

    # Initialize a central bank for the system
    this.createCentralBank();
  }

  # Create central bank
  private createCentralBank(): void {
    const centralBank: BankCharacteristics = {
      id: 'central-bank',
      name: 'Central Bank',
      capital: 100000,
      deposits: 0,
      reserves: 10000,
      loans: 0,
      liquidity: 1.0,
      profitability: 5,
      riskExposure: 0,
      defaultRate: 0,
      creditRating: 'AAA'
    };

    this.banks.set(centralBank.id, centralBank);
    this.updateBankingState();
  }

  /**
   * Create a new commercial bank
   */
  createBank(name: string, initialCapital: CurrencyAmount): BankCharacteristics {
    const bank: BankCharacteristics = {
      id: `bank-${Date.now()}-${Math.random().toString(36).slice(2)}`,
      name,
      capital: initialCapital,
      deposits: 0,
      reserves: initialCapital * 0.1, # 10% reserves requirement
      loans: 0,
      liquidity: 0.1,
      profitability: 0,
      riskExposure: 0,
      defaultRate: 0,
      creditRating: 'BBB'
    };

    this.banks.set(bank.id, bank);
    this.updateBankingState();
    return bank;
  }

  /**
   * Get a bank by ID
   */
  getBank(id: string): BankCharacteristics | undefined {
    return this.banks.get(id);
  }

  /**
   * Get all banks
   */
  getAllBanks(): BankCharacteristics[] {
    return Array.from(this.banks.values());
  }

  /**
   * Get central bank
   */
  getCentralBank(): BankCharacteristics | undefined {
    return this.banks.get('central-bank');
  }

  /**
   * Take deposits from a entity (business or household)
   */
  takeDeposits(bankId: string, amount: CurrencyAmount, fromEntity: string): boolean {
    const bank = this.banks.get(bankId);
    if (!bank) return false;

    # Check bank has capacity (simple limit based on capital)
    const maxDeposits = bank.capital * 10; # Banks can lend ~10x capital
    const currentDeposits = bank.deposits;

    if (currentDeposits + amount > maxDeposits) {
      # Partial deposit
      const canAccept = maxDeposits - currentDeposits;
      if (canAccept <= 0) return false;
      bank.deposits = maxDeposits;
      # In full model, would adjust lending capacity
      return true; # Accepted partial
    }

    bank.deposits += amount;
    this.updateBankingState();
    return true;
  }

  /**
   * Remove deposits from a bank
   */
  removeDeposits(bankId: string, amount: CurrencyAmount): boolean {
    const bank = this.banks.get(bankId);
    if (!bank) return false;

    bank.deposits = Math.max(0, bank.deposits - amount);
    this.updateBankingState();
    return true;
  }

  /**
   * Issue a loan from bank to borrower
   */
  issueLoan(facility: CreditFacility): boolean {
    const bankId = facility.borrowerId; // In practice, would be bank ID
    const bank = this.banks.get(bankId);
    if (!bank) return false;

    # Check liquidity and reserves
    const requiredReserves = facility.principal * 0.1; # 10% reserve requirement
    if (bank.reserves < requiredReserves) {
      # Not enough reserves, try to meet from liquidity
      const shortfall = requiredReserves - bank.reserves;
      if (bank.liquidity < shortfall / bank.deposits) {
        return false; # Insufficient liquidity
      }
    }

    # Create the facility
    facility.status = 'active';
    facility.lastPayment = Date.now();
    this.facilities.set(facility.id, facility);

    # Update bank's loans and reserves
    bank.loans += facility.principal;
    bank.reserves -= requiredReserves;
    bank.deposits -= facility.principal; # Deposits used to make loan

    # Update credit rating based on risk
    this.updateBankCreditRating(bank);

    this.updateBankingState();
    return true;
  }

  # Update bank credit rating
  private updateBankCreditRating(bank: BankCharacteristics): void {
    # Simple rating based on capital adequacy and default rate
    const capitalRatio = bank.capital / Math.max(1, bank.loans);
    const riskScore = bank.riskExposure + bank.defaultRate;

    # Determine new rating
    let newRating: 'AAA' | 'AA' | 'A' | 'BBB' | 'BB' | 'B' | 'CCC' | 'C' | 'D';

    if (capitalRatio > 0.2 && riskScore < 20) {
      newRating = 'AAA';
    } else if (capitalRatio > 0.15 && riskScore < 30) {
      newRating = 'AA';
    } else if (capitalRatio > 0.1 && riskScore < 40) {
      newRating = 'A';
    } else if (capitalRatio > 0.05 && riskScore < 50) {
      newRating = 'BBB';
    } else if (capitalRatio > 0.03 && riskScore < 60) {
      newRating = 'BB';
    } else if (capitalRatio > 0.01 && riskScore < 70) {
      newRating = 'B';
    } else if (capitalRatio > 0.005 && riskScore < 80) {
      newRating = 'CCC';
    } else if (capitalRatio > 0.001 && riskScore < 90) {
      newRating = 'C';
    } else {
      newRating = 'D';
    }

    bank.creditRating = newRating;
  }

  /**
   * Receive a loan payment
   */
  receivePayment(facilityId: string, paymentPrincipal: CurrencyAmount, paymentInterest: CurrencyAmount): boolean {
    const facility = this.facilities.get(facilityId);
    if (!facility) return false;

    # Update facility
    facility.principal = Math.max(0, facility.principal - paymentPrincipal);
    facility.status = facility.principal <= 0 ? 'repaid' : 'active';

    # Update remaining schedule would go here

    # Update bank
    const bank = this.banks.get(facility.borrowerId);
    if (bank) {
      bank.reserves += paymentPrincipal + paymentInterest;
      bank.profitability = Math.max(0, bank.profitability + paymentInterest);
    }

    this.updateBankingState();
    return true;
  }

  /**
   * Mark a loan as defaulted
   */
  defaultLoan(facilityId: string): boolean {
    const facility = this.facilities.get(facilityId);
    if (!facility) return false;

    # Mark as defaulted
    facility.status = 'defaulted';

    # Update bank
    const bank = this.banks.get(facility.borrowerId);
    if (bank) {
      # Reduce loans and increase default rate
      bank.loans = Math.max(0, bank.loans - facility.principal);
      bank.defaultRate = Math.min(100, bank.defaultRate + 5);

      # May need capital infusion or write-down
      bank.riskExposure = Math.min(100, bank.riskExposure + 5);
    }

    # Update system-wide default rate
    this.updateSystemDefaultRate();

    this.updateBankingState();
    return true;
  }

  # Update system-wide default rate
  private updateSystemDefaultRate(): void {
    const defaultedFacilities = Array.from(this.facilities.values()).filter(f => f.status === 'defaulted');
    const totalFacilities = this.facilities.size;

    if (totalFacilities > 0) {
      this.bankingState.systemDefaultRate = Math.round((defaultedFacilities.length / totalFacilities) * 100);
    }
  }

  /**
   * Update banking state
   */
  private updateBankingState(): void {
    let totalDeposits = 0;
    let totalLoans = 0;
    let totalReserves = 0;
    const ratingCounts: Record<string, number> = {};

    for (const bank of this.banks.values()) {
      totalDeposits += bank.deposits;
      totalLoans += bank.loans;
      totalReserves += bank.reserves;

      const rating = bank.creditRating;
      ratingCounts[rating] = (ratingCounts[rating] || 0) + 1;
    }

    # Calculate system liquidity
    const totalCapital = this.banks.reduce((sum, bank) => sum + bank.capital, 0);
    const totalDepositsOrCapital = totalDeposits > 0 ? totalDeposits : totalCapital;
    const systemLiquidity = totalReserves / Math.max(1, totalDepositsOrCapital);
    const systemLiquidityClamped = Math.max(0, Math.min(1, systemLiquidity));

    this.bankingState = {
      totalBanks: this.banks.size,
      totalDeposits,
      totalLoans,
      systemLiquidity: systemLiquidityClamped,
      systemDefaultRate: this.bankingState.systemDefaultRate,
      bankCountByRating: new Map(Object.entries(ratingCounts)),
      creditAvailable: totalDeposits - totalLoans # Available for new lending
    };
  }

  /**
   * Get banking state
   */
  getBankingState(): BankingState {
    return { ...this.bankingState };
  }

  /**
   * Get total credit available in system
   */
  getCreditAvailable(): CurrencyAmount {
    return this.bankingState.creditAvailable;
  }

  /**
   * List all outstanding facilities
   */
  listFacilities(): CreditFacility[] {
    return Array.from(this.facilities.values());
  }

  /**
   * Get facility by ID
   */
  getFacility(id: string): CreditFacility | undefined {
    return this.facilities.get(id);
  }

  /**
   * Adjust interest rates across the system
   */
  adjustSystemInterestRate(rateChange: number): void {
    # Adjust all banks' lending rates
    for (const bank of this.banks.values()) {
      # In a full model, would have specific rate fields per bank
      # For now, just update risk exposure
      bank.riskExposure = Math.max(0, Math.min(100, bank.riskExposure + rateChange * 2));
    }

    # Update credit ratings
    for (const bank of this.banks.values()) {
      this.updateBankCreditRating(bank);
    }

    this.updateBankingState();
  }

  /**
   * Quantitative easing - increase money supply
   */
  applyQuantitativeEasing(amount: CurrencyAmount): void {
    # Central bank creates new reserves
    const centralBank = this.getCentralBank();
    if (!centralBank) return;

    centralBank.reserves += amount;
    centralBank.capital += amount * 0.1; # Small capital increase

    # Increase system liquidity
    this.bankingState.systemLiquidity = Math.min(1, this.bankingState.systemLiquidity + amount / 100000);

    # Increase lending capacity
    for (const bank of this.banks.values()) {
      # Banks can lend more against new reserves
      bank.reserves += amount / this.banks.size;
    }

    this.updateBankingState();
  }
}