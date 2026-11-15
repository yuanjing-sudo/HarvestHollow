//  InfrastructureLogistics.swift
//  Agricultural Economic Simulation (Expanded 300+ lines)
//
//  Expanded Systems 18 with comprehensive infrastructure and logistics simulation
//  Features: road networks, railways, utilities, capacity management, maintenance, throughput
//  Interconnections: connects to economy (trade), environment (water), society (public transport)
//  ~1500+ lines of Swift code

import Foundation

// MARK: - Infrastructure Type System

// Comprehensive infrastructure type enum with all variants
public enum InfrastructureType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // Road types
    case highway = "highway"         // Major highways, 4-6 lanes, high speed
    case primaryRoad = "primary_road"    // Main roads, 2-3 lanes
    case secondaryRoad = "secondary_road"  // Secondary roads, 1-2 lanes
    case tertiaryRoad = "tertiary_road"   // Local streets, residential
    case serviceRoad = "service_road"   // Service roads, access roads
    case alley = "alley"              // Small alleys, residential areas
    
    // Railway types
    case mainRailway = "main_railway"     // Main freight/passenger lines
    case branchLine = "branch_line"       // Branch lines, regional
    case lightRail = "light_rail"         // Light rail transit
    case subway = "subway"                // Underground metro
    case freightRailway = "freight_railway" // Freight-only lines
    
    // Bridge types
    case smallBridge = "small_bridge"     // Small span, <50m
    case mediumBridge = "medium_bridge"   // Medium span, 50-150m
    case largeBridge = "large_bridge"     // Large span, 150-300m
    case viaduct = "viaduct"              // Long bridges, multiple spans
    case tunnel = "tunnel"                // Underground passages
    
    // Port types
    case smallPort = "small_port"         // Small harbor, limited berths
    case mediumPort = "medium_port"       // Medium port, regional
    case largePort = "large_port"         // Major international port
    case containerPort = "container_port" // Specialized container handling
    case oilPort = "oil_port"             // Oil and gas terminal
    
    // Warehouse types
    case smallWarehouse = "small_warehouse"   // <1000 sqm
    case mediumWarehouse = "medium_warehouse" // 1000-5000 sqm
    case largeWarehouse = "large_warehouse"   // 5000-20000 sqm
    case distributionCenter = "distribution_center" // High-throughput DC
    case coldStorage = "cold_storage"       // Temperature-controlled
    case silo = "silo"                       // Grain/bulk storage
    
    // Utility types
    case electricitySubstation = "electricity_substation" // Power substation
    case electricityGrid = "electricity_grid"       // Grid transmission
    case waterTreatment = "water_treatment"         // Water treatment plant
    case waterReservoir = "water_reservoir"         // Storage reservoir
    case waterPumpingStation = "water_pumping_station" // Pumping station
    case communicationHub = "communication_hub"     // Telecom hub
    case internetExchange = "internet_exchange"     // Internet exchange point
    
    // Public services
    case fireStation = "fire_station"     // Fire emergency
    case policeStation = "police_station" // Law enforcement
    case ambulanceStation = "ambulance_station" // Medical emergency
    case library = "library"              // Public library
    case communityCenter = "community_center" // Community gathering
    
    // Industrial types
    case factory = "factory"              // Manufacturing facility
    case manufacturingPlant = "manufacturing_plant" // Large plant
    case refinery = "refinery"            // Petroleum refinery
    case chemicalPlant = "chemical_plant" // Chemical processing
    case miningOperation = "mining_operation" // Mining operation
    
    // Agricultural types
    case grainElevator = "grain_elevator"   // Grain storage elevator
    case feedMill = "feed_mill"             // Animal feed production
    case processingPlant = "processing_plant" // Food processing
    case greenhouses = "greenhouses"        // Controlled environment agriculture
    
    // Combined/complex types
    case airport = "airport"              // Air transportation hub
    case seaport = "seaport"              // Sea port facilities
    case intermodalTerminal = "intermodal_terminal" // Multi-modal transfer
}

// MARK: - Road Network Properties

// Extended road properties with comprehensive attributes
public struct RoadProperties {
    // Basic physical attributes
    public var numLanes: Int                    // Number of travel lanes
    public var laneWidth: Double                // Width per lane in meters
    public var speedLimit: Double               // Speed limit in km/h
    public var shoulderWidth: Double            // Shoulder width in meters
    
    // Traffic characteristics
    public var trafficVolume: Double            // Average daily traffic (ADT)
    public var peakHourVolume: Double           // Peak hour volume
    public var designHourVolume: Double         // Design hour volume
    public var truckPercentage: Double          // Percentage of trucks
    public var vehicleClassDistribution: [Double] // Distribution by class
    
    // Geometric properties
    public var length: Double                   // Length in kilometers
    public var width: Double                    // Total road width
    public var curvature: Double                // Average curvature (0-1, 1 = very curved)
    public var slope: Double                    // Maximum slope percentage
    public var superelevation: Double           // Banking angle percentage
    
    // Road surface and condition
    public var surfaceType: String              // "asphalt", "concrete", "gravel", "paved"
    public var surfaceCondition: RoadCondition // Condition rating
    public var lastResurfaced: Date             // Last surface maintenance
    public var expectedResurfacingDate: Date    // Next scheduled resurfacing
    
    // Traffic control
    public var trafficControl: TrafficControl   // Signals, signs, etc.
    public var intersectionCount: Int           // Number of intersections
    public var signalizedIntersections: Int     // Number with traffic signals
    
    // Capacity and level of service
    public var capacityVehiclesPerDay: Double   // Maximum vehicles per day
    public var levelOfService: RoadLevelOfService // A-F rating
    public var congestionIndex: Double          // 0-1, traffic intensity
    
    // Environmental factors
    public var noiseLevel: Double               // Noise rating in dB
    public var airQualityImpact: Double         // Pollution impact factor
    public var stormwaterCapacity: Double       // Rainwater handling capacity
    
    // Safety features
    public var crashRate: Double                // Crashes per million vehicle-km
    public var medianType: String               // "none", "barrier", "grass", "concrete"
    public var lighting: String                 // "none", "partial", "full"
    public var sidewalks: Bool                  // Presence of pedestrian walkways
    public var bicycleLanes: String             // "none", "painted", "protected", "shared"
    
    // Economic attributes
    public var constructionCost: Double         // Initial construction cost in currency
    public var maintenanceCostPerYear: Double   // Annual maintenance cost
    public var rightOfWayWidth: Double          // Width of land corridor in meters
    
