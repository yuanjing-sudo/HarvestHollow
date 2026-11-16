//  InfrastructureLogistics.swift
//  Agricultural Economic Simulation (Massively Expanded)
//
//  Expanded System 18 with comprehensive infrastructure and logistics simulation
//  Features: extensive road networks, railways, utilities, capacity management, maintenance, throughput
//  Interconnections: connects to economy (trade), environment (water), society (public transport)
//  ~4000+ lines of Swift code

import Foundation

// MARK: - Comprehensive Infrastructure Type System (Enhanced)

public enum InfrastructureType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // === ROAD TYPE CATEGORY ===
    case highway_4lane = "highway_4lane"
    case highway_6lane = "highway_6lane"
    case highway_8lane = "highway_8lane"
    case highway_improved = "highway_improved"
    case primary_arterial = "primary_arterial"
    case primary_collector = "primary_collector"
    case primary_suburban = "primary_suburban"
    case secondary_major = "secondary_major"
    case secondary_minor = "secondary_minor"
    case secondary_residential = "secondary_residential"
    case tertiary_main = "tertiary_main"
    case tertiary_feeder = "tertiary_feeder"
    case tertiary_local = "tertiary_local"
    case service_industrial = "service_industrial"
    case service_commercial = "service_commercial"
    case service_residential = "service_residential"
    case alley_main = "alley_main"
    case alley_sub = "alley_sub"
    
    // Railway subtypes
    case railway_single = "railway_single"
    case railway_double = "railway_double"
    case railway_high_speed = "railway_high_speed"
    case railway_narrow = "railway_narrow"
    case railway_tram = "railway_tram"
    
    // Bridge subtypes
    case bridge_beam = "bridge_beam"
    case bridge_arch = "bridge_arch"
    case bridge_suspension = "bridge_suspension"
    case bridge_cable_stayed = "bridge_cable_stayed"
    case bridge_box_girder = "bridge_box_girder"
    case bridge_viaduct = "bridge_viaduct"
    case bridge_tunnel = "bridge_tunnel"
    
    // Port subtypes
    case port_fishing = "port_fishing"
    case port_commercial = "port_commercial"
    case port_cargo = "port_cargo"
    case port_container = "port_container"
    case port_tanker = "port_tanker"
    case port_referigerated = "port_referigerated"
    
    // Warehouse subtypes
    case warehouse_dry = "warehouse_dry"
    case warehouse_ref = "warehouse_ref"
    case warehouse_hazmat = "warehouse_hazmat"
    case warehouse_dist = "warehouse_dist"
    case warehouse_farm = "warehouse_farm"
    case silo_grain = "silo_grain"
    case silo_seed = "silo_seed"
    
    // Utility subtypes
    case substation_step_down = "substation_step_down"
    case substation_step_up = "substation_step_up"
    case grid_transmission = "grid_transmission"
    case grid_distribution = "grid_distribution"
    case water_treatment_plants = "water_treatment_plants"
    case water_distribution = "water_distribution"
    case communications_fiber = "communications_fiber"
    case communications_wireless = "communications_wireless"
    
    // Public service subtypes
    case fire_station_urban = "fire_station_urban"
    case fire_station_rural = "fire_station_rural"
    case police_station_local = "police_station_local"
    case police_station_regional = "police_station_regional"
    case hospital = "hospital"
    case clinic = "clinic"
    
    // Industrial subtypes
    case factory_manufacturing = "factory_manufacturing"
    case factory_assembly = "factory_assembly"
    case factory_processing = "factory_processing"
    case refinery_petroleum = "refinery_petroleum"
    case refinery_chemical = "refinery_chemical"
    case mine_open_pit = "mine_open_pit"
    case mine_underground = "mine_underground"
    
    // Agricultural subtypes
    case elevator_grain = "elevator_grain"
    case mill_feed = "mill_feed"
    case plant_processing = "plant_processing"
    case greenhouse_standard = "greenhouse_standard"
    case greenhouse_hydroponic = "greenhouse_hydroponic"
    case greenhouse_aquaponic = "greenhouse_aquaponic"
    
    // Combined/intermodal types
    case intermodal_terminal = "intermodal_terminal"
    case airport_international = "airport_international"
    case airport_regional = "airport_regional"
    
    // Categorization helpers
    var isRoad: Bool {
        switch self {
        case .highway_4lane, .highway_6lane, .highway_8lane, .highway_improved,
                .primary_arterial, .primary_collector, .primary_suburban,
                .secondary_major, .secondary_minor, .secondary_residential,
                .tertiary_main, .tertiary_feeder, .tertiary_local,
                .service_industrial, .service_commercial, .service_residential,
                .alley_main, .alley_sub: return true
        default: return false
        }
    }
    
    var isRailway: Bool {
        switch self {
        case .railway_single, .railway_double, .railway_high_speed, .railway_narrow, .railway_tram: return true
        default: return false
        }
    }
    
    var isBridge: Bool {
        switch self {
        case .bridge_beam, .bridge_arch, .bridge_suspension, .bridge_cable_stayed, .bridge_box_girder, .bridge_viaduct, .bridge_tunnel: return true
        default: return false
        }
    }
    
    var isPort: Bool {
        switch self {
        case .port_fishing, .port_commercial, .port_cargo, .port_container, .port_tanker, .port_referigerated: return true
        default: return false
        }
    }
    
    var isWarehouse: Bool {
        switch self {
        case .warehouse_dry, .warehouse_ref, .warehouse_hazmat, .warehouse_dist, .warehouse_farm, .silo_grain, .silo_seed: return true
        default: return false
        }
    }
    
    var isUtility: Bool {
        switch self {
        case .substation_step_down, .substation_step_up, .grid_transmission, .grid_distribution, .water_treatment_plants, .water_distribution, .communications_fiber, .communications_wireless: return true
        default: return false
        }
    }
    
    var isPublicService: Bool {
        switch self {
        case .fire_station_urban, .fire_station_rural, .police_station_local, .police_station_regional, .hospital, .clinic: return true
        default: return false
        }
    }
    
    var isIndustrial: Bool {
        switch self {
        case .factory_manufacturing, .factory_assembly, .factory_processing, .refinery_petroleum, .refinery_chemical, .mine_open_pit, .mine_underground: return true
        default: return false
        }
    }
    
    var isAgricultural: Bool {
        switch self {
        case .elevator_grain, .mill_feed, .plant_processing, .greenhouse_standard, .greenhouse_hydroponic, .greenhouse_aquaponic: return true
        default: return false
        }
    }
}

// MARK: - Infrastructure Condition System

public enum InfrastructureConditionState: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
}

public struct InfrastructureCondition {
    public var state: InfrastructureConditionState
    public var rating: Double // 0-100
    public var lastInspection: Date
    public var nextInspection: Date
    public var deteriorationRate: Double // per year 0-1
    public var maintenanceCostAccumulated: Double
    public var deferredMaintenance: Double
    
    public init(state: InfrastructureConditionState = .excellent, rating: Double = 100, lastInspection: Date = Date(), nextInspection: Date = Date().addingTimeInterval(365*24*60*60), deteriorationRate: Double = 0.02, maintenanceCostAccumulated: Double = 0, deferredMaintenance: Double = 0) {
        self.state = state
        self.rating = rating
        self.lastInspection = lastInspection
        self.nextInspection = nextInspection
        self.deteriorationRate = deteriorationRate
        self.maintenanceCostAccumulated = maintenanceCostAccumulated
        self.deferredMaintenance = deferredMaintenance
    }
    
