#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

/// Why a ``GridConfig`` could not be built from the given inputs.
public enum GridConfigError: Error, Equatable, CustomStringConvertible {
    /// The reel count is outside the supported range for a single-row machine.
    case reelCountOutOfRange(Int)
    /// The symbol count is too small to host a jackpot symbol plus at least one other.
    case tooFewSymbols(Int)

    /// A human-readable explanation, surfaced to the CLI user on a bad flag.
    public var description: String {
        switch self {
        case let .reelCountOutOfRange(reels):
            "reels must be between \(GridConfig.reelRange.lowerBound) and " +
                "\(GridConfig.reelRange.upperBound) (got \(reels))"
        case let .tooFewSymbols(count):
            "need at least 2 symbols to spin (got \(count))"
        }
    }
}

/// A validated grid configuration: an `rows × cols` machine with per-symbol landing odds.
///
/// A single-row machine is `rows == 1` with `cols` columns (the `--reels` mode); the default is
/// the fixed `3 × 3` board. Every face is equally likely — a reel is one strip of the distinct
/// faces, and a stop lands on whatever face is showing, so the jackpot (`7`) is simply 1 in
/// `symbolCount` per cell, like a real machine with no rigging.
public struct GridConfig: Sendable, Equatable {
    /// The supported single-row reel-count range (`1...10`).
    public static let reelRange = 1 ... 10
    /// The side length of the square machine — fixed at `3` (3 rows + 2 diagonals).
    public static let gridSize = 3

    /// Number of rows (1 for a single-row machine).
    public let rows: Int
    /// Number of columns.
    public let cols: Int
    /// How many distinct symbols a cell can land on (index 0 is the jackpot).
    public let symbolCount: Int

    /// Builds a single-row machine of `reels` columns. Throws on a bad reel count.
    public static func singleRow(reels: Int, symbolCount: Int) throws -> GridConfig {
        guard reelRange.contains(reels) else { throw GridConfigError.reelCountOutOfRange(reels) }
        return try GridConfig(rows: 1, cols: reels, symbolCount: symbolCount)
    }

    /// Builds the fixed `3 × 3` square machine (the default). Throws only on too few symbols.
    public static func square(symbolCount: Int) throws -> GridConfig {
        try GridConfig(rows: gridSize, cols: gridSize, symbolCount: symbolCount)
    }

    private init(rows: Int, cols: Int, symbolCount: Int) throws {
        guard symbolCount >= 2 else { throw GridConfigError.tooFewSymbols(symbolCount) }
        self.rows = rows
        self.cols = cols
        self.symbolCount = symbolCount
    }

    /// The number of cells to draw: `rows × cols`.
    public var cellCount: Int {
        rows * cols
    }

    /// The terminal width the grid needs: each column is a `cellWidth` cell plus two borders.
    public func requiredWidth(cellWidth: Int) -> Int {
        (cellWidth + 2) * cols
    }

    /// The terminal height the grid needs: `rows` bands of `cellHeight` art rows, the
    /// `rows - 1` interior rules, a top and bottom border, and one result line of headroom.
    public func requiredHeight(cellHeight: Int) -> Int {
        rows * cellHeight + (rows - 1) + 2 + 1
    }
}
