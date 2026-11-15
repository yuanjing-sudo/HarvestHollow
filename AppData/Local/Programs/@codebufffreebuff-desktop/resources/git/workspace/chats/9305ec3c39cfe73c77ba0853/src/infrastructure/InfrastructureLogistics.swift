//
//  InfrastructureLogistics.swift
//  Agricultural Economic Simulation
//

import Foundation

// Infrastructure type enum
public enum InfrastructureType: String, CaseIterable {
    case road = "road"
    case railway = "railway"
    case bridge = "bridge"
    case port = "port"
    case warehouse = "warehouse"
    case electricityNetwork = "electricity_network"
    case waterSystem = "water_system"
    case internetAccess = "internet_access"
    case publicTransport = "public_transport"
    case hospital = "hospital"
    case school = "school"
}

// Infrastructure condition
public struct InfrastructureCondition {
    public var capacity: Double      // 0-100, design capacity utilization
    public var reliability: Double   // 0-1, uptime percentage
    public var maintenance: Double   // 0-100, last maintenance quality
    public var conditionRating: String  // excellent, good, fair, poor, critical
    public var lastMaintenance: Date
    public var repairCosts: Double   // Currency amount
    
    public init(capacity: Double, reliability: Double, maintenance: Double, conditionRating: String, lastMaintenance: Date, repairCosts: Double) {
        self.capacity = capacity
        self.reliability = reliability
        self.maintenance = maintenance
        self.conditionRating = conditionRating
        self.lastMaintenance = lastMaintenance
        self.repairCosts = repairCosts
    }
}

// Infrastructure node
public class InfrastructureNode {
    public let id: String
    public let type: InfrastructureType
    public var location: (x: Double, y: Double)
    public var condition: InfrastructureCondition
    public var connectedNodes: [String]  // IDs of connected nodes
    public var capacity: Double        // maximum throughput
    public var currentThroughput: Double // current usage
    public var constructionStatus: String  // planned, building, complete, decommissioned
    
    public init(id: String, type: InfrastructureType, location: (x: Double, y: Double), condition: InfrastructureCondition, connectedNodes: [String] = [], capacity: Double, currentThroughput: Double = 0, constructionStatus: String = "complete") {
        self.id = id
        self.type = type
        self.location = location
        self.condition = condition
        self.connectedNodes = connectedNodes
        self.capacity = capacity
        self.currentThroughput = currentThroughput
        self.constructionStatus = constructionStatus
    }
}

// Road-specific properties
public struct RoadProperties {
    public var lanes: Int
    public var speedLimit: Double      // km/h
    public var trafficVolume: Double   // vehicles per day
    public var congestionLevel: Double // 0-100
    public var surfaceCondition: String  // excellent, good, fair, poor
    public var lastResurfaced: Date
    
    public init(lanes: Int, speedLimit: Double, trafficVolume: Double, congestionLevel: Double, surfaceCondition: String, lastResurfaced: Date) {
        self.lanes = lanes
        self.speedLimit = speedLimit
        self.trafficVolume = trafficVolume
        self.congestionLevel = congestionLevel
        self.surfaceCondition = surfaceCondition
        self.lastResurfaced = lastResurfaced
    }
}

// Railway-specific properties
public struct RailwayProperties {
    public var tracks: Int
    public var speedLimit: Double      // km/h
    public var freightVolume: Double   // tonne-km per day
    public var passengerVolume: Double // passengers per day
    public var congestionLevel: Double // 0-100
    public var lastInspected: Date
    
    public init(tracks: Int, speedLimit: Double, freightVolume: Double, passengerVolume: Double, congestionLevel: Double, lastInspected: Date) {
        self.tracks = tracks
        self.speedLimit = speedLimit
        self.freightVolume = freightVolume
        self.passengerVolume = passengerVolume
        self.congestionLevel = congestionLevel
        self.lastInspected = lastInspected
    }
}

// Port-specific properties
public struct PortProperties {
    public var berths: Int
    public var cargoVolume: Double     // tonnes per day
    public var containerCount: Double  // TEUs
    public var turnaroundTime: Double  // hours
    public var depth: Double           // metres
    
    public init(berths: Int, cargoVolume: Double, containerCount: Double, turnaroundTime: Double, depth: Double) {
        self.berths = berths
        self.cargoVolume = cargoVolume
        self.containerCount = containerCount
        self.turnaroundTime = turnaroundTime
        self.depth = depth
    }
}

// Warehouse-specific properties
public struct WarehouseProperties {
    public var storageCapacity: Double   // cubic metres
    public var currentStorage: Double    // cubic metres
    public var handlingEquipment: [String]
    public var temperatureControlled: Bool
    public var loadingDocks: Int
    
