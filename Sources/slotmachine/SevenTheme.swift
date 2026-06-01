import SlotKit

/// The slot machine's faces and look: a `7` (the jackpot), a cherry, a `BAR`, and a bell.
///
/// Cells are a compact 6×5 so that even nine reels (≈ `(6+2)×9 = 72` columns) fit inside a
/// standard 80-column terminal without the lines wrapping — wrapping would desync SlotKit's
/// in-place redraw. Index 0 is the `7`, wired to the theme's `jackpotIndex`.
enum SevenTheme {
    /// Builds the slot theme. Throws ``SlotThemeError`` only if the bundled art is malformed
    /// (it isn't — the dimensions are fixed), so callers can treat this as non-failing.
    static func make() throws -> SlotTheme {
        try SlotTheme.make { draft in
            draft.cellWidth = 6
            draft.cellHeight = 5
            draft.symbols = [seven, cherry, bar, bell]
            draft.jackpotIndex = 0
            draft.spinning = [seven, cherry, bar, bell]
            // `win` / `lose` are unused by the symbol path but required by the validator.
            draft.win = seven
            draft.lose = bar
            draft.colorize = SlotColorizers.rainbow
            draft.frameInterval = 0.08
            draft.minSpin = 1.0
            draft.finale = SlotTheme.SlotFinale(frames: 10, interval: 0.1)
            draft.bust = SlotTheme.SlotFinale(frames: 6, interval: 0.18)
        }
    }

    private static let seven = SlotSymbol(rows: [
        "██████",
        "   ██ ",
        "  ██  ",
        " ██   ",
        " ██   ",
    ])

    private static let cherry = SlotSymbol(rows: [
        "   /  ",
        "  o   ",
        " (_)  ",
        "(_)(_)",
        " (_)  ",
    ])

    private static let bar = SlotSymbol(rows: [
        "╔════╗",
        "║ ▄▄ ║",
        "║ ██ ║",
        "║ ▀▀ ║",
        "╚════╝",
    ])

    private static let bell = SlotSymbol(rows: [
        " ▄▄▄  ",
        "▐███▌ ",
        "▐███▌ ",
        "█████ ",
        "  ▀   ",
    ])
}
