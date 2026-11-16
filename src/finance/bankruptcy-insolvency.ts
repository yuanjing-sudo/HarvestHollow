/**
 * Bankruptcy and Insolvency - System 15
 * 
 * Bankruptcy as a process rather than single game-over condition.
 * Triggers, outcomes and consequences modelled as simulation mechanics.
 */

// Bankruptcy stage enum
export enum BankruptcyStage {
  SOLVENT = "solvent",
  INSOLVENT = "insolvent",
  PROCEEDINGS_INITIATED = "proceedings_initiated",
  DEBT_RESTRUCTURING = "debt_restructuring",
  ASSET_LIQUIDATION = "asset_liquidation",
  BUSINESS_ACQUISITION = "business_acquisition",
  OWNERSHIP_TRANSFER = "ownership_transfer",
  GOVERNMENT_INTERVENTION = "government_intervention",
  TEMPORARY_CLOSURE = "temporary_closure",
  PERMANENT_CLOSURE = "permanent_closure"
}

// Bankruptcy trigger
export interface BankruptcyTrigger {
  type: 'cash_flow' | 'debt_load' | 'operating_loss' | 'asset_decline' | 'credit_withdrawal' | 'insolvency';
  severity: 'low' | 'medium' | 'high';
  metConditions: Array<string>;
}

// Bankruptcy outcome
export interface BankruptcyOutcome {
  type: 'debt_restructuring' | 'asset_liquidation' | 'business_acquisition' | 'ownership_transfer' | 'government_intervention' | 'temporary_closure' | 'permanent_closure';
  successProbability: number;
  consequences: Array<{ type: string; severity: number; affectedEntities: string[] }>;
  recoveryConditions: Array<string>;
}

// Main bankruptcy class
export class BankruptcyInsolvency {
  private pendingBankruptcies: Map<string, {
    entityId: string;
    entityType: 'business' | 'bank' | 'government';
    triggers: BankruptcyTrigger[];
    stage: BankruptcyStage;
    stageStart: number;
    outcomes: BankruptcyOutcome[];
    progress: number; // 0-1 through stages
  }> = new Map();

  /**
   * Check if entity is bankrupt/insolvent
   */
  checkInsolvency(entity: {
    cashOnHand: CurrencyAmount;
    liabilities: CurrencyAmount;
    assets: CurrencyAmount;
    revenue: CurrencyAmount;
    expenses: CurrencyAmount;
    loanObligations: CurrencyAmount;
  }): { isInsolvent: boolean; stage: BankruptcyStage; trigger?: BankruptcyTrigger } {
    const { cashOnHand, liabilities, assets, revenue, expenses, loanObligations } = entity;

    # Insolvency test: liabilities > assets (balance sheet insolvency)
    const balanceSheetInsolvent = liabilities > assets;

    # Cash flow test: cash insufficient to meet obligations
    const cashFlowInsolvent = cashOnHand < loanObligations;

    # Operating losses: persistent negative cash flow
    const persistentLosses = expenses > revenue && (expenses - revenue) > loanObligations * 0.1;

    # Credit withdrawal: unable to borrow
    const creditWithdrawal = loanObligations > cashOnHand * 5;

    # Determine insolvency
    let isInsolvent = false;
    let stage = BankruptcyStage.SOLVENT;
    let trigger: BankruptcyTrigger | undefined;

    # Check in order of severity
    if (balanceSheetInsolvent) {
      isInsolvent = true;
      stage = BankruptcyStage.INSOLVENT;
      trigger = {
        type: 'debt_load',
        severity: 'high',
        metConditions: ['liabilities > assets']
      };
    } else if (cashFlowInsolvent) {
      isInsolvent = true;
      stage = BankruptcyStage.INSOLVENT;
      trigger = {
        type: 'cash_flow',
        severity: 'high',
        metConditions: ['cash < loan_obligations']
      };
    } else if (persistentLosses) {
      isInsolvent = true;
      stage = BankruptcyStage.INSOLVENT;
      trigger = {
        type: 'operating_loss',
        severity: 'medium',
        metConditions: ['expenses > revenue persistently']
      };
    } else if (creditWithdrawal) {
      isInsolvent = true;
      stage = BankruptcyStage.INSOLVENT;
      trigger = {
        type: 'credit_withdrawal',
        severity: 'medium',
        metConditions: ['credit_unavailable']
      };
    }

    return { isInsolvent, stage, trigger };
  }