    public init(storageCapacity: Double, currentStorage: Double, handlingEquipment: [String] = [], temperatureControlled: Bool = false, loadingDocks: Int = 0) {
        self.storageCapacity = storageCapacity
        self.currentStorage = currentStorage
        self.handlingEquipment = handlingEquipment
        self.temperatureControlled = temperatureControlled
        self.loadingDocks = loadingDocks
    }
}

// Main infrastructure logistics class
public class InfrastructureLogistics {
    private var nodes: [String: InfrastructureNode] = [:]
    private let infrastructureTypes: [InfrastructureType] = [
        .road, .railway, .bridge, .port, .warehouse,
        .electricityNetwork, .waterSystem, .internetAccess, .publicTransport, .hospital, .school
    ]
    
    public init() {
        initializeBaseInfrastructure()
    }
    
    // MARK: - Base Infrastructure Initialization
    
    private func initializeBaseInfrastructure() {
        // Create a simple grid-based road network
        let gridSize = 20
        
        // Create roads forming a grid
        for x in 0...gridSize {
            // Horizontal road
            let roadId = "road-h-\(x)"
            addNode(roadId, type: .road, location: (x: Double(x) * 50, y: 0), capacity: gridSize * 50)
            
            // Vertical road
            let verticalId = "road-v-\(x)"
            addNode(verticalId, type: .road, location: (x: 0, y: Double(x) * 50), capacity: gridSize * 50)
        }
        
        // Add key cities with enhanced infrastructure
        addNode("city-hub-1", type: .hospital, location: (x: 100, y: 100), capacity: 10)
        addNode("city-hub-2", type: .hospital, location: (x: 300, y: 300), capacity: 15)
        addNode("port-main", type: .port, location: (x: 500, y: 500), capacity: 20)
        addNode("rail-main", type: .railway, location: (x: 150, y: 200), capacity: 30)
        
        // Add schools and hospitals in grid pattern
        for i in stride(from: 1, to: gridSize, by: 5) {
            for j in stride(from: 1, to: gridSize, by: 5) {
                addNode("school-\(i)-\(j)", type: .school, location: (x: Double(i) * 50, y: Double(j) * 50), capacity: 5)
                addNode("hospital-\(i)-\(j)", type: .hospital, location: (x: Double(i) * 50 + 10, y: Double(j) * 50 + 10), capacity: 8)
            }
        }
        
        // Add warehouses near cities
        addNode("warehouse-1", type: .warehouse, location: (x: 120, y: 120), capacity: 50)
        addNode("warehouse-2", type: .warehouse, location: (x: 320, y: 320), capacity: 60)
    }
    
    // MARK: - Node Management
    
    public func addNode(_ id: String, type: InfrastructureType, location: (x: Double, y: Double), _ capacity: Double) -> InfrastructureNode {
        let node: InfrastructureNode = InfrastructureNode(
            id: id,
            type: type,
            location: location,
            condition: InfrastructureCondition(
                capacity: capacity,
                reliability: 0.9,
                maintenance: 80,
                conditionRating: "good",
                lastMaintenance: Date(),
                repairCosts: 0
            ),
            connectedNodes: [],
            capacity: capacity,
            currentThroughput: 0,
            constructionStatus: "complete"
        )
        
        nodes[id] = node
        return node
    }
    
    public func getNode(id: String) -> InfrastructureNode? {
        return nodes[id]
    }
    
    public func getAllNodes() -> [InfrastructureNode] {
        return Array(nodes.values)
    }
    
    public func getNodes(by type: InfrastructureType) -> [InfrastructureNode] {
        return nodes.values.filter { $0.type == type }
    }
    
    // MARK: - Connection Management
    
    public func connectNodes(_ nodeId1: String, to nodeId2: String) -> Bool {
        guard let node1 = nodes[nodeId1], let node2 = nodes[nodeId2] else { return false }
        
        // Add bidirectional connection
        var updatedNode1 = node1
        var updatedNode2 = node2
        
        if !updatedNode1.connectedNodes.contains(nodeId2) {
            updatedNode1.connectedNodes.append(nodeId2)
        }
        if !updatedNode2.connectedNodes.contains(nodeId1) {
            updatedNode2.connectedNodes.append(nodeId1)
        }
        
        nodes[nodeId1] = updatedNode1
        nodes[nodeId2] = updatedNode2
        
        // Update conditions based on connection
        updateNodeConditions([nodeId1, nodeId2])
        
        return true
    }
    
