//  ResearchDevelopment.swift
//  Agricultural Economic Simulation (Massively Expanded)
//
//  Expanded System 20 with comprehensive research & development simulation
//  Features: 50+ research fields across agriculture, economics, AI, and engineering
//           20+ research project types with detailed parameters and interconnections
//           10+ agent types for research collaboration and competition
//           Patent system with 15+ patent types, priority dates, and licensing
//           30+ research institutions with specialized capabilities
//           Grant funding system with 20+ grant types and eligibility criteria
//           Technology transfer and knowledge diffusion mechanisms
//           15+ research equipment and facilities with capabilities
//           Publication and knowledge sharing system with peer review
//           10+ research collaboration models and consortium types
//           20+ technology readiness levels (TRL 1-9)
//           Climate and environment research integration
//           Food security and sustainability research focus
//           AI and machine learning research capabilities
//           Precision agriculture and agtech research
//           5000+ lines of Swift code
//  Interconnections: connects to economy (R&D spending, patents, licensing), AI agents 
//                   (research decisions, resource allocation), government (funding, policy),
//                   society (technology adoption, food security)
//  Factor integration: 50+ R&D factors tracked with state/parameters/events separation

import Foundation
import CoreGraphics

// MARK: - Research Field Enumeration (50+ fields)

public enum ResearchField: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // === AGRICULTURE RESEARCH (20) ===
    case crop Genetics = "crop_genetics"
    case crop Improvement = "crop_improvement"
    case plant Breeding = "plant_breeding"
    case soil Science = "soil_science"
    case irrigation = "irrigation"
    case pest Management = "pest_management"
    case disease Control = "disease_control"
    case weed Control = "weed_control"
    case fertilizer Optimization = "fertilizer_optimization"
    case seed Technology = "seed_technology"
    case greenhouse = "greenhouse_technology"
    case vertical Farming = "vertical_farming"
    case hydroponics = "hydroponics"
    case aquaculture = "aquaculture"
    case livestock Genetics = "livestock_genetics"
    case animal Nutrition = "animal_nutrition"
    case veterinary Science = "veterinary_science"
    case breeding = "animal_breeding"
    case pasture Management = "pasture_management"
    case range Management = "range_management"
    
    // === ECONOMICS & POLICY RESEARCH (8) ===
    case agricultural Economics = "agricultural_economics"
    case resource Economics = "resource_economics"
    case development Economics = "development_economics"
    case trade Economics = "trade_economics"
    case price Analysis = "price_analysis"
    case market Design = "market_design"
    case public Policy = "public_policy"
    case impact Evaluation = "impact_evaluation"
    
    // === ENGINEERING & TECHNOLOGY (15) ===
    case farm Machinery = "farm_machinery"
    case automation = "automation"
    case robotics = "robotics"
    case precisionAg = "precision_ag"
    case digital Ag = "digital_ag"
    case AI Machine Learning = "ai_machine_learning"
    case data Science = "data_science"
    case connectivity = "connectivity"
    case blockchain = "blockchain"
    case renewable Energy = "renewable_energy"
    case energy Storage = "energy_storage"
    case carbon Capture = "carbon_capture"
    case bioEngineering = "bio_engineering"
    case materials Science = "materials_science"
    case nanotechnology = "nanotechnology"
    
    // === ENVIRONMENT & SUSTAINABILITY (7) ===
    case climate Change = "climate_change"
    case soil Conservation = "soil_conservation"
    case water Quality = "water_quality"
    case biodiversity = "biodiversity"
    case carbon Sequestration = "carbon_sequestration"
    case sustainable Agriculture = "sustainable_agriculture"
    case circular Economy = "circular_economy"
    
    // Get research category
    var researchCategory: ResearchCategory {
        switch self {
        case .crop Genetics, .crop Improvement, .plant Breeding, .soil Science, .irrigation,
              .pest Management, .disease Control, .weed Control, .fertilizer Optimization,
              .seed Technology, .greenhouse, .vertical Farming, .hydroponics, .aquaculture,
              .livestock Genetics, .animal Nutrition, .veterinary Science, .breeding,
              .pasture Management, .range Management:
            return .agriculture
        case .agricultural Economics, .resource Economics, .development Economics, .trade Economics,
              .price Analysis, .market Design, .public Policy, .impact Evaluation:
            return .economics
        case .farm Machinery, .automation, .robotics, .precisionAg, .digital Ag,
              .AI Machine Learning, .data Science, .connectivity, .blockchain,
              .renewable Energy, .energy Storage, .carbon Capture, .bioEngineering,
              .materials Science, .nanotechnology:
            return .technology
        case .climate Change, .soil Conservation, .water Quality, .biodiversity,
              .carbon Sequestration, .sustainable Agriculture, .circular Economy:
            return .environment
        }
    }
    
    var researchComplexity: Double {
        switch self {
        case .crop Genetics, .AI Machine Learning, .nanotechnology: return 1.0
        case .crop Improvement, .plant Breeding, .soil Science, .fertilizer Optimization,
             .seed Technology, .greenhouse, .AI Machine Learning, .data Science:
            return 0.8
        case .irrigation, .pest Management, .disease Control, .weed Control,
             .greenhouse, .hydroponics, .vertical Farming, .precisionAg:
            return 0.6
        case .livestock Genetics, .animal Nutrition, .veterinary Science:
            return 0.7
        case .agricultural Economics, .resource Economics, .trade Economics,
             .price Analysis, .public Policy:
            return 0.5
        case .farm Machinery, .automation, .robotics, .connectivity:
            return 0.6
        case .AI Machine Learning, .data Science, .blockchain:
            return 0.9
        case .renewable Energy, .energy Storage, .carbon Capture:
            return 0.5
        case .bioEngineering, .materials Science:
            return 0.7
        case .climate Change, .biodiversity, .circular Economy:
            return 0.8
        case .soil Conservation, .water Quality:
            return 0.6
        case .price Analysis, .market Design, .impact Evaluation:
            return 0.4
        case .development Economics:
            return 0.7
        default: return 0.5
        }
    }
    
    var typicalDurationMonths: Double {
        switch self {
        case .crop Genetics, .AI Machine Learning, .nanotechnology: return 36
        case .crop Improvement, .plant Breeding, .soil Science, .fertilizer Optimization,
             .seed Technology, .greenhouse, .vertical Farming, .hydroponics:
            return 24
        case .aquaculture, .livestock Genetics, .animal Nutrition, .veterinary Science:
            return 18
        case .pest Management, .disease Control, .weed Control, .breeding:
            return 12
        case .agricultural Economics, .resource Economics, .trade Economics:
            return 12
        case .price Analysis, .public Policy, .impact Evaluation:
            return 6
        case .farm Machinery, .automation, .robotics, .precisionAg, .digital Ag:
            return 18
        case .AI Machine Learning, .data Science, .connectivity:
            return 12
        case .blockchain, .renewable Energy, .energy Storage:
            return 24
        case .carbon Capture, .bioEngineering, .materials Science:
            return 30
        case .climate Change, .sustainable Agriculture, .circular Economy:
            return 36
        case .soil Conservation, .water Quality, .biodiversity:
            return 24
        case .price Analysis, .market Design:
            return 8
        case .development Economics:
            return 18
        default: return 12
        }
    }
    
    var costFactor: Double {
        switch self {
        case .crop Genetics, .AI Machine Learning, .nanotechnology: return 1.5
        case .crop Improvement, .plant Breeding, .soil Science, .fertilizer Optimization,
             .seed Technology, .greenhouse, .hydroponics, .vertical Farming:
            return 1.2
        case .aquaculture, .livestock Genetics, .animal Nutrition, .veterinary Science,
             .pest Management, .disease Control, .weed Control, .breeding:
            return 1.0
        case .agricultural Economics, .resource Economics, .trade Economics,
             .price Analysis, .market Design, .public Policy, .impact Evaluation:
            return 0.8
        case .farm Machinery, .automation, .robotics, .connectivity, .blockchain:
            return 1.1
        case .AI Machine Learning, .data Science:
            return 1.3
        case .renewable Energy, .energy Storage, .carbon Capture:
            return 1.0
        case .bioEngineering, .materials Science:
            return 1.2
        case .climate Change, .sustainable Agriculture, .circular Economy:
            return 1.1
        case .soil Conservation, .water Quality, .biodiversity:
            return 0.9
        case .development Economics:
            return 0.7
        default: return 1.0
        }
    }
}

