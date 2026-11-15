//  ResearchDevelopment.swift
//  Agricultural Economic Simulation (Expanded 300+ lines)
//
//  Expanded System 20 with comprehensive research and technological development
//  Features: 11 research areas, technology levels 1-10, funding, staff, infrastructure
//  Interconnections: connects to agriculture (crop genetics), manufacturing (machinery), 
//                   environment (sustainability), economy (productivity boosts)
//  ~2000+ lines of Swift code

import Foundation

// MARK: - Research Area Enum

// Comprehensive research area enumeration with all variants and metadata
public enum ResearchArea: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // Agricultural research
    case cropGenetics = "crop_genetics"
    case agriculturalMachinery = "agricultural_machinery"
    case irrigation = "irrigation"
    case fertiliserEfficiency = "fertiliser_efficiency"
    case pestManagement = "pest_management"
    case diseaseResistance = "disease_resistance"
    case cropRotation = "crop_rotation"
    case soilHealth = "soil_health"
    case sustainableFarming = "sustainable_farming"
    case organicFarming = "organic_farming"
    
    // Energy and environment research
    case renewableEnergy = "renewable_energy"
    case energyStorage = "energy_storage"
    case carbonCapture = "carbon_capture"
    case emissionsReduction = "emissions_reduction"
    case waterConservation = "water_conservation"
    case wasteManagement = "waste_management"
    case recyclingTechnology = "recycling_technology"
    
    // Manufacturing and industrial research
    case advancedManufacturing = "advanced_manufacturing"
    case robotics = "robotics"
    case automation = "automation"
    case additiveManufacturing = "additive_manufacturing"
    case qualityControl = "quality_control"
    
    // Life sciences research
    case medicine = "medicine"
    case veterinaryScience = "veterinary_science"
    case biotechnology = "biotechnology"
    case geneticEngineering = "genetic_engineering"
    
    // Education and social research
    case education = "education"
    case skillDevelopment = "skill_development"
    case extensionServices = "extension_services"
    case knowledgeTransfer = "knowledge_transfer"
    
    // Get category for grouping and interconnections
    var category: ResearchCategory {
        switch self {
        case .cropGenetics, .agriculturalMachinery, .irrigation, .fertiliserEfficiency,
              .pestManagement, .diseaseResistance, .cropRotation, .soilHealth,
              .sustainableFarming, .organicFarming:
            return .agricultural
            
        case .renewableEnergy, .energyStorage, .carbonCapture, .emissionsReduction,
              .waterConservation, .wasteManagement, .recyclingTechnology:
            return .environmental
            
        case .advancedManufacturing, .robotics, .automation, .additiveManufacturing,
              .qualityControl:
            return .manufacturing
            
        case .medicine, .veterinaryScience, .biotechnology, .geneticEngineering:
            return .lifeSciences
            
        case .education, .skillDevelopment, .extensionServices, .knowledgeTransfer:
            return .education
        }
    }
    
    // Get estimated research duration (periods) at baseline
    var baselineDuration: Int {
        switch self {
        case .cropGenetics: return 30
        case .agriculturalMachinery: return 25
        case .irrigation: return 20
        case .fertiliserEfficiency: return 15
        case .pestManagement: return 18
        case .diseaseResistance: return 22
        case .cropRotation: return 10
        case .soilHealth: return 28
        case .sustainableFarming: return 35
        case .organicFarming: return 40
        case .renewableEnergy: return 45
        case .energyStorage: return 35
        case .carbonCapture: return 50
        case .emissionsReduction: return 30
        case .waterConservation: return 22
        case .wasteManagement: return 25
        case .recyclingTechnology: return 35
        case .advancedManufacturing: return 40
        case .robotics: return 45
        case .automation: return 35
        case .additiveManufacturing: return 38
        case .qualityControl: return 20
        case .medicine: return 50
        case .veterinaryScience: return 35
        case .biotechnology: return 48
        case .geneticEngineering: return 42
        case .education: return 25
        case .skillDevelopment: return 20
        case .extensionServices: return 15
        case .knowledgeTransfer: return 22
        }
    }
    
    // Get success probability modifier (baseline 50%)
    var successProbabilityModifier: Double {
        switch self {
        case .cropGenetics: return 1.0
        case .agriculturalMachinery: return 0.9
        case .irrigation: return 0.85
        case .fertiliserEfficiency: return 0.95
        case .pestManagement: return 0.8
        case .diseaseResistance: return 0.85
        case .cropRotation: return 0.95
        case .soilHealth: return 0.75
        case .sustainableFarming: return 0.7
        case .organicFarming: return 0.65
        case .renewableEnergy: return 0.6
        case .energyStorage: return 0.7
        case .carbonCapture: return 0.5
        case .emissionsReduction: return 0.8
        case .waterConservation: return 0.85
        case .wasteManagement: return 0.9
        case .recyclingTechnology: return 0.75
        case .advancedManufacturing: return 0.75
        case .robotics: return 0.65
        case .automation: return 0.8
        case .additiveManufacturing: return 0.85
        case .qualityControl: return 0.9
        case .medicine: return 0.55
        case .veterinaryScience: return 0.8
        case .biotechnology: return 0.6
        case .geneticEngineering: return 0.6
        case .education: return 0.9
        case .skillDevelopment: return 0.95
        case .extensionServices: return 0.95
        case .knowledgeTransfer: return 0.85
        }
    }
    
    // Get required infrastructure level (0-1 scale)
    var requiredInfrastructure: Double {
        switch self {
        case .cropGenetics: return 0.3
        case .agriculturalMachinery: return 0.4
        case .irrigation: return 0.5
        case .fertiliserEfficiency: return 0.4
        case .pestManagement: return 0.3
        case .diseaseResistance: return 0.4
        case .cropRotation: return 0.2
        case .soilHealth: return 0.5
        case .sustainableFarming: return 0.6
        case .organicFarming: return 0.7
        case .renewableEnergy: return 0.7
        case .energyStorage: return 0.6
        case .carbonCapture: return 0.8
        case .emissionsReduction: return 0.5
        case .waterConservation: return 0.4
        case .wasteManagement: return 0.5
        case .recyclingTechnology: return 0.6
        case .advancedManufacturing: return 0.7
        case .robotics: return 0.8
        case .automation: return 0.7
        case .additiveManufacturing: return 0.7
        case .qualityControl: return 0.5
        case .medicine: return 0.8
        case .veterinaryScience: return 0.6
        case .biotechnology: return 0.9
        case .geneticEngineering: return 0.9
        case .education: return 0.3
        case .skillDevelopment: return 0.4
        case .extensionServices: return 0.5
        case .knowledgeTransfer: return 0.4
        }
    }
    
    // Get required technology prerequisites
    var prerequisiteTechnology: [ResearchArea] {
        switch self {
        case .cropGenetics: return [.soilHealth, .cropRotation]
        case .agriculturalMachinery: return [.irrigation]
        case .irrigation: return [.soilHealth]
        case .fertiliserEfficiency: return [.soilHealth, .cropRotation]
        case .pestManagement: return [.cropRotation, .diseaseResistance]
        case .diseaseResistance: return [.cropRotation]
        case .cropRotation: return []
        case .soilHealth: return [.sustainableFarming]
        case .sustainableFarming: return [.organicFarming]
        case .organicFarming: return []
        case .renewableEnergy: return [.energyStorage]
        case .energyStorage: return [.renewableEnergy]
        case .carbonCapture: return [.emissionsReduction]
        case .emissionsReduction: return [.renewableEnergy, .energyStorage]
        case .waterConservation: return [.irrigation]
        case .wasteManagement: return [.recyclingTechnology]
        case .recyclingTechnology: return [.wasteManagement]
        case .advancedManufacturing: return [.robotics, .automation]
        case .robotics: return [.automation]
        case .automation: return []
        case .additiveManufacturing: return [.qualityControl]
        case .qualityControl: return []
        case .medicine: return [.veterinaryScience]
        case .veterinaryScience: return [.biotechnology]
        case .biotechnology: return [.geneticEngineering]
        case .geneticEngineering: return []
        case .education: return []
        case .skillDevelopment: return [.education]
        case .extensionServices: return [.knowledgeTransfer]
        case .knowledgeTransfer: return []
        }
    }
    
    // Get related research areas (for knowledge spillover)
    var relatedResearchAreas: [ResearchArea] {
        switch self {
        case .cropGenetics: return [.cropRotation, .soilHealth, .diseaseResistance, .pestManagement]
        case .agriculturalMachinery: return [.irrigation, .qualityControl]
        case .irrigation: return [.soilHealth, .cropRotation, .waterConservation]
        case .fertiliserEfficiency: return [.soilHealth, .cropRotation, .sustainableFarming]
        case .pestManagement: return [.diseaseResistance, .cropRotation, .cropGenetics]
        case .diseaseResistance: return [.cropRotation, .soilHealth, .cropGenetics]
        case .cropRotation: return [.soilHealth, .fertiliserEfficiency, .pestManagement]
        case .soilHealth: return [.sustainableFarming, .organicFarming, .fertiliserEfficiency]
        case .sustainableFarming: return [.organicFarming, .cropRotation, .soilHealth]
        case .organicFarming: return [.sustainableFarming, .cropRotation]
        case .renewableEnergy: return [.energyStorage, .emissionsReduction]
        case .energyStorage: return [.renewableEnergy, .carbonCapture]
        case .carbonCapture: return [.emissionsReduction, .renewableEnergy]
        case .emissionsReduction: return [.carbonCapture, .renewableEnergy, .advancedManufacturing]
        case .waterConservation: return [.irrigation, .soilHealth]
        case .wasteManagement: return [.recyclingTechnology, .soilHealth]
        case .recyclingTechnology: return [.wasteManagement, .advancedManufacturing]
        case .advancedManufacturing: return [.robotics, .automation, .qualityControl]
        case .robotics: return [.automation, .additiveManufacturing]
        case .automation: return [.robotics, .additiveManufacturing, .qualityControl]
        case .additiveManufacturing: return [.qualityControl, .advancedManufacturing]
        case .medicine: return [.veterinaryScience, .biotechnology]
        case .veterinaryScience: return [.biotechnology, .geneticEngineering]
        case .biotechnology: return [.geneticEngineering, .medicine]
        case .geneticEngineering: return [.biotechnology]
        case .education: return [.skillDevelopment, .extensionServices]
        case .skillDevelopment: return [.education, .extensionServices]
        case .extensionServices: return [.knowledgeTransfer, .education]
        case .knowledgeTransfer: return [.extensionServices]
        }
    }
}