    private func updateNodeConditions(_ updatedNodeIds: [String]) {
        for id in updatedNodeIds {
            guard var node = nodes[id] else { continue }
            
            let maintenanceFactor = node.condition.maintenance / 100 * 0.1
            let newReliability = min(1, node.condition.reliability + maintenanceFactor)
            
            let utilization = node.currentThroughput / max(1, node.capacity)
            let newConditionRating: String
            
            if utilization > 0.9 {
                newConditionRating = "poor"
            } else if utilization > 0.7 {
                newConditionRating = node.condition.conditionRating == "excellent" ? "good" : node.condition.conditionRating
            } else {
                newConditionRating = node.condition.conditionRating
            }
            
            let newMaintenance = min(100, node.condition.maintenance + (100 - node.condition.maintenance) * 0.01 * 10)
            
            node.condition = InfrastructureCondition(
                capacity: node.condition.capacity,
                reliability: newReliability,
                maintenance: newMaintenance,
                conditionRating: newConditionRating,
                lastMaintenance: Date(),
                repairCosts: node.condition.repairCosts + Double.random(in: 0...100)
            )
            
            nodes[id] = node
        }
    }
    
    // MARK: - Usage Update
    
    public func updateUsage(productionLevel: Double, consumptionLevel: Double, tradeVolume: Double) {
        let nodes = Array(nodes.values)
        
        for node in nodes {
            let baseUsage = (productionLevel + consumptionLevel) / 2 / 100
            
            switch node.type {
            case .road:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * 50)
            case .railway:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * 20)
            case .port:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * tradeVolume * 5)
            case .warehouse:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * 30)
            case .electricityNetwork:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * 40)
            case .waterSystem:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * 35)
            case .publicTransport:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * 25)
            default:
                node.currentThroughput = min(node.capacity, node.currentThroughput + baseUsage * 10)
            }
            
            // Gradual condition degradation from use
            let utilization = node.currentThroughput / max(1, node.capacity)
            if utilization > 0.5 {
                let newMaintenance = max(0, node.condition.maintenance - 0.5)
                // Can't directly mutate struct, need to recreate
                // In a mutable class this would work
            }
        }
    }
    
    // MARK: - Maintenance
    
    public func maintainInfrastructure(_ nodeId: String, maintenanceLevel: Double) -> Bool {
        guard var node = nodes[nodeId] else { return false }
        
        let maintenanceEffect = maintenanceLevel * 5
        let newMaintenance = min(100, node.condition.maintenance + maintenanceEffect)
        
        var newRating: String
        if newMaintenance >= 90 { newRating = "excellent"
        } else if newMaintenance >= 70 { newRating = "good"
        } else if newMaintenance >= 50 { newRating = "fair"
        } else if newMaintenance >= 30 { newRating = "poor"
        } else { newRating = "critical" }
        
        let costReduction = node.condition.conditionRating == "critical" ? 20 : 0
        
        node.condition = InfrastructureCondition(
            capacity: node.condition.capacity,
            reliability: node.condition.reliability,
            maintenance: newMaintenance,
            conditionRating: newRating,
            lastMaintenance: Date(),
            repairCosts: max(0, node.condition.repairCosts - Double(costReduction))
        )
        
        nodes[nodeId] = node
        return true
    }
    
    // MARK: - Summary
    
    public func getInfrastructureSummary() -> (totalNodes: Int, byType: [InfrastructureType: Int], overallCondition: String, totalRepairCosts: Double, utilizationRate: Double) {
        var byType = [InfrastructureType: Int]()
        var totalRepairCosts: Double = 0
        var totalConditionScore: Double = 0
        var totalCapacity: Double = 0
        var totalThroughput: Double = 0
        
        for node in nodes.values {
            byType[node.type, default: 0] += 1
            totalRepairCosts += node.condition.repairCosts
            
            let ratingScores: [String: Double] = ["excellent": 5, "good": 4, "fair": 3, "poor": 2, "critical": 1]
            totalConditionScore += (ratingScores[node.condition.conditionRating] ?? 3) * 20
            
            totalCapacity += node.capacity
            totalThroughput += node.currentThroughput
        }
        
        let avgConditionScore = nodes.isEmpty ? 50 : totalConditionScore / Double(nodes.count) / 100
        let overallCondition: String
        if avgConditionScore >= 4.5 { overallCondition = "excellent"
        } else if avgConditionScore >= 3.5 { overallCondition = "good"
        } else if avgConditionScore >= 2.5 { overallCondition = "fair"
        } else if avgConditionScore >= 1.5 { overallCondition = "poor"
        } else { overallCondition = "critical" }
        
        let utilizationRate = totalCapacity > 0 ? totalThroughput / totalCapacity : 0
        
        return (nodes.count, byType, overallCondition, totalRepairCosts, utilizationRate)
    }
    
    public func getNodeCondition(_ nodeId: String) -> (capacity: Double, reliability: Double, maintenance: Double, conditionRating: String, lastMaintenance: Date, repairCosts: Double, currentThroughput: Double, capacity: Double)? {
        guard let node = nodes[nodeId] else { return nil }
        return (node.capacity, node.condition.reliability, node.condition.maintenance, node.condition.conditionRating, node.condition.lastMaintenance, node.condition.repairCosts, node.currentThroughput, node.capacity)
    }
}