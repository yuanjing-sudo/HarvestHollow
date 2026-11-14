import Foundation

public struct SaveEnvelope: Codable, Sendable {
    public let version: Int
    public let savedAt: Date
    public let state: GameState

    public init(version: Int, savedAt: Date, state: GameState) {
        self.version = version
        self.savedAt = savedAt
        self.state = state
    }
}

public enum SaveError: Error, LocalizedError, Equatable {
    case unsupportedVersion(Int)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "This save was created by a newer version of Harvest Hollow (save v\(version))."
        case .invalidData:
            return "The save file could not be read."
        }
    }
}

public enum SaveCodec {
    public static func encode(_ state: GameState, savedAt: Date = Date()) throws -> Data {
        var snapshot = state
        snapshot.lastSavedAt = savedAt
        let envelope = SaveEnvelope(
            version: GameConstants.saveVersion,
            savedAt: savedAt,
            state: snapshot
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    public static func decode(_ data: Data) throws -> GameState {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let envelope: SaveEnvelope
        do {
            envelope = try decoder.decode(SaveEnvelope.self, from: data)
        } catch {
            throw SaveError.invalidData
        }
        guard envelope.version <= GameConstants.saveVersion else {
            throw SaveError.unsupportedVersion(envelope.version)
        }
        return envelope.state
    }

    public static func exportString(_ state: GameState) throws -> String {
        let data = try encode(state)
        return data.base64EncodedString()
    }

    public static func importString(_ string: String) throws -> GameState {
        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: cleaned) else {
            throw SaveError.invalidData
        }
        return try decode(data)
    }
}

/// Atomic, human-readable JSON persistence in Application Support.
public final class SaveStore {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static func defaultURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("HarvestHollow", isDirectory: true)
        return folder.appendingPathComponent("save.json")
    }

    public var backupURL: URL {
        url.deletingLastPathComponent().appendingPathComponent("save.backup.json")
    }

    public func load() throws -> GameState? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try SaveCodec.decode(data)
    }

    public func loadBackup() throws -> GameState? {
        guard FileManager.default.fileExists(atPath: backupURL.path) else { return nil }
        let data = try Data(contentsOf: backupURL)
        return try SaveCodec.decode(data)
    }

    public func save(_ state: GameState, at date: Date = Date()) throws {
        let data = try SaveCodec.encode(state, savedAt: date)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: url, to: backupURL)
        }

        try data.write(to: url, options: .atomic)
    }

    public func delete() throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
    }
}
