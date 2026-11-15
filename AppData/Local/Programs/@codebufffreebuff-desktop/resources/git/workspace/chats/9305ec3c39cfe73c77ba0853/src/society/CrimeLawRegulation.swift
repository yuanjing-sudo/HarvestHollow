//
//  CrimeLawRegulation.swift
//  Agricultural Economic Simulation
//

import Foundation

// Crime type enum
public enum CrimeType: String {
    case theft = "theft"
    case fraud = "fraud"
    case vandalism = "vandalism"
    case corruption = "corruption"
    case smuggling = "smuggling"
    case illegalWorkers = "illegal_workers"
    case counterfeiting = "counterfeiting"
    case illegalGambling = "illegal_gambling"
    case drugTrafficking = "drug_trafficking"
}

// Regulatory compliance
public struct RegulatoryCompliance {
    public let businessId: String
    public var complianceArea: String
    public var complianceStatus: String  // compliant, under_review, non_compliant, penalised
    public var violationCount: Int
    public var lastInspection: Date
    public var finesPaid: Double
    public var penaltySeverity: String  // warning, fine, license_suspension, business_closure
    
    public init(businessId: String, complianceArea: String, complianceStatus: String = "under_review", violationCount: Int = 0, lastInspection: Date = Date(), finesPaid: Double = 0, penaltySeverity: String = "warning") {
        self.businessId = businessId
        self.complianceArea = complianceArea
        self.complianceStatus = complianceStatus
        self.violationCount = violationCount
        self.lastInspection = lastInspection
        self.finesPaid = finesPaid
        self.penaltySeverity = penaltySeverity
    }
}

// Social and legal indicators
public struct SocialLegalIndicators {
    public var crimeRate: Double  // per 1000 population per period
    public var fraudIncidents: Int
    public var corruptionLevel: Double  // 0-100
    public var regulatoryComplianceRate: Double  // 0-100, percentage
    public var publicSafety: Double  // 0-100
    public var lawEnforcementCapacity: Double  // 0-100
    public var courtEfficiency: Double  // 0-100
    public var inspectionCapacity: Double  // 0-100
    
    public init(crimeRate: Double = 5, fraudIncidents: Int = 10, corruptionLevel: Double = 10, regulatoryComplianceRate: Double = 85, publicSafety: Double = 75, lawEnforcementCapacity: Double = 70, courtEfficiency: Double = 80, inspectionCapacity: Double = 75) {
        self.crimeRate = crimeRate
        self.fraudIncidents = fraudIncidents
        self.corruptionLevel = corruptionLevel
        self.regulatoryComplianceRate = regulatoryComplianceRate
        self.publicSafety = publicSafety
        self.lawEnforcementCapacity = lawEnforcementCapacity
        self.courtEfficiency = courtEfficiency
        self.inspectionCapacity = inspectionCapacity
    }
}

// Business regulation
public struct BusinessRegulation {
    public var licenceRequired: Bool
    public var safetyStandards: Double  // 0-100 compliance required
    public var environmentalStandards: Double  // 0-100 compliance required
    public var labourProtections: Double  // 0-100 compliance required
    public var productStandards: Double  // 0-100 compliance required
    public var taxCompliance: Double  // 0-100 compliance required
    public var competitionRegulation: Double  // 0-100 compliance required
    
    public init(licenceRequired: Bool = false, safetyStandards: Double = 80, environmentalStandards: Double = 70, labourProtections: Double = 75, productStandards: Double = 85, taxCompliance: Double = 85, competitionRegulation: Double = 80) {
        self.licenceRequired = licenceRequired
        self.safetyStandards = safetyStandards
        self.environmentalStandards = environmentalStandards
        self.labourProtections = labourProtections
        self.productStandards = productStandards
        self.taxCompliance = taxCompliance
        self.competitionRegulation = competitionRegulation
    }
}

// Main crime-law regulation class
public class CrimeLawRegulation {
    private var crimeStats: SocialLegalIndicators
    private var regulations: [String: BusinessRegulation] = [:]
    private var complianceRegistry: [String: RegulatoryCompliance] = [:]
    
    public init() {
        // Initialize social/legal indicators
        crimeStats = SocialLegalIndicators()
        
        createInitialRegulations()
    }
    
    // MARK: - Initial Regulations
    
    private func createInitialRegulations() {
        let regulationAreas: [String] = ["healthcare", "education", "infrastructure", "agriculture", "environment"]
        
        for area in regulationAreas {
            let regulationId = "reg-\(area)-\(Date.timeIntervalSince1970)"
            let regulation: BusinessRegulation = BusinessRegulation(
                licenceRequired: area != "environment",
                safetyStandards: 80, environmentalStandards: 70, labourProtections: 75,
                productStandards: 85, taxCompliance: 85, competitionRegulation: 80
            )
            
            regulations[regulationId] = regulation
        }
    }
    
    // MARK: - Crime Recording
    
    public mutating func recordCrime(_ crimeType: CrimeType, severity: String, location: (x: Double, y: Double), affectedEntities: [String]) {
        let severityMultiplier: [String: Double] = ["low": 1, "medium": 3, "high": 5]
        let increase = crimeRate + (1 / 1000) * severityMultiplier[severity] ?? 1
        
        crimeStats.crimeRate = max(0, min(50, increase))
        
        if crimeType == .fraud { crimeStats.fraudIncidents += 1 }
        if crimeType == .corruption {
            crimeStats.corruptionLevel = min(100, crimeStats.corruptionLevel + 2)
        }
    }
    