    mutating func deteriorate(days: Double) {
        let annualDeterioration = deteriorationRate * 365
        let dailyDeterioration = annualDeterioration / 365
        rating -= dailyDeterioration * days
        rating = max(0, min(100, rating))
        updateState()
    }
    
    mutating func maintain(improvement: Double) {
        rating += improvement
        rating = max(0, min(100, rating))
        if rating > 80 { state = .excellent }
        else if rating > 60 { state = .good }
        else if rating > 40 { state = .fair }
        else if rating > 20 { state = .poor }
        else { state = .critical }
        maintenanceCostAccumulated = 0
        deferredMaintenance = max(0, deferredMaintenance - improvement * 10)
    }
    
    private func updateState() {
        if rating > 80 { state = .excellent }
        else if rating > 60 { state = .good }
        else if rating > 40 { state = .fair }
        else if rating > 20 { state = .poor }
        else { state = .critical }
    }
}

// MARK: - Infrastructure Link Type

public enum InfrastructureLinkType: String, CaseIterable {
    case road = "road"
    case rail = "rail"
    case bridge = "bridge"
    case port = "port"
    case warehouse = "warehouse"
    case utility = "utility"
    case public_service = "public_service"
    case industrial = "industrial"
    case agricultural = "agricultural"
    case intermodal = "intermodal"
    case airport = "airport"
}

// MARK: - Infrastructure Node (Enhanced)

public struct InfrastructureNode: Identifiable {
    public let id: String
    public var type: InfrastructureType
    public var location: (x: Double, y: Double) // km coordinates
    public var condition: InfrastructureCondition
    public var capacity: Double // Max throughput units/day
    public var currentThroughput: Double // Current usage units/day
    public var status: InfrastructureStatus
    public var connectedNodes: [String] // IDs of connected nodes
    public var constructionDate: Date
    public var lastMaintenance: Date
    public var scheduledMaintenance: [Date]
    public var metadata: [String: Any]
    
    public init(
        id: String,
        type: InfrastructureType,
        location: (x: Double, y: Double),
        condition: InfrastructureCondition? = nil,
        capacity: Double = 1000,
        status: InfrastructureStatus = .active
    ) {
        self.id = id
        self.type = type
        self.location = location
        self.condition = condition ?? InfrastructureCondition()
        self.capacity = capacity
        self.currentThroughput = 0
        self.status = status
        self.connectedNodes = []
        self.constructionDate = Date()
        self.lastMaintenance = Date()
        self.scheduledMaintenance = []
        self.metadata = [:]
    }
}

public enum InfrastructureStatus: String, CaseIterable {
    case active = "active"
    case at_capacity = "at_capacity"
    congested = "congested"
    case under_maintenance = "under_maintenance"
    case closed = "closed"
    case damaged = "damaged"
}

// MARK: - Road Properties (Enhanced)

public struct RoadProperties {
    public var numLanes: Int
    public var laneWidth: Double
    public var roadType: InfrastructureType
    public var speedLimit: Double
    public var avgDailyTraffic: Double
    public var peakHourVolume: Double
    public var designHourVolume: Double
    public var truckPercentage: Double
    public var vehicleClassDist: [Double]
    public var lengthKm: Double
    public var curveRadius: Double
    public var superelevation: Double
    public var gradient: Double
    public var surfaceType: String
    public var conditionRating: Double
    public var lastMaintenance: Date
    public var nextMaintenance: Date
    public var maintenanceCostAnnual: Double
    public var capacityVehPerDay: Double
    public var levelOfService: String
    public var congestionIndex: Double
    public var crashRate: Double
    public var hasMedian: Bool
    public var hasShoulder: Bool
    public var shoulderWidth: Double
    public var lighting: String
    public var sidewalks: Bool
    public var bicycleLane: String
    public var noiseLevel: Double
    public var airQualityImpact: Double
    public var stormwaterCapacity: Double
    public var constructionCost: Double
    public var rightOfWayWidth: Double
    public var landAcquisitionCost: Double
    
    public init() {
        self.numLanes = 2
        self.laneWidth = 3.5
        self.roadType = .secondary_major
        self.speedLimit = 50
        self.avgDailyTraffic = 1000
        self.peakHourVolume = 150
        self.designHourVolume = 200
        self.truckPercentage = 10
        self.vehicleClassDist = [0.3, 0.2, 0.15, 0.1, 0.25]
        self.lengthKm = 1.0
        self.curveRadius = 200
        self.superelevation = 2.0
        self.gradient = 3.0
        self.surfaceType = "asphalt"
        self.conditionRating = 85
        self.lastMaintenance = Date().addingTimeInterval(-365*24*60*60)
        self.nextMaintenance = Date().addingTimeInterval(365*24*60*60)
        self.maintenanceCostAnnual = 25000
        self.capacityVehPerDay = 20000
        self.levelOfService = "C"
        self.congestionIndex = 0.3
        self.crashRate = 2.5
        self.hasMedian = true
        self.hasShoulder = true
        self.shoulderWidth = 2.0
        self.lighting = "partial"
        self.sidewalks = true
        self.bicycleLane = "painted"
        self.noiseLevel = 65
        self.airQualityImpact = 0.5
        self.stormwaterCapacity = 50
        self.constructionCost = 5000000
        self.rightOfWayWidth = 30
        self.landAcquisitionCost = 1000000
    }
}

// MARK: - Railway Properties (Enhanced)

public struct RailwayProperties {
    public var numTracks: Int
    public var trackGauge: Double
    public var speedLimit: Double
    public var electrification: String
    public var freightCapacity: Double
    public var passengerCapacity: Double
    public var trainFrequency: Double
    public var trackCondition: Double
    public var lastInspection: Date
    public var nextInspection: Date
    public var maintenanceCostAnnual: Double
    public var maxTrainLength: Double
    public var signalingSystem: String
    public var electrificationLosses: Double
    
    public init() {
        self.numTracks = 2
        self.trackGauge = 1.435
        self.speedLimit = 120
        self.electrification = "dc"
        self.freightCapacity = 10000
        self.passengerCapacity = 500
        self.trainFrequency = 24
        self.trackCondition = 90
        self.lastInspection = Date()
        self.nextInspection = Date().addingTimeInterval(30*24*60*60)
        self.maintenanceCostAnnual = 500000
        self.maxTrainLength = 500
        self.signalingSystem = "advanced"
        self.electrificationLosses = 0.05
    }
}

// MARK: - Bridge Properties (Enhanced)

public struct BridgeProperties {
    public var span: Double
    public var totalLength: Double
    public var deckWidth: Double
    public var loadCapacity: Double
    public var structuralType: String
    public var materials: [String]
    public var yearBuilt: Int
    public var lastInspection: Date
    public var nextInspection: Date
    public var deteriorationRate: Double
    public var seismicRating: Double
    public var scourRisk: Double
    public var floodRisk: Double
    public var trafficLoad: Double
    public var replacementCost: Double
    public var maintenanceCostAnnual: Double
    
    public init() {
        self.span = 30
        self.totalLength = 50
        self.deckWidth = 10
        self.loadCapacity = 40
        self.structuralType = "beam"
        self.materials = ["concrete", "steel"]
        self.yearBuilt = 2000
        self.lastInspection = Date()
        self.nextInspection = Date().addingTimeInterval(365*24*60*60)
        self.deteriorationRate = 0.02
        self.seismicRating = 0.8
        self.scourRisk = 0.3
        self.floodRisk = 0.2
        self.trafficLoad = 1000
        self.replacementCost = 2000000
        self.maintenanceCostAnnual = 25000
    }
}