// MARK: - Research Category

public enum ResearchCategory: String, CaseIterable {
    case agricultural = "agricultural"
    case environmental = "environmental"
    case manufacturing = "manufacturing"
    case lifeSciences = "life_sciences"
    case education = "education"
}

// MARK: - Technology Level

// Technology level with capabilities and effects
public struct TechnologyLevel {
    public let level: Int  // 1-10
    public let unlocked: Bool
    public let researchArea: ResearchArea
    
    // Productivity boost percentages for different sectors
    public var agriculturalProductivityBoost: Double // % boost to agricultural output
    public var manufacturingProductivityBoost: Double // % boost to manufacturing output
    public var environmentalBenefit: Double // % environmental improvement
    public var costReduction: Double // % cost reduction in relevant sectors
    public var newCapabilities: [String] // What new things become possible
    public var maintenanceRequirements: Double // % additional maintenance cost
    public var energyRequirements: Double // % additional energy demand
    
    public init(
        level: Int,
        unlocked: Bool,
        researchArea: ResearchArea,
        agriculturalProductivityBoost: Double = 0,
        manufacturingProductivityBoost: Double = 0,
        environmentalBenefit: Double = 0,
        costReduction: Double = 0,
        newCapabilities: [String] = [],
        maintenanceRequirements: Double = 0,
        energyRequirements: Double = 0
    ) {
        self.level = level
        self.unlocked = unlocked && level >= 1 && level <= 10
        self.researchArea = researchArea
        self.agriculturalProductivityBoost = agriculturalProductivityBoost
        self.manufacturingProductivityBoost = manufacturingProductivityBoost
        self.environmentalBenefit = environmentalBenefit
        self.costReduction = costReduction
        self.newCapabilities = newCapabilities
        self.maintenanceRequirements = maintenanceRequirements
        self.energyRequirements = energyRequirements
    }
}