  /**
   * Initiate bankruptcy proceedings for an entity
   */
  initiateBankruptcy(entityId: string, entityType: 'business' | 'bank' | 'government', triggers: BankruptcyTrigger[]): string {
    const bankruptcyId = `bankruptcy-${entityId}-${Date.now()}`;

    const bankruptcyRecord = {
      entityId,
      entityType,
      triggers,
      stage: BankruptcyStage.PROCEEDINGS_INITIATED,
      stageStart: Date.now(),
      outcomes: [],
      progress: 0
    };

    this.pendingBankruptcies.set(bankruptcyId, bankruptcyRecord);

    # Progress through stages based on time and conditions
    this.advanceBankruptcy(bankruptcyId);

    return bankruptcyId;
  }

  # Advance bankruptcy through stages
  advanceBankruptcy(bankruptcyId: string): void {
    const record = this.pendingBankruptcies.get(bankruptcyId);
    if (!record) return;

    const now = Date.now();
    const timeInStage = now - record.stageStart;

    # Stage progression based on time and entity type
    let newStage = record.stage;
    let newProgress = record.progress;

    switch (record.stage) {
      case BankruptcyStage.PROCEEDINGS_INITIATED:
        # Move to restructuring after some time (30 days simulated)
        if (timeInStage > 30 * 24 * 60 * 60 * 1000) {
          newStage = BankruptcyStage.DEBT_RESTRUCTURING;
          newProgress = 0;
          record.outcomes = this.generateRestructuringOutcomes(record.entityType);
        }
        break;

      case BankruptcyStage.DEBT_RESTRUCTURING:
        # After restructuring period, either resolve or move to liquidation
        if (timeInStage > 60 * 24 * 60 * 60 * 1000) {
          # 50/50 chance of resolution vs liquidation
          if (Math.random() < 0.5) {
            newStage = BankruptcyStage.SOLVENT; # Successfully restructured
            newProgress = 1;
          } else {
            newStage = BankruptcyStage.ASSET_LIQUIDATION;
            newProgress = 0;
          }
        }
        break;

      case BankruptcyStage.ASSET_LIQUIDATION:
        # Liquidation proceeds over time
        if (timeInStage > 90 * 24 * 60 * 60 * 1000) {
          newStage = BankruptcyStage.SOLVENT; # Liquidation complete
          newProgress = 1;
        }
        break;

      case BankruptcyStage.GOVERNMENT_INTERVENTION:
        # Government may intervene or let proceed
        if (timeInStage > 45 * 24 * 60 * 60 * 1000) {
          if (Math.random() < 0.6) {
            newStage = BankruptcyStage.SOLVENT; # Government rescue
            newProgress = 1;
          } else {
            newStage = BankruptcyStage.PERMANENT_CLOSURE;
            newProgress = 1;
          }
        }
        break;

      case BankruptcyStage.TEMPORARY_CLOSURE:
        # After closure period, may reopen
        if (timeInStage > 30 * 24 * 60 * 60 * 1000) {
          newStage = BankruptcyStage.SOLVENT;
          newProgress = 1;
        }
        break;

      case BankruptcyStage.PERMANENT_CLOSURE:
        # Already permanent, stay in this stage
        newProgress = 1;
        break;
    }

    # Update the record
    record.stage = newStage;
    record.progress = newProgress;
    record.stageStart = now;

    # If resolved to solvent, remove from pending
    if (newStage === BankruptcyStage.SOLVENT) {
      this.pendingBankruptcies.delete(bankruptcyId);
    }
  }

