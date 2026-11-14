import Foundation

/// Deterministic market helpers. Prices move a little every in-game day so
/// that selling is a small, pleasant decision rather than a fixed exchange.
public enum Market {
    public static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }

    public static func multiplier(itemID: String, day: Int) -> Double {
        let spread = Int(stableHash("\(itemID)|\(day)") % 47)
        return 0.82 + Double(spread) / 100.0
    }

    public static func sellPrice(base: Int, itemID: String, day: Int, comfort: Int) -> Int {
        guard base > 0 else { return 0 }
        let comfortBonus = 1.0 + min(0.25, Double(comfort) / 100.0)
        let raw = Double(base) * multiplier(itemID: itemID, day: day) * comfortBonus
        return max(1, Int(raw.rounded()))
    }
}
