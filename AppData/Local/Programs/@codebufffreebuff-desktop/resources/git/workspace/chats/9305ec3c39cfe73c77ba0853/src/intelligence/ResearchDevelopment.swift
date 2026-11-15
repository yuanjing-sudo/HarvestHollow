//
//  ResearchDevelopment.swift
//  Agricultural Economic Simulation
//

import Foundation

// Research area enum
public enum ResearchArea: String, CaseIterable {
    case cropGenetics = "crop_genetics"
    case agriculturalMachinery = "agricultural_machinery"
    case irrigation = "irrigation"
    case fertiliserEfficiency = "fertiliser_efficiency"
    case renewableEnergy = "renewable_energy"
    case manufacturing = "manufacturing"
    case robotics = "robotics"
    case logistics = "logistics"
    case medicine = "medicine"
    case education = "education"
    case environmentalScience = "environmental_science"
}

// Research project status
public enum ResearchStatus: String {
    case idle = "idle"
    case inProgress = "in_progress"
    case onHold = "on_hold"
    case completed = "completed"
    case failed = "failed"
}

// Research project
public struct ResearchProject: Identifiable {
    public let id: String
    public let area: ResearchArea
    public let title: String
    public let description: String
    public var funding: Double
    public let fundingRequired: Double
    public var progress: Double  // 0-1
    public let successProbability: Double  // 0-100%
    public var timeRemaining: Int  // periods
    public var researchStaff: Int
    public var researchInfrastructure: Double  // 0-1
    public var technologyMaturity: Double  // 0-1
    public var adoptionCost: Double
    public var timeToAdoption: Int  // periods until technology can be used
    public var productivityImprovement: Double  // percentage improvement when adopted
    public var maintenanceRequirements: Double  // Ongoing maintenance cost
    public var status: ResearchStatus
    public let started: Date
    public var completed: Date?
    
    public init(id: String, area: ResearchArea, title: String, description: String, funding: Double, fundingRequired: Double, progress: Double = 0, successProbability: Double = 50, timeRemaining: Int = 20, researchStaff: Int = 1, researchInfrastructure: Double = 0.5, technologyMaturity: Double = 1, adoptionCost: Double = 0, timeToAdoption: Int = 0, productivityImprovement: Double = 0, maintenanceRequirements: Double = 0, status: ResearchStatus = .idle, started: Date = Date(), completed: Date? = nil) {
        self.id = id
        self.area = area
        self.title = title
        self.description = description
        self.funding = funding
        self.fundingRequired = fundingRequired
        self.progress = progress
        self.successProbability = successProbability
        self.timeRemaining = timeRemaining
        self.researchStaff = researchStaff
        self.researchInfrastructure = researchInfrastructure
        self.technologyMaturity = technologyMaturity
        self.adoptionCost = adoptionCost
        self.timeToAdoption = timeToAdoption
        self.productivityImprovement = productivityImprovement
        self.maintenanceRequirements = maintenanceRequirements
        self.status = status
        self.started = started
        self.completed = completed
    }
}

// Technology level
public typealias TechnologyLevel = Int  // 1-10, sequential unlock levels

// Technology effect
public struct TechnologyEffect {
    public let area: ResearchArea
    public let level: TechnologyLevel
    public let description: String
    public let productivityBoost: Double  // percentage boost to relevant production
    public let costReduction: Double  // percentage cost reduction
    public let newCapabilities: [String]
    public let unlockRequirements: (researchLevel: TechnologyLevel, cost: Double, prerequisiteTechnology?: TechnologyLevel)
    
    public init(area: ResearchArea, level: TechnologyLevel, description: String, productivityBoost: Double, costReduction: Double, newCapabilities: [String], unlockRequirements: (researchLevel: TechnologyLevel, cost: Double, prerequisiteTechnology?: TechnologyLevel)) {
        self.area = area
        self.level = level
        self.description = description
        self.productivityBoost = productivityBoost
        self.costReduction = costReduction
        self.newCapabilities = newCapabilities
        self.unlockRequirements = unlockRequirements
    }
}

// Research management class
public class ResearchDevelopment {
    private var researchProjects: [String: ResearchProject] = [:]
    private var technologyLevels: [ResearchArea: TechnologyLevel] = [:]
    private let maxTechnologyLevel = 10
    private let researchCostBase = 100  // Base cost per period
    
