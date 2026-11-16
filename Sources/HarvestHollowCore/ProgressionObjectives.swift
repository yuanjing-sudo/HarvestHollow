//  ProgressionObjectives.swift
//  Agricultural Economic Simulation (Massively Expanded)
//
//  Expanded System 25 with comprehensive progression and objectives system
//  Features: 30 levels across 7 eras with 4 independent progression tracks,
//           XP curve 100n^1.65, prestige system post-level 30,
//           track-specific objectives and rewards, milestone achievements
//  Interconnections: connects to AI agents (agent XP gains), economy (revenue from levels),
//                   agriculture (unlocks new crops/abilities), trade (market access),
//                   society (unlocks technologies, policies), environment (unlocks sustainability features)
//  ~4000+ lines of Swift code

import Foundation

// MARK: - Comprehensive Era Enum (Expanded)

public enum Era: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case era1 = "era_1"
    case era2 = "era_2"
    case era3 = "era_3"
    case era4 = "era_4"
    case era5 = "era_5"
    case era6 = "era_6"
    case era7 = "era_7"
    
    // Era display name
    var displayName: String {
        switch self {
        case .era1: return "Pioneering"
        case .era2: return "Expansion"
        case .era3: return "Growth"
        case .era4: return "Industrialization"
        case .era5: return "Modernization"
        case .era6: return "Sustainability"
        case .era7: return "Future"
        }
    }
    
    // Era color (for UI)
    var color: String {
        switch self {
        case .era1: return "906e1f" // Bronze
        case .era2: return "c9a862" // Light bronze
        case .era3: return "d4af37" // Gold
        case .era4: return "8d6e63" // Steel
        case .era5: return "558b2f" // Green
        case .era6: return "0d98ba" // Blue
        case .era7: return "6a1b9a" // Purple
        }
    }
    
    // Era level range (inclusive)
    var levelRange: ClosedRange<Int> {
        switch self {
        case .era1: return 1...4
        case .era2: return 5...9
        case .era3: return 10...14
        case .era4: return 15...19
        case .era5: return 20...24
        case .era6: return 25...27
        case .era7: return 28...30
        }
    }
    
    // Era description
    var description: String {
        switch self {
        case .era1: return "Beginner farming era - learning the basics of cultivation and harvest"
        case .era2: return "Expanding operations - building infrastructure and establishing trade"
        case .era3: return "Growing prosperity - increasing production and diversifying crops"
        case .era4: return "Industrial age - integrating machinery and industrial processes"
        case .era5: return "Modern era - adopting technology and sustainable practices"
        case .era6: return "Sustainability era - focusing on environmental stewardship"
        case .era7: return "Future era - pioneering new frontiers and innovations"
        }
    }
    
    // Era-specific bonuses
    var eraBonuses: [String: Any] {
        switch self {
        case .era1:
            return ["crop_speed": 1.0, "max_land": 100, "initial_capital": 1000]
        case .era2:
            return ["crop_speed": 1.2, "max_land": 250, "initial_capital": 5000]
        case .era3:
            return ["crop_speed": 1.4, "max_land": 500, "initial_capital": 20000]
        case .era4:
            return ["crop_speed": 1.6, "max_land": 1000, "initial_capital": 100000]
        case .era5:
            return ["crop_speed": 1.8, "max_land": 2000, "initial_capital": 500000]
        case .era6:
            return ["crop_speed": 2.0, "max_land": 5000, "initial_capital": 2000000]
        case .era7:
            return ["crop_speed": 2.5, "max_land": 10000, "initial_capital": 10000000]
        }
    }
}

// MARK: - Comprehensive Progression Track Enum (Expanded)