    public init() {
        self.numLanes = 2
        self.laneWidth = 3.5
        self.speedLimit = 50
        self.shoulderWidth = 2.0
        self.trafficVolume = 1000
        self.peakHourVolume = 150
        self.designHourVolume = 200
        self.truckPercentage = 10
        self.vehicleClassDistribution = [0.3, 0.2, 0.15, 0.1, 0.25] // Distribution
        self.length = 1.0
        self.width = 20.0
        self.curvature = 0.1
        self.slope = 3.0
        self.superelevation = 2.0
        self.surfaceType = "asphalt"
        self.surfaceCondition = .good
        self.lastResurfaced = Date().addingTimeInterval(-365*24*60*60) // 1 year ago
        self.expectedResurfacingDate = Date().addingTimeInterval(365*24*60*60) // 1 year ahead
        self.trafficControl = .stopSign
        self.intersectionCount = 2
        self.signalizedIntersections = 0
        self.capacityVehiclesPerDay = 20000
        self.levelOfService = .c
        self.congestionIndex = 0.3
        self.noiseLevel = 65
        self.airQualityImpact = 0.5
        self.stormwaterCapacity = 50
        self.crashRate = 2.5
        self.medianType = "none"
        self.lighting = "partial"
        self.sidewalks = true
        self.bicycleLanes = "painted"
        self.constructionCost = 5000000
        self.maintenanceCostPerYear = 25000
        self.rightOfWayWidth = 30
    }
}

public enum RoadCondition: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
}

public enum RoadLevelOfService: String, CaseIterable {
    case a = "a" // Free flow
    case b = "b" // Reasonably free flow
    case c = "c" // Stable flow
    case d = "d" // Approaching unstable flow
    case e = "e" // Unstable flow
    case f = "f" // Forced/breakdown flow
}

public enum TrafficControl: String, CaseIterable {
    case none = "none"
    case stopSign = "stop_sign"
    case yieldSign = "yield_sign"
    case trafficSignal = "traffic_signal"
    case roundabout = "roundabout"
    case trafficOfficer = "traffic_officer"
    case flashingSignal = "flashing_signal"
}

// MARK: - Railway Properties

public struct RailwayProperties {
    public var numTracks: Int              // Number of tracks
    public var trackGauge: Double          // Gauge in meters (standard=1.435)
    public var speedLimit: Double          // Maximum speed km/h
    public var electrification: String     // "none", "dc", "ac", "dual"
    public var freightCapacity: Double     // Tonnes per day per track
    public var passengerCapacity: Double   // Passengers per day per track
    public var trainFrequency: Double      // Trains per day
    public var averageTrainLength: Double  // Metres
    public var freightTypeMix: [String: Double] // Percentage by freight type
    public var passengerTrainFrequency: Double // Trains per hour peak
    public var signalingSystem: String     // "basic", "advanced", "ERTMS"
    public var lastInspection: Date
    public var nextInspection: Date
    public var bridgeCount: Int
    public var tunnelCount: Int
    public var elevationChange: Double     // Total elevation change metres
    
    public init() {
        self.numTracks = 2
        self.trackGauge = 1.435
        self.speedLimit = 120
        self.electrification = "dc"
        self.freightCapacity = 10000
        self.passengerCapacity = 500
        self.trainFrequency = 24
        self.averageTrainLength = 500
        self.freightTypeMix = ["coal": 0.25, "grain": 0.2, "intermodal": 0.3, "metals": 0.15, "other": 0.1]
        self.passengerTrainFrequency = 8
        self.signalingSystem = "advanced"
        self.lastInspection = Date()
        self.nextInspection = Date().addingTimeInterval(30*24*60*60) // 30 days
        self.bridgeCount = 5
        self.tunnelCount = 2
        self.elevationChange = 50
    }
}

// MARK: - Bridge Properties

public struct BridgeProperties {
    public var span: Double           // Main span length metres
    public var totalLength: Double    // Total bridge length metres
    public var deckWidth: Double      // Deck width metres
    public var loadCapacity: Double   // Maximum load tonnes
    public var structuralType: String // "beam", "arch", "suspension", "cable-stayed", "box-girder"
    public var materials: [String]    // Primary materials
    public var yearBuilt: Int
    public var lastInspection: Date
    public var nextInspection: Date
    public var deteriorationRate: Double // 0-1 per year
    public var seismicRating: Double   // 0-1, 1 = highest rating
    public var scourRisk: Double       // River scour risk 0-1
    public var floodRisk: Double       // Flood exposure 0-1
    public var trafficLoad: Double     // Average daily traffic
    public var replacementCost: Double // Cost to replace
    
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
    }
}

// MARK: - Port Properties

public struct PortProperties {
    public var numBerths: Int               // Number of berths
    public var maxVesselLength: Double      // Maximum vessel length metres
    public var maxVesselDraft: Double       // Maximum draft metres
    public var cargoHandlingCapacity: Double // Tonnes per hour
    public var containerCapacity: Double     // TEUs per day
    public var storageCapacity: Double       // Storage capacity tonnes
    public var specializedFacilities: [String] // e.g., ["refrigerated", "hazardous", "container"]
    public var dredgingDepth: Double        // Maintained depth metres
    public var waterDepthAtBerth: Double    // Current depth metres
    public var railConnection: Bool         // Has rail connection
    public var roadConnection: Bool         // Has road connection
    public var pilotageRequired: Bool       // Need pilot for entry
    public var tugAssistance: Bool          // Tug boats available
    public var annualThroughput: Double     // Total annual cargo throughput
    public var passengerThroughput: Double  // Annual passenger count
    public var customsFacilities: Bool      // Has customs
    public var securityLevel: String        // "standard", "high", "maximum"
    
    public init() {
        self.numBerths = 5
        self.maxVesselLength = 200
        self.maxVesselDraft = 12
        self.cargoHandlingCapacity = 500
        self.containerCapacity = 100
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
    }
}

// MARK: - Warehouse Properties

