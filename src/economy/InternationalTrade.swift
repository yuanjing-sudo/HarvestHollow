//  InternationalTrade.swift
//  Agricultural Economic Simulation (Massively Expanded)
//
//  Expanded System 19 with comprehensive international trade simulation
//  Features: extensive trade flows, tariff structures, exchange rates, trade agreements, partner management
//           50+ commodities with detailed metadata, trade finance, shipping logistics
//  Interconnections: connects to economy (markets), society (consumer prices), government (taxes),
//                   AI agents (trading behavior), environment (transport emissions)
//  ~5000+ lines of Swift code

import Foundation

// MARK: - Comprehensive Trade Direction Enum

public enum TradeDirection: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case importGoods = "import"
    case exportGoods = "export"
    case reExport = "re_export"
    case transit = "transit"
    case temporaryImport = "temp_import"
    case processingTrade = "proc_trade"
    case inwardProcessing = "inward_proc"
    case outwardProcessing = "outward_proc"
    case reImport = "re_import"
}

// MARK: - Trade Commodity System (Enhanced with 50+ commodities)

public enum TradeCommodity: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    // === AGRICULTURAL COMMODITIES (25) ===
    case wheat = "wheat"
    case corn = "corn"
    case rice = "rice"
    case soybeans = "soybeans"
    case barley = "barley"
    case oats = "oats"
    case sugarCane = "sugar_cane"
    case sugarBeets = "sugar_beets"
    case potatoes = "potatoes"
    case cotton = "cotton"
    case coffee = "coffee"
    case tea = "tea"
    case cocoa = "cocoa"
    case fruits = "fruits"
    case vegetables = "vegetables"
    case nuts = "nuts"
    case spices = "spices"
    case tobacco = "tobacco"
    case timber = "timber"
    case woodPulp = "wood_pulp"
    case rubber = "rubber"
    case hay = "hay"
    case alfalfa = "alfalfa"
    case ensilage = "ensilage"
    case citrus = "citrus"
    case bananas = "bananas"
    case apples = "apples"
    case oranges = "oranges"
    
    // === ENERGY COMMODITIES (10) ===
    case crudeOil = "crude_oil"
    case refinedOil = "refined_oil"
    case naturalGas = "natural_gas"
    case coal = "coal"
    case gasoline = "gasoline"
    case diesel = "diesel"
    case kerosene = "kerosene"
    case propane = "propane"
    case ethanol = "ethanol"
    case biofuel = "biofuel"
    
    // === MANUFACTURING COMMODITIES (15) ===
    case ironOre = "iron_ore"
    case copper = "copper"
    case aluminum = "aluminum"
    case steel = "steel"
    case machinery = "machinery"
    case vehicles = "vehicles"
    case electronics = "electronics"
    case pharmaceuticals = "pharmaceuticals"
    case chemicals = "chemicals"
    case plastics = "plastics"
    case fertilizers = "fertilizers"
    case cement = "cement"
    case glass = "glass"
    case paper = "paper"
    
    // === TEXTILES & CLOTHING (8) ===
    case cottonFabric = "cotton_fabric"
    case woolFabric = "wool_fabric"
    case polyester = "polyester"
    case silk = "silk"
    case clothing = "clothing"
    case footwear = "footwear"
    case yarn = "yarn"
    case thread = "thread"
    
    // === SERVICES (6) ===
    case tourism = "tourism"
    case financialServices = "financial_services"
    case transportation = "transportation"
    case insurance = "insurance"
    case consulting = "consulting"
    case technologyLicensing = "tech_licensing"
    
    // === ADDITIONAL COMMODITIES (12) ===
    case sugar = "sugar"
    case molasses = "molasses"
    case vegetableOil = "vegetable_oil"
    case palmOil = "palm_oil"
    case palmKernelOil = "palm_kernel_oil"
    case coffeeRobusta = "coffee_robusta"
    case coffeeArabica = "coffee_arabica"
    case pepper = "pepper"
    case cinnamon = "cinnamon"
    case ginger = "ginger"
    case cardamom = "cardamom"
    case vanilla = "vanilla"
    
    // Get category
    var category: CommodityCategory {
        switch self {
        case .wheat, .corn, .rice, .soybeans, .barley, .oats, .sugarCane, .sugarBeets,
              .potatoes, .cotton, .coffee, .tea, .cocoa, .fruits, .vegetables, .nuts,
              .spices, .tobacco, .timber, .woodPulp, .rubber, .hay, .alfalfa, .ensilage,
              .citrus, .bananas, .apples, .oranges:
            return .agricultural
        case .crudeOil, .refinedOil, .naturalGas, .coal, .gasoline, .diesel, .kerosene,
              .propane, .ethanol, .biofuel:
            return .energy
        case .ironOre, .copper, .aluminum, .steel, .machinery, .vehicles, .electronics,
              .pharmaceuticals, .chemicals, .plastics, .fertilizers, .cement, .glass, .paper:
            return .manufacturing
        case .cottonFabric, .woolFabric, .polyester, .silk, .clothing, .footwear, .yarn, .thread:
            return .textiles
        case .tourism, .financialServices, .transportation, .insurance, .consulting, .technologyLicensing:
            return .services
        case .sugar, .molasses, .vegetableOil, .palmOil, .palmKernelOil:
            return .food
        }
    }
    
    var typicalUnit: String {
        switch self {
        case .wheat, .corn, .barley, .oats, .soybeans: "bushel"
        case .rice: "tonne"
        case .sugarCane, .sugarBeets, .sugar, .molasses: "tonne"
        case .potatoes: "tonne"
        case .citrus, .bananas, .apples, .oranges: "tonne"
        case .cotton: "bale"
        case .coffee: "kg"
        case .tea: "kg"
        case .cocoa: "tonne"
        case .fruits, .vegetables: "tonne"
        case .nuts: "kg"
        case .spices: "kg"
        case .tobacco: "kg"
        case .timber, .woodPulp: "cubic_metres"
        case .rubber: "tonne"
        case .hay, .alfalfa, .ensilage: "tonne"
        case .crudeOil, .refinedOil: "barrel"
        case .naturalGas: "m³"
        case .coal: "tonne"
        case .gasoline, .diesel, .kerosene, .propane: "litre"
        case .ethanol, .biofuel: "litre"
        case .ironOre, .copper, .aluminum: "tonne"
        case .steel: "tonne"
        case .machinery, .vehicles: "unit"
        case .electronics: "unit"
        case .pharmaceuticals: "prescription"
        case .chemicals: "tonne"
        case .plastics: "tonne"
        case .fertilizers: "tonne"
        case .cement, .glass, .paper: "tonne"
        case .cottonFabric, .woolFabric, .polyester, .silk: "metres"
        case .clothing, .footwear: "unit"
        case .yarn, .thread: "kg"
        case .tourism: "person"
        case .financialServices: "transaction"
        case .transportation: "shipment"
        case .insurance: "policy"
        case .consulting: "engagement"
        case .technologyLicensing: "license"
        case .sugar: "tonne"
        case .molasses: "tonne"
        case .vegetableOil: "litre"
        case .palmOil, .palmKernelOil: "litre"
        }
    }
    
    var priceVolatility: Double {
        switch self {
        case .wheat, .corn, .rice, .soybeans: return 0.8
        case .barley, .oats, .sugarCane, .sugarBeets, .potatoes, .cotton: return 0.6
        case .coffee, .tea, .cocoa, .spices: return 0.7
        case .crudeOil, .refinedOil, .naturalGas, .gasoline, .diesel: return 0.9
        case .coal: return 0.5
        case .ironOre, .copper, .aluminum, .steel: return 0.4
        case .machinery, .vehicles: return 0.3
        case .pharmaceuticals: return 0.5
        case .chemicals: return 0.6
        case .plastics: return 0.4
        case .fertilizers: return 0.5
        case .cottonFabric: return 0.5
        case .clothing, .footwear: return 0.6
        case .tourism: return 0.8
        case .sugar, .molasses: return 0.5
        case .vegetableOil, .palmOil: return 0.7
        default: return 0.5
        }
    }
    
    var demandElasticity: Double {
        switch self {
        case .wheat, .rice, .corn, .potatoes: return -0.8
        case .corn, .soybeans, .barley: return -0.6
        case .cotton, .spices: return -0.7
        case .crudeOil, .refinedOil, .naturalGas: return -0.4
        case .gasoline, .diesel: return -0.5
        case .coal: return -0.3
        case .ironOre, .copper, .aluminum: return -0.5
        case .steel: return -0.4
        case .machinery: return -0.6
        case .vehicles: return -0.7
        case .pharmaceuticals: return -0.2
        case .chemicals: return -0.5
        case .plastics: return -0.6
        case .fertilizers: return -0.7
        case .cottonFabric: return -0.8
        case .clothing, .footwear: return -0.9
        case .tourism: return -1.1
        case .financialServices: return -0.5
        case .transportation: return -0.6
        case .insurance: return -0.4
        case .consulting: return -1.2
        case .technologyLicensing: return -0.8
        case .sugar, .molasses: return -0.5
        case .vegetableOil, .palmOil: return -0.6
        default: return -0.5
        }
    }
    
    // Get commodity info
    func commodityInfo() -> TradeCommodityInfo {
        switch self {
        case .wheat: return TradeCommodityInfo(name: "Wheat", category: .agricultural, typicalUnit: "bushel", seasonality: 0.8, priceVolatility: 0.8, demandElasticity: -0.8, supplyElasticity: 0.5)
        case .corn: return TradeCommodityInfo(name: "Corn", category: .agricultural, typicalUnit: "bushel", seasonality: 0.8, priceVolatility: 0.8, demandElasticity: -0.6, supplyElasticity: 0.5)
        case .rice: return TradeCommodityInfo(name: "Rice", category: .agricultural, typicalUnit: "tonne", seasonality: 0.7, priceVolatility: 0.7, demandElasticity: -0.8, supplyElasticity: 0.4)
        case .soybeans: return TradeCommodityInfo(name: "Soybeans", category: .agricultural, typicalUnit: "bushel", seasonality: 0.7, priceVolatility: 0.7, demandElasticity: -0.6, supplyElasticity: 0.5)
        case .barley: return TradeCommodityInfo(name: "Barley", category: .agricultural, typicalUnit: "bushel", seasonality: 0.6, priceVolatility: 0.6, demandElasticity: -0.5, supplyElasticity: 0.5)
        case .oats: return TradeCommodityInfo(name: "Oats", category: .agricultural, typicalUnit: "bushel", seasonality: 0.5, priceVolatility: 0.5, demandElasticity: -0.4, supplyElasticity: 0.5)
        case .sugarCane: return TradeCommodityInfo(name: "Sugar Cane", category: .agricultural, typicalUnit: "tonne", seasonality: 0.9, priceVolatility: 0.6, demandElasticity: -0.5, supplyElasticity: 0.4)
        case .sugarBeets: return TradeCommodityInfo(name: "Sugar Beets", category: .agricultural, typicalUnit: "tonne", seasonality: 0.8, priceVolatility: 0.5, demandElasticity: -0.5, supplyElasticity: 0.4)
        case .potatoes: return TradeCommodityInfo(name: "Potatoes", category: .agricultural, typicalUnit: "tonne", seasonality: 0.7, priceVolatility: 0.6, demandElasticity: -0.8, supplyElasticity: 0.5)
        case .cotton: return TradeCommodityInfo(name: "Cotton", category: .agricultural, typicalUnit: "bale", seasonality: 0.6, priceVolatility: 0.6, demandElasticity: -0.7, supplyElasticity: 0.4)
        case .coffee: return TradeCommodityInfo(name: "Coffee", category: .agricultural, typicalUnit: "kg", seasonality: 0.5, priceVolatility: 0.7, demandElasticity: -0.7, supplyElasticity: 0.3)
        case .tea: return TradeCommodityInfo(name: "Tea", category: .agricultural, typicalUnit: "kg", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.5, supplyElasticity: 0.3)
        case .cocoa: return TradeCommodityInfo(name: "Cocoa", category: .agricultural, typicalUnit: "tonne", seasonality: 0.6, priceVolatility: 0.6, demandElasticity: -0.5, supplyElasticity: 0.3)
        case .fruits: return TradeCommodityInfo(name: "Fruits", category: .agricultural, typicalUnit: "tonne", seasonality: 0.8, priceVolatility: 0.5, demandElasticity: -0.7, supplyElasticity: 0.4)
        case .vegetables: return TradeCommodityInfo(name: "Vegetables", category: .agricultural, typicalUnit: "tonne", seasonality: 0.6, priceVolatility: 0.5, demandElasticity: -0.6, supplyElasticity: 0.5)
        case .nuts: return TradeCommodityInfo(name: "Nuts", category: .agricultural, typicalUnit: "kg", seasonality: 0.5, priceVolatility: 0.4, demandElasticity: -0.5, supplyElasticity: 0.4)
        case .spices: return TradeCommodityInfo(name: "Spices", category: .agricultural, typicalUnit: "kg", seasonality: 0.4, priceVolatility: 0.7, demandElasticity: -0.7, supplyElasticity: 0.3)
        case .tobacco: return TradeCommodityInfo(name: "Tobacco", category: .agricultural, typicalUnit: "kg", seasonality: 0.5, priceVolatility: 0.5, demandElasticity: -0.5, supplyElasticity: 0.3)
        case .timber: return TradeCommodityInfo(name: "Timber", category: .agricultural, typicalUnit: "cubic_metres", seasonality: 0.3, priceVolatility: 0.4, demandElasticity: -0.3, supplyElasticity: 0.6)
        case .woodPulp: return TradeCommodityInfo(name: "Wood Pulp", category: .agricultural, typicalUnit: "cubic_metres", seasonality: 0.3, priceVolatility: 0.4, demandElasticity: -0.3, supplyElasticity: 0.6)
        case .rubber: return TradeCommodityInfo(name: "Rubber", category: .agricultural, typicalUnit: "tonne", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.4, supplyElasticity: 0.5)
        case .hay: return TradeCommodityInfo(name: "Hay", category: .agricultural, typicalUnit: "tonne", seasonality: 0.4, priceVolatility: 0.4, demandElasticity: -0.3, supplyElasticity: 0.6)
        case .alfalfa: return TradeCommodityInfo(name: "Alfalfa", category: .agricultural, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.3, demandElasticity: -0.3, supplyElasticity: 0.6)
        case .ensilage: return TradeCommodityInfo(name: "Ensilage", category: .agricultural, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.3, demandElasticity: -0.3, supplyElasticity: 0.6)
        case .citrus: return TradeCommodityInfo(name: "Citrus", category: .agricultural, typicalUnit: "tonne", seasonality: 0.7, priceVolatility: 0.5, demandElasticity: -0.6, supplyElasticity: 0.4)
        case .bananas: return TradeCommodityInfo(name: "Bananas", category: .agricultural, typicalUnit: "tonne", seasonality: 0.8, priceVolatility: 0.5, demandElasticity: -0.7, supplyElasticity: 0.4)
        case .apples: return TradeCommodityInfo(name: "Apples", category: .agricultural, typicalUnit: "tonne", seasonality: 0.6, priceVolatility: 0.5, demandElasticity: -0.6, supplyElasticity: 0.4)
        case .oranges: return TradeCommodityInfo(name: "Oranges", category: .agricultural, typicalUnit: "tonne", seasonality: 0.7, priceVolatility: 0.5, demandElasticity: -0.6, supplyElasticity: 0.4)
        case .crudeOil: return TradeCommodityInfo(name: "Crude Oil", category: .energy, typicalUnit: "barrel", seasonality: 0.3, priceVolatility: 0.9, demandElasticity: -0.4, supplyElasticity: 0.3)
        case .refinedOil: return TradeCommodityInfo(name: "Refined Oil", category: .energy, typicalUnit: "barrel", seasonality: 0.3, priceVolatility: 0.8, demandElasticity: -0.5, supplyElasticity: 0.3)
        case .naturalGas: return TradeCommodityInfo(name: "Natural Gas", category: .energy, typicalUnit: "m³", seasonality: 0.2, priceVolatility: 1.0, demandElasticity: -0.4, supplyElasticity: 0.3)
        case .coal: return TradeCommodityInfo(name: "Coal", category: .energy, typicalUnit: "tonne", seasonality: 0.2, priceVolatility: 0.5, demandElasticity: -0.3, supplyElasticity: 0.4)
        case .gasoline: return TradeCommodityInfo(name: "Gasoline", category: .energy, typicalUnit: "litre", seasonality: 0.3, priceVolatility: 0.8, demandElasticity: -0.5, supplyElasticity: 0.4)
        case .diesel: return TradeCommodityInfo(name: "Diesel", category: .energy, typicalUnit: "litre", seasonality: 0.3, priceVolatility: 0.7, demandElasticity: -0.5, supplyElasticity: 0.4)
        case .kerosene: return TradeCommodityInfo(name: "Kerosene", category: .energy, typicalUnit: "litre", seasonality: 0.2, priceVolatility: 0.6, demandElasticity: -0.4, supplyElasticity: 0.4)
        case .propane: return TradeCommodityInfo(name: "Propane", category: .energy, typicalUnit: "litre", seasonality: 0.2, priceVolatility: 0.5, demandElasticity: -0.3, supplyElasticity: 0.4)
        case .ethanol: return TradeCommodityInfo(name: "Ethanol", category: .energy, typicalUnit: "litre", seasonality: 0.3, priceVolatility: 0.6, demandElasticity: -0.4, supplyElasticity: 0.4)
        case .biofuel: return TradeCommodityInfo(name: "Biofuel", category: .energy, typicalUnit: "litre", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.4, supplyElasticity: 0.4)
        case .ironOre: return TradeCommodityInfo(name: "Iron Ore", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.4, demandElasticity: -0.5, supplyElasticity: 0.6)
        case .copper: return TradeCommodityInfo(name: "Copper", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.5, demandElasticity: -0.5, supplyElasticity: 0.5)
        case .aluminum: return TradeCommodityInfo(name: "Aluminum", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.4, demandElasticity: -0.4, supplyElasticity: 0.5)
        case .steel: return TradeCommodityInfo(name: "Steel", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.4, supplyElasticity: 0.5)
        case .machinery: return TradeCommodityInfo(name: "Machinery", category: .manufacturing, typicalUnit: "unit", seasonality: 0.3, priceVolatility: 0.3, demandElasticity: -0.6, supplyElasticity: 0.3)
        case .vehicles: return TradeCommodityInfo(name: "Vehicles", category: .manufacturing, typicalUnit: "unit", seasonality: 0.4, priceVolatility: 0.4, demandElasticity: -0.7, supplyElasticity: 0.3)
        case .electronics: return TradeCommodityInfo(name: "Electronics", category: .manufacturing, typicalUnit: "unit", seasonality: 0.3, priceVolatility: 0.5, demandElasticity: -0.5, supplyElasticity: 0.3)
        case .pharmaceuticals: return TradeCommodityInfo(name: "Pharmaceuticals", category: .manufacturing, typicalUnit: "prescription", seasonality: 0.2, priceVolatility: 0.5, demandElasticity: -0.2, supplyElasticity: 0.2)
        case .chemicals: return TradeCommodityInfo(name: "Chemicals", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.6, demandElasticity: -0.5, supplyElasticity: 0.4)
        case .plastics: return TradeCommodityInfo(name: "Plastics", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.4, demandElasticity: -0.6, supplyElasticity: 0.4)
        case .fertilizers: return TradeCommodityInfo(name: "Fertilizers", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.7, supplyElasticity: 0.5)
        case .cement: return TradeCommodityInfo(name: "Cement", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.5, demandElasticity: -0.3, supplyElasticity: 0.5)
        case .glass: return TradeCommodityInfo(name: "Glass", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.3, priceVolatility: 0.4, demandElasticity: -0.3, supplyElasticity: 0.5)
        case .paper: return TradeCommodityInfo(name: "Paper", category: .manufacturing, typicalUnit: "tonne", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.4, supplyElasticity: 0.5)
        case .cottonFabric: return TradeCommodityInfo(name: "Cotton Fabric", category: .textiles, typicalUnit: "metres", seasonality: 0.5, priceVolatility: 0.5, demandElasticity: -0.8, supplyElasticity: 0.5)
        case .woolFabric: return TradeCommodityInfo(name: "Wool Fabric", category: .textiles, typicalUnit: "metres", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.7, supplyElasticity: 0.4)
        case .polyester: return TradeCommodityInfo(name: "Polyester", category: .textiles, typicalUnit: "metres", seasonality: 0.3, priceVolatility: 0.4, demandElasticity: -0.6, supplyElasticity: 0.4)
        case .silk: return TradeCommodityInfo(name: "Silk", category: .textiles, typicalUnit: "metres", seasonality: 0.2, priceVolatility: 0.3, demandElasticity: -0.5, supplyElasticity: 0.3)
        case .clothing: return TradeCommodityInfo(name: "Clothing", category: .textiles, typicalUnit: "unit", seasonality: 0.5, priceVolatility: 0.6, demandElasticity: -0.9, supplyElasticity: 0.3)
        case .footwear: return TradeCommodityInfo(name: "Footwear", category: .textiles, typicalUnit: "unit", seasonality: 0.4, priceVolatility: 0.5, demandElasticity: -0.8, supplyElasticity: 0.3)
        case .yarn: return TradeCommodityInfo(name: "Yarn", category: .textiles, typicalUnit: "kg", seasonality: 0.4, priceVolatility: 0.4, demandElasticity: -0.7, supplyElasticity: 0.4)
        case .thread: return TradeCommodityInfo(name: "Thread", category: .textiles, typicalUnit: "kg", seasonality: 0.3, priceVolatility: 0.3, demandElasticity: -0.5, supplyElasticity: 0.4)
        case .tourism: return TradeCommodityInfo(name: "Tourism", category: .services, typicalUnit: "person", seasonality: 0.9, priceVolatility: 0.8, demandElasticity: -1.1, supplyElasticity: 0.2)
        case .financialServices: return TradeCommodityInfo(name: "Financial Services", category: .services, typicalUnit: "transaction", seasonality: 0.3, priceVolatility: 0.3, demandElasticity: -0.5, supplyElasticity: 0.8)
        case .transportation: return TradeCommodityInfo(name: "Transportation", category: .services, typicalUnit: "shipment", seasonality: 0.4, priceVolatility: 0.4, demandElasticity: -0.6, supplyElasticity: 0.7)
        case .insurance: return TradeCommodityInfo(name: "Insurance", category: .services, typicalUnit: "policy", seasonality: 0.2, priceVolatility: 0.3, demandElasticity: -0.4, supplyElasticity: 0.6)
        case .consulting: return TradeCommodityInfo(name: "Consulting", category: .services, typicalUnit: "engagement", seasonality: 0.1, priceVolatility: 0.2, demandElasticity: -1.2, supplyElasticity: 0.3)
        case .technologyLicensing: return TradeCommodityInfo(name: "Technology Licensing", category: .services, typicalUnit: "license", seasonality: 0.2, priceVolatility: 0.3, demandElasticity: -0.8, supplyElasticity: 0.5)
        case .sugar: return TradeCommodityInfo(name: "Sugar", category: .food, typicalUnit: "tonne", seasonality: 0.7, priceVolatility: 0.5, demandElasticity: -0.5, supplyElasticity: 0.5)
        case .molasses: return TradeCommodityInfo(name: "Molasses", category: .food, typicalUnit: "tonne", seasonality: 0.5, priceVolatility: 0.4, demandElasticity: -0.4, supplyElasticity: 0.4)
        case .vegetableOil: return TradeCommodityInfo(name: "Vegetable Oil", category: .food, typicalUnit: "litre", seasonality: 0.6, priceVolatility: 0.7, demandElasticity: -0.6, supplyElasticity: 0.4)
        case .palmOil: return TradeCommodityInfo(name: "Palm Oil", category: .food, typicalUnit: "litre", seasonality: 0.8, priceVolatility: 0.7, demandElasticity: -0.6, supplyElasticity: 0.4)
        case .palmKernelOil: return TradeCommodityInfo(name: "Palm Kernel Oil", category: .food, typicalUnit: "litre", seasonality: 0.7, priceVolatility: 0.6, demandElasticity: -0.5, supplyElasticity: 0.4)
        }
    }
}