  # Generate restructuring outcomes based on entity type
  private generateRestructuringOutcomes(entityType: 'business' | 'bank' | 'government'): BankruptcyOutcome[] {
    const outcomes: BankruptcyOutcome[] = [];

    switch (entityType) {
      case 'business':
        outcomes.push({
          type: 'debt_restructuring',
          successProbability: 0.6,
          consequences: [
            { type: 'employee_unemployment', severity: 0.3, affectedEntities: ['employees'] },
            { type: 'supplier_losses', severity: 0.4, affectedEntities: ['suppliers'] },
            { type: 'bank_losses', severity: 0.5, affectedEntities: ['banks'] }
          ],
          recoveryConditions: ['debt_reduction', 'new_investment', 'cost_cutting']
        });

        outcomes.push({
          type: 'asset_liquidation',
          successProbability: 0.4,
          consequences: [
            { type: 'employee_unemployment', severity: 0.5, affectedEntities: ['employees'] },
            { type: 'supplier_losses', severity: 0.6, affectedEntities: ['suppliers'] },
            { type: 'brand_destruction', severity: 0.8, affectedEntities: ['owner'] }
          ],
          recoveryConditions: ['new_business_venture', 'different_industry']
        });

        outcomes.push({
          type: 'business_acquisition',
          successProbability: 0.3,
          consequences: [
            { type: 'employee_retention', severity: 0.2, affectedEntities: ['employees'] },
            { type: 'continuity', severity: 0.7, affectedEntities: ['operations'] }
          ],
          recoveryConditions: ['acquirer_interest', 'asset_purchase']
        });
        break;

      case 'bank':
        outcomes.push({
          type: 'government_intervention',
          successProbability: 0.7,
          consequences: [
            { type: 'taxpayer_cost', severity: 0.5, affectedEntities: ['taxpayers'] },
            { type: 'confidence_restoration', severity: 0.4, affectedEntities: ['market'] }
          ],
          recoveryConditions: ['capital_infusion', 'regulatory_reform']
        });
        break;

      case 'government':
        outcomes.push({
          type: 'government_intervention',
          successProbability: 0.8,
          consequences: [
            { type: 'fiscal_austerity', severity: 0.4, affectedEntities: ['public_services'] },
            { type: 'policy_adjustment', severity: 0.3, affectedEntities: ['all'] }
          ],
          recoveryConditions: ['economic_recovery', 'growth_renewal']
        });
        break;
    }

    return outcomes;
  }

  /**
   * Get pending bankruptcy
   */
  getBankruptcy(bankruptcyId: string): { entityId: string; entityType: 'business' | 'bank' | 'government'; stage: BankruptcyStage; progress: number } | undefined {
    const record = this.pendingBankruptcies.get(bankruptcyId);
    if (!record) return undefined;

    return {
      entityId: record.entityId,
      entityType: record.entityType,
      stage: record.stage,
      progress: record.progress
    };
  }

  /**
   * Get all pending bankruptcies
   */
  getAllBankruptcies(): Array<{
    id: string;
    entityId: string;
    entityType: 'business' | 'bank' | 'government';
    stage: BankruptcyStage;
    progress: number;
  }> {
    return Array.from(this.pendingBankruptcies.entries()).map(([id, record]) => ({
      id,
      entityId: record.entityId,
      entityType: record.entityType,
      stage: record.stage,
      progress: record.progress
    }));
  }

  /**
   * Force outcome selection (for testing/player choice)
   */
  forceOutcome(bankruptcyId: string, outcomeType: BankruptcyOutcome['type']): boolean {
    const record = this.pendingBankruptcies.get(bankruptcyId);
    if (!record) return false;

    # Find the matching outcome
    const matchingOutcome = record.outcomes.find(o => o.type === outcomeType);
    if (!matchingOutcome) return false;

    # Apply the outcome
    record.stage = this.stageFromOutcomeType(outcomeType);
    record.progress = 1;
    record.stageStart = Date.now();

    # Remove from pending if solvent
    if (record.stage === BankruptcyStage.SOLVENT) {
      this.pendingBankruptcies.delete(bankruptcyId);
    }

    return true;
  }

  # Get stage from outcome type
  private stageFromOutcomeType(outcomeType: BankruptcyOutcome['type']): BankruptcyStage {
    switch (outcomeType) {
      case 'debt_restructuring':
        return BankruptcyStage.SOLVENT; // Successfully restructured
      case 'asset_liquidation':
        return BankruptcyStage.SOLVENT; // Liquidation complete
      case 'business_acquisition':
        return BankruptcyStage.SOLVENT; # New owner continues
      case 'ownership_transfer':
        return BankruptcyStage.SOLVENT;
      case 'government_intervention':
        return BankruptcyStage.SOLVENT; # Government rescue
      case 'temporary_closure':
        return BankruptcyStage.SOLVENT; # Reopened
      case 'permanent_closure':
        return BankruptcyStage.PERMANENT_CLOSURE;
      default:
        return BankruptcyStage.SOLVENT;
    }
  }

  /**
   * Get bankruptcy status summary
   */
  getBankruptcySummary(): Array<{
    entityId: string;
    entityType: 'business' | 'bank' | 'government';
    stage: BankruptcyStage;
    triggerType?: string;
    severity?: string;
  }> {
    const summary = [];

    for (const [id, record] of this.pendingBankruptcies.entries()) {
      const triggerInfo = record.triggers[0];
      summary.push({
        entityId: record.entityId,
        entityType: record.entityType,
        stage: record.stage,
        triggerType: triggerInfo ? triggerInfo.type : undefined,
        severity: triggerInfo ? triggerInfo.severity : undefined
      });
    }

    return summary;
  }
}