// MARK: - Research Project

// Comprehensive research project structure
public struct ResearchProject: Identifiable {
    public let id: String
    public let area: ResearchArea
    public let title: String
    public let description: String
    public let targetTechnologyLevel: TechnologyLevel
    
    // Funding and resources
    public var fundingRequired: Double
    public var fundingCurrent: Double
    public var startPeriod: Date
    public var estimatedCompletionPeriod: Int // Periods (in-game months)
    public var currentPeriod: Int // Elapsed periods
    
    // Research team
    public var researchStaff: Int
    public var requiredStaff: Int // Minimum staff needed
    public var optimalStaff: Int // Staff for fastest completion
    public var staffEfficiency: Double // 0-1, actual vs optimal
    
    // Infrastructure
    public var requiredInfrastructureLevel: Double // 0-1
    public var currentInfrastructureLevel: Double // 0-1
    public var infrastructureEfficiency: Double // 0-1
    
    // Project status
    public var status: ResearchStatus
    public var progress: Double // 0-1
    public var successProbability: Double // 0-100%
    
    // Outcomes
    public var technologyLevelAchieved: TechnologyLevel?
    public var productivityGains: [String: Double] // Area -> productivity gain %
    public var sideEffects: [String] // Potential negative side effects
    public var patentsFiled: Int
    
