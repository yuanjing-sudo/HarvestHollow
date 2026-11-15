import Foundation

// MARK: - Compact model data

/// The sculpting tools emit one voxel per line. This decoder turns that
/// human-readable data into the same value type used by procedural builders,
/// keeping generated and hand-built models interchangeable.
public enum VoxelModelCodec {
    public static func make(
        id: String,
        name: String,
        category: VoxelCategory,
        notes: String = "",
        anchor: Vec3 = .zero,
        rows: String
    ) -> VoxelModel {
        var voxels: [Voxel] = []
        voxels.reserveCapacity(512)
        for line in rows.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false)
            guard parts.count >= 5,
                  let x = Int(parts[0]),
                  let y = Int(parts[1]),
                  let z = Int(parts[2]) else { continue }
            let color = VoxelColor(hex: String(parts[3]))
            let material = VoxelMaterial(rawValue: String(parts[4])) ?? .wood
            voxels.append(Voxel(x: x, y: y, z: z, color: color, material: material))
        }
        return VoxelModel(
            id: id,
            name: name,
            category: category,
            voxels: voxels,
            anchor: anchor,
            notes: notes
        )
    }
}

// MARK: - Model library

public enum VoxelModelLibrary {
    public static let animalModels: [VoxelModel] = VoxelAnimalModels.all
    public static let buildingModels: [VoxelModel] = VoxelBuildingModels.all
    public static let natureModels: [VoxelModel] = VoxelNatureModels.all
    public static let propModels: [VoxelModel] = VoxelPropModels.all
    public static let cropModels: [VoxelModel] = VoxelCropModels.all
    public static let characterModels: [VoxelModel] = VoxelCharacterModels.all

    public static let all: [VoxelModel] = animalModels
        + buildingModels
        + natureModels
        + propModels
        + cropModels
        + characterModels

    public static let byID: [String: VoxelModel] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    public static func model(_ id: String) -> VoxelModel? {
        byID[id]
    }

    public static func models(in category: VoxelCategory) -> [VoxelModel] {
        all.filter { $0.category == category }
    }

    public static var totalVoxels: Int {
        all.reduce(0) { $0 + $1.voxelCount }
    }

    public static var totalSurfaceFaces: Int {
        all.reduce(0) { $0 + $1.surfaceFaceCount }
    }

    public static var modelCount: Int { all.count }

    public static let featuredIDs: [String] = [
        "animal.pig",
        "animal.cow",
        "animal.chicken",
        "animal.sheep",
        "animal.horse",
        "build.barn",
        "build.farmhouse",
        "build.windmill",
        "nature.oak",
        "nature.appletree",
        "prop.tractor",
        "character.farmer"
    ]

    public static var featured: [VoxelModel] {
        featuredIDs.compactMap(model)
    }

    /// The average pig is deliberately more than one hundred voxels. The
    /// statistic is exposed for the model inspector and for tests.
    public static var averageAnimalVoxels: Int {
        guard !animalModels.isEmpty else { return 0 }
        return animalModels.reduce(0) { $0 + $1.voxelCount } / animalModels.count
    }

    public static var largestModel: VoxelModel? {
        all.max { $0.voxelCount < $1.voxelCount }
    }

    public static var smallestModel: VoxelModel? {
        all.min { $0.voxelCount < $1.voxelCount }
    }
}

// MARK: - Face cache

/// Voxel models are static, so their visible-face list only needs to be built
/// once. The cache is a class because it is owned by the interactive view and
/// mutated between frames, while the models themselves remain value types.
public final class VoxelFaceCache {
    private var storage: [String: [VoxelFace]] = [:]

    public init() {}

    public func faces(for model: VoxelModel) -> [VoxelFace] {
        if let cached = storage[model.id] {
            return cached
        }
        let faces = model.surfaceFaces()
        storage[model.id] = faces
        return faces
    }

    public func clear() {
        storage.removeAll(keepingCapacity: true)
    }

    public var cachedModelCount: Int { storage.count }

    public var cachedFaceCount: Int {
        storage.values.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Model inspector

public struct VoxelModelSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: VoxelCategory
    public let voxelCount: Int
    public let surfaceFaces: Int
    public let width: Int
    public let height: Int
    public let depth: Int
    public let notes: String

    public init(model: VoxelModel) {
        id = model.id
        name = model.name
        category = model.category
        voxelCount = model.voxelCount
        surfaceFaces = model.surfaceFaceCount
        width = model.bounds.width
        height = model.bounds.height
        depth = model.bounds.depth
        notes = model.notes
    }

    public var dimensions: String {
        "\(width) × \(height) × \(depth)"
    }
}

public enum VoxelModelInspector {
    public static func summaries() -> [VoxelModelSummary] {
        VoxelModelLibrary.all
            .map(VoxelModelSummary.init)
            .sorted {
                if $0.category == $1.category {
                    return $0.name < $1.name
                }
                return $0.category.rawValue < $1.category.rawValue
            }
    }

    public static func summary(for id: String) -> VoxelModelSummary? {
        VoxelModelLibrary.model(id).map(VoxelModelSummary.init)
    }

    public static func voxelsByCategory() -> [VoxelCategory: Int] {
        Dictionary(grouping: VoxelModelLibrary.all, by: \.category)
            .mapValues { models in models.reduce(0) { $0 + $1.voxelCount } }
    }
}
