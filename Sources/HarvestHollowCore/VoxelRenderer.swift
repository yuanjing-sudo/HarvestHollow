import Foundation

// MARK: - Projection

public struct VoxelProjection: Hashable, Sendable {
    public let point: Vec2
    public let depth: Double
    public let scale: Double
    public let visible: Bool

    public init(point: Vec2, depth: Double, scale: Double, visible: Bool) {
        self.point = point
        self.depth = depth
        self.scale = scale
        self.visible = visible
    }
}

public struct VoxelBasis: Hashable, Sendable {
    public let right: Vec3
    public let up: Vec3
    public let forward: Vec3

    public init(right: Vec3, up: Vec3, forward: Vec3) {
        self.right = right
        self.up = up
        self.forward = forward
    }
}

/// An orbit camera with an explicit XYZ basis. Keeping the camera
/// independent of SwiftUI makes the 3D scene deterministic in tests and lets
/// the same scene feed the CLI previewer.
public struct VoxelCamera: Hashable, Sendable {
    public var target: Vec3
    public var yaw: Double
    public var pitch: Double
    public var distance: Double
    public var fieldOfView: Double
    public var nearPlane: Double

    public init(
        target: Vec3 = Vec3(0, 2.4, 0),
        yaw: Double = -0.68,
        pitch: Double = 0.58,
        distance: Double = 24,
        fieldOfView: Double = 0.86,
        nearPlane: Double = 0.05
    ) {
        self.target = target
        self.yaw = yaw
        self.pitch = max(-1.15, min(1.2, pitch))
        self.distance = max(2, distance)
        self.fieldOfView = max(0.2, min(1.6, fieldOfView))
        self.nearPlane = max(0.001, nearPlane)
    }

    public var position: Vec3 {
        let horizontal = cos(pitch) * distance
        return Vec3(
            target.x + sin(yaw) * horizontal,
            target.y + sin(pitch) * distance,
            target.z + cos(yaw) * horizontal
        )
    }

    public var basis: VoxelBasis {
        let forward = (target - position).normalized()
        var right = forward.cross(.up)
        if right.lengthSquared < 0.000_001 {
            right = Vec3(1, 0, 0)
        }
        right = right.normalized()
        let up = right.cross(forward).normalized()
        return VoxelBasis(right: right, up: up, forward: forward)
    }

    public var focalLength: Double {
        1 / tan(fieldOfView * 0.5)
    }

    public func project(_ point: Vec3, viewport: Vec2) -> VoxelProjection {
        let eye = position
        let view = basis
        let relative = point - eye
        let cameraX = relative.dot(view.right)
        let cameraY = relative.dot(view.up)
        let cameraZ = relative.dot(view.forward)
        guard cameraZ > nearPlane else {
            return VoxelProjection(
                point: Vec2(viewport.x * 0.5, viewport.y * 0.5),
                depth: cameraZ,
                scale: 0,
                visible: false
            )
        }
        let focal = min(viewport.x, viewport.y) * focalLength
        let screenX = viewport.x * 0.5 + cameraX / cameraZ * focal
        let screenY = viewport.y * 0.5 - cameraY / cameraZ * focal
        return VoxelProjection(
            point: Vec2(screenX, screenY),
            depth: cameraZ,
            scale: focal / cameraZ,
            visible: true
        )
    }

    public func screenScale(viewport: Vec2) -> Double {
        min(viewport.x, viewport.y) * focalLength
    }

    public func orbit(deltaYaw: Double, deltaPitch: Double) -> VoxelCamera {
        var copy = self
        copy.yaw = yaw + deltaYaw
        copy.pitch = max(-0.06, min(1.16, pitch + deltaPitch))
        return copy
    }

    public func zoomed(by factor: Double) -> VoxelCamera {
        var copy = self
        copy.distance = max(3.5, min(90, distance * factor))
        return copy
    }

    public func panning(by delta: Vec2, viewport: Vec2) -> VoxelCamera {
        let view = basis
        let worldPerPoint = distance / max(80, min(viewport.x, viewport.y))
        let movement = view.right * (delta.x * worldPerPoint)
            + view.up * (-delta.y * worldPerPoint)
        var copy = self
        copy.target = target + movement
        return copy
    }

    public func looking(at newTarget: Vec3) -> VoxelCamera {
        var copy = self
        copy.target = newTarget
        return copy
    }

