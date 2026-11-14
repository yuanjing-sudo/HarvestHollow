#if canImport(SwiftUI)
import SwiftUI
import HarvestHollowCore

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Settings

public struct SettingsSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var showResetConfirm = false
    @State private var showExport = false
    @State private var showImport = false
    @State private var exportCode = ""

    public init() {}

    private var state: GameState { store.state }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                preferencesCard
                saveCard
                aboutCard
                resetCard
                footer
            }
            .padding(18)
        }
        .background(HHTheme.cream)
        .scrollIndicators(.hidden)
        .alert("Reset the farm?", isPresented: $showResetConfirm) {
            Button("Reset everything", role: .destructive) {
                store.resetGame()
                dismiss()
            }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("This erases the current save and starts a brand-new farm. There is no undo.")
        }
        .sheet(isPresented: $showExport) {
            ExportCodeSheet(code: exportCode)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showImport) {
            ImportCodeSheet()
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Settings")
                    .font(.hhTitle(25))
                    .foregroundStyle(HHTheme.ink)
                Text("Sound, saving, and the little details.")
                    .font(.hhBody(12.5))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 6)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 23))
                    .foregroundStyle(HHTheme.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close settings")
        }
    }

    // MARK: Preferences

    private var preferencesCard: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Preferences", icon: "slider.horizontal.3")

                Toggle(isOn: soundBinding) {
                    settingLabel(
                        icon: "speaker.wave.2.fill",
                        title: "Sound effects",
                        subtitle: "Soft pops and harvest chimes.",
                        tint: HHTheme.forest
                    )
                }
                .tint(HHTheme.forest)

                Divider().overlay(HHTheme.ink.opacity(0.07))

                Toggle(isOn: hapticsBinding) {
                    settingLabel(
                        icon: "hand.tap.fill",
                        title: "Haptics",
                        subtitle: "A gentle tap for actions and level-ups.",
                        tint: HHTheme.rose
                    )
                }
                .tint(HHTheme.rose)
            }
        }
    }

    private func settingLabel(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.hhHeadline(13.5))
                    .foregroundStyle(HHTheme.ink)
                Text(subtitle)
                    .font(.hhCaption(10.5))
                    .foregroundStyle(HHTheme.muted)
            }
            Spacer(minLength: 0)
        }
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { state.settings.soundEnabled },
            set: { _ in store.toggleSound() }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { state.settings.hapticsEnabled },
            set: { _ in store.toggleHaptics() }
        )
    }

    // MARK: Save

    private var saveCard: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 11) {
                SectionHeader(
                    "Your save",
                    subtitle: "The farm autosaves every 20 seconds and whenever the app closes.",
                    icon: "externaldrive.fill"
                )

                HStack(spacing: 8) {
                    Image(systemName: store.saveStatus.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(store.saveStatus.tint)
                    Text(store.saveStatus.text)
                        .font(.hhHeadline(12.5))
                        .foregroundStyle(HHTheme.ink)
                    Spacer(minLength: 0)
                    Text("Day \(state.day) · Level \(state.level)")
                        .font(.hhCaption(10))
                        .foregroundStyle(HHTheme.muted)
                }
                .padding(10)
                .background(HHTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack(spacing: 7) {
                    Button {
                        store.saveNow()
                    } label: {
                        Label("Save now", systemImage: "arrow.down.doc.fill")
                            .font(.hhHeadline(11))
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.forest))

                    Button {
                        exportCode = (try? SaveCodec.exportString(store.state)) ?? ""
                        if !exportCode.isEmpty {
                            showExport = true
                        }
                    } label: {
                        Label("Export code", systemImage: "square.and.arrow.up")
                            .font(.hhHeadline(11))
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.goldDeep))

                    Button {
                        showImport = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .font(.hhHeadline(11))
                    }
                    .buttonStyle(MiniActionStyle(tint: HHTheme.terracotta))
                }
            }
        }
    }

    // MARK: About

    private var aboutCard: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader("About", icon: "leaf.fill")

                HStack(spacing: 10) {
                    Text("🌾")
                        .font(.system(size: 26))
                        .frame(width: 42, height: 42)
                        .background(HHTheme.gold.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Harvest Hollow")
                            .font(.hhHeadline(14))
                            .foregroundStyle(HHTheme.ink)
                        Text("Version 1.0 · built entirely with SwiftUI")
                            .font(.hhCaption(10.5))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                }

                Text("A small pixel-art farming game about quiet mornings, good soil, and the friends waiting in the barn.")
                    .font(.hhBody(12))
                    .foregroundStyle(HHTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    TagChip("\(state.stats.cropsHarvested) harvests", icon: "basket.fill", tint: HHTheme.goldDeep)
                    TagChip("\(state.stats.questsCompleted) quests", icon: "checkmark.seal.fill", tint: HHTheme.forest)
                    TagChip("\(state.flags.totalDaysPlayed) days", icon: "sun.max.fill", tint: HHTheme.terracotta)
                }
            }
        }
    }

    // MARK: Reset

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Danger zone")
                .font(.hhCaption(10.5))
                .foregroundStyle(HHTheme.terracotta)
                .textCase(.uppercase)
                .tracking(0.6)

            Button {
                showResetConfirm = true
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13, weight: .bold))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Reset the farm")
                            .font(.hhHeadline(13))
                        Text("Erase the save and begin again.")
                            .font(.hhCaption(10))
                            .foregroundStyle(HHTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(HHTheme.muted)
                }
                .foregroundStyle(HHTheme.terracotta)
                .padding(12)
                .background(HHTheme.terracotta.opacity(0.07), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(HHTheme.terracotta.opacity(0.17), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        Text("Made with care in the Hollow · SwiftUI + Swift")
            .font(.hhCaption(10))
            .foregroundStyle(HHTheme.muted.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
    }
}

// MARK: - Export

struct ExportCodeSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    init(code: String) {
        self.code = code
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Save code")
                        .font(.hhTitle(23))
                        .foregroundStyle(HHTheme.ink)
                    Text("Keep this somewhere safe. Anyone with the code can load your farm.")
                        .font(.hhBody(12))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 6)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(HHTheme.muted)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                Text(code)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(HHTheme.ink.opacity(0.8))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(11)
            }
            .frame(height: 230)
            .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(HHTheme.ink.opacity(0.1), lineWidth: 1)
            )

            HStack(spacing: 8) {
                Button {
                    copyToClipboard(code)
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy code", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(CozySecondaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(HHTheme.cream)
        .onChange(of: copied) { _, newValue in
            guard newValue else { return }
            Task {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                copied = false
            }
        }
    }
}

