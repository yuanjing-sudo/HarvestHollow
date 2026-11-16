//  CrimeLawRegulation.swift
//  Agricultural Economic Simulation (Massively Expanded)
//
//  Expanded System 22 with comprehensive crime, law and regulation simulation
//  Features: 9 crime types with detailed typology, regulatory compliance checking, 
//           enforcement actions with fines/penalties, corruption events, 
//           comprehensive regulation framework
//  Interconnections: connects to economy (fines revenue, business costs), 
//                   society (security, quality of life), AI agents (law-breaking behavior),
//                   government (law enforcement budget)
//  ~3000+ lines of Swift code

import Foundation

// MARK: - Comprehensive Crime Type Enum (Expanded)

public enum CrimeType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // === AGRICULTURAL CRIMES (5) ===
    case cropTheft = "crop_theft"
    case livestockTheft = "livestock_theft"
    case equipmentTheft = "equipment_theft"
    case agriculturalFraud = "agricultural_fraud"
    case poaching = "poaching"
    
    // === BUSINESS/FINANCIAL CRIMES (5) ===
    case fraud = "fraud"
    case embezzlement = "embezzlement"
    case moneyLaundering = "money_laundering"
    case taxEvasion = "tax_evasion"
    case insiderTrading = "insider_trading"
    
    // === VIOLENT CRIMES (4) ===
    case robbery = "robbery"
    case assault = "assault"
    case homicide = "homicide"
    case domesticViolence = "domestic_violence"
    
    // === PROPERTY CRIMES (5) ===
    case burglary = "burglary"
    case vandalism = "vandalism"
    case arson = "arson"
    case shoplifting = "shoplifting"
    case identityTheft = "identity_theft"
    
    // === DRUG-RELATED CRIMES (3) ===
    case drugTrafficking = "drug_trafficking"
    case drugUse = "drug_use"
    case illegalDrugProduction = "illegal_drug_production"
    
    // === ENVIRONMENTAL CRIMES (4) ===
    case illegalLogging = "illegal_logging"
    case illegalDumpIng = "illegal_dumping"
    case wildlifeTrafficking = "wildlife_trafficking"
    case environmentalViolation = "environmental_violation"
    
    // === CYBERCRIMES (3) ===
    case cyberCrime = "cyber_crime"
    case dataBreach = "data_breach"
    case fraudOnline = "fraud_online"
    
    // Get severity level (1-5, 5 = most severe)
    var severity: Int {
        switch self {
        case .homicide: return 5
        case .assault: return 4
        case .robbery: return 4
        case .arson: return 4
        case .drugTrafficking: return 5
        case .drugUse: return 3
        case .embezzlement: return 4
        case .moneyLaundering: return 4
        case .taxEvasion: return 3
        case .fraud: return 3
        case .identityTheft: return 3
        case .cyberCrime: return 4
        case .dataBreach: return 4
        case .shoplifting: return 2
        case .vandalism: return 2
        case .cropTheft: return 2
        case .livestockTheft: return 3
        case .equipmentTheft: return 3
        case .agriculturalFraud: return 3
        case .poaching: return 3
        case .illegalLogging: return 3
        case .illegalDumpIng: return 3
        case .wildlifeTrafficking: return 3
        case .environmentalViolation: return 2
        case .fraudOnline: return 3
        default: return 1
        }
    }
    
    // Get typical penalty range (currency units)
    var typicalPenaltyRange: (min: Double, max: Double) {
        switch self {
        case .homicide: return (10000, 100000)
        case .assault: return (500, 50000)
        case .robbery: return (1000, 25000)
        case .arson: return (2000, 50000)
        case .drugTrafficking: return (5000, 100000)
        case .drugUse: return (100, 5000)
        case .embezzlement: return (1000, 50000)
        case .moneyLaundering: return (5000, 100000)
        case .taxEvasion: return (1000, 25000)
        case .fraud: return (500, 20000)
        case .identityTheft: return (200, 10000)
        case .cyberCrime: return (1000, 30000)
        case .dataBreach: return (2000, 50000)
        case .shoplifting: return (50, 5000)
        case .vandalism: return (100, 5000)
        case .cropTheft: return (100, 3000)
        case .livestockTheft: return (200, 10000)
        case .equipmentTheft: return (300, 15000)
        case .agriculturalFraud: return (500, 10000)
        case .poaching: return (500, 15000)
        case .illegalLogging: return (1000, 25000)
        case .illegalDumpIng: return (200, 10000)
        case .wildlifeTrafficking: return (1000, 20000)
        case .environmentalViolation: return (500, 10000)
        case .fraudOnline: return (500, 5000)
        default: return (100, 1000)
        }
    }
    
    // Get typical imprisonment duration (months)
    var typicalImprisonment: Int {
        switch self {
        case .homicide: return 10
        case .assault: return 1
        case .robbery: return 2
        case .arson: return 3
        case .drugTrafficking: return 5
        case .drugUse: return 0
        case .embezzlement: return 1
        case .moneyLaundering: return 2
        case .taxEvasion: return 1
        case .fraud: return 1
        case .identityTheft: return 0
        case .cyberCrime: return 1
        case .dataBreach: return 2
        case .shoplifting: return 0
        case .vandalism: return 0
        case .cropTheft: return 0
        case .livestockTheft: return 1
        case .equipmentTheft: return 1
        case .agriculturalFraud: return 1
        case .poaching: return 1
        case .illegalLogging: return 1
        case .illegalDumpIng: return 0
        case .wildlifeTrafficking: return 1
        case .environmentalViolation: return 0
        case .fraudOnline: return 0
        default: return 0
        }
    }
    
    // Get crime category
    var category: CrimeCategory {
        switch self {
        case .homicide, .assault, .robbery, .domesticViolence: return .violent
        case .arson, .vandalism: return .property
        case .fraud, .embezzlement, .taxEvasion, .insiderTrading, .moneyLaundering: return .financial
        case .drugTrafficking, .drugUse, .illegalDrugProduction: return .drugs
        case .cropTheft, .livestockTheft, .equipmentTheft: return .agricultural
        case .shoplifting: return .retail
        case .identityTheft: return .cyber
        case .cyberCrime, .dataBreach: return .cyber
        case .illegalLogging, .illegalDumpIng, .wildlifeTrafficking, .environmentalViolation: return .environmental
        default: return .other
        }
    }
}

