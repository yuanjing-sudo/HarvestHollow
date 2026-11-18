import XCTest
@testable import HarvestHollowCore

final class ArcadeVoxelTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - Voxel models

    func testThePigIsBuiltFromMoreThanOneHundredVoxels() throws {
        let pig = try XCTUnwrap(VoxelModelLibrary.model("animal.pig"))
        XCTAssertGreaterThan(pig.voxelCount, 100)
        XCTAssertGreaterThan(pig.surfaceFaceCount, 100)
        XCTAssertGreaterThan(pig.bounds.width, 5)
        XCTAssertGreaterThan(pig.bounds.height, 5)
        XCTAssertGreaterThan(pig.bounds.depth, 5)
        XCTAssertTrue(pig.notes.contains("voxels"))
    }

    func testModelLibraryHasEveryCategoryAndUniqueIdentifiers() {
        let all = VoxelModelLibrary.all
        XCTAssertGreaterThanOrEqual(all.count, 70)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertGreaterThan(VoxelModelLibrary.averageAnimalVoxels, 100)
        for category in VoxelCategory.allCases {
            XCTAssertFalse(VoxelModelLibrary.models(in: category).isEmpty, category.rawValue)
        }
    }

    func testModelCodecParsesCompactRowsAndMaterials() {
        let model = VoxelModelCodec.make(
            id: "test.cube",
            name: "Test Cube",
            category: .prop,
            notes: "A test.",
            rows: """
            0,0,0,FF0000,wood
            1,0,0,00FF00,stone
            2,0,0,0000FF,metal
            """
        )
        XCTAssertEqual(model.voxelCount, 3)
        XCTAssertEqual(model.bounds.width, 3)
        XCTAssertEqual(model.voxels[0].color.red, 255)
        XCTAssertEqual(model.voxels[1].material, .stone)
        XCTAssertEqual(model.surfaceFaceCount, 14)
    }

    func testCameraProjectionOrbitAndFitStayFinite() {
        let camera = VoxelCamera(target: Vec3(1, 2, 3), yaw: -0.6, pitch: 0.4, distance: 20)
        let projection = camera.project(Vec3(0, 0, 0), viewport: Vec2(390, 500))
        XCTAssertTrue(projection.visible)
        XCTAssertTrue(projection.depth > 0)
        XCTAssertTrue(projection.point.x.isFinite)
        XCTAssertTrue(projection.point.y.isFinite)

        let orbited = camera.orbit(deltaYaw: 1.2, deltaPitch: 4)
        XCTAssertLessThanOrEqual(orbited.pitch, 1.16)
        let zoomed = camera.zoomed(by: 0.0001)
        XCTAssertGreaterThanOrEqual(zoomed.distance, 3.5)
        let fitted = VoxelCamera.fitting(bounds: VoxelBounds(
            minimum: VoxelKey(x: -10, y: 0, z: -10),
            maximum: VoxelKey(x: 10, y: 20, z: 10)
        ))
        XCTAssertGreaterThan(fitted.distance, 10)
    }

    func testRendererCullsBackFacesAndSortsDepth() {
        let voxel = Voxel(x: 0, y: 0, z: 0, hex: "FFAA33", material: .wood)
        let model = VoxelModel(id: "test.cube", name: "Cube", category: .prop, voxels: [voxel])
        let object = VoxelSceneObject(
            id: "cube",
            modelID: "test.cube",
            position: Vec3(0, 0, 0),
            scale: 1,
            label: "Cube"
        )
        let camera = VoxelCamera(target: Vec3(0, 0, 0), yaw: 0.7, pitch: 0.35, distance: 9)
        let snapshot = VoxelRenderer.render(
            objects: [object],
            models: ["test.cube": model],
            camera: camera,
            viewport: Vec2(400, 400)
        )
        XCTAssertGreaterThan(snapshot.faces.count, 0)
        XCTAssertLessThanOrEqual(snapshot.faces.count, 3)
        XCTAssertEqual(snapshot.anchors.count, 1)
        XCTAssertEqual(snapshot.voxelCount, 1)
        XCTAssertEqual(snapshot.visibleObjectCount, 1)
        for (index, face) in snapshot.faces.enumerated() where index > 0 {
            XCTAssertGreaterThanOrEqual(snapshot.faces[index - 1].depth, face.depth)
        }
        let picked = snapshot.object(at: snapshot.anchors[0].center)
        XCTAssertEqual(picked?.id, "cube")
    }

    func testFaceCacheBuildsOnceAndReturnsStableFaces() {
        let model = VoxelModelLibrary.model("animal.chicken")!
        let cache = VoxelFaceCache()
        let first = cache.faces(for: model)
        let second = cache.faces(for: model)
        XCTAssertEqual(first.count, second.count)
        XCTAssertGreaterThan(first.count, 0)
        XCTAssertEqual(cache.cachedModelCount, 1)
        XCTAssertEqual(cache.cachedFaceCount, first.count)
    }

    // MARK: - World

    func testWorldBuildsAPlayableDioramaWithRealObjects() {
        var state = GameState.newGame(now: fixedDate, seed: 4)
        state.clock = GameConstants.dayLength * 0.75
        let world = VoxelWorldBuilder.build(state: state)
        XCTAssertGreaterThan(world.objectCount, 20)
        XCTAssertGreaterThan(world.totalVoxels, 10_000)
        XCTAssertFalse(world.models.isEmpty)
        XCTAssertEqual(world.day, state.day)
        XCTAssertTrue(world.objects.contains { $0.kind == .building })
        XCTAssertTrue(world.objects.contains { $0.kind == .animal })
        XCTAssertTrue(world.objects.contains { $0.kind == .crop })
        XCTAssertTrue(world.objects.contains { $0.kind == .nature })
        XCTAssertNotNil(world.object("building.barn"))
        XCTAssertNotNil(world.object("nature.pondwater"))
        XCTAssertTrue(world.objects.contains { $0.label == "Willow Pond" })

        let camera = world.camera(for: .barn)
        let snapshot = world.render(
            camera: camera,
            viewport: Vec2(390, 500),
            options: .diorama,
            cache: VoxelFaceCache()
        )
        XCTAssertGreaterThan(snapshot.faces.count, 0)
        XCTAssertGreaterThan(snapshot.anchors.count, 0)
        XCTAssertEqual(snapshot.objectCount, world.objectCount)
    }

    func testWorldFollowsPlantedCropsAndAnimalPens() {
        var state = GameState.newGame(now: fixedDate, seed: 9)
        state.plots[0].crop = CropInstance(cropID: "carrot", growth: 0.5)
        state.plots[0].unlocked = true
        state.pens[0].animal = AnimalInstance(
            id: UUID(),
            speciesID: "chicken",
            name: "Mabel",
            fedUntil: nil,
            progress: 0.3,
            stored: 1,
            happiness: 80,
            acquiredAt: fixedDate,
            affection: 70
        )
        let world = VoxelWorldBuilder.build(state: state)
        XCTAssertTrue(world.objects.contains { $0.id.hasPrefix("animal.") && $0.label == "Mabel" })
        XCTAssertTrue(world.objects.contains { $0.modelID == "crop.carrot" })
        XCTAssertGreaterThanOrEqual(world.residentCount, 1)
        XCTAssertGreaterThanOrEqual(world.cropCount, 1)
    }

    // MARK: - Meadow levels and run

    func testMeadowCatalogHasSixteenDistinctDeterministicLevels() {
        let levels = MeadowLevelCatalog.levels
        XCTAssertEqual(levels.count, 16)
        XCTAssertEqual(Set(levels.map(\.id)).count, 16)
        XCTAssertEqual(levels.first?.index, 1)
        XCTAssertEqual(levels.last?.index, 16)
        XCTAssertEqual(levels, MeadowLevelCatalog.levels)
        for level in levels {
            XCTAssertFalse(level.name.isEmpty)
            XCTAssertGreaterThan(level.length, 1_000)
            XCTAssertGreaterThan(level.baseSpeed, 100)
            XCTAssertGreaterThan(level.goalApples, 0)
            XCTAssertTrue(level.spawns.contains { $0.kind.isObstacle })
            XCTAssertTrue(level.spawns.contains { $0.kind.pickup != nil })
        }
    }

    func testMeadowRunAdvancesJumpDashAndCollisionState() {
        let level = MeadowLevelCatalog.levels[0]
        var run = MeadowRunState(level: level)
        run.start()
        run.update(delta: 0.05)
        XCTAssertGreaterThan(run.distance, 0)
        XCTAssertGreaterThan(run.elapsed, 0)

        run.jump()
        XCTAssertFalse(run.player.isGrounded)
        XCTAssertGreaterThan(run.player.verticalVelocity, 0)
        XCTAssertEqual(run.player.jumpsUsed, 1)
        run.jump()
        XCTAssertEqual(run.player.jumpsUsed, 2)

        run.dash()
        XCTAssertTrue(run.player.isDashing)
        XCTAssertGreaterThan(run.player.dashCooldown, 0)

        var grounded = MeadowRunState(level: level)
        grounded.start()
        grounded.slide()
        XCTAssertTrue(grounded.player.isSliding)
        for _ in 0..<10 {
            grounded.update(delta: 0.08)
        }
        XCTAssertFalse(grounded.player.isSliding)
    }

    func testMeadowRunFinishesAndProducesStars() {
        let level = MeadowLevelCatalog.levels[0]
        var run = MeadowRunState(level: level)
        run.start()
        run.apples = level.goalApples
        run.hearts = 3
        run.distance = level.length - 0.5
        run.update(delta: 0.02)
        XCTAssertEqual(run.phase, .finished)
        XCTAssertGreaterThanOrEqual(run.stars, 2)
        XCTAssertNotNil(run.result)
        XCTAssertTrue(run.result?.success == true)
        XCTAssertEqual(run.result?.goalApples, level.goalApples)
    }

    func testArcadeStateUnlocksLevelsAndPersistsStars() {
        let result = MeadowRunResult(
            levelIndex: 1,
            score: 1_200,
            apples: 14,
            stars: 3,
            distance: 1_400,
            elapsed: 12,
            hearts: 2,
            maxHearts: 3,
            goalApples: 8,
            maxCombo: 9,
            powers: ["clover", "dash"],
            success: true
        )
        var state = ArcadeState()
        state.register(result, day: 4)
        XCTAssertEqual(state.bestScore, 1_200)
        XCTAssertEqual(state.unlockedLevel, 2)
        XCTAssertEqual(state.stars(for: 1), 3)
        XCTAssertEqual(state.totalStars(), 3)
        XCTAssertTrue(state.isUnlocked(2))
        XCTAssertTrue(state.discoveredPowers.contains("clover"))
        XCTAssertEqual(state.dailyRuns, 1)
        XCTAssertEqual(state.dailyBest, 1_200)
        state.register(result, day: 4)
        XCTAssertEqual(state.totalRuns, 2)
        XCTAssertEqual(state.dailyRuns, 2)
    }

    func testArcadeStateDecodesFromOlderSaveWithoutArcadeKey() throws {
        let state = GameState.newGame(now: fixedDate, seed: 2)
        let data = try JSONEncoder().encode(state)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "arcade")
        let stripped = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(GameState.self, from: stripped)
        XCTAssertEqual(decoded.arcade.bestScore, 0)
        XCTAssertEqual(decoded.arcade.unlockedLevel, 1)
        XCTAssertEqual(decoded.version, GameConstants.saveVersion)
    }

    func testEngineRecordsMeadowRunAndAwardsBoundedRewards() {
        let state = GameState.newGame(now: fixedDate, seed: 3)
        let engine = GameEngine(state: state, clock: { self.fixedDate })
        let result = MeadowRunResult(
            levelIndex: 1,
            score: 900,
            apples: 9,
            stars: 2,
            distance: 1_400,
            elapsed: 13,
            hearts: 2,
            maxHearts: 3,
            goalApples: 8,
            maxCombo: 6,
            powers: [],
            success: true
        )
        let beforeCoins = engine.state.coins
        let beforeXP = engine.state.xp
        let reward = engine.recordMeadowRun(result)
        XCTAssertGreaterThan(reward.coins, 0)
        XCTAssertGreaterThan(reward.xp, 0)
        XCTAssertGreaterThan(engine.state.coins, beforeCoins)
        XCTAssertGreaterThanOrEqual(engine.state.xp, beforeXP)
        XCTAssertEqual(engine.state.arcade.bestScore, 900)
        XCTAssertEqual(engine.state.arcade.unlockedLevel, 2)
        XCTAssertTrue(engine.drainEvents().contains { event in
            if case .meadowRunCompleted = event { return true }
            return false
        })
    }
}