    public init() {
        // Initialize technology levels at 1 (baseline) for all areas
        for area in ResearchArea.allCases {
            technologyLevels[area] = 1
        }
        
        // Initialize some baseline research projects
        initializeBaselineResearch()
    }
    
    // MARK: - Baseline Research Initialization
    
    private func initializeBaselineResearch() {
        // Create one idle research project per area
        for area in ResearchArea.allCases {
            let project: ResearchProject = ResearchProject(
                id: "research-\(area.rawValue)-\(Date.timeIntervalSince1970)",
                area: area,
                title: "Basic \(area.rawValue.replacingOccurrences(of: "_", with: " ")) Research",
                description: "Foundational research in \(area.rawValue.replacingOccurrences(of: "_", with: " "))",
                funding: 0,
                fundingRequired: researchCostBase,
                progress: 0,
                successProbability: 50,
                timeRemaining: 20,
                researchStaff: 1,
                researchInfrastructure: 0.5,
                technologyMaturity: 1,
                adoptionCost: 0,
                timeToAdoption: 0,
                productivityImprovement: 0,
                maintenanceRequirements: 0,
                status: .idle,
                started: Date(),
                completed: nil
            )
            
            researchProjects[project.id] = project
        }
    }
    
    // MARK: - Project Management
    
    public func getProject(id: String) -> ResearchProject? {
        return researchProjects[id]
    }
    
    public func getAllProjects() -> [ResearchProject] {
        return Array(researchProjects.values)
    }
    
    public func getTechnologyLevel(area: ResearchArea) -> TechnologyLevel {
        return technologyLevels[area] ?? 1
    }
    
    public func getAllTechnologyLevels() -> [ResearchArea: TechnologyLevel] {
        return technologyLevels
    }
    
    public func startProject(_ projectId: String) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        // Can only start idle or on-hold projects
        if project.status != .idle && project.status != .onHold { return false }
        
        // Check if funding is available
        if project.funding < project.fundingRequired { return false }
        
        // Start the project
        project.status = .inProgress
        project.started = Date()
        project.timeRemaining = calculateResearchTime(project)
        