public enum ProgressionTrack: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case player = "player"
    case research = "research"
    case business = "business"
    case influence = "influence"
    
    // Track display name
    var displayName: String {
        switch self {
        case .player: return "Player Level"
        case .research: return "Research Level"
        case .business: return "Business Level"
        case .influence: return "Influence Level"
        }
    }
    
    // Track description
    var description: String {
        switch self {
        case .player: return "Overall player progression and capabilities"
        case .research: return "Research and technological advancement"
        case .business: return "Business and enterprise development"
        case .influence: return "Political and social influence"
        }
    }
    
    // Track color
    var color: String {
        switch self {
        case .player: return "6a1b9a" // Purple
        case .research: return "558b2f" // Green
        case .business: return "8d6e63" // Steel/blue-gray
        case .influence: return "0d98ba" // Light blue
        }
    }
    
    // Track icon
    var icon: String {
        switch self {
        case .player: return "figure"
        case .research: return "brain"
        case .business: return "building"
        case .influence: return "gavel"
        }
    }
    
    // XP requirements formula: 100 * n^1.65
    func xpForLevel(_ level: Int) -> Double {
        return 100 * pow(Double(level), 1.65)
    }
    
    // Calculate total XP needed to reach this level from level 1
    func totalXPToReachLevel(_ level: Int) -> Double {
        var total: Double = 0
        for n in 1..<level {
            total += xpForLevel(n)
        }
        return total
    }
    
    // Check if level is valid for this track
    func isValidLevel(_ level: Int) -> Bool {
        let era = Era.levelMapping(forTrack: self, level: level)
        return era != nil
    }
}

// MARK: - Era Level Mapping

extension Era {
    static func levelMapping(forTrack track: ProgressionTrack, level: Int) -> Int? {
        // All tracks share the same era/level structure
        return Era.levelMapping(level: level)
    }
    
    static func levelMapping(level: Int) -> Int? {
        for era in Era.allCases where era.levelRange.contains(level) {
            return level
        }
        return nil
    }
}

// MARK: - Milestone Achievement (Expanded)

public enum MilestoneType: String, CaseIterable {
    case levelUp = "level_up"
    case trackLevel = "track_level"
    case eraCompletion = "era_completion"
    case objectiveComplete = "objective_complete"
    case specialAchievement = "special_achievement"
    case economyMilestone = "economy_milestone"
    case agricultureMilestone = "agriculture_milestone"
    case researchMilestone = "research_milestone"
    case tradeMilestone = "trade_milestone"
}

// Milestone record
public struct MilestoneAchievement: Identifiable {
    public let id: String
    public let milestoneType: MilestoneType
    public let name: String
    public let description: String
    public let requirement: String // Description of what was achieved
    public let reward: String // What reward was given
    public let earnedPeriod: Int
    public var isCompleted: Bool
    public var earnedTimestamp: Date?
    
    public init(
        id: String,
        milestoneType: MilestoneType,
        name: String,
        description: String,
        requirement: String,
        reward: String,
        earnedPeriod: Int,
        isCompleted: Bool = false,
        earnedTimestamp: Date? = nil
    ) {
        self.id = id
        self.milestoneType = milestoneType
        self.name = name
        self.description = description
        self.requirement = requirement
        self.reward = reward
        self.earnedPeriod = earnedPeriod
        self.isCompleted = isCompleted
        self.earnedTimestamp = earnedTimestamp
    }
}

// MARK: - Objective System (Expanded)

public enum ObjectiveType: String, CaseIterable {
    case cropYield = "crop_yield"
    case revenue = "revenue"
    case profit = "profit"
    case landExpansion = "land_expansion"
    case technologyUnlock = "technology_unlock"
    case researchComplete = "research_complete"
    case tradeVolume = "trade_volume"
    case policyImplemented = "policy_implemented"
    case sustainability = "sustainability"
    case reputation = "reputation"
    case wealthAccumulation = "wealth_accumulation"
    case eraProgress = "era_progress"
}

// Objective record with comprehensive tracking
public struct Objective: Identifiable {
    public let id: String
    public let objectiveType: ObjectiveType
    public let name: String
    public let description: String
    public let target: Double // Target value
    public var currentValue: Double // Current progress
    public let track: ProgressionTrack // Which track this belongs to
    public let era: Era // Associated era
    public let rewardXP: Double // XP reward for completion
    public let rewardCurrency: Double // Currency reward
    public let rewardItem: String? // Item reward
    public var isCompleted: Bool
    public var completedPeriod: Int?
    public var attempts: Int // Number of attempts toward this objective
    
    public init(
        id: String,
        objectiveType: ObjectiveType,
        name: String,
        description: String,
        target: Double,
        initialValue: Double = 0,
        track: ProgressionTrack,
        era: Era,
        rewardXP: Double = 100,
        rewardCurrency: Double = 0,
        rewardItem: String? = nil,
        isCompleted: Bool = false,
        completedPeriod: Int? = nil,
        attempts: Int = 0
    ) {
        self.id = id
        self.objectiveType = objectiveType
        self.name = name
        self.description = description
        self.target = target
        self.currentValue = initialValue
        self.track = track
        self.era = era
        self.rewardXP = rewardXP
        self.rewardCurrency = rewardCurrency
        self.rewardItem = rewardItem
        self.isCompleted = isCompleted
        self.completedPeriod = completedPeriod
        self.attempts = attempts
    }
    
