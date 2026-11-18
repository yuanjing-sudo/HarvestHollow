import Foundation

// MARK: - Camera presets

public enum VoxelCameraPreset: String, CaseIterable, Sendable, Identifiable {
    case overview
    case barn
    case animals
    case fields
    case house
    case pond

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .overview: return "The whole Hollow"
        case .barn: return "Big red barn"
        case .animals: return "Friends & pens"
        case .fields: return "Crop rows"
        case .house: return "Farmhouse garden"
        case .pond: return "Willow pond"
        }
    }

    public var icon: String {
        switch self {
        case .overview: return "square.grid.3x3.fill"
        case .barn: return "house.fill"
        case .animals: return "pawprint.fill"
        case .fields: return "leaf.fill"
        case .house: return "sofa.fill"
        case .pond: return "drop.fill"
        }
    }

    public var target: Vec3 {
        switch self {
        case .overview: return Vec3(0, 1.3, 2)
        case .barn: return Vec3(-6, 2.3, -6)
        case .animals: return Vec3(9, 1.5, 4)
        case .fields: return Vec3(-7, 1.2, 11)
        case .house: return Vec3(9, 2, -7)
        case .pond: return Vec3(12, 0.8, 14)
        }
    }

    public var yaw: Double {
        switch self {
        case .overview: return -0.68
        case .barn: return -0.3
        case .animals: return -1.2
        case .fields: return -0.4
        case .house: return 0.55
        case .pond: return -1.45
        }
    }

    public var pitch: Double {
        switch self {
        case .overview: return 0.52
        case .barn: return 0.28
        case .animals: return 0.34
        case .fields: return 0.3
        case .house: return 0.36
        case .pond: return 0.22
        }
    }

    public var distance: Double {
        switch self {
        case .overview: return 34
        case .barn: return 14
        case .animals: return 16
        case .fields: return 17
        case .house: return 15
        case .pond: return 14
        }
    }

    public var fieldOfView: Double {
        switch self {
        case .overview: return 1.05
        case .animals, .fields: return 1.0
        case .barn, .house, .pond: return 0.95
        }
    }

    public func camera() -> VoxelCamera {
        VoxelCamera(
            target: target,
            yaw: yaw,
            pitch: pitch,
            distance: distance,
            fieldOfView: fieldOfView
        )
    }
}

// MARK: - World

public struct VoxelFarmWorld: Sendable {
    public let objects: [VoxelSceneObject]
    public let models: [String: VoxelModel]
    public let weather: Weather
    public let day: Int
    public let season: FarmSeason
    public let lightPreset: VoxelLightPreset
    public let defaults: VoxelRenderOptions
    public let residentCount: Int
    public let cropCount: Int
    public let landmarkCount: Int

    public init(
        objects: [VoxelSceneObject],
        models: [String: VoxelModel],
        weather: Weather,
        day: Int,
        season: FarmSeason,
        lightPreset: VoxelLightPreset,
        defaults: VoxelRenderOptions,
        residentCount: Int,
        cropCount: Int,
        landmarkCount: Int
    ) {
        self.objects = objects
        self.models = models
        self.weather = weather
        self.day = day
        self.season = season
        self.lightPreset = lightPreset
        self.defaults = defaults
        self.residentCount = residentCount
        self.cropCount = cropCount
        self.landmarkCount = landmarkCount
    }

    public var objectCount: Int { objects.count }

    public var totalVoxels: Int {
        objects.reduce(0) { total, object in
            total + (models[object.modelID]?.voxelCount ?? 0)
        }
    }

    public var totalFaces: Int {
        objects.reduce(0) { total, object in
            total + (models[object.modelID]?.surfaceFaceCount ?? 0)
        }
    }

    public func object(_ id: String) -> VoxelSceneObject? {
        objects.first { $0.id == id }
    }

    public func model(for object: VoxelSceneObject) -> VoxelModel? {
        models[object.modelID]
    }

    public func camera(for preset: VoxelCameraPreset) -> VoxelCamera {
        preset.camera()
    }

    public func render(
        camera: VoxelCamera,
        viewport: Vec2,
        options: VoxelRenderOptions? = nil,
        cache: VoxelFaceCache? = nil
    ) -> VoxelSceneSnapshot {
        let resolvedOptions = options ?? lightPreset.options(base: defaults)
        return VoxelRenderer.render(
            objects: objects,
            models: models,
            camera: camera,
            viewport: viewport,
            light: lightPreset.light,
            options: resolvedOptions,
            faceCache: cache
        )
    }