    public static func fitting(
        bounds: VoxelBounds,
        yaw: Double = -0.68,
        pitch: Double = 0.58
    ) -> VoxelCamera {
        let center = bounds.center
        let radius = max(
            2,
            sqrt(
                Double(bounds.width * bounds.width)
                    + Double(bounds.height * bounds.height)
                    + Double(bounds.depth * bounds.depth)
            ) * 0.5
        )
        return VoxelCamera(
            target: Vec3(center.x, max(1, center.y * 0.42), center.z),
            yaw: yaw,
            pitch: pitch,
            distance: max(10, radius * 2.6)
        )
    }
}

// MARK: - Lighting

public struct VoxelLight: Hashable, Sendable {
    public var sunDirection: Vec3
    public var ambient: Double
    public var diffuse: Double
    public var rim: Double
    public var warmth: Double

    public init(
        sunDirection: Vec3 = Vec3(-0.48, 0.82, 0.32).normalized(),
        ambient: Double = 0.52,
        diffuse: Double = 0.54,
        rim: Double = 0.1,
        warmth: Double = 0.06
    ) {
        self.sunDirection = sunDirection
        self.ambient = ambient
        self.diffuse = diffuse
        self.rim = rim
        self.warmth = warmth
    }

    public func shade(_ color: VoxelColor, normal: Vec3, material: VoxelMaterial) -> VoxelColor {
        let sun = max(0, normal.dot(sunDirection))
        let bounce = max(0, -normal.y) * 0.09
        let factor = (ambient + diffuse * sun + rim + bounce) * material.lightResponse
            + material.ambientBonus
        var shaded = color.scaled(by: factor)
        if warmth > 0 {
            shaded = shaded.mixed(
                with: VoxelColor(red: 255, green: 216, blue: 160),
                amount: warmth * sun
            )
        }
        return shaded
    }
}

// MARK: - Scene objects

public enum VoxelObjectKind: String, Codable, CaseIterable, Sendable {
    case animal
    case building
    case nature
    case prop
    case crop
    case avatar
    case landmark

    public var title: String {
        switch self {
        case .animal: return "Animal"
        case .building: return "Building"
        case .nature: return "Nature"
        case .prop: return "Farm prop"
        case .crop: return "Crop"
        case .avatar: return "Character"
        case .landmark: return "Landmark"
        }
    }
}

public struct VoxelSceneObject: Identifiable, Hashable, Sendable {
    public var id: String
    public var modelID: String
    public var position: Vec3
    public var rotationY: Double
    public var scale: Double
    public var label: String
    public var detail: String
    public var kind: VoxelObjectKind
    public var selectable: Bool
    public var accent: VoxelColor

    public init(
        id: String,
        modelID: String,
        position: Vec3,
        rotationY: Double = 0,
        scale: Double = 0.1,
        label: String,
        detail: String = "",
        kind: VoxelObjectKind = .prop,
        selectable: Bool = true,
        accent: VoxelColor = VoxelColor(hex: "4F8A5A")
    ) {
        self.id = id
        self.modelID = modelID
        self.position = position
        self.rotationY = rotationY
        self.scale = scale
        self.label = label
        self.detail = detail
        self.kind = kind
        self.selectable = selectable
        self.accent = accent
    }

    public func transformed(_ model: VoxelModel) -> (points: [Vec3], normals: [Vec3], bounds: VoxelBounds) {
        let rotation = rotationY
        let anchor = model.anchor
        let points = model.voxels.map { voxel -> Vec3 in
            let local = Vec3(Double(voxel.x), Double(voxel.y), Double(voxel.z)) - anchor
            return (local * scale).rotatedY(radians: rotation) + position
        }
        let normals = VoxelDirection.allCases.map {
            $0.normal.rotatedY(radians: rotation)
        }
        return (points, normals, model.bounds)
    }
}

// MARK: - Render options

public struct VoxelRenderOptions: Hashable, Sendable {
    public var backgroundTop: VoxelColor
    public var backgroundBottom: VoxelColor
    public var horizon: VoxelColor
    public var showGrid: Bool
    public var showAxes: Bool
    public var showObjectHalo: Bool
    public var showShadows: Bool
    public var outlineFaces: Bool
    public var gridExtent: Int
    public var gridStep: Int
    public var axisLength: Double
    public var minimumDepth: Double
    public var maximumFaces: Int
    public var minimumFaceArea: Double