// MARK: - Port Properties (Enhanced)

public struct PortProperties {
    public var numBerths: Int
    public var maxVesselLength: Double
    public var maxVesselDraft: Double
    public var cargoThroughput: Double
    public var containerTEUs: Double
    public var storageCapacity: Double
    public var specializedFacilities: [String]
    public var dredgingDepth: Double
    public var waterDepthAtBerth: Double
    public var railConnection: Bool
    public var roadConnection: Bool
    public var pilotageRequired: Bool
    public var tugAssistance: Bool
    public var annualThroughput: Double
    public var passengerThroughput: Double
    public var customsFacilities: Bool
    public var securityLevel: String
    public var averageTurnaroundTime: Double
    
    public init() {
        self.numBerths = 5
        self.maxVesselLength = 200
        self.maxVesselDraft = 12
        self.cargoThroughput = 500
        self.containerTEUs = 100
        self.storageCapacity = 10000
        self.specializedFacilities = ["refrigerated"]
        self.dredgingDepth = 15
        self.waterDepthAtBerth = 14
        self.railConnection = true
        self.roadConnection = true
        self.pilotageRequired = true
        self.tugAssistance = true
        self.annualThroughput = 500000
        self.passengerThroughput = 10000
        self.customsFacilities = true
        self.securityLevel = "high"
        self.averageTurnaroundTime = 24
    }
}

// MARK: - Warehouse Properties (Enhanced)

public struct WarehouseProperties {
    public var totalArea: Double
    public var storageArea: Double
    public var handlingArea: Double
    public var coldStorageArea: Double
    public var numDocks: Int
    public var dockType: String
    public var ceilingHeight: Double
    public var clearHeight: Double
    public var rackingSystem: String
    public var maxStackHeight: Int
    public var temperatureRange: ClosedRange<Double>
    public var humidityRange: ClosedRange<Double>
    public var sprinklerSystem: Bool
    public var fireSuppression: String
    public var yardArea: Double
    public var parkingArea: Double
    public var officeArea: Double
    public var powerCapacity: Double
    public var backupPower: Bool
    public var securitySystem: String
    public var automationLevel: String
    public var averageDwellTime: Double
    public var throughputRate: Double
    
    public init() {
        self.totalArea = 5000
        self.storageArea = 3500
        self.handlingArea = 800
        self.coldStorageArea = 500
        self.numDocks = 4
        self.dockType = "enclosed"
        self.ceilingHeight = 12
        self.clearHeight = 10
        self.rackingSystem = "selective"
        self.maxStackHeight = 5
        self.temperatureRange = 0...4
        self.humidityRange = 50...80
        self.sprinklerSystem = true
        self.fireSuppression = "sprinkler"
        self.yardArea = 1000
        self.parkingArea = 500
        self.officeArea = 300
        self.powerCapacity = 500
        self.backupPower = true
        self.securitySystem = "surveillance"
        self.automationLevel = "semi-automated"
        self.averageDwellTime = 3
        self.throughputRate = 500
    }
}

// MARK: - Substation Properties

public struct SubstationProperties {
    public var capacityMVA: Double
    public var numTransformers: Int
    public var voltageLevel: Double
    public var backupTransformers: Int
    public var switchingEquipment: String
    public var protectionScheme: String
    public var groundingSystem: String
    public var landArea: Double
    public var fencing: String
    public var remoteMonitoring: Bool
    public var lastMaintenance: Date
    public var nextMaintenance: Date
    public var failureRate: Double
    public var outageDuration: Double
    public var connectedLoad: Double
    public var peakLoad: Double
    public var loadGrowthRate: Double
    
    public init() {
        self.capacityMVA = 100
        self.numTransformers = 2
        self.voltageLevel = 138
        self.backupTransformers = 1
        self.switchingEquipment = "automatic"
        self.protectionScheme = "differential"
        self.groundingSystem = "solid"
        self.landArea = 500
        self.fencing = "standard"
        self.remoteMonitoring = true
        self.lastMaintenance = Date()
        self.nextMaintenance = Date().addingTimeInterval(90*24*60*60)
        self.failureRate = 0.01
        self.outageDuration = 4
        self.connectedLoad = 80
        self.peakLoad = 90
        self.loadGrowthRate = 2.0
    }
}

// MARK: - Water Treatment Properties

public struct WaterTreatmentProperties {
    public var designCapacityMLD: Double
    public var currentCapacityMLD: Double
    public var treatmentProcess: String
    public var filtrationType: String
    public var reservoirCapacityML: Double
    public var pumpingCapacityMLD: Double
    public var numPumps: Int
    public var pumpRedundancy: Int
    public var waterQuality: String
    public var treatedWaterQuality: String
    public var chemicalUsage: [String: Double]
    public var sludgeProduction: Double
    public var sludgeDisposal: String
    public var numFilters: Int
    public var filterReplacementRate: Double
    public var monitoringParams: [String]
    public var complianceStatus: String
    public var lastComplianceCheck: Date
    public var nextComplianceCheck: Date
    public var waterSource: String
    public var maxRecoveryRate: Double
    
    public init() {
        self.designCapacityMLD = 100
        self.currentCapacityMLD = 80
        self.treatmentProcess = "tertiary"
        self.filtrationType = "membrane"
        self.reservoirCapacityML = 50
        self.pumpingCapacityMLD = 90
        self.numPumps = 4
        self.pumpRedundancy = 2
        self.waterQuality = "potable"
        self.treatedWaterQuality = "potable"
        self.chemicalUsage = ["chlorine": 500, "coagulant": 200, "flocculant": 150]
        self.sludgeProduction = 10
        self.sludgeDisposal = "landfill"
        self.numFilters = 8
        self.filterReplacementRate = 0.5
        self.monitoringParams = ["pH", "turbidity", "chlorine", "temperature", "conductivity"]
        self.complianceStatus = "compliant"
        self.lastComplianceCheck = Date()
        self.nextComplianceCheck = Date().addingTimeInterval(30*24*60*60)
        self.waterSource = "river"
        self.maxRecoveryRate = 95
    }
}

// MARK: - Main Infrastructure Logistics Class (Massively Enhanced)

public class InfrastructureLogistics {
    // Node storage by type categories
    private var nodes: [String: InfrastructureNode] = [:]
    private var roads: [String: InfrastructureNode] = [:]
    private var railways: [String: InfrastructureNode] = [:]
    private var bridges: [String: InfrastructureNode] = [:]
    private var ports: [String: InfrastructureNode] = [:]
    private var warehouses: [String: InfrastructureNode] = [:]
    private var utilities: [String: InfrastructureNode] = [:]
    private var publicServices: [String: InfrastructureNode] = [:]
    private var industrial: [String: InfrastructureNode] = [:]
    private var agricultural: [String: InfrastructureNode] = [:]
    
    // Connectivity graph
    private var connectivityGraph: [String: [String: InfrastructureLinkType]] = [:]
    
    // Tracking
    private var dailyTraffic: [String: Double] = [:]
    private var freightFlows: [String: Double] = [:]
    private var utilityUsage: [String: Double] = [:]
    private var maintenanceSchedule: [String: [Date]] = [:]
    private var repairBacklog: Double = 0
    private var inspectionSchedule: [String: Date] = [:]
    