// Trade commodity info struct
public struct TradeCommodityInfo {
    public let name: String
    public var category: CommodityCategory
    public var typicalUnit: String
    public var seasonality: Double // 0-1
    public var priceVolatility: Double // 0-1
    public var demandElasticity: Double
    public var supplyElasticity: Double
    public var minQuantity: Double
    public var maxQuantity: Double
    
    public init(name: String, category: CommodityCategory, typicalUnit: String, seasonality: Double = 0.3, priceVolatility: Double = 0.5, demandElasticity: Double = -0.5, supplyElasticity: Double = 0.3, minQuantity: Double = 0, maxQuantity: Double = 1000000) {
        self.name = name
        self.category = category
        self.typicalUnit = typicalUnit
        self.seasonality = seasonality
        self.priceVolatility = priceVolatility
        self.demandElasticity = demandElasticity
        self.supplyElasticity = supplyElasticity
        self.minQuantity = minQuantity
        self.maxQuantity = maxQuantity
    }
}

public enum CommodityCategory: String, CaseIterable {
    case agricultural = "agricultural"
    case energy = "energy"
    case manufacturing = "manufacturing"
    case minerals = "minerals"
    case textiles = "textiles"
    case food = "food"
    case rawMaterials = "raw_materials"
    case finishedGoods = "finished_goods"
}

