/**
 * Infrastructure and Logistics - System 18
 * 
 * Roads, railways, bridges, ports, warehouses, utilities networks,
 * infrastructure performance and logistics management.
 */

// Infrastructure type enum
export enum InfrastructureType {
  ROAD = "road",
  RAILWAY = "railway",
  BRIDGE = "bridge",
  PORT = "port",
  WAREHOUSE = "warehouse",
  ELECTRICITY_NETWORK = "electricity_network",
  WATER_SYSTEM = "water_system",
  INTERNET_ACCESS = "internet_access",
  PUBLIC_TRANSPORT = "public_transport",
  HOSPITAL = "hospital",
  SCHOOL = "school"
}

// Infrastructure condition
export interface InfrastructureCondition {
  capacity: number; // 0-100, design capacity utilization
  reliability: number; // 0-1, uptime percentage
  maintenance: number; // 0-100, last maintenance quality
  conditionRating: 'excellent' | 'good' | 'fair' | 'poor' | 'critical';
  lastMaintenance: number;
  repairCosts: CurrencyAmount;
}

// Infrastructure node
export interface InfrastructureNode {
  id: string;
  type: InfrastructureType;
  location: { x: number; y: number };
  condition: InfrastructureCondition;
  connectedNodes: string[]; // IDs of connected nodes
  capacity: number; // maximum throughput
  currentThroughput: number; // current usage
  constructionStatus: 'planned' | 'building' | 'complete' | 'decommissioned';
}

// Road-specific properties
export interface RoadProperties {
  lanes: number;
  speedLimit: number; // km/h
  trafficVolume: number; // vehicles per day
  congestionLevel: number; // 0-100
  surfaceCondition: 'excellent' | 'good' | 'fair' | 'poor';
  lastResurfaced: number;
}

// Railway-specific properties
export interface RailwayProperties {
  tracks: number;
  speedLimit: number; // km/h
  freightVolume: number; // tonne-km per day
  passengerVolume: number; // passengers per day
  congestionLevel: number; // 0-100
  lastInspected: number;
}

// Port-specific properties
export interface PortProperties {
  berths: number;
  cargoVolume: number; // tonnes per day
  containerCount: number; // TEUs
  turnaroundTime: number; // hours
  depth: number; // metres
}

// Warehouse-specific properties
export interface WarehouseProperties {
  storageCapacity: number; // cubic metres
  currentStorage: number; // cubic metres
  handlingEquipment: string[];
  temperatureControlled: boolean;
  loadingDocks: number;
}

// Main infrastructure class
export class InfrastructureLogistics {
  private nodes: Map<string, InfrastructureNode> = new Map();
  private readonly infrastructureTypes: InfrastructureType[] = [
    InfrastructureType.ROAD,
    InfrastructureType.RAILWAY,
    InfrastructureType.BRIDGE,
    InfrastructureType.PORT,
    InfrastructureType.WAREHOUSE,
    InfrastructureType.ELECTRICITY_NETWORK,
    InfrastructureType.WATER_SYSTEM,
    InfrastructureType.INTERNET_ACCESS,
    InfrastructureType.PUBLIC_TRANSPORT,
    InfrastructureType.HOSPITAL,
    InfrastructureType.SCHOOL
  ];

  constructor() {
    # Initialize with basic infrastructure network
    this.initializeBaseInfrastructure();
  }

  # Initialize base infrastructure
  private initializeBaseInfrastructure(): void {
    # Create a simple grid-based road network
    const gridSize = 20;

    # Create roads forming a grid
    for (let x = 0; x <= gridSize; x++) {
      # Horizontal road
      const roadId = `road-h-${x}`;
      this.addNode(roadId, InfrastructureType.ROAD, x * 50, 0, gridSize * 50);

      # Vertical road
      const verticalId = `road-v-${x}`;
      this.addNode(verticalId, InfrastructureType.ROAD, 0, x * 50, gridSize * 50);
    }

    # Add some key cities with enhanced infrastructure
    this.addNode(`city-hub-1`, InfrastructureType.HOSPITAL, 100, 100, 10);
    this.addNode(`city-hub-2`, InfrastructureType.HOSPITAL, 300, 300, 15);
    this.addNode(`port-main`, InfrastructureType.PORT, 500, 500, 20);
    this.addNode(`rail-main`, InfrastructureType.RAILWAY, 150, 200, 30);

    # Add schools and hospitals in grid pattern
    for (let i = 1; i < gridSize; i += 5) {
      for (let j = 1; j < gridSize; j += 5) {
        this.addNode(
          `school-${i}-${j}`,
          InfrastructureType.SCHOOL,
          i * 50,
          j * 50,
          5
        );
        this.addNode(
          `hospital-${i}-${j}`,
          InfrastructureType.HOSPITAL,
          i * 50 + 10,
          j * 50 + 10,
          8
        );
      }
    }

    # Add warehouses near cities
    this.addNode(`warehouse-1`, InfrastructureType.WAREHOUSE, 120, 120, 50);
    this.addNode(`warehouse-2`, InfrastructureType.WAREHOUSE, 320, 320, 60);
  }