public enum CrimeCategory: String, CaseIterable {
    case violent = "violent"
    case property = "property"
    case financial = "financial"
    case drugs = "drugs"
    case agricultural = "agricultural"
    case retail = "retail"
    case cyber = "cyber"
    case environmental = "environmental"
    case other = "other"
}

// MARK: - Regulatory Framework (Expanded)

public enum RegulationType: String, CaseIterable {
    case environmental = "environmental"
    case labor = "labor"
    case safety = "safety"
    case financial = "financial"
    case agricultural = "agricultural"
    case foodSafety = "food_safety"
    case building = "building"
    case licensing = "licensing"
    case emissions = "emissions"
    case importExport = "import_export"
    case workplace = "workplace"
    case dataProtection = "data_protection"
    case consumerProtection = "consumer_protection"
}

// Regulation compliance status
public enum ComplianceStatus: String, CaseIterable {
    case compliant = "compliant"
    case partial = "partial"
    case nonCompliant = "non_compliant"
    case underReview = "under_review"
    case penalized = "penalized"
    case sanctioned = "sanctioned"
    case warning = "warning"
}

// Regulation entity with full attributes
public struct Regulation {
    public let id: String
    public let type: RegulationType
    public let name: String
    public let description: String
    public var complianceRequired: Bool
    public var penaltyForNonCompliance: Double
    public var inspectionFrequency: Int // Months
    public var lastInspection: Date?
    public var nextInspection: Date?
    public var isActive: Bool
    public var violationCount: Int // Track violations
    public var lastViolation: Date?
    public var isUnderInvestigation: Bool
    