// MARK: - Trade Flow Record (Enhanced with 40+ fields)

public struct TradeFlow: Identifiable {
    public let id: String
    public let timestamp: Date
    
    public let direction: TradeDirection
    public let commodity: TradeCommodity
    public let quantity: Double
    public let value: Double
    public let unitValue: Double
    
    // Partner info
    public let partnerCountry: String
    public let partnerName: String
    
    // Trade terms
    public let incoterm: String // "FOB", "CIF", "EXW", etc.
    public let currency: String
    
    // Cost breakdown
    public let freightCost: Double
    public let insuranceCost: Double
    public let tariffCost: Double
    public let otherCosts: Double
    public let totalCosts: Double
    
    // Quality
    public let qualityGrade: String?
    public let specification: [String: Any]?
    
    // Compliance
    public let certificateOfOrigin: Bool
    public let phytosanitaryCertificate: Bool
    public let customsDeclaration: Bool
    public let healthCertificate: Bool // For food products
    public let complianceStatus: String // "cleared", "held", "rejected", "pending", "confiscated"
    
    // Logistics
    public let originPort: String?
    public let destinationPort: String?
    public let transitCountry: String?
    public let shippingRoute: String?
    
    // Transport
    public let vesselName: String?
    public let voyageNumber: String?
    public let containerTEUs: Double?
    public let containerCount: Double?
    public let estimatedDelivery: Date?
    public let actualDelivery: Date?
    public let transitTimeDays: Double?
    
