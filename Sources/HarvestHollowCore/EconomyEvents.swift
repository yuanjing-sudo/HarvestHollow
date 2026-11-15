import Foundation

extension ValleyEconomy {
    /// Firms respond to demand, wages, taxes, credit, and competition. Weak
    /// firms shrink; healthy firms hire and invest; new firms appear when
    /// confidence and demand are strong enough.
    mutating func updateBusinesses(
        inputs: EconomyInputs,
        rng: inout GameRNG
    ) -> (jobs: Int, output: Double) {
        var jobs = 0
        var output = 0.0
        var failed: [String] = []
        let demandSignal = hhClamp(demand / max(1, supply), 0.5, 1.6)

        for index in aiBusinesses.indices {
            var firm = aiBusinesses[index]
            let wageBill = Double(firm.employees) * averageWage * 0.5
            let revenue = firm.output * 6.5 * demandSignal * (1 - taxRate * 0.5)
            let capitalCost = firm.capital * interestRate / 12
            let pollutionCost = firm.pollution * 12
            let profit = revenue - wageBill - capitalCost - pollutionCost

            firm.capital = max(1, firm.capital + profit * 0.12)
            firm.productivity = hhClamp(
                firm.productivity
                    + profit * 0.0004
                    + education * 0.0004
                    + technology * 0.0002,
                0.1, 1.1
            )
            firm.technology = hhClamp(
                firm.technology
                    + Double(researchLevel) * 0.0003
                    + profit * 0.00015,
                0.05, 1.3
            )
            if profit > 8, demandSignal > 1.02 {
                firm.employees = min(12, firm.employees + 1)
            } else if profit < -4, firm.employees > 1 {
                firm.employees -= 1
            }
            firm.price = hhClamp(
                firm.price * (1 + inflation * 0.01 - competition * 0.003),
                0.5, 2.2
            )
            firm.mood = hhClamp(
                firm.mood + profit * 0.001 - taxRate * 0.001,
                0, 1
            )
            firm.pollution = hhClamp(
                firm.pollution + firm.output * 0.0004 * (1 - renewableShare),
                0, 1
            )
            aiBusinesses[index] = firm
            jobs += firm.employees
            output += firm.output

            if firm.capital < 2.5,
               tier.rawValue >= EconomyTier.district.rawValue,
               rng.chance(0.06) {
                failed.append(firm.name)
            }
        }

        if !failed.isEmpty {
            aiBusinesses.removeAll { failed.contains($0.name) }
        }

        if aiBusinesses.count < tier.maxFirms,
           rng.chance(0.02 + consumerConfidence * 0.02) {
            let eligible = AIBusinessKind.allCases.filter {
                $0.minimumTier.rawValue <= tier.rawValue
            }
            if !eligible.isEmpty {
                let kind = eligible[rng.int(in: 0...(eligible.count - 1))]
                let name = "\(kind.title) \(aiBusinesses.count + 1)"
                aiBusinesses.append(AIBusiness(
                    name: name,
                    kind: kind,
                    employees: 1 + rng.int(in: 0...2),
                    capital: 14 + rng.double01() * 14,
                    productivity: 0.28 + rng.double01() * 0.18,
                    technology: 0.12 + rng.double01() * 0.12,
                    foundedDay: day
                ))
            }
        }

        return (jobs, output)
    }