    public init(
        backgroundTop: VoxelColor = VoxelColor(hex: "BFE3EE"),
        backgroundBottom: VoxelColor = VoxelColor(hex: "E9DCBF"),
        horizon: VoxelColor = VoxelColor(hex: "D6E6D2"),
        showGrid: Bool = true,
        showAxes: Bool = true,
        showObjectHalo: Bool = true,
        showShadows: Bool = true,
        outlineFaces: Bool = false,
        gridExtent: Int = 76,
        gridStep: Int = 4,
        axisLength: Double = 5,
        minimumDepth: Double = 0.15,
        maximumFaces: Int = 30_000,
        minimumFaceArea: Double = 0.16
    ) {
        self.backgroundTop = backgroundTop
        self.backgroundBottom = backgroundBottom
        self.horizon = horizon
        self.showGrid = showGrid
        self.showAxes = showAxes
        self.showObjectHalo = showObjectHalo
        self.showShadows = showShadows
        self.outlineFaces = outlineFaces
        self.gridExtent = gridExtent
        self.gridStep = max(1, gridStep)
        self.axisLength = axisLength
        self.minimumDepth = minimumDepth
        self.maximumFaces = maximumFaces
        self.minimumFaceArea = max(0, minimumFaceArea)
    }

    public static let diorama = VoxelRenderOptions()

    public static let clean = VoxelRenderOptions(
        showGrid: false,
        showAxes: false,
        showObjectHalo: false
    )

    public static let technical = VoxelRenderOptions(
        showGrid: true,
        showAxes: true,
        showObjectHalo: true,
        showShadows: true,
        outlineFaces: true,
        gridExtent: 96,
        gridStep: 2
    )
}

// MARK: - Draw commands

public struct VoxelRenderFace: Identifiable, Sendable {
    public let id: Int
    public let points: [Vec2]
    public let depth: Double
    public let color: VoxelColor
    public let material: VoxelMaterial
    public let objectID: String
}

public struct VoxelRenderLine: Identifiable, Sendable {
    public let id: Int
    public let from: Vec2
    public let to: Vec2
    public let depth: Double
    public let color: VoxelColor
    public let isAxis: Bool
    public let label: String?
}

public struct VoxelRenderAnchor: Identifiable, Sendable {
    public let id: String
    public let center: Vec2
    public let radius: Double
    public let depth: Double
    public let label: String
    public let kind: VoxelObjectKind
    public let selectable: Bool
    public let accent: VoxelColor
}

public struct VoxelSceneSnapshot: Sendable {
    public let faces: [VoxelRenderFace]
    public let lines: [VoxelRenderLine]
    public let anchors: [VoxelRenderAnchor]
    public let camera: VoxelCamera
    public let viewport: Vec2
    public let voxelCount: Int
    public let visibleVoxelCount: Int
    public let objectCount: Int
    public let visibleObjectCount: Int
    public let renderMilliseconds: Double
    public let nearestObjectID: String?

    public func object(at point: Vec2) -> VoxelRenderAnchor? {
        let candidates = anchors
            .filter(\.selectable)
            .filter { $0.center.distance(to: point) <= max(20, $0.radius) }
            .sorted { lhs, rhs in
                let left = lhs.center.distance(to: point) / max(1, lhs.radius)
                let right = rhs.center.distance(to: point) / max(1, rhs.radius)
                if abs(left - right) < 0.08 {
                    return lhs.depth < rhs.depth
                }
                return left < right
            }
        return candidates.first
    }
}

// MARK: - Renderer