  /**
   * Add an infrastructure node
   */
  addNode(
    id: string,
    type: InfrastructureType,
    x: number,
    y: number,
    baseCapacity: number
  ): InfrastructureNode {
    const node: InfrastructureNode = {
      id,
      type,
      location: { x, y },
      condition: {
        capacity: baseCapacity,
        reliability: 0.9,
        maintenance: 80,
        conditionRating: 'good',
        lastMaintenance: Date.now(),
        repairCosts: 0
      },
      connectedNodes: [],
      capacity: baseCapacity,
      currentThroughput: 0,
      constructionStatus: 'complete'
    };

    this.nodes.set(id, node);
    return node;
  }

  /**
   * Get infrastructure node by ID
   */
  getNode(id: string): InfrastructureNode | undefined {
    return this.nodes.get(id);
  }

  /**
   * Get all infrastructure nodes
   */
  getAllNodes(): InfrastructureNode[] {
    return Array.from(this.nodes.values());
  }

  /**
   * Get nodes by type
   */
  getNodesByType(type: InfrastructureType): InfrastructureNode[] {
    return Array.from(this.nodes.values()).filter(n => n.type === type);
  }

  /**
   * Connect two nodes
   */
  connectNodes(nodeId1: string, nodeId2: string): boolean {
    const node1 = this.nodes.get(nodeId1);
    const node2 = this.nodes.get(nodeId2);

    if (!node1 || !node2) return false;

    # Add bidirectional connection
    if (!node1.connectedNodes.includes(nodeId2)) {
      node1.connectedNodes.push(nodeId2);
    }
    if (!node2.connectedNodes.includes(nodeId1)) {
      node2.connectedNodes.push(nodeId1);
    }

    this.nodes.set(nodeId1, node1);
    this.nodes.set(nodeId2, node2);

    # Update conditions based on connection
    this.updateNodeConditions([nodeId1, nodeId2]);

    return true;
  }

  # Update node conditions based on maintenance and usage
  private updateNodeConditions(updatedNodeIds: string[]): void {
    for (const id of updatedNodeIds) {
      const node = this.nodes.get(id);
      if (!node) continue;

      const { condition, constructionStatus } = node;

      # Maintenance improves condition slightly
      const maintenanceFactor = condition.maintenance / 100 * 0.1;
      const newReliability = Math.min(1, condition.reliability + maintenanceFactor);

      # Wear from usage (current throughput vs capacity)
      const utilization = node.currentThroughput / Math.max(1, node.capacity);
      const wear = utilization * 0.05; # 5% wear per update at full capacity

      const newConditionRating: 'excellent' | 'good' | 'fair' | 'poor' | 'critical' =
        utilization > 0.9
          ? 'poor'
          : utilization > 0.7
            ? condition.conditionRating === 'excellent'
              ? 'good'
              : condition.conditionRating
            : condition.conditionRating;

      # Repair improves condition
      const repairFactor = (100 - condition.maintenance) * 0.01;
      const newMaintenance = Math.min(100, condition.maintenance + repairFactor * 10);

      # Update condition
      node.condition = {
        ...node.condition,
        reliability: newReliability,
        conditionRating: newConditionRating,
        maintenance: newMaintenance,
        lastMaintenance: Date.now(),
        repairCosts: node.condition.repairCosts + Math.random() * 100
      };

      this.nodes.set(id, node);
    }
  }

