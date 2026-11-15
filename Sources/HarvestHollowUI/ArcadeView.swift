#if canImport(SwiftUI)
import SwiftUI
import Combine
import HarvestHollowCore

// MARK: - Meadow Dash

/// The interactive 2D page. Meadow Dash is a real little game: a deterministic
/// side-scrolling run with physics, double jumps, a dash, collectibles, hearts,
/// combos, sixteen hand-built levels, and a save-backed career.
public struct ArcadeView: View {
    @EnvironmentObject private var store: GameStore

    @State private var selectedLevel = 1
    @State private var run = MeadowRunState(level: MeadowLevelCatalog.levels[0])
    @State private var lastTick = Date()
    @State private var recordedResult: MeadowRunResult?
    @State private var rewardCoins = 0
    @State private var rewardXP = 0
    @State private var notice: String?
    @State private var showHowTo = false

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    public init() {}

    private var arcade: ArcadeState { store.state.arcade }

    private var selectedDefinition: MeadowLevelDefinition {
        MeadowLevelCatalog.level(selectedLevel) ?? MeadowLevelCatalog.levels[0]
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                stage
                controls
                if let notice {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                        Text(notice)
                        Spacer(minLength: 0)
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                self.notice = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.hhCaption(12))
                    .foregroundStyle(HHTheme.terracottaDark)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(HHTheme.terracotta.opacity(0.1), in: Capsule())
                    .transition(.opacity)
                }
                levelSection
                careerSection
                howToCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
            .frame(maxWidth: 860)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .onReceive(timer) { now in
            guard run.phase == .running else {
                lastTick = now
                return
            }
            let delta = now.timeIntervalSince(lastTick)
            lastTick = now
            run.update(delta: delta)
        }
        .onChange(of: run.phase) { _, phase in
            if phase == .finished || phase == .failed {
                registerResultIfNeeded()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        CozyCard(padding: 15) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [HHTheme.forest, HHTheme.leaf],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "figure.run")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text("Meadow Dash")
                            .font(.hhTitle(25))
                            .foregroundStyle(HHTheme.ink)
                        Text("2D")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(HHTheme.terracotta, in: Capsule())
                    }
                    Text("Jump, dash and collect apples across sixteen tiny meadows.")
                        .font(.hhCaption(12))
                        .foregroundStyle(HHTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(arcade.bestScore)")
                        .font(.hhTitle(21))
                        .foregroundStyle(HHTheme.forest)
                    Text("BEST SCORE")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(HHTheme.muted)
                }
            }
        }
    }

    // MARK: Stage

    private var stage: some View {
        MeadowGameStage(
            run: run,
            onStart: startCurrent,
            onPause: { run.pause() },
            onResume: { run.resume() },
            onRestart: startCurrent,
            onNext: advanceLevel,
            onJump: jump,
            onDash: dash,
            onSlide: slide,
            rewardCoins: rewardCoins,
            rewardXP: rewardXP
        )
        .frame(height: 346)
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 10) {
            MeadowControlButton(
                icon: "arrow.up",
                title: "Jump",
                subtitle: "double hop",
                tint: HHTheme.forest,
                isEnabled: run.phase == .running
            ) {
                jump()
            }
            MeadowControlButton(
                icon: "hare.fill",
                title: "Dash",
                subtitle: run.player.dashCooldown > 0
                    ? String(format: "%.1fs", run.player.dashCooldown)
                    : "ready",
                tint: HHTheme.terracotta,
                isEnabled: run.phase == .running && run.player.dashCooldown <= 0
            ) {
                dash()
            }
            MeadowControlButton(
                icon: "arrow.down.to.line",
                title: "Slide",
                subtitle: "duck low",
                tint: HHTheme.lavender,
                isEnabled: run.phase == .running
            ) {
                slide()
            }
        }
    }

    // MARK: Levels

    private var levelSection: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    SectionHeader(
                        "Choose a meadow",
                        subtitle: "Every meadow has its own weather, obstacles and secret route.",
                        icon: "map.fill",
                        accent: HHTheme.forest
                    )
                    Spacer(minLength: 0)
                    Text("\(arcade.totalStars())/\(MeadowLevelCatalog.levelCount * 3)★")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.goldDeep)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(MeadowLevelCatalog.levels) { level in
                            MeadowLevelCard(
                                level: level,
                                stars: arcade.stars(for: level.index),
                                unlocked: arcade.isUnlocked(level.index),
                                selected: selectedLevel == level.index
                            ) {
                                choose(level)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: Career

    private var careerSection: some View {
        CozyCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    "Meadow career",
                    subtitle: "Saved with your farm. Runs can earn a few coins and XP for Hollow.",
                    icon: "rosette",
                    accent: HHTheme.terracotta
                )
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 9
                ) {
                    careerStat(value: "\(arcade.totalRuns)", label: "Runs", icon: "figure.run")
                    careerStat(value: "\(arcade.totalApples)", label: "Apples", icon: "apple.logo")
                    careerStat(value: "\(arcade.totalStars())", label: "Stars", icon: "star.fill")
                    careerStat(value: "\(arcade.perfectRuns)", label: "Perfect runs", icon: "checkmark.seal.fill")
                }
                HStack(spacing: 8) {
                    TagChip("\(arcade.totalDistance) m travelled", icon: "arrow.left.and.right", tint: HHTheme.forest)
                    TagChip("\(arcade.discoveredPowers.count) tricks found", icon: "sparkles", tint: HHTheme.lavender)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func careerStat(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(HHTheme.forest)
                .frame(width: 30, height: 30)
                .background(HHTheme.forest.opacity(0.09), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.hhHeadline(16))
                    .foregroundStyle(HHTheme.ink)
                Text(label)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(HHTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    // MARK: Help

    private var howToCard: some View {
        CozyCard(padding: 14) {
            DisclosureGroup(isExpanded: $showHowTo) {
                VStack(alignment: .leading, spacing: 9) {
                    helpRow(icon: "arrow.up.circle.fill", text: "Tap Jump for a hop. Tap again in the air for a double hop.")
                    helpRow(icon: "hare.fill", text: "Dash breaks fences, crates and pumpkins. It also makes you briefly invincible.")
                    helpRow(icon: "arrow.down.to.line", text: "Slide under high crows and collect low apples without slowing down.")
                    helpRow(icon: "leaf.fill", text: "Clover gives a shield, carrots refill your dash, and golden apples are worth five.")
                    helpRow(icon: "flag.checkered", text: "Finish with enough apples and at least two hearts for a three-star run.")
                }
                .padding(.top, 10)
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(HHTheme.terracotta)
                    Text("How to dash")
                        .font(.hhHeadline(15))
                        .foregroundStyle(HHTheme.ink)
                    Spacer(minLength: 0)
                }
            }
            .tint(HHTheme.forest)
        }
    }

    private func helpRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(HHTheme.forest)
                .frame(width: 18)
            Text(text)
                .font(.hhCaption(11.5))
                .foregroundStyle(HHTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Actions

    private func choose(_ level: MeadowLevelDefinition) {
        guard arcade.isUnlocked(level.index) else {
            withAnimation(.easeOut(duration: 0.2)) {
                notice = "Clear meadow \(arcade.unlockedLevel) to unlock \(level.name)."
            }
            return
        }
        selectedLevel = level.index
        run = MeadowRunState(level: level)
        recordedResult = nil
        rewardCoins = 0
        rewardXP = 0
        notice = nil
        lastTick = Date()
    }

    private func startCurrent() {
        let level = selectedDefinition
        run = MeadowRunState(level: level)
        run.start()
        recordedResult = nil
        rewardCoins = 0
        rewardXP = 0
        notice = nil
        lastTick = Date()
    }

    private func advanceLevel() {
        guard selectedLevel < MeadowLevelCatalog.levelCount else {
            startCurrent()
            return
        }
        selectedLevel += 1
        if let next = MeadowLevelCatalog.level(selectedLevel), arcade.isUnlocked(next.index) {
            run = MeadowRunState(level: next)
            run.start()
        } else {
            run = MeadowRunState(level: selectedDefinition)
        }
        recordedResult = nil
        rewardCoins = 0
        rewardXP = 0
        lastTick = Date()
    }

    private func jump() {
        run.jump()
    }

    private func dash() {
        run.dash()
    }

    private func slide() {
        run.slide()
    }

    private func registerResultIfNeeded() {
        guard let result = run.result, result != recordedResult else { return }
        recordedResult = result
        let rewards = store.recordMeadowRun(result)
        rewardCoins = rewards.coins
        rewardXP = rewards.xp
    }
}

// MARK: - Stage

private struct MeadowGameStage: View {
    let run: MeadowRunState
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onRestart: () -> Void
    let onNext: () -> Void
    let onJump: () -> Void
    let onDash: () -> Void
    let onSlide: () -> Void
    let rewardCoins: Int
    let rewardXP: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    Canvas { context, canvasSize in
                        MeadowSceneRenderer.draw(
                            context: &context,
                            size: canvasSize,
                            run: run,
                            time: timeline.date.timeIntervalSinceReferenceDate
                        )
                    }
                    .background(Color(hex: run.level.biome.skyTopHex))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if run.phase == .ready { onStart() } else if run.phase == .running { onJump() }
                    }

                    stageHUD(size: size)

                    if run.phase == .ready {
                        stageWelcome
                    } else if run.phase == .paused {
                        stagePaused
                    } else if run.phase == .finished || run.phase == .failed {
                        stageResult
                    }

                    if run.player.shieldTimer > 0 {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(HHTheme.leafLight.opacity(0.55), lineWidth: 3)
                            .padding(5)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(HHTheme.ink.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: HHTheme.soilDark.opacity(0.2), radius: 14, y: 8)
            }
        }
    }

    private func stageHUD(size: CGSize) -> some View {
        VStack {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<run.maxHearts, id: \.self) { heart in
                        Image(systemName: heart < run.hearts ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(heart < run.hearts ? Color(hex: "D95D4F") : .white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.black.opacity(0.22), in: Capsule())

                Text(run.level.name)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.22), in: Capsule())

                Spacer(minLength: 0)

                Text("\(run.score)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(HHTheme.forest.opacity(0.85), in: Capsule())

                Button {
                    if run.phase == .running { onPause() } else if run.phase == .paused { onResume() }
                } label: {
                    Image(systemName: run.phase == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.black.opacity(0.24), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(run.phase != .running && run.phase != .paused)
            }
            .padding(10)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(run.apples)/\(run.level.goalApples)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    if run.combo > 1 {
                        Text("×\(run.combo)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(HHTheme.gold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.25), in: Capsule())
                    }
                    Spacer(minLength: 0)
                    if run.player.shieldTimer > 0 {
                        Label("shield", systemImage: "leaf.fill")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.22))
                        Capsule()
                            .fill(HHTheme.gold)
                            .frame(width: max(0, proxy.size.width * run.progress))
                    }
                }
                .frame(height: 5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(10)
        }
        .allowsHitTesting(run.phase == .running || run.phase == .paused)
    }

    private var stageWelcome: some View {
        VStack(spacing: 9) {
            Text(run.level.biome.title.uppercased())
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.85))
            Text(run.level.name)
                .font(.hhTitle(28))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            Text(run.level.subtitle)
                .font(.hhCaption(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: 270)
            Button(action: onStart) {
                HStack(spacing: 7) {
                    Image(systemName: "play.fill")
                    Text("Start run")
                }
                .font(.hhHeadline(14))
                .foregroundStyle(HHTheme.forestDark)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(HHTheme.gold, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(20)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(20)
    }

    private var stagePaused: some View {
        VStack(spacing: 10) {
            Text("Paused")
                .font(.hhTitle(26))
                .foregroundStyle(.white)
            Text("The meadow will wait.")
                .font(.hhCaption(12))
                .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 9) {
                Button("Resume", action: onResume)
                    .buttonStyle(MeadowPillButtonStyle(tint: HHTheme.forest))
                Button("Restart", action: onRestart)
                    .buttonStyle(MeadowPillButtonStyle(tint: HHTheme.terracotta))
            }
        }
        .padding(20)
        .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var stageResult: some View {
        VStack(spacing: 8) {
            if let result = run.result {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < result.stars ? "star.fill" : "star")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(index < result.stars ? HHTheme.gold : .white.opacity(0.55))
                    }
                }
                Text(result.success ? "Meadow cleared" : "The meadow wins this round")
                    .font(.hhTitle(23))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    resultStat("\(result.score)", "score")
                    resultStat("\(result.apples)", "apples")
                    resultStat("×\(result.maxCombo)", "combo")
                }
                if rewardCoins > 0 {
                    Text("+\(rewardCoins) coins · +\(rewardXP) XP for Hollow")
                        .font(.hhCaption(11))
                        .foregroundStyle(HHTheme.gold)
                }
                HStack(spacing: 8) {
                    Button("Run again", action: onRestart)
                        .buttonStyle(MeadowPillButtonStyle(tint: HHTheme.terracotta))
                    if result.success {
                        Button {
                            onNext()
                        } label: {
                            Label("Next meadow", systemImage: "arrow.right")
                        }
                        .buttonStyle(MeadowPillButtonStyle(tint: HHTheme.forest))
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(16)
    }

    private func resultStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Controls

private struct MeadowControlButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.hhHeadline(14))
                    Text(subtitle)
                        .font(.hhCaption(9.5))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(isEnabled ? tint : HHTheme.muted)
            .padding(10)
            .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(isEnabled ? 0.22 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}

private struct MeadowLevelCard: View {
    let level: MeadowLevelDefinition
    let stars: Int
    let unlocked: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(level.index)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(selected ? .white : HHTheme.ink)
                    Spacer(minLength: 0)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(selected ? .white.opacity(0.8) : HHTheme.muted)
                    } else {
                        Text(level.biome.emoji)
                            .font(.system(size: 11))
                    }
                }
                Text(level.name)
                    .font(.hhCaption(10.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(selected ? .white : HHTheme.ink)
                    .frame(height: 28, alignment: .topLeading)
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < stars ? "star.fill" : "star")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(index < stars ? HHTheme.gold : (selected ? .white.opacity(0.4) : HHTheme.ink.opacity(0.15)))
                    }
                }
            }
            .padding(10)
            .frame(width: 94, height: 103)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(selected ? HHTheme.forest : HHTheme.cream.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(selected ? HHTheme.forestDark : HHTheme.ink.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MeadowPillButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hhHeadline(12))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1), in: Capsule())
    }
}