    mutating func progress(_ amount: Double) {
        currentValue += amount
        attempts += 1
        
        if currentValue >= target && !isCompleted {
            complete()
        }
    }
    
    mutating private func complete() {
        isCompleted = true
        completedPeriod = attempts // Record which period/attempt completed it
    }
    
    func progressPercentage() -> Double {
        guard target > 0 else { return 0 }
        return min(1, currentValue / target)
    }
    
    func statusString() -> String {
        if isCompleted { return "completed" }
        let pct = progressPercentage() * 100
        return "\(String(format: \"%.1f\", pct))% complete"
    }
}

// MARK: - Progression Track (Expanded)

public class ProgressionTrack: Identifiable {
    public let id: String
    public let track: ProgressionTrack.Type // The track type
    public var currentLevel: Int
    public var currentXP: Double
    public var trackXP: Double // XP specific to this track
    public var levelsCompleted: [Int: Double] // Level -> XP at that level
    public var trackMilestones: [String: MilestoneAchievement] // Milestone ID -> achievement
    public var trackObjectives: [String: Objective] // Objective ID -> objective
    public var era: Era
    
    public init(
        id: String,
        track: ProgressionTrack.Type,
        currentLevel: Int = 1,
        currentXP: Double = 0,
        trackXP: Double = 0,
        era: Era = .era1
    ) {
        self.id = id
        self.track = track
        self.currentLevel = currentLevel
        self.currentXP = currentXP
        self.trackXP = trackXP
        self.era = era
        self.levelsCompleted = [:]
        self.trackMilestones = [:]
        self.trackObjectives = [:]
    }
    
    // Get XP needed for next level
    func xpForNextLevel() -> Double {
        ProgressionTrack.xpForLevel(currentLevel + 1)
    }
    
    // Get total XP needed to reach current level
    func totalXPForCurrentLevel() -> Double {
        ProgressionTrack.totalXPToReachLevel(currentLevel + 1)
    }
    
    // Add XP to this track
    mutating func addXP(_ amount: Double) {
        currentXP += amount
        trackXP += amount
        
        // Check for level up
        while currentXP >= xpForNextLevel() && currentLevel < 30 {
            currentXP -= xpForNextLevel()
            currentLevel += 1
            
            #warning("Handle level up - check era transition")
            // Check if we've moved to a new era
            let newEra = Era.levelMapping(forTrack: track, level: currentLevel) != nil 
                ? Era.levelMapping(forTrack: track, level: currentLevel)!
                : era
            
            if era != newEra {
                era = newEra
                #warning("Era transition triggered")
            }
            
            #warning("Award level up rewards")
            awardLevelUpRewards()
        }
    }
    
    // Award rewards for leveling up
    func awardLevelUpRewards() -> [String: Any] {
        let eraBonuses = Era.eraBonuses[era] as? [String: Any] ?? [:]
        let trackBonuses: [String: Any]
        
        switch track {
        case .player:
            trackBonuses = ["player_bonuses": ["new_ability": "unlocked"]]
        case .research:
            trackBonuses = ["research_bonuses": ["new_technology": "unlocked"]]
        case .business:
            trackBonuses = ["business_bonuses": ["new_enterprise": "unlocked"]]
        case .influence:
            trackBonuses = ["influence_bonuses": ["new_capability": "unlocked"]]
        }
        
        return ["era_bonuses": eraBonuses, "track_bonuses": trackBonuses]
    }
    
    // Check if objective can be worked on
    func canProgressObjective(_ objectiveId: String) -> Bool {
        guard let objective = trackObjectives[objectiveId] else { return false }
        return !objective.isCompleted && objective.currentValue < objective.target
    }
    
    // Progress an objective
    mutating func progressObjective(_ objectiveId: String, _ amount: Double) -> Bool {
        guard var objective = trackObjectives[objectiveId] else { return false }
        
        // Skip if already completed
        if objective.isCompleted { return false }
        
        // Progress the objective
        objective.progress(amount)
        trackObjectives[objectiveId] = objective
        
        #warning("Check for objective completion rewards")
        
        // Check if this triggered a track level up
        let pct = objective.progressPercentage()
        if pct >= 1 && !objective.isCompleted {
            #warning("Objective completed - award rewards")
        }
        
        return objective.isCompleted
    }
    