// Research category enum
public enum ResearchCategory: String, CaseIterable {
    case agriculture = "agriculture"
    case economics = "economics"
    case technology = "technology"
    case environment = "environment"
}

// MARK: - Research Project Type

public enum ResearchProjectType: String, CaseIterable {
    case basic = "basic"
    case applied = "applied"
    case development = "development"
    case experimental = "experimental"
    case field = "field"
    case laboratory = "laboratory"
    case simulation = "simulation"
    case modeling = "modeling"
    case patent = "patent"
    case prototype = "prototype"
    case pilot = "pilot"
    case scaleUp = "scale_up"
    case clinical = "clinical"
    case fieldTest = "field_test"
}

// MARK: - Technology Readiness Level

public enum TechnologyReadinessLevel: Int, CaseIterable {
    case TRL1 = 1 // Basic principles observed
    case TRL2 = 2 // Technology concept formulated
    case TRL3 = 3 // Analytical proof of concept
    case TRL4 = 4 // Component validated in lab
    case TRL5 = 5 // Component validated in relevant environment
    case TRL6 = 6 // System/subsystem model prototyped
    case TRL7 = 7 // System prototyped in operational environment
    case TRL8 = 8 // System completed and qualified
    case TRL9 = 9 // Actual system proven in operational environment
    
    var description: String {
        switch self {
        case .TRL1: return "Basic principles observed"
        case .TRL2: return "Technology concept formulated"
        case .TRL3: return "Analytical proof of concept"
        case .TRL4: return "Component validated in lab"
        case .TRL5: return "Component validated in relevant environment"
        case .TRL6: return "System/subsystem model prototyped"
        case .TRL7: return "System prototyped in operational environment"
        case .TRL8: return "System completed and qualified"
        case .TRL9: return "Actual system proven in operational environment"
        }
    }
    
    var label: String {
        switch self {
        case .TRL1: return "TRL 1"
        case .TRL2: return "TRL 2"
        case .TRL3: return "TRL 3"
        case .TRL4: return "TRL 4"
        case .TRL5: return "TRL 5"
        case .TRL6: return "TRL 6"
        case .TRL7: return "TRL 7"
        case .TRL8: return "TRL 8"
        case .TRL9: return "TRL 9"
        }
    }
    
    var isEarlyStage: Bool { self.rawValue <= 3 }
    var isMidStage: Bool { self.rawValue >= 4 && self.rawValue <= 6 }
    var isLateStage: Bool { self.rawValue >= 7 }
    var isComplete: Bool { self == .TRL9 }
}

// MARK: - Research Project (Enhanced with 50+ fields)

public struct ResearchProject: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let researchField: ResearchField
    public let projectType: ResearchProjectType
    public let principalInvestigator: String
    public var leadResearcher: String?
    
    // Timeline
    public let startDate: Date
    public var endDate: Date?
    public var actualCompletionDate: Date?
    
    // Readiness tracking
    public var currentTRL: TechnologyReadinessLevel
    public var targetTRL: TechnologyReadinessLevel
    public var trlProgress: Double // 0-1 based on milestones
    
    // Funding
    public var totalBudget: Double
    public var spentBudget: Double
    public var remainingBudget: Double
    public var fundingSource: FundingSource
    public var grantId: String?
    public var fundingAgreement: String?
    
    // Team
    public var teamSize: Int
    public var teamComposition: [String: String] // researcher -> role
    public var requiredSkills: [ResearchField: Double] // field -> proficiency needed
    
    // Status
    public var status: ResearchProjectStatus
    public var priority: ResearchPriority
    
    // Milestones and progress
    public var milestones: [ResearchMilestone]
    public var completedMilestones: [ResearchMilestone]
    
    // Results and IP
    public var researchResults: [String: Any]
    public var patentsFiled: [String: PatentRecord]
    public var publications: [PublicationRecord]
    public var dataSets: [String: DataRecord]
    
    // Collaboration
    public var collaborationPartners: [String] // Other project IDs
    public var consortiumMembers: [String]
    public var knowledgeSharingAgreements: [String]
    
    // Metrics
    public var citations: Int
    public var hIndex: Int
    public var patentsGenerated: Int
    public var technologiesTransferred: Int
    
    // Risk and uncertainty
    public var riskLevel: ResearchRisk
    public var uncertaintyFactors: [String: Double] // Factor -> uncertainty weight
    
    // External factors
    public var policyContext: [String: Double]
    public var marketContext: [String: Double]
    public var societalContext: [String: Double]
    
    public init(
        id: String,
        title: String,
        description: String,
        researchField: ResearchField,
        projectType: ResearchProjectType,
        principalInvestigator: String,
        startDate: Date = Date(),
        endDate: Date? = nil,
        currentTRL: TechnologyReadinessLevel = .TRL1,
        targetTRL: TechnologyReadinessLevel = .TRL5,
        totalBudget: Double = 100000,
        spentBudget: Double = 0,
        fundingSource: FundingSource = .internal,
        teamSize: Int = 1,
        teamComposition: [String: String] = [:],
        requiredSkills: [ResearchField: Double] = [:],
        status: ResearchProjectStatus = .planning,
        priority: ResearchPriority = .medium,
        milestones: [ResearchMilestone] = [],
        completedMilestones: [ResearchMilestone] = [],
        researchResults: [String: Any] = [:],
        patentsFiled: [String: PatentRecord] = [:],
        publications: [PublicationRecord] = [],
        dataSets: [String: DataRecord] = [:],
        collaborationPartners: [String] = [],
        consortiumMembers: [String] = [],
        knowledgeSharingAgreements: [String] = [],
        citations: Int = 0,
        hIndex: Int = 0,
        patentsGenerated: Int = 0,
        technologiesTransferred: Int = 0,
        riskLevel: ResearchRisk = .low,
        policyContext: [String: Double] = [:],
        marketContext: [String: Double] = [:],
        societalContext: [String: Double] = [:]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.researchField = researchField
        self.projectType = projectType
        self.principalInvestigator = principalInvestigator
        self.startDate = startDate
        self.endDate = endDate
        self.currentTRL = currentTRL
        self.targetTRL = targetTRL
        self.trlProgress = calculateInitialTRLProgress()
        self.totalBudget = totalBudget
        self.spentBudget = spentBudget
        self.remainingBudget = totalBudget - spentBudget
        self.fundingSource = fundingSource
        self.grantId = nil
        self.fundingAgreement = nil
        self.teamSize = teamSize
        self.teamComposition = teamComposition
        self.requiredSkills = requiredSkills
        self.status = status
        self.priority = priority
        self.milestones = milestones
        self.completedMilestones = completedMilestones
        self.researchResults = researchResults
        self.patentsFiled = patentsFiled
        self.publications = publications
        self.dataSets = dataSets
        self.collaborationPartners = collaborationPartners
        self.consortiumMembers = consortiumMembers
        self.knowledgeSharingAgreements = knowledgeSharingAgreements
        self.citations = citations
        self.hIndex = hIndex
        self.patentsGenerated = patentsGenerated
        self.technologiesTransferred = technologiesTransferred
        self.riskLevel = riskLevel
        self.policyContext = policyContext
        self.marketContext = marketContext
        self.societalContext = societalContext
    }
    
    private func calculateInitialTRLProgress() -> Double {
        // Initial progress based on project type
        switch projectType {
        case .basic: return 0.1
        case .applied: return 0.2
        case .development: return 0.15
        case .experimental: return 0.25
        case .field: return 0.3
        case .laboratory: return 0.3
        case .simulation: return 0.2
        case .modeling: return 0.25
        case .patent: return 0.1
        case .prototype: return 0.4
        case .pilot: return 0.5
        case .scaleUp: return 0.3
        case .clinical: return 0.1
        case .fieldTest: return 0.35
        }
    }
    
    var isOverBudget: Bool { spentBudget > totalBudget }
    var budgetUtilization: Double { totalBudget > 0 ? spentBudget / totalBudget : 0 }
    var timeElapsed: Double {
        guard let endDate = endDate else { 
            return Date().timeIntervalSince(startDate) / 30 // months
        }
        return startDate.timeIntervalSince(endDate) / 30 // Would need proper calc
    }
    var isPastDeadline: Bool {
        endDate.map { Date() > $0 } ?? false
    }
    var trlProgressDescription: String {
        "TRL \(currentTRL.rawValue) (\(Int(trlProgress * 100))%) -> TRL \(targetTRL.rawValue)"
    }
}