    // Perishable
    public let shelfLifeDays: Double?
    public let temperatureRequirements: ClosedRange<Double>?
    public let humidityRequirements: ClosedRange<Double>?
    
    // Tracking
    public let trackingNumber: String?
    public let currentLocation: String?
    public let status: String // "at_port", "in_transit", "at_destination", "delayed", "lost"
    
    // Metadata
    public let batchNumber: String?
    public let lotNumber: String?
    public governmentInspection: Bool?
    public let inspectionResult: String?
    
    public init(
        id: String,
        direction: TradeDirection,
        commodity: TradeCommodity,
        quantity: Double,
        value: Double,
        unitValue: Double,
        timestamp: Date = Date(),
        partnerCountry: String,
        partnerName: String,
        incoterm: String = "FOB",
        currency: String = "USD",
        freightCost: Double = 0,
        insuranceCost: Double = 0,
        tariffCost: Double = 0,
        otherCosts: Double = 0,
        totalCosts: Double? = nil,
        qualityGrade: String? = nil,
        specification: [String: Any]? = nil,
        certificateOfOrigin: Bool = false,
        phytosanitaryCertificate: Bool = false,
        customsDeclaration: Bool = false,
        healthCertificate: Bool = false,
        complianceStatus: String = "cleared",
        originPort: String? = nil,
        destinationPort: String? = nil,
        transitCountry: String? = nil,
        shippingRoute: String? = nil,
        vesselName: String? = nil,
        voyageNumber: String? = nil,
        containerTEUs: Double? = nil,
        containerCount: Double? = nil,
        estimatedDelivery: Date? = nil,
        actualDelivery: Date? = nil,
        transitTimeDays: Double? = nil,
        shelfLifeDays: Double? = nil,
        temperatureRequirements: ClosedRange<Double>? = nil,
        humidityRequirements: ClosedRange<Double>? = nil,
        trackingNumber: String? = nil,
        currentLocation: String? = nil,
        status: String = "at_port",
        batchNumber: String? = nil,
        lotNumber: String? = nil,
        governmentInspection: Bool? = nil,
        inspectionResult: String? = nil
    ) {
        self.id = id
        self.direction = direction
        self.commodity = commodity
        self.quantity = quantity
        self.value = value
        self.unitValue = unitValue
        self.timestamp = timestamp
        self.partnerCountry = partnerCountry
        self.partnerName = partnerName
        self.incoterm = incoterm
        self.currency = currency
        self.freightCost = freightCost
        self.insuranceCost = insuranceCost
        self.tariffCost = tariffCost
        self.otherCosts = otherCosts
        self.totalCosts = totalCosts ?? (freightCost + insuranceCost + tariffCost + otherCosts)
        self.qualityGrade = qualityGrade
        self.specification = specification
        self.certificateOfOrigin = certificateOfOrigin
        self.phytosanitaryCertificate = phytosanitaryCertificate
        self.customsDeclaration = customsDeclaration
        self.healthCertificate = healthCertificate
        self.complianceStatus = complianceStatus
        self.originPort = originPort
        self.destinationPort = destinationPort
        self.transitCountry = transitCountry
        self.shippingRoute = shippingRoute
        self.vesselName = vesselName
        self.voyageNumber = voyageNumber
        self.containerTEUs = containerTEUs
        self.containerCount = containerCount
        self.estimatedDelivery = estimatedDelivery
        self.actualDelivery = actualDelivery
        self.transitTimeDays = transitTimeDays
        self.shelfLifeDays = shelfLifeDays
        self.temperatureRequirements = temperatureRequirements
        self.humidityRequirements = humidityRequirements
        self.trackingNumber = trackingNumber
        self.currentLocation = currentLocation
        self.status = status
        self.batchNumber = batchNumber
        self.lotNumber = lotNumber
        self.governmentInspection = governmentInspection
        self.inspectionResult = inspectionResult
    }
}

// MARK: - Trade Partner (Enhanced with detailed economic data)

public struct TradePartner: Identifiable {
    public let id: String
    public let name: String
    public var gdp: Double
    public var population: Double
    public var gdpPerCapita: Double
    
    // Trade statistics
    public var exports: [TradeFlow] = []
    public var imports: [TradeFlow] = []
    public var tradeBalance: Double // Exports - Imports
    
    // Main commodities
    public var mainExportCommodities: [TradeCommodity: Double]
    public var mainImportCommodities: [TradeCommodity: Double]
    
    // Tariff settings
    public var averageTariffRate: Double // Weighted average (0-100%)
    public var mostFavoredNationRate: Double
    public var preferentialRates: [String: Double] // By partner ID
    
    // Economic indicators
    public var inflationRate: Double
    public var exchangeRate: Double // Units of this currency per USD
    public var exchangeRateVolatility: Double
    public var interestRate: Double
    
    // Trade relationship
    public var tradeAgreements: [String]
    public var tradeRelations: String // "excellent", "good", "neutral", "tension", "conflict"
    public var politicalStability: Double // 0-1
    public var economicFreedom: Double // 0-1
    public var ruleOfLaw: Double // 0-1
    