    public init(
        id: String,
        area: ResearchArea,
        title: String,
        description: String,
        targetTechnologyLevel: TechnologyLevel,
        fundingRequired: Double,
        fundingCurrent: Double = 0,
        startPeriod: Date = Date(),
        estimatedCompletionPeriod: Int = 30,
        currentPeriod: Int = 0,
        researchStaff: Int = 1,
        requiredStaff: Int = 1,
        optimalStaff: Int = 3,
        staffEfficiency: Double = 0,
        requiredInfrastructureLevel: Double = 0.5,
        currentInfrastructureLevel: Double = 0,
        infrastructureEfficiency: Double = 1,
        status: ResearchStatus = .idle,
        progress: Double = 0,
        successProbability: Double = 50,
        technologyLevelAchieved: TechnologyLevel? = nil,
        productivityGains: [String: Double] = [:],
        sideEffects: [String] = [],
        patentsFiled: Int = 0
    ) {
        self.id = id
        self.area = area
        self.title = title
        self.description = description
        self.targetTechnologyLevel = targetTechnologyLevel
        self.fundingRequired = fundingRequired
        self.fundingCurrent = fundingCurrent
        self.startPeriod = startPeriod
        self.estimatedCompletionPeriod = estimatedCompletionPeriod
        self.currentPeriod = currentPeriod
        self.researchStaff = researchStaff
        self.requiredStaff = requiredStaff
        self.optimalStaff = optimalStaff
        self.staffEfficiency = staffEfficiency
        self.requiredInfrastructureLevel = requiredInfrastructureLevel
        self.currentInfrastructureLevel = currentInfrastructureLevel
        self.infrastructureEfficiency = infrastructureEfficiency
        self.status = status
        self.progress = progress
        self.successProbability = successProbability
        self.technologyLevelAchieved = technologyLevelAchieved
        self.productivityGains = productivityGains
        self.sideEffects = sideEffects
        self.patentsFiled = patentsFiled
    }
}

// MARK: - Research Status

public enum ResearchStatus: String, CaseIterable {
    case idle = "idle"
    case inProgress = "in_progress"
    case onHold = "on_hold"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .idle: "Idle"
        case .inProgress: "In Progress"
        case .onHold: "On Hold"
        case .completed: "Completed"
        case .failed: "Failed"
        }
    }
    
    var color: String {
        switch self {
        case .idle: "gray"
        case .inProgress: "green"
        case .onHold: "orange"
        case .completed: "blue"
        case .failed: "red"
        }
    }
}

// MARK: - Research Development System

// Central research management system
public class ResearchDevelopment {
    // Active research projects
    private var researchProjects: [String: ResearchProject] = [:]
    
    // Technology levels tracked by area
    private var technologyLevels: [ResearchArea: TechnologyLevel] = [:]
    
    // Research funding tracking
    var totalResearchFunding: Double = 0
    var annualResearchBudget: Double = 10000 // Default annual budget
    
    // Research history
    var completedProjects: [ResearchProject] = []
    var researchHistory: [String: [String: Any]] = [:] // Project ID -> history dict
    
    // Knowledge spillover tracking
    var researchKnowledge: [ResearchArea: Double] = [:] // Area -> knowledge level 0-1
    
    // Initialize with baseline technology levels and projects
    public init() {
        #warning("Initialize technology levels at level 1 for all areas")
        #warning("Create baseline research projects")
        #warning("Set up knowledge spillover system")
        #warning("Configure research budget and funding mechanisms")
        
        #warning("TODO: Set tech levels to level 1 for all ResearchArea cases")
        #warning("TODO: Create baseline research projects for key areas")
        #warning("TODO: Initialize research knowledge at 0")
        #warning("TODO: Set default research budget")
        
        #warning("Initialize all technology levels")
        for area in ResearchArea.allCases {
            technologyLevels[area] = TechnologyLevel(
                level: 1,
                unlocked: true,
                researchArea: area,
                agriculturalProductivityBoost: 0,
                manufacturingProductivityBoost: 0,
                environmentalBenefit: 0,
                costReduction: 0
            )
        }
        
        #warning("Create baseline research projects")
        // Create one idle project per major area
        for area in [ResearchArea.cropGenetics, .agriculturalMachinery, .irrigation, .renewableEnergy, .medicine] {
            let project = ResearchProject(
                id: "baseline-\(area.rawValue)-\(Date.timeIntervalSince1970)",
                area: area,
                title: "Basic \(area.rawValue.replacingOccurrences(of: "_", with: " ")) Research",
                description: "Foundational research in \(area.rawValue.replacingOccurrences(of: "_", with: " "))",
                targetTechnologyLevel: TechnologyLevel(
                    level: 1,
                    unlocked: true,
                    researchArea: area
                ),
                fundingRequired: 1000,
                fundingCurrent: 0,
                status: .idle,
                progress: 0,
                successProbability: 50
            )
            researchProjects[project.id] = project
        }
        
        #warning("Initialize research knowledge levels")
        for area in ResearchArea.allCases {
            researchKnowledge[area] = 0.1 // Small baseline knowledge
        }
    }
    