// MARK: - Scene renderer

private enum MeadowSceneRenderer {
    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        run: MeadowRunState,
        time: Double
    ) {
        let biome = run.level.biome
        drawSky(context: &context, size: size, biome: biome, time: time)
        drawHills(context: &context, size: size, biome: biome, run: run, time: time)
        drawDistantFarm(context: &context, size: size, biome: biome, run: run)
        drawGround(context: &context, size: size, biome: biome, run: run, time: time)
        drawScenery(context: &context, size: size, run: run, time: time)
        drawSpawns(context: &context, size: size, run: run, time: time)
        drawPlayer(context: &context, size: size, run: run, time: time)
        drawWeather(context: &context, size: size, biome: biome, time: time)
        drawVignette(context: &context, size: size)
    }

    private static func drawSky(
        context: inout GraphicsContext,
        size: CGSize,
        biome: MeadowBiome,
        time: Double
    ) {
        let sky = CGRect(origin: .zero, size: size)
        context.fill(
            Path(sky),
            with: .linearGradient(
                Gradient(colors: [Color(hex: biome.skyTopHex), Color(hex: biome.skyBottomHex)]),
                startPoint: CGPoint(x: size.width * 0.5, y: 0),
                endPoint: CGPoint(x: size.width * 0.5, y: size.height * 0.72)
            )
        )

        // Celestial body.
        let isNight = biome == .moonlit
        let sunX = size.width * 0.76
        let sunY = size.height * 0.16 + CGFloat(sin(time * 0.08)) * 3
        let sunColor = isNight ? Color(hex: "E8E3C9") : Color(hex: "FFE7A3")
        for ring in (0...3).reversed() {
            let radius = CGFloat(12 + ring * 8)
            context.fill(
                Path(ellipseIn: CGRect(x: sunX - radius, y: sunY - radius, width: radius * 2, height: radius * 2)),
                with: .color(sunColor.opacity(ring == 0 ? 0.95 : 0.08))
            )
        }
        if isNight {
            for index in 0..<24 {
                let x = CGFloat((index * 71) % 101) / 101 * size.width
                let y = CGFloat((index * 43) % 53) / 53 * size.height * 0.55
                let alpha = 0.38 + 0.38 * sin(time * 0.7 + Double(index))
                context.hhPixel(x: x, y: y, width: 1.5, height: 1.5, color: .white.opacity(alpha))
            }
        }

        // Pixel clouds with independent parallax.
        let cloudOffset = CGFloat((time * 5).truncatingRemainder(dividingBy: Double(size.width + 180)))
        for index in 0..<5 {
            let baseX = CGFloat(index * 103 + 34) - cloudOffset
            let x = baseX < -120 ? baseX + size.width + 240 : baseX
            let y = CGFloat(24 + (index * 37) % 76)
            drawCloud(context: &context, x: x, y: y, scale: CGFloat(0.75 + Double(index % 3) * 0.2), tint: Color.white.opacity(0.72))
        }
    }

    private static func drawCloud(
        context: inout GraphicsContext,
        x: CGFloat,
        y: CGFloat,
        scale: CGFloat,
        tint: Color
    ) {
        let blocks: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0, 8, 40, 9), (8, 2, 24, 10), (21, 0, 20, 12),
            (31, 5, 28, 9), (6, 14, 49, 6)
        ]
        for block in blocks {
            context.hhPixel(
                x: x + block.0 * scale,
                y: y + block.1 * scale,
                width: block.2 * scale,
                height: block.3 * scale,
                color: tint
            )
        }
    }

    private static func drawHills(
        context: inout GraphicsContext,
        size: CGSize,
        biome: MeadowBiome,
        run: MeadowRunState,
        time: Double
    ) {
        let layers = MeadowArtDirection.layers(for: biome)
        let horizon = size.height * 0.61
        for (index, layer) in layers.enumerated() {
            let scroll = CGFloat(run.distance * layer.parallax * 0.7)
            let color = Color(hex: layer.hillHex).opacity(index == 0 ? 0.62 : 0.95)
            let height = size.height * CGFloat(0.1 + Double(index) * 0.035)
            var path = Path()
            path.move(to: CGPoint(x: -20, y: horizon + CGFloat(index) * 10))
            let step: CGFloat = 62
            var x: CGFloat = -20 - scroll.truncatingRemainder(dividingBy: step)
            var flip = 0
            while x < size.width + step {
                let peak = horizon + CGFloat(index) * 10 - height + CGFloat((flip + index) % 3) * 7
                path.addCurve(
                    to: CGPoint(x: x + step, y: horizon + CGFloat(index) * 10),
                    control1: CGPoint(x: x + step * 0.28, y: peak),
                    control2: CGPoint(x: x + step * 0.72, y: peak)
                )
                x += step
                flip += 1
            }
            path.addLine(to: CGPoint(x: size.width + 30, y: size.height))
            path.addLine(to: CGPoint(x: -20, y: size.height))
            path.closeSubpath()
            context.fill(path, with: .color(color))
        }

        // Fence and tree silhouettes on the middle hill.
        let scroll = CGFloat(run.distance * 0.33)
        var x = -scroll.truncatingRemainder(dividingBy: 145) - 40
        while x < size.width + 80 {
            drawDistantTree(context: &context, x: x, y: horizon + 4, scale: 0.7, color: Color(hex: layers[1].treeHex).opacity(0.58))
            x += 145
        }
        var fenceX = -scroll.truncatingRemainder(dividingBy: 58) - 20
        while fenceX < size.width + 60 {
            context.hhPixel(x: fenceX, y: horizon + 18, width: 2, height: 12, color: Color(hex: "8A5A3A").opacity(0.35))
            context.hhPixel(x: fenceX, y: horizon + 21, width: 58, height: 1.5, color: Color(hex: "8A5A3A").opacity(0.3))
            context.hhPixel(x: fenceX, y: horizon + 25, width: 58, height: 1.5, color: Color(hex: "8A5A3A").opacity(0.3))
            fenceX += 58
        }
        _ = time
    }

    private static func drawDistantTree(
        context: inout GraphicsContext,
        x: CGFloat,
        y: CGFloat,
        scale: CGFloat,
        color: Color
    ) {
        context.hhPixel(x: x + 8 * scale, y: y - 20 * scale, width: 3 * scale, height: 20 * scale, color: Color(hex: "6B4A32").opacity(0.55))
        context.hhPixel(x: x, y: y - 37 * scale, width: 20 * scale, height: 13 * scale, color: color)
        context.hhPixel(x: x + 4 * scale, y: y - 44 * scale, width: 13 * scale, height: 9 * scale, color: color)
        context.hhPixel(x: x + 7 * scale, y: y - 48 * scale, width: 8 * scale, height: 7 * scale, color: color)
    }

    private static func drawDistantFarm(
        context: inout GraphicsContext,
        size: CGSize,
        biome: MeadowBiome,
        run: MeadowRunState
    ) {
        let baseY = size.height * 0.585
        let offset = CGFloat(run.distance * 0.13).truncatingRemainder(dividingBy: size.width + 420)
        let barnX = size.width * 0.61 - offset + 210
        let wrappedBarnX = barnX < -170 ? barnX + size.width + 420 : barnX
        let barn = Color(hex: "B64B3F").opacity(0.5)
        let roof = Color(hex: "8B4A3D").opacity(0.55)
        context.hhPixel(x: wrappedBarnX, y: baseY - 42, width: 82, height: 42, color: barn)
        context.hhPixel(x: wrappedBarnX - 6, y: baseY - 52, width: 94, height: 8, color: roof)
        context.hhPixel(x: wrappedBarnX + 9, y: baseY - 61, width: 64, height: 7, color: roof)
        context.hhPixel(x: wrappedBarnX + 28, y: baseY - 26, width: 25, height: 26, color: Color(hex: "7A382F").opacity(0.6))
        context.hhPixel(x: wrappedBarnX + 34, y: baseY - 20, width: 13, height: 12, color: Color(hex: "E9D9B7").opacity(0.35))
        context.hhPixel(x: wrappedBarnX + 57, y: baseY - 40, width: 16, height: 28, color: Color(hex: "A7A397").opacity(0.45))
        context.hhPixel(x: wrappedBarnX + 55, y: baseY - 45, width: 20, height: 5, color: roof)

        let houseX = wrappedBarnX + 130
        let house = Color(hex: "F4E3C1").opacity(0.45)
        context.hhPixel(x: houseX, y: baseY - 28, width: 34, height: 28, color: house)
        context.hhPixel(x: houseX - 4, y: baseY - 36, width: 42, height: 8, color: roof)
        context.hhPixel(x: houseX + 5, y: baseY - 24, width: 8, height: 8, color: Color(hex: "4F7FA8").opacity(0.45))
        context.hhPixel(x: houseX + 22, y: baseY - 20, width: 8, height: 20, color: Color(hex: "8A5A3A").opacity(0.5))

        if biome == .golden || biome == .storm {
            context.hhPixel(
                x: 0,
                y: size.height * 0.48,
                width: size.width,
                height: size.height * 0.16,
                color: Color(hex: biome == .golden ? "D8B65C" : "879B8D").opacity(0.22)
            )
        }
    }

    private static func drawGround(
        context: inout GraphicsContext,
        size: CGSize,
        biome: MeadowBiome,
        run: MeadowRunState,
        time: Double
    ) {
        let horizon = size.height * 0.65
        let grass = Color(hex: biome.grassHex)
        let soil = Color(hex: biome.soilHex)
        context.hhPixel(x: 0, y: horizon, width: size.width, height: size.height - horizon, color: grass)
        context.hhPixel(x: 0, y: horizon + 9, width: size.width, height: size.height - horizon - 9, color: grass.opacity(0.96))
        context.hhPixel(x: 0, y: horizon + 20, width: size.width, height: size.height - horizon - 20, color: soil.opacity(0.18))

        // Pixel grass blades and tiny flowers, scrolling with the run.
        let scroll = CGFloat(run.distance)
        var x = -scroll.truncatingRemainder(dividingBy: 17) - 17
        var index = 0
        while x < size.width + 20 {
            let y = horizon + CGFloat(22 + (index * 13) % 54)
            let tint = index % 4 == 0 ? Color(hex: "D95D4F").opacity(0.7) : grass.opacity(0.5)
            context.hhPixel(x: x, y: y, width: 2, height: 4, color: tint)
            context.hhPixel(x: x + 2, y: y + 2, width: 2, height: 3, color: tint.opacity(0.75))
            x += 17
            index += 1
        }

        // A soft path with stepping stones.
        let pathY = size.height * 0.78
        context.hhPixel(x: 0, y: pathY, width: size.width, height: size.height - pathY, color: soil.opacity(0.22))
        context.hhPixel(x: 0, y: pathY + 2, width: size.width, height: 2, color: Color(hex: "C9B391").opacity(0.22))
        var stoneX = -scroll.truncatingRemainder(dividingBy: 52) - 30
        while stoneX < size.width + 30 {
            context.hhPixel(x: stoneX, y: pathY + 14, width: 26, height: 3, color: Color(hex: "A7A397").opacity(0.2))
            stoneX += 52
        }
        _ = time
    }

    private static func drawScenery(
        context: inout GraphicsContext,
        size: CGSize,
        run: MeadowRunState,
        time: Double
    ) {
        let groundY = size.height * 0.78
        let scroll = CGFloat(run.distance * 0.55)
        var index = 0
        var x = -scroll.truncatingRemainder(dividingBy: 215) - 80
        while x < size.width + 120 {
            if index % 2 == 0 {
                drawForegroundTree(
                    context: &context,
                    x: x,
                    baseY: groundY - 15,
                    scale: 0.85,
                    tint: Color(hex: run.level.biome == .moonlit ? "2F4A3C" : "4F8A5A")
                )
            } else {
                drawForegroundBush(
                    context: &context,
                    x: x + 24,
                    baseY: groundY - 7,
                    scale: 0.8,
                    tint: Color(hex: run.level.biome == .moonlit ? "2F503F" : "5E9C68")
                )
            }
            x += 215
            index += 1
        }

        // Butterflies during the daytime.
        if run.level.biome != .moonlit {
            for butterfly in 0..<4 {
                let base = time * (0.24 + Double(butterfly) * 0.04) + Double(butterfly) * 1.7
                let bx = CGFloat((sin(base) * 0.5 + 0.5) * Double(size.width))
                let by = size.height * 0.48 + CGFloat(cos(base * 1.4) * 16)
                let wing = 2.0 + CGFloat(sin(time * 8 + Double(butterfly)) * 1.2)
                context.hhPixel(x: bx - wing, y: by, width: wing, height: wing, color: Color(hex: "8FC3DD").opacity(0.82))
                context.hhPixel(x: bx, y: by, width: wing, height: wing, color: Color(hex: "A9D9EE").opacity(0.82))
                context.hhPixel(x: bx, y: by - 2, width: 1, height: 2, color: Color(hex: "4F5D75").opacity(0.8))
            }
        }
    }

    private static func drawForegroundTree(
        context: inout GraphicsContext,
        x: CGFloat,
        baseY: CGFloat,
        scale: CGFloat,
        tint: Color
    ) {
        context.hhPixel(x: x + 18 * scale, y: baseY - 54 * scale, width: 7 * scale, height: 54 * scale, color: Color(hex: "6B4A32").opacity(0.9))
        context.hhPixel(x: x + 6 * scale, y: baseY - 77 * scale, width: 31 * scale, height: 26 * scale, color: tint.opacity(0.9))
        context.hhPixel(x: x + 12 * scale, y: baseY - 89 * scale, width: 20 * scale, height: 18 * scale, color: tint)
        context.hhPixel(x: x, y: baseY - 66 * scale, width: 19 * scale, height: 16 * scale, color: tint.opacity(0.82))
        context.hhPixel(x: x + 26 * scale, y: baseY - 69 * scale, width: 17 * scale, height: 17 * scale, color: tint.opacity(0.78))
    }

    private static func drawForegroundBush(
        context: inout GraphicsContext,
        x: CGFloat,
        baseY: CGFloat,
        scale: CGFloat,
        tint: Color
    ) {
        context.hhPixel(x: x, y: baseY - 18 * scale, width: 24 * scale, height: 18 * scale, color: tint)
        context.hhPixel(x: x + 5 * scale, y: baseY - 26 * scale, width: 14 * scale, height: 12 * scale, color: tint.opacity(0.9))
        context.hhPixel(x: x + 17 * scale, y: baseY - 22 * scale, width: 10 * scale, height: 14 * scale, color: tint.opacity(0.72))
    }

    private static func drawSpawns(
        context: inout GraphicsContext,
        size: CGSize,
        run: MeadowRunState,
        time: Double
    ) {
        let groundY = size.height * 0.78
        let scale = max(1.2, size.height / 175)
        let playerScreenX = size.width * 0.27

        for live in run.spawns where !live.isResolved {
            let spawn = live.spawn
            let dx = CGFloat(spawn.x - run.player.x) * scale
            let x = playerScreenX + dx
            guard x > -140, x < size.width + 140 else { continue }
            let bottom = groundY - CGFloat(spawn.y) * scale
            let rect = CGRect(
                x: x - CGFloat(spawn.scale) * scale * 9,
                y: bottom - CGFloat(spawn.scale) * scale * 18,
                width: CGFloat(spawn.scale) * scale * 18,
                height: CGFloat(spawn.scale) * scale * 18
            )
            if let pickup = spawn.kind.pickup {
                drawPickup(context: &context, kind: pickup, center: CGPoint(x: x, y: bottom - 20), scale: scale, time: time)
            } else if let obstacle = spawn.kind.obstacle {
                drawObstacle(
                    context: &context,
                    kind: obstacle,
                    rect: rect,
                    time: time,
                    shadowY: groundY
                )
            }
        }
    }

    private static func drawObstacle(
        context: inout GraphicsContext,
        kind: MeadowObstacleKind,
        rect: CGRect,
        time: Double,
        shadowY: CGFloat
    ) {
        let cell = max(1.1, rect.width / 18)
        let ox = rect.minX
        let oy = rect.maxY
        context.hhPixel(x: rect.midX - rect.width * 0.35, y: shadowY + 2, width: rect.width * 0.7, height: 3, color: .black.opacity(0.12))

        func block(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
            context.hhPixel(x: ox + x * cell, y: oy - y * cell, width: w * cell, height: h * cell, color: color)
        }

        switch kind {
        case .fence:
            block(1, 0, 16, 2, Color(hex: "8A5A3A"))
            block(2, 2, 2, 14, Color(hex: "E9D9B7"))
            block(14, 2, 2, 14, Color(hex: "E9D9B7"))
            block(2, 7, 14, 2, Color(hex: "FFF6E4"))
            block(2, 11, 14, 2, Color(hex: "FFF6E4"))
        case .rock:
            block(2, 0, 14, 3, Color(hex: "7A776F"))
            block(1, 3, 16, 4, Color(hex: "A7A397"))
            block(4, 7, 10, 5, Color(hex: "8F8C82"))
            block(6, 12, 6, 2, Color(hex: "B8B4A7"))
            block(5, 8, 3, 2, Color(hex: "4F8A5A"))
        case .stump:
            block(3, 0, 12, 7, Color(hex: "74482E"))
            block(2, 7, 14, 3, Color(hex: "C9A876"))
            block(6, 8, 6, 1, Color(hex: "8A5A3A"))
            block(4, 2, 6, 2, Color(hex: "4F8A5A"))
            block(11, 9, 3, 2, Color(hex: "C94F45"))
        case .hayBale:
            block(2, 0, 14, 12, Color(hex: "D8B65C"))
            block(1, 3, 16, 2, Color(hex: "8A5A3A"))
            block(1, 8, 16, 2, Color(hex: "8A5A3A"))
            block(4, 11, 10, 1, Color(hex: "E7C76B"))
        case .puddle:
            block(1, 0, 16, 4, Color(hex: "4F7FA8"))
            block(4, 3, 10, 1, Color(hex: "8FC3DD"))
            block(2, 1, 5, 1, Color(hex: "D8EDF5"))
        case .crow:
            block(5, 2, 8, 7, Color(hex: "2D2622"))
            block(8, 9, 5, 4, Color(hex: "3B3A46"))
            block(12, 12, 4, 2, Color(hex: "E4A63D"))
            block(3, 4, 2, 4, Color(hex: "3B3A46"))
            block(1, 6, 4, 2, Color(hex: "3B3A46"))
            block(9, 4, 2, 2, Color(hex: "FFF6E4"))
            block(10, 4, 1, 1, Color(hex: "2D2622"))
        case .bee:
            block(5, 3, 8, 7, Color(hex: "E7B93F"))
            block(6, 5, 6, 2, Color(hex: "2D2622"))
            block(7, 9, 4, 2, Color(hex: "2D2622"))
            block(3, 8, 3, 3, Color(hex: "D8EDF5").opacity(0.7))
            block(12, 8, 3, 3, Color(hex: "D8EDF5").opacity(0.7))
            block(9, 11, 2, 1, Color(hex: "2D2622"))
        case .thistle:
            block(8, 0, 3, 10, Color(hex: "4F8A5A"))
            block(4, 8, 4, 3, Color(hex: "8E6BC4"))
            block(11, 9, 4, 3, Color(hex: "A17ED4"))
            block(7, 12, 5, 3, Color(hex: "8E6BC4"))
            block(8, 15, 3, 2, Color(hex: "4F8A5A"))
        case .crate:
            block(2, 0, 14, 12, Color(hex: "8A5A3A"))
            block(1, 2, 16, 2, Color(hex: "A46B49"))
            block(1, 8, 16, 2, Color(hex: "A46B49"))
            block(7, 3, 4, 3, Color(hex: "C94F45"))
            block(5, 10, 8, 2, Color(hex: "FFF6E4"))
        case .pumpkin:
            block(3, 0, 12, 8, Color(hex: "E08A32"))
            block(2, 2, 14, 5, Color(hex: "F0A34A"))
            block(5, 4, 8, 4, Color(hex: "C97726"))
            block(8, 8, 2, 3, Color(hex: "4F8A5A"))
            block(1, 7, 3, 2, Color(hex: "4F8A5A"))
        }
        _ = time
    }

    private static func drawPickup(
        context: inout GraphicsContext,
        kind: MeadowPickupKind,
        center: CGPoint,
        scale: CGFloat,
        time: Double
    ) {
        let bob = CGFloat(sin(time * 4.2 + Double(center.x) * 0.04)) * 2
        let cell = max(1.2, scale * 0.72)
        let y = center.y + bob
        context.hhPixel(x: center.x - 1, y: y + 1, width: 2, height: 3, color: .black.opacity(0.14))
        switch kind {
        case .apple:
            let rect = CGRect(x: center.x - 7 * cell, y: y - 8 * cell, width: 14 * cell, height: 14 * cell)
            context.hhPixel(x: rect.minX + 2, y: rect.minY + 2, width: 10 * cell, height: 9 * cell, color: Color(hex: "C94F45"))
            context.hhPixel(x: rect.minX + 3, y: rect.minY + 1, width: 7 * cell, height: 3 * cell, color: Color(hex: "E06B5A"))
            context.hhPixel(x: rect.minX + 7, y: rect.minY - 2, width: 2 * cell, height: 4 * cell, color: Color(hex: "6B4A32"))
            context.hhPixel(x: rect.minX + 9, y: rect.minY - 2, width: 3 * cell, height: 2 * cell, color: Color(hex: "4F8A5A"))
        case .goldenApple:
            context.hhPixel(x: center.x - 7 * cell, y: y - 7 * cell, width: 14 * cell, height: 14 * cell, color: Color(hex: "B8892E"))
            context.hhPixel(x: center.x - 5 * cell, y: y - 8 * cell, width: 10 * cell, height: 10 * cell, color: Color(hex: "F0C95C"))
            context.hhPixel(x: center.x - 1 * cell, y: y - 12 * cell, width: 2 * cell, height: 4 * cell, color: Color(hex: "6B4A32"))
            for sparkle in 0..<4 {
                let angle = Double(sparkle) * 1.57 + time
                let sx = center.x + CGFloat(cos(angle)) * 17
                let sy = y + CGFloat(sin(angle)) * 15
                context.hhPixel(x: sx, y: sy, width: 2, height: 2, color: Color(hex: "FFF6E4").opacity(0.9))
            }
        case .clover:
            context.hhPixel(x: center.x - 1, y: y - 3 * cell, width: 2 * cell, height: 10 * cell, color: Color(hex: "3F7350"))
            let leafColor = Color(hex: "4F8A5A")
            context.hhPixel(x: center.x - 7 * cell, y: y - 9 * cell, width: 6 * cell, height: 6 * cell, color: leafColor)
            context.hhPixel(x: center.x + 1 * cell, y: y - 9 * cell, width: 6 * cell, height: 6 * cell, color: leafColor)
            context.hhPixel(x: center.x - 7 * cell, y: y - 3 * cell, width: 6 * cell, height: 6 * cell, color: leafColor)
            context.hhPixel(x: center.x + 1 * cell, y: y - 3 * cell, width: 6 * cell, height: 6 * cell, color: leafColor)
        case .carrot:
            context.hhPixel(x: center.x - 4 * cell, y: y - 2 * cell, width: 8 * cell, height: 10 * cell, color: Color(hex: "E08A32"))
            context.hhPixel(x: center.x - 2 * cell, y: y - 2 * cell, width: 4 * cell, height: 9 * cell, color: Color(hex: "F0A34A"))
            context.hhPixel(x: center.x - 5 * cell, y: y - 9 * cell, width: 4 * cell, height: 7 * cell, color: Color(hex: "4F8A5A"))
            context.hhPixel(x: center.x + 1 * cell, y: y - 11 * cell, width: 4 * cell, height: 8 * cell, color: Color(hex: "6FA84F"))
        case .heart:
            context.hhPixel(x: center.x - 7 * cell, y: y - 7 * cell, width: 5 * cell, height: 5 * cell, color: Color(hex: "D95D4F"))
            context.hhPixel(x: center.x + 2 * cell, y: y - 7 * cell, width: 5 * cell, height: 5 * cell, color: Color(hex: "D95D4F"))
            context.hhPixel(x: center.x - 5 * cell, y: y - 3 * cell, width: 10 * cell, height: 5 * cell, color: Color(hex: "D95D4F"))
            context.hhPixel(x: center.x - 2 * cell, y: y + 2 * cell, width: 4 * cell, height: 2 * cell, color: Color(hex: "D95D4F"))
        case .star:
            context.hhPixel(x: center.x - 1 * cell, y: y - 12 * cell, width: 2 * cell, height: 20 * cell, color: Color(hex: "F0C95C"))
            context.hhPixel(x: center.x - 6 * cell, y: y - 4 * cell, width: 12 * cell, height: 2 * cell, color: Color(hex: "F0C95C"))
            context.hhPixel(x: center.x - 4 * cell, y: y - 8 * cell, width: 8 * cell, height: 8 * cell, color: Color(hex: "FFF0B8"))
        }
    }

    private static func drawPlayer(
        context: inout GraphicsContext,
        size: CGSize,
        run: MeadowRunState,
        time: Double
    ) {
        let groundY = size.height * 0.78
        let scale = max(1.2, size.height / 175)
        let centerX = size.width * 0.27
        let bottomY = groundY - CGFloat(run.player.y) * scale + 1
        // Shadow.
        context.hhPixel(
            x: centerX - 24,
            y: groundY + 2,
            width: 48,
            height: 4,
            color: .black.opacity(run.player.y > 1 ? 0.08 : 0.15)
        )
        drawPig(
            context: &context,
            centerX: centerX,
            bottomY: bottomY,
            cell: scale * 0.9,
            run: run,
            time: time
        )
    }

    private static func drawPig(
        context: inout GraphicsContext,
        centerX: CGFloat,
        bottomY: CGFloat,
        cell: CGFloat,
        run: MeadowRunState,
        time: Double
    ) {
        let gridWidth = 27
        let gridHeight = 27
        let originX = centerX - CGFloat(gridWidth) * cell * 0.5
        let originY = bottomY - CGFloat(gridHeight) * cell
        let isSliding = run.player.isSliding
        let bounce = isSliding ? 0 : CGFloat(abs(sin(time * 12)) * 0.7)
        let bobY = run.player.isGrounded ? bounce : 0

        func px(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: String, alpha: Double = 1) {
            context.hhPixel(
                x: originX + x * cell,
                y: originY + (y + bobY) * cell,
                width: w * cell + 0.2,
                height: h * cell + 0.2,
                color: Color(hex: hex).opacity(alpha)
            )
        }

        let outline = "7A3F51"
        let dark = "D97B92"
        let pink = "F3A6B8"
        let light = "FFC3D0"
        let hoof = "5C3A45"

        if isSliding {
            px(2, 12, 22, 10, outline)
            px(3, 13, 20, 8, pink)
            px(19, 11, 7, 8, outline)
            px(20, 12, 5, 6, pink)
            px(16, 15, 5, 4, dark)
            px(10, 21, 4, 3, hoof)
            px(19, 21, 4, 3, hoof)
            px(21, 13, 1.4, 1.4, "2D2622")
            px(2, 13, 3, 3, dark)
            return
        }

        let legPhase = run.player.isGrounded ? sin(time * 14) : 0.6
        let frontLeg: CGFloat = legPhase > 0 ? 2 : 0
        let backLeg: CGFloat = legPhase > 0 ? 0 : 2

        // Back legs, body, head, ears, snout, eye, curly tail, front legs.
        px(5 + backLeg, 19, 5, 7, outline)
        px(6 + backLeg, 19, 3, 6, pink)
        px(6 + backLeg, 24, 3, 2, hoof)
        px(18 + frontLeg, 19, 5, 7, outline)
        px(19 + frontLeg, 19, 3, 6, pink)
        px(19 + frontLeg, 24, 3, 2, hoof)

        px(3, 9, 20, 13, outline)
        px(4, 10, 18, 11, pink)
        px(5, 9, 10, 3, light)
        px(9, 6, 8, 8, outline)
        px(10, 7, 6, 6, pink)
        px(16, 8, 8, 9, outline)
        px(17, 9, 6, 7, pink)
        px(19, 12, 5, 4, dark)
        px(20, 13, 4, 2, outline)
        px(20, 13, 1, 1, "7A3F51")
        px(22, 13, 1, 1, "7A3F51")
        px(18, 10, 1.4, 1.4, "2D2622")
        px(17, 9, 1, 1, "FFF6E4")
        px(15, 5, 4, 5, outline)
        px(16, 6, 3, 4, pink)
        px(18, 5, 4, 5, outline)
        px(19, 6, 2, 4, pink)
        px(2, 13, 4, 3, dark)
        px(0, 12, 3, 2, outline)
        px(0, 10, 2, 3, dark)
        px(1, 8, 2, 3, dark)
        px(6, 4, 2, 2, light)
        px(12, 5, 1, 1, light)

        if run.player.isDashing {
            px(-7, 11, 7, 2, "FFF0B8", alpha: 0.6)
            px(-9, 15, 6, 1, "FFF0B8", alpha: 0.4)
        }
        if run.player.shieldTimer > 0 {
            let shimmer = 0.35 + 0.2 * sin(time * 9)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: originX - 8,
                    y: originY - 2,
                    width: CGFloat(gridWidth) * cell + 16,
                    height: CGFloat(gridHeight) * cell + 14
                )),
                with: .color(Color(hex: "A7CE7E").opacity(shimmer))
            )
        }
    }

    private static func drawWeather(
        context: inout GraphicsContext,
        size: CGSize,
        biome: MeadowBiome,
        time: Double
    ) {
        switch biome {
        case .storm:
            for index in 0..<44 {
                let speed = 150.0 + Double(index % 5) * 28
                let x = (Double(index * 97) + time * speed).truncatingRemainder(dividingBy: Double(size.width + 60)) - 30
                let y = (Double(index * 53) + time * speed * 1.25).truncatingRemainder(dividingBy: Double(size.height))
                context.hhPixel(
                    x: CGFloat(x),
                    y: CGFloat(y),
                    width: 1.1,
                    height: 7,
                    color: Color(hex: "D8EDF5").opacity(0.35)
                )
            }
        case .moonlit:
            for index in 0..<22 {
                let x = (sin(time * 0.5 + Double(index) * 1.7) * 0.5 + 0.5) * Double(size.width)
                let y = (cos(time * 0.4 + Double(index) * 0.9) * 0.3 + 0.55) * Double(size.height)
                let alpha = 0.25 + 0.5 * (0.5 + 0.5 * sin(time * 1.8 + Double(index)))
                context.hhPixel(x: CGFloat(x), y: CGFloat(y), width: 2, height: 2, color: Color(hex: "F0C95C").opacity(alpha))
            }
        case .orchard:
            for index in 0..<16 {
                let x = (Double(index * 83) + time * 9).truncatingRemainder(dividingBy: Double(size.width + 40)) - 20
                let y = (Double(index * 47) + time * 18).truncatingRemainder(dividingBy: Double(size.height * 0.6)) + 30
                context.hhPixel(x: CGFloat(x), y: CGFloat(y), width: 3, height: 2, color: Color(hex: "F7B7C7").opacity(0.65))
            }
        default:
            break
        }
    }

    private static func drawVignette(context: inout GraphicsContext, size: CGSize) {
        let edge = Color.black.opacity(0.14)
        context.hhPixel(x: 0, y: 0, width: size.width, height: 6, color: edge)
        context.hhPixel(x: 0, y: size.height - 8, width: size.width, height: 8, color: edge)
    }
}

// MARK: - Drawing helpers

private extension GraphicsContext {
    mutating func hhPixel(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        color: Color
    ) {
        guard width > 0, height > 0 else { return }
        fill(
            Path(CGRect(x: x, y: y, width: width, height: height)),
            with: .color(color)
        )
    }
}

private extension MeadowBiome {
    var emoji: String {
        switch self {
        case .meadow: return "🌿"
        case .orchard: return "🍎"
        case .creek: return "💧"
        case .golden: return "🌾"
        case .moonlit: return "🌙"
        case .storm: return "⛈️"
        }
    }
}

#endif