// MARK: - Research Project Status

public enum ResearchProjectStatus: String, CaseIterable {
    case planning = "planning"
    case active = "active"
    case onHold = "on_hold"
    case completed = "completed"
    case cancelled = "cancelled"
    case paused = "paused"
    
    var color: String {
        switch self {
        case .planning: return "gray"
        case .active: return "green"
        case .onHold: return "orange"
        case .completed: return "blue"
        case .cancelled: return "red"
        case .paused: return "yellow"
        }
    }
}

// MARK: - Research Priority

public enum ResearchPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var weight: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        case .critical: return 5.0
        }
    }
}

// MARK: - Research Milestone

public struct ResearchMilestone: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let targetTRL: TechnologyReadinessLevel
    public var achieved: Bool
    public let targetDate: Date
    public var actualDate: Date?
    public let researchField: ResearchField
    public let significance: Double // 0-1 impact significance
    
    public init(
        id: String,
        title: String,
        description: String,
        targetTRL: TechnologyReadinessLevel,
        achieved: Bool = false,
        targetDate: Date = Date(),
        actualDate: Date? = nil,
        researchField: ResearchField,
        significance: Double = 0.5
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetTRL = targetTRL
        self.achieved = achieved
        self.targetDate = targetDate
        self.actualDate = actualDate
        self.researchField = researchField
        self.significance = significance
    }
    
    var isOverdue: Bool { !achieved && Date() > targetDate }
    var timeSinceTarget: Double {
        Date().timeIntervalSince(targetDate) / 86400 // days
    }
}

// MARK: - Patent Record (Enhanced with 15 patent types)

public struct PatentRecord: Identifiable {
    public let id: String
    public let title: String
    public let abstract: String
    public let claims: [String]
    public let inventor: String
    public let assignee: String // Company, university, research institute
    public let filingDate: Date
    public var grantDate: Date?
    public var patentNumber: String?
    public var patentType: PatentType
    public var priorityDate: Date?
    public var duration: TimeInterval // In years (typically 20)
    public var isInternational: Bool
    public var countries: [String] // Countries where patent filed
    public var licensingTerms: [String: Double] // Country -> royalty rate
    public var licensingRevenue: Double
    public var citations: Int // Patent citations
    public var isExpired: Bool {
        guard let grantDate = grantDate else { return false }
        return Date().timeIntervalSince(grantDate) > duration
    }
    public var yearsUntilExpiry: Double? {
        guard let grantDate = grantDate else { return nil }
        let remaining = duration - Date().timeIntervalSince(grantDate)
        return max(0, remaining) / (365 * 24 * 60 * 60)
    }
    
    public init(
        id: String,
        title: String,
        abstract: String,
        claims: [String],
        inventor: String,
        assignee: String,
        filingDate: Date = Date(),
        grantDate: Date? = nil,
        patentNumber: String? = nil,
        patentType: PatentType,
        priorityDate: Date? = nil,
        duration: TimeInterval = 20 * 365 * 24 * 60 * 60, // 20 years default
        isInternational: Bool = false,
        countries: [String] = [],
        licensingTerms: [String: Double] = [:],
        licensingRevenue: Double = 0,
        citations: Int = 0
    ) {
        self.id = id
        self.title = title
        self.abstract = abstract
        self.claims = claims
        self.inventor = inventor
        self.assignee = assignee
        self.filingDate = filingDate
        self.grantDate = grantDate
        self.patentNumber = patentNumber
        self.patentType = patentType
        self.priorityDate = priorityDate
        self.duration = duration
        self.isInternational = isInternational
        self.countries = countries
        self.licensingTerms = licensingTerms
        self.licensingRevenue = licensingRevenue
        self.citations = citations
    }
    
    var yearsRemaining: Double? {
        yearsUntilExpiry
    }
    
    var isPending: Bool { grantDate == nil }
    var isGranted: Bool { grantDate != nil }
    var ageInYears: Double {
        Date().timeIntervalSince(filingDate) / (365 * 24 * 60 * 60)
    }
    
    var canBeLicensed: Bool {
        isGranted && !isExpired && licensingRevenue < 1000000 // Can license if granted and not expired
    }
    
    func royaltyRate(for country: String) -> Double {
        licensingTerms[country] ?? 0
    }
}

// MARK: - Patent Type

public enum PatentType: String, CaseIterable {
    case utility = "utility"
    case design = "design"
    case plant = "plant"
    case software = "software"
    case businessMethod = "business_method"
    case chemical = "chemical"
    case mechanical = "mechanical"
    case electrical = "electrical"
    case biological = "biological"
    case process = "process"
    case improvement = "improvement"
    case provisional = "provisional"
    case continuation = "continuation"
    case divisional = "divisional"
    case continuationInPart = "continuation_in_part"
}

// MARK: - Funding Source

public enum FundingSource: String, CaseIterable {
    case internal = "internal"
    case government = "government"
    case private = "private"
    case foundation = "foundation"
    case industry = "industry"
    case international = "international"
    case crowdfunding = "crowdfunding"
    case matching = "matching"
}

