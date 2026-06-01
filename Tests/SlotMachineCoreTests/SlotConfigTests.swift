@testable import SlotMachineCore
import Testing

struct SlotConfigTests {
    @Test(arguments: [2, 3, 5, 9])
    func acceptsReelCountsInRange(reels: Int) throws {
        let config = try SlotConfig(reels: reels, odds: 0.1, symbolCount: 4)
        #expect(config.reels == reels)
    }

    @Test(arguments: [1, 0, 10, -1])
    func rejectsReelCountsOutOfRange(reels: Int) {
        #expect(throws: SlotConfigError.reelCountOutOfRange(reels)) {
            try SlotConfig(reels: reels, odds: 0.1, symbolCount: 4)
        }
    }

    @Test(arguments: [0.01, 0.1, 0.5, 1.0])
    func acceptsOddsInRange(odds: Double) throws {
        let config = try SlotConfig(reels: 3, odds: odds, symbolCount: 4)
        #expect(config.odds == odds)
    }

    @Test(arguments: [0.0, -0.1, 1.5, 2.0])
    func rejectsOddsOutOfRange(odds: Double) {
        #expect(throws: SlotConfigError.oddsOutOfRange(odds)) {
            try SlotConfig(reels: 3, odds: odds, symbolCount: 4)
        }
    }

    @Test(arguments: [1, 0, -3])
    func rejectsTooFewSymbols(symbolCount: Int) {
        #expect(throws: SlotConfigError.tooFewSymbols(symbolCount)) {
            try SlotConfig(reels: 3, odds: 0.1, symbolCount: symbolCount)
        }
    }

    @Test
    func weightsSumToOneAndLeadWithTheJackpotOdds() throws {
        let config = try SlotConfig(reels: 3, odds: 0.1, symbolCount: 4)
        let weights = config.weights
        #expect(weights.count == 4)
        #expect(weights.first == 0.1)
        #expect(abs(weights.reduce(0, +) - 1.0) < 1e-12)
        // The non-jackpot symbols share the remaining 0.9 evenly.
        #expect(weights.dropFirst().allSatisfy { abs($0 - 0.3) < 1e-12 })
    }

    @Test(arguments: [
        (2, 0.1, 0.01),
        (3, 0.1, 0.001),
        (7, 0.5, 0.0078125),
    ])
    func jackpotProbabilityIsOddsToThePowerOfReels(reels: Int, odds: Double, expected: Double) throws {
        let config = try SlotConfig(reels: reels, odds: odds, symbolCount: 4)
        #expect(abs(config.jackpotProbability - expected) < 1e-12)
    }

    @Test
    func requiredWidthCountsEveryReelPlusItsBorders() throws {
        let config = try SlotConfig(reels: 9, odds: 0.1, symbolCount: 4)
        #expect(config.requiredWidth(cellWidth: 6) == (6 + 2) * 9)
    }
}