    // MARK: - Violation Recording
    
    public mutating func recordViolation(businessId: String, regulationArea: String, severity: String) {
        var compliance = complianceRegistry[businessId]
        
        if compliance == nil {
            compliance = RegulatoryCompliance(
                businessId: businessId,
                complianceArea: regulationArea,
                complianceStatus: "under_review",
                violationCount: 1,
                lastInspection: Date(),
                finesPaid: 0,
                penaltySeverity: "warning"
            )
        }
        
        compliance?.violationCount += 1
        compliance?.lastInspection = Date()
        
        if compliance!.violationCount <= 3 {
            compliance?.complianceStatus = "under_review"
        } else if compliance!.violationCount <= 7 {
            compliance?.complianceStatus = "non_compliant"
        } else {
            compliance?.complianceStatus = "penalised"
        }
        
        let severityMultiplier: [String: Double] = ["low": 100, "medium": 500, "high": 2000]
        let fineAmount = severityMultiplier[severity] ?? 100
        compliance?.finesPaid = max(0, compliance!.finesPaid + fineAmount)
        
        if compliance!.violationCount >= 5 { compliance?.penaltySeverity = "fine" }
        if compliance!.violationCount >= 10 { compliance?.penaltySeverity = "license_suspension" }
        if compliance!.violationCount >= 15 { compliance?.penaltySeverity = "business_closure" }
        
        complianceRegistry[businessId] = compliance!
        
        updateComplianceRate()
    }
    
    private mutating func updateComplianceRate() {
        let totalBusinesses = regulations.count
        let compliantCount = complianceRegistry.values.filter { $0.complianceStatus == "compliant" }.count
        
        crimeStats.regulatoryComplianceRate = totalBusinesses > 0 ? round((Double(compliantCount) / Double(totalBusinesses)) * 100) : 100
    }
    
    // MARK: - Regulation Compliance Check
    
    public func checkRegulationCompliance(business: (id: String, industry: String, fines: Double, violations: [(area: String, severity: String)])) -> (compliant: Bool, violations: [(area: String, severity: String, penalty: Double)], recommendedActions: [String]) {
        var violations: [(area: String, severity: String, penalty: Double)] = []
        var totalPenalty: Double = 0
        
        for violation in business.violations {
            let severityMap: [String: Double] = ["low": 100, "medium": 500, "high": 2000]
            let penalty = fineAmount ?? severityMap[violation.severity] ?? 100
            
            violations.append((violation.area, violation.severity, penalty))
            totalPenalty += penalty
        }
        
        let compliant = totalPenalty == 0 || business.fines < totalPenalty * 0.1
        
        var recommendedActions: [String] = []
        if !compliant {
            recommendedActions.append("Pay outstanding fines")
            recommendedActions.append("Improve compliance practices")
            recommendedActions.append("Schedule inspection")
        }
        
        return (compliant, violations, recommendedActions)
    }
    
    // MARK: - Getters
    
    public func getCrimeStats() -> SocialLegalIndicators { return crimeStats }
    public func getRegulatoryComplianceRate() -> Double { return crimeStats.regulatoryComplianceRate }
    public func getAllRegulations() -> [String: BusinessRegulation] { return regulations }
    public func getComplianceRecord(_ businessId: String) -> RegulatoryCompliance? { return complianceRegistry[businessId] }
    
    // MARK: - Enforcement
    
    public mutating func enforceRegulations(_ businessId: String, severity: String) -> Bool {
        guard var compliance = complianceRegistry[businessId] else { return false }
        
        let enforcementFines: [String: Double] = ["low": 500, "medium": 2000, "high": 5000]
        compliance.finesPaid = max(0, compliance.finesPaid + enforcementFines[severity] ?? 0)
        
        compliance.violationCount += 1
        compliance.lastInspection = Date()
        
        if compliance.violationCount >= 5 { compliance.complianceStatus = "non_compliant" }
        if compliance.violationCount >= 10 { compliance.penaltySeverity = "fine" }
        if compliance.violationCount >= 15 { compliance.penaltySeverity = "license_suspension" }
        
        complianceRegistry[businessId] = compliance
        updateComplianceRate()
        
        return true
    }
    
    // MARK: - Corruption
    
    public mutating func recordCorruptionEvent(_ severity: String, _ area: String, _ amount: Double) {
        crimeStats.corruptionLevel = min(100, crimeStats.corruptionLevel + (severity == "high" ? 10 : severity == "medium" ? 5 : 2))
        crimeStats.regulatoryComplianceRate = max(0, crimeStats.regulatoryComplianceRate - 5)
        crimeStats.crimeRate = min(50, crimeStats.crimeRate + 2)
    }
    
    public mutating func performAntiCorruptionAction(_ severity: String) {
        let reduction: [String: Double] = ["high": 15, "medium": 8, "low": 3]
        
        crimeStats.corruptionLevel = max(0, crimeStats.corruptionLevel - reduction[severity] ?? 0)
        crimeStats.regulatoryComplianceRate = min(100, crimeStats.regulatoryComplianceRate + reduction[severity] ?? 0)
        crimeStats.crimeRate = max(0, crimeStats.crimeRate - 2)
    }
}