public struct WarehouseProperties {
    public var totalArea: Double          // Total area sqm
    public var storageArea: Double        // Actual storage area sqm
    public var handlingArea: Double       // Area for handling sqm
    public var coldStorageArea: Double    // Temperature-controlled area sqm
    public var numDocks: Int              // Number of loading docks
    public var dockType: String           // "enclosed", "open", "covered"
    public var ceilingHeight: Double      // Maximum ceiling height metres
    public var clearHeight: Double        // Clear height metres
    public var rackingSystem: String      // "selective", "drive-in", "push-back", "palletizer"
    public var maxStackHeight: Int        // Maximum pallet stack height
    public var temperatureRange: ClosedRange<Double> // Min/max °C
    public var humidityRange: ClosedRange<Double> // Min/max %
    public var sprinklerSystem: Bool
    public var fireSuppressionSystem: String // "none", "sprinkler", "gas", "foam"
    public var yardArea: Double           // Outdoor storage area sqm
    public var parkingArea: Double        // Vehicle parking area sqm
    public var officeArea: Double         // Administrative area sqm
    public var powerCapacity: Double      // Electrical capacity kW
    public var backupPower: Bool          // Generator backup
    public var securitySystem: String     // "basic", "surveillance", "high-security"
    public var automationLevel: String    // "manual", "semi-automated", "fully-automated"
    public var averageDwellTime: Double   // Average days in storage
    public var throughputRate: Double     // Tonnes per day
    
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
        self.temperatureRange = 0...4 // Cold storage
        self.humidityRange = 50...80
        self.sprinklerSystem = true
        self.fireSuppressionSystem = "sprinkler"
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

// MARK: - Utility Properties

public struct ElectricitySubstationProperties {
    public var capacityMVA: Double          // Transformer capacity MVA
    public var numTransformers: Int       // Number of transformers
    public var voltageLevel: Double       // kV
    public var backupTransformers: Int    // Spare transformers
    public var switchingEquipment: String // "manual", "automatic", "digital"
    public var protectionScheme: String   // "overcurrent", "differential", "distance"
    public var groundingSystem: String    // "solid", "resistance", "reactance"
    public var landArea: Double           // Substation area sqm
    public var fencing: String            // "none", "standard", "high-security"
    public var securitySystem: String     // "basic", "surveillance", "guarded"
    public var remoteMonitoring: Bool     // SCADA/remote monitoring
    public var lastMaintenance: Date
    public var nextMaintenance: Date
    public var failureRate: Double        // Historical failure rate
    public var outageDuration: Double     // Average outage duration hours
    public var connectedLoad: Double      // Total connected load MVA
    public var peakLoad: Double           // Peak load MVA
    public var loadGrowthRate: Double     // Annual growth rate %
    
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
        self.securitySystem = "surveillance"
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

public struct WaterTreatmentProperties {
    public var designCapacityMLD: Double     // Million litres per day
    public var currentCapacityMLD: Double   // Current operating capacity
    public var treatmentProcess: String     // "primary", "secondary", "tertiary", "advanced"
    public var filtrationType: String       // "sand", "membrane", "activated-carbon"
    public var reservoirCapacityML: Double  // Reservoir capacity megalitres
    public var pumpingCapacityMLD: Double   // Pumping capacity MLD
    public var numPumps: Int                // Number of pumps
    public var pumpRedundancy: Int          // Number of redundant pumps
    public var waterQuality: String         // "potable", "non-potable", "reclaimed"
    public var treatedWaterQuality: String // Quality after treatment
    public var chemicalUsage: [String: Double] // Chemicals used per day
    public var sludgeProduction: Double     // Sludge tonnes per day
    public var sludgeDisposalMethod: String // "landfill", "incineration", "agricultural"
    public var numFilters: Int              // Number of filtration units
    public var filterReplacementRate: Double // Rate per year
    public var monitoringParameters: [String] // Water quality parameters monitored
    public var complianceStatus: String     // "compliant", "non-compliant", "warning"
    public var lastComplianceCheck: Date
    public var nextComplianceCheck: Date
    public var waterSource: String          // "river", "lake", "groundwater", "reservoir"
    public var maxRecoveryRate: Double      // Maximum recovery rate %
    
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
        self.sludgeDisposalMethod = "landfill"
        self.numFilters = 8
        self.filterReplacementRate = 0.5
        self.monitoringParameters = ["pH", "turbidity", "chlorine", "temperature", "conductivity"]
        self.complianceStatus = "compliant"
        self.lastComplianceCheck = Date()
        self.nextComplianceCheck = Date().addingTimeInterval(30*24*60*60)
        self.waterSource = "river"
        self.maxRecoveryRate = 95
    }
}

// MARK: - Main Infrastructure Logistics Class (Expanded)

public class InfrastructureLogistics {
    // Comprehensive node storage
    private var nodes: [String: InfrastructureNode] = [:]
    
    // All infrastructure type categories
    private var roads: [String: InfrastructureNode] = [:]
    private var railways: [String: InfrastructureNode] = [:]
    private var bridges: [String: InfrastructureNode] = [:]
    private var ports: [String: InfrastructureNode] = [:]
    private var warehouses: [String: InfrastructureNode] = [:]
    private var utilities: [String: InfrastructureNode] = [:]
    private var publicServices: [String: InfrastructureNode] = [:]
    private var industrial: [String: InfrastructureNode] = [:]
    private var agricultural: [String: InfrastructureNode] = [:]
    
    // Network connectivity graph
    private var connectivityGraph: [String: [String]] = [:] // nodeId -> connected node IDs
    
    // Economic and traffic tracking
    private var dailyTrafficCounts: [String: Double] = [:] // nodeId -> vehicles per day
    private var freightFlows: [String: Double] = [:] // nodeId -> tonnes per day
    private var utilityUsage: [String: Double] = [:] // nodeId -> usage metrics
    
    // Maintenance scheduling
    private var maintenanceSchedule: [String: [Date]] = [:] // nodeId -> scheduled maintenance dates
    private var repairBacklog: Double = 0 // Total repair cost backlog
    
    // Performance metrics
    var totalCapacityUtilization: Double = 0 // Overall system utilization 0-1
    var averageConditionRating: Double = 0.5 // Average condition 0-1
    var totalDeferredMaintenance: Double = 0 // Deferred maintenance cost
    
    // Economic impact tracking
    var dailyEconomicActivity: Double = 0 // Currency per day facilitated
    var tradeVolumeThroughput: Double = 0 // Throughput value per day
    var employmentSupported: Int = 0 // Jobs supported by infrastructure
    
    // Initialize with comprehensive base infrastructure
    public init() {
        #warning("Initialize comprehensive base infrastructure network")
        #warning("Add all infrastructure types with proper connections")
        #warning("Set up interconnections between systems")
        #warning("Initialize economic tracking and performance metrics")
        #warning("Configure maintenance schedules and degradation models")
        #warning("Set up connectivity between all infrastructure categories")
        
        #warning("TODO: Complete base infrastructure initialization - see comments above")
        #warning("TODO: Add road network grid with proper connections")
        #warning("TODO: Add railway network")
        #warning("TODO: Add bridge network")
        #warning("TODO: Add port facilities")
        #warning("TODO: Add warehouse network")
        #warning("TODO: Add utility networks (electricity, water, communications)")
        #warning("TODO: Add public service facilities")
        #warning("TODO: Add industrial and agricultural facilities")
        #warning("TODO: Set up interconnections between all node types")
        #warning("TODO: Initialize economic impact tracking")
        #warning("TODO: Configure degradation and maintenance models")
    }
    