public enum VoxelRenderer {
    public static func render(
        objects: [VoxelSceneObject],
        models: [String: VoxelModel],
        camera: VoxelCamera,
        viewport: Vec2,
        light: VoxelLight = VoxelLight(),
        options: VoxelRenderOptions = .diorama,
        faceCache: VoxelFaceCache? = nil
    ) -> VoxelSceneSnapshot {
        let started = Date()
        let eye = camera.position
        var faces: [VoxelRenderFace] = []
        var anchors: [VoxelRenderAnchor] = []
        var visibleVoxels = 0
        var visibleObjects = 0
        var faceID = 0
        var totalVoxels = 0
        faces.reserveCapacity(min(options.maximumFaces, 6_000))
        anchors.reserveCapacity(objects.count)

        for object in objects {
            guard let model = models[object.modelID] else { continue }
            totalVoxels += model.voxelCount
            let modelFaces = faceCache?.faces(for: model) ?? model.surfaceFaces()
            var objectDrewAnything = false

            let centerWorld = (model.bounds.center - model.anchor) * object.scale
            let center = centerWorld.rotatedY(radians: object.rotationY) + object.position
            let projectedCenter = camera.project(center, viewport: viewport)
            let radiusWorld = max(
                model.boundingSize.x,
                model.boundingSize.y,
                model.boundingSize.z
            ) * object.scale * 0.58
            if projectedCenter.visible, projectedCenter.depth > options.minimumDepth {
                anchors.append(
                    VoxelRenderAnchor(
                        id: object.id,
                        center: projectedCenter.point,
                        radius: max(13, radiusWorld * projectedCenter.scale * 0.92),
                        depth: projectedCenter.depth,
                        label: object.label,
                        kind: object.kind,
                        selectable: object.selectable,
                        accent: object.accent
                    )
                )
            }

            for face in modelFaces {
                if faces.count >= options.maximumFaces { break }
                let rotation = object.rotationY
                let anchor = model.anchor
                let worldCorners = face.corners.map { corner -> Vec3 in
                    ((corner - anchor) * object.scale)
                        .rotatedY(radians: rotation)
                        + object.position
                }
                let normal = face.normal.rotatedY(radians: rotation)
                let faceCenter = worldCorners.reduce(.zero, +) / Double(worldCorners.count)
                let toEye = eye - faceCenter
                guard normal.dot(toEye) > 0.000_1 else { continue }

                var projected: [Vec2] = []
                projected.reserveCapacity(4)
                var totalDepth = 0.0
                var visible = true
                for corner in worldCorners {
                    let result = camera.project(corner, viewport: viewport)
                    guard result.visible, result.depth > options.minimumDepth else {
                        visible = false
                        break
                    }
                    projected.append(result.point)
                    totalDepth += result.depth
                }
                guard visible, projected.count == 4 else { continue }
                if options.minimumFaceArea > 0 {
                    let area = polygonArea(projected)
                    guard area >= options.minimumFaceArea else { continue }
                }
                let depth = totalDepth / 4
                let shade = light.shade(face.color, normal: normal, material: face.material)
                faces.append(
                    VoxelRenderFace(
                        id: faceID,
                        points: projected,
                        depth: depth,
                        color: shade,
                        material: face.material,
                        objectID: object.id
                    )
                )
                faceID += 1
                objectDrewAnything = true
            }

            if objectDrewAnything {
                visibleObjects += 1
                visibleVoxels += model.voxelCount
            }
        }

        // Painter's algorithm: distant faces first, near faces last.
        faces.sort { $0.depth > $1.depth }
        anchors.sort { $0.depth < $1.depth }

        var lines: [VoxelRenderLine] = []
        if options.showGrid {
            lines.append(contentsOf: gridLines(camera: camera, viewport: viewport, options: options))
        }
        if options.showAxes {
            lines.append(contentsOf: axisLines(camera: camera, viewport: viewport, options: options))
        }

        let elapsed = Date().timeIntervalSince(started) * 1000
        return VoxelSceneSnapshot(
            faces: faces,
            lines: lines,
            anchors: anchors,
            camera: camera,
            viewport: viewport,
            voxelCount: totalVoxels,
            visibleVoxelCount: visibleVoxels,
            objectCount: objects.count,
            visibleObjectCount: visibleObjects,
            renderMilliseconds: elapsed,
            nearestObjectID: anchors.first(where: \.selectable)?.id
        )
    }

    private static func polygonArea(_ points: [Vec2]) -> Double {
        guard points.count >= 3 else { return 0 }
        var sum = 0.0
        for index in points.indices {
            let next = points[(index + 1) % points.count]
            sum += points[index].x * next.y - next.x * points[index].y
        }
        return abs(sum) * 0.5
    }

    private static func gridLines(
        camera: VoxelCamera,
        viewport: Vec2,
        options: VoxelRenderOptions
    ) -> [VoxelRenderLine] {
        var lines: [VoxelRenderLine] = []
        let extent = options.gridExtent
        let step = options.gridStep
        let major = VoxelColor(hex: "5D725C").withAlpha(0.24)
        let minor = VoxelColor(hex: "5D725C").withAlpha(0.1)
        var index = -extent
        var id = 0
        while index <= extent {
            let tint = index % (step * 4) == 0 ? major : minor
            for axis in 0...1 {
                let start: Vec3
                let end: Vec3
                if axis == 0 {
                    start = Vec3(Double(index), 0, Double(-extent))
                    end = Vec3(Double(index), 0, Double(extent))
                } else {
                    start = Vec3(Double(-extent), 0, Double(index))
                    end = Vec3(Double(extent), 0, Double(index))
                }
                let a = camera.project(start, viewport: viewport)
                let b = camera.project(end, viewport: viewport)
                if a.visible, b.visible {
                    lines.append(
                        VoxelRenderLine(
                            id: id,
                            from: a.point,
                            to: b.point,
                            depth: (a.depth + b.depth) * 0.5,
                            color: tint,
                            isAxis: false,
                            label: nil
                        )
                    )
                    id += 1
                }
            }
            index += step
        }
        return lines
    }