    public func selectedObject(for anchor: VoxelRenderAnchor?) -> VoxelSceneObject? {
        guard let anchor else { return nil }
        return object(anchor.id)
    }
}

// MARK: - Builder

public enum VoxelWorldBuilder {
    /// A shallow pond is built in code so the fishing spot is visible in the
    /// 3D farm without adding a PNG or a heavyweight mesh.
    private static let pondWaterModel: VoxelModel = makePondWaterModel()

    private static func makePondWaterModel() -> VoxelModel {
        var voxels: [Voxel] = []
        let width = 34
        let depth = 22
        for x in 0..<width {
            for z in 0..<depth {
                let dx = Double(x) - 17
                let dz = Double(z) - 11
                let ellipse = (dx * dx) / (17 * 17) + (dz * dz) / (11 * 11)
                if ellipse > 1 { continue }
                if ellipse > 0.80 {
                    voxels.append(Voxel(x: x, y: 0, z: z, hex: "8F8C82", material: .stone))
                    if (x + z) % 4 == 0 {
                        voxels.append(Voxel(x: x, y: 1, z: z, hex: "A8A394", material: .stone))
                    }
                } else {
                    let shade = (x / 3 + z / 4) % 2 == 0 ? "4F8AAE" : "5C9BC0"
                    voxels.append(Voxel(x: x, y: 0, z: z, hex: shade, material: .water))
                }
            }
        }
        for center in [(10, 8), (23, 6), (15, 15), (26, 14)] {
            for dx in -1...1 {
                for dz in -1...1 where abs(dx) + abs(dz) <= 1 {
                    voxels.append(
                        Voxel(x: center.0 + dx, y: 1, z: center.1 + dz, hex: "5A9B69", material: .leaf)
                    )
                }
            }
        }
        return VoxelModel(
            id: "nature.pondwater",
            name: "Willow Pond",
            category: .nature,
            voxels: voxels,
            notes: "Shallow water, stone edge and lily pads for the Hollow fishing pond."
        )
    }