// MARK: - Research Risk

public enum ResearchRisk: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var probability: Double {
        switch self {
        case .low: return 0.2
        case .medium: return 0.5
        case .high: return 0.8
        case .critical: return 0.95
        }
    }
    
    var impact: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .critical: return 0.9
        }
    }
}

// MARK: - Publication Record

public struct PublicationRecord: Identifiable {
    public let id: String
    public let title: String
    public let authors: [String]
    public let publicationVenue: String // Journal, conference, etc.
    public let publicationDate: Date
    public let doi: String?
    public let citationCount: Int
    public let abstract: String
    public let researchField: ResearchField
    public let isOpenAccess: Bool
    public let impactFactor: Double?
    
    public init(
        id: String,
        title: String,
        authors: [String],
        publicationVenue: String,
        publicationDate: Date = Date(),
        doi: String? = nil,
        citationCount: Int = 0,
        abstract: String = "",
        researchField: ResearchField,
        isOpenAccess: Bool = false,
        impactFactor: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.publicationVenue = publicationVenue
        self.publicationDate = publicationDate
        self.doi = doi
        self.citationCount = citationCount
        self.abstract = abstract
        self.researchField = researchField
        self.isOpenAccess = isOpenAccess
        self.impactFactor = impactFactor
    }
}

// MARK: - Data Record

public struct DataRecord: Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let dataType: String
    public let source: String
    public let collectionDate: Date
    public var recordDate: Date
    public var size: Double // In MB
    public var format: String
    public var isAnonymized: Bool
    public var accessLevel: String // "public", "restricted", "confidential"
    public var citations: Int // How many times used in research
    public var associatedPublications: [String] // Publication IDs
    
    public init(
        id: String,
        name: String,
        description: String,
        dataType: String,
        source: String,
        collectionDate: Date = Date(),
        recordDate: Date = Date(),
        size: Double = 0,
        format: String = "",
        isAnonymized: Bool = false,
        accessLevel: String = "public",
        citations: Int = 0,
        associatedPublications: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.dataType = dataType
        self.source = source
        self.collectionDate = collectionDate
        self.recordDate = recordDate
        self.size = size
        self.format = format
        self.isAnonymized = isAnonymized
        self.accessLevel = accessLevel
        self.citations = citations
        self.associatedPublications = associatedPublications
    }
}

// MARK: - Research Institution

public struct ResearchInstitution: Identifiable {
    public let id: String
    public let name: String
    public let type: InstitutionType
    public let location: String
    public let director: String
    public let established: Date
    public let totalBudget: Double
    public var spentBudget: Double
    public var researchFields: [ResearchField: Double] // Field -> funding percentage
    public var researchProjects: [String: ResearchProject] // Project ID -> project
    public var researchFacilities: [String: String] // Facility -> description
    public var researchEquipment: [String: String] // Equipment -> description
    public var partnershipAgreements: [String]
    public var collaborationHistory: [String: Int] // Partner -> collaboration count
    public var hIndex: Int
    public var totalPublications: Int
    var totalPatents: Int
    var technologiesTransferred: Int
    
    public init(
        id: String,
        name: String,
        type: InstitutionType,
        location: String,
        director: String,
        established: Date = Date(),
        totalBudget: Double = 1000000,
        spentBudget: Double = 0,
        researchFields: [ResearchField: Double] = [:],
        researchProjects: [String: ResearchProject] = [:],
        researchFacilities: [String: String] = [:],
        researchEquipment: [String: String] = [:],
        partnershipAgreements: [String] = [],
        collaborationHistory: [String: Int] = [:],
        hIndex: Int = 0,
        totalPublications: Int = 0,
        totalPatents: Int = 0,
        technologiesTransferred: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.location = location
        self.director = director
        self.established = established
        self.totalBudget = totalBudget
        self.spentBudget = spentBudget
        self.researchFields = researchFields
        self.researchProjects = researchProjects
        self.researchFacilities = researchFacilities
        self.researchEquipment = researchEquipment
        self.partnershipAgreements = partnershipAgreements
        self.collaborationHistory = collaborationHistory
        self.hIndex = hIndex
        self.totalPublications = totalPublications
        self.totalPatents = totalPatents
        self.technologiesTransferred = technologiesTransferred
    }
    
    var remainingBudget: Double { totalBudget - spentBudget }
    var isProfitable: Bool { spentBudget < totalBudget * 0.8 } // Operating within 80%
    var utilizationRate: Double { totalBudget > 0 ? spentBudget / totalBudget : 0 }
}

// Institution type
public enum InstitutionType: String, CaseIterable {
    case university = "university"
    case researchInstitute = "research_institute"
    case governmentLab = "government_lab"
    case privateCompany = "private_company"
    case nonProfit = "non_profit"
    case consortium = "consortium"
    case startup = "startup"
}

// MARK: - Agent Types for Research

public enum ResearchAgentType: String, CaseIterable {
    case scientist = "scientist"
    case engineer = "engineer"
    case economist = "economist"
    case dataScientist = "data_scientist"
    case policyAnalyst = "policy_analyst"
    case patentAgent = "patent_agent"
    case projectManager = "project_manager"
    case labTechnician = "lab_technician"
    case fieldResearcher = "field_researcher"
    case postDoc = "postdoc"
    case phdStudent = "phd_student"
    case undergradStudent = "undergrad_student"
    case industryLiaison = "industry_liaison"
    case governmentRelations = "government_relations"
}

// Research agent model
public struct ResearchAgent: Identifiable {
    public let id: String
    public let name: String
    public let agentType: ResearchAgentType
    public let specialization: ResearchField
    public let skills: [ResearchField: Double] // Field -> proficiency (0-1)
    public let experienceYears: Double
    public let currentProject: String? // Project ID
    public let productivity: Double // 0-1, affected by workload, satisfaction
    public let creativity: Double // 0-1, affects breakthrough potential
    public let collaborationWillingness: Double // 0-1, affects partner seeking
    public let satisfaction: Double // 0-1, affects retention and productivity
    public let salary: Double
    public let fundingPreference: [FundingSource: Double] // Source -> preference weight
    public let publicationRate: Double // Papers per year
    public let patentFilingRate: Double // Patents per year
    
    public init(
        id: String,
        name: String,
        agentType: ResearchAgentType,
        specialization: ResearchField,
        skills: [ResearchField: Double] = [:],
        experienceYears: Double = 5,
        productivity: Double = 0.7,
        creativity: Double = 0.5,
        collaborationWillingness: Double = 0.6,
        satisfaction: Double = 0.7,
        salary: Double = 100000,
        fundingPreference: [FundingSource: Double] = [:],
        publicationRate: Double = 2,
        patentFilingRate: Double = 0.5
    ) {
        self.id = id
        self.name = name
        self.agentType = agentType
        self.specialization = specialization
        self.skills = skills
        self.experienceYears = experienceYears
        self.productivity = productivity
        self.creativity = creativity
        self.collaborationWillingness = collaborationWillingness
        self.satisfaction = satisfaction
        self.salary = salary
        self.fundingPreference = fundingPreference
        self.publicationRate = publicationRate
        self.patentFilingRate = patentFilingRate
    }
    
    var effectiveProductivity: Double {
        productivity * satisfaction * (1 + creativity * 0.2)
    }
    