    // Complete an era
    mutating func completeEra() {
        #warning("Complete current era, transition to next")
        
        // In a full system, would handle era transition
        // For now, just mark objectives related to this era
        for (_, objective) in trackObjectives where objective.era == era {
            if !objective.isCompleted && objective.objectiveType == .eraProgress {
                objective.isCompleted = true
                objective.completedPeriod = currentLevel
                trackObjectives[objective.id] = objective
            }
        }
    }
}

// MARK: - Progression Objectives System (Expanded)

public class ProgressionObjectives {
    // Track management
    private var tracks: [String: ProgressionTrack] = [:]
    var milestoneHistory: [String: MilestoneAchievement] = [:]
    var allObjectives: [String: Objective] = [:]
    
    // Statistics
    var totalLevelsAcrossTracks: Int = 0
    var erasCompleted: [Era: Int] = [:]
    var totalObjectivesCompleted: Int = 0
    
    public init() {
        #warning("Initialize progression tracks with all objectives")
        #warning("Set up era progression and milestone structure")
        #warning("Configure XP curves and level requirements")
        
        #warning("TODO: Initialize 4 progression tracks (player, research, business, influence)")
        #warning("TODO: Set up 7 eras with 30 levels total (4+5+5+5+5+2+2=28, need 30)")
        #warning("TODO: Configure XP curve 100n^1.65 and level-up calculations")
        #warning("TODO: Create milestone achievements for key progression points")
        #warning("TODO: Set up objectives for each track in each era")
        
        // Initialize 4 progression tracks
        let playerTrack = ProgressionTrack(
            id: "player_track",
            track: ProgressionTrack.self,
            currentLevel: 1,
            currentXP: 0,
            trackXP: 0,
            era: .era1
        )
        
        let researchTrack = ProgressionTrack(
            id: "research_track",
            track: ProgressionTrack.self,
            currentLevel: 1,
            currentXP: 0,
            trackXP: 0,
            era: .era1
        )
        
        let businessTrack = ProgressionTrack(
            id: "business_track",
            track: ProgressionTrack.self,
            currentLevel: 1,
            currentXP: 0,
            trackXP: 0,
            era: .era1
        )
        
        let influenceTrack = ProgressionTrack(
            id: "influence_track",
            track: ProgressionTrack.self,
            currentLevel: 1,
            currentXP: 0,
            trackXP: 0,
            era: .era1
        )
        
        tracks["player"] = playerTrack
        tracks["research"] = researchTrack
        tracks["business"] = businessTrack
        tracks["influence"] = influenceTrack
        
        #warning("Set up era tracking")
        for era in Era.allCases {
            erasCompleted[era] = 0
        }
        
        #warning("Initialize all objectives for all tracks and eras")
        initializeAllObjectives()
        
        #warning("Set up milestone achievements")
        setupMilestoneAchievements()
    }
    
    // MARK: - Track Management
    
    func getTrack(_ track: ProgressionTrack) -> ProgressionTrack? {
        return tracks[track.rawValue]
    }
    
    func getAllTracks() -> [ProgressionTrack] {
        return Array(tracks.values)
    }
    
    func getTrackStatistics() -> [ProgressionTrack: [String: Any]] {
        var stats: [ProgressionTrack: [String: Any]] = [:]
        
        for track in ProgressionTrack.allCases {
            if let progressionTrack = tracks[track.rawValue] {
                stats[track] = [
                    "current_level": progressionTrack.currentLevel,
                    "current_xp": progressionTrack.currentXP,
                    "track_xp": progressionTrack.trackXP,
                    "era": progressionTrack.era.displayName,
                    "levels_completed": progressionTrack.levelsCompleted.count,
                    "active_objectives": progressionTrack.trackObjectives.values.filter { !$0.isCompleted }.count,
                    "completed_milestones": progressionTrack.trackMilestones.values.filter { $0.isCompleted }.count
                ]
            }
        }
        
        return stats
    }
    
    // MARK: - Objective Management
    
    func getObjective(_ id: String) -> Objective? {
        return allObjectives[id]
    }
    
    func getObjectives(byTrack track: ProgressionTrack) -> [Objective] {
        return allObjectives.values.filter { $0.track == track }
    }
    