// MARK: - Import

struct ImportCodeSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var errorText: String?
    @State private var showReplaceConfirm = false

    init() {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Load a save")
                        .font(.hhTitle(23))
                        .foregroundStyle(HHTheme.ink)
                    Text("Paste a Harvest Hollow save code below.")
                        .font(.hhBody(12))
                        .foregroundStyle(HHTheme.muted)
                }
                Spacer(minLength: 6)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(HHTheme.muted)
                }
                .buttonStyle(.plain)
            }

            TextEditor(text: $code)
                .font(.system(size: 10, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(9)
                .frame(height: 230)
                .background(HHTheme.paper, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(HHTheme.ink.opacity(0.1), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if code.isEmpty {
                        Text("Paste save code here…")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(HHTheme.muted.opacity(0.7))
                            .padding(15)
                            .allowsHitTesting(false)
                    }
                }

            if let errorText {
                NoticeBanner(
                    icon: "exclamationmark.triangle.fill",
                    title: "Could not load that save",
                    message: errorText,
                    tint: HHTheme.terracotta
                )
            }

            NoticeBanner(
                icon: "exclamationmark.arrow.triangle.2.circlepath",
                title: "This replaces the current farm",
                message: "The save is loaded right away and the current farm is overwritten.",
                tint: HHTheme.goldDeep
            )

            HStack(spacing: 8) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(CozySecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button {
                    load()
                } label: {
                    Label("Load save", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPrimaryButtonStyle())
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
        }
        .padding(18)
        .background(HHTheme.cream)
        .alert("Replace the current farm?", isPresented: $showReplaceConfirm) {
            Button("Load save", role: .destructive) {
                applyImport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current farm will be replaced and saved immediately.")
        }
    }

    private func load() {
        errorText = nil
        do {
            _ = try SaveCodec.importString(code)
            showReplaceConfirm = true
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func applyImport() {
        do {
            let imported = try SaveCodec.importString(code)
            store.importSave(imported)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}

// MARK: - Clipboard

private func copyToClipboard(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #endif
}
#endif
