@testable import SlotMachineCore
import Testing

struct GridConfigTests {
    @Test(arguments: [1, 3, 10])
    func singleRowAcceptsReelsInRange(reels: Int) throws {
        let config = try GridConfig.singleRow(reels: reels, symbolCount: 8)
        #expect(config.rows == 1)
        #expect(config.cols == reels)
    }

    @Test(arguments: [0, 11, -1])
    func singleRowRejectsReelsOutOfRange(reels: Int) {
        #expect(throws: GridConfigError.reelCountOutOfRange(reels)) {
            try GridConfig.singleRow(reels: reels, symbolCount: 8)
        }
    }

    @Test
    func squareIsTheFixedThreeByThreeBoard() throws {
        let config = try GridConfig.square(symbolCount: 8)
        #expect(config.rows == GridConfig.gridSize)
        #expect(config.cols == GridConfig.gridSize)
        #expect(config.cellCount == GridConfig.gridSize * GridConfig.gridSize)
    }

    @Test(arguments: [1, 0, -1])
    func rejectsTooFewSymbols(symbolCount: Int) {
        #expect(throws: GridConfigError.tooFewSymbols(symbolCount)) {
            try GridConfig.square(symbolCount: symbolCount)
        }
    }

    @Test
    func requiredWidthAndHeightCountBordersAndRules() throws {
        let config = try GridConfig.square(symbolCount: 8)
        #expect(config.requiredWidth(cellWidth: 6) == (6 + 2) * 3)
        // 3 bands × cellHeight 5 + 2 interior rules + 2 borders + 1 headroom
        #expect(config.requiredHeight(cellHeight: 5) == 3 * 5 + 2 + 2 + 1)
    }
}