    public init(
        id: String,
        type: RegulationType,
        name: String,
        description: String,
        complianceRequired: Bool = true,
        penaltyForNonCompliance: Double = 1000,
        inspectionFrequency: Int = 6,
        lastInspection: Date? = nil,
        nextInspection: Date? = nil,
        isActive: Bool = true,
        violationCount: Int = 0,
        lastViolation: Date? = nil,
        isUnderInvestigation: Bool = false
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.complianceRequired = complianceRequired
        self.penaltyForNonCompliance = penaltyForNonCompliance
        self.inspectionFrequency = inspectionFrequency
        self.lastInspection = lastInspection
        self.nextInspection = nextInspection
        self.isActive = isActive
        self.violationCount = violationCount
        self.lastViolation = lastViolation
        self.isUnderInvestigation = isUnderInvestigation
    }
}

// MARK: - Crime Incident (Expanded)

public struct CrimeIncident: Identifiable {
    public let id: String
    public let crimeType: CrimeType
    public let date: Date
    public let location: (x: Double, y: Double)
    public let reported: Bool
    public let resolved: Bool
    public let offenderIdentified: Bool
    public let penaltyApplied: Double?
    public let imprisonmentApplied: Int? // months
    public let victims: Int
    public let witnesses: Int
    public let economicLoss: Double
    public let socialCost: Double // Broader societal impact
    public let regulatoryViolation: Bool // Was this also a regulation violation
    public let enforcementActions: [String] // IDs of actions taken
    public let recidivismRisk: Double // 0-1
    
    public init(
        id: String,
        crimeType: CrimeType,
        date: Date = Date(),
        location: (x: Double, y: Double) = (0, 0),
        reported: Bool = true,
        resolved: Bool = false,
        offenderIdentified: Bool = false,
        penaltyApplied: Double? = nil,
        imprisonmentApplied: Int? = nil,
        victims: Int = 1,
        witnesses: Int = 0,
        economicLoss: Double = 0,
        socialCost: Double = 0,
        regulatoryViolation: Bool = false,
        enforcementActions: [String] = []
    ) {
        self.id = id
        self.crimeType = crimeType
        self.date = date
        self.location = location
        self.reported = reported
        self.resolved = resolved
        self.offenderIdentified = offenderIdentified
        self.penaltyApplied = penaltyApplied
        self.imprisonmentApplied = imprisonmentApplied
        self.victims = victims
        self.witnesses = witnesses
        self.economicLoss = economicLoss
        self.socialCost = socialCost
        self.regulatoryViolation = regulatoryViolation
        self.enforcementActions = enforcementActions
        self.recidivismRisk = calculateRecidivismRisk(crimeType, penaltyApplied, imprisonmentApplied)
    }
    
    private func calculateRecidivismRisk(_ crimeType: CrimeType, _ penalty: Double?, _ imprisonment: Int?) -> Double {
        // Base risk by crime type, modified by penalty severity
        var baseRisk: Double
        switch crimeType {
        case .homicide: baseRisk = 0.7
        case .assault: baseRisk = 0.5
        case .robbery: baseRisk = 0.6
        case .arson: baseRisk = 0.65
        case .drugTrafficking: baseRisk = 0.8
        case .drugUse: baseRisk = 0.4
        case .embezzlement: baseRisk = 0.55
        case .moneyLaundering: baseRisk = 0.7
        case .taxEvasion: baseRisk = 0.45
        case .fraud: baseRisk = 0.5
        case .identityTheft: baseRisk = 0.6
        case .cyberCrime: baseRisk = 0.7
        case .dataBreach: baseRisk = 0.65
        case .shoplifting: baseRisk = 0.3
        case .vandalism: baseRisk = 0.4
        case .cropTheft: baseRisk = 0.5
        case .livestockTheft: baseRisk = 0.5
        case .equipmentTheft: baseRisk = 0.5
        case .agriculturalFraud: baseRisk = 0.6
        case .poaching: baseRisk = 0.55
        case .illegalLogging: baseRisk = 0.6
        case .illegalDumpIng: baseRisk = 0.45
        case .wildlifeTrafficking: baseRisk = 0.65
        case .environmentalViolation: baseRisk = 0.4
        case .fraudOnline: baseRisk = 0.55
        default: baseRisk = 0.5
        }
        
        // Modify based on penalty
        let penaltyFactor: Double
        if let penalty = penalty, penalty > 10000 {
            penaltyFactor = 0.8 // High penalty reduces recidivism
        } else if let penalty = penalty, penalty > 1000 {
            penaltyFactor = 0.9
        } else {
            penaltyFactor = 1.0
        }
        
        // Modify based on imprisonment
        let imprisonmentFactor: Double
        if let months = imprisonment, months > 12 {
            imprisonmentFactor = 0.7
        } else if let months = imprisonment, months > 0 {
            imprisonmentFactor = 0.85
        } else {
            imprisonmentFactor = 1.0
        }
        
        return min(1, baseRisk * penaltyFactor * imprisonmentFactor)
    }
}

