#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

// MARK: - Hollow 3D

/// A tactile voxel diorama of the whole farm. Every tree, animal, crop and
/// building is a real voxel model with an XYZ position. The camera orbits,
/// pinches, and picks individual objects; the axis gizmo and grid make the
/// coordinate system explicit rather than decorative.
public struct World3DView: View {
    @EnvironmentObject private var store: GameStore

    @State private var camera = VoxelCameraPreset.overview.camera()
    @State private var activePreset: VoxelCameraPreset? = .overview
    @State private var selectedObjectID: String?
    @State private var showGrid = true
    @State private var showAxes = true
    @State private var outlineFaces = true
    @State private var showLibrary = false
    @State private var showDetails = false
    @State private var isInteracting = false
    @State private var faceCache = VoxelFaceCache()
    @State private var cachedWorld = World3DView.placeholderWorld
    @State private var isBuildingWorld = true

    public init() {}

    /// Building the full voxel diorama is deliberately cached. Rebuilding all
    /// 170k voxels on every SwiftUI body pass made the page block the main
    /// thread long enough for the simulator watchdog to kill the app.
    private var worldSignature: String {
        let crops = store.state.plots.compactMap(\.crop)
        let animals = store.state.pens.compactMap(\.animal)
        return [
            String(store.state.day),
            String(store.state.level),
            store.state.weather.rawValue,
            store.state.season.rawValue,
            String(store.state.unlockedPlots),
            String(store.state.unlockedPens),
            String(crops.count),
            String(animals.count),
            String(animals.reduce(0) { $0 + $1.stored })
        ].joined(separator: "|")
    }

    private var world: VoxelFarmWorld { cachedWorld }

    private static let placeholderWorld = VoxelFarmWorld(
        objects: [],
        models: [:],
        weather: .sunny,
        day: 1,
        season: .spring,
        lightPreset: .noon,
        defaults: .diorama,
        residentCount: 0,
        cropCount: 0,
        landmarkCount: 0
    )

    private var options: VoxelRenderOptions {
        var resolved = world.lightPreset.options(base: world.defaults)
        resolved.showGrid = showGrid
        resolved.showAxes = showAxes
        resolved.outlineFaces = outlineFaces
        resolved.maximumFaces = 50_000
        // Use a coarser face LOD while the user is dragging or pinching, then
        // draw the full detail as soon as the gesture settles. The per-object
        // budget keeps every landmark visible even when the barn is close.
        resolved.minimumFaceArea = isInteracting ? 1.2 : 0.4
        resolved.perObjectFaceLimit = camera.distance > 26 ? 900 : 0
        return resolved
    }

    private var selectedObject: VoxelSceneObject? {
        guard let selectedObjectID else { return nil }
        return world.object(selectedObjectID)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                hero
                presetBar
                scene
                if let selectedObject {
                    selectedCard(selectedObject)
                }
                inspector
                legend
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showLibrary) {
            VoxelModelLibrarySheet()
        }
        .sheet(isPresented: $showDetails) {
            VoxelDetailsSheet(
                world: world,
                selectedObjectID: selectedObjectID,
                camera: $camera
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: store.state.day) { _, _ in
            selectedObjectID = nil
        }
        .task(id: worldSignature) {
            isBuildingWorld = true
            await Task.yield()
            let built = VoxelWorldBuilder.build(state: store.state)
            cachedWorld = built
            isBuildingWorld = false
        }
    }

    // MARK: Hero

