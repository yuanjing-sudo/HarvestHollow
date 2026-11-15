//
//  ProgressionObjectives.swift
//  Agricultural Economic Simulation
//

import Foundation

// Era enum
public enum Era: Int, CaseIterable {
    case beginnerFarmer = 1
    case establishedFarmer
    case agriculturalEntrepreneur
    case regionalBusinessOwner
    case economicLeader
    case industrialMagnate
    case economicArchitect
}

// Progression track enum
public enum ProgressionTrack: String {
    case playerLevel = "player_level"
    case researchLevel = "research_level"
    case businessLevel = "business_level"
    case influenceLevel = "influence_level"
}

// Level info
public struct LevelInfo {
    public let level: Int
    public let title: String
    public let era: Era
    public let xpRequired: Double
    public let eraNumber: Int
    public var objectives: [String]
    public var unlocks: [String]
    
    public init(level: Int, title: String, era: Era, xpRequired: Double, eraNumber: Int, objectives: [String] = [], unlocks: [String] = []) {
        self.level = level
        self.title = title
        self.era = era
        self.xpRequired = xpRequired
        self.eraNumber = eraNumber
        self.objectives = objectives
        self.unlocks = unlocks
    }
}

// XP curve: XP_n = 100 * n^1.65
func calculateXPRequired(_ level: Int) -> Double {
    Double(100 * pow(Double(level), 1.65))
}

// Pre-calculated XP for levels 1-30
let xpForLevel: [Double] = (1...30).map { calculateXPRequired($0) }

// Player progression state
public struct PlayerProgression {
    public var playerLevel: Int
    public var experience: Double
    public var era: Era
    public var trackProgress: [ProgressionTrack: Double]  // 0-100 per track
    public var completedObjectives: Set<String>
    public var unlockedFeatures: Set<String>
    public var skillPoints: Int
    public var prestigeLevel: Int
    
    public init(playerLevel: Int = 1, experience: Double = 0, era: Era = .beginnerFarmer, 
                trackProgress: [ProgressionTrack: Double] = [:], completedObjectives: Set<String> = Set(),
                unlockedFeatures: Set<String> = Set(), skillPoints: Int = 0, prestigeLevel: Int = 0) {
        self.playerLevel = playerLevel
        self.experience = experience
        self.era = era
        self.trackProgress = trackProgress.isEmpty ? [:] : trackProgress
        self.completedObjectives = completedObjectives
        self.unlockedFeatures = unlockedFeatures
        self.skillPoints = skillPoints
        self.prestigeLevel = prestigeLevel
    }
}

// Main progression system
public class ProgressionSystem {
    private var progression: PlayerProgression
    private var eraDescriptions: [Era: String] = [
        .beginnerFarmer: "Learn farming and establish the first production cycle",
        .establishedFarmer: "Expand land, livestock, machinery and commercial activity",
        .agriculturalEntrepreneur: "Develop businesses, employ workers and enter industrial production",
        .regionalBusinessOwner: "Build supply chains, logistics and regional economic influence",
        .economicLeader: "Manage complex finance, research, investment and economic shocks",
        .industrialMagnate: "Expand into international trade, advanced technology and large-scale industry",
        .economicArchitect: "Influence public policy, national development and the wider economy"
    ]
    
    public init() {
        self.progression = PlayerProgression()
    }
    
    // MARK: - Add Experience
    
    public mutating func addExperience(_ amount: Double) {
        progression.experience += amount
        
        // Check for level up
        while progression.playerLevel < 30 {
            let xpToNextLevel = xpForLevel[progression.playerLevel]  // XP from current level to next
            
            if progression.experience >= xpToNextLevel {
                progression.experience -= xpToNextLevel
                progression.playerLevel += 1
                checkEraAdvancement()
            } else {
                break
            }
        }
        
        // If at level 30 with excess XP, convert to skill points
        if progression.playerLevel >= 30 {
            let excessXP = progression.experience
            progression.skillPoints += Int(excessXP / 1000)
            progression.experience = 0
        }
    }
    
    // MARK: - Era Advancement
    
    private mutating func checkEraAdvancement() {
        let level = progression.playerLevel
        var newEra: Era
        
        if level <= 4 { newEra = .beginnerFarmer }
        else if level <= 8 { newEra = .establishedFarmer }
        else if level <= 12 { newEra = .agriculturalEntrepreneur }
        else if level <= 16 { newEra = .regionalBusinessOwner }
        else if level <= 20 { newEra = .economicLeader }
        else if level <= 25 { newEra = .industrialMagnate }
        else { newEra = .economicArchitect }
        
        if newEra != progression.era {
            progression.era = newEra
        }
    }
    
    // MARK: - Objective Completion
    
    public mutating func completeObjective(_ objectiveId: String) {
        progression.completedObjectives.insert(objectiveId)
        addExperience(500)  // Base objective XP
    }
    