    private static func axisLines(
        camera: VoxelCamera,
        viewport: Vec2,
        options: VoxelRenderOptions
    ) -> [VoxelRenderLine] {
        var lines: [VoxelRenderLine] = []
        let origin = Vec3(0, 0.02, 0)
        let axes: [(Vec3, VoxelColor, String)] = [
            (Vec3(options.axisLength, 0, 0), VoxelColor(hex: "D95D4F"), "X"),
            (Vec3(0, options.axisLength, 0), VoxelColor(hex: "5A9B69"), "Y"),
            (Vec3(0, 0, options.axisLength), VoxelColor(hex: "4F7FA8"), "Z")
        ]
        for (index, axis) in axes.enumerated() {
            let start = camera.project(origin, viewport: viewport)
            let end = camera.project(axis.0, viewport: viewport)
            guard start.visible, end.visible else { continue }
            lines.append(
                VoxelRenderLine(
                    id: index,
                    from: start.point,
                    to: end.point,
                    depth: end.depth,
                    color: axis.1,
                    isAxis: true,
                    label: axis.2
                )
            )
        }
        return lines
    }
}

// MARK: - World lighting presets

public enum VoxelLightPreset: String, CaseIterable, Sendable, Identifiable {
    case morning
    case noon
    case goldenHour
    case night
    case storm

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .morning: return "Morning"
        case .noon: return "Noon"
        case .goldenHour: return "Golden hour"
        case .night: return "Night"
        case .storm: return "Storm"
        }
    }

    public var light: VoxelLight {
        switch self {
        case .morning:
            return VoxelLight(
                sunDirection: Vec3(-0.62, 0.44, 0.34).normalized(),
                ambient: 0.48,
                diffuse: 0.58,
                rim: 0.1,
                warmth: 0.13
            )
        case .noon:
            return VoxelLight(
                sunDirection: Vec3(-0.18, 0.95, 0.22).normalized(),
                ambient: 0.56,
                diffuse: 0.48,
                rim: 0.07,
                warmth: 0.02
            )
        case .goldenHour:
            return VoxelLight(
                sunDirection: Vec3(-0.78, 0.28, 0.26).normalized(),
                ambient: 0.44,
                diffuse: 0.66,
                rim: 0.16,
                warmth: 0.24
            )
        case .night:
            return VoxelLight(
                sunDirection: Vec3(-0.2, 0.72, 0.18).normalized(),
                ambient: 0.28,
                diffuse: 0.28,
                rim: 0.12,
                warmth: -0.14
            )
        case .storm:
            return VoxelLight(
                sunDirection: Vec3(-0.42, 0.62, 0.1).normalized(),
                ambient: 0.4,
                diffuse: 0.34,
                rim: 0.08,
                warmth: -0.2
            )
        }
    }

    public var skyTop: VoxelColor {
        switch self {
        case .morning: return VoxelColor(hex: "BFE3EE")
        case .noon: return VoxelColor(hex: "A9D9EE")
        case .goldenHour: return VoxelColor(hex: "F0B47D")
        case .night: return VoxelColor(hex: "24334E")
        case .storm: return VoxelColor(hex: "6C7D8D")
        }
    }

    public var skyBottom: VoxelColor {
        switch self {
        case .morning: return VoxelColor(hex: "F4E5C5")
        case .noon: return VoxelColor(hex: "EAF1D8")
        case .goldenHour: return VoxelColor(hex: "F7D9A2")
        case .night: return VoxelColor(hex: "40516B")
        case .storm: return VoxelColor(hex: "AEB7B5")
        }
    }

    public func options(base: VoxelRenderOptions = .diorama) -> VoxelRenderOptions {
        var copy = base
        copy.backgroundTop = skyTop
        copy.backgroundBottom = skyBottom
        copy.horizon = skyBottom.mixed(with: VoxelColor(hex: "8FAE74"), amount: 0.34)
        return copy
    }
}
