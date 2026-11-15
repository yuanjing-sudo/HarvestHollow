import Foundation

// MARK: - Two-dimensional vector

/// A tiny value-type vector used by projections, picking, and the 2D arcade.
/// It deliberately avoids CoreGraphics so the whole renderer stays testable
/// on Linux and can feed either SwiftUI `Canvas` or the command-line harness.
public struct Vec2: Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double

    public init(_ x: Double = 0, _ y: Double = 0) {
        self.x = x
        self.y = y
    }

    public static let zero = Vec2()

    public static func + (lhs: Vec2, rhs: Vec2) -> Vec2 {
        Vec2(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    public static func - (lhs: Vec2, rhs: Vec2) -> Vec2 {
        Vec2(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    public static func * (lhs: Vec2, rhs: Double) -> Vec2 {
        Vec2(lhs.x * rhs, lhs.y * rhs)
    }

    public static func / (lhs: Vec2, rhs: Double) -> Vec2 {
        Vec2(lhs.x / rhs, lhs.y / rhs)
    }

    public var lengthSquared: Double { x * x + y * y }
    public var length: Double { sqrt(lengthSquared) }

    public func distance(to other: Vec2) -> Double {
        (self - other).length
    }

    public func normalized() -> Vec2 {
        let magnitude = length
        guard magnitude > 0.000_001 else { return .zero }
        return self / magnitude
    }

    public func dot(_ other: Vec2) -> Double {
        x * other.x + y * other.y
    }

    public func rotated(radians: Double) -> Vec2 {
        let cosine = cos(radians)
        let sine = sin(radians)
        return Vec2(x * cosine - y * sine, x * sine + y * cosine)
    }

    public static func lerp(_ a: Vec2, _ b: Vec2, _ t: Double) -> Vec2 {
        a + (b - a) * max(0, min(1, t))
    }
}

// MARK: - Three-dimensional vector

public struct Vec3: Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(_ x: Double = 0, _ y: Double = 0, _ z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static let zero = Vec3()
    public static let one = Vec3(1, 1, 1)
    public static let up = Vec3(0, 1, 0)
    public static let right = Vec3(1, 0, 0)
    public static let forward = Vec3(0, 0, 1)

    public static func + (lhs: Vec3, rhs: Vec3) -> Vec3 {
        Vec3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    public static func - (lhs: Vec3, rhs: Vec3) -> Vec3 {
        Vec3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    public static prefix func - (value: Vec3) -> Vec3 {
        Vec3(-value.x, -value.y, -value.z)
    }

    public static func * (lhs: Vec3, rhs: Double) -> Vec3 {
        Vec3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    public static func * (lhs: Double, rhs: Vec3) -> Vec3 {
        rhs * lhs
    }

    public static func * (lhs: Vec3, rhs: Vec3) -> Vec3 {
        Vec3(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z)
    }

    public static func / (lhs: Vec3, rhs: Double) -> Vec3 {
        Vec3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }

    public static func += (lhs: inout Vec3, rhs: Vec3) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout Vec3, rhs: Vec3) {
        lhs = lhs - rhs
    }

    public static func *= (lhs: inout Vec3, rhs: Double) {
        lhs = lhs * rhs
    }

    public var lengthSquared: Double { x * x + y * y + z * z }
    public var length: Double { sqrt(lengthSquared) }

    public var flattened: Vec3 { Vec3(x, 0, z) }

    public func distance(to other: Vec3) -> Double {
        (self - other).length
    }

    public func normalized() -> Vec3 {
        let magnitude = length
        guard magnitude > 0.000_001 else { return .zero }
        return self / magnitude
    }

    public func dot(_ other: Vec3) -> Double {
        x * other.x + y * other.y + z * other.z
    }

    public func cross(_ other: Vec3) -> Vec3 {
        Vec3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }

    public func projected(on planeNormal: Vec3) -> Vec3 {
        self - planeNormal * dot(planeNormal)
    }

    public func lerp(to other: Vec3, _ t: Double) -> Vec3 {
        self + (other - self) * max(0, min(1, t))
    }

    public func rotatedY(radians: Double) -> Vec3 {
        let cosine = cos(radians)
        let sine = sin(radians)
        return Vec3(x * cosine + z * sine, y, -x * sine + z * cosine)
    }

    public func rotatedY(radians: Double, around pivot: Vec3) -> Vec3 {
        (self - pivot).rotatedY(radians: radians) + pivot
    }

    public func rotatedX(radians: Double) -> Vec3 {
        let cosine = cos(radians)
        let sine = sin(radians)
        return Vec3(x, y * cosine - z * sine, y * sine + z * cosine)
    }

    public func rotatedZ(radians: Double) -> Vec3 {
        let cosine = cos(radians)
        let sine = sin(radians)
        return Vec3(x * cosine - y * sine, x * sine + y * cosine, z)
    }

    public static func lerp(_ a: Vec3, _ b: Vec3, _ t: Double) -> Vec3 {
        a.lerp(to: b, t)
    }

    public var isFinite: Bool {
        x.isFinite && y.isFinite && z.isFinite
    }
}

// MARK: - Voxel colour

/// Colours are stored as bytes so voxel palettes stay compact and travel
/// unchanged through saves, tests, and snapshots.
public struct VoxelColor: Hashable, Codable, Sendable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        if text.count == 3 {
            text = text.map { "\($0)\($0)" }.joined()
        }
        var value: UInt64 = 0
        Scanner(string: text).scanHexInt64(&value)
        if text.count == 8 {
            red = UInt8((value >> 24) & 0xFF)
            green = UInt8((value >> 16) & 0xFF)
            blue = UInt8((value >> 8) & 0xFF)
            alpha = UInt8(value & 0xFF)
        } else {
            red = UInt8((value >> 16) & 0xFF)
            green = UInt8((value >> 8) & 0xFF)
            blue = UInt8(value & 0xFF)
            alpha = 255
        }
    }

    public var hex: String {
        String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
    }

    public var redUnit: Double { Double(red) / 255 }
    public var greenUnit: Double { Double(green) / 255 }
    public var blueUnit: Double { Double(blue) / 255 }
    public var alphaUnit: Double { Double(alpha) / 255 }

    public var luminance: Double {
        redUnit * 0.2126 + greenUnit * 0.7152 + blueUnit * 0.0722
    }

    public func scaled(by factor: Double) -> VoxelColor {
        let clamped = max(0, min(1.8, factor))
        return VoxelColor(
            red: UInt8(max(0, min(255, Double(red) * clamped))),
            green: UInt8(max(0, min(255, Double(green) * clamped))),
            blue: UInt8(max(0, min(255, Double(blue) * clamped))),
            alpha: alpha
        )
    }

    public func mixed(with other: VoxelColor, amount: Double) -> VoxelColor {
        let t = max(0, min(1, amount))
        func blend(_ a: UInt8, _ b: UInt8) -> UInt8 {
            UInt8(max(0, min(255, Double(a) * (1 - t) + Double(b) * t)))
        }
        return VoxelColor(
            red: blend(red, other.red),
            green: blend(green, other.green),
            blue: blend(blue, other.blue),
            alpha: blend(alpha, other.alpha)
        )
    }

    public func withAlpha(_ value: Double) -> VoxelColor {
        VoxelColor(
            red: red,
            green: green,
            blue: blue,
            alpha: UInt8(max(0, min(255, value * 255)))
        )
    }

    public static let clear = VoxelColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let white = VoxelColor(red: 255, green: 255, blue: 255)
    public static let black = VoxelColor(red: 24, green: 24, blue: 24)
}

// MARK: - Materials

public enum VoxelMaterial: String, Codable, CaseIterable, Sendable {
    case fur
    case skin
    case wool
    case feather
    case wood
    case darkWood
    case stone
    case brick
    case roof
    case leaf
    case flower
    case metal
    case glass
    case water
    case hay
    case soil
    case crop
    case fabric
    case ceramic
    case gold
    case light
    case eye

    /// Some materials catch more of the sun and some stay beautifully matte.
    public var lightResponse: Double {
        switch self {
        case .metal, .gold: return 1.22
        case .glass: return 1.34
        case .water: return 1.18
        case .leaf, .crop, .flower: return 0.96
        case .fur, .wool, .feather: return 0.88
        case .stone, .brick, .roof: return 0.9
        case .light: return 1.5
        case .eye: return 0.72
        default: return 1
        }
    }

    public var ambientBonus: Double {
        switch self {
        case .light: return 0.22
        case .glass, .gold: return 0.1
        case .eye: return -0.05
        default: return 0
        }
    }
}

// MARK: - Voxel

public struct VoxelKey: Hashable, Codable, Sendable {
    public let x: Int
    public let y: Int
    public let z: Int

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct Voxel: Hashable, Codable, Sendable {
    public var x: Int
    public var y: Int
    public var z: Int
    public var color: VoxelColor
    public var material: VoxelMaterial

    public init(x: Int, y: Int, z: Int, color: VoxelColor, material: VoxelMaterial = .fur) {
        self.x = x
        self.y = y
        self.z = z
        self.color = color
        self.material = material
    }

    public init(x: Int, y: Int, z: Int, hex: String, material: VoxelMaterial = .fur) {
        self.init(x: x, y: y, z: z, color: VoxelColor(hex: hex), material: material)
    }

    public var key: VoxelKey { VoxelKey(x: x, y: y, z: z) }

    public var position: Vec3 {
        Vec3(Double(x), Double(y), Double(z))
    }
}

// MARK: - Bounds

public struct VoxelBounds: Hashable, Sendable {
    public var minimum: VoxelKey
    public var maximum: VoxelKey

    public init(minimum: VoxelKey, maximum: VoxelKey) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public init?(voxels: [Voxel]) {
        guard let first = voxels.first else { return nil }
        var minX = first.x
        var minY = first.y
        var minZ = first.z
        var maxX = first.x
        var maxY = first.y
        var maxZ = first.z
        for voxel in voxels.dropFirst() {
            minX = min(minX, voxel.x)
            minY = min(minY, voxel.y)
            minZ = min(minZ, voxel.z)
            maxX = max(maxX, voxel.x)
            maxY = max(maxY, voxel.y)
            maxZ = max(maxZ, voxel.z)
        }
        minimum = VoxelKey(x: minX, y: minY, z: minZ)
        maximum = VoxelKey(x: maxX, y: maxY, z: maxZ)
    }

    public var width: Int { maximum.x - minimum.x + 1 }
    public var height: Int { maximum.y - minimum.y + 1 }
    public var depth: Int { maximum.z - minimum.z + 1 }

    public var size: Vec3 {
        Vec3(Double(width), Double(height), Double(depth))
    }

    public var center: Vec3 {
        Vec3(
            Double(minimum.x + maximum.x) * 0.5,
            Double(minimum.y + maximum.y) * 0.5,
            Double(minimum.z + maximum.z) * 0.5
        )
    }

    public var volume: Int { width * height * depth }

    public func contains(x: Int, y: Int, z: Int) -> Bool {
        x >= minimum.x && x <= maximum.x
            && y >= minimum.y && y <= maximum.y
            && z >= minimum.z && z <= maximum.z
    }

    public func expanded(by amount: Int) -> VoxelBounds {
        VoxelBounds(
            minimum: VoxelKey(
                x: minimum.x - amount,
                y: minimum.y - amount,
                z: minimum.z - amount
            ),
            maximum: VoxelKey(
                x: maximum.x + amount,
                y: maximum.y + amount,
                z: maximum.z + amount
            )
        )
    }
}

// MARK: - Faces

public struct VoxelFace: Hashable, Sendable {
    public let corners: [Vec3]
    public let normal: Vec3
    public let color: VoxelColor
    public let material: VoxelMaterial

    public init(
        corners: [Vec3],
        normal: Vec3,
        color: VoxelColor,
        material: VoxelMaterial
    ) {
        self.corners = corners
        self.normal = normal
        self.color = color
        self.material = material
    }

    public var center: Vec3 {
        guard !corners.isEmpty else { return .zero }
        var total = Vec3.zero
        for corner in corners {
            total += corner
        }
        return total / Double(corners.count)
    }
}

// MARK: - Model

public enum VoxelCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case animal
    case building
    case nature
    case prop
    case crop
    case character

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .animal: return "Animals"
        case .building: return "Buildings"
        case .nature: return "Nature"
        case .prop: return "Farm Props"
        case .crop: return "Crops"
        case .character: return "Characters"
        }
    }
}

/// A voxel model is immutable: its occupancy set is built once, so the
/// renderer can cull hidden faces without allocating a dictionary every frame.
public struct VoxelModel: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let category: VoxelCategory
    public let voxels: [Voxel]
    public let bounds: VoxelBounds
    public let anchor: Vec3
    public let notes: String

    private let occupancy: Set<VoxelKey>

    public init(
        id: String,
        name: String,
        category: VoxelCategory,
        voxels: [Voxel],
        anchor: Vec3? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.voxels = voxels
        self.bounds = VoxelBounds(voxels: voxels)
            ?? VoxelBounds(
                minimum: VoxelKey(x: 0, y: 0, z: 0),
                maximum: VoxelKey(x: 0, y: 0, z: 0)
            )
        self.anchor = anchor ?? self.bounds.center
        self.notes = notes
        self.occupancy = Set(voxels.map(\.key))
    }

    public var voxelCount: Int { voxels.count }
    public var volume: Int { bounds.volume }
    public var boundingSize: Vec3 { bounds.size }

    public var surfaceFaceCount: Int {
        var count = 0
        for voxel in voxels {
            for direction in VoxelDirection.allCases {
                let key = VoxelKey(
                    x: voxel.x + direction.dx,
                    y: voxel.y + direction.dy,
                    z: voxel.z + direction.dz
                )
                if !occupancy.contains(key) {
                    count += 1
                }
            }
        }
        return count
    }

    public func voxel(at x: Int, y: Int, z: Int) -> Voxel? {
        guard occupancy.contains(VoxelKey(x: x, y: y, z: z)) else { return nil }
        return voxels.first { $0.x == x && $0.y == y && $0.z == z }
    }

    public func hasVoxel(at x: Int, y: Int, z: Int) -> Bool {
        occupancy.contains(VoxelKey(x: x, y: y, z: z))
    }

    /// Returns only the faces that touch open air. This is the single most
    /// important optimization in the voxel renderer: interior voxels cost no
    /// drawing work at all.
    public func surfaceFaces() -> [VoxelFace] {
        var result: [VoxelFace] = []
        result.reserveCapacity(surfaceFaceCount)
        for voxel in voxels {
            for direction in VoxelDirection.allCases {
                let neighbor = VoxelKey(
                    x: voxel.x + direction.dx,
                    y: voxel.y + direction.dy,
                    z: voxel.z + direction.dz
                )
                guard !occupancy.contains(neighbor) else { continue }
                result.append(
                    VoxelFace(
                        corners: direction.corners(
                            x: Double(voxel.x),
                            y: Double(voxel.y),
                            z: Double(voxel.z)
                        ),
                        normal: direction.normal,
                        color: voxel.color,
                        material: voxel.material
                    )
                )
            }
        }
        return result
    }

    public func scaled(by factor: Double) -> VoxelModel {
        guard factor != 1 else { return self }
        let scaled = voxels.map {
            Voxel(
                x: Int((Double($0.x) * factor).rounded()),
                y: Int((Double($0.y) * factor).rounded()),
                z: Int((Double($0.z) * factor).rounded()),
                color: $0.color,
                material: $0.material
            )
        }
        return VoxelModel(
            id: id,
            name: name,
            category: category,
            voxels: scaled,
            anchor: anchor * factor,
            notes: notes
        )
    }

    public func translated(x: Int, y: Int, z: Int) -> VoxelModel {
        let moved = voxels.map {
            Voxel(
                x: $0.x + x,
                y: $0.y + y,
                z: $0.z + z,
                color: $0.color,
                material: $0.material
            )
        }
        return VoxelModel(
            id: id,
            name: name,
            category: category,
            voxels: moved,
            anchor: anchor + Vec3(Double(x), Double(y), Double(z)),
            notes: notes
        )
    }
}