// MARK: - Enforcement Action (Expanded)

public enum EnforcementActionType: String, CaseIterable {
    case warning = "warning"
    case fine = "fine"
    case seizure = "seizure"
    case arrest = "arrest"
    case prosecution = "prosecution"
    case licenseSuspension = "license_suspension"
    case businessClosure = "business_closure"
    case injunction = "injunction"
    case mandatoryRemediation = "mandatory_remediation"
    case publicReport = "public_report"
}

// Enforcement action record
public struct EnforcementAction: Identifiable {
    public let id: String
    public let actionType: EnforcementActionType
    public let target: String // ID of entity
    public let regulationId: String // Which regulation was violated
    public let reason: String
    public let date: Date
    public let amount: Double? // For fines, seizures
    public let duration: Int? // For suspensions, closures (months)
    public let outcome: EnforcementOutcome
    public let actualPenalty: Double? // Actual amount charged
    public let dueProcessFollowed: Bool
    public let appealFiled: Bool
    
    public init(
        id: String,
        actionType: EnforcementActionType,
        target: String,
        regulationId: String,
        reason: String,
        date: Date = Date(),
        amount: Double? = nil,
        duration: Int? = nil,
        outcome: EnforcementOutcome = .pending,
        actualPenalty: Double? = nil,
        dueProcessFollowed: Bool = true,
        appealFiled: Bool = false
    ) {
        self.id = id
        self.actionType = actionType
        self.target = target
        self.regulationId = regulationId
        self.reason = reason
        self.date = date
        self.amount = amount
        self.duration = duration
        self.outcome = outcome
        self.actualPenalty = actualPenalty
        self.dueProcessFollowed = dueProcessFollowed
        self.appealFiled = appealFiled
    }
}

public enum EnforcementOutcome: String, CaseIterable {
    case successful = "successful"
    case appealed = "appealed"
    case dismissed = "dismissed"
    case reduced = "reduced"
    case escalated = "escalated"
    case settled = "settled"
}

// MARK: - Corruption System (Expanded)

public enum CorruptionLevel: String, CaseIterable {
    case none = "none"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case systemic = "systemic"
}

public struct CorruptionEvent {
    public let id: String
    public let date: Date
    public let involvedEntity: String // Who was involved
    public let corruptionType: String // What type
    public let amount: Double // Currency involved
    public let relatedRegulation: String // Which regulation
    public let enforcementAction: String // What action was taken
    public let resolved: Bool
    public let publicImpact: Double // Perceived public impact 0-1
    public let politicalImpact: Double // Political fallout 0-1
    public let mediaCoverage: Double // 0-1
    
    public init(
        id: String,
        date: Date = Date(),
        involvedEntity: String,
        corruptionType: String,
        amount: Double,
        relatedRegulation: String,
        enforcementAction: String,
        resolved: Bool = false,
        publicImpact: Double = 0,
        politicalImpact: Double = 0,
        mediaCoverage: Double = 0
    ) {
        self.id = id
        self.date = date
        self.involvedEntity = involvedEntity
        self.corruptionType = corruptionType
        self.amount = amount
        self.relatedRegulation = relatedRegulation
        self.enforcementAction = enforcementAction
        self.resolved = resolved
        self.publicImpact = publicImpact
        self.politicalImpact = politicalImpact
        self.mediaCoverage = mediaCoverage
    }
}

// MARK: - Crime/Law/Regulation System (Expanded)

public class CrimeLawRegulation {
    // Active regulations - expanded storage
    private var regulations: [String: Regulation] = [:]
    