    mutating func tickElection(rng: inout GameRNG) -> EconomyEventRecord? {
        electionInDays -= 1
        guard electionInDays <= 0 else { return nil }

        let oldParty = rulingParty
        let greenWeight = 0.18 + sustainability * 0.24 + education * 0.08
        let merchantWeight = 0.18 + tradeBalance / 60 + (1 - taxRate) * 0.2
        let workerWeight = 0.18 + (1 - unemployment) * 0.12 + poverty * 0.18
        let stewardWeight = 0.18 + politicalStability * 0.24
        let total = greenWeight + merchantWeight + workerWeight + stewardWeight
        let roll = rng.double01() * total

        if roll < greenWeight {
            rulingParty = .green
        } else if roll < greenWeight + merchantWeight {
            rulingParty = .merchants
        } else if roll < greenWeight + merchantWeight + workerWeight {
            rulingParty = .workers
        } else {
            rulingParty = .stewards
        }

        taxRate = hhClamp(taxRate * 0.6 + rulingParty.taxBias * 0.4, 0.05, 0.4)
        subsidyRate = hhClamp(
            subsidyRate * 0.6 + rulingParty.subsidyBias * 0.4,
            0, 0.3
        )
        tariffRate = hhClamp(
            tariffRate * 0.6 + rulingParty.tariffBias * 0.4,
            0, 0.35
        )
        publicSpending = hhClamp(
            publicSpending * 0.6 + rulingParty.spendingBias * 0.4,
            0.05, 0.4
        )
        electionInDays = 24 + rng.int(in: 0...12)
        let voteShare = 42 + Int(rng.double01() * 23)
        let changed = oldParty != rulingParty

        return EconomyEventRecord(
            day: day,
            kind: .election,
            title: changed ? "\(rulingParty.shortTitle) wins the valley vote" : "\(rulingParty.shortTitle) holds the valley",
            detail: "\(voteShare)% support. Tax \(Int((taxRate * 100).rounded()))%, spending \(Int((publicSpending * 100).rounded()))%, tariff \(Int((tariffRate * 100).rounded()))%.",
            impact: changed ? 0.02 : 0.01
        )
    }
}