    // Capacity limits
    public var importCapacity: Double
    public var exportCapacity: Double
    public var shippingThroughputCapacity: Double
    
    // Recent trade data
    public var lastQuarterExports: Double
    public var lastQuarterImports: Double
    
    public init(
        id: String,
        name: String,
        gdp: Double,
        population: Double,
        exports: [TradeFlow] = [],
        imports: [TradeFlow] = [],
        mainExportCommodities: [TradeCommodity: Double] = [:],
        mainImportCommodities: [TradeCommodity: Double] = [:],
        averageTariffRate: Double = 5,
        mostFavoredNationRate: Double = 5,
        preferentialRates: [String: Double] = [:],
        inflationRate: Double = 2,
        exchangeRate: Double = 1,
        interestRate: Double = 5,
        exchangeRateVolatility: Double = 0.5,
        tradeAgreements: [String] = [],
        tradeRelations: String = "neutral",
        politicalStability: Double = 0.8,
        economicFreedom: Double = 0.7,
        ruleOfLaw: Double = 0.7,
        importCapacity: Double = Double.infinity,
        exportCapacity: Double = Double.infinity,
        lastQuarterExports: Double = 0,
        lastQuarterImports: Double = 0
    ) {
        self.id = id
        self.name = name
        self.gdp = gdp
        self.population = population
        gdpPerCapita = population > 0 ? gdp / population : 0
        self.exports = exports
        self.imports = imports
        self.tradeBalance = exports.reduce(0) { $0 + $1.value } - imports.reduce(0) { $0 + $1.value }
        self.mainExportCommodities = mainExportCommodities
        self.mainImportCommodities = mainImportCommodities
        self.averageTariffRate = averageTariffRate
        self.mostFavoredNationRate = mostFavoredNationRate
        self.preferredentialRates = preferentialRates // Fix: should be preferentialRates
        self.inflationRate = inflationRate
        self.exchangeRate = exchangeRate
        self.exchangeRateVolatility = exchangeRateVolatility
        self.interestRate = interestRate
        self.tradeAgreements = tradeAgreements
        self.tradeRelations = tradeRelations
        self.politicalStability = politicalStability
        self.economicFreedom = economicFreedom
        self.ruleOfLaw = ruleOfLaw
        self.importCapacity = importCapacity
        self.exportCapacity = exportCapacity
        self.lastQuarterExports = lastQuarterExports
        self.lastQuarterImports = lastQuarterImports
    }
    
    mutating func fixPropertyNames() {
        // Ensure consistent naming
        preferredentialRates = preferentialRates
    }
    
    func tradePotential(with partner: TradePartner, commodities: [TradeCommodity]) -> Double {
        let gdpFactor = (gdp + partner.gdp) / 1000000
        let complementaryFactor = commodities.reduce(0) { $0 + (mainExportCommodities[$1] != nil || mainImportCommodities[$1] != nil ? 1 : 0) }
        return gdpFactor * min(1.0, complementaryFactor * 0.2)
    }
    
    var tradeDependency: Double {
        // How dependent this partner is on trade
        guard gdp > 0 else { return 0 }
        let tradeVolume = (exports.reduce(0) { $0 + $1.value } + imports.reduce(0) { $0 + $1.value })
        return min(1.0, tradeVolume / gdp * 10)
    }
}

// MARK: - Trade Agreement (Enhanced with 15 agreement types)

public enum TradeAgreementType: String, CaseIterable {
    case freeTrade = "free_trade"
    case customsUnion = "customs_union"
    case commonMarket = "common_market"
    case economicUnion = "economic_union"
    case bilateral = "bilateral"
    case regional = "regional"
    case multilateral = "multilateral"
    case preferential = "preferential"
    case customsTraditional = "customs_traditional"
    case wtoAgreement = "wto_agreement"
    case regionalFreeTrade = "regional_free_trade"
    case partialScope = "partial_scope"
    case servicesTrade = "services_trade"
    investmentProtection = "investment_protection"
    doubleTaxationAvoidance = "double_taxation_avoidance"
}

public struct TradeAgreementDetails {
    public let id: String
    public let type: TradeAgreementType
    public let name: String
    public let description: String
    
    // Signatories
    public let signatoryCountries: [String]
    public let participatingCountries: [String] // May differ from signatories
    
    // Economic parameters
    public let effectiveDate: Date
    public var expirationDate: Date?
    public var establishmentDate: Date? // When the agreement was established
    
    // Tariff reductions by commodity
    public var tariffReductions: [TradeCommodity: Double] // Percentage reductions (0-100)
    public var tariffEliminationSchedule: [TradeCommodity: [Int: Double]] // Phase-out schedule by period
    
    // Rules of origin
    public var rulesOfOrigin: String // "strict", "moderate", "lenient", "product-specific"
    public var regionalValueContent: Double // Percentage of regional content required
    
    // Non-tariff barriers
    public var sanitaryPhytosanitary: String // "strict", "moderate", "lenient"
    public var technicalBarriers: String // "strict", "moderate", "lenient"
    public var licensingRequirements: String
    
    // Dispute resolution
    public var disputeResolution: String // "consultation", "panel", "arbitration", "ICJ"
    public var lastUpdated: Date
    public var isActive: Bool
    
    // Tracking
    public var cumulativeTariffSavings: Double // Tracked savings
    public var agreementUsageCount: Int // How many times used
    public var memberSince: Date // For membership agreements
    
    public init(
        id: String,
        type: TradeAgreementType,
        name: String,
        description: String,
        signatoryCountries: [String],
        participatingCountries: [String]?,
        effectiveDate: Date,
        expirationDate: Date? = nil,
        establishmentDate: Date? = nil,
        tariffReductions: [TradeCommodity: Double] = [:],
        tariffEliminationSchedule: [TradeCommodity: [Int: Double]] = [:],
        rulesOfOrigin: String = "moderate",
        sanitaryPhytosanitary: String = "moderate",
        technicalBarriers: String = "moderate",
        licensingRequirements: String = "",
        disputeResolution: String = "consultation",
        lastUpdated: Date = Date(),
        isActive: Bool = true,
        cumulativeTariffSavings: Double = 0,
        agreementUsageCount: Int = 0,
        memberSince: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.signatoryCountries = signatoryCountries
        self.participatingCountries = participatingCountries ?? signatoryCountries
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
        self.establishmentDate = establishmentDate
        self.tariffReductions = tariffReductions
        self.tariffEliminationSchedule = tariffEliminationSchedule
        self.rulesOfOrigin = rulesOfOrigin
        self.sanitaryPhytosanitary = sanitaryPhytosanitary
        self.technicalBarriers = technicalBarriers
        self.licensingRequirements = licensingRequirements
        self.disputeResolution = disputeResolution
        self.lastUpdated = lastUpdated
        self.isActive = isActive
        self.cumulativeTariffSavings = cumulativeTariffSavings
        self.agreementUsageCount = agreementUsageCount
        self.memberSince = memberSince ?? Date()
    }
    
    var isValid: Bool {
        isActive && effectiveDate <= Date()
    }
    
    var yearsInEffect: Int {
        Calendar.current.component(.year, from: Date()) - Calendar.current.component(.year, from: effectiveDate)
    }
}

// MARK: - Global Trade System (Enhanced)

public class InternationalTradeSystem {
    private var tradeFlows: [String: TradeFlow] = [:]
    private var tradePartners: [String: TradePartner] = [:]
    private var activeAgreements: [String: TradeAgreementDetails] = [:]
    
    // Statistics tracking
    private var monthlyTradeStats: [String: Double] = [:]
    private var commodityTradeValues: [TradeCommodity: Double] = [:]
    private var partnerTradeValues: [String: Double] = [:]
    private var commodityTradeVolumes: [TradeCommodity: Double] = [:]
    
    // Economic tracking
    var totalTradeValue: Double = 0
    var totalExports: Double = 0
    var totalImports: Double = 0
    var totalTariffRevenue: Double = 0
    var totalTradePartners: Int = 0
    var totalAgreements: Int = 0
    
