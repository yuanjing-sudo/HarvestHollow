import Foundation

extension ValleyEconomy {
    /// Advances every interlinked part of the valley economy by one in-game day.
    /// The order matters: resources set yields, yields set supply, supply sets
    /// prices, and prices circle back into wages, confidence, and policy.
    @discardableResult
    public mutating func advanceDay(
        _ inputs: EconomyInputs,
        rng: inout GameRNG
    ) -> EconomyReport {
        let previousTier = tier
        let previousGdp = gdp
        let previousLevel = lastKnownLevel
        lastKnownLevel = max(1, inputs.level)
        tier = EconomyTier.forLevel(lastKnownLevel)
        let unlocked = EconomyFactor.allCases.filter {
            $0.minimumLevel > previousLevel && $0.minimumLevel <= lastKnownLevel
        }
        day = inputs.day
        lastWeather = inputs.weather

        var rain = 0.0
        var heat = 0.0
        var storm = 0.0
        switch inputs.weather {
        case .sunny, .breezy: break
        case .rainy: rain = 1
        case .heatwave: heat = 1
        case .storm: storm = 1
        }

        var weatherYield = 1.02
        switch inputs.weather {
        case .sunny: weatherYield = 1.02
        case .rainy: weatherYield = 1.06
        case .breezy: weatherYield = 1.03
        case .heatwave: weatherYield = 0.93
        case .storm: weatherYield = 0.84
        }

        var seasonModifier = 1.0
        switch inputs.season {
        case .spring: seasonModifier = 1.06
        case .summer: seasonModifier = 1.02
        case .autumn: seasonModifier = 0.96
        case .winter: seasonModifier = 0.76
        }

        let cropUse = min(1, Double(inputs.cropCount) / 14)
        soilFertility = hhClamp(
            soilFertility
                + 0.004 * (1 - soilFertility)
                - cropUse * 0.0025
                - pollution * 0.002
                + subsidyRate * 0.004
                + rain * 0.0012
                - heat * 0.0015
                - storm * 0.002,
            0.08, 1
        )
        soilDegradation = hhClamp(
            soilDegradation
                + cropUse * 0.002
                - subsidyRate * 0.004
                - bareSoilRecovery(inputs)
                - rain * 0.0005,
            0, 1
        )
        irrigation = hhClamp(
            irrigation
                + (inputs.wateredCrops > 0 ? 0.0012 : 0)
                + rain * 0.0012
                + infrastructure * 0.0004
                - heat * 0.0008
                - 0.0004,
            0.05, 1
        )
        cropDiversity = hhClamp(
            cropDiversity
                + (inputs.cropCount >= 3 ? 0.0008 : -0.0007)
                + subsidyRate * 0.001
                - cropUse * 0.0004,
            0.05, 1
        )
        livestockHealth = hhClamp(
            livestockHealth
                + (inputs.animalHappiness - 0.5) * 0.014
                + inputs.animalAffection * 0.004
                - pollution * 0.004
                - heat * 0.001
                - 0.0008,
            0.08, 1
        )
        livestockBreeding = hhClamp(
            livestockBreeding
                + livestockHealth * 0.0008
                + inputs.animalAffection * 0.002
                - 0.0004,
            0.03, 1
        )
        animalWelfare = hhClamp(
            animalWelfare
                + (inputs.animalHappiness - 0.5) * 0.01
                + (1 - pollution) * 0.0005
                - 0.0005,
            0.05, 1
        )
        let householdWaterUse = Double(population) * 0.00035
        let farmWaterUse = Double(inputs.wateredCrops) * 0.0016
        waterAvailability = hhClamp(
            waterAvailability
                + rain * 0.045
                - heat * 0.035
                - storm * 0.012
                - householdWaterUse
                - farmWaterUse
                + irrigation * 0.0015
                + infrastructure * 0.0008
                - 0.002,
            0.03, 1
        )
        energyCapacity = hhClamp(
            energyCapacity
                + infrastructure * 0.0012
                + publicSpending * 0.002
                + technology * 0.0008
                + renewableShare * 0.001
                - manufacturing * 0.0006
                - 0.0004,
            0.05, 1.3
        )
        renewableShare = hhClamp(
            renewableShare
                + publicSpending * 0.0015
                + subsidyRate * 0.002
                + technology * 0.0008
                + (subsidyRate > 0.04 ? 0.0007 : 0)
                - 0.0003,
            0.02, 1
        )

        farmYield = hhClamp(
            (0.32 + soilFertility * 0.58 + irrigation * 0.2 + cropDiversity * 0.1)
                * weatherYield
                * seasonModifier
                * (1 + technology * 0.18)
                * (1 - pollution * 0.15)
                * (0.9 + animalWelfare * 0.1),
            0.05, 1.6
        )

        let localFood = (
            Double(inputs.cropCount) * 0.6
                + Double(inputs.readyCrops) * 0.9
                + Double(inputs.animalCount) * 0.7 * (0.6 + livestockHealth * 0.4)
                + Double(inputs.storedGoods) * 0.02
        ) * farmYield

        manufacturing = hhClamp(
            manufacturing
                + productivity * 0.001
                + infrastructure * 0.001
                + technology * 0.0005
                - (1 - waterAvailability) * 0.0005
                - pollution * 0.0003
                - 0.0002,
            0.03, 1
        )
        logistics = hhClamp(
            logistics
                + infrastructure * 0.0015
                + technology * 0.0007
                + tradeBalance * 0.0001
                - pollution * 0.0005,
            0.05, 1
        )

        let productionLoad = manufacturing * 0.0035
            + Double(aiBusinesses.count) * 0.0008
            + Double(inputs.animalCount) * 0.0003
        pollution = hhClamp(
            pollution
                + productionLoad
                - renewableShare * 0.004
                - publicSpending * 0.001
                - technology * 0.0008
                + storm * 0.002,
            0.01, 1
        )
        biodiversity = hhClamp(
            biodiversity
                + renewableShare * 0.002
                + cropDiversity * 0.001
                - pollution * 0.0025
                - cropUse * 0.0007
                - storm * 0.003,
            0.05, 1
        )
        let firmResult = updateBusinesses(inputs: inputs, rng: &rng)
        let firmJobs = firmResult.jobs
        let businessOutput = firmResult.output

        workforce = max(1, Int(Double(population) * 0.58))
        let publicJobs = Int(publicSpending * 55)
        let farmJobs = min(18, inputs.cropCount + inputs.animalCount)
        employed = min(workforce, firmJobs + publicJobs + farmJobs)
        unemployment = hhClamp(
            1 - Double(employed) / Double(max(1, workforce)),
            0, 1
        )
        averageWage = hhClamp(
            averageWage * (
                1
                    + inflation * 0.004
                    + productivity * 0.006
                    - unemployment * 0.003
                    + 0.001
            ),
            4, 500
        )

        supply = max(
            1,
            localFood
                + businessOutput * 0.6
                + imports * 0.55
                + manufacturing * 8
                + logistics * 2
        )
        let householdDemand = Double(population)
            * 0.33
            * (0.55 + consumerConfidence)
            * (1 + min(0.4, max(0, averageWage - 20) / 120))
        demand = max(
            1,
            householdDemand
                + exports * 0.75
                + Double(inputs.inventoryValue) * 0.0015
        )

        let marketPressure = (demand - supply) / max(1, supply)
        let inflationTarget = 0.02
            + marketPressure * 0.1
            + max(0, averageWage - 30) * 0.0002
            + tariffRate * 0.05
            - currencyStrength * 0.01
            - energyCapacity * 0.004
        inflation = hhClamp(
            inflation * 0.7 + inflationTarget * 0.3,
            -0.04, 0.25
        )
        priceIndex = hhClamp(
            priceIndex * (1 + inflation / 120),
            0.35, 4
        )
        consumerConfidence = hhClamp(
            0.36
                + happiness * 0.24
                + (1 - unemployment) * 0.18
                + (1 - min(0.2, max(0, inflation))) * 0.1
                - inequality * 0.1
                - crime * 0.05
                - pollution * 0.03,
            0.05, 1
        )
        let taylor = 0.02
            + inflation * 0.7
            + max(0, 0.06 - unemployment) * 0.25
            - max(0, debtToGDP - 1) * 0.01
        interestRate = hhClamp(
            interestRate * 0.8 + taylor * 0.2,
            -0.01, 0.25
        )
        currencyStrength = hhClamp(
            currencyStrength
                + tradeBalance * 0.0004
                - inflation * 0.01
                + (interestRate - 0.04) * 0.08,
            0.1, 1
        )

        let competitiveness = (0.4 + productivity * 0.45 + logistics * 0.2)
            * (1 - tariffRate * 0.7)
            / max(0.6, priceIndex)
        exports = hhClamp(
            exports * 0.75
                + manufacturing * 30 * competitiveness
                + farmYield * 3.5,
            0, 250
        )
        imports = hhClamp(
            imports * 0.75
                + max(0, demand - supply * 0.9) * 0.3
                + Double(population) * 0.02 * (1 + tariffRate),
            0, 250
        )

        productivity = hhClamp(
            productivity
                + education * 0.0008
                + technology * 0.0008
                + infrastructure * 0.0004
                - unemployment * 0.0003,
            0.05, 1.6
        )
        researchPoints += education * 0.9
            + publicSpending * 2
            + Double(aiBusinesses.count) * 0.1
        while researchPoints >= Double(18 * researchLevel) {
            researchPoints -= Double(18 * researchLevel)
            researchLevel += 1
            technology = hhClamp(technology + 0.025, 0.05, 1.5)
            productivity = hhClamp(productivity + 0.008, 0.05, 1.6)
        }

        infrastructure = hhClamp(
            infrastructure
                + publicSpending * 0.003
                - pollution * 0.001
                - 0.0008,
            0.05, 1
        )
        publicServices = hhClamp(
            publicServices
                + publicSpending * 0.004
                + education * 0.0005
                - corruption * 0.001
                - 0.0006,
            0.05, 1
        )
        health = hhClamp(
            health
                + publicServices * 0.002
                + publicSpending * 0.002
                - pollution * 0.004
                - poverty * 0.0015
                + 0.0005,
            0.1, 1
        )
        education = hhClamp(
            education
                + publicSpending * 0.002
                + 0.0004
                - poverty * 0.001,
            0.05, 1
        )
        happiness = hhClamp(
            happiness
                + 0.0015
                + min(0.003, averageWage / 15000)
                + health * 0.0015
                + (1 - min(0.2, max(0, inflation))) * 0.001
                - unemployment * 0.008
                - poverty * 0.004
                - inequality * 0.002
                - crime * 0.005
                - corruption * 0.004
                - pollution * 0.003
                + politicalStability * 0.002
                - 0.002,
            0.05, 1
        )
        poverty = hhClamp(
            poverty
                + unemployment * 0.003
                + inflation * 0.015
                - averageWage * 0.00004
                - education * 0.0015
                - publicServices * 0.002
                - 0.0005,
            0.01, 1
        )
        inequality = hhClamp(
            inequality
                + (competition < 0.45 ? 0.001 : -0.0005)
                - taxRate * 0.003
                + (1 - education) * 0.0005
                - 0.0003,
            0.05, 0.9
        )
        crime = hhClamp(
            crime
                + unemployment * 0.0025
                + poverty * 0.002
                + inequality * 0.001
                - education * 0.0015
                - publicServices * 0.0015
                - 0.0003,
            0.01, 0.8
        )
        corruption = hhClamp(
            corruption
                + (1 - politicalStability) * 0.0008
                + (1 - taxRate) * 0.0002
                - education * 0.0008
                - publicServices * 0.0008,
            0, 0.8
        )

        ensureLedgers()
        let forcedBefore = market?.forcedLiquidations ?? 0
        advanceMarket(inputs: inputs, rng: &rng)
        let todaysIncident = advanceJustice(rng: &rng)
        let marketNotice = (market?.forcedLiquidations ?? 0) > forcedBefore
            ? market?.lastNotice
            : nil

        let gdpNow = gdp
        governmentBalance = gdpNow * (taxRate - publicSpending - subsidyRate)
            + tariffRate * imports * 0.6
            - publicDebt * interestRate / 365
        publicDebt = hhClamp(
            publicDebt - governmentBalance * 0.08,
            0, gdpNow * 4
        )
        politicalStability = hhClamp(
            0.5
                + happiness * 0.2
                + (1 - unemployment) * 0.1
                + (1 - corruption) * 0.08
                - max(0, inflation - 0.06) * 0.5
                - min(0.3, debtToGDP) * 0.1
                - poverty * 0.05,
            0.1, 1
        )

        var todaysEvent = tickElection(rng: &rng)
        netWorth = Double(inputs.coins)
            + gdp * 0.02
            + investmentMarket.equity
            + aiBusinesses.reduce(0) { $0 + $1.capital } * 0.5
            + aiCitizens.reduce(0) { $0 + $1.savings } * 0.25
        for index in loans.indices {
            loans[index].balance += loans[index].dailyInterest
        }
        let loanTotal = totalLoanBalance
        var creditDelta = 0
        if governmentBalance > 0 { creditDelta += 1 }
        if unemployment > 0.15 { creditDelta -= 1 }
        if loanTotal > Double(inputs.coins) * 0.6 { creditDelta -= 1 }
        if investmentMarket.leverage > 2.2 { creditDelta -= 1 }
        if investmentMarket.equity < 0 { creditDelta -= 1 }
        if pollution < 0.25 { creditDelta += 1 }
        creditScore = Int(hhClamp(
            Double(creditScore + creditDelta),
            300, 850
        ))
        bankruptcyRisk = hhClamp(
            loanTotal / max(150, Double(inputs.coins) + gdp * 0.02) * 0.35
                + max(0, -governmentBalance / max(1, gdp)) * 0.5
                + unemployment * 0.12
                + max(0, inflation - 0.08) * 0.4,
            0, 1
        )

        let migration = (happiness - 0.45) * 0.004
            + (health - 0.5) * 0.002
            - pollution * 0.003
            - unemployment * 0.002
            + (publicServices - 0.4) * 0.002
        let natural = 0.0004
            - pollution * 0.0008
            - max(0, poverty - 0.3) * 0.0008
        populationMomentum = hhClamp(
            populationMomentum * 0.8 + (migration + natural) * 0.2,
            -0.01, 0.01
        )
        population = max(
            12,
            population + Int((Double(population) * populationMomentum).rounded())
        )
        workforce = max(1, Int(Double(population) * 0.58))

        for index in aiCitizens.indices {
            var citizen = aiCitizens[index]
            let hasJob = rng.double01() >= unemployment
            citizen.employed = hasJob
            citizen.income = hasJob
                ? averageWage * (0.85 + citizen.education * 0.3)
                : max(3, averageWage * 0.2)
            citizen.consumption = citizen.income
                * (0.45 + consumerConfidence * 0.3)
                / max(0.6, priceIndex)
            citizen.savings = max(
                0,
                citizen.savings + citizen.income - citizen.consumption - 3
            )
            citizen.happiness = hhClamp(
                citizen.happiness
                    + (citizen.income / (averageWage + 1) - 1) * 0.01
                    - inflation * 0.01
                    + (hasJob ? 0.001 : -0.004),
                0.05, 1
            )
            citizen.health = hhClamp(
                citizen.health + health * 0.002 - pollution * 0.002 - 0.0005,
                0.05, 1
            )
            citizen.education = hhClamp(
                citizen.education + education * 0.001 - 0.0002,
                0.05, 1
            )
            aiCitizens[index] = citizen
        }

        let eventChance = hhClamp(
            0.045
                + Double(tier.rawValue) * 0.012
                + pollution * 0.04
                + max(0, inflation - 0.08) * 0.35,
            0.02, 0.32
        )
        if todaysEvent == nil, rng.chance(eventChance) {
            todaysEvent = applyRandomEvent(rng: &rng)
        }
        if let event = todaysEvent {
            eventHistory.insert(event, at: 0)
            if eventHistory.count > 12 {
                eventHistory.removeLast(eventHistory.count - 12)
            }
        }
        activeEvent = todaysEvent
        let growth = previousGdp > 0 ? (gdp - previousGdp) / previousGdp : 0
        let headline: String
        if let event = todaysEvent {
            headline = event.title
        } else if growth > 0.008 {
            headline = "The valley economy is expanding"
        } else if growth < -0.008 {
            headline = "The valley economy is softening"
        } else {
            headline = "A steady day in the valley"
        }

        var warnings: [String] = []
        if inflation > 0.08 { warnings.append("Inflation is pressing household budgets.") }
        if unemployment > 0.12 { warnings.append("Unemployment is above the village comfort line.") }
        if pollution > 0.5 { warnings.append("Pollution is damaging soil and health.") }
        if debtToGDP > 1 { warnings.append("Public debt is larger than annual output.") }
        if bankruptcyRisk > 0.5 { warnings.append("Household debt risk is elevated.") }
        if happiness < 0.35 { warnings.append("Residents are unhappy; migration may follow.") }
        if crime > 0.3 { warnings.append("Crime is eroding confidence.") }
        if investmentMarket.marginDebt > 0, investmentMarket.leverage > 2.2 {
            warnings.append("Margin debt is high; a share-price fall can force a sale.")
        }

        let summary = "GDP \(Int(gdp))c · prices \(String(format: "%.2f", priceIndex)) · \(Int((unemployment * 100).rounded()))% idle · \(Int(population)) residents"
        let report = EconomyReport(
            day: day,
            tier: tier,
            previousTier: previousTier,
            headline: headline,
            summary: summary,
            warnings: warnings,
            unlockedFactors: unlocked,
            event: todaysEvent,
            gdp: gdp,
            demand: demand,
            supply: supply,
            priceIndex: priceIndex,
            governmentBalance: governmentBalance,
            marketNotice: marketNotice,
            crimeIncident: todaysIncident
        )
        lastReport = report
        history.append(snapshot())
        if history.count > 40 {
            history.removeFirst(history.count - 40)
        }
        return report
    }

    private func bareSoilRecovery(_ inputs: EconomyInputs) -> Double {
        let idlePlots = max(0, 6 - inputs.cropCount)
        return Double(idlePlots) * 0.0004
    }
}