    private var hero: some View {
        CozyCard(padding: 15) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4F7FA8"), Color(hex: "8FC3DD")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "cube.fill")
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 55, height: 55)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text("Hollow 3D")
                            .font(.hhTitle(25))
                            .foregroundStyle(HHTheme.ink)
                        Text("XYZ")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(hex: "4F7FA8"), in: Capsule())
                    }
                    Text("A complete miniature of your farm, sculpted one small voxel at a time. Drag to orbit, pinch to zoom, tap any resident.")
                        .font(.hhCaption(12))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        TagChip("\(world.objectCount) objects", icon: "cube.transparent", tint: Color(hex: "4F7FA8"))
                        TagChip("\(world.totalVoxels.formatted()) voxels", icon: "square.grid.3x3.fill", tint: HHTheme.forest)
                    }
                    .padding(.top, 2)
                    Text("One voxel is ten centimetres. Select any object to inspect its coordinates.")
                        .font(.hhCaption(10.5))
                        .foregroundStyle(HHTheme.muted.opacity(0.9))
                        .padding(.top, 1)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Camera presets

    private var presetBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VoxelCameraPreset.allCases) { preset in
                    Button {
                        activePreset = preset
                        withAnimation(.easeInOut(duration: 0.32)) {
                            camera = preset.camera()
                        }
                        selectedObjectID = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(preset.title)
                                .font(.hhCaption(11))
                                .lineLimit(1)
                        }
                        .foregroundStyle(activePreset == preset ? .white : HHTheme.forest)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(
                            activePreset == preset ? HHTheme.forest : HHTheme.paper,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(HHTheme.forest.opacity(activePreset == preset ? 0 : 0.17), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: Scene

    private var scene: some View {
        ZStack(alignment: .topTrailing) {
            WorldSceneCanvas(
                world: world,
                camera: $camera,
                options: options,
                selectedObjectID: selectedObjectID,
                faceCache: faceCache,
                onSelect: { anchor in
                    withAnimation(.easeOut(duration: 0.18)) {
                        selectedObjectID = anchor?.id
                    }
                    if anchor == nil {
                        showDetails = false
                    }
                },
                onCameraMoved: {
                    activePreset = nil
                },
                onInteractionChanged: { interacting in
                    isInteracting = interacting
                }
            )
            .frame(height: 492)
            .background(
                LinearGradient(
                    colors: [
                        options.backgroundTop.hhColor,
                        options.backgroundBottom.hhColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(HHTheme.ink.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: HHTheme.soilDark.opacity(0.2), radius: 16, y: 8)
            .overlay {
                if isBuildingWorld {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(hex: "BFE3EE").opacity(0.92))
                        VStack(spacing: 9) {
                            ProgressView()
                                .tint(HHTheme.forest)
                            Text("Stacking voxels…")
                                .font(.hhCaption(12))
                                .foregroundStyle(HHTheme.muted)
                        }
                    }
                }
            }

            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Text(world.lightPreset.title)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.ink)
                    Circle()
                        .fill(Color(hex: world.lightPreset.skyTop.hex))
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())

                Button {
                    activePreset = .overview
                    withAnimation(.easeInOut(duration: 0.3)) {
                        camera = VoxelCameraPreset.overview.camera()
                    }
                    selectedObjectID = nil
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(HHTheme.ink)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset camera")
            }
            .padding(12)

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    AxisGizmo()
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DRAG · ORBIT")
                        Text("PINCH · ZOOM")
                        Text("TAP · INSPECT")
                    }
                    .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(HHTheme.ink.opacity(0.44))
                }
                .padding(12)
            }
        }
    }

    // MARK: Selected object

    private func selectedCard(_ object: VoxelSceneObject) -> some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: icon(for: object.kind))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(object.accent.hhColor)
                        .frame(width: 36, height: 36)
                        .background(object.accent.hhColor.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(object.label)
                            .font(.hhHeadline(17))
                            .foregroundStyle(HHTheme.ink)
                        Text(object.kind.title)
                            .font(.hhCaption(11))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button {
                        selectedObjectID = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(HHTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
                if !object.detail.isEmpty {
                    Text(object.detail)
                        .font(.hhBody(13))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let model = world.model(for: object) {
                    HStack(spacing: 7) {
                        TagChip("\(model.voxelCount) voxels", icon: "square.grid.3x3.fill", tint: HHTheme.forest)
                        TagChip("\(model.surfaceFaceCount) faces", icon: "triangle.fill", tint: HHTheme.terracotta)
                        TagChip("\(model.bounds.width)×\(model.bounds.height)×\(model.bounds.depth)", icon: "ruler", tint: HHTheme.lavender)
                        Spacer(minLength: 0)
                    }
                }
                HStack(spacing: 8) {
                    Button("Focus camera") {
                        focus(on: object)
                    }
                    .buttonStyle(CozyCompactButtonStyle(tint: HHTheme.forest))
                    Button("Model details") {
                        showDetails = true
                    }
                    .buttonStyle(CozyCompactButtonStyle(tint: Color(hex: "4F7FA8")))
                    Spacer(minLength: 0)
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Inspector

    private var inspector: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    "Build inspector",
                    subtitle: "Every object has a real position, rotation, scale and voxel count.",
                    icon: "cube.transparent",
                    accent: Color(hex: "4F7FA8")
                )
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                    metric("Objects", "\(world.objectCount)", "cube.fill", HHTheme.forest)
                    metric("Voxels placed", world.totalVoxels.formatted(), "square.grid.3x3.fill", Color(hex: "4F7FA8"))
                    metric("Residents", "\(world.residentCount)", "pawprint.fill", HHTheme.terracotta)
                    metric("Crop rows", "\(world.cropCount)", "leaf.fill", HHTheme.leaf)
                }
                HStack(spacing: 8) {
                    toggleChip("Grid", icon: "square.grid.3x3", isOn: $showGrid)
                    toggleChip("XYZ axes", icon: "move.3d", isOn: $showAxes)
                    toggleChip("Edges", icon: "triangle", isOn: $outlineFaces)
                    Spacer(minLength: 0)
                    Button {
                        showLibrary = true
                    } label: {
                        Label("Model kit", systemImage: "books.vertical.fill")
                            .font(.hhCaption(11.5))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Color(hex: "4F7FA8"), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                HStack(spacing: 6) {
                    Image(systemName: "ruler")
                    Text("Model space is 1/10 world scale. The average animal has \(VoxelModelLibrary.averageAnimalVoxels) voxels.")
                }
                .font(.hhCaption(10.5))
                .foregroundStyle(HHTheme.muted)
            }
        }
    }

    private func metric(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 27, height: 27)
                .background(tint.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.hhHeadline(15))
                    .foregroundStyle(HHTheme.ink)
                Text(title)
                    .font(.hhCaption(10))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(HHTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func toggleChip(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Label(title, systemImage: icon)
                .font(.hhCaption(10.5))
                .foregroundStyle(isOn.wrappedValue ? .white : HHTheme.muted)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(isOn.wrappedValue ? HHTheme.forest : HHTheme.cream, in: Capsule())
                .overlay(Capsule().stroke(HHTheme.ink.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Legend

    private var legend: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    "XYZ, explained",
                    subtitle: "The red, green and blue arrows in the scene are the world axes.",
                    icon: "move.3d",
                    accent: HHTheme.lavender
                )
                HStack(spacing: 8) {
                    axisChip("X", "east ↔ west", "D95D4F")
                    axisChip("Y", "up ↕ down", "5A9B69")
                    axisChip("Z", "north ↔ south", "4F7FA8")
                }
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .foregroundStyle(HHTheme.forest)
                    Text("Tap a resident or landmark to inspect its model. Use Focus camera to frame it without losing the overview.")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(9)
                .background(HHTheme.forest.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func axisChip(_ letter: String, _ detail: String, _ hex: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(letter)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: hex))
            Text(detail)
                .font(.hhCaption(9.5))
                .foregroundStyle(HHTheme.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color(hex: hex).opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func icon(for kind: VoxelObjectKind) -> String {
        switch kind {
        case .animal: return "pawprint.fill"
        case .building: return "house.fill"
        case .nature: return "tree.fill"
        case .prop: return "shippingbox.fill"
        case .crop: return "leaf.fill"
        case .avatar: return "figure.stand"
        case .landmark: return "mappin.and.ellipse"
        }
    }

    private func focus(on object: VoxelSceneObject) {
        guard let model = world.model(for: object) else { return }
        let span = Double(max(model.bounds.width, model.bounds.height, model.bounds.depth)) * object.scale
        let height = Double(model.bounds.height) * object.scale
        let target = object.position + Vec3(0, height * 0.42, 0)
        withAnimation(.easeInOut(duration: 0.34)) {
            camera = VoxelCamera(
                target: target,
                yaw: camera.yaw,
                pitch: min(0.72, max(0.22, camera.pitch)),
                distance: max(6.5, span * 3.6)
            )
        }
    }
}

// MARK: - Scene canvas

private struct WorldSceneCanvas: View {
    let world: VoxelFarmWorld
    @Binding var camera: VoxelCamera
    let options: VoxelRenderOptions
    let selectedObjectID: String?
    let faceCache: VoxelFaceCache
    let onSelect: (VoxelRenderAnchor?) -> Void
    let onCameraMoved: () -> Void
    let onInteractionChanged: (Bool) -> Void

    @State private var previousTranslation: CGSize = .zero
    @State private var previousMagnification: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            Canvas { context, canvasSize in
                let viewport = Vec2(Double(canvasSize.width), Double(canvasSize.height))
                let snapshot = world.render(
                    camera: camera,
                    viewport: viewport,
                    options: options,
                    cache: faceCache
                )
                WorldScenePainter.paint(
                    snapshot: snapshot,
                    in: &context,
                    size: canvasSize,
                    options: options,
                    selectedObjectID: selectedObjectID
                )
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        let dx = value.translation.width - previousTranslation.width
                        let dy = value.translation.height - previousTranslation.height
                        previousTranslation = value.translation
                        camera = camera.orbit(
                            deltaYaw: Double(dx) * 0.0075,
                            deltaPitch: -Double(dy) * 0.0055
                        )
                        onCameraMoved()
                        onInteractionChanged(true)
                    }
                    .onEnded { _ in
                        previousTranslation = .zero
                        onInteractionChanged(false)
                    }
            )
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let viewport = Vec2(Double(size.width), Double(size.height))
                        let snapshot = world.render(
                            camera: camera,
                            viewport: viewport,
                            options: options,
                            cache: faceCache
                        )
                        onSelect(snapshot.object(at: Vec2(Double(value.location.x), Double(value.location.y))))
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / previousMagnification
                        previousMagnification = value
                        guard delta.isFinite, delta > 0 else { return }
                        camera = camera.zoomed(by: 1 / Double(delta))
                        onCameraMoved()
                        onInteractionChanged(true)
                    }
                    .onEnded { _ in
                        previousMagnification = 1
                        onInteractionChanged(false)
                    }
            )
        }
    }
}