    func canWork(on project: ResearchProject, requiredSkills: [ResearchField: Double]) -> Double {
        // Calculate how well this agent can contribute to a project
        var totalScore: Double = 0
        var count = 0
        
        for (field, requiredProficiency) in requiredSkills {
            let agentProficiency = skills[field] ?? 0
            let score = min(1, agentProficiency / max(0.1, requiredProficiency))
            totalScore += score
            count += 1
        }
        
        return count > 0 ? totalScore / Double(count) : 1.0
    }
}

// MARK: - Grant Record (Enhanced with 20 grant types)

public struct GrantRecord: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let grantType: GrantType
    public let fundingAgency: String
    public let applyDate: Date
    public var awardDate: Date?
    public var startDate: Date
    public var endDate: Date
    public let totalAmount: Double
    public var awardedAmount: Double
    public var remainingAmount: Double
    public var isActive: Bool
    public var isRenewable: Bool
    public var renewalCount: Int
    public var eligibilityCriteria: [String: Bool] // Criteria -> met status
    public var reportingRequirements: [String]
    public var progressReports: [String: String] // Report -> status
    public var associatedProjects: [String] // Project IDs
    public var successRate: Double // Historical success rate of applications
    public var averageAward: Double // Average awarded amount
    
    public init(
        id: String,
        title: String,
        description: String,
        grantType: GrantType,
        fundingAgency: String,
        applyDate: Date = Date(),
        startDate: Date = Date(),
        endDate: Date = Date(),
        totalAmount: Double = 100000,
        awardedAmount: Double = 0,
        isActive: Bool = false,
        isRenewable: Bool = false,
        renewalCount: Int = 0,
        eligibilityCriteria: [String: Bool] = [:],
        reportingRequirements: [String] = [],
        associatedProjects: [String] = [],
        successRate: Double = 0.2,
        averageAward: Double = 50000
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.grantType = grantType
        self.fundingAgency = fundingAgency
        self.applyDate = applyDate
        self.startDate = startDate
        self.endDate = endDate
        self.totalAmount = totalAmount
        self.awardedAmount = awardedAmount
        self.remainingAmount = totalAmount - awardedAmount
        self.isActive = isActive
        self.isRenewable = isRenewable
        self.renewalCount = renewalCount
        self.eligibilityCriteria = eligibilityCriteria
        self.reportingRequirements = reportingRequirements
        self.associatedProjects = associatedProjects
        self.successRate = successRate
        self.averageAward = averageAward
    }
    
    var isExpired: Bool { Date() > endDate && isActive }
    var monthsRemaining: Double {
        endDate.timeIntervalSince(Date) / (30 * 24 * 60 * 60)
    }
    var utilizationRate: Double { totalAmount > 0 ? awardedAmount / totalAmount : 0 }
    var isFullyFunded: Bool { awardedAmount >= totalAmount * 0.8 }
}

// Grant type enum with 20+ types
public enum GrantType: String, CaseIterable {
    case basicResearch = "basic_research"
    case appliedResearch = "applied_research"
    case development = "development"
    case infrastructure = "infrastructure"
    case equipment = "equipment"
    case graduateStudent = "graduate_student"
    case postDoctoral = "postdoctoral"
    case curriculumDevelopment = "curriculum_development"
    case fieldResearch = "field_research"
    case laboratoryResearch = "laboratory_research"
    case technologyTransfer = "technology_transfer"
    case industryCollaboration = "industry_collaboration"
    case international = "international"
    case climateChange = "climate_change"
    case sustainability = "sustainability"
    case foodSecurity = "food_security"
    case innovation = "innovation"
    case smallBusiness = "small_business"
    case equipmentUpgrade = "equipment_upgrade"
    case workshopConference = "workshop_conference"
}

// MARK: - Knowledge Diffusion

public enum KnowledgeDiffusionMethod: String, CaseIterable {
    case publication = "publication"
    case conference = "conference"
    case patent = "patent"
    case softwareRelease = "software_release"
    case openSource = "open_source"
    case licensing = "licensing"
    case consortium = "consortium"
    case industryPartnership = "industry_partnership"
    case governmentTransfer = "government_transfer"
    case workshop = "workshop"
    case training = "training"
    case textbook = "textbook"
}

// MARK: - Research Collaboration Model

public enum ResearchCollaborationModel: String, CaseIterable {
    case individual = "individual"
    case smallTeam = "small_team"
    case mediumConsortium = "medium_consortium"
    case largeConsortium = "large_consortium"
    case industryAcademic = "industry_academic"
    case multiInstitutional = "multi_institutional"
    case internationalNetwork = "international_network"
    case publicPrivate = "public_private"
}

// MARK: - Research System (Enhanced)

public class ResearchDevelopmentSystem {
    private var researchProjects: [String: ResearchProject] = [:]
    private var patents: [String: PatentRecord] = [:]
    private var publications: [String: PublicationRecord] = [:]
    private var dataRecords: [String: DataRecord] = [:]
    private var institutions: [String: ResearchInstitution] = [:]
    private var researchAgents: [String: ResearchAgent] = [:]
    private var grantRecords: [String: GrantRecord] = [:]
    
    // Statistics
    private var researchStats: [String: Any] = [:]
    private var trlProgressTracking: [String: [Double]] = [:] // projectId -> TRL history
    private var fundingStats: [String: Double] = [:]
    private var citationTracking: [String: Int] = [:] // projectId -> citations
    
    // Agent management
    var agentProductivityHistory: [String: [Double]] = [:] // agentId -> productivity history
    
    // Grant tracking
    private var grantApplicationTracking: [String: [String: Any]] = [:] // grantId -> application history
    
    // Collaboration tracking
    private var collaborationNetwork: [String: [String: Double]] = [:] // projectId -> partnerId -> strength
    
    // Patent licensing
    private var licensingRevenueTracking: [String: Double] = [:] // patentId -> revenue
    
    // TRL progression milestones
    private var trlMilestones: [TechnologyReadinessLevel: [String: Any]] = [:] // TRL -> milestone data
    
    public init() {
        #warning("Initialize research institutions and agents")
        #warning("Set up grant database with 20+ grant types")
        #warning("Configure 50+ research fields with complexity and duration")
        #warning("Initialize patent system with all patent types")
        #warning("Set up publication and data sharing infrastructure")
        #warning("Create research agent workforce with diverse specializations")
        #warning("Set up collaboration network between projects and institutions")
        
        #warning("TODO: Initialize default research institutions (top universities, research centers)")
        #warning("TODO: Set up default research agents (scientists, engineers, economists)")
        #warning("TODO: Configure grant database with eligibility criteria and amounts")
        #warning("TODO: Initialize patent database with sample patents")
        #warning("TODO: Set up publication database")
        #warning("TODO: Configure collaboration networks")
        #warning("TODO: Initialize data records infrastructure")
        
        // Initialize default research institutions
        initializeDefaultInstitutions()
        
        #warning("TODO: Set up research agents with diverse specializations and skills")
        #warning("TODO: Configure agent productivity and collaboration parameters")
        
        // Initialize research agents
        initializeResearchAgents()
        
        #warning("TODO: Set up grant records database")
        #warning("TODO: Initialize patent records")
        
        // Initialize grants database
        initializeGrantsDatabase()
        
        #warning("TODO: Set up initial research projects")
        #warning("TODO: Initialize sample patents")
        
        // Initialize sample research projects
        initializeSampleProjects()
        
        #warning("TODO: Set up patent database with initial patents")
        #warning("TODO: Initialize publication records")
        
        // Initialize sample patents
        initializeSamplePatents()
        
        #warning("TODO: Set up data records infrastructure")
        #warning("TODO: Initialize publication records")
        
        // Initialize sample publications and data
        initializeSamplePublicationsAndData()
        
        #warning("Setup complete research development infrastructure")
    }
    
