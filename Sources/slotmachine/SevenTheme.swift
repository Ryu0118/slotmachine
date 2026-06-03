import SlotKit
import SlotMachineCore

/// The slot machine's faces and look: eight symbols — a `7` (the jackpot), `BAR`, cherry,
/// bell, plum, orange, grape, and diamond — the kind of spread a real slot machine carries.
///
/// Cells are `8 × 5`. Each face is written as its raw art and **centered into the cell
/// width** by ``symbol(_:)``, so every face sits symmetrically (equal margins) with no
/// hand-counted padding to get wrong. Eight reels still fit a 100-column terminal; wider
/// grids fall back to plain when the window is too small. Index 0 is the `7`.
enum SevenTheme {
    /// How many distinct faces a cell can land on (the `symbols` count). Fixed by `faces`, so
    /// the CLI can size the grid before building the theme.
    static let symbolCount = faces.count
    private static let cellWidth = 8
    private static let cellHeight = 5

    private static let faces = [seven, bar, cherry, bell, plum, orange, grape, diamond]

    /// The per-lane reel strips as ``SlotTheme/symbols`` indices — one strip per column, what a
    /// stop lands on. The `7` (index 0) is weighted differently per reel like a real machine:
    /// generous on the first reel, single and rare on the last (see ``laneStrip(_:of:)``), so
    /// catching three `7`s takes the timing the final reel demands rather than a learnable knack.
    static func laneStripIndices(laneCount: Int) -> [[Int]] {
        (0 ..< max(laneCount, 1)).map { laneStrip($0, of: laneCount) }
    }

    /// Builds the slot theme with per-lane reel strips for `laneCount` columns: the `7` is
    /// weighted differently on each reel (generous first, scarce last) like a real machine, so a
    /// hand stop lands on whatever's showing on that reel's strip. Throws ``SlotThemeError`` only
    /// on malformed art (it isn't — ``symbol(_:)`` centers every row), so callers can treat this
    /// as non-failing.
    static func make(laneCount: Int) throws -> SlotTheme {
        let strips = laneStripIndices(laneCount: laneCount).map { strip in strip.map { faces[$0] } }
        return try SlotTheme.make { draft in
            draft.cellWidth = cellWidth
            draft.cellHeight = cellHeight
            draft.symbols = faces
            draft.jackpotIndex = 0
            draft.spinning = faces
            draft.spinningStrips = strips
            // `win` / `lose` are unused by the symbol path but required by the validator.
            draft.win = seven
            draft.lose = bar
            draft.colorize = SlotColorizers.rainbow
            // Reels scroll one art row per frame; at this interval a face slides past fast
            // enough that a hand stop can't easily catch the 7 (a real skill stop).
            draft.frameInterval = 0.010
            // The gate (keypress / timer) controls when each reel stops, so no minimum spin —
            // otherwise a reel would keep spinning for minSpin after it is released.
            draft.minSpin = 0
            // Reels scroll their faces vertically like a real machine (a face slides down the
            // window) instead of swapping whole each frame. A face dwells `cellHeight` frames,
            // so the spin also reads at a watchable speed.
            draft.scrollSpin = true
            draft.finale = SlotTheme.SlotFinale(frames: 10, interval: 0.1)
            draft.bust = SlotTheme.SlotFinale(frames: 6, interval: 0.18)
        }
    }

    /// The strip (as `symbols` indices) for lane `lane` of `laneCount`. Every reel carries
    /// exactly one `7` (index 0); the reels differ in **length**, so the `7`'s per-cell chance
    /// falls off down the row — 1/8 on the first reel, 1/12 in the middle, 1/16 on the last —
    /// the scarce-final-reel weighting a real machine uses. One `7` per strip means it can never
    /// show twice (or as a vertical triple) in a column, and no face is circularly adjacent to
    /// itself, so a column never repeats a face.
    private static func laneStrip(_ lane: Int, of laneCount: Int) -> [Int] {
        let isLast = lane == laneCount - 1
        if lane == 0 {
            // The eight faces once — the most generous reel (7 chance 1/8).
            return [0, 1, 2, 3, 4, 5, 6, 7]
        }
        if isLast {
            // One 7 on the longest strip — the scarce final reel (7 chance 1/16), the gate.
            return [0, 1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4, 5, 6, 7, 2]
        }
        // One 7 on a medium strip — a middle reel (7 chance 1/12).
        return [0, 1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4]
    }

    /// Centers each raw art row into the cell width (left-biased on odd padding), padding to
    /// exactly `cellHeight` rows — so a face is declared by its shape alone and always
    /// validates, however ragged the source lines are.
    private static func symbol(_ art: [String]) -> SlotSymbol {
        var rows = art.prefix(cellHeight).map(center)
        while rows.count < cellHeight {
            rows.append(String(repeating: " ", count: cellWidth))
        }
        return SlotSymbol(rows: rows)
    }

    private static func center(_ text: String) -> String {
        let trimmed = text.count > cellWidth ? String(text.prefix(cellWidth)) : text
        let pad = cellWidth - trimmed.count
        let left = pad / 2
        return String(repeating: " ", count: left) + trimmed + String(repeating: " ", count: pad - left)
    }

    private static let seven = symbol([
        "██████",
        "   ██",
        "  ██",
        " ██",
        " ██",
    ])

    private static let cherry = symbol([
        "/",
        "o",
        "(_)",
        "(_)(_)",
        "(_)",
    ])

    private static let bar = symbol([
        "╔════╗",
        "║▄▄▄▄║",
        "║ BAR║",
        "║▀▀▀▀║",
        "╚════╝",
    ])

    private static let bell = symbol([
        "▄▄",
        "▟██▙",
        "████",
        "████",
        "▀▀",
    ])

    private static let plum = symbol([
        "__",
        "/  \\",
        "|    |",
        "\\__/",
        "",
    ])

    private static let orange = symbol([
        "||",
        ".--.",
        "/ XX \\",
        "\\ XX /",
        "'--'",
    ])

    private static let grape = symbol([
        "o o",
        "o o o",
        "o o",
        "o",
        "",
    ])

    private static let diamond = symbol([
        "/\\",
        "/  \\",
        "<    >",
        "\\  /",
        "\\/",
    ])
}