// MARK: - Directions

public enum VoxelDirection: Int, CaseIterable, Sendable {
    case west
    case east
    case down
    case up
    case north
    case south

    public var dx: Int {
        switch self {
        case .west: return -1
        case .east: return 1
        default: return 0
        }
    }

    public var dy: Int {
        switch self {
        case .down: return -1
        case .up: return 1
        default: return 0
        }
    }

    public var dz: Int {
        switch self {
        case .north: return -1
        case .south: return 1
        default: return 0
        }
    }

    public var normal: Vec3 {
        Vec3(Double(dx), Double(dy), Double(dz))
    }

    /// Corners are emitted counter-clockwise when viewed from outside.
    public func corners(x: Double, y: Double, z: Double) -> [Vec3] {
        switch self {
        case .east:
            return [
                Vec3(x + 1, y, z),
                Vec3(x + 1, y + 1, z),
                Vec3(x + 1, y + 1, z + 1),
                Vec3(x + 1, y, z + 1)
            ]
        case .west:
            return [
                Vec3(x, y, z + 1),
                Vec3(x, y + 1, z + 1),
                Vec3(x, y + 1, z),
                Vec3(x, y, z)
            ]
        case .up:
            return [
                Vec3(x, y + 1, z + 1),
                Vec3(x, y + 1, z),
                Vec3(x + 1, y + 1, z),
                Vec3(x + 1, y + 1, z + 1)
            ]
        case .down:
            return [
                Vec3(x, y, z),
                Vec3(x + 1, y, z),
                Vec3(x + 1, y, z + 1),
                Vec3(x, y, z + 1)
            ]
        case .south:
            return [
                Vec3(x + 1, y, z + 1),
                Vec3(x + 1, y + 1, z + 1),
                Vec3(x, y + 1, z + 1),
                Vec3(x, y, z + 1)
            ]
        case .north:
            return [
                Vec3(x, y, z),
                Vec3(x, y + 1, z),
                Vec3(x + 1, y + 1, z),
                Vec3(x + 1, y, z)
            ]
        }
    }
}