extension ValleyEconomy {
    mutating func applyRandomEvent(rng: inout GameRNG) -> EconomyEventRecord {
        var pool: [EconomyEventKind] = [.drought, .storm, .boom, .harvestFestival]
        if tier.rawValue >= EconomyTier.village.rawValue {
            pool.append(contentsOf: [.strike, .epidemic, .heatwave])
        }
        if tier.rawValue >= EconomyTier.marketTown.rawValue {
            pool.append(contentsOf: [.recession, .subsidyProgram, .crimeWave])
        }
        if tier.rawValue >= EconomyTier.district.rawValue {
            pool.append(contentsOf: [.exportBan, .techBreakthrough, .bankruptcyScare])
        }
        if tier.rawValue >= EconomyTier.regional.rawValue {
            pool.append(.globalSlowdown)
        }

        let kind = pool[rng.int(in: 0...(pool.count - 1))]
        var detail = ""
        var impact = 0.0

        switch kind {
        case .drought:
            soilFertility = hhClamp(soilFertility - 0.04, 0.08, 1)
            waterAvailability = hhClamp(waterAvailability - 0.1, 0.03, 1)
            farmYield = hhClamp(farmYield - 0.08, 0.05, 1.6)
            inflation += 0.02
            happiness -= 0.015
            detail = "Dry winds sap soil moisture and lift food prices."
            impact = -0.04
        case .flood:
            infrastructure = hhClamp(infrastructure - 0.04, 0.05, 1)
            waterAvailability = hhClamp(waterAvailability + 0.05, 0.03, 1)
            pollution = hhClamp(pollution + 0.025, 0.01, 1)
            imports += 8
            happiness -= 0.02
            detail = "Floodwater damages roads and delays deliveries."
            impact = -0.035
        case .storm:
            infrastructure = hhClamp(infrastructure - 0.035, 0.05, 1)
            energyCapacity = hhClamp(energyCapacity - 0.03, 0.05, 1.3)
            supply = max(1, supply - 7)
            pollution = hhClamp(pollution + 0.015, 0.01, 1)
            detail = "A storm tears through the valley grid and fields."
            impact = -0.025
        case .recession:
            demand *= 0.86
            consumerConfidence = hhClamp(consumerConfidence - 0.08, 0.05, 1)
            unemployment = hhClamp(unemployment + 0.02, 0, 1)
            happiness -= 0.02
            interestRate = hhClamp(interestRate - 0.005, -0.01, 0.25)
            detail = "Order books thin and firms postpone hiring."
            impact = -0.045
        case .boom:
            demand *= 1.12
            consumerConfidence = hhClamp(consumerConfidence + 0.06, 0.05, 1)
            exports += 6
            inflation += 0.01
            detail = "Outside buyers discover the valley's goods."
            impact = 0.04
        case .epidemic:
            health = hhClamp(health - 0.08, 0.1, 1)
            happiness -= 0.05
            publicSpending = hhClamp(publicSpending + 0.02, 0.05, 0.4)
            unemployment = hhClamp(unemployment + 0.015, 0, 1)
            detail = "A seasonal illness keeps workers home and clinics busy."
            impact = -0.04
        case .election:
            break
        case .strike:
            manufacturing = hhClamp(manufacturing - 0.07, 0.03, 1)
            supply = max(1, supply - 10)
            averageWage *= 1.025
            inflation += 0.012
            detail = "Workers down tools over pay and conditions."
            impact = -0.03
        case .exportBan:
            exports *= 0.7
            currencyStrength = hhClamp(currencyStrength - 0.05, 0.1, 1)
            demand = max(1, demand - 4)
            detail = "A foreign market closes its border to valley produce."
            impact = -0.03
        case .techBreakthrough:
            technology = hhClamp(technology + 0.06, 0.05, 1.5)
            productivity = hhClamp(productivity + 0.03, 0.05, 1.6)
            researchPoints += 10
            pollution = hhClamp(pollution - 0.02, 0.01, 1)
            detail = "A local inventor improves irrigation and storage."
            impact = 0.05
        case .bankruptcyScare:
            creditScore = max(300, creditScore - 30)
            interestRate = hhClamp(interestRate + 0.02, -0.01, 0.25)
            for index in aiBusinesses.indices {
                aiBusinesses[index].mood -= 0.1
            }
            competition = hhClamp(competition - 0.03, 0, 1)
            detail = "A failed loan spooks lenders and tightens credit."
            impact = -0.035
        case .crimeWave:
            crime = hhClamp(crime + 0.06, 0.01, 0.8)
            happiness -= 0.03
            consumerConfidence = hhClamp(consumerConfidence - 0.04, 0.05, 1)
            detail = "Thefts at market stalls unsettle residents."
            impact = -0.03
        case .heatwave:
            waterAvailability = hhClamp(waterAvailability - 0.08, 0.03, 1)
            farmYield = hhClamp(farmYield - 0.06, 0.05, 1.6)
            energyCapacity = hhClamp(energyCapacity - 0.02, 0.05, 1.3)
            health = hhClamp(health - 0.015, 0.1, 1)
            detail = "A heatwave strains water, power, and field workers."
            impact = -0.03
        case .globalSlowdown:
            exports *= 0.75
            demand *= 0.92
            currencyStrength = hhClamp(currencyStrength - 0.04, 0.1, 1)
            detail = "Distant markets slow and shipping orders shrink."
            impact = -0.04
        case .subsidyProgram:
            happiness += 0.02
            poverty = hhClamp(poverty - 0.02, 0.01, 1)
            farmYield = hhClamp(farmYield + 0.03, 0.05, 1.6)
            publicDebt += 10
            detail = "A new grant helps farms modernise and families cope."
            impact = 0.025
        case .harvestFestival:
            happiness += 0.04
            demand += 8
            consumerConfidence = hhClamp(consumerConfidence + 0.04, 0.05, 1)
            politicalStability = hhClamp(politicalStability + 0.02, 0.1, 1)
            detail = "Lanterns, pies, and music lift the whole valley."
            impact = 0.03
        }

        return EconomyEventRecord(
            day: day,
            kind: kind,
            detail: detail,
            impact: impact
        )
    }
}
