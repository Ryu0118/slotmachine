@testable import SlotMachineCore
import Testing

struct GridConfigTests {
    @Test(arguments: [1, 3, 10])
    func singleRowAcceptsReelsInRange(reels: Int) throws {
        let config = try GridConfig.singleRow(reels: reels, odds: 0.1, symbolCount: 8)
        #expect(config.rows == 1)
        #expect(config.cols == reels)
    }

    @Test(arguments: [0, 11, -1])
    func singleRowRejectsReelsOutOfRange(reels: Int) {
        #expect(throws: GridConfigError.reelCountOutOfRange(reels)) {
            try GridConfig.singleRow(reels: reels, odds: 0.1, symbolCount: 8)
        }
    }

    @Test(arguments: [3, 5, 9])
    func squareAcceptsSizeInRange(size: Int) throws {
        let config = try GridConfig.square(size: size, odds: 0.1, symbolCount: 8)
        #expect(config.rows == size)
        #expect(config.cols == size)
        #expect(config.cellCount == size * size)
    }

    @Test(arguments: [2, 10, 0])
    func squareRejectsSizeOutOfRange(size: Int) {
        #expect(throws: GridConfigError.gridSizeOutOfRange(size)) {
            try GridConfig.square(size: size, odds: 0.1, symbolCount: 8)
        }
    }

    @Test(arguments: [0.0, 1.5, -0.1])
    func rejectsOddsOutOfRange(odds: Double) {
        #expect(throws: GridConfigError.oddsOutOfRange(odds)) {
            try GridConfig.singleRow(reels: 3, odds: odds, symbolCount: 8)
        }
    }

    @Test
    func weightsSumToOneAndLeadWithTheJackpotOdds() throws {
        let config = try GridConfig.square(size: 3, odds: 0.1, symbolCount: 8)
        let weights = config.weights
        #expect(weights.count == 8)
        #expect(weights.first == 0.1)
        #expect(abs(weights.reduce(0, +) - 1.0) < 1e-12)
    }

    @Test
    func requiredWidthAndHeightCountBordersAndRules() throws {
        let config = try GridConfig.square(size: 3, odds: 0.1, symbolCount: 8)
        #expect(config.requiredWidth(cellWidth: 6) == (6 + 2) * 3)
        // 3 bands × cellHeight 5 + 2 interior rules + 2 borders + 1 headroom
        #expect(config.requiredHeight(cellHeight: 5) == 3 * 5 + 2 + 2 + 1)
    }
}