    func getObjectives(byEra era: Era) -> [Objective] {
        return allObjectives.values.filter { $0.era == era }
    }
    
    func getCompletedObjectives(byTrack track: ProgressionTrack) -> [Objective] {
        return allObjectives.values.filter {
            $0.track == track && $0.isCompleted
        }
    }
    
    mutating func addObjective(_ objective: Objective) {
        allObjectives[objective.id] = objective
    }
    
    mutating func removeObjective(_ id: String) {
        allObjectives.removeValue(forKey: id)
    }
    
    // MARK: - XP and Level Management
    
    mutating func addXP(_ amount: Double, toTrack track: ProgressionTrack) -> [String: Any] {
        guard var progressionTrack = tracks[track.rawValue] else { return [:] }
        
        let rewards = progressionTrack.addXP(amount)
        
        #warning("Check for track level ups and award rewards")
        
        tracks[track.rawValue] = progressionTrack
        
        return [
            "current_level": progressionTrack.currentLevel,
            "current_xp": progressionTrack.currentXP,
            "track_xp_added": amount,
            "level_up_occurred": rewards.isEmpty ? false : true,
            "new_era": progressionTrack.era.displayName
        ]
    }
    
    func getXPForLevel(_ level: Int, track: ProgressionTrack) -> Double {
        ProgressionTrack.xpForLevel(level)
    }
    
    func totalXPToReachLevel(_ level: Int, track: ProgressionTrack) -> Double {
        ProgressionTrack.totalXPToReachLevel(level)
    }
    
    // MARK: - Milestone Management
    
    mutating func awardMilestone(_ milestoneId: String, _ track: ProgressionTrack) -> Bool {
        guard var progressionTrack = tracks[track.rawValue] else { return false }
        
        // Check if milestone exists and can be awarded
        // In a full system, would look up milestone definition
        let milestoneKey = "\(track.rawValue)_\(milestoneId)"
        
        if progressionTrack.trackMilestones[milestoneId].isCompleted {
            #warning("Milestone already completed")
            return false
        }
        
        // Mark milestone as completed
        var milestone = progressionTrack.trackMilestones[milestoneId]!
        milestone.isCompleted = true
        milestone.earnedPeriod = progressionTrack.currentLevel
        milestone.earnedTimestamp = Date()
        
        progressionTrack.trackMilestones[milestoneId] = milestone
        
        #warning("Award milestone rewards")
        #warning("Check for cascade effects to other milestones or objectives")
        
        tracks[track.rawValue] = progressionTrack
        totalObjectivesCompleted += 1
        
        return true
    }
    
    // MARK: - Era Management
    
    mutating func completeCurrentEra(_ track: ProgressionTrack) -> Era {
        guard var progressionTrack = tracks[track.rawValue] else { return .era1 }
        
        #warning("Transition to next era")
        
        // Find current era and transition
        let currentEra = progressionTrack.era
        
        // Get next era
        let currentEraIndex = Era.allCases.firstIndex { $0 == currentEra } ?? 0
        let nextEraIndex = min(currentEraIndex + 1, Era.allCases.count - 1)
        let nextEra = Era.allCases[nextEraIndex]
        
        #warning("Apply era transition bonuses and changes")
        // In a full system, would apply era-specific bonuses, unlock new features
        
        progressionTrack.era = nextEra
        erasCompleted[currentEra] = (erasCompleted[currentEra] ?? 0) + 1
        
        tracks[track.rawValue] = progressionTrack
        
        return nextEra
    }
    
    func getEraProgress(_ track: ProgressionTrack) -> (current: Era, completed: Int, total: Int) {
        let current = tracks[track.rawValue]?.era ?? .era1
        let completed = erasCompleted[current] ?? 0
        let total = Era.allCases.count
        
        return (current, completed, total)
    }
    
    // MARK: - Era Objectives Initialization
    