// MARK: - Painter

private enum WorldScenePainter {
    static func paint(
        snapshot: VoxelSceneSnapshot,
        in context: inout GraphicsContext,
        size: CGSize,
        options: VoxelRenderOptions,
        selectedObjectID: String?
    ) {
        // Sky and horizon wash.
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    options.backgroundTop.hhColor,
                    options.backgroundBottom.hhColor
                ]),
                startPoint: CGPoint(x: size.width * 0.5, y: 0),
                endPoint: CGPoint(x: size.width * 0.5, y: size.height)
            )
        )
        context.fill(
            Path(CGRect(x: 0, y: size.height * 0.56, width: size.width, height: size.height * 0.44)),
            with: .color(options.horizon.hhColor.opacity(0.42))
        )

        // Grid and axes sit behind the models. The renderer has already
        // projected every endpoint through the same camera as the voxels.
        for line in snapshot.lines {
            var path = Path()
            path.move(to: CGPoint(x: line.from.x, y: line.from.y))
            path.addLine(to: CGPoint(x: line.to.x, y: line.to.y))
            context.stroke(
                path,
                with: .color(line.color.hhColor),
                lineWidth: line.isAxis ? 2.4 : 0.8
            )
        }

        // Voxel faces, sorted back to front by the core renderer.
        for face in snapshot.faces {
            guard face.points.count >= 3 else { continue }
            var path = Path()
            path.move(to: CGPoint(x: face.points[0].x, y: face.points[0].y))
            for point in face.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            path.closeSubpath()
            context.fill(path, with: .color(face.color.hhColor))
            if options.outlineFaces {
                context.stroke(
                    path,
                    with: .color(face.color.scaled(by: 0.72).hhColor.opacity(0.36)),
                    lineWidth: 0.45
                )
            }
        }

        // Selection ring and gentle attention dot.
        if let selectedObjectID,
           let anchor = snapshot.anchors.first(where: { $0.id == selectedObjectID }) {
            let ring = CGRect(
                x: CGFloat(anchor.center.x) - CGFloat(anchor.radius) * 0.86,
                y: CGFloat(anchor.center.y) - CGFloat(anchor.radius) * 0.86,
                width: CGFloat(anchor.radius) * 1.72,
                height: CGFloat(anchor.radius) * 1.72
            )
            context.stroke(
                Path(ellipseIn: ring),
                with: .color(HHTheme.gold),
                lineWidth: 2.2
            )
            context.fill(
                Path(ellipseIn: CGRect(
                    x: CGFloat(anchor.center.x) - 3,
                    y: CGFloat(anchor.center.y) - 3,
                    width: 6,
                    height: 6
                )),
                with: .color(HHTheme.goldDeep)
            )
        }
    }
}