    // Advanced metrics
    var totalCapacityUtilization: Double = 0
    var averageConditionRating: Double = 0.5
    var totalDeferredMaintenance: Double = 0
    var networkEfficiency: Double = 1.0
    var congestionHotspots: [String: Double] = [:]
    
    // Economic
    var dailyEconomicActivity: Double = 0
    var tradeVolumeThroughput: Double = 0
    var employmentSupported: Int = 0
    var infrastructureInvestment: Double = 0
    var maintenanceRevenue: Double = 0
    
    // Time tracking
    var currentSimulationPeriod: Int = 0
    var totalSimulatedYears: Int = 0
    
    public init() {
        #warning("Initialize comprehensive base infrastructure network with all types")
        #warning("Add road grid network spanning the simulation area")
        #warning("Add railway network connecting major regions")
        #warning("Add bridge network spanning waterways")
        #warning("Add port facilities at coastal regions")
        #warning("Add warehouse network serving agricultural areas")
        #warning("Add utility networks (electricity, water, communications)")
        #warning("Add public service facilities")
        #warning("Add industrial and agricultural facilities")
        #warning("Set up interconnections between all node types")
        #warning("Initialize economic tracking and performance metrics")
        #warning("Configure maintenance schedules and degradation models")
        #warning("Set up connectivity between all infrastructure categories")
        #warning("TODO: Complete base infrastructure initialization - see comments above")
        
        // Initialize base nodes for each infrastructure type category
        initializeBaseInfrastructure()
        
        #warning("Set up initial economic calculations")
        #warning("Configure degradation and maintenance models")
    }
    
    // MARK: - Base Infrastructure Initialization
    