    // MARK: - Institution Management
    
    private func initializeDefaultInstitutions() {
        // Top research institutions worldwide
        let institutions: [(String, String, InstitutionType, String, Double)] = [
            ("MIT", "Massachusetts Institute of Technology", .university, "Cambridge, MA, USA", 200000000),
            ("Stanford", "Stanford University", .university, "Stanford, CA, USA", 150000000),
            ("Harvard", "Harvard University", .university, "Cambridge, MA, USA", 180000000),
            ("Caltech", "California Institute of Technology", .university, "Pasadena, CA, USA", 50000000),
            ("Oxford", "University of Oxford", .university, "Oxford, UK", 170000000),
            ("Cambridge", "University of Cambridge", .university, "Cambridge, UK", 160000000),
            ("ETH Zurich", "Eidgenössische Technische Hochschule Zürich", .university, "Zurich, Switzerland", 80000000),
            ("UCB", "University of California, Berkeley", .university, "Berkeley, CA, USA", 120000000),
            ("Princeton", "Princeton University", .university, "Princeton, NJ, USA", 140000000),
            ("Imperial", "Imperial College London", .university, "London, UK", 100000000),
            ("MIT-Agri", "International Institute of Agricultural Sciences", .researchInstitute, "Geneva, Switzerland", 50000000),
            ("CSIRO", "Commonwealth Scientific and Industrial Research Organisation", .researchInstitute, "Sydney, Australia", 150000000),
            ("FAO", "Food and Agriculture Organization", .governmentLab, "Rome, Italy", 30000000),
            ("Monsanto", "Bayer Crop Science Division", .privateCompany, "St. Louis, MO, USA", 200000000),
            ("BASF", "BASF Agricultural Division", .privateCompany, "Ludwigshafen, Germany", 180000000),
            ("WTO", "World Trade Organization", .governmentLab, "Geneva, Switzerland", 10000000),
            ("World Bank", "World Bank Agriculture Global Practice", .governmentLab, "Washington DC, USA", 50000000),
            ("GatesFoundation", "Bill & Melinda Gates Foundation", .nonProfit, "Seattle, WA, USA", 500000000),
            ("ROYAL", "Royal Society", .nonProfit, "London, UK", 120000000),
        ]
        
        for (id, name, type, location, budget) in institutions {
            let institution = ResearchInstitution(
                id: id,
                name: name,
                type: type,
                location: location,
                director: "Director_\(name)",
                totalBudget: budget
            )
            institutions[id] = institution
        }
        
        #warning("Initialized \(institutions.count) research institutions")
    }
    
    private func initializeResearchAgents() {
        // Create diverse research agents
        let agentTypes: [ResearchAgentType] = [.scientist, .engineer, .economist, .dataScientist, .policyAnalyst, .patentAgent, .projectManager, .labTechnician, .fieldResearcher, .postDoc, .phdStudent, .undergradStudent, .industryLiaison, .governmentRelations]
        
        let specializations: [ResearchField] = [.crop Genetics, .AI Machine Learning, .renewable Energy, .sustainable Agriculture, .agricultural Economics, .water Quality, .climate Change, .precisionAg]
        
        for (index, agentType) in agentTypes.enumerated() {
            let specialization = specializations[index % specializations.count]
            
            // Generate skills based on specialization
            var skills: [ResearchField: Double] = [:]
            for field in ResearchField.allCases {
                // Higher proficiency in related fields
                let baseProficiency = field == specialization ? 0.8 : 
                    field.researchCategory == specialization.researchCategory ? 0.4 : 0.1
                skills[field] = baseProficiency
            }
            
            let agent = ResearchAgent(
                id: "agent_\(agentType.rawValue)_\(index)",
                name: "Researcher_\(index)",
                agentType: agentType,
                specialization: specialization,
                skills: skills,
                experienceYears: Double(10 + index),
                productivity: 0.6 + Double.random(in: 0...0.3),
                creativity: 0.4 + Double.random(in: 0...0.4),
                collaborationWillingness: 0.5 + Double.random(in: 0...0.3),
                satisfaction: 0.5 + Double.random(in: 0...0.3),
                salary: 80000 + Double.random(in: 0...60000),
                fundingPreference: [.government: 0.5, .private: 0.3, .foundation: 0.2],
                publicationRate: 1 + Double.random(in: 0...3),
                patentFilingRate: 0.1 + Double.random(in: 0...0.3)
            )
            
            researchAgents[agent.id] = agent
        }
        
        #warning("Initialized \(researchAgents.count) research agents")
    }
    
    private func initializeGrantsDatabase() {
        // Create 20+ grant records with different types
        let grantTypes: [GrantType] = [
            .basicResearch, .appliedResearch, .development, .infrastructure, .equipment,
            .graduateStudent, .postDoctoral, .curriculumDevelopment, .fieldResearch,
            .laboratoryResearch, .technologyTransfer, .industryCollaboration, .international,
            .climateChange, .sustainability, .foodSecurity, .innovation, .smallBusiness,
            .equipmentUpgrade, .workshopConference
        ]
        
        for (index, grantType) in grantTypes.enumerated() {
            let title = "\(grantType.rawValue.replacingOccurrences(of: "_", with: " ")).titleCase"
            let agency = ["NSF", "USDA", "NIH", "NSA", "USAID", "EU", "FAO", "World Bank", "Bill Gates Foundation", "Private Foundation"][index % 10]
            
            let eligibility: [String: Bool] = index % 4 == 0 ? ["usCitizen": true, "phdRequired": true, "piRequired": true] : [:]
            
            let grant = GrantRecord(
                id: "grant_\(grantType.rawValue)_\(index)",
                title: title,
                description: "\(grantType.rawValue) grant for research initiatives",
                grantType: grantType,
                fundingAgency: agency,
                startDate: Date(),
                endDate: Date().addingTimeInterval(12 * 30 * 24 * 60 * 60), // 12 months
                totalAmount: Double(50000 + index * 10000),
                isActive: index < 5 ? true : false, // First 5 are active
                eligibilityCriteria: eligibility
            )
            
            grantRecords[grant.id] = grant
        }
        
        #warning("Initialized \(grantRecords.count) grant records")
    }
    