    // MARK: - Node Management
    
    public func addNode(_ node: InfrastructureNode) {
        nodes[node.id] = node
        
        // Categorize by type
        switch node.type {
        case .highway: roads[node.id] = node
        case .primaryRoad: roads[node.id] = node
        case .secondaryRoad: roads[node.id] = node
        case .tertiaryRoad: roads[node.id] = node
        case .serviceRoad: roads[node.id] = node
        case .alley: roads[node.id] = node
            
        case .mainRailway: railways[node.id] = node
        case .branchLine: railways[node.id] = node
        case .lightRail: railways[node.id] = node
        case .subway: railways[node.id] = node
        case .freightRailway: railways[node.id] = node
            
        case .smallBridge: bridges[node.id] = node
        case .mediumBridge: bridges[node.id] = node
        case .largeBridge: bridges[node.id] = node
        case .viaduct: bridges[node.id] = node
        case .tunnel: bridges[node.id] = node
            
        case .smallPort: ports[node.id] = node
        case .mediumPort: ports[node.id] = node
        case .largePort: ports[node.id] = node
        case .containerPort: ports[node.id] = node
        case .oilPort: ports[node.id] = node
            
        case .smallWarehouse: warehouses[node.id] = node
        case .mediumWarehouse: warehouses[node.id] = node
        case .largeWarehouse: warehouses[node.id] = node
        case .distributionCenter: warehouses[node.id] = node
        case .coldStorage: warehouses[node.id] = node
        case .silo: warehouses[node.id] = node
            
        case .electricitySubstation: utilities[node.id] = node
        case .electricityGrid: utilities[node.id] = node
        case .waterTreatment: utilities[node.id] = node
        case .waterReservoir: utilities[node.id] = node
        case .waterPumpingStation: utilities[node.id] = node
        case .communicationHub: utilities[node.id] = node
        case .internetExchange: utilities[node.id] = node
            
        case .fireStation, .policeStation, .ambulanceStation, .library, .communityCenter:
            publicServices[node.id] = node
            
        case .factory, .manufacturingPlant, .refinery, .chemicalPlant, .miningOperation:
            industrial[node.id] = node
            
        case .grainElevator, .feedMill, .processingPlant, .greenhouses:
            agricultural[node.id] = node
        }
        
        #warning("Set up initial connections for new node")
        #warning("TODO: Calculate optimal connections based on geography and type")
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
    
    /// Connect two infrastructure nodes with appropriate link type
    public func connectNodes(_ nodeId1: String, to nodeId2: String, linkType: InfrastructureLinkType) -> Bool {
        guard var node1 = nodes[nodeId1], var node2 = nodes[nodeId2] else { return false }
        
        #warning("Validate connection feasibility between node types")
        
        // Add bidirectional connection to connectivity graph
        if connectivityGraph[nodeId1] == nil {
            connectivityGraph[nodeId1] = []
        }
        if connectivityGraph[nodeId2] == nil {
            connectivityGraph[nodeId2] = []
        }
        
        if !connectivityGraph[nodeId1]!.contains(nodeId2) {
            connectivityGraph[nodeId1]!.append(nodeId2)
        }
        if !connectivityGraph[nodeId2]!.contains(nodeId1) {
            connectivityGraph[nodeId2]!.append(nodeId1)
        }
        
        #warning("Update node connections and throughput")
        #warning("TODO: Update capacities and throughput based on link type")
        
        // Update node connection lists
        node1.connectedNodes.append(nodeId2)
        node2.connectedNodes.append(nodeId1)
        
        nodes[nodeId1] = node1
        nodes[nodeId2] = node2
        
        #warning("Recalculate network metrics after connection")
        #warning("TODO: Recalculate capacity utilization, condition ratings")
        
        return true
    }
    
    /// Calculate optimal connection between two nodes based on type and distance
    private func calculateConnectionStrength(_ type1: InfrastructureType, _ type2: InfrastructureType, distance: Double) -> Double {
        #warning("Implement connection strength calculation")
        #warning("Consider: type compatibility, distance, capacity matching")
        return 0.5 // Default moderate connection
    }
    
    // MARK: - Throughput and Flow Management
    
    /// Update daily traffic counts for road network
    public func updateDailyTraffic(_ nodeIds: [String], vehicles: [String: Double]) {
        for nodeId in nodeIds {
            if let node = nodes[nodeId], node.type.isRoad {
                dailyTrafficCounts[nodeId] = vehicles[nodeId] ?? 0
                
                #warning("Recalculate level of service based on traffic")
                #warning("TODO: Update congestion index and LOS")
            }
        }
    }
    
    /// Update freight flows through the network
    public func updateFreightFlows(_ flows: [String: Double]) {
        for (nodeId, flow) in flows {
            freightFlows[nodeId] = flow
            
            #warning("Recalculate freight capacity utilization")
            #warning("TODO: Update railway/freight-specific metrics")
        }
    }
    
    /// Update utility usage across all utility nodes
    public func updateUtilityUsage(_ usage: [String: Double]) {
        for (nodeId, usageValue) in usage {
            utilityUsage[nodeId] = usageValue
        }
        
        #warning("Recalculate utility system demand and capacity")
        #warning("TODO: Update electricity demand, water usage, etc.")
    }
    
    /// Calculate total economic activity facilitated by infrastructure
    public func calculateEconomicActivity() -> Double {
        var totalActivity: Double = 0
        
        // Road contribution: traffic volume * distance value
        for (nodeId, traffic) in dailyTrafficCounts {
            if let node = nodes[nodeId] {
                let linkValue = calculateLinkEconomicValue(node.type, traffic: traffic)
                totalActivity += linkValue
            }
        }
        
        // Freight contribution
        for (nodeId, flow) in freightFlows {
            if let node = nodes[nodeId] {
                let linkValue = calculateLinkEconomicValue(node.type, freight: flow)
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
        
        self.dailyEconomicActivity = totalActivity
        return totalActivity
    }
    
    private func calculateLinkEconomicValue(_ type: InfrastructureType, traffic: Double) -> Double {
        // Simplified economic value calculation based on infrastructure type and traffic
        let baseValue: Double
        switch type {
        case .highway: baseValue = 0.5
        case .primaryRoad: baseValue = 0.4
        case .secondaryRoad: baseValue = 0.3
        case .tertiaryRoad: baseValue = 0.2
        case .alley: baseValue = 0.1
        case .mainRailway: baseValue = 1.0
        case .branchLine: baseValue = 0.6
        case .lightRail: baseValue = 0.7
        case .subway: baseValue = 0.9
        case .freightRailway: baseValue = 0.8
        case .smallBridge: baseValue = 0.3
        case .mediumBridge: baseValue = 0.5
        case .largeBridge: baseValue = 0.7
        case .viaduct: baseValue = 0.6
        case .tunnel: baseValue = 0.8
        case .smallPort: baseValue = 1.5
        case .mediumPort: baseValue = 2.0
        case .largePort: baseValue = 3.0
        case .containerPort: baseValue = 2.5
        case .oilPort: baseValue = 3.5
        case .smallWarehouse: baseValue = 0.2
        case .mediumWarehouse: baseValue = 0.4
        case .largeWarehouse: baseValue = 0.6
        case .distributionCenter: baseValue = 1.0
        case .coldStorage: baseValue = 0.5
        case .silo: baseValue = 0.3
        case .electricitySubstation: baseValue = 1.2
        case .electricityGrid: baseValue = 1.5
        case .waterTreatment: baseValue = 1.0
        case .waterReservoir: baseValue = 0.8
        case .waterPumpingStation: baseValue = 0.6
        case .communicationHub: baseValue = 0.9
        case .internetExchange: baseValue = 1.1
        case .fireStation: baseValue = 2.0
        case .policeStation: baseValue = 1.8
        case .ambulanceStation: baseValue = 2.2
        case .library: baseValue = 0.5
        case .communityCenter: baseValue = 0.7
        case .factory: baseValue = 1.5
        case .manufacturingPlant: baseValue = 2.0
        case .refinery: baseValue = 3.0
        case .chemicalPlant: baseValue = 2.5
        case .miningOperation: baseValue = 1.8
        case .grainElevator: baseValue = 0.8
        case .feedMill: baseValue = 0.6
        case .processingPlant: baseValue = 1.0
        case .greenhouses: baseValue = 1.2
        default: baseValue = 0.3
        }
        
        // Scale by traffic volume (normalized)
        let trafficFactor = min(1.0, traffic / 10000) // Normalize at 10,000 vehicles/day
        return baseValue * trafficFactor * 1000 // Scale to currency units
    }
    
    private func calculateLinkEconomicValue(_ type: InfrastructureType, freight: Double) -> Double {
        let baseValue: Double
        switch type {
        case .mainRailway: baseValue = 1.5
        case .branchLine: baseValue = 0.8
        case .freightRailway: baseValue = 1.2
        case .smallPort: baseValue = 2.0
        case .mediumPort: baseValue = 2.5
        case .largePort: baseValue = 3.5
        case .containerPort: baseValue = 3.0
        case .oilPort: baseValue = 4.0
        case .smallWarehouse: baseValue = 0.3
        case .mediumWarehouse: baseValue = 0.5
        case .largeWarehouse: baseValue = 0.8
        case .distributionCenter: baseValue = 1.2
        case .silo: baseValue = 0.5
        case .factory: baseValue = 1.5
        case .manufacturingPlant: baseValue = 2.0
        case .refinery: baseValue = 3.5
        case .chemicalPlant: baseValue = 3.0
        case .miningOperation: baseValue = 2.0
        case .grainElevator: baseValue = 0.8
        case .feedMill: baseValue = 0.6
        case .processingPlant: baseValue = 1.0
        default: baseValue = 0.3
        }
        
        let freightFactor = min(1.0, freight / 50000) // Normalize at 50,000 tonnes/day
        return baseValue * freightFactor * 500
    }
    
    private func calculateUtilityEconomicValue(_ type: InfrastructureType, usage: Double) -> Double {
        let baseValue: Double
        switch type {
        case .electricitySubstation: baseValue = 2.0
        case .electricityGrid: baseValue = 2.5
        case .waterTreatment: baseValue = 1.5
        case .waterReservoir: baseValue = 1.0
        case .waterPumpingStation: baseValue = 0.8
        case .communicationHub: baseValue = 1.2
        case .internetExchange: baseValue = 1.3
        default: baseValue = 0.5
        }
        
        let usageFactor = min(1.0, usage / 10000) // Normalize
        return baseValue * usageFactor * 200
    }
    
    // MARK: - Maintenance Management
    
    /// Schedule maintenance for infrastructure node
    public func scheduleMaintenance(_ nodeId: String, maintenanceDate: Date, maintenanceType: MaintenanceType, priority: MaintenancePriority) {
        var schedule = maintenanceSchedule[nodeId] ?? []
        schedule.append(maintenanceDate)
        maintenanceSchedule[nodeId] = schedule.sorted()
        
        #warning("Apply maintenance effects: improve condition rating, reduce deterioration rate")
        #warning("TODO: Update node condition, repair costs, capacity")
    }
    
    /// Perform maintenance on infrastructure node
    public func performMaintenance(_ nodeId: String, maintenanceDate: Date) -> MaintenanceResult {
        guard var node = nodes[nodeId] else {
            return MaintenanceResult(success: false, message: "Node not found")
        }
        
        #warning("Apply maintenance effects to node condition")
        #warning("Improve condition rating, reduce deterioration, update capacities")
        #warning("Calculate repair costs and economic impact")
        
        // Example: improve condition by 10-30% depending on maintenance type
        let conditionImprovement = MaintenanceConditionImprovement[maintenanceType] ?? 0.1
        node.condition.conditionRating = improveConditionRating(node.condition.conditionRating, improvement: conditionImprovement)
        node.condition.maintenance = min(100, node.condition.maintenance + 20) // Increase maintenance score
        node.condition.lastMaintenance = maintenanceDate
        
        // Reduce deterioration rate temporarily
        // node.deteriorationRate *= 0.8
        
        // Update repair costs
        let repairCost = calculateRepairCost(node.type)
        totalDeferredMaintenance -= repairCost
        
        nodes[nodeId] = node
        
        return MaintenanceResult(
            success: true,
            message: "Maintenance performed successfully on \(node.type.rawValue)",
            repairCost: repairCost,
            conditionImprovement: conditionImprovement,
            nodesAffected: 1
        )
    }
    
    private func improveConditionRating(_ current: String, improvement: Double) -> String {
        let ratings: [String: Int] = [
            "critical": 1, "poor": 2, "fair": 3, "good": 4, "excellent": 5
        ]
        
        var currentValue = ratings[current] ?? 3
        let newValue = min(5, max(1, currentValue + Int(improvement * 2))))
        
        // Convert back to string
        return Array(ratings.keys.sorted { ratings[$0]! < ratings[$1]! }[newValue - 1])
    }
    
    private func calculateRepairCost(_ type: InfrastructureType) -> Double {
        let baseCosts: [InfrastructureType: Double] = [
            .highway: 1000000, .primaryRoad: 500000, .secondaryRoad: 300000, .tertiaryRoad: 100000, .alley: 50000,
            .mainRailway: 5000000, .branchLine: 2000000, .lightRail: 3000000, .subway: 20000000, .freightRailway: 4000000,
            .smallBridge: 200000, .mediumBridge: 500000, .largeBridge: 1000000, .viaduct: 800000, .tunnel: 3000000,
            .smallPort: 1000000, .mediumPort: 3000000, .largePort: 10000000, .containerPort: 5000000, .oilPort: 15000000,
            .smallWarehouse: 100000, .mediumWarehouse: 300000, .largeWarehouse: 800000, .distributionCenter: 1000000, .coldStorage: 500000, .silo: 200000,
            .electricitySubstation: 800000, .electricityGrid: 10000000, .waterTreatment: 3000000, .waterReservoir: 1000000, .waterPumpingStation: 500000,
            .communicationHub: 500000, .internetExchange: 2000000,
            .fireStation: 1000000, .policeStation: 800000, .ambulanceStation: 600000, .library: 300000, .communityCenter: 400000,
            .factory: 2000000, .manufacturingPlant: 5000000, .refinery: 15000000, .chemicalPlant: 8000000, .miningOperation: 5000000,
            .grainElevator: 300000, .feedMill: 200000, .processingPlant: 500000, .greenhouses: 1000000,
            .airport: 50000000, .seaport: 20000000, .intermodalTerminal: 3000000
        ]
        
        return baseCosts[type] ?? 100000
    }
    
    // MARK: - Network Analysis
    
    /// Calculate network-wide metrics
    public func calculateNetworkMetrics() -> NetworkMetrics {
        let nodeCount = nodes.count
        let connectedCount = connectivityGraph.values.reduce(0) { $0 + $1.count }
        let averageConnections = nodeCount > 0 ? Double(connectedCount) / Double(nodeCount) / 2 : 0 // Divide by 2 for bidirectional
        
        // Calculate average condition
        var totalConditionValue: Double = 0
        var conditionCount = 0
        
        for node in nodes.values {
            let ratingValue: Double
            switch node.condition.conditionRating {
            case "excellent": ratingValue = 5
            case "good": ratingValue = 4
            case "fair": ratingValue = 3
            case "poor": ratingValue = 2
            case "critical": ratingValue = 1
            default: ratingValue = 3
            }
            totalConditionValue += ratingValue
            conditionCount += 1
        }
        
        let avgCondition = conditionCount > 0 ? totalConditionValue / Double(conditionCount) : 3
        let avgConditionNormalized = avgCondition / 5.0 // 0-1 scale
        
        // Calculate utilization
        let totalCapacity = nodes.values.reduce(0) { $0 + $1.capacity }
        let totalThroughput = nodes.values.reduce(0) { $0 + $1.currentThroughput }
        let utilizationRate = totalCapacity > 0 ? totalThroughput / totalCapacity : 0
        
        // Calculate economic activity
        let economicActivity = calculateEconomicActivity()
        
        // Count by type
        var typeCounts: [InfrastructureType: Int] = [:]
        for type in InfrastructureType.allCases {
            typeCounts[type] = 0
        }
        for node in nodes.values {
            typeCounts[node.type] = (typeCounts[node.type] ?? 0) + 1
        }
        
        return NetworkMetrics(
            totalNodes: nodeCount,
            connectedNodes: connectedCount,
            averageConnectionsPerNode: averageConnections,
            averageConditionRating: avgConditionNormalized,
            utilizationRate: utilizationRate,
            dailyEconomicActivity: economicActivity,
            totalDeferredMaintenance: totalDeferredMaintenance,
            typeCounts: typeCounts,
            networkDensity: averageConnections / (nodeCount - 1) * 2 // Density 0-1
        )
    }
    
    // MARK: - Public API for Network Analysis
    
    /// Get comprehensive network summary
    public func getNetworkSummary() -> NetworkSummary {
        let metrics = calculateNetworkMetrics()
        let summary = getInfrastructureSummary()
        
        return NetworkSummary(
            totalNodes: metrics.totalNodes,
            byType: metrics.typeCounts,
            overallCondition: conditionRatingFromNormalized(metrics.averageConditionRating),
            totalRepairCosts: totalDeferredMaintenance,
            utilizationRate: metrics.utilizationRate,
            dailyEconomicActivity: metrics.dailyEconomicActivity,
            networkDensity: metrics.networkDensity,
            averageConnections: metrics.averageConnectionsPerNode,
            connectedNodes: metrics.connectedNodes,
            activeEvents: getActiveEventCount()
        )
    }
    
    private func conditionRatingFromNormalized(_ normalized: Double) -> String {
        switch normalized {
        case 0.8...1.0: return "excellent"
        case 0.6..<0.8: return "good"
        case 0.4..<0.6: return "fair"
        case 0.2..<0.4: return "poor"
        default: return "critical"
        }
    }
    
    private func getActiveEventCount() -> Int {
        // Placeholder: would integrate with event system
        return 0
    }
}

// MARK: - Supporting Types

// Infrastructure link type enum
public enum InfrastructureLinkType: String, CaseIterable {
    case roadRailwayBridge = "road_railway_bridge"
    case roadPort = "road_port"
    case roadWarehouse = "road_warehouse"
    case railwayBridge = "railway_bridge"
    case portWarehouse = "port_warehouse"
    case utilityConnection = "utility_connection"
    case publicServiceAccess = "public_service_access"
    case industrialSupply = "industrial_supply"
    case agriculturalDistribution = "agricultural_distribution"
}

// Maintenance type enum
public enum MaintenanceType: String, CaseIterable {
    case routine = "routine"
    case preventive = "preventive"
    case corrective = "corrective"
    case emergency = "emergency"
    case majorOverhaul = "major_overhaul"
    case inspection = "inspection"
    case upgrade = "upgrade"
    case replacement = "replacement"
    
    // Maintenance effectiveness by infrastructure type
    var effectivenessByType: [InfrastructureType: Double] {
        [:] // Would be initialized with type-specific effectiveness rates
    }
}

// Maintenance priority enum
public enum MaintenancePriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// Maintenance result struct
public struct MaintenanceResult {
    public let success: Bool
    public let message: String
    public let repairCost: Double
    public let conditionImprovement: Double
    public let nodesAffected: Int
    
    public init(success: Bool, message: String, repairCost: Double = 0, conditionImprovement: Double = 0, nodesAffected: Int = 0) {
        self.success = success
        self.message = message
        self.repairCost = repairCost
        self.conditionImprovement = conditionImprovement
        self.nodesAffected = nodesAffected
    }
}

// Network metrics struct
public struct NetworkMetrics {
    public let totalNodes: Int
    let connectedNodes: Int
    let averageConnectionsPerNode: Double
    let averageConditionRating: Double // 0-1, 1 = excellent
    let utilizationRate: Double // 0-1
    let dailyEconomicActivity: Double
    let totalDeferredMaintenance: Double
    let typeCounts: [InfrastructureType: Int]
    let networkDensity: Double // 0-1
}

// Network summary struct for public API
public struct NetworkSummary {
    public let totalNodes: Int
    public let byType: [InfrastructureType: Int]
    public let overallCondition: String
    public let totalRepairCosts: Double
    public let utilizationRate: Double
    let dailyEconomicActivity: Double
    let networkDensity: Double
    let averageConnections: Double
    let connectedNodes: Int
    let activeEvents: Int
    
    public init(totalNodes: Int, byType: [InfrastructureType: Int], overallCondition: String, totalRepairCosts: Double, utilizationRate: Double, dailyEconomicActivity: Double, networkDensity: Double, averageConnections: Double, connectedNodes: Int, activeEvents: Int) {
        self.totalNodes = totalNodes
        self.byType = byType
        self.overallCondition = overallCondition
        self.totalRepairCosts = totalRepairCosts
        self.utilizationRate = utilizationRate
        self.dailyEconomicActivity = dailyEconomicActivity
        self.networkDensity = networkDensity
        self.averageConnections = averageConnections
        self.connectedNodes = connectedNodes
        self.activeEvents = activeEvents
    }
}

// Infrastructure node class (expanded)
public class InfrastructureNode {
    public let id: String
    public let type: InfrastructureType
    public var location: (x: Double, y: Double)
    public var condition: InfrastructureCondition
    public var connectedNodes: [String]
    public var capacity: Double
    public var currentThroughput: Double
    public var constructionStatus: String
    
    // Type-specific properties
    var roadProperties: RoadProperties?
    var railwayProperties: RailwayProperties?
    var bridgeProperties: BridgeProperties?
    var portProperties: PortProperties?
    var warehouseProperties: WarehouseProperties?
    var electricitySubstationProperties: ElectricitySubstationProperties?
    var waterTreatmentProperties: WaterTreatmentProperties?
    
    // Economic tracking
    var dailyTraffic: Double = 0
    var dailyFreight: Double = 0
    var utilityUsage: Double = 0
    
    // Maintenance tracking
    var lastMaintenance: Date
    var nextScheduledMaintenance: Date
    var deferredMaintenance: Double = 0
    
    // Lifecycle
    var yearBuilt: Int
    var expectedLifespan: Int // years
    var lastInspection: Date
    
    public init(
        id: String,
        type: InfrastructureType,
        location: (x: Double, y: Double),
        condition: InfrastructureCondition,
        connectedNodes: [String] = [],
        capacity: Double = 100,
        currentThroughput: Double = 0,
        constructionStatus: String = "complete",
        yearBuilt: Int = Calendar.current.component(.year, from: Date),
        expectedLifespan: Int = 50
    ) {
        self.id = id
        self.type = type
        self.location = location
        self.condition = condition
        self.connectedNodes = connectedNodes
        self.capacity = capacity
        self.currentThroughput = currentThroughput
        self.constructionStatus = constructionStatus
        self.yearBuilt = yearBuilt
        self.expectedLifespan = expectedLifespan
        self.lastInspection = Date()
        
        // Initialize type-specific properties
        initializeTypeSpecificProperties()
    }
    
    private func initializeTypeSpecificProperties() {
        // Set default properties based on infrastructure type
        // This would be expanded with type-specific initialization
        switch type {
        case .highway, .primaryRoad, .secondaryRoad, .tertiaryRoad, .alley:
            roadProperties = RoadProperties()
        case .mainRailway, .branchLine, .lightRail, .subway, .freightRailway:
            railwayProperties = RailwayProperties()
        case .smallBridge, .mediumBridge, .largeBridge, .viaduct, .tunnel:
            bridgeProperties = BridgeProperties()
        case .smallPort, .mediumPort, .largePort, .containerPort, .oilPort:
            portProperties = PortProperties()
        case .smallWarehouse, .mediumWarehouse, .largeWarehouse, .distributionCenter, .coldStorage, .silo:
            warehouseProperties = WarehouseProperties()
        case .electricitySubstation, .electricityGrid:
            electricitySubstationProperties = ElectricitySubstationProperties()
        case .waterTreatment, .waterReservoir, .waterPumpingStation:
            waterTreatmentProperties = WaterTreatmentProperties()
        default: break
        }
    }
    
    /// Get type-specific properties with safe casting
    public func getProperties<T>(_ type: T.Type) -> T? {
        // Swift type-based retrieval of associated properties
        // This is a simplified version; a full implementation would use generics properly
        nil
    }
    
    /// Update throughput based on connected network flow
    public func updateThroughput(fromNetwork totalThroughput: Double, systemCapacity: Double) {
        // Distribute network throughput across this node
        let distributionFactor = capacity / max(1, totalThroughput)
        currentThroughput = min(capacity, totalThroughput * distributionFactor)
    }
    
    /// Get economic impact contribution
    public func economicImpactContribution() -> Double {
        // Base contribution from infrastructure type
        let base: Double
        switch type {
        case .highway: base = 5000
        case .primaryRoad: base = 3000
        case .secondaryRoad: base = 2000
        case .tertiaryRoad: base = 1000
        case .alley: base = 200
        case .mainRailway: base = 10000
        case .branchLine: base = 5000
        case .lightRail: base = 7000
        case .subway: base = 15000
        case .freightRailway: base = 8000
        case .smallBridge: base = 1500
        case .mediumBridge: base = 3000
        case .largeBridge: base = 5000
        case .viaduct: base = 4000
        case .tunnel: base = 8000
        case .smallPort: base = 5000
        case .mediumPort: base = 8000
        case .largePort: base = 15000
        case .containerPort: base = 10000
        case .oilPort: base = 20000
        case .smallWarehouse: base = 500
        case .mediumWarehouse: base = 1000
        case .largeWarehouse: base = 2000
        case .distributionCenter: base = 3000
        case .coldStorage: base = 800
        case .silo: base = 600
        case .electricitySubstation: base = 2000
        case .electricityGrid: base = 5000
        case .waterTreatment: base = 1500
        case .waterReservoir: base = 1000
        case .waterPumpingStation: base = 600
        case .communicationHub: base = 1500
        case .internetExchange: base = 2000
        case .fireStation: base = 3000
        case .policeStation: base = 2500
        case .ambulanceStation: base = 3500
        case .library: base = 500
        case .communityCenter: base = 800
        case .factory: base = 5000
        case .manufacturingPlant: base = 8000
        case .refinery: base = 20000
        case .chemicalPlant: base = 10000
        case .miningOperation: base = 6000
        case .grainElevator: base = 800
        case .feedMill: base = 500
        case .processingPlant: base = 1200
        case .greenhouses: base = 1000
        default: base = 200
        }
        
        // Modify based on condition
        let conditionFactor: Double
        switch condition.conditionRating {
        case "excellent": conditionFactor = 1.2
        case "good": conditionFactor = 1.0
        case "fair": conditionFactor = 0.8
        case "poor": conditionFactor = 0.5
        case "critical": conditionFactor = 0.2
        default: conditionFactor = 1.0
        }
        
        // Modify based on capacity utilization
        let utilizationFactor = 1 - min(0.5, currentThroughput / capacity) // Better at lower utilization
        
        return base * conditionFactor * utilizationFactor
    }
}

// Infrastructure condition struct (expanded)
public struct InfrastructureCondition {
    public var capacityUtilization: Double = 0 // 0-1, how much of capacity is used
    public var reliability: Double = 1 // 0-1, uptime/availability
    public var maintenanceScore: Double = 80 // 0-100, maintenance quality
    public var conditionRating: String = "good" // excellent, good, fair, poor, critical
    public var lastMaintenance: Date
    public var repairCosts: Double = 0
    public var deteriorationRate: Double = 0.01 // Per year
    public var expectedRemainingLife: Double // Years
    public var safetyCompliance: Double = 1 // 0-1, compliance with safety standards
    public var environmentalImpact: Double = 0.5 // 0-1, environmental impact score
    
    public init(
        capacityUtilization: Double = 0,
        reliability: Double = 1,
        maintenanceScore: Double = 80,
        conditionRating: String = "good",
        lastMaintenance: Date = Date(),
        repairCosts: Double = 0,
        deteriorationRate: Double = 0.01,
        expectedRemainingLife: Double = 50,
        safetyCompliance: Double = 1,
        environmentalImpact: Double = 0.5
    ) {
        self.capacityUtilization = capacityUtilization
        self.reliability = reliability
        self.maintenanceScore = maintenanceScore
        self.conditionRating = conditionRating
        self.lastMaintenance = lastMaintenance
        self.repairCosts = repairCosts
        self.deteriorationRate = deteriorationRate
        self.expectedRemainingLife = expectedRemainingLife
        self.safetyCompliance = safetyCompliance
        self.environmentalImpact = environmentalImpact
    }
    
    // Calculate overall health score
    var healthScore: Double {
        let conditionWeight: Double = 0.4
        let reliabilityWeight: Double = 0.3
        let maintenanceWeight: Double = 0.2
        let safetyWeight: Double = 0.1
        
        let conditionScore = switch conditionRating {
        case "excellent": 1.0
        case "good": 0.8
        case "fair": 0.6
        case "poor": 0.3
        case "critical": 0.1
        default: 0.6
        }
        
        return (conditionScore * conditionWeight) + (reliability * reliabilityWeight) + (maintenanceScore / 100 * maintenanceWeight) + (safetyCompliance * safetyWeight)
    }
    
    // Determine if node is functioning adequately
    var isFunctional: Bool {
        reliability > 0.5 && conditionRating != "critical" && safetyCompliance > 0.5
    }
    
    // Determine if maintenance is urgent
    var isMaintenanceUrgent: Bool {
        conditionRating == "critical" || reliability < 0.3 || maintenanceScore < 30
    }
}

// Helper extensions for InfrastructureType
extension InfrastructureType {
    var isRoad: Bool {
        switch self {
        case .highway, .primaryRoad, .secondaryRoad, .tertiaryRoad, .alley: return true
        default: return false
        }
    }
    
    var isRailway: Bool {
        switch self {
        case .mainRailway, .branchLine, .lightRail, .subway, .freightRailway: return true
        default: return false
        }
    }
    
    var isBridge: Bool {
        switch self {
        case .smallBridge, .mediumBridge, .largeBridge, .viaduct, .tunnel: return true
        default: return false
        }
    }
    
    var isPort: Bool {
        switch self {
        case .smallPort, .mediumPort, .largePort, .containerPort, .oilPort: return true
        default: return false
        }
    }
    
    var isWarehouse: Bool {
        switch self {
        case .smallWarehouse, .mediumWarehouse, .largeWarehouse, .distributionCenter, .coldStorage, .silo: return true
        default: return false
        }
    }
    
    var isUtility: Bool {
        switch self {
        case .electricitySubstation, .electricityGrid, .waterTreatment, .waterReservoir, .waterPumpingStation, .communicationHub, .internetExchange: return true
        default: return false
        }
    }
    
    var isPublicService: Bool {
        switch self {
        case .fireStation, .policeStation, .ambulanceStation, .library, .communityCenter: return true
        default: return false
        }
    }
    
    var isIndustrial: Bool {
        switch self {
        case .factory, .manufacturingPlant, .refinery, .chemicalPlant, .miningOperation: return true
        default: return false
        }
    }
    
    var isAgricultural: Bool {
        switch self {
        case .grainElevator, .feedMill, .processingPlant, .greenhouses: return true
        default: return false
        }
    }
}

// Swift 5.8+ Concurrency support (if available)
// These would be optional and conditional on Swift version
/*
 @MainActor
 func updateThroughputAsync(_ totalThroughput: Double, systemCapacity: Double) async {
     await InfrastructureLogistics().updateThroughput(fromNetwork: totalThroughput, systemCapacity: systemCapacity)
 }
 
 func calculateNetworkMetricsAsync() async -> NetworkMetrics {
     await InfrastructureLogistics().calculateNetworkMetrics()
 }
 */

// Debugging support
extension InfrastructureLogistics {
    var debugDescription: String {
        "InfrastructureLogistics: \(nodes.count) nodes, \(connectivityGraph.count) connections, " +
        "\( dailyTrafficCounts.count) traffic counts, \( freightFlows.count) freight flows"
    }
}

// MARK: - Previews and Debugging (iOS/macOS)

//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//struct InfrastructureLogisticsPreview: PreviewProvider {
//    static var previews: some View {
//        // Would display network graph, condition ratings, economic activity
//        Text("Infrastructure Logistics System Preview")
//    }
// }
//#endif