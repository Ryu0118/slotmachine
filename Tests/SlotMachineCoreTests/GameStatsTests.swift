@testable import SlotMachineCore
import Testing

struct GameStatsTests {
    private static func win(jackpot: Bool = false, lines: Int = 1) -> GameOutcome {
        GameOutcome(didWin: true, isJackpot: jackpot, lineCount: lines)
    }

    private static let loss = GameOutcome(didWin: false, isJackpot: false, lineCount: 0)

    private static func fold(_ outcomes: [GameOutcome]) -> GameStats {
        outcomes.reduce(.empty) { $0.recording($1) }
    }

    @Test
    func emptyHasZeroRates() {
        #expect(GameStats.empty.games == 0)
        #expect(GameStats.empty.winRate == 0)
        #expect(GameStats.empty.jackpotRate == 0)
    }

    @Test
    func talliesGamesWinsJackpotsAndLines() {
        let stats = Self.fold([Self.win(lines: 2), Self.loss, Self.win(jackpot: true, lines: 5)])
        #expect(stats.games == 3)
        #expect(stats.wins == 2)
        #expect(stats.jackpots == 1)
        #expect(stats.totalLines == 7)
    }

    @Test
    func winRateAndJackpotRate() {
        let stats = Self.fold([Self.win(), Self.win(jackpot: true), Self.loss, Self.loss])
        #expect(abs(stats.winRate - 0.5) < 1e-12)
        #expect(abs(stats.jackpotRate - 0.25) < 1e-12)
    }

    @Test
    func currentStreakResetsOnLoss() {
        let stats = Self.fold([Self.win(), Self.win(), Self.loss])
        #expect(stats.currentStreak == 0)
    }

    @Test
    func bestStreakKeepsTheLongestRun() {
        let stats = Self.fold([Self.win(), Self.win(), Self.win(), Self.loss, Self.win()])
        #expect(stats.bestStreak == 3)
        #expect(stats.currentStreak == 1)
    }

    @Test
    func recordingIsAPureFold() {
        // The same outcomes folded twice yield equal tallies — no shared mutable state.
        let outcomes = [Self.win(), Self.loss, Self.win(jackpot: true)]
        #expect(Self.fold(outcomes) == Self.fold(outcomes))
    }
}