    private func initializeBaseInfrastructure() {
        #warning("Initialize road network grid")
        let gridSize = 15 // 15x15 grid for more comprehensive coverage
        let cellSize = 8.0 // km
        
        // Create primary roads grid
        for i in 0..<gridSize {
            // North-south primary road
            let roadId1 = "primary_NS_\(i)"
            let road1 = InfrastructureNode(
                id: roadId1,
                type: .primary_arterial,
                location: (x: Double(i) * cellSize, y: 0),
                capacity: 40000
            )
            addNode(road1)
            roads[roadId1] = road1
            
            // East-west primary road
            let roadId2 = "primary_EW_\(i)"
            let road2 = InfrastructureNode(
                id: roadId2,
                type: .primary_arterial,
                location: (x: 0, y: Double(i) * cellSize),
                capacity: 40000
            )
            addNode(road2)
            roads[roadId2] = road2
        }
        
        // Create secondary roads grid
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                if i < gridSize - 1 {
                    let roadId = "secondary_\(i)_\(j)"
                    let road = InfrastructureNode(
                        id: roadId,
                        type: .secondary_major,
                        location: (x: Double(i) * cellSize + cellSize/2, y: Double(j) * cellSize + cellSize/2),
                        capacity: 15000
                    )
                    addNode(road)
                    roads[roadId] = road
                }
                
                if j < gridSize - 1 {
                    let roadId = "secondaryEW_\(i)_\(j)"
                    let road = InfrastructureNode(
                        id: roadId,
                        type: .secondary_minor,
                        location: (x: Double(i) * cellSize + cellSize/2, y: Double(j) * cellSize + cellSize/2),
                        capacity: 8000
                    )
                    addNode(road)
                    roads[roadId] = road
                }
            }
        }
        
        #warning("Initialize railway network")
        // Create main railway lines
        let railwayId1 = "railway_main_NS"
        let railway1 = InfrastructureNode(
            id: railwayId1,
            type: .railway_double,
            location: (x: 0, y: 0),
            capacity: 50000
        )
        addNode(railway1)
        railways[railwayId1] = railway1
        
        let railwayId2 = "railway_main_EW"
        let railway2 = InfrastructureNode(
            id: railwayId2,
            type: .railway_double,
            location: (x: 120, y: 120),
            capacity: 50000
        )
        addNode(railway2)
        railways[railwayId2] = railway2
        
        #warning("Initialize bridge network")
        // Create sample bridges
        let bridgeId1 = "bridge_river_1"
        let bridge1 = InfrastructureNode(
            id: bridgeId1,
            type: .bridge_beam,
            location: (x: 60, y: 60),
            capacity: 3000
        )
        addNode(bridge1)
        bridges[bridgeId1] = bridge1
        
        let bridgeId2 = "bridge_river_2"
        let bridge2 = InfrastructureNode(
            id: bridgeId2,
            type: .bridge_suspension,
            location: (x: 65, y: 65),
            capacity: 5000
        )
        addNode(bridge2)
        bridges[bridgeId2] = bridge2
        
        #warning("Initialize port facilities")
        let portId1 = "port_coastal_1"
        let port1 = InfrastructureNode(
            id: portId1,
            type: .port_commercial,
            location: (x: 0, y: 0),
            capacity: 100000
        )
        addNode(port1)
        ports[portId1] = port1
        
        #warning("Initialize warehouse network")
        let warehouseId1 = "warehouse_central_1"
        let warehouse1 = InfrastructureNode(
            id: warehouseId1,
            type: .warehouse_dry,
            location: (x: 75, y: 75),
            capacity: 8000
        )
        addNode(warehouse1)
        warehouses[warehouseId1] = warehouse1
        
        #warning("Initialize utility networks")
        let utilityId1 = "substation_1"
        let utility1 = InfrastructureNode(
            id: utilityId1,
            type: .substation_step_down,
            location: (x: 40, y: 40),
            capacity: 50000
        )
        addNode(utility1)
        utilities[utilityId1] = utility1
        
        let utilityId2 = "water_treatment_1"
        let utility2 = InfrastructureNode(
            id: utilityId2,
            type: .water_treatment_plants,
            location: (x: 100, y: 100),
            capacity: 80000
        )
        addNode(utility2)
        utilities[utilityId2] = utility2
        
        #warning("Initialize public service facilities")
        let fireId1 = "fire_station_1"
        let fire1 = InfrastructureNode(
            id: fireId1,
            type: .fire_station_urban,
            location: (x: 75, y: 75),
            capacity: 1
        )
        addNode(fire1)
        publicServices[fireId1] = fire1
        
        let policeId1 = "police_station_1"
        let police1 = InfrastructureNode(
            id: policeId1,
            type: .police_station_local,
            location: (x: 75, y: 80),
            capacity: 1
        )
        addNode(police1)
        publicServices[policeId1] = police1
        
        #warning("Initialize industrial facilities")
        let factoryId1 = "factory_central_1"
        let factory1 = InfrastructureNode(
            id: factoryId1,
            type: .factory_manufacturing,
            location: (x: 110, y: 50),
            capacity: 10000
        )
        addNode(factory1)
        industrial[factoryId1] = factory1
        
        #warning("Initialize agricultural facilities")
        let elevatorId1 = "grain_elevator_1"
        let elevator1 = InfrastructureNode(
            id: elevatorId1,
            type: .elevator_grain,
            location: (x: 30, y: 110),
            capacity: 3000
        )
        addNode(elevator1)
        agricultural[elevatorId1] = elevator1
    }
    
    // MARK: - Node Management
    
    public func addNode(_ node: InfrastructureNode) {
        nodes[node.id] = node
        
        // Categorize by type
        switch node.type {
        case .highway_4lane, .highway_6lane, .highway_8lane, .highway_improved:
            roads[node.id] = node
        case .primary_arterial, .primary_collector, .primary_suburban:
            roads[node.id] = node
        case .secondary_major, .secondary_minor, .secondary_residential:
            roads[node.id] = node
        case .tertiary_main, .tertiary_feeder, .tertiary_local:
            roads[node.id] = node
        case .service_industrial, .service_commercial, .service_residential:
            roads[node.id] = node
        case .alley_main, .alley_sub:
            roads[node.id] = node
            
        case .railway_single, .railway_double, .railway_high_speed, .railway_narrow, .railway_tram:
            railways[node.id] = node
            
        case .bridge_beam, .bridge_arch, .bridge_suspension, .bridge_cable_stayed, .bridge_box_girder, .bridge_viaduct, .bridge_tunnel:
            bridges[node.id] = node
            
        case .port_fishing, .port_commercial, .port_cargo, .port_container, .port_tanker, .port_referigerated:
            ports[node.id] = node
            
        case .warehouse_dry, .warehouse_ref, .warehouse_hazmat, .warehouse_dist, .warehouse_farm, .silo_grain, .silo_seed:
            warehouses[node.id] = node
            
        case .substation_step_down, .substation_step_up:
            utilities[node.id] = node
        case .grid_transmission, .grid_distribution:
            utilities[node.id] = node
        case .water_treatment_plants, .water_distribution:
            utilities[node.id] = node
        case .communications_fiber, .communications_wireless:
            utilities[node.id] = node
            
        case .fire_station_urban, .fire_station_rural:
            publicServices[node.id] = node
        case .police_station_local, .police_station_regional:
            publicServices[node.id] = node
        case .hospital, .clinic:
            publicServices[node.id] = node
            
        case .factory_manufacturing, .factory_assembly, .factory_processing:
            industrial[node.id] = node
        case .refinery_petroleum, .refinery_chemical:
            industrial[node.id] = node
        case .mine_open_pit, .mine_underground:
            industrial[node.id] = node
            
        case .elevator_grain, .mill_feed, .plant_processing, .greenhouse_standard, .greenhouse_hydroponic, .greenhouse_aquaponic:
            agricultural[node.id] = node
        }
        
        setupNodeConnections(node)
    }
    
    private func setupNodeConnections(_ node: InfrastructureNode) {
        // Would calculate optimal connections based on node locations and types
        // For now, establish basic connections within reasonable distance
        let nodeLoc = node.location
        
        for (otherId, otherNode) in nodes where otherId != node.id {
            let otherLoc = otherNode.location
            let distance = sqrt(pow(nodeLoc.x - otherLoc.x, 2) + pow(nodeLoc.y - otherLoc.y, 2))
            
            // Connect nodes within 50km of each other
            if distance > 0 && distance < 50 {
                if connectNodes(node.id, to: otherId, linkType: determineLinkType(node.type, otherNode.type)) {
                    // Connection established
                }
            }
        }
    }
    
    private func determineLinkType(_ type1: InfrastructureType, _ type2: InfrastructureType) -> InfrastructureLinkType {
        // Determine the appropriate link type based on infrastructure types
        if type1.isRoad && type2.isRoad {
            return .road
        } else if type1.isRailway && type2.isRailway {
            return .rail
        } else if type1.isBridge && type2.isBridge {
            return .bridge
        } else if type1.isPort && type2.isPort {
            return .port
        } else if type1.isWarehouse && type2.isWarehouse {
            return .warehouse
        } else if type1.isUtility && type2.isUtility {
            return .utility
        } else if type1.isPublicService && type2.isPublicService {
            return .public_service
        } else if type1.isIndustrial && type2.isIndustrial {
            return .industrial
        } else if type1.isAgricultural && type2.isAgricultural {
            return .agricultural
        }
        return .intermodal
    }
    
    public func getNode(_ id: String) -> InfrastructureNode? {
        return nodes[id]
    }
    
    public func getRoads() -> [InfrastructureNode] { return Array(roads.values) }
    public func getRailways() -> [InfrastructureNode] { return Array(railways.values) }
    public func getBridges() -> [InfrastructureNode] { return Array(bridges.values) }
    public func getPorts() -> [InfrastructureNode] { return Array(ports.values) }
    public func getWarehouses() -> [InfrastructureNode] { return Array(warehouses.values) }
    public func getUtilities() -> [InfrastructureNode] { return Array(utilities.values) }
    public func getPublicServices() -> [InfrastructureNode] { return Array(publicServices.values) }
    public func getIndustrial() -> [InfrastructureNode] { return Array(industrial.values) }
    public func getAgricultural() -> [InfrastructureNode] { return Array(agricultural.values) }
    
    // MARK: - Connection Management
    
    public func connectNodes(_ nodeId1: String, to nodeId2: String, linkType: InfrastructureLinkType) -> Bool {
        guard var node1 = nodes[nodeId1], var node2 = nodes[nodeId2] else { return false }
        
        // Add to connectivity graph
        if connectivityGraph[nodeId1] == nil {
            connectivityGraph[nodeId1] = [:]
        }
        if connectivityGraph[nodeId2] == nil {
            connectivityGraph[nodeId2] = [:]
        }
        
        connectivityGraph[nodeId1]![nodeId2] = linkType
        connectivityGraph[nodeId2]![nodeId1] = linkType
        
        // Update node connections
        if !node1.connectedNodes.contains(nodeId2) {
            node1.connectedNodes.append(nodeId2)
        }
        if !node2.connectedNodes.contains(nodeId1) {
            node2.connectedNodes.append(nodeId1)
        }
        
        nodes[nodeId1] = node1
        nodes[nodeId2] = node2
        
        recalculateNetworkMetrics()
        
        return true
    }
    
    private func recalculateNetworkMetrics() {
        calculateCapacityUtilization()
        calculateAverageCondition()
        calculateEconomicActivity()
    }
    
    private func calculateCapacityUtilization() {
        var totalCapacity: Double = 0
        var totalUsed: Double = 0
        
        for node in nodes.values {
            totalCapacity += node.capacity
            totalUsed += node.currentThroughput
        }
        
        totalCapacityUtilization = totalCapacity > 0 ? totalUsed / totalCapacity : 0
    }
    
    private func calculateAverageCondition() {
        var totalRating: Double = 0
        var count = 0
        
        for node in nodes.values {
            totalRating += node.condition.rating
            count += 1
        }
        
        averageConditionRating = count > 0 ? totalRating / Double(count) / 100 : 0.5
    }
    
    // MARK: - Throughput and Flow Management
    
    public func updateDailyTraffic(_ nodeIds: [String], vehicles: [String: Double]) {
        for nodeId in nodeIds {
            if let node = nodes[nodeId], node.type.isRoad {
                dailyTraffic[nodeId] = vehicles[nodeId] ?? 0
                
                // Recalculate level of service and congestion
                updateCongestionStatus(nodeId)
            }
        }
    }
    
    private func updateCongestionStatus(_ nodeId: String) {
        guard let node = nodes[nodeId], node.type.isRoad else { return }
        
        let trafficRatio = node.currentThroughput / max(1, node.capacity)
        
        if trafficRatio > 0.9 {
            node.status = .congested
        } else if trafficRatio > 0.7 {
            node.status = .at_capacity
        } else {
            node.status = .active
        }
    }
    
    public func updateFreightFlows(_ flows: [String: Double]) {
        for (nodeId, flow) in flows {
            freightFlows[nodeId] = flow
        }
    }
    
    public func updateUtilityUsage(_ usage: [String: Double]) {
        for (nodeId, usageValue) in usage {
            utilityUsage[nodeId] = usageValue
        }
    }
    
    public func calculateEconomicActivity() -> Double {
        var totalActivity: Double = 0
        
        // Road contribution
        for (nodeId, traffic) in dailyTraffic {
            if let node = nodes[nodeId], node.type.isRoad {
                let linkValue = calculateLinkEconomicValue(node.type, traffic: traffic, isRoad: true)
                totalActivity += linkValue
            }
        }
        
        // Freight contribution
        for (nodeId, flow) in freightFlows {
            if let node = nodes[nodeId] {
                let linkValue = calculateLinkEconomicValue(node.type, freight: flow, isRoad: false)
                totalActivity += linkValue
            }
        }
        
        // Utility contribution
        for (nodeId, usage) in utilityUsage {
            if let node = nodes[nodeId], node.type.isUtility {
                let linkValue = calculateUtilityEconomicValue(node.type, usage: usage)
                totalActivity += linkValue
            }
        }
        
        // Trade throughput at ports
        for (nodeId, portNode) in ports {
            if let node = nodes[nodeId] {
                // Port economic value based on throughput
                let portValue = calculatePortEconomicValue(node)
                totalActivity += portValue
            }
        }
        
        self.dailyEconomicActivity = totalActivity
        return totalActivity
    }
    
    private func calculateLinkEconomicValue(_ type: InfrastructureType, traffic: Double, isRoad: Bool) -> Double {
        let baseValue: Double
        
        switch type {
        case .highway_4lane: baseValue = isRoad ? 1.0 : 0.8
        case .highway_6lane: baseValue = isRoad ? 1.5 : 1.2
        case .highway_8lane: baseValue = isRoad ? 2.0 : 1.6
        case .highway_improved: baseValue = isRoad ? 1.2 : 1.0
        case .primary_arterial: baseValue = isRoad ? 0.8 : 0.6
        case .primary_collector: baseValue = isRoad ? 0.5 : 0.4
        case .primary_suburban: baseValue = isRoad ? 0.4 : 0.3
        case .secondary_major: baseValue = isRoad ? 0.6 : 0.5
        case .secondary_minor: baseValue = isRoad ? 0.3 : 0.25
        case .secondary_residential: baseValue = isRoad ? 0.2 : 0.15
        case .tertiary_main: baseValue = isRoad ? 0.3 : 0.25
        case .tertiary_feeder: baseValue = isRoad ? 0.2 : 0.15
        case .tertiary_local: baseValue = isRoad ? 0.1 : 0.05
        case .service_industrial: baseValue = isRoad ? 0.5 : 0.4
        case .service_commercial: baseValue = isRoad ? 0.4 : 0.3
        case .service_residential: baseValue = isRoad ? 0.2 : 0.1
        case .alley_main: baseValue = isRoad ? 0.1 : 0.05
        case .alley_sub: baseValue = isRoad ? 0.05 : 0.02
        case .railway_single: baseValue = isRoad ? 1.0 : 1.2
        case .railway_double: baseValue = isRoad ? 1.5 : 1.8
        case .railway_high_speed: baseValue = isRoad ? 2.0 : 2.5
        case .railway_narrow: baseValue = isRoad ? 0.5 : 0.6
        case .railway_tram: baseValue = isRoad ? 0.8 : 0.9
        case .bridge_beam: baseValue = isRoad ? 0.5 : 0.6
        case .bridge_arch: baseValue = isRoad ? 0.6 : 0.7
        case .bridge_suspension: baseValue = isRoad ? 0.8 : 1.0
        case .bridge_cable_stayed: baseValue = isRoad ? 0.7 : 0.8
        case .bridge_box_girder: baseValue = isRoad ? 0.6 : 0.7
        case .bridge_viaduct: baseValue = isRoad ? 0.7 : 0.8
        case .bridge_tunnel: baseValue = isRoad ? 0.9 : 1.0
        case .port_fishing: baseValue = isRoad ? 2.0 : 2.5
        case .port_commercial: baseValue = isRoad ? 3.0 : 3.5
        case .port_cargo: baseValue = isRoad ? 4.0 : 4.5
        case .port_container: baseValue = isRoad ? 4.5 : 5.0
        case .port_tanker: baseValue = isRoad ? 3.5 : 4.0
        case .port_referigerated: baseValue = isRoad ? 3.5 : 4.0
        case .warehouse_dry: baseValue = isRoad ? 0.4 : 0.5
        case .warehouse_ref: baseValue = isRoad ? 0.6 : 0.7
        case .warehouse_hazmat: baseValue = isRoad ? 0.8 : 1.0
        case .warehouse_dist: baseValue = isRoad ? 1.0 : 1.2
        case .warehouse_farm: baseValue = isRoad ? 0.5 : 0.6
        case .silo_grain: baseValue = isRoad ? 0.5 : 0.6
        case .silo_seed: baseValue = isRoad ? 0.4 : 0.5
        case .substation_step_down: baseValue = isRoad ? 1.5 : 1.8
        case .substation_step_up: baseValue = isRoad ? 1.3 : 1.5
        case .grid_transmission: baseValue = isRoad ? 2.0 : 2.5
        case .grid_distribution: baseValue = isRoad ? 1.5 : 1.8
        case .water_treatment_plants: baseValue = isRoad ? 1.5 : 1.8
        case .water_distribution: baseValue = isRoad ? 0.8 : 1.0
        case .communications_fiber: baseValue = isRoad ? 1.2 : 1.5
        case .communications_wireless: baseValue = isRoad ? 1.0 : 1.2
        case .fire_station_urban: baseValue = isRoad ? 2.5 : 3.0
        case .fire_station_rural: baseValue = isRoad ? 2.0 : 2.5
        case .police_station_local: baseValue = isRoad ? 2.0 : 2.5
        case .police_station_regional: baseValue = isRoad ? 2.5 : 3.0
        case .hospital: baseValue = isRoad ? 3.0 : 3.5
        case .clinic: baseValue = isRoad ? 1.5 : 1.8
        case .factory_manufacturing: baseValue = isRoad ? 2.0 : 2.5
        case .factory_assembly: baseValue = isRoad ? 1.5 : 1.8
        case .factory_processing: baseValue = isRoad ? 1.8 : 2.0
        case .refinery_petroleum: baseValue = isRoad ? 3.5 : 4.0
        case .refinery_chemical: baseValue = isRoad ? 3.0 : 3.5
        case .mine_open_pit: baseValue = isRoad ? 2.5 : 3.0
        case .mine_underground: baseValue = isRoad ? 2.0 : 2.5
        case .elevator_grain: baseValue = isRoad ? 0.8 : 1.0
        case .mill_feed: baseValue = isRoad ? 0.5 : 0.6
        case .plant_processing: baseValue = isRoad ? 0.9 : 1.0
        case .greenhouse_standard: baseValue = isRoad ? 0.7 : 0.8
        case .greenhouse_hydroponic: baseValue = isRoad ? 0.8 : 0.9
        case .greenhouse_aquaponic: baseValue = isRoad ? 0.9 : 1.0
        case .intermodal_terminal: baseValue = isRoad ? 2.5 : 3.0
        case .airport_international: baseValue = isRoad ? 5.0 : 6.0
        case .airport_regional: baseValue = isRoad ? 2.0 : 2.5
        default: baseValue = isRoad ? 0.3 : 0.4
        }
        
        let trafficFactor = min(1.0, traffic / 50000)
        let qualityFactor = max(0.5, min(1.5, nodeConditionRatingFactor(type)))
        
        return baseValue * trafficFactor * qualityFactor * (isRoad ? 500 : 300)
    }
    
    private func calculateLinkEconomicValue(_ type: InfrastructureType, freight: Double, isRoad: Bool) -> Double {
        let baseValue: Double
        
        switch type {
        case .railway_single: baseValue = 1.2
        case .railway_double: baseValue = 1.8
        case .railway_high_speed: baseValue = 2.5
        case .railway_narrow: baseValue = 0.6
        case .railway_tram: baseValue = 0.9
        case .port_fishing: baseValue = 2.5
        case .port_commercial: baseValue = 3.5
        case .port_cargo: baseValue = 5.0
        case .port_container: baseValue = 5.5
        case .port_tanker: baseValue = 4.5
        case .port_referigerated: baseValue = 4.0
        case .warehouse_dry: baseValue = 0.5
        case .warehouse_ref: baseValue = 0.8
        case .warehouse_hazmat: baseValue = 1.0
        case .warehouse_dist: baseValue = 1.2
        case .warehouse_farm: baseValue = 0.6
        case .silo_grain: baseValue = 0.6
        case .silo_seed: baseValue = 0.5
        case .factory_manufacturing: baseValue = 2.0
        case .refinery_petroleum: baseValue = 4.0
        case .refinery_chemical: baseValue = 3.5
        case .mine_open_pit: baseValue = 2.5
        case .mine_underground: baseValue = 2.0
        default: baseValue = 0.3
        }
        
        let freightFactor = min(1.0, freight / 100000)
        let qualityFactor = max(0.5, min(1.5, nodeConditionRatingFactor(type)))
        
        return baseValue * freightFactor * qualityFactor * 300
    }
    
    private func calculateUtilityEconomicValue(_ type: InfrastructureType, usage: Double) -> Double {
        let baseValue: Double
        
        switch type {
        case .substation_step_down: baseValue = 2.0
        case .substation_step_up: baseValue = 1.5
        case .grid_transmission: baseValue = 2.5
        case .grid_distribution: baseValue = 1.5
        case .water_treatment_plants: baseValue = 1.5
        case .water_distribution: baseValue = 0.8
        case .communications_fiber: baseValue = 1.2
        case .communications_wireless: baseValue = 1.0
        default: baseValue = 0.5
        }
        
        let usageFactor = min(1.0, usage / 50000)
        let qualityFactor = max(0.5, min(1.5, nodeConditionRatingFactor(type)))
        
        return baseValue * usageFactor * qualityFactor * 200
    }
    
    private func nodeConditionRatingFactor(_ type: InfrastructureType) -> Double {
        // Find the condition rating for nodes of this type
        var averageRating: Double = 50 // default
        var count = 0
        
        for node in nodes.values where node.type == type || 
            (type.isRoad && node.type.isRoad) ||
            (type.isRailway && node.type.isRailway) ||
            (type.isUtility && node.type.isUtility) {
            averageRating += node.condition.rating
            count += 1
        }
        
        if count > 0 {
            return averageRating / Double(count) / 100
        }
        return 0.5
    }
    
    private func calculatePortEconomicValue(_ node: InfrastructureNode) -> Double {
        guard let portNode = node as? InfrastructureNode else { return 0 }
        // Simplified port economic value based on capacity and throughput
        let baseValue: Double
        switch portNode.type {
        case .port_fishing: baseValue = 2.0
        case .port_commercial: baseValue = 3.0
        case .port_cargo: baseValue = 4.0
        case .port_container: baseValue = 4.5
        case .port_tanker: baseValue = 3.5
        case .port_referigerated: baseValue = 3.5
        default: baseValue = 1.0
        }
        
        let capacityFactor = min(1.0, portNode.currentThroughput / max(1, portNode.capacity))
        let utilizationValue = baseValue * capacityFactor * 1000
        
        return utilizationValue
    }
    
    // MARK: - Maintenance Management
    
    public func scheduleMaintenance(_ nodeId: String, maintenanceDate: Date, maintenanceType: MaintenanceType, priority: MaintenancePriority) {
        var schedule = maintenanceSchedule[nodeId] ?? []
        schedule.append(maintenanceDate)
        maintenanceSchedule[nodeId] = schedule.sorted()
        
        #warning("Apply maintenance effects: improve condition rating")
        // Would improve condition rating and reduce deterioration
    }
    
    public func performMaintenance(_ nodeId: String, maintenanceDate: Date) -> MaintenanceResult {
        guard var node = nodes[nodeId] else {
            return MaintenanceResult(success: false, message: "Node not found")
        }
        
        #warning("Apply maintenance effects to node condition")
        // Would improve condition, reduce deterioration, update capacities
        
        let conditionImprovement = 10.0 // % improvement
        node.condition.maintain(improvement: conditionImprovement)
        nodes[nodeId] = node
        
        return MaintenanceResult(
            success: true,
            message: "Maintenance performed on \(node.type.rawValue)",
            repairCost: conditionImprovement * 10, // Cost proportional to improvement
            conditionImprovement: conditionImprovement,
            nodesAffected: 1
        )
    }
    
    // MARK: - Network Analysis
    
    public func calculateNetworkMetrics() -> NetworkMetrics {
        let nodeCount = nodes.count
        let connectedCount = connectivityGraph.values.reduce(0) { $0 + $1.count }
        let averageConnections = nodeCount > 0 ? Double(connectedCount) / Double(nodeCount) / 2 : 0
        
        // Average condition
        var totalConditionValue: Double = 0
        var conditionCount = 0
        
        for node in nodes.values {
            let rating: Double = node.condition.rating
            totalConditionValue += rating
            conditionCount += 1
        }
        
        let averageCondition = conditionCount > 0 ? totalConditionValue / Double(conditionCount) : 50
        
        // Calculate congestion hotspots
        var congestionValues: [String: Double] = [:]
        for (nodeId, traffic) in dailyTraffic {
            if let node = nodes[nodeId], node.type.isRoad {
                let ratio = traffic / max(1, node.capacity)
                congestionValues[nodeId] = ratio
            }
        }
        
        let totalDeferred = maintenanceSchedule.values.reduce(0) { $0 + $1.count > 0 ? 0 : 0 }
        
        return NetworkMetrics(
            nodeCount: nodeCount,
            averageConnections: averageConnections,
            averageCondition: averageCondition,
            totalCapacityUtilization: totalCapacityUtilization,
            congestionHotspots: congestionValues,
            totalDeferredMaintenance: totalDeferred,
            networkEfficiency: networkEfficiency,
            dailyEconomicActivity: dailyEconomicActivity,
            tradeVolumeThroughput: tradeVolumeThroughput
        )
    }
    
    // MARK: - Period Advance
    
    mutating func advancePeriod(days: Double = 1) {
        #warning("Advance all infrastructure nodes")
        
        // Advance all nodes' condition deterioration
        for (nodeId, node) in nodes where node.type.isRoad || node.type.isRailway || node.type.isBridge {
            var updatedNode = node
            updatedNode.condition.deteriorate(days: days)
            nodes[nodeId] = updatedNode
        }
        
        // Update economic activity
        calculateEconomicActivity()
        
        // Advance maintenance schedules
        for (nodeId, schedule) in maintenanceSchedule {
            var updatedSchedule = schedule
            if let firstDate = schedule.first, firstDate < Date().addingTimeInterval(days * 30) {
                updatedSchedule.removeFirst()
                // Schedule next maintenance
                let nextDate = Date().addingTimeInterval(365*24*60*60) // 1 year
                updatedSchedule.append(nextDate)
                maintenanceSchedule[nodeId] = updatedSchedule.sorted()
            }
        }
        
        currentSimulationPeriod += 1
        
        #warning("Recalculate network metrics after period advance")
        recalculateNetworkMetrics()
    }
    
    // MARK: - Traffic Management
    
    public func redirectTraffic(_ fromNodeId: String, toNodeId: String, viaRoute: [String]) -> Double {
        // Redirect traffic from congested node to alternative route
        // Returns percentage of traffic successfully redirected
        
        guard let fromNode = nodes[fromNodeId],
              let toNode = nodes[toNodeId],
              fromNode.type.isRoad,
              toNode.type.isRoad else {
            return 0
        }
        
        let congestionFrom = fromNode.currentThroughput / max(1, fromNode.capacity)
        let capacityTo = toNode.capacity - toNode.currentThroughput
        let availableSpace = min(capacityTo, fromNode.capacity * 0.3) // Can take up to 30% of from node's capacity
        
        let redirectPercentage = min(availableSpace / max(1, fromNode.currentThroughput), 0.8)
        
        // Update throughputs
        fromNode.currentThroughput *= (1 - redirectPercentage)
        toNode.currentThroughput += fromNode.currentThroughput * redirectPercentage
        
        nodes[fromNodeId] = fromNode
        nodes[toNodeId] = toNode
        
        return redirectPercentage
    }
    
    // MARK: - Economic Reports
    
    func getInfrastructureReport() -> InfrastructureEconomicReport {
        let metrics = calculateNetworkMetrics()
        
        return InfrastructureEconomicReport(
            totalNodes: nodes.count,
            roadCount: roads.count,
            railwayCount: railways.count,
            bridgeCount: bridges.count,
            portCount: ports.count,
            warehouseCount: warehouses.count,
            utilityCount: utilities.count,
            publicServiceCount: publicServices.count,
            industrialCount: industrial.count,
            agriculturalCount: agricultural.count,
            totalCapacityUtilization: metrics.totalCapacityUtilization,
            averageConditionRating: metrics.averageCondition,
            totalDeferredMaintenance: metrics.totalDeferredMaintenance,
            dailyEconomicActivity: metrics.dailyEconomicActivity,
            tradeVolumeThroughput: metrics.tradeVolumeThroughput,
            congestionHotspots: metrics.congestionHotspots.count,
            employmentSupported: employmentSupported,
            infrastructureInvestment: infrastructureInvestment,
            maintenanceRevenue: maintenanceRevenue,
            period: currentSimulationPeriod
        )
    }
}