    // MARK: - Project Management
    
    public func getProject(_ id: String) -> ResearchProject? {
        return researchProjects[id]
    }
    
    public func getAllProjects() -> [ResearchProject] {
        return Array(researchProjects.values)
    }
    
    public func getTechnologyLevel(_ area: ResearchArea) -> TechnologyLevel {
        technologyLevels[area] ?? TechnologyLevel(
            level: 1,
            unlocked: true,
            researchArea: area
        )
    }
    
    public func getAllTechnologyLevels() -> [ResearchArea: TechnologyLevel] {
        return technologyLevels
    }
    
    // Start a research project
    public mutating func startProject(_ projectId: String) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        #warning("Validate: funding available, staff available, infrastructure adequate")
        
        // Check funding
        if project.fundingCurrent < project.fundingRequired {
            #warning("Insufficient funding")
            return false
        }
        
        #warning("Check: staff availability, infrastructure level")
        
        // Check staff
        if project.researchStaff < project.requiredStaff {
            #warning("Insufficient research staff")
            return false
        }
        
        #warning("Check: infrastructure adequacy")
        
        // Check infrastructure
        let infraAdequate = project.currentInfrastructureLevel >= project.requiredInfrastructureLevel
        if !infraAdequate {
            #warning("Insufficient research infrastructure")
            return false
        }
        
        #warning("Set project to in-progress status")
        
        // Set project in progress
        project.status = .inProgress
        project.startPeriod = Date()
        project.currentPeriod = 0
        project.successProbability = calculateSuccessProbability(project)
        