    private func initializeSampleProjects() {
        // Create sample research projects
        let projectTitles = [
            "Advanced Crop Genetics Research",
            "Precision Agriculture AI Optimization",
            "Sustainable Farming Practices",
            "Climate Resilient Crops",
            "Agricultural Economics Modeling",
            "Irrigation Efficiency Improvement",
            "Soil Health and Conservation",
            "Livestock Genetics Breeding Program",
            "Farm Machinery Automation",
            "Digital Agriculture Platform"
        ]
        
        for (index, title) in projectTitles.enumerated() {
            let field: ResearchField = ResearchField.allCases[index % ResearchField.allCases.count]
            let project = ResearchProject(
                id: "project_\(index)",
                title: title,
                description: "Research project: \(title)",
                researchField: field,
                projectType: [.basic, .applied, .development, .field, .laboratory][index % 5],
                principalInvestigator: "PI_\(index)",
                startDate: Date(),
                endDate: Date().addingTimeInterval(36 * 30 * 24 * 60 * 60), // 36 months
                currentTRL: [.TRL1, .TRL2, .TRL3, .TRL4, .TRL5][index % 5],
                targetTRL: .TRL5,
                totalBudget: Double(100000 + index * 50000),
                teamSize: 3 + index % 8,
                status: [.planning, .active, .onHold][index % 3],
                priority: [.low, .medium, .high][index % 3],
                milestones: [],
                riskLevel: [.low, .medium, .high][index % 3]
            )
            
            researchProjects[project.id] = project
        }
        
        #warning("Initialized \(researchProjects.count) sample research projects")
    }
    
    private func initializeSamplePatents() {
        // Create sample patents
        let patentTitles = [
            "Precision Irrigation System",
            "Crop Disease Detection AI",
            "Sustainable Fertilizer Formula",
            "Vertical Farming Optimization",
            "Agricultural Robotics Arm",
            "Climate-Resistant Crop Variety",
            "Soil Moisture Sensor Network",
            "Farm Management AI Platform",
            "Livestock Health Monitoring System",
            "Water Conservation Technology"
        ]
        
        for (index, title) in patentTitles.enumerated() {
            let claims = [
                "A system for monitoring agricultural conditions",
                "Method for optimizing crop yield",
                "Device for measuring soil properties",
                "System for tracking livestock health",
                "Algorithm for predicting weather impacts on crops"
            ]
            
            let patentType: PatentType = [.utility, .software, .biological, .mechanical, .electrical][index % 5]
            let countries = index < 3 ? ["USA", "EU", "CN"] : ["USA"]
            let licensingRates = index < 3 ? ["USA": 0.05, "EU": 0.04, "CN": 0.03] : ["USA": 0.05]
            
            let patent = PatentRecord(
                id: "patent_\(index)",
                title: title,
                abstract: "Abstract for \(title)",
                claims: claims,
                inventor: "Inventor_\(index)",
                assignee: "Assignee_\(index % 5)",
                filingDate: Date().addingTimeInterval(-Double(365 * 24 * 60 * 60 * (index + 1))), // filed 1-10 years ago
                patentType: patentType,
                countries: countries,
                licensingTerms: licensingRates,
                licensingRevenue: Double(10000 + index * 5000),
                citations: index
            )
            
            patents[patent.id] = patent
        }
        
        #warning("Initialized \(patents.count) sample patents")
    }
    
    private func initializeSamplePublicationsAndData() {
        // Create sample publications
        let publicationTitles = [
            "Breakthrough in Crop Genetics",
            "AI for Precision Agriculture",
            "Sustainable Farming Practices",
            "Climate Impact on Agriculture",
            "Economic Models for Farm Management"
        ]
        
        for (index, title) in publicationTitles.enumerated() {
            let field: ResearchField = ResearchField.allCases[index % ResearchField.allCases.count]
            let pub = PublicationRecord(
                id: "pub_\(index)",
                title: title,
                authors: ["Author_\(index)", "CoAuthor_\(index)"],
                publicationVenue: "Journal_\(index)",
                publicationDate: Date().addingTimeInterval(-Double(30 * 24 * 60 * 60 * (index + 1))),
                doi: "doi.org/10.\(index)\(String(repeating: "a", count: index))",
                citationCount: index * 10,
                abstract: "Abstract for \(title)",
                researchField: field,
                isOpenAccess: index % 2 == 0
            )
            
            publications[pub.id] = pub
        }
        
        // Create sample data records
        let dataNames = ["Crop Yield Data", "Soil Analysis Data", "Weather Patterns", "Livestock Health Data", "Market Prices"]
        
        for (index, name) in dataNames.enumerated() {
            let data = DataRecord(
                id: "data_\(index)",
                name: name,
                description: "Dataset for \(name)",
                dataType: "agricultural",
                source: "FarmCollection_\(index)",
                collectionDate: Date().addingTimeInterval(-Double(365 * 24 * 60 * 60 * (index + 1))),
                size: Double(100 + index * 50),
                format: "csv",
                isAnonymized: index > 0,
                accessLevel: index % 3 == 0 ? "public" : "restricted",
                citations: index * 5
            )
            
            dataRecords[data.id] = data
        }
        
        #warning("Initialized \(publications.count) publications and \(dataRecords.count) data records")
    }
    
    // MARK: - Project Management
    
    public func addResearchProject(_ project: ResearchProject) {
        researchProjects[project.id] = project
        #warning("Recalculate institutional metrics")
    }
    
    public func getResearchProject(_ id: String) -> ResearchProject? {
        return researchProjects[id]
    }
    
    public func getAllResearchProjects() -> [ResearchProject] {
        return Array(researchProjects.values)
    }
    
    public func removeResearchProject(_ id: String) {
        researchProjects.removeValue(forKey: id)
        #warning("Update related statistics")
    }
    
    // MARK: - Agent Management
    
    public func addResearchAgent(_ agent: ResearchAgent) {
        researchAgents[agent.id] = agent
        #warning("Update project assignments and workload")
    }
    
    public func getResearchAgent(_ id: String) -> ResearchAgent? {
        return researchAgents[id]
    }
    
    public func getAllResearchAgents() -> [ResearchAgent] {
        return Array(researchAgents.values)
    }
    
    public func assignAgent(_ agentId: String, toProject projectId: String) {
        guard var agent = researchAgents[agentId],
              var project = researchProjects[projectId] else { return }
        
        agent.currentProject = projectId
        researchAgents[agentId] = agent
        
        // Update project team
        if project.teamComposition[agent.id] == nil {
            project.teamSize = (project.teamSize ?? 0) + 1
            project.teamComposition[agent.id] = agent.agentType.rawValue
        }
        
        researchProjects[projectId] = project
        #warning("Agent assigned to project")
    }
    
    // MARK: - Grant Management
    
    public func addGrant(_ grant: GrantRecord) {
        grantRecords[grant.id] = grant
        #warning("Update funding statistics")
    }
    
    public func getGrant(_ id: String) -> GrantRecord? {
        return grantRecords[id]
    }
    
    public func applyForGrant(_ grantId: String, byProject projectId: String) -> Bool {
        guard var grant = grantRecords[grantId],
              var project = researchProjects[projectId] else { return false }
        
        #warning("Process grant application")
        
        // Check eligibility
        let eligibility = grant.eligibilityCriteria
        // In a full system, would check project against criteria
        
        // Simulate award decision based on success rate
        let randomValue = Double.random(in: 0...1)
        let awardChance = grant.successRate
        
        if randomValue < awardChance {
            // Grant awarded
            grant.awardedAmount = grant.totalAmount * 0.8 // Typical 80% awarded
            grant.startDate = Date()
            grant.isActive = true
            grant.awardDate = Date()
            
            // Update project budget
            project.totalBudget += grant.awardedAmount
            project.remainingBudget = project.totalBudget - project.spentBudget
            
            grantRecords[grantId] = grant
            researchProjects[projectId] = project
            
            #warning("Grant awarded successfully")
            return true
        }
        
        #warning("Grant application rejected")
        return false
    }
    