  /**
   * Update infrastructure usage based on economic activity
   */
  updateUsage(economicActivity: {
    productionLevel: number;
    consumptionLevel: number;
    tradeVolume: number;
  }): void {
    # Distribute usage across infrastructure network
    const nodes = Array.from(this.nodes.values());

    for (const node of nodes) {
      # Base usage proportional to economic activity
      const baseUsage = (economicActivity.productionLevel + economicActivity.consumptionLevel) / 2 / 100;

      # Different types have different usage patterns
      switch (node.type) {
        case InfrastructureType.ROAD:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * 50);
          break;
        case InfrastructureType.RAILWAY:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * 20);
          break;
        case InfrastructureType.PORT:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * economicActivity.tradeVolume * 5);
          break;
        case InfrastructureType.WAREHOUSE:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * 30);
          break;
        case InfrastructureType.ELECTRICITY_NETWORK:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * 40);
          break;
        case InfrastructureType.WATER_SYSTEM:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * 35);
          break;
        case InfrastructureType.PUBLIC_TRANSPORT:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * 25);
          break;
        default:
          node.currentThroughput = Math.min(node.capacity, node.currentThroughput + baseUsage * 10);
      }

      # Gradual condition degradation from use
      const utilization = node.currentThroughput / Math.max(1, node.capacity);
      if (utilization > 0.5) {
        # Reduce maintenance effectiveness slightly with high usage
        const newMaintenance = Math.max(0, node.condition.maintenance - 0.5);
        node.condition.maintenance = newMaintenance;
      }
    }
  }

  /**
   * Maintain infrastructure (repair, upgrade)
   */
  maintainInfrastructure(nodeId: string, maintenanceLevel: number): boolean {
    const node = this.nodes.get(nodeId);
    if (!node) return false;

    # Maintenance improves condition
    const maintenanceEffect = maintenanceLevel * 5; # 5 points per level
    const newMaintenance = Math.min(100, node.condition.maintenance + maintenanceEffect);

    # Improve condition rating based on maintenance
    let newRating: 'excellent' | 'good' | 'fair' | 'poor' | 'critical' = node.condition.conditionRating;

    if (newMaintenance >= 90) {
      newRating = 'excellent';
    } else if (newMaintenance >= 70) {
      newRating = 'good';
    } else if (newMaintenance >= 50) {
      newRating = 'fair';
    } else if (newMaintenance >= 30) {
      newRating = 'poor';
    } else {
      newRating = 'critical';
    }

    # Reduce repair costs if was in poor condition
    let costReduction = 0;
    if (node.condition.conditionRating === 'critical') {
      costReduction = 20; # Fixing critical is expensive but reduces future costs
    }

    node.condition = {
      ...node.condition,
      maintenance: newMaintenance,
      conditionRating: newRating,
      repairCosts: Math.max(0, node.condition.repairCosts - costReduction),
      lastMaintenance: Date.now()
    };

    this.nodes.set(nodeId, node);
    return true;
  }

  /**
   * Get infrastructure summary
   */
  getInfrastructureSummary(): {
    totalNodes: number;
    byType: Map<InfrastructureType, number>;
    overallCondition: 'excellent' | 'good' | 'fair' | 'poor' | 'critical';
    totalRepairCosts: CurrencyAmount;
    utilizationRate: number;
  } {
    const byType = new Map<InfrastructureType, number>();
    let totalRepairCosts = 0;
    let totalConditionScore = 0;
    let totalCapacity = 0;
    let totalThroughput = 0;

    for (const node of this.nodes.values()) {
      byType.set(node.type, (byType.get(node.type) || 0) + 1);
      totalRepairCosts += node.condition.repairCosts;

      # Condition score: excellent=5, good=4, fair=3, poor=2, critical=1
      const ratingScores: Record<string, number> = {
        excellent: 5,
        good: 4,
        fair: 3,
        poor: 2,
        critical: 1
      };
      totalConditionScore += (ratingScores[node.condition.conditionRating] || 3) * 20;

      totalCapacity += node.capacity;
      totalThroughput += node.currentThroughput;
    }

    const avgConditionScore = totalNodes > 0 ? totalConditionScore / this.nodes.size / 100 : 50;
    let overallCondition: 'excellent' | 'good' | 'fair' | 'poor' | 'critical';
    if (avgConditionScore >= 4.5) overallCondition = 'excellent';
    else if (avgConditionScore >= 3.5) overallCondition = 'good';
    else if (avgConditionScore >= 2.5) overallCondition = 'fair';
    else if (avgConditionScore >= 1.5) overallCondition = 'poor';
    else overallCondition = 'critical';

    const utilizationRate = totalCapacity > 0 ? totalThroughput / totalCapacity : 0;

    return {
      totalNodes: this.nodes.size,
      byType,
      overallCondition,
      totalRepairCosts,
      utilizationRate
    };
  }

  /**
   * Get node condition display
   */
  getNodeCondition(nodeId: string): {
    capacity: number;
    reliability: number;
    maintenance: number;
    conditionRating: string;
    lastMaintenance: number;
    repairCosts: CurrencyAmount;
    currentThroughput: number;
    capacity: number;
  } | undefined {
    const node = this.nodes.get(nodeId);
    if (!node) return undefined;

    return {
      capacity: node.capacity,
      reliability: node.condition.reliability,
      maintenance: node.condition.maintenance,
      conditionRating: node.condition.conditionRating,
      lastMaintenance: node.condition.lastMaintenance,
      repairCosts: node.condition.repairCosts,
      currentThroughput: node.currentThroughput
    };
  }
}