// MARK: - Builder

/// A compact voxel sculpting kit. Procedural details and imported model data
/// both flow through the same builder so duplicate coordinates are handled
/// consistently.
public struct VoxelBuilder: Sendable {
    public private(set) var voxels: [Voxel] = []
    private var occupancy: Set<VoxelKey> = []

    public init() {}

    public mutating func place(
        x: Int,
        y: Int,
        z: Int,
        color: VoxelColor,
        material: VoxelMaterial = .fur
    ) {
        let key = VoxelKey(x: x, y: y, z: z)
        guard !occupancy.contains(key) else { return }
        occupancy.insert(key)
        voxels.append(Voxel(x: x, y: y, z: z, color: color, material: material))
    }

    public mutating func place(x: Int, y: Int, z: Int, hex: String, material: VoxelMaterial = .fur) {
        place(x: x, y: y, z: z, color: VoxelColor(hex: hex), material: material)
    }

    public mutating func box(
        from start: VoxelKey,
        to end: VoxelKey,
        color: VoxelColor,
        material: VoxelMaterial = .wood,
        hollow: Bool = false
    ) {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)
        let minZ = min(start.z, end.z)
        let maxZ = max(start.z, end.z)
        for y in minY...maxY {
            for z in minZ...maxZ {
                for x in minX...maxX {
                    if hollow {
                        let onShell = x == minX || x == maxX
                            || y == minY || y == maxY
                            || z == minZ || z == maxZ
                        guard onShell else { continue }
                    }
                    place(x: x, y: y, z: z, color: color, material: material)
                }
            }
        }
    }

    public mutating func ellipsoid(
        center: Vec3,
        radii: Vec3,
        color: VoxelColor,
        material: VoxelMaterial = .fur,
        hollow: Bool = false,
        noise: Double = 0
    ) {
        let minX = Int(floor(center.x - radii.x))
        let maxX = Int(ceil(center.x + radii.x))
        let minY = Int(floor(center.y - radii.y))
        let maxY = Int(ceil(center.y + radii.y))
        let minZ = Int(floor(center.z - radii.z))
        let maxZ = Int(ceil(center.z + radii.z))
        for y in minY...maxY {
            for z in minZ...maxZ {
                for x in minX...maxX {
                    let dx = (Double(x) - center.x) / max(0.1, radii.x)
                    let dy = (Double(y) - center.y) / max(0.1, radii.y)
                    let dz = (Double(z) - center.z) / max(0.1, radii.z)
                    let distance = dx * dx + dy * dy + dz * dz
                    guard distance <= 1 else { continue }
                    if hollow && distance < 0.62 { continue }
                    var adjusted = color
                    if noise > 0 {
                        let seed = Double((x &* 73856093) ^ (y &* 19349663) ^ (z &* 83492791))
                        let value = sin(seed) * noise
                        adjusted = color.scaled(by: 1 + value)
                    }
                    place(x: x, y: y, z: z, color: adjusted, material: material)
                }
            }
        }
    }

    public mutating func sphere(
        center: Vec3,
        radius: Double,
        color: VoxelColor,
        material: VoxelMaterial = .wood,
        hollow: Bool = false
    ) {
        ellipsoid(
            center: center,
            radii: Vec3(radius, radius, radius),
            color: color,
            material: material,
            hollow: hollow
        )
    }

    public mutating func cylinder(
        x: Int,
        z: Int,
        yRange: ClosedRange<Int>,
        radius: Double,
        color: VoxelColor,
        material: VoxelMaterial = .wood,
        hollow: Bool = false
    ) {
        let minX = Int(floor(Double(x) - radius))
        let maxX = Int(ceil(Double(x) + radius))
        let minZ = Int(floor(Double(z) - radius))
        let maxZ = Int(ceil(Double(z) + radius))
        for y in yRange {
            for dz in minZ...maxZ {
                for dx in minX...maxX {
                    let ox = Double(dx) - Double(x)
                    let oz = Double(dz) - Double(z)
                    let distance = sqrt(ox * ox + oz * oz)
                    guard distance <= radius else { continue }
                    if hollow && distance < radius - 1 { continue }
                    place(x: dx, y: y, z: dz, color: color, material: material)
                }
            }
        }
    }

    public mutating func line(
        from start: VoxelKey,
        to end: VoxelKey,
        color: VoxelColor,
        material: VoxelMaterial = .wood,
        thickness: Int = 1
    ) {
        let steps = max(
            abs(end.x - start.x),
            abs(end.y - start.y),
            abs(end.z - start.z),
            1
        )
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let x = Int((Double(start.x) + Double(end.x - start.x) * t).rounded())
            let y = Int((Double(start.y) + Double(end.y - start.y) * t).rounded())
            let z = Int((Double(start.z) + Double(end.z - start.z) * t).rounded())
            if thickness <= 1 {
                place(x: x, y: y, z: z, color: color, material: material)
            } else {
                box(
                    from: VoxelKey(x: x - thickness / 2, y: y - thickness / 2, z: z - thickness / 2),
                    to: VoxelKey(x: x + thickness / 2, y: y + thickness / 2, z: z + thickness / 2),
                    color: color,
                    material: material
                )
            }
        }
    }

    public mutating func ring(
        center: Vec3,
        radius: Double,
        y: Int,
        color: VoxelColor,
        material: VoxelMaterial = .wood,
        thickness: Double = 1
    ) {
        let minX = Int(floor(center.x - radius))
        let maxX = Int(ceil(center.x + radius))
        let minZ = Int(floor(center.z - radius))
        let maxZ = Int(ceil(center.z + radius))
        for z in minZ...maxZ {
            for x in minX...maxX {
                let dx = Double(x) - center.x
                let dz = Double(z) - center.z
                let distance = sqrt(dx * dx + dz * dz)
                guard abs(distance - radius) <= thickness else { continue }
                place(x: x, y: y, z: z, color: color, material: material)
            }
        }
    }

    public mutating func patch(
        center: Vec3,
        radius: Double,
        color: VoxelColor,
        material: VoxelMaterial = .leaf,
        yNoise: Int = 0
    ) {
        let minX = Int(floor(center.x - radius))
        let maxX = Int(ceil(center.x + radius))
        let minZ = Int(floor(center.z - radius))
        let maxZ = Int(ceil(center.z + radius))
        for z in minZ...maxZ {
            for x in minX...maxX {
                let dx = Double(x) - center.x
                let dz = Double(z) - center.z
                guard sqrt(dx * dx + dz * dz) <= radius else { continue }
                let hash = (x &* 92837111) ^ (z &* 689287499)
                let jitter = yNoise == 0 ? 0 : (abs(hash) % (yNoise * 2 + 1)) - yNoise
                place(
                    x: x,
                    y: Int(center.y) + jitter,
                    z: z,
                    color: color.scaled(by: 0.94 + Double(abs(hash) % 11) / 55),
                    material: material
                )
            }
        }
    }

    public func build(
        id: String,
        name: String,
        category: VoxelCategory,
        anchor: Vec3? = nil,
        notes: String = ""
    ) -> VoxelModel {
        VoxelModel(
            id: id,
            name: name,
            category: category,
            voxels: voxels,
            anchor: anchor,
            notes: notes
        )
    }
}