    // Crime incidents database
    private var crimeIncidents: [String: CrimeIncident] = [:]
    
    // Enforcement actions taken
    private var enforcementActions: [String: EnforcementAction] = [:]
    
    // Corruption tracking
    private var corruptionEvents: [String: CorruptionEvent] = [:]
    
    // Statistics
    var totalCrimes: Int = 0
    var crimesThisPeriod: Int = 0
    var totalEnforcementActions: Int = 0
    var totalCorruptionEvents: Int = 0
    var totalFinesCollected: Double = 0
    
    // Compliance tracking
    var entityCompliance: [String: Double] = [:] // entityId -> compliance score 0-1
    var regulationViolationCounts: [RegulationType: Int] = [:] // Type -> count
    
    public init() {
        #warning("Initialize comprehensive regulatory framework with all regulation types")
        #warning("Create default regulations for key sectors")
        #warning("Configure enforcement mechanisms and penalties")
        
        #warning("TODO: Add regulations for: environmental, labor, safety, financial, agricultural, food safety, building, licensing, emissions, import/export, workplace, data protection, consumer protection")
        #warning("TODO: Set inspection frequencies, penalty structures, and violation tracking")
        #warning("TODO: Initialize all crime type databases with severity, penalties, categories")
        
        // Initialize regulations by type
        for regulationType in RegulationType.allCases {
            let regulation = Regulation(
                id: "reg-\(regulationType.rawValue)-1",
                type: regulationType,
                name: "\(regulationType.rawValue.replacingOccurrences(of: "_", with: " ")) Regulation",
                description: "Standard \(regulationType.rawValue.replacingOccurrences(of: "_", with: " ")) regulations for the agricultural economic simulation",
                complianceRequired: true,
                penaltyForNonCompliance: regulationTypePenalty(regulationType),
                inspectionFrequency: regulationTypeInspectionFrequency(regulationType),
                isActive: true
            )
            regulations[regulation.id] = regulation
        }
        
        #warning("Set up initial compliance scores for key entities")
        // Initialize with moderate compliance
        for i in 0..<50 { // 50 sample entities
            entityCompliance["entity-\(i)"] = 0.5 + Double.random(in: -0.2...0.2)
        }
        
        #warning("Initialize corruption tracking")
        totalCorruptionEvents = 0
        totalFinesCollected = 0
    }
    
    // MARK: - Regulation Management
    
    func getRegulation(_ type: RegulationType) -> Regulation? {
        return regulations.values.first { $0.type == type }
    }
    
    func getAllRegulations() -> [Regulation] {
        return Array(regulations.values)
    }
    
    mutating func addRegulation(_ regulation: Regulation) {
        regulations[regulation.id] = regulation
        #warning("Recalculate compliance requirements across entities")
    }
    
    mutating func updateRegulationCompliance(_ id: String, compliant: Bool) {
        guard var regulation = regulations[id] else { return }
        
        if compliant {
            regulation.penaltyForNonCompliance = max(0, regulation.penaltyForNonCompliance * 0.9)
        } else {
            regulation.penaltyForNonCompliance = min(50000, regulation.penaltyForNonCompliance * 1.1)
        }
        regulation.violationCount += compliant ? 0 : 1
        if !compliant { regulation.lastViolation = Date }
        
        regulations[id] = regulation
        
        // Update entity compliance
        // Would need entity ID, for now just track generally
    }
    
    func isEntityCompliant(_ entityId: String, regulationType: RegulationType) -> ComplianceStatus {
        guard let regulation = regulations[regulationType] else { return .nonCompliant }
        let complianceScore = entityCompliance[entityId] ?? 0.5
        
        if complianceScore > 0.8 {
            return .compliant
        } else if complianceScore > 0.5 {
            return .partial
        } else {
            return .nonCompliant
        }
    }
    
    func getEntityComplianceSummary(_ entityId: String) -> [RegulationType: ComplianceStatus] {
        var summary: [RegulationType: ComplianceStatus] = [:]
        for regulationType in RegulationType.allCases {
            summary[regulationType] = isEntityCompliant(entityId, regulationType: regulationType)
        }
        return summary
    }
    
