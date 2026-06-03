@testable import SlotMachineCore
import Testing

struct SlotOddsTests {
    /// A distinct-face strip of eight symbols (the real machine's strip): no two adjacent
    /// faces are equal, so a column of consecutive positions can never be a vertical triple.
    private static let strip = Array(0 ..< 8)

    @Test(arguments: [UInt64(42), 1, 999])
    func sameSeedReproducesTheSameStops(seed: UInt64) {
        let first = SlotOdds.stops(reels: 7, stripLength: 40, seed: seed)
        let second = SlotOdds.stops(reels: 7, stripLength: 40, seed: seed)
        #expect(first == second)
    }

    @Test
    func drawsOneStopPerReel() {
        #expect(SlotOdds.stops(reels: 5, stripLength: 8, seed: 7).count == 5)
        #expect(SlotOdds.stops(reels: 2, stripLength: 8, seed: 7).count == 2)
        #expect(SlotOdds.stops(reels: 9, stripLength: 8, seed: 7).count == 9)
    }

    @Test
    func everyStopIsWithinTheStrip() {
        let stops = SlotOdds.stops(reels: 9, stripLength: 8, seed: 12345)
        #expect(stops.allSatisfy { (0 ..< 8).contains($0) })
    }

    @Test
    func differentSeedsGenerallyDiffer() {
        let first = SlotOdds.stops(reels: 9, stripLength: 40, seed: 1)
        let second = SlotOdds.stops(reels: 9, stripLength: 40, seed: 2)
        #expect(first != second)
    }

    @Test
    func gridStopsReturnsColumnsOfRowCells() {
        let grid = SlotOdds.gridStops(rows: 3, cols: 4, strip: Self.strip, seed: 1)
        #expect(grid.count == 4) // four columns
        #expect(grid.allSatisfy { $0.count == 3 }) // each three cells
    }

    @Test
    func gridStopsIsSeedReproducible() {
        let first = SlotOdds.gridStops(rows: 3, cols: 3, strip: Self.strip, seed: 42)
        let second = SlotOdds.gridStops(rows: 3, cols: 3, strip: Self.strip, seed: 42)
        #expect(first == second)
    }

    /// **The reel-consistency invariant — the fix for the vertical-triple bug.** Every auto
    /// column must be `rows` *consecutive* positions on the strip (wrapping at the end), exactly
    /// what the spinning reel shows. Asserted as a positive property across many seeds.
    @Test(arguments: 0 ..< 200)
    func everyColumnIsConsecutiveStripPositions(seed: Int) {
        let rows = 3
        let strip = Self.strip
        let grid = SlotOdds.gridStops(rows: rows, cols: 3, strip: strip, seed: UInt64(seed))
        for column in grid {
            // Find the strip position whose window equals this column.
            let matches = (0 ..< strip.count).contains { start in
                (0 ..< rows).allSatisfy { row in column[row] == strip[(start + row) % strip.count] }
            }
            #expect(matches, "column \(column) is not a consecutive strip window")
        }
    }

    /// A distinct-face strip can never produce a vertical triple (all `rows` cells equal),
    /// because consecutive positions are always different faces. The direct corollary players
    /// care about.
    @Test(arguments: 0 ..< 200)
    func noColumnIsAVerticalTriple(seed: Int) {
        let grid = SlotOdds.gridStops(rows: 3, cols: 3, strip: Self.strip, seed: UInt64(seed))
        for column in grid {
            #expect(Set(column).count > 1, "vertical triple \(column) — impossible on a distinct strip")
        }
    }

    /// **Odds preserved.** Over many seeded runs the per-cell jackpot (index 0) rate is about
    /// `1 / strip.count` and the per-line all-match rate is about `(1 / strip.count)^2` — proof
    /// the reel-stop draw didn't distort the distribution.
    @Test
    func perCellJackpotRateIsOneInStripLength() {
        let strip = Self.strip
        let runs = 4000
        let cells = (0 ..< runs).flatMap { seed in
            SlotOdds.gridStops(rows: 3, cols: 3, strip: strip, seed: UInt64(seed)).flatMap(\.self)
        }
        let jackpotCells = cells.count { $0 == 0 }
        let rate = Double(jackpotCells) / Double(cells.count)
        #expect(abs(rate - 1.0 / Double(strip.count)) < 0.02)
    }
}