    public static func build(state: GameState) -> VoxelFarmWorld {
        var objects: [VoxelSceneObject] = []
        let localModels = ["nature.pondwater": pondWaterModel]
        var residentCount = 0
        var cropCount = 0
        var landmarkCount = 0

        func add(
            _ id: String,
            _ modelID: String,
            x: Double,
            y: Double,
            z: Double,
            rotation: Double = 0,
            scale: Double = 0.1,
            label: String,
            detail: String = "",
            kind: VoxelObjectKind = .prop,
            accent: String = "4F8A5A"
        ) {
            guard VoxelModelLibrary.model(modelID) != nil || localModels[modelID] != nil else { return }
            objects.append(
                VoxelSceneObject(
                    id: id,
                    modelID: modelID,
                    position: Vec3(x, y, z),
                    rotationY: rotation,
                    scale: scale,
                    label: label,
                    detail: detail,
                    kind: kind,
                    accent: VoxelColor(hex: accent)
                )
            )
        }

        // Landmark buildings
        add(
            "building.barn",
            "build.barn",
            x: -6.2, y: 0, z: -7.8,
            rotation: 0.04,
            label: "The Big Red Barn",
            detail: "Hayloft, sliding doors and a weather vane. The heart of the farm.",
            kind: .building,
            accent: "B64B3F"
        )
        add(
            "building.farmhouse",
            "build.farmhouse",
            x: 8.6, y: 0, z: -7.6,
            rotation: -0.08,
            label: "Hollow Farmhouse",
            detail: "A cream cottage with a red roof and flower boxes by the porch.",
            kind: .building,
            accent: "D98745"
        )
        add(
            "building.silo",
            "build.silo",
            x: -12.8, y: 0, z: -3.8,
            rotation: 0.12,
            label: "Grain Silo",
            detail: "Stone, copper and a ladder to the very top.",
            kind: .building,
            accent: "8F8C82"
        )
        add(
            "building.windmill",
            "build.windmill",
            x: -17.5, y: 0, z: 5.2,
            rotation: -0.24,
            label: "The Old Windmill",
            detail: "Four sails turning over the western field.",
            kind: .building,
            accent: "C9B391"
        )
        add(
            "building.coop",
            "build.coop",
            x: 14.5, y: 0, z: 4.2,
            rotation: 0.15,
            label: "Chicken Coop",
            detail: "A warm little house with a ramp and nest boxes.",
            kind: .building,
            accent: "B64B3F"
        )
        add(
            "building.greenhouse",
            "build.greenhouse",
            x: 16.2, y: 0, z: -1.8,
            rotation: -0.15,
            label: "Glass Greenhouse",
            detail: "Seedlings, terracotta pots and warm afternoon light.",
            kind: .building,
            accent: "6B8F73"
        )
        add(
            "building.well",
            "build.well",
            x: 2.8, y: 0, z: 5.4,
            rotation: 0.2,
            label: "Stone Well",
            detail: "Cold water, a rope and a bucket that always comes back up.",
            kind: .building,
            accent: "A7A397"
        )
        add(
            "building.market",
            "build.market",
            x: -3.6, y: 0, z: 11.2,
            rotation: 0.08,
            label: "Saturday Market",
            detail: "Striped awning, scales and baskets of the week's harvest.",
            kind: .building,
            accent: "B64B3F"
        )
        add(
            "building.shed",
            "build.shed",
            x: 15.4, y: 0, z: 11.2,
            rotation: -0.1,
            label: "Tool Shed",
            detail: "Every rake, spade and piece of twine has a home.",
            kind: .building,
            accent: "8A7358"
        )

        // Nature
        add(
            "nature.oak",
            "nature.oak",
            x: -22.5, y: 0, z: 13.8,
            rotation: 0.2,
            scale: 0.11,
            label: "The Old Oak",
            detail: "The rope swing has been here longer than anyone remembers.",
            kind: .nature,
            accent: "4F8A5A"
        )
        add(
            "nature.appletree",
            "nature.appletree",
            x: 22.8, y: 0, z: 9.6,
            rotation: -0.4,
            scale: 0.11,
            label: "Apple Tree",
            detail: "Seven apples visible from this side. Probably.",
            kind: .nature,
            accent: "C94F45"
        )
        add(
            "nature.pine",
            "nature.pine",
            x: -24.0, y: 0, z: -10.5,
            rotation: 0.1,
            scale: 0.1,
            label: "North Pine",
            detail: "A windbreak and a favourite hiding place for birds.",
            kind: .nature,
            accent: "2F5D43"
        )
        add(
            "nature.birch",
            "nature.birch",
            x: 23.0, y: 0, z: -10.8,
            rotation: -0.2,
            scale: 0.1,
            label: "Silver Birch",
            detail: "Pale bark, small leaves and a soft rustle.",
            kind: .nature,
            accent: "8FC77D"
        )
        add(
            "nature.bush",
            "nature.bush",
            x: 8.0, y: 0, z: 10.8,
            rotation: 0.2,
            scale: 0.1,
            label: "Berry Bush",
            detail: "The blue berries are for the birds, mostly.",
            kind: .nature,
            accent: "4F8A5A"
        )
        add(
            "nature.flowers",
            "nature.flowers",
            x: 5.0, y: 0, z: 8.6,
            rotation: 0.0,
            scale: 0.1,
            label: "Flower Patch",
            detail: "Poppies, daisies and lavender for the cottage table.",
            kind: .nature,
            accent: "D95D4F"
        )
        add(
            "nature.rocks",
            "nature.rocks",
            x: -16.0, y: 0, z: 15.2,
            rotation: 0.5,
            scale: 0.11,
            label: "Mossy Rocks",
            detail: "Warm stone for a lazy afternoon.",
            kind: .nature,
            accent: "8F8C82"
        )
        add(
            "nature.pondwater",
            "nature.pondwater",
            x: 12.2, y: 0, z: 14.9,
            rotation: 0,
            scale: 0.13,
            label: "Willow Pond",
            detail: "The Hollow fishing pond: shallow water, a stone edge, and lily pads. Tap Visit pond to cast a line.",
            kind: .nature,
            accent: "4F8AAE"
        )
        add(
            "nature.lilypad",
            "nature.lilypad",
            x: 13.8, y: 0, z: 15.4,
            rotation: 0.2,
            scale: 0.12,
            label: "Lily Pads",
            detail: "Lily pads, reeds and a frog who is not currently visible.",
            kind: .nature,
            accent: "4F8A5A"
        )
        add(
            "nature.reeds",
            "nature.reeds",
            x: 16.8, y: 0, z: 14.2,
            rotation: -0.3,
            scale: 0.12,
            label: "Pond Reeds",
            detail: "Cattails standing guard at the water's edge.",
            kind: .nature,
            accent: "5A7D4F"
        )

        // Farm props and furniture
        add(
            "prop.tractor",
            "prop.tractor",
            x: -15.0, y: 0, z: 12.6,
            rotation: 0.16,
            scale: 0.1,
            label: "Little Tractor",
            detail: "Pea-green, noisy and absolutely essential.",
            kind: .prop,
            accent: "6B8F73"
        )
        add(
            "prop.wagon",
            "prop.wagon",
            x: 1.8, y: 0, z: 12.8,
            rotation: -0.08,
            scale: 0.1,
            label: "Harvest Wagon",
            detail: "Sacks and pumpkins ready for market day.",
            kind: .prop,
            accent: "A46B49"
        )
        add(
            "prop.haybale",
            "prop.haybale",
            x: 5.8, y: 0, z: 9.4,
            rotation: 0.3,
            scale: 0.11,
            label: "Hay Bale",
            detail: "Sweet-smelling and surprisingly comfortable.",
            kind: .prop,
            accent: "D8B65C"
        )
        add(
            "prop.scarecrow",
            "prop.scarecrow",
            x: -9.2, y: 0, z: 8.8,
            rotation: -0.3,
            scale: 0.1,
            label: "Scarecrow",
            detail: "His name is Captain Straw and he takes the job seriously.",
            kind: .prop,
            accent: "C9B391"
        )
        add(
            "prop.lamppost",
            "prop.lamppost",
            x: -0.2, y: 0, z: 8.5,
            rotation: 0.0,
            scale: 0.1,
            label: "Path Lamp",
            detail: "A warm welcome after a long day in the fields.",
            kind: .prop,
            accent: "F0C95C"
        )
        add(
            "prop.bench",
            "prop.bench",
            x: 6.8, y: 0, z: 5.8,
            rotation: 0.4,
            scale: 0.11,
            label: "Garden Bench",
            detail: "The best seat for watching the sun go down.",
            kind: .prop,
            accent: "8A5A3A"
        )
        add(
            "prop.mailbox",
            "prop.mailbox",
            x: 11.8, y: 0, z: 6.8,
            rotation: 0.2,
            scale: 0.12,
            label: "Mailbox",
            detail: "Usually contains seeds, occasionally a letter from town.",
            kind: .prop,
            accent: "B64B3F"
        )

        // Fence boundary. Each section is a real model object, not a texture.
        let fencePositions: [(Double, Double, Double)] = [
            (-18, 6.0, 0), (-15, 6.0, 0), (-12, 6.0, 0),
            (12, 6.0, 0), (15, 6.0, 0), (18, 6.0, 0),
            (-19, 0.5, 13), (-16, 0.5, 13), (17, 0.5, 13),
            (20, 0.5, 13)
        ]
        for (index, fence) in fencePositions.enumerated() {
            add(
                "fence.\(index)",
                "prop.fence",
                x: fence.0, y: 0, z: fence.2,
                rotation: fence.1 == 0 ? 1.5708 : 0,
                scale: 0.1,
                label: "Fence",
                detail: "Keeps the sheep in and the carrots safe.",
                kind: .prop,
                accent: "E9D9B7"
            )
        }

        // The player's real animals occupy the pens. On a brand-new save the
        // diorama still welcomes a few resident critters so the tab is alive.
        let actualAnimals = state.pens.compactMap(\.animal)
        if !actualAnimals.isEmpty {
            for (index, animal) in actualAnimals.enumerated() {
                let species = animal.speciesID
                let angle = Double(index) * 1.18
                let x = 8.0 + cos(angle) * 3.6
                let z = 2.2 + sin(angle) * 2.6
                add(
                    "animal.\(animal.id.uuidString)",
                    "animal.\(species)",
                    x: x, y: 0, z: z,
                    rotation: angle + 1.2,
                    scale: 0.115,
                    label: animal.name,
                    detail: "\(species.capitalized) · affection level \(animal.affectionLevel) · \(animal.affectionTitle)",
                    kind: .animal,
                    accent: "C96A4B"
                )
                residentCount += 1
            }
        } else {
            let resident: [(String, String, Double, Double, Double)] = [
                ("Pip", "animal.pig", 7.2, 2.0, -0.4),
                ("Clucky", "animal.chicken", 12.4, 5.0, 0.8),
                ("Bramble", "animal.cow", 4.8, 1.2, 1.6)
            ]
            for entry in resident {
                add(
                    "resident.\(entry.0)",
                    entry.1,
                    x: entry.2, y: 0, z: entry.3,
                    rotation: entry.4,
                    scale: 0.12,
                    label: entry.0,
                    detail: "A Hollow resident, waiting for a pen of their own.",
                    kind: .animal,
                    accent: "C96A4B"
                )
                residentCount += 1
            }
        }

        // Field plots become actual crop models. If the field is empty, a few
        // showcase rows keep the diorama warm without changing the farm save.
        let planted = state.plots.compactMap { plot -> (Int, CropInstance)? in
            guard let crop = plot.crop else { return nil }
            return (plot.id, crop)
        }
        if !planted.isEmpty {
            for entry in planted.prefix(12) {
                let index = entry.0
                let row = index / 4
                let column = index % 4
                add(
                    "crop.\(index)",
                    "crop.\(entry.1.cropID)",
                    x: -12.0 + Double(column) * 2.1,
                    y: 0,
                    z: 8.0 + Double(row) * 1.9,
                    rotation: 0.08,
                    scale: 0.1,
                    label: "Plot \(index + 1)",
                    detail: "\(entry.1.cropID.capitalized) · \(Int(entry.1.growth * 100))% grown",
                    kind: .crop,
                    accent: "6FA84F"
                )
                cropCount += 1
            }
        } else {
            let showcase: [(String, Double, Double)] = [
                ("wheat", -12.0, 8.0), ("carrot", -9.9, 8.0), ("corn", -7.8, 8.0),
                ("wheat", -12.0, 9.9), ("carrot", -9.9, 9.9), ("tomato", -7.8, 9.9)
            ]
            for (index, entry) in showcase.enumerated() {
                add(
                    "showcase.\(index)",
                    "crop.\(entry.0)",
                    x: entry.1, y: 0, z: entry.2,
                    rotation: 0.08,
                    scale: 0.1,
                    label: "Field rows",
                    detail: "A little sample of the crop rotation.",
                    kind: .crop,
                    accent: "6FA84F"
                )
                cropCount += 1
            }
        }

        // A couple of small details around the pond and barnyard.
        add(
            "prop.bridge",
            "prop.bridge",
            x: 11.2, y: 0, z: 15.0,
            rotation: 0.1,
            scale: 0.1,
            label: "Pond Bridge",
            detail: "A humped crossing with a mossy stone footing.",
            kind: .landmark,
            accent: "8A5A3A"
        )
        add(
            "prop.birdhouse",
            "prop.birdhouse",
            x: 18.2, y: 0, z: 8.8,
            rotation: 0.0,
            scale: 0.12,
            label: "Birdhouse",
            detail: "Blue paint and a very busy front door.",
            kind: .prop,
            accent: "4F7FA8"
        )
        add(
            "prop.sundial",
            "prop.sundial",
            x: -0.5, y: 0, z: 2.6,
            rotation: 0.0,
            scale: 0.11,
            label: "Garden Sundial",
            detail: "Brass, lavender and a shadow that always tells the truth.",
            kind: .prop,
            accent: "B8892E"
        )

        landmarkCount = objects.filter { $0.kind == .landmark || $0.kind == .building }.count

        let modelIDs = Set(objects.map(\.modelID))
        var models: [String: VoxelModel] = [:]
        for id in modelIDs {
            if let model = VoxelModelLibrary.model(id) ?? localModels[id] {
                models[id] = model
            }
        }

        let lightPreset = lightPreset(for: state)
        var defaults = VoxelRenderOptions.diorama
        defaults.showGrid = true
        defaults.showAxes = true
        defaults.showShadows = true
        defaults.minimumFaceArea = 0.22

        return VoxelFarmWorld(
            objects: objects,
            models: models,
            weather: state.weather,
            day: state.day,
            season: state.season,
            lightPreset: lightPreset,
            defaults: defaults,
            residentCount: residentCount,
            cropCount: cropCount,
            landmarkCount: landmarkCount
        )
    }

    public static func lightPreset(for state: GameState) -> VoxelLightPreset {
        if state.weather == .storm { return .storm }
        let time = state.timeOfDay
        if time < 0.22 || time > 0.84 { return .night }
        if time < 0.36 { return .morning }
        if time > 0.66 { return .goldenHour }
        return .noon
    }

    public static func previewWorld() -> VoxelFarmWorld {
        build(state: .newGame(now: Date(timeIntervalSince1970: 1_700_000_000), seed: 7))
    }
}