// MARK: - Axis gizmo

private struct AxisGizmo: View {
    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: 28, y: size.height - 21)
            let length: CGFloat = 19
            let axes: [(CGPoint, Color, String)] = [
                (CGPoint(x: origin.x + length, y: origin.y), Color(hex: "D95D4F"), "X"),
                (CGPoint(x: origin.x, y: origin.y - length), Color(hex: "5A9B69"), "Y"),
                (CGPoint(x: origin.x + length * 0.55, y: origin.y + length * 0.58), Color(hex: "4F7FA8"), "Z")
            ]
            for axis in axes {
                var path = Path()
                path.move(to: origin)
                path.addLine(to: axis.0)
                context.stroke(path, with: .color(axis.1), lineWidth: 2)
                context.fill(
                    Path(ellipseIn: CGRect(x: axis.0.x - 2.5, y: axis.0.y - 2.5, width: 5, height: 5)),
                    with: .color(axis.1)
                )
                context.draw(
                    Text(axis.2)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundColor(axis.1),
                    at: CGPoint(
                        x: axis.0.x + (axis.2 == "X" ? 8 : axis.2 == "Y" ? -2 : 6),
                        y: axis.0.y + (axis.2 == "Y" ? -8 : -3)
                    )
                )
            }
            context.fill(
                Path(ellipseIn: CGRect(x: origin.x - 2, y: origin.y - 2, width: 4, height: 4)),
                with: .color(HHTheme.ink.opacity(0.55))
            )
        }
        .frame(width: 62, height: 56)
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - Model library sheet

