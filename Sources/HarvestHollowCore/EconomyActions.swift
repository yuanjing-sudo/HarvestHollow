import Foundation

extension ValleyEconomy {
    @discardableResult
    public mutating func setTaxRate(_ value: Double) -> Bool {
        guard isUnlocked(.taxationSubsidies) else { return false }
        taxRate = hhClamp(value, 0.05, 0.4)
        lastPolicyDay = day
        return true
    }

    @discardableResult
    public mutating func setSubsidyRate(_ value: Double) -> Bool {
        guard isUnlocked(.taxationSubsidies) else { return false }
        subsidyRate = hhClamp(value, 0, 0.3)
        lastPolicyDay = day
        return true
    }

    @discardableResult
    public mutating func setPublicSpending(_ value: Double) -> Bool {
        guard isUnlocked(.infrastructureServices) else { return false }
        publicSpending = hhClamp(value, 0.05, 0.4)
        lastPolicyDay = day
        return true
    }

    @discardableResult
    public mutating func setTariffRate(_ value: Double) -> Bool {
        guard isUnlocked(.importsExports) else { return false }
        tariffRate = hhClamp(value, 0, 0.35)
        lastPolicyDay = day
        return true
    }

    @discardableResult
    public mutating func setInterestRate(_ value: Double) -> Bool {
        guard isUnlocked(.currencyInterest) else { return false }
        interestRate = hhClamp(value, -0.01, 0.25)
        lastPolicyDay = day
        return true
    }

    @discardableResult
    public mutating func invest(_ investment: EconomyInvestment) -> Bool {
        guard lastKnownLevel >= investment.minimumLevel else { return false }
        switch investment {
        case .irrigation:
            irrigation = hhClamp(irrigation + 0.12, 0.05, 1)
            waterAvailability = hhClamp(waterAvailability + 0.04, 0.03, 1)
            farmYield = hhClamp(farmYield + 0.04, 0.05, 1.6)
        case .renewableEnergy:
            renewableShare = hhClamp(renewableShare + 0.12, 0.02, 1)
            energyCapacity = hhClamp(energyCapacity + 0.08, 0.05, 1.3)
            pollution = hhClamp(pollution - 0.03, 0.01, 1)
        case .roads:
            infrastructure = hhClamp(infrastructure + 0.1, 0.05, 1)
            logistics = hhClamp(logistics + 0.08, 0.05, 1)
            exports += 3
        case .school:
            education = hhClamp(education + 0.08, 0.05, 1)
            productivity = hhClamp(productivity + 0.02, 0.05, 1.6)
            researchPoints += 4
        case .clinic:
            health = hhClamp(health + 0.08, 0.1, 1)
            happiness = hhClamp(happiness + 0.03, 0.05, 1)
            populationMomentum = hhClamp(populationMomentum + 0.002, -0.01, 0.01)
        case .research:
            researchPoints += 14
            technology = hhClamp(technology + 0.03, 0.05, 1.5)
        case .cleanup:
            pollution = hhClamp(pollution - 0.1, 0.01, 1)
            biodiversity = hhClamp(biodiversity + 0.05, 0.05, 1)
            health = hhClamp(health + 0.02, 0.1, 1)
        case .digitalNetwork:
            productivity = hhClamp(productivity + 0.03, 0.05, 1.6)
            logistics = hhClamp(logistics + 0.06, 0.05, 1)
            publicServices = hhClamp(publicServices + 0.04, 0.05, 1)
            for index in aiBusinesses.indices {
                aiBusinesses[index].technology = hhClamp(
                    aiBusinesses[index].technology + 0.04,
                    0.05, 1.3
                )
            }
        }
        return true
    }

    public func canBorrow(_ amount: Double) -> Bool {
        guard isUnlocked(.loansCreditDebt) else { return false }
        guard amount >= 50, amount <= 1000 else { return false }
        guard creditScore >= 450 else { return false }
        return totalLoanBalance + amount <= max(120, gdp * 0.75)
    }

    @discardableResult
    public mutating func takeLoan(
        amount: Double,
        purpose: String,
        day: Int
    ) -> EconomyLoan? {
        guard canBorrow(amount) else { return nil }
        let loan = EconomyLoan(
            principal: amount,
            balance: amount,
            annualRate: max(0.03, interestRate + 0.045),
            purpose: purpose,
            takenDay: day
        )
        loans.append(loan)
        publicDebt += amount * 0.15
        lastPolicyDay = day
        return loan
    }

    /// Returns the amount actually repaid.
    @discardableResult
    public mutating func repayLoan(id: UUID, amount: Double) -> Double {
        guard let index = loans.firstIndex(where: { $0.id == id }) else {
            return 0
        }
        let payment = min(amount, loans[index].balance)
        guard payment > 0 else { return 0 }
        loans[index].balance -= payment
        if loans[index].balance < 0.5 {
            loans.remove(at: index)
        }
        creditScore = min(850, creditScore + 2)
        return payment
    }
}
