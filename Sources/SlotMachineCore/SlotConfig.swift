#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

/// Why a ``SlotConfig`` could not be built from the given inputs.
public enum SlotConfigError: Error, Equatable, CustomStringConvertible {
    /// The reel count is outside the supported 2…9 range.
    case reelCountOutOfRange(Int)
    /// The per-reel jackpot odds are not in the open-to-closed range (0, 1].
    case oddsOutOfRange(Double)
    /// The symbol count is too small to host a jackpot symbol plus at least one other.
    case tooFewSymbols(Int)

    /// A human-readable explanation, surfaced to the CLI user on a bad flag.
    public var description: String {
        switch self {
        case let .reelCountOutOfRange(reels):
            "reels must be between \(SlotConfig.reelRange.lowerBound) and \(SlotConfig.reelRange.upperBound) (got \(reels))"
        case let .oddsOutOfRange(odds):
            "odds must be greater than 0 and at most 1 (got \(odds))"
        case let .tooFewSymbols(count):
            "need at least 2 symbols to spin (got \(count))"
        }
    }
}

/// A validated slot configuration: how many reels spin and the per-symbol landing odds.
///
/// The jackpot symbol (index 0) lands with probability `odds`; the remaining `1 - odds`
/// is split evenly across the other symbols. So with `N` reels the jackpot line happens
/// with probability `odds^N`, and any same-symbol line with `odds^N + (other_freq^N) × (symbolCount - 1)`.
public struct SlotConfig: Sendable, Equatable {
    /// The supported reel-count range (`2...9`).
    public static let reelRange = 2 ... 9

    /// Number of reels that spin (2…9).
    public let reels: Int
    /// Per-reel probability the jackpot symbol (index 0) is drawn.
    public let odds: Double
    /// How many distinct symbols a reel can land on (index 0 is the jackpot).
    public let symbolCount: Int

    /// Builds a validated config, or throws ``SlotConfigError`` if any input is out of range.
    ///
    /// - Parameters:
    ///   - reels: reel count; must be in ``reelRange``.
    ///   - odds: per-reel jackpot probability; must be in `(0, 1]`.
    ///   - symbolCount: distinct landing faces; must be at least 2 (jackpot + one other).
    public init(reels: Int, odds: Double, symbolCount: Int) throws {
        guard Self.reelRange.contains(reels) else {
            throw SlotConfigError.reelCountOutOfRange(reels)
        }
        guard odds > 0, odds <= 1 else {
            throw SlotConfigError.oddsOutOfRange(odds)
        }
        guard symbolCount >= 2 else {
            throw SlotConfigError.tooFewSymbols(symbolCount)
        }
        self.reels = reels
        self.odds = odds
        self.symbolCount = symbolCount
    }

    /// The per-symbol landing weights: index 0 (jackpot) is `odds`, and the remaining
    /// `1 - odds` is spread evenly across the other `symbolCount - 1` symbols. Sums to 1.
    public var weights: [Double] {
        let others = Double(symbolCount - 1)
        let rest = (1 - odds) / others
        return [odds] + Array(repeating: rest, count: symbolCount - 1)
    }

    /// The probability every reel lands on the jackpot symbol — `odds^reels`.
    public var jackpotProbability: Double {
        pow(odds, Double(reels))
    }

    /// The terminal width, in columns, the spinning grid needs: each reel is a `cellWidth`
    /// cell plus its two border columns. Below this the animated grid wraps and the in-place
    /// redraw desyncs, so the caller should fall back to plain output on a narrower terminal.
    public func requiredWidth(cellWidth: Int) -> Int {
        (cellWidth + 2) * reels
    }
}