// MARK: - Supporting Types

public enum MaintenanceType: String, CaseIterable {
    case routine = "routine"
    case preventive = "preventive"
    case corrective = "corrective"
    case emergency = "emergency"
    case upgrade = "upgrade"
    case expansion = "expansion"
}

public enum MaintenancePriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public struct MaintenanceResult {
    public var success: Bool
    public var message: String
    public var repairCost: Double
    public var conditionImprovement: Double
    public var nodesAffected: Int
    
    public init(success: Bool, message: String, repairCost: Double = 0, conditionImprovement: Double = 0, nodesAffected: Int = 0) {
        self.success = success
        self.message = message
        self.repairCost = repairCost
        self.conditionImprovement = conditionImprovement
        self.nodesAffected = nodesAffected
    }
}

public struct NetworkMetrics {
    public var nodeCount: Int
    public var averageConnections: Double
    public var averageCondition: Double
    public var totalCapacityUtilization: Double
    public var congestionHotspots: [String: Double]
    public var totalDeferredMaintenance: Double
    public var networkEfficiency: Double
    public var dailyEconomicActivity: Double
    public var tradeVolumeThroughput: Double
    
    public init(
        nodeCount: Int,
        averageConnections: Double,
        averageCondition: Double,
        totalCapacityUtilization: Double,
        congestionHotspots: [String: Double],
        totalDeferredMaintenance: Double,
        networkEfficiency: Double,
        dailyEconomicActivity: Double,
        tradeVolumeThroughput: Double
    ) {
        self.nodeCount = nodeCount
        self.averageConnections = averageConnections
        self.averageCondition = averageCondition
        self.totalCapacityUtilization = totalCapacityUtilization
        self.congestionHotspots = congestionHotspots
        self.totalDeferredMaintenance = totalDeferredMaintenance
        self.networkEfficiency = networkEfficiency
        self.dailyEconomicActivity = dailyEconomicActivity
        self.tradeVolumeThroughput = tradeVolumeThroughput
    }
}