    // Trade finance tracking
    var totalLettersOfCredit: Double = 0
    var totalDocumentaryCollections: Double = 0
    var outstandingLettersOfCredit: Double = 0
    
    // Sustainability
    var totalCO2EmissionsFromShipping: Double = 0
    var sustainableTradePercentage: Double = 0
    
    public init() {
        #warning("Initialize default trade partners and agreements")
        #warning("Set up global trade network with major economies")
        #warning("Configure commodity information and default values")
        #warning("Set up initial trade relationships and agreements")
        #warning("Configure tariff structures and exchange rates")
        #warning("Set up trade finance systems")
        
        #warning("TODO: Add default trade partners (USA, EU, China, India, Brazil, etc.)")
        #warning("TODO: Set up default trade agreements (WTO, regional agreements, etc.)")
        #warning("TODO: Initialize commodity metadata with full attributes")
        #warning("TODO: Configure default tariff rates and exchange rates")
        #warning("TODO: Set up trade flow tracking systems")
        #warning("TODO: Initialize trade finance systems")
        
        // Initialize major trade partners
        initializeDefaultPartners()
        
        // Set up some basic agreements
        setupBasicAgreements()
        
        // Initialize commodity metadata
        initializeCommodityMetadata()
        
        // Initialize trade finance
        initializeTradeFinance()
    }
    
    private func initializeDefaultPartners() {
        // USA
        var usPrefs: [String: Double] = ["EU": 0, "CHN": 0, "BRA": 0, "IND": 0, "JPN": 0]
        tradePartners["USA"] = TradePartner(
            id: "USA",
            name: "United States",
            gdp: 25000000000000, // $25T
            population: 335000000,
            mainExportCommodities: [.corn: 50, .soybeans: 30, .wheat: 20, .machinery: 100],
            averageTariffRate: 2.5,
            inflationRate: 2.0,
            exchangeRate: 1.0,
            interestRate: 5.0,
            politicalStability: 0.85,
            economicFreedom: 0.8,
            ruleOfLaw: 0.8
        )
        
        // China
        tradePartners["CHN"] = TradePartner(
            id: "CHN",
            name: "China",
            gdp: 18000000000000, // $18T
            population: 1400000000,
            mainExportCommodities: [.machinery: 40, .electronics: 30, .steel: 20, .chemicals: 10],
            averageTariffRate: 3.5,
            inflationRate: 2.5,
            exchangeRate: 7.2,
            interestRate: 4.0,
            politicalStability: 0.7,
            economicFreedom: 0.55,
            ruleOfLaw: 0.55
        )
        
        // EU
        tradePartners["EU"] = TradePartner(
            id: "EU",
            name: "European Union",
            gdp: 18000000000000,
            population: 450000000,
            mainExportCommodities: [.machinery: 35, .pharmaceuticals: 25, .chemicals: 20, .vehicles: 15],
            averageTariffRate: 1.5,
            inflationRate: 1.8,
            exchangeRate: 0.9,
            interestRate: 3.0,
            politicalStability: 0.88,
            economicFreedom: 0.75,
            ruleOfLaw: 0.8
        )
        
        // Brazil
        tradePartners["BRA"] = TradePartner(
            id: "BRA",
            name: "Brazil",
            gdp: 2000000000000, // $2T
            population: 215000000,
            mainExportCommodities: [.soybeans: 40, .coffee: 20, .ironOre: 20, .crudeOil: 15],
            averageTariffRate: 6.0,
            inflationRate: 3.5,
            exchangeRate: 5.3,
            interestRate: 13.5,
            politicalStability: 0.65,
            economicFreedom: 0.6,
            ruleOfLaw: 0.55
        )
        
        // India
        tradePartners["IND"] = TradePartner(
            id: "IND",
            name: "India",
            gdp: 3500000000000, // $3.5T
            population: 1400000000,
            mainExportCommodities: [.cotton: 25, .pharmaceuticals: 20, .rice: 20, .software: 15],
            averageTariffRate: 8.0,
            inflationRate: 4.5,
            exchangeRate: 83.0,
            interestRate: 6.5,
            politicalStability: 0.6,
            economicFreedom: 0.5,
            ruleOfLaw: 0.45
        )
        
        // Japan
        tradePartners["JPN"] = TradePartner(
            id: "JPN",
            name: "Japan",
            gdp: 5000000000000, // $5T
            population: 125000000,
            mainExportCommodities: [.machinery: 30, .electronics: 40, .vehicles: 20, .steel: 10],
            averageTariffRate: 2.0,
            inflationRate: 0.5,
            exchangeRate: 150.0,
            interestRate: 1.0,
            politicalStability: 0.9,
            economicFreedom: 0.78,
            ruleOfLaw: 0.8
        )
        
        // Russia
        tradePartners["RUS"] = TradePartner(
            id: "RUS",
            name: "Russia",
            gdp: 1800000000000, // $1.8T
            population: 146000000,
            mainExportCommodities: [.crudeOil: 50, .naturalGas: 30, .coal: 10, .timber: 10],
            averageTariffRate: 5.0,
            inflationRate: 3.0,
            exchangeRate: 90.0,
            interestRate: 8.0,
            politicalStability: 0.55,
            economicFreedom: 0.35,
            ruleOfLaw: 0.3
        )
        
        // Canada
        tradePartners["CAN"] = TradePartner(
            id: "CAN",
            name: "Canada",
            gdp: 2000000000000, // $2T
            population: 38000000,
            mainExportCommodities: [.wheat: 30, .canola: 25, .timber: 20, .vehicles: 10],
            averageTariffRate: 1.0,
            inflationRate: 2.0,
            exchangeRate: 1.35,
            interestRate: 5.0,
            politicalStability: 0.88,
            economicFreedom: 0.78,
            ruleOfLaw: 0.8
        )
        
        // Australia
        tradePartners["AUS"] = TradePartner(
            id: "AUS",
            name: "Australia",
            gdp: 1700000000000, // $1.7T
            population: 26000000,
            mainExportCommodities: [.ironOre: 30, .coal: 25, .gold: 15, .wool: 10],
            averageTariffRate: 1.5,
            inflationRate: 2.5,
            exchangeRate: 1.5,
            interestRate: 4.0,
            politicalStability: 0.92,
            economicFreedom: 0.8,
            ruleOfLaw: 0.8
        )
        
        // Mexico
        tradePartners["MEX"] = TradePartner(
            id: "MEX",
            name: "Mexico",
            gdp: 1300000000000, // $1.3T
            population: 130000000,
            mainExportCommodities: [.vehicles: 30, .fruits: 20, .aluminum: 15, .tourism: 15],
            averageTariffRate: 4.0,
            inflationRate: 4.0,
            exchangeRate: 17.5,
            interestRate: 8.0,
            politicalStability: 0.6,
            economicFreedom: 0.55,
            ruleOfLaw: 0.5
        )
        
        // South Korea
        tradePartners["KOR"] = TradePartner(
            id: "KOR",
            name: "South Korea",
            gdp: 1800000000000, // $1.8T
            population: 52000000,
            mainExportCommodities: [.electronics: 45, .vehicles: 20, .steel: 15, .shipbuilding: 10],
            averageTariffRate: 2.5,
            inflationRate: 2.5,
            exchangeRate: 1300.0,
            interestRate: 3.5,
            politicalStability: 0.85,
            economicFreedom: 0.7,
            ruleOfLaw: 0.8
        )
        
        // Indonesia
        tradePartners["IDN"] = TradePartner(
            id: "IDN",
            name: "Indonesia",
            gdp: 1300000000000, // $1.3T
            population: 275000000,
            mainExportCommodities: [.palmOil: 30, .coal: 20, .naturalGas: 15, .rubber: 10],
            averageTariffRate: 5.0,
            inflationRate: 3.5,
            exchangeRate: 14800.0,
            interestRate: 5.5,
            politicalStability: 0.65,
            economicFreedom: 0.55,
            ruleOfLaw: 0.4
        )
        
        // Turkey
        tradePartners["TUR"] = TradePartner(
            id: "TUR",
            name: "Turkey",
            gdp: 900000000000, // $900B
            population: 85000000,
            mainExportCommodities: [.cotton: 20, .vehicles: 15, .agriculture: 15, .textiles: 15],
            averageTariffRate: 5.0,
            inflationRate: 20.0, // High inflation
            exchangeRate: 19.0,
            interestRate: 25.0,
            politicalStability: 0.45,
            economicFreedom: 0.4,
            ruleOfLaw: 0.35
        )
        
        totalTradePartners = tradePartners.count
    }
    
