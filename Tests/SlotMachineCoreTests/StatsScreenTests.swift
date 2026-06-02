@testable import SlotMachineCore
import Testing

struct StatsScreenTests {
    private static func stats(games: Int, wins: Int, jackpots: Int) -> GameStats {
        var tally = GameStats.empty
        for index in 0 ..< games {
            let didWin = index < wins
            let isJackpot = index < jackpots
            tally = tally.recording(GameOutcome(didWin: didWin, isJackpot: isJackpot, lineCount: didWin ? 1 : 0))
        }
        return tally
    }

    @Test
    func displayWidthCountsWideGlyphsAsTwo() {
        #expect(StatsScreen.width(of: "🎰") == 2) // emoji
        #expect(StatsScreen.width(of: "★") == 2) // wide symbol (rendered double-width)
        #expect(StatsScreen.width(of: "abc") == 3)
        #expect(StatsScreen.width(of: "\u{1B}[1mX\u{1B}[22m") == 1) // ANSI ignored
    }

    @Test
    func everyColoredRowIsTheSameDisplayWidth() {
        // The panel must be a clean rectangle — every row (border to border) lines up. With a
        // jackpot present, the title (🎰), streak (🔥), and jackpot callout (★) rows all carry
        // wide glyphs, so this catches the lopsided-border bug.
        let lines = StatsScreen.coloredLines(Self.stats(games: 10, wins: 6, jackpots: 3))
        let widths = Set(lines.map { StatsScreen.width(of: $0) })
        #expect(widths.count == 1)
    }

    @Test
    func everyColoredRowAlignsEvenWithNoJackpot() {
        let lines = StatsScreen.coloredLines(Self.stats(games: 10, wins: 0, jackpots: 0))
        let widths = Set(lines.map { StatsScreen.width(of: $0) })
        #expect(widths.count == 1)
    }

    @Test
    func plainRenderHasNoAnsiEscapes() {
        let text = StatsScreen.render(Self.stats(games: 5, wins: 2, jackpots: 1), color: false)
        #expect(!text.contains("\u{1B}"))
        #expect(text.contains("games:    5"))
    }
}