private struct VoxelModelLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: VoxelCategory = .animal

    private var summaries: [VoxelModelSummary] {
        VoxelModelInspector.summaries()
    }

    private var filtered: [VoxelModelSummary] {
        summaries.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        libraryStat("\(VoxelModelLibrary.modelCount)", "models")
                        libraryStat("\(VoxelModelLibrary.totalVoxels.formatted())", "voxels")
                        libraryStat("\(VoxelModelLibrary.averageAnimalVoxels)", "avg animal")
                    }
                    .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(VoxelCategory.allCases) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Text(category.title)
                                        .font(.hhCaption(11))
                                        .foregroundStyle(selectedCategory == category ? .white : HHTheme.forest)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 7)
                                        .background(
                                            selectedCategory == category ? HHTheme.forest : HHTheme.paper,
                                            in: Capsule()
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    LazyVStack(spacing: 8) {
                        ForEach(filtered) { summary in
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(HHTheme.forest.opacity(0.09))
                                    Image(systemName: "cube.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(HHTheme.forest)
                                }
                                .frame(width: 34, height: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(summary.name)
                                        .font(.hhHeadline(14))
                                        .foregroundStyle(HHTheme.ink)
                                    Text("\(summary.voxelCount) voxels · \(summary.surfaceFaces) faces · \(summary.dimensions)")
                                        .font(.hhCaption(10.5))
                                        .foregroundStyle(HHTheme.muted)
                                    Text(summary.notes)
                                        .font(.hhCaption(9.5))
                                        .foregroundStyle(HHTheme.muted.opacity(0.8))
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Text("\(summary.width)×\(summary.height)×\(summary.depth)")
                                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(HHTheme.forest)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(HHTheme.forest.opacity(0.08), in: Capsule())
                            }
                            .padding(9)
                            .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            .background(HHTheme.cream)
            .navigationTitle("Voxel model kit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func libraryStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.hhHeadline(15))
                .foregroundStyle(HHTheme.ink)
            Text(label)
                .font(.hhCaption(9.5))
                .foregroundStyle(HHTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Object details sheet

private struct VoxelDetailsSheet: View {
    let world: VoxelFarmWorld
    let selectedObjectID: String?
    @Binding var camera: VoxelCamera

    @Environment(\.dismiss) private var dismiss

    private var object: VoxelSceneObject? {
        guard let selectedObjectID else { return nil }
        return world.object(selectedObjectID)
    }

    private var model: VoxelModel? {
        guard let object else { return nil }
        return world.model(for: object)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let object, let model {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "BFE3EE"), Color(hex: "F4E5C5")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            VoxelObjectPreview(
                                world: world,
                                object: object,
                                camera: camera
                            )
                            .padding(18)
                        }
                        .frame(height: 260)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(object.label)
                                .font(.hhTitle(25))
                                .foregroundStyle(HHTheme.ink)
                            Text(object.detail)
                                .font(.hhBody(14))
                                .foregroundStyle(HHTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 7) {
                                TagChip(object.kind.title, icon: "cube.fill", tint: HHTheme.forest)
                                TagChip("\(model.voxelCount) voxels", icon: "square.grid.3x3.fill", tint: Color(hex: "4F7FA8"))
                                TagChip("\(model.surfaceFaceCount) visible faces", icon: "triangle.fill", tint: HHTheme.terracotta)
                            }
                            HStack(spacing: 7) {
                                TagChip("x \(String(format: "%.2f", object.position.x))", tint: Color(hex: "D95D4F"))
                                TagChip("y \(String(format: "%.2f", object.position.y))", tint: Color(hex: "5A9B69"))
                                TagChip("z \(String(format: "%.2f", object.position.z))", tint: Color(hex: "4F7FA8"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model bounds")
                                .font(.hhHeadline(15))
                                .foregroundStyle(HHTheme.ink)
                            Text("\(model.bounds.width) × \(model.bounds.height) × \(model.bounds.depth) voxels · \(model.voxels.count) individual cubes")
                                .font(.hhCaption(11.5))
                                .foregroundStyle(HHTheme.muted)
                            Text(model.notes)
                                .font(.hhCaption(11))
                                .foregroundStyle(HHTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(HHTheme.cream, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                        Button {
                            let span = Double(max(model.bounds.width, model.bounds.height, model.bounds.depth)) * object.scale
                            let height = Double(model.bounds.height) * object.scale
                            withAnimation(.easeInOut(duration: 0.34)) {
                                camera = VoxelCamera(
                                    target: object.position + Vec3(0, height * 0.42, 0),
                                    yaw: camera.yaw,
                                    pitch: 0.36,
                                    distance: max(6, span * 4)
                                )
                            }
                            dismiss()
                        } label: {
                            Label("Frame in the farm", systemImage: "viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CozyPrimaryButtonStyle())
                    }
                    .padding(16)
                } else {
                    ContentUnavailableView(
                        "Nothing selected",
                        systemImage: "cube.transparent",
                        description: Text("Tap an object in the 3D farm to inspect it.")
                    )
                    .padding(20)
                }
            }
            .background(HHTheme.cream)
            .navigationTitle("Object details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Object preview

private struct VoxelObjectPreview: View {
    let world: VoxelFarmWorld
    let object: VoxelSceneObject
    let camera: VoxelCamera

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard let model = world.model(for: object) else { return }
                let preview = VoxelFarmWorld(
                    objects: [object],
                    models: [object.modelID: model],
                    weather: world.weather,
                    day: world.day,
                    season: world.season,
                    lightPreset: .noon,
                    defaults: .clean,
                    residentCount: 0,
                    cropCount: 0,
                    landmarkCount: 0
                )
                let bounds = model.bounds
                let span = Double(max(bounds.width, bounds.height, bounds.depth)) * object.scale
                let previewCamera = VoxelCamera(
                    target: object.position + Vec3(0, Double(bounds.height) * object.scale * 0.42, 0),
                    yaw: camera.yaw,
                    pitch: 0.32,
                    distance: max(2.5, span * 3.4)
                )
                var options = VoxelRenderOptions.clean
                options.showGrid = false
                options.showAxes = false
                options.minimumFaceArea = 0.05
                let snapshot = preview.render(
                    camera: previewCamera,
                    viewport: Vec2(Double(size.width), Double(size.height)),
                    options: options
                )
                for face in snapshot.faces {
                    guard face.points.count >= 3 else { continue }
                    var path = Path()
                    path.move(to: CGPoint(x: face.points[0].x, y: face.points[0].y))
                    for point in face.points.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x, y: point.y))
                    }
                    path.closeSubpath()
                    context.fill(path, with: .color(face.color.hhColor))
                }
                _ = geometry
            }
        }
    }
}

// MARK: - Color bridge

private extension VoxelColor {
    var hhColor: Color {
        Color(
            red: redUnit,
            green: greenUnit,
            blue: blueUnit,
            opacity: alphaUnit
        )
    }
}

private struct CozyCompactButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hhCaption(11.5))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
    }
}

#endif