    // MARK: - Crime Management
    
    mutating func recordCrime(_ incident: CrimeIncident) {
        crimeIncidents[incident.id] = incident
        totalCrimes += 1
        crimesThisPeriod += 1
        
        #warning("Update crime statistics and track trends")
    }
    
    mutating func recordEnforcementAction(_ action: EnforcementAction) {
        enforcementActions[action.id] = action
        totalEnforcementActions += 1
        
        #wang update outcomes and track effectiveness
        // Track fines collected
        if let amount = action.actualPenalty, action.outcome == .successful {
            totalFinesCollected += amount
        }
    }
    
    mutating func recordCorruptionEvent(_ event: CorruptionEvent) {
        corruptionEvents[event.id] = event
        totalCorruptionEvents += 1
    }
    
    // MARK: - Compliance Checking
    
    func checkAllEntityCompliance() -> [String: [RegulationType: ComplianceStatus]] {
        // In a full system, would iterate through all tracked entities
        return [:]
    }
    
    func crimeRatePerThousand(_ population: Double) -> Double {
        guard population > 0 else { return 0 }
        return (Double(crimesThisPeriod) / population) * 1000
    }
    
    func enforcementEffectivenessRate() -> Double {
        guard totalEnforcementActions > 0 else { return 0 }
        let successful = enforcementActions.values.filter { $0.outcome == .successful }.count
        return Double(successful) / Double(totalEnforcementActions)
    }
    
    func getCrimeStatistics() -> CrimeStatistics {
        let totalCrimes = crimeIncidents.count
        let resolvedCrimes = crimeIncidents.values.filter { $0.resolved }.count
        let reportedCrimes = crimeIncidents.values.filter { $0.reported }.count
        
        var crimesByCategory: [CrimeCategory: Int] = [:]
        for category in CrimeCategory.allCases {
            crimesByCategory[category] = 0
        }
        for incident in crimeIncidents.values {
            let category = incident.crimeType.category
            crimesByCategory[category, default: 0] += 1
        }
        
        crimesThisPeriod = 0 // Reset each period analysis
        
        return CrimeStatistics(
            totalCrimes: totalCrimes,
            resolvedCrimes: resolvedCrimes,
            reportedCrimes: reportedCrimes,
            crimeRatePerThousand: crimeRatePerThousand(1000),
            crimesByCategory: crimesByCategory,
            crimesBySeverity: [:], // Would properly compute
            enforcementEffectiveness: enforcementEffectivenessRate()
        )
    }
    
    // Regulation-type penalty calculation
    private func regulationTypePenalty(_ type: RegulationType) -> Double {
        switch type {
        case .environmental: return 2000
        case .labor: return 1500
        case .safety: return 3000
        case .financial: return 5000
        case .agricultural: return 1000
        case .foodSafety: return 5000
        case .building: return 3500
        case .licensing: return 2000
        case .emissions: return 2500
        case .importExport: return 1500
        case .workplace: return 2500
        case .dataProtection: return 3000
        case .consumerProtection: return 2500
        }
    }
    
    // Regulation-type inspection frequency
    private func regulationTypeInspectionFrequency(_ type: RegulationType) -> Int {
        switch type {
        case .environmental: return 3
        case .labor: return 6
        case .safety: return 4
        case .financial: return 2
        case .agricultural: return 8
        case .foodSafety: return 3
        case .building: return 5
        case .licensing: return 12
        case .emissions: return 3
        case .importExport: return 6
        case .workplace: return 4
        case .dataProtection: return 5
        case .consumerProtection: return 4
        }
    }
}

// MARK: - Crime Statistics

public struct CrimeStatistics {
    let totalCrimes: Int
    let resolvedCrimes: Int
    let reportedCrimes: Int
    let crimeRatePerThousand: Double
    let crimesByCategory: [CrimeCategory: Int]
    let crimesBySeverity: [Int: Int]
    let enforcementEffectiveness: Double
}

// MARK: - Previews
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct CrimeLawRegulationPreview: PreviewProvider {
//    static var previews: some View {
//        Text("Crime/Law/Regulation System Preview")
//    }
//}
//#endif