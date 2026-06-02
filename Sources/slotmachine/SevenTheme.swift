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
    private static let cellWidth = 8
    private static let cellHeight = 5
    /// The weighted spinning pool's length — long enough to render odds like 0.1 reasonably.
    private static let poolLength = 40

    private static let faces = [seven, bar, cherry, bell, plum, orange, grape, diamond]

    /// Builds the slot theme. When `skillOdds` is given, the spinning pool is **weighted** so
    /// the `7` scrolls by only about that fraction of the time — a skill stop then catches it
    /// with that probability. Without it the pool is the eight faces evenly (for the auto path,
    /// which draws its outcome up front). Throws ``SlotThemeError`` only on malformed art (it
    /// isn't — ``symbol(_:)`` centers every row), so callers can treat this as non-failing.
    static func make(skillOdds: Double? = nil) throws -> SlotTheme {
        let spinningFaces: [SlotSymbol] = if let skillOdds {
            SlotOdds.weightedPool(symbolCount: faces.count, jackpotOdds: skillOdds, length: poolLength)
                .map { faces[$0] }
        } else {
            faces
        }
        return try SlotTheme.make { draft in
            draft.cellWidth = cellWidth
            draft.cellHeight = cellHeight
            draft.symbols = faces
            draft.jackpotIndex = 0
            draft.spinning = spinningFaces
            // `win` / `lose` are unused by the symbol path but required by the validator.
            draft.win = seven
            draft.lose = bar
            draft.colorize = SlotColorizers.rainbow
            draft.frameInterval = 0.08
            // The gate (keypress / timer) controls when each reel stops, so no minimum spin —
            // otherwise a reel would keep spinning for minSpin after it is released.
            draft.minSpin = 0
            draft.finale = SlotTheme.SlotFinale(frames: 10, interval: 0.1)
            draft.bust = SlotTheme.SlotFinale(frames: 6, interval: 0.18)
        }
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