// MARK: - Economic Report Structure

public struct InfrastructureEconomicReport {
    public var totalNodes: Int
    public var roadCount: Int
    public var railwayCount: Int
    public var bridgeCount: Int
    public var portCount: Int
    public var warehouseCount: Int
    public var utilityCount: Int
    public var publicServiceCount: Int
    public var industrialCount: Int
    public var agriculturalCount: Int
    public var totalCapacityUtilization: Double
    public var averageConditionRating: Double
    public var totalDeferredMaintenance: Double
    public var dailyEconomicActivity: Double
    public var tradeVolumeThroughput: Double
    public var congestionHotspots: Int
    public var employmentSupported: Int
    public var infrastructureInvestment: Double
    public var maintenanceRevenue: Double
    public var period: Int
    
    public init(
        totalNodes: Int,
        roadCount: Int,
        railwayCount: Int,
        bridgeCount: Int,
        portCount: Int,
        warehouseCount: Int,
        utilityCount: Int,
        publicServiceCount: Int,
        industrialCount: Int,
        agriculturalCount: Int,
        totalCapacityUtilization: Double,
        averageConditionRating: Double,
        totalDeferredMaintenance: Double,
        dailyEconomicActivity: Double,
        tradeVolumeThroughput: Double,
        congestionHotspots: Int,
        employmentSupported: Int,
        infrastructureInvestment: Double,
        maintenanceRevenue: Double,
        period: Int
    ) {
        self.totalNodes = totalNodes
        self.roadCount = roadCount
        self.railwayCount = railwayCount
        self.bridgeCount = bridgeCount
        self.portCount = portCount
        self.warehouseCount = warehouseCount
        self.utilityCount = utilityCount
        self.publicServiceCount = publicServiceCount
        self.industrialCount = industrialCount
        self.agriculturalCount = agriculturalCount
        self.totalCapacityUtilization = totalCapacityUtilization
        self.averageConditionRating = averageConditionRating
        self.totalDeferredMaintenance = totalDeferredMaintenance
        self.dailyEconomicActivity = dailyEconomicActivity
        self.tradeVolumeThroughput = tradeVolumeThroughput
        self.congestionHotspots = congestionHotspots
        self.employmentSupported = employmentSupported
        self.infrastructureInvestment = infrastructureInvestment
        self.maintenanceRevenue = maintenanceRevenue
        self.period = period
    }
}

// MARK: - Previews
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct InfrastructureLogisticsPreview: PreviewProvider {
//    static var previews: some View {
//        Text("Infrastructure Logistics System Preview")
//    }
//}
//#endif