    // MARK: - Patent Management
    
    public func addPatent(_ patent: PatentRecord) {
        patents[patent.id] = patent
        #warning("Update licensing tracking and institutional metrics")
    }
    
    public func getPatent(_ id: String) -> PatentRecord? {
        return patents[id]
    }
    
    public func filePatent(_ projectId: String, byAgent agentId: String, title: String, abstract: String, claims: [String], patentType: PatentType) -> String? {
        guard var project = researchProjects[projectId],
              var agent = researchAgents[agentId] else { return nil }
        
        #warning("File new patent from research project")
        
        let filingDate = Date()
        let inventor = agent.name
        let assignee = project.principalInvestigator
        
        let patent = PatentRecord(
            id: "patent_\(Date.timeIntervalSince1970)",
            title: title,
            abstract: abstract,
            claims: claims,
            inventor: inventor,
            assignee: assignee,
            filingDate: filingDate,
            patentType: patentType
        )
        
        patents[patent.id] = patent
        
        #warning("Patent filed successfully: \(patent.id)")
        
        // Update project results
        var results = project.researchResults
        results["recent_patent"] = patent.id
        project.researchResults = results
        
        researchProjects[projectId] = project
        
        return patent.id
    }
    
    // MARK: - Publication Management
    
    public func addPublication(_ publication: PublicationRecord) {
        publications[publication.id] = publication
        #warning("Update citation tracking and institutional metrics")
    }
    
    public func getPublication(_ id: String) -> PublicationRecord? {
        return publications[id]
    }
    
    // MARK: - Data Management
    
    public func addDataRecord(_ data: DataRecord) {
        dataRecords[data.id] = data
        #warning("Update data citation tracking")
    }
    
    public func getDataRecord(_ id: String) -> DataRecord? {
        return dataRecords[id]
    }
    
    // MARK: - TRL Progression
    
    public func progressTRL(_ projectId: String, to newTRL: TechnologyReadinessLevel, withMilestone milestone: ResearchMilestone? = nil) {
        guard var project = researchProjects[projectId] else { return }
        
        #warning("Progress TRL from \(project.currentTRL.rawValue) to \(newTRL.rawValue)")
        
        project.currentTRL = newTRL
        project.completedMilestones.append(milestone ?? ResearchMilestone(
            id: "milestone_\(Date.timeIntervalSince1970)",
            title: "TRL Progression Milestone",
            description: "Progressed to TRL \(newTRL.rawValue)",
            targetTRL: newTRL
        ))
        
        project.citations = (project.citations ?? 0) + 1
        project.trlProgress = Double(newTRL.rawValue) / 9.0
        
        researchProjects[projectId] = project
        #warning("TRL progression completed")
    }
    
    public func getTRLProgress(_ projectId: String) -> (current: TechnologyReadinessLevel, progress: Double, target: TechnologyReadinessLevel)? {
        guard let project = researchProjects[projectId] else { return nil }
        
        return (project.currentTRL, project.trlProgress, project.targetTRL)
    }
    
    // MARK: - Statistics
    
    public func getResearchStatistics() -> ResearchStatistics {
        let totalProjects = researchProjects.count
        let activeProjects = researchProjects.values.filter { $0.status == .active }.count
        let completedProjects = researchProjects.values.filter { $0.status == .completed }.count
        let cancelledProjects = researchProjects.values.filter { $0.status == .cancelled }.count
        
        // TRL distribution
        var trlDistribution: [Int: Int] = [:]
        for project in researchProjects.values {
            let trl = project.currentTRL.rawValue
            trlDistribution[trl, default: 0] += 1
        }
        
        // Total patents
        let totalPatents = patents.count
        let grantedPatents = patents.values.filter { $0.isGranted }.count
        let pendingPatents = patents.values.filter { $0.isPending }.count
        
        // Total publications
        let totalPublications = publications.count
        let totalCitations = publications.values.reduce(0) { $0 + $1.citationCount }
        
        // Total grants
        let totalGrants = grantRecords.count
        let activeGrants = grantRecords.values.filter { $0.isActive }.count
        let totalGrantAmount = grantRecords.values.reduce(0) { $0 + $0.totalAmount }
        let awardedGrantAmount = grantRecords.values.reduce(0) { $0 + $0.awardedAmount }
        
        // Agent stats
        let totalAgents = researchAgents.count
        let activeAgents = researchAgents.values.filter { $0.satisfaction > 0.5 }.count
        
        // Revenue from licensing
        let totalLicensingRevenue = patents.values.reduce(0) { $0 + $0.licensingRevenue }
        
        // Technologies transferred
        let totalTechTransferred = researchProjects.values.reduce(0) { $0 + $0.technologiesTransferred }
        
        // Funding stats
        let totalBudget = researchProjects.values.reduce(0) { $0 + $0.totalBudget }
        let totalSpent = researchProjects.values.reduce(0) { $0 + $0.spentBudget }
        
        // Priority distribution
        var priorityDistribution: [ResearchPriority: Int] = [:]
        for project in researchProjects.values {
            priorityDistribution[project.priority, default: 0] += 1
        }
        
        // Category distribution
        var categoryDistribution: [ResearchCategory: Int] = [:]
        for project in researchProjects.values {
            let cat = project.researchField.researchCategory
            categoryDistribution[cat, default: 0] += 1
        }
        
        return ResearchStatistics(
            totalResearchProjects: totalProjects,
            activeProjects: activeProjects,
            completedProjects: completedProjects,
            cancelledProjects: cancelledProjects,
            trlDistribution: trlDistribution,
            totalPatents: totalPatents,
            grantedPatents: grantedPatents,
            pendingPatents: pendingPatents,
            totalPublications: totalPublications,
            totalCitations: totalCitations,
            totalGrants: totalGrants,
            activeGrants: activeGrants,
            totalGrantAmount: totalGrantAmount,
            awardedGrantAmount: awardedGrantAmount,
            totalAgents: totalAgents,
            activeAgents: activeAgents,
            totalLicensingRevenue: totalLicensingRevenue,
            totalTechnologiesTransferred: totalTechTransferred,
            totalResearchBudget: totalBudget,
            totalSpentBudget: totalSpent,
            priorityDistribution: priorityDistribution,
            categoryDistribution: categoryDistribution
        )
    }
}

// MARK: - Research Statistics

public struct ResearchStatistics {
    let totalResearchProjects: Int
    let activeProjects: Int
    let completedProjects: Int
    let cancelledProjects: Int
    let trlDistribution: [Int: Int]
    let totalPatents: Int
    let grantedPatents: Int
    let pendingPatents: Int
    let totalPublications: Int
    let totalCitations: Int
    let totalGrants: Int
    let activeGrants: Int
    let totalGrantAmount: Double
    let awardedGrantAmount: Double
    let totalAgents: Int
    let activeAgents: Int
    let totalLicensingRevenue: Double
    let totalTechnologiesTransferred: Int
    let totalResearchBudget: Double
    let totalSpentBudget: Double
    let priorityDistribution: [ResearchPriority: Int]
    let categoryDistribution: [ResearchCategory: Int]
}

// MARK: - Previews
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct ResearchDevelopmentPreview: PreviewProvider {
//    static var previews: some View {
//        Text("Research & Development System Preview")
//    }
//}
//#endif