    // MARK: - Feature Unlocking
    
    public func unlockFeature(_ featureId: String) -> Bool {
        // Check requirements
        let levelReq = getLevelRequirement(featureId)
        let trackReq = getTrackRequirement(featureId)
        let resourceReq = getResourceRequirement(featureId)
        
        let levelMet = progression.playerLevel >= levelReq
        let trackMet = progression.trackProgress[.playerLevel] ?? 0 >= trackReq
        let resourceMet = progression.experience >= resourceReq
        
        if levelMet && trackMet && resourceMet {
            progression.unlockedFeatures.insert(featureId)
            return true
        }
        
        return false
    }
    
    private func getLevelRequirement(_ featureId: String) -> Int {
        let requirements: [String: Int] = [
            "flour_mill": 10, "dairy_processing": 11, "warehouse_2": 14, "factory": 17,
            "bank": 18, "research_lab": 19, "international_trade": 21,
            "advanced_irrigation": 9, "irrigation_system": 10, "greenhouse": 12, "cold_storage": 11
        ]
        return requirements[featureId] ?? 1
    }
    
    private func getTrackRequirement(_ featureId: String) -> Double {
        // Each track unlocks every 4 levels
        return ceil(Double(progression.playerLevel) / 4.0)
    }
    
    private func getResourceRequirement(_ featureId: String) -> Double {
        let requirements: [String: Double] = [
            "flour_mill": 5000, "dairy_processing": 8000, "warehouse_2": 10000, "factory": 50000,
            "bank": 20000, "research_lab": 15000, "international_trade": 30000,
            "advanced_irrigation": 3000, "irrigation_system": 5000, "greenhouse": 10000, "cold_storage": 7000
        ]
        return requirements[featureId] ?? 0
    }
    
    // MARK: - Track Progress
    
    public mutating func gainTrackProgress(_ track: ProgressionTrack, amount: Double) {
        let current = progression.trackProgress[track] ?? 0
        let newProgress = min(100, current + amount)
        progression.trackProgress[track] = newProgress
        
        if newProgress >= 100 {
            addExperience(1000)
            progression.trackProgress[track] = 0
        }
    }
    
    // MARK: - Skill Points
    
    public mutating func spendSkillPoints(_ amount: Int) -> Int {
        let current = progression.skillPoints
        let spent = max(0, current - amount)
        progression.skillPoints = spent
        return current - spent
    }
    
    public mutating func gainSkillPoint() {
        progression.skillPoints += 1
    }
    
    // MARK: - Summary
    
    public func getProgressionSummary() -> (playerLevel: Int, experience: Double, era: Era, trackProgress: [ProgressionTrack: Double], skillPoints: Int, prestigeLevel: Int, unlockedFeatureCount: Int, totalFeatures: Int) {
        let totalFeatures = 50  // Would be dynamically determined
        let unlockedCount = progression.unlockedFeatures.count
        
        return (progression.playerLevel, progression.experience, progression.era, 
                progression.trackProgress, progression.skillPoints, progression.prestigeLevel,
                unlockedCount, totalFeatures)
    }
    
    // MARK: - Level Information
    
    public func getLevelInfo(_ level: Int? = nil) -> LevelInfo {
        let targetLevel = level ?? progression.playerLevel
        
        // Determine era
        var era: Era
        if targetLevel <= 4 { era = .beginnerFarmer }
        else if targetLevel <= 8 { era = .establishedFarmer }
        else if targetLevel <= 12 { era = .agriculturalEntrepreneur }
        else if targetLevel <= 16 { era = .regionalBusinessOwner }
        else if targetLevel <= 20 { era = .economicLeader }
        else if targetLevel <= 25 { era = .industrialMagnate }
        else { era = .economicArchitect }
        
        // Determine title
        let titles: [Int: String] = [
            1: "Newcomer", 2: "Gardener", 3: "Smallholder", 4: "Local Farmer",
            5: "Farm Operator", 6: "Livestock Keeper", 7: "Agricultural Specialist", 8: "Commercial Farmer",
            9: "Entrepreneur", 10: "Producer", 11: "Business Owner", 12: "Market Competitor",
            13: "Industrialist", 14: "Regional Trader", 15: "Infrastructure Investor", 16: "Regional Tycoon",
            17: "Financial Strategist", 18: "Economic Analyst", 19: "Financial Powerhouse", 20: "Economic Influencer",
            21: "Technology Investor", 22: "Industrial Leader", 23: "International Entrepreneur", 24: "Corporate Conglomerate", 25: "Global Magnate",
            26: "Public Policy Advisor", 27: "National Development Leader", 28: "Economic Architect", 29: "World Economic Leader", 30: "Master Architect"
        ]
        
        let title = titles[targetLevel] ?? "Player"
        
        // Objectives for this level
        let objectives = getLevelObjectives(targetLevel)
        
        // Unlocks for this level
        let unlocks = getLevelUnlocks(targetLevel)
        
        let xpRequired = targetLevel <= 30 ? xpForLevel[targetLevel - 1] : 0
        
        return LevelInfo(level: targetLevel, title: title, era: era, xpRequired: xpRequired, eraNumber: Int(ceil(Double(targetLevel) / 4.0)), objectives: objectives, unlocks: unlocks)
    }
    