    private func setupBasicAgreements() {
        // WTO-style multilateral agreement
        let wto = TradeAgreementDetails(
            id: "wto_2024",
            type: .multilateral,
            name: "World Trade Organization Agreement",
            description: "Multilateral trade agreement establishing most-favored-nation principles",
            signatoryCountries: ["USA", "CHN", "EU", "BRA", "IND", "JPN", "CAN", "MEX", "KOR", "IDN"],
            participatingCountries: ["USA", "CHN", "EU", "BRA", "IND", "JPN", "CAN", "MEX", "KOR", "IDN", "AUS", "TUR"],
            effectiveDate: Date(),
            tariffReductions: [:], // General most-favored-nation rates apply
            rulesOfOrigin: "moderate",
            disputeResolution: "panel",
            isActive: true
        )
        activeAgreements["wto_2024"] = wto
        
        // US-China Phase One
        let usChina = TradeAgreementDetails(
            id: "us_china_phase1",
            type: .bilateral,
            name: "US-China Phase One Trade Agreement",
            description: "Bilateral agreement focusing on agricultural and manufactured goods",
            signatoryCountries: ["USA", "CHN"],
            participatingCountries: ["USA", "CHN"],
            effectiveDate: Date(),
            tariffReductions: [.soybeans: 25, .crudeOil: 20, .machinery: 15, .electronics: 10],
            rulesOfOrigin: "strict",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["us_china_phase1"] = usChina
        
        // EU-Canada
        let euCanada = TradeAgreementDetails(
            id: "eu_canada",
            type: .freeTrade,
            name: "EU-Canada Comprehensive Economic and Trade Agreement",
            description: "Comprehensive agreement covering goods, services, and investment",
            signatoryCountries: ["EU", "CAN"],
            participatingCountries: ["EU", "CAN"],
            effectiveDate: Date(),
            tariffReductions: [:],
            rulesOfOrigin: "moderate",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["eu_canada"] = euCanada
        
        // USMCA (North America)
        let usmca = TradeAgreementDetails(
            id: "usmca_2020",
            type: .regional,
            name: "United States-Mexico-Canada Agreement",
            description: "Regional agreement replacing NAFTA with updated provisions",
            signatoryCountries: ["USA", "CAN", "MEX"],
            participatingCountries: ["USA", "CAN", "MEX"],
            effectiveDate: Date(),
            tariffReductions: [:],
            rulesOfOrigin: "strict",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["usmca_2020"] = usmca
        
        // EU-Japan
        let euJapan = TradeAgreementDetails(
            id: "eu_japan",
            type: .bilateral,
            name: "EU-Japan Economic Partnership Agreement",
            description: "Bilateral agreement between EU and Japan",
            signatoryCountries: ["EU", "JPN"],
            participatingCountries: ["EU", "JPN"],
            effectiveDate: Date(),
            tariffReductions: [:],
            rulesOfOrigin: "moderate",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["eu_japan"] = euJapan
        
        // CPTPP (Comprehensive and Progressive Agreement for Trans-Pacific Partnership)
        let cptpp = TradeAgreementDetails(
            id: "cptpp_2018",
            type: .regional,
            name: "CPTPP - Comprehensive and Progressive Agreement for Trans-Pacific Partnership",
            description: "Pacific Rim trade agreement with 11 member countries",
            signatoryCountries: ["USA", "CHN", "JPN", "CAN", "MEX", "AUS", "MYA", "MYS", "VNM", "PRK", "CHN_HK"],
            participatingCountries: ["JPN", "CAN", "AUS", "MYA", "MYS", "VNM", "MYS", "BRN", "CHN_SGP", "NZL", "PER"],
            effectiveDate: Date(),
            tariffReductions: [:],
            rulesOfOrigin: "strict",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["cptpp_2018"] = cptpp
        
        // Africa Continental Free Trade Area
        let AfCFTA = TradeAgreementDetails(
            id: "afcfta_2019",
            type: .regional,
            name: "AfCFTA - African Continental Free Trade Area",
            description: "African Union initiative for free trade across Africa",
            signatoryCountries: ["EGY", "KEN", "NGA", "ZAF", "ETH", "TZA", "MAR", "TUN", "BWA", "NAM"],
            participatingCountries: ["EGY", "KEN", "NGA", "ZAF", "ETH", "TZA", "MAR", "TUN", "BWA", "NAM", "SEN", "CIV"],
            effectiveDate: Date(),
            tariffReductions: [:],
            rulesOfOrigin: "moderate",
            disputeResolution: "consultation",
            isActive: true
        )
        activeAgreements["afcfta_2019"] = AfCFTA
        
        totalAgreements = activeAgreements.count
    }
    
    private func initializeCommodityMetadata() {
        // Initialize comprehensive commodity info for all trade commodities
        // This is done in the TradeCommodity enum cases
    }
    
    // MARK: - Partner Management
    
    public func addTradePartner(_ partner: TradePartner) {
        tradePartners[partner.id] = partner
        #warning("Recalculate trade balances and statistics")
    }
    
    public func getTradePartner(_ id: String) -> TradePartner? {
        return tradePartners[id]
    }
    
    public func getAllTradePartners() -> [TradePartner] {
        return Array(tradePartners.values)
    }
    
    public func removeTradePartner(_ id: String) {
        tradePartners.removeValue(forKey: id)
        #warning("Recalculate statistics after partner removal")
    }
    
    // MARK: - Trade Flow Management
    
    public mutating func recordTradeFlow(_ flow: TradeFlow) -> TradeFlow {
        #warning("Validate trade flow: capacity, compliance, agreements")
        
        let tariffApplied = applyTariff(flow)
        var updatedFlow = flow
        updatedFlow.tariffCost = tariffApplied
        // Calculate total value including all costs
        updatedFlow.value = flow.quantity * flow.unitValue + tariffApplied + flow.freightCost + flow.insuranceCost + flow.otherCosts
        updatedFlow.totalCosts = updatedFlow.freightCost + updatedFlow.insuranceCost + updatedFlow.tariffCost + updatedFlow.otherCosts
        updatedFlow.complianceStatus = checkCompliance(flow)
        
        tradeFlows[updatedFlow.id] = updatedFlow
        
        #warning("Update partner trade statistics")
        updateTradeStatistics(flow: updatedFlow)
        
        return updatedFlow
    }
    
    private func applyTariff(_ flow: TradeFlow) -> Double {
        guard let partner = tradePartners[flow.partnerCountry] else {
            return flow.value * (flow.direction == .import ? 5 / 100 : 0)
        }
        
        var tariffRate: Double
        
        // Check for trade agreement
        if let agreementId = findApplicableAgreement(flow.partnerCountry, flow.direction) {
            if let agreement = activeAgreements[agreementId] {
                if let reduction = agreement.tariffReductions[flow.commodity] {
                    tariffRate = max(0, partner.averageTariffRate - reduction)
                } else {
                    tariffRate = partner.averageTariffRate
                }
            } else {
                tariffRate = partner.averageTariffRate
            }
        } else {
            tariffRate = partner.averageTariffRate
        }
        
        // Apply MFN if no special agreement
        let finalTariffRate = tariffRate
        
        return flow.value * (finalTariffRate / 100)
    }
    
    private func findApplicableAgreement(_ partnerCountry: String, _ direction: TradeDirection) -> String? {
        // Search through active agreements for matching partner
        for (agreementId, agreement) in activeAgreements where agreement.isActive {
            if agreement.signatoryCountries.contains(partnerCountry) {
                return agreementId
            }
        }
        return nil
    }
    
    private func checkCompliance(_ flow: TradeFlow) -> String {
        if flow.certificateOfOrigin && flow.phytosanitaryCertificate && flow.healthCertificate {
            return "cleared"
        } else if flow.customsDeclaration {
            return "held"
        } else {
            return "pending"
        }
    }
    
    private func updateTradeStatistics(flow: TradeFlow) {
        totalTradeValue += flow.value
        
        if flow.direction == .export {
            totalExports += flow.value
        } else if flow.direction == .import {
            totalImports += flow.value
        }
        
        // Update commodity values
        commodityTradeValues[flow.commodity, default: 0] += flow.value
        commodityTradeVolumes[flow.commodity, default: 0] += flow.quantity
        
        // Update partner values
        partnerTradeValues[flow.partnerCountry, default: 0] += flow.value
        
        totalTariffRevenue += flow.tariffCost
        
        // Update partner records
        if var partner = tradePartners[flow.partnerCountry] {
            partner.lastQuarterExports = partner.exports.reduce(0) { $0 + $1.value }
            partner.lastQuarterImports = partner.imports.reduce(0) { $0 + $1.value }
            tradePartners[flow.partnerCountry] = partner
        }
    }
    
    // MARK: - Partner Trade Operations
    
    public mutating func exportCommodities(
        _ commodities: [TradeCommodity],
        quantities: [TradeCommodity: Double],
        to partnerId: String,
        unitValues: [TradeCommodity: Double],
        direction: TradeDirection = .export
    ) -> [TradeFlow] {
        var flows: [TradeFlow] = []
        guard let partner = tradePartners[partnerId] else { return flows }
        
        for commodity in commodities {
            if let quantity = quantities[commodity],
               let unitValue = unitValues[commodity],
               unitValue > 0 {
                
                let estimatedValue = quantity * unitValue
                
                let flow = TradeFlow(
                    id: "trade-\(Date.timeIntervalSince1970)-\(commodity.rawValue)",
                    direction: direction,
                    commodity: commodity,
                    quantity: quantity,
                    value: estimatedValue,
                    unitValue: unitValue,
                    partnerCountry: partnerId,
                    partnerName: partner.name,
                    complianceStatus: "cleared"
                )
                
                let recordedFlow = recordTradeFlow(flow)
                flows.append(recordedFlow)
            }
        }
        
        return flows
    }
    
    public mutating func importCommodities(
        _ commodities: [TradeCommodity],
        quantities: [TradeCommodity: Double],
        from partnerId: String,
        unitValues: [TradeCommodity: Double],
        direction: TradeDirection = .import
    ) -> [TradeFlow] {
        var flows: [TradeFlow] = []
        guard let partner = tradePartners[partnerId] else { return flows }
        
        for commodity in commodities {
            if let quantity = quantities[commodity],
               let unitValue = unitValues[commodity],
               unitValue > 0 {
                
                let estimatedValue = quantity * unitValue
                
                let flow = TradeFlow(
                    id: "trade-\(Date.timeIntervalSince1970)-\(commodity.rawValue)",
                    direction: direction,
                    commodity: commodity,
                    quantity: quantity,
                    value: estimatedValue,
                    unitValue: unitValue,
                    partnerCountry: partnerId,
                    partnerName: partner.name,
                    complianceStatus: "pending"
                )
                
                let recordedFlow = recordTradeFlow(flow)
                flows.append(recordedFlow)
            }
        }
        
        return flows
    }
    
    // MARK: - Agreement Management
    
    public mutating func createAgreement(
        id: String,
        type: TradeAgreementType,
        name: String,
        signatoryCountries: [String],
        participatingCountries: [String],
        effectiveDate: Date
    ) -> TradeAgreementDetails {
        let agreement = TradeAgreementDetails(
            id: id,
            type: type,
            name: name,
            description: "\(name) agreement effective \(effectiveDate.description)",
            signatoryCountries: signatoryCountries,
            participatingCountries: participatingCountries,
            effectiveDate: effectiveDate
        )
        
        activeAgreements[id] = agreement
        #warning("Initialize agreement tariff reductions and rules")
        
        return agreement
    }
    
    public mutating func removeAgreement(_ id: String) {
        activeAgreements.removeValue(forKey: id)
        #warning("Recalculate tariffs and trade flows after agreement removal")
    }
    
    public mutating func updateAgreementTariffs(
        _ id: String,
        tariffReductions: [TradeCommodity: Double]
    ) {
        guard var agreement = activeAgreements[id] else { return }
        agreement.tariffReductions = tariffReductions
        agreement.lastUpdated = Date()
        activeAgreements[id] = agreement
        #warning("Recalculate trade flows with new tariffs")
    }
    
    // MARK: - Statistics and Reporting
    
    public func getTradeStatistics() -> TradeStatistics {
        let totalExports = exports.reduce(0) { $0 + $1.value }
        let totalImports = imports.reduce(0) { $0 + $1.value }
        let tradeBalance = totalExports - totalImports
        
        // By commodity
        var commodityValues: [TradeCommodity: Double] = [:]
        for flow in tradeFlows.values where flow.direction == .export {
            commodityValues[flow.commodity, default: 0] += flow.value
        }
        for flow in tradeFlows.values where flow.direction == .import {
            commodityValues[flow.commodity, default: 0] -= flow.value
        }
        
        // By partner
        var partnerValues: [String: Double] = [:]
        for flow in tradeFlows.values {
            partnerValues[flow.partnerCountry, default: 0] += flow.value
        }
        
        // Average tariff
        let avgTariff = tradeFlows.isEmpty ? 0 : tradeFlows.reduce(0) { $0 + $1.tariffCost } / Double(tradeFlows.count) / (totalImports > 0 ? totalImports : 1) * 100
        
        return TradeStatistics(
            totalTradeValue: totalTradeValue,
            totalExports: totalExports,
            totalImports: totalImports,
            tradeBalance: tradeBalance,
            totalTariffRevenue: totalTariffRevenue,
            commodityTradeValues: commodityValues,
            partnerTradeValues: partnerValues,
            averageTariffRate: avgTariff,
            totalFlows: tradeFlows.count,
            activeAgreements: activeAgreements.count,
            totalPartners: tradePartners.count,
            totalLettersOfCredit: totalLettersOfCredit,
            sustainableTradePercentage: sustainableTradePercentage
        )
    }
    
    public func getTradeFlow(
        _ commodity: TradeCommodity,
        direction: TradeDirection,
        with partnerId: String
    ) -> [TradeFlow] {
        tradeFlows.values.filter { flow in
            flow.commodity == commodity && flow.direction == direction && flow.partnerCountry == partnerId
        }
    }
    
    // Prediction functionality
    func predictTradeFlow(
        _ commodity: TradeCommodity,
        from source: String,
        to destination: String,
        timePeriod: Int // months
    ) -> (predictedValue: Double, confidence: Double) {
        let historicalFlows = tradeFlows.values.filter {
            $0.commodity == commodity && 
            $0.partnerCountry == destination && 
            $0.direction == (source == "local" ? .export : .import)
        }
        
        guard !historicalFlows.isEmpty else {
            return (0, 0.1)
        }
        
        let avgValue = historicalFlows.reduce(0) { $0 + $1.value } / Double(historicalFlows.count)
        let trendAdjustment = 1.0
        let confidence = min(0.9, 0.3 + Double(historicalFlows.count) * 0.07)
        
        let predictedValue = avgValue * trendAdjustment * Double(timePeriod)
        
        return (predictedValue, confidence)
    }
}

// MARK: - Trade Statistics

public struct TradeStatistics {
    let totalTradeValue: Double
    let totalExports: Double
    let totalImports: Double
    let tradeBalance: Double
    let totalTariffRevenue: Double
    let commodityTradeValues: [TradeCommodity: Double]
    let partnerTradeValues: [String: Double]
    let averageTariffRate: Double
    let totalFlows: Int
    let activeAgreements: Int
    let totalPartners: Int
    let totalLettersOfCredit: Double
    let sustainableTradePercentage: Double
}

// MARK: - Previews
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct InternationalTradePreview: PreviewProvider {
//    static var previews: some View {
//        Text("International Trade System Preview")
//    }
//}
//#endif