        researchProjects[projectId] = project
        return true
    }
    
    private func calculateResearchTime(_ project: ResearchProject) -> Int {
        var baseTime = 20
        
        // Adjust for research staff
        let staffFactor = 1 + (Double(project.researchStaff) - 1) * 0.5
        
        // Adjust for infrastructure
        let infraFactor = 1 + (project.researchInfrastructure - 0.5) * 0.5
        
        // Adjust for technology maturity
        let maturityFactor = 1 - (project.technologyMaturity - 1) * 0.1
        
        // Adjust for success probability
        let probFactor = 100 / max(1, project.successProbability)
        
        return max(1, Int(baseTime * staffFactor * infraFactor * probFactor))
    }
    
    public mutating func advanceResearchPeriod() {
        let now = Date()
        
        for project in researchProjects.values where project.status == .inProgress {
            let elapsed = now.timeIntervalSince(project.started)
            
            project.timeRemaining = max(0, project.timeRemaining - 1)
            
            if project.timeRemaining <= 0 {
                completeProject(project)
            }
        }
    }
    
    private mutating func completeProject(_ project: ResearchProject) {
        // In a struct-based approach, we need to update the dictionary
        // This is a simplification - in a full implementation would use var researchProjects
        project.status = .completed
        project.completed = Date()
        project.progress = 1
        
        advanceTechnology(project)
        
        // Mark as idle (can be restarted for further research)
        project.status = .idle
        project.started = Date().timeIntervalSince1970  // Reset start time
        
        // Update in dictionary
        researchProjects[project.id] = project
    }
    
    private mutating func advanceTechnology(_ project: ResearchProject) {
        guard var currentLevel = technologyLevels[project.area] else { return }
        
        let improvement = project.productivityImprovement / 100  // Convert percentage
        let newLevel = min(maxTechnologyLevel, currentLevel + 1)
        
        if newLevel > currentLevel {
            technologyLevels[project.area] = newLevel
            applyTechnologyEffect(project.area, newLevel)
        }
        
        // Increase success probability for future research
        // project.successProbability = min(95, project.successProbability + 5)
    }
    
    private func applyTechnologyEffect(_ area: ResearchArea, _ level: TechnologyLevel) {
    }
    
    // MARK: - Funding
    
    public func fundProject(_ projectId: String, amount: Double) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        project.funding = max(0, project.funding + amount)
        
        if project.funding >= project.fundingRequired {
            return startProject(projectId)
        }
        
        researchProjects[projectId] = project
        return false
    }
    
    public mutating func recruitResearchStaff(_ projectId: String, additionalStaff: Int) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        project.researchStaff = max(1, project.researchStaff + additionalStaff)
        let staffCost = Double(additionalStaff) * 500
        project.funding = max(0, project.funding - staffCost)
        
        researchProjects[projectId] = project
        return true
    }
    
    public mutating func improveResearchInfrastructure(_ projectId: String, investment: Double) -> Bool {
        guard var project = researchProjects[projectId] else { return false }
        
        project.researchInfrastructure = min(1, project.researchInfrastructure + investment / 1000)
        project.fundingRequired = max(1, project.fundingRequired - investment * 0.1)
        
        researchProjects[projectId] = project
        return true
    }
    
    // MARK: - Summary
    
    public func getResearchSummary() -> (totalProjects: Int, inProgress: Int, completed: Int, failed: Int, byArea: [ResearchArea: (projectCount: Int, averageProgress: Double, averageLevel: TechnologyLevel, totalFunding: Double)], technologyLevels: [ResearchArea: TechnologyLevel], totalFundingCommitted: Double) {
        var totalProjects = 0
        var inProgress = 0
        var completed = 0
        var failed = 0
        var totalFundingCommitted: Double = 0
        
        var byArea: [ResearchArea: (projectCount: Int, averageProgress: Double, averageLevel: TechnologyLevel, totalFunding: Double)] = [:]
        
        // Initialize
        for area in ResearchArea.allCases {
            byArea[area] = (projectCount: 0, averageProgress: 0, averageLevel: 1, totalFunding: 0)
        }
        
        for project in researchProjects.values {
            totalProjects += 1
            totalFundingCommitted += project.funding
            
            guard let areaData = byArea[project.area] else { continue }
            let newCount = areaData.projectCount + 1
            let newProgress = (areaData.averageProgress * Double(areaData.projectCount) + project.progress) / Double(newCount)
            
            byArea[project.area] = (
                projectCount: newCount,
                averageProgress: newProgress,
                averageLevel: technologyLevels[project.area] ?? 1,
                totalFunding: areaData.totalFunding + project.funding
            )
            
            switch project.status {
            case .inProgress: inProgress += 1
            case .completed: completed += 1
            case .failed: failed += 1
            default: break
            }
        }
        
        return (totalProjects, inProgress, completed, failed, byArea, technologyLevels, totalFundingCommitted)
    }
    
    // MARK: - Technology Unlocks
    
    public func getTechnologyUnlocks() -> [ResearchArea: (currentLevel: TechnologyLevel, nextLevel: TechnologyLevel?, productivityBoost: Double, costReduction: Double, newCapabilities: [String], unlockCost: Double)] {
        var result: [ResearchArea: (currentLevel: TechnologyLevel, nextLevel: TechnologyLevel?, productivityBoost: Double, costReduction: Double, newCapabilities: [String], unlockCost: Double)] = [:]
        
        for area in ResearchArea.allCases {
            let currentLevel = technologyLevels[area] ?? 1
            let nextLevel = currentLevel < maxTechnologyLevel ? currentLevel + 1 : nil
            
            let levelProgress = Double(currentLevel - 1) / Double(maxTechnologyLevel - 1)
            let productivityBoost = levelProgress * 15  // Up to 15% boost
            let costReduction = levelProgress * 10  // Up to 10% cost reduction
            
            var newCapabilities: [String] = []
            if currentLevel >= 3 { newCapabilities.append("basic_efficiency") }
            if currentLevel >= 5 { newCapabilities.append("advanced_equipment") }
            if currentLevel >= 7 { newCapabilities.append("automation") }
            if currentLevel >= 9 { newCapabilities.append("optimization") }
            
            let unlockCost = max(1, researchCostBase * (1 - levelProgress) * 0.5)
            
            result[area] = (currentLevel, nextLevel, productivityBoost, costReduction, newCapabilities, unlockCost)
        }
        
        return result
    }
}