    private func getLevelObjectives(_ level: Int) -> [String] {
        let objectivesByLevel: [Int: [String]] = [
            1: ["Establish basic farm", "Plant first crops", "Build animal enclosure"],
            2: ["Improve crop quality", "Learn crop rotation", "Sell first produce"],
            3: ["Breed first livestock", "Set up feeding system", "Basic animal care"],
            4: ["Market stall setup", "Earn first meaningful profit", "Complete first season"],
            5: ["Purchase additional land", "Build storage buildings", "Set up milk production"],
            6: ["Breed livestock", "Veterinary care", "Advanced animal genetics"],
            7: ["Advanced seeds", "Soil nutrients", "Irrigation setup", "Weather forecasts"],
            8: ["Tractors and machinery", "Hired workers", "Farm loans", "Supply contracts"],
            9: ["Hire permanent workers", "Farm company setup", "Basic accounting"],
            10: ["Flour mills", "Dairy processing", "Food production", "Manufacturing chains"],
            11: ["Multiple farms", "Business ownership", "Employee wages", "Business expenses"],
            12: ["Supply-demand pricing", "Market competition", "Inventory speculation", "Consumer demand"],
            13: ["Large factories", "Industrial workers", "Advanced production"],
            14: ["Regional markets", "Imports", "Exports", "Transport networks"],
            15: ["Roads, railways, warehouses", "Electricity and water infrastructure"],
            16: ["Regional economic indicators", "Competitors", "Population simulation"],
            17: ["Banking, business credit", "Investment portfolios", "Interest rates"],
            18: ["Comprehensive economic dashboard"],
            19: ["Mergers", "Acquisitions", "Bankruptcy"],
            20: ["Government contracts"],
            21: ["Research centres", "Automation", "Agricultural robotics"],
            22: ["Advanced manufacturing", "Technology licensing"],
            23: ["Foreign markets", "Global supply chains"],
            24: ["Holding companies", "Subsidiaries"],
            25: ["Global economic shocks"],
            26: ["Government policy simulations"],
            27: ["National development projects"],
            28: ["Advanced policy simulations"],
            29: ["International development partnerships"],
            30: ["Full sandbox governance"]
        ]
        
        return objectivesByLevel[level] ?? ["Continue progression"]
    }
    
    private func getLevelUnlocks(_ level: Int) -> [String] {
        let unlocksByLevel: [Int: [String]] = [
            1: ["Basic crop seeds", "Simple tools", "Basic enclosure"],
            2: ["Tomato seeds", "Potato seeds", "Fertiliser", "Crop rotation"],
            3: ["Chickens", "Eggs", "Animal feeding", "Animal care"],
            4: ["Market stalls", "Selling produce", "Basic market prices"],
            5: ["Larger plots", "Land purchases", "Cows", "Milk production"],
            6: ["Pigs", "Sheep", "Breeding", "Animal genetics"],
            7: ["Advanced seeds", "Soil nutrients", "Irrigation", "Weather forecasts"],
            8: ["Tractors", "Harvesting machinery", "Hired workers", "Farm loans"],
            9: ["Farm company", "Basic accounting", "Permanent workers"],
            10: ["Flour mills", "Dairy processing", "Food production"],
            11: ["Multiple farms", "Business ownership", "Employee wages"],
            12: ["Supply-demand pricing", "Market competition"],
            13: ["Large factories", "Industrial workers", "Advanced production"],
            14: ["Regional markets", "Imports", "Exports", "Transport networks"],
            15: ["Infrastructure construction"],
            16: ["Regional economic indicators"],
            17: ["Banking institutions", "Corporate borrowing"],
            18: ["Comprehensive economic dashboard"],
            19: ["Mergers", "Acquisitions", "Bankruptcy"],
            20: ["Government contracts"],
            21: ["Research centres", "Automation", "Agricultural robotics"],
            22: ["Advanced manufacturing", "Technology licensing"],
            23: ["Foreign markets", "Global supply chains"],
            24: ["Holding companies", "Subsidiaries"],
            25: ["Global economic shocks"],
            26: ["Government policy simulations"],
            27: ["National development projects"],
            28: ["Advanced policy simulations"],
            29: ["International development partnerships"],
            30: ["Full sandbox governance"]
        ]
        
        return unlocksByLevel[level] ?? []
    }
}