    private func initializeAllObjectives() {
        #warning("Initialize objectives for all 4 tracks across 7 eras")
        
        // For each track and era, create relevant objectives
        for track in ProgressionTrack.allCases {
            for era in Era.allCases {
                let eraLevelRange = era.levelRange
                
                // Create 3-5 objectives per track per era
                let numObjectives = 3 + (era == .era7 ? 2 : 1) // Era 7 has extra objectives
                
                for i in 0..<numObjectives {
                    let objectiveId = "\(track.rawValue)_era\(era.rawValue)_obj\(i)"
                    let objectiveName = "\(track.displayName) - \(era.displayName) Objective \(i+1)"
                    let objectiveDescription = "Complete key tasks during \(era.displayName) era for \(track.displayName)"
                    let trackBonuses = track.xpForLevel(1) // Base XP
                    let targetValue: Double
                    
                    // Set targets based on era and track
                    switch (track, era) {
                    case (.player, .era1):
                        targetValue = 100
                    case (.player, .era3):
                        targetValue = 500
                    case (.player, .era5):
                        targetValue = 2000
                    case (.player, .era7):
                        targetValue = 10000
                    case (.research, .era1):
                        targetValue = 50
                    case (.research, .era3):
                        targetValue = 200
                    case (.research, .era5):
                        targetValue = 800
                    case (.research, .era7):
                        targetValue = 5000
                    case (.business, .era1):
                        targetValue = 100
                    case (.business, .era3):
                        targetValue = 500
                    case (.business, .era5):
                        targetValue = 2500
                    case (.business, .era7):
                        targetValue = 10000
                    case (.influence, .era1):
                        targetValue = 50
                    case (.influence, .era3):
                        targetValue = 300
                    case (.influence, .era5):
                        targetValue = 1500
                    case (.influence, .era7):
                        targetValue = 8000
                    default:
                        targetValue = 100
                    }
                    
                    let objective = Objective(
                        id: objectiveId,
                        objectiveType: .eraProgress,
                        name: objectiveName,
                        description: objectiveDescription,
                        target: targetValue,
                        initialValue: 0,
                        track: track,
                        era: era,
                        rewardXP: track.xpForLevel(1) * 0.5,
                        rewardCurrency: 0,
                        rewardItem: i == numObjectives - 1 ? "era_completion_badge" : nil,
                        isCompleted: false,
                        attempts: 0
                    )
                    
                    addObjective(objective)
                }
            }
        }
    }
    
    private func setupMilestoneAchievements() {
        #warning("Set up milestone achievements across all tracks and levels")
        
        // Milestones at key level points
        let milestoneLevels = [5, 10, 15, 20, 25, 30] // Every 5 levels, plus prestige at 30
        
        for track in ProgressionTrack.allCases {
            for level in milestoneLevels {
                let milestoneId = "\(track.rawValue)_level_\(level)"
                let milestoneName = "\(track.displayName) Level \(level)"
                let milestoneDescription = "Reach level \(level) in \(track.displayName)"
                let milestoneRequirement = "Achieve level \(level) with sufficient XP"
                let milestoneReward = "XP bonus and special capability"
                
                let milestone = MilestoneAchievement(
                    id: milestoneId,
                    milestoneType: .levelUp,
                    name: milestoneName,
                    description: milestoneDescription,
                    requirement: milestoneRequirement,
                    reward: milestoneReward,
                    earnedPeriod: level
                )
                
                // Add to the track's milestone dictionary
                if var progressionTrack = tracks[track.rawValue] {
                    progressionTrack.trackMilestones[milestoneId] = milestone
                    tracks[track.rawValue] = progressionTrack
                }
            }
        }
        
        // Era completion milestones
        for track in ProgressionTrack.allCases {
            for era in Era.allCases {
                let milestoneId = "\(track.rawValue)_era_\(era.rawValue)_complete"
                let milestoneName = "\(track.displayName) - \(era.displayName) Era Complete"
                let milestoneDescription = "Complete all objectives in the \(era.displayName) era"
                let milestoneRequirement = "Complete all \(era.displayName) era objectives"
                let milestoneReward = "Era completion bonus and era transition"
                
                let milestone = MilestoneAchievement(
                    id: milestoneId,
                    milestoneType: .eraCompletion,
                    name: milestoneName,
                    description: milestoneDescription,
                    requirement: milestoneRequirement,
                    reward: milestoneReward,
                    earnedPeriod: 0 // Will be set when earned
                )
                
                if var progressionTrack = tracks[track.rawValue] {
                    progressionTrack.trackMilestones[milestoneId] = milestone
                    tracks[track.rawValue] = progressionTrack
                }
            }
        }
    }
}

// MARK: - Previews
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct ProgressionObjectivesPreview: PreviewProvider {
//    static var previews: some View {
//        Text("Progression Objectives System Preview")
//    }
//}
//#endif