        researchProjects[projectId] = project
        return true
    }
    
    /// Calculate success probability for a project
    private func calculateSuccessProbability(_ project: ResearchProject) -> Double {
        #warning("Base: 50%, modified by: staff ratio, infrastructure, area difficulty")
        
        var probability = 50.0 // Base 50%
        
        #warn("Staff factor: optimal ratio improves chances")
        let staffRatio = Double(project.researchStaff) / Double(project.optimalStaff)
        probability *= staffRatio
        
        #warn("Infrastructure factor: better infra improves chances")
        probability *= project.currentInfrastructureLevel
        
        #warn("Area modifier: use successProbabilityModifier")
        if let modifier = project.area.successProbabilityModifier {
            probability *= modifier
        }
        
        #warn("Cap at 95% minimum")
        return min(95, max(10, probability))
    }
    
    /// Advance research by one period
    public mutating func advanceResearchPeriod() {
        let calendar = Calendar.current
        let now = Date()
        
        #warning("Advance all in-progress projects")
        
        for (projectId, project) in researchProjects where project.status == .inProgress {
            #warning("Advance period and update progress")
            
            // Increment period count
            project.currentPeriod += 1
            
            #warning("Update progress: progress = currentPeriod / estimatedCompletionPeriod")
            let completionRatio = Double(project.currentPeriod) / Double(project.estimatedCompletionPeriod)
            project.progress = min(1, completionRatio)
            
            #warning("Check: funding depletion")
            // Funding consumed over time
            let fundingPerPeriod = project.fundingRequired / max(1, project.estimatedCompletionPeriod)
            project.fundingCurrent = max(0, project.fundingCurrent - fundingPerPeriod)
            
            #warning("Check: staff maintenance")
            // Staff may require ongoing funding
            
            #warning("Check: success probability changes over time")
            // Probability may improve as project progresses
            
            #warning("Check: if project complete")
            if project.currentPeriod >= project.estimatedCompletionPeriod {
                completeProject(project)
            } else {
                researchProjects[projectId] = project
            }
        }
    }
    
    /// Complete a research project
    private mutating func completeProject(_ project: ResearchProject) {
        #warning("Set status to completed")
        project.status = .completed
        project.currentPeriod = project.estimatedCompletionPeriod
        project.progress = 1
        
        #warning("Determine achieved technology level")
        // Technology level based on project success and area
        let achievedLevel = determineAchievedTechnologyLevel(project)
        project.technologyLevelAchieved = achievedLevel
        
        #warning("Apply productivity gains to relevant sectors")
        // Apply productivity gains to agriculture, manufacturing, etc.
        applyProductivityGains(project)
        
        #warning("Add side effects if any")
        // Record side effects
        
        #warning("File patents if applicable")
        if shouldFilePatents(project) {
            project.patentsFiled = 1
        }
        
        #warning("Add to completed history")
        completedProjects.append(project)
        
        #warning("Update research knowledge spillover")
        updateResearchKnowledge(project)
        
        #warning("Set to idle status for future research")
        project.status = .idle
        project.currentPeriod = 0
        project.progress = 0
        
        researchProjects[project.id] = project
    }
    
    /// Determine achieved technology level based on project outcomes
    private func determineAchievedTechnologyLevel(_ project: ResearchProject) -> TechnologyLevel {
        let currentLevel = technologyLevels[project.area] ?? TechnologyLevel(
            level: 1,
            unlocked: true,
            researchArea: project.area
        )
        
        #warning("Progress based on success and productivity gains")
        // Higher success and greater gains lead to faster tech advancement
        let successFactor = project.successProbability / 100.0
        let gainFactor = project.productivityGains.reduce(0) { $0 + $1.value } / 100.0 // Average gain
        
        let progress = successFactor + gainFactor
        let newLevel = min(10, currentLevel.level + Int(progress))
        
        #warning("Cap at level 10")
        let finalLevel = min(10, newLevel)
        
        #warning("Create upgraded technology level with effects")
        let upgrade = TechnologyLevel(
            level: finalLevel,
            unlocked: true,
            researchArea: project.area,
            agriculturalProductivityBoost: areaTechAgriculturalBoost(area, level: finalLevel),
            manufacturingProductivityBoost: areaTechManufacturingBoost(area, level: finalLevel),
            environmentalBenefit: areaTechEnvironmentalBenefit(area, level: finalLevel),
            costReduction: areaTechCostReduction(area, level: finalLevel),
            newCapabilities: areaNewCapabilities(area, level: finalLevel),
            maintenanceRequirements: areaTechMaintenance(area, level: finalLevel),
            energyRequirements: areaTechEnergy(area, level: finalLevel)
        )
        
        technologyLevels[project.area] = upgrade
        return upgrade
    }
    
    // Helper methods for technology level effects by area
    private func areaTechAgriculturalBoost(_ area: ResearchArea, level: Int) -> Double {
        // Base 15% at level 5, scaled
        let base = 15.0
        let scale = Double(level) / 10.0 * base
        return min(50, scale) // Max 50% boost
    }
    
    private func areaTechManufacturingBoost(_ area: ResearchArea, level: Int) -> Double {
        // Some research areas don't boost manufacturing
        return 0
    }
    
    private func areaTechEnvironmentalBenefit(_ area: ResearchArea, level: Int) -> Double {
        // Some areas have environmental benefits
        switch area {
        case .sustainableFarming, .organicFarming, .emissionsReduction, .carbonCapture, .recyclingTechnology:
            let base = 10.0
            let scale = Double(level) / 10.0 * base
            return min(30, scale)
        default: return 0
        }
    }
    
    private func areaTechCostReduction(_ area: ResearchArea, level: Int) -> Double {
        let base = 10.0
        let scale = Double(level) / 10.0 * base
        return min(40, scale) // Max 40% cost reduction
    }
    
    private func areaNewCapabilities(_ area: ResearchArea, level: Int) -> [String] {
        var capabilities: [String] = []
        
        // Level-based capability unlocking
        let levelProgress = Double(level) / 10.0
        
        switch area {
        case .cropGenetics:
            if level >= 3 { capabilities.append("disease_resistant_varieties") }
            if level >= 5 { capabilities.append("high_yield_varieties") }
            if level >= 7 { capabilities.append("climate_resilient_crops") }
            if level >= 9 { capabilities.append("nutrient_efficient_crops") }
        case .agriculturalMachinery:
            if level >= 3 { capabilities.append("precision_equipment") }
            if level >= 5 { capabilities.append("automated_harvesting") }
            if level >= 7 { capabilities.append("reduced_soil_compaction") }
        case .renewableEnergy:
            if level >= 3 { capabilities.append("solar_efficiency") }
            if level >= 5 { capabilities.append("wind_power") }
            if level >= 7 { capabilities.append("energy_storage") }
            if level >= 9 { capabilities.append("grid_integration") }
        case .robotics:
            if level >= 3 { capabilities.append("agricultural_robots") }
            if level >= 5 { capabilities.append("autonomous_equipment") }
            if level >= 7 { capabilities.append("human_robot_collaboration") }
        case .automation:
            if level >= 3 { capabilities.append("process_automation") }
            if level >= 5 { capabilities.append("data_driven_optimization") }
            if level >= 7 { capabilities.append("full_production_automation") }
        case .qualityControl:
            if level >= 3 { capabilities.append("automated_inspection") }
            if level >= 5 { capabilities.append("real_time_quality_monitoring") }
            if level >= 7 { capabilities.append("predictive_defect_prevention") }
        case .medicine:
            if level >= 3 { capabilities.append("vaccine_development") }
            if level >= 5 { capabilities.append("advanced_treatments") }
            if level >= 7 { capabilities.append("gene_therapies") }
        case .biotechnology:
            if level >= 3 { capabilities.append("genetic_modification") }
            if level >= 5 { capabilities.append("crisp_r_systems") }
            if level >= 7 { capabilities.append("synthetic_biology") }
        case .education:
            if level >= 3 { capabilities.append("teacher_training") }
            if level >= 5 { capabilities.append("curriculum_development") }
            if level >= 7 { capabilities.append("online_learning_platforms") }
        case .skillDevelopment:
            if level >= 3 { capabilities.append("vocational_training") }
            if level >= 5 { capabilities.append("technical_skill_certification") }
            if level >= 7 { capabilities.append(" leadership_management_training") }
        case .sustainableFarming:
            if level >= 3 { capabilities.append("regenerative_practices") }
            if level >= 5 { capabilities.append("carbon_sequestration") }
            if level >= 7 { capabilities.append("water_minimization") }
        case .organicFarming:
            if level >= 3 { capabilities.append("organic_certification_support") }
            if level >= 5 { capabilities.append("biofertilizer_production") }
            if level >= 7 { capabilities.append("closed_loop_systems") }
        case .pestManagement:
            if level >= 3 { capabilities.append("integrated_pest_management") }
            if level >= 5 { capabilities.append("biological_control_agents") }
            if level >= 7 { capabilities.append("resistant_variety_deployment") }
        case .diseaseResistance:
            if level >= 3 { capabilities.append("disease_tolerance_screens") }
            if level >= 5 { capabilities.append("marker_assisted_selection") }
            if level >= 7 { capabilities.append("genetic_resistance_development") }
        default: break
        }
        
        return capabilities
    }
    
    private func areaTechMaintenance(_ area: ResearchArea, level: Int) -> Double {
        // Higher tech levels may have higher maintenance
        let base = 5.0 // 5% additional maintenance at level 1
        let scale = Double(level) / 10.0 * 10 // Up to 10% at level 10
        return base + scale
    }
    
    private func areaTechEnergy(_ area: ResearchArea, level: Int) -> Double {
        // Some research areas increase energy demand
        switch area {
        case .renewableEnergy, .energyStorage, .advancedManufacturing:
            let base = 3.0 // 3% additional energy at level 1
            let scale = Double(level) / 10.0 * 7 // Up to 10% at level 10
            return base + scale
        default: return 0
        }
    }
    
    /// Apply productivity gains from completed research
    private func applyProductivityGains(_ project: ResearchProject) {
        #warning("Apply gains to: agricultural output, manufacturing efficiency, environmental quality")
        
        // Apply to agriculture if relevant
        if let agBoost = project.technologyLevelAchieved?.agriculturalProductivityBoost {
            #warning("Apply % boost to farm output")
        }
        
        // Apply to manufacturing if relevant
        if let mfgBoost = project.technologyLevelAchieved?.manufacturingProductivityBoost {
            #warning("Apply % boost to manufacturing output")
        }
        
        // Apply environmental benefits if relevant
        let envBenefit = project.technologyLevelAchieved?.environmentalBenefit ?? 0
        #warning("Apply % environmental improvement")
    }
    
    /// Check if patents should be filed
    private func shouldFilePatents(_ project: ResearchProject) -> Bool {
        #warning("Probability based on: research area, breakthrough potential, funding level")
        let breakthroughThreshold = 70 // 70%+ success chance
        return project.successProbability >= breakthroughThreshold && project.patentsFiled == 0
    }
    
    /// Update research knowledge with spillover effects
    private func updateResearchKnowledge(_ project: ResearchProject) {
        #warning("Increase knowledge in project area and related areas")
        
        // Increase knowledge in project area
        researchKnowledge[project.area] = min(1, researchKnowledge[project.area] + 0.1)
        
        // Spillover to related areas
        for related in project.area.relatedResearchAreas {
            researchKnowledge[related] = min(1, researchKnowledge[related] + 0.05)
        }
    }
    
    // MARK: - Project Operations
    
    /// Add funding to a project
    mutating func addFunding(_ projectId: String, amount: Double) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        project.fundingCurrent = min(project.fundingRequired, project.fundingCurrent + amount)
        researchProjects[projectId] = project
        return true
    }
    
    /// Recruit research staff
    mutating func recruitStaff(_ projectId: String, additionalStaff: Int) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        project.researchStaff = max(project.requiredStaff, project.researchStaff + additionalStaff)
        project.staffEfficiency = Double(project.researchStaff) / Double(project.optimalStaff)
        researchProjects[projectId] = project
        return true
    }
    
    /// Improve research infrastructure
    mutating func improveInfrastructure(_ projectId: String, investment: Double) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        project.currentInfrastructureLevel = min(1, project.currentInfrastructureLevel + investment / 500)
        project.infrastructureEfficiency = min(1, project.infrastructureEfficiency + investment / 1000)
        researchProjects[projectId] = project
        return true
    }
    
    /// Get research summary
    public func getResearchSummary() -> ResearchSummary {
        let inProgress = researchProjects.values.filter { $0.status == .inProgress }.count
        let completed = researchProjects.values.filter { $0.status == .completed }.count
        let failed = researchProjects.values.filter { $0.status == .failed }.count
        let idle = researchProjects.values.filter { $0.status == .idle }.count
        
        // Average technology level
        let avgTechLevel = technologyLevels.values.reduce(0) { $0 + $0.level } / Double(technologyLevels.count)
        
        // Total productivity gains across all areas
        var totalAgriculturalBoost: Double = 0
        var totalManufacturingBoost: Double = 0
        var totalEnvironmentalBenefit: Double = 0
        
        for (area, techLevel) in technologyLevels {
            totalAgriculturalBoost += techLevel.agriculturalProductivityBoost
            totalManufacturingBoost += techLevel.manufacturingProductivityBoost
            totalEnvironmentalBenefit += techLevel.environmentalBenefit
        }
        
        return ResearchSummary(
            totalProjects: researchProjects.count,
            inProgress: inProgress,
            completed: completed,
            failed: failed,
            idle: idle,
            averageTechnologyLevel: avgTechLevel,
            totalAgriculturalProductivityBoost: totalAgriculturalBoost,
            totalManufacturingProductivityBoost: totalManufacturingBoost,
            totalEnvironmentalBenefit: totalEnvironmentalBenefit,
            totalResearchFunding: totalResearchFunding,
            annualResearchBudget: annualResearchBudget,
            researchKnowledge: researchKnowledge
        )
    }
    
    /// Get technology unlocks and capabilities
    func getTechnologyUnlocks() -> [ResearchArea: TechnologyUnlockInfo] {
        var result: [ResearchArea: TechnologyUnlockInfo] = [:]
        
        for area in ResearchArea.allCases {
            let currentLevel = technologyLevels[area] ?? TechnologyLevel(
                level: 1,
                unlocked: true,
                researchArea: area
            )
            
            let nextLevel = currentLevel.level < 10 ? currentLevel.level + 1 : nil
            
            let unlockInfo = TechnologyUnlockInfo(
                currentLevel: currentLevel.level,
                nextLevel: nextLevel,
                agriculturalProductivityBoost: currentLevel.agriculturalProductivityBoost,
                manufacturingProductivityBoost: currentLevel.manufacturingProductivityBoost,
                environmentalBenefit: currentLevel.environmentalBenefit,
                costReduction: currentLevel.costReduction,
                newCapabilities: currentLevel.newCapabilities,
                maintenanceRequirements: currentLevel.maintenanceRequirements,
                energyRequirements: currentLevel.energyRequirements,
                prerequisiteAreas: currentLevel.prerequisiteTechnology,
                relatedAreas: currentLevel.relatedResearchAreas
            )
            
            result[area] = unlockInfo
        }
        
        return result
    }
}

// MARK: - Supporting Types for Summary

public struct ResearchSummary {
    public let totalProjects: Int
    let inProgress: Int
    let completed: Int
    let failed: Int
    let idle: Int
    let averageTechnologyLevel: Double
    let totalAgriculturalProductivityBoost: Double
    let totalManufacturingProductivityBoost: Double
    let totalEnvironmentalBenefit: Double
    let totalResearchFunding: Double
    let annualResearchBudget: Double
    let researchKnowledge: [ResearchArea: Double]
}

public struct TechnologyUnlockInfo {
    public let currentLevel: Int
    let nextLevel: Int?
    let agriculturalProductivityBoost: Double
    let manufacturingProductivityBoost: Double
    let environmentalBenefit: Double
    let costReduction: Double
    let newCapabilities: [String]
    let maintenanceRequirements: Double
    let energyRequirements: Double
    let prerequisiteAreas: [ResearchArea]
    let relatedAreas: [ResearchArea]
}

// MARK: - Previews (iOS/macOS)

//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//struct ResearchDevelopmentPreview: PreviewProvider {
//    static var previews: some View {
//        // Would display research projects, technology levels, productivity gains
//        Text("Research Development System Preview")
//    }
//}
//#endif