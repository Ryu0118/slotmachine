@testable import SlotMachineCore
import Testing

struct SlotOddsTests {
    /// Uniform-ish weights for a 4-symbol machine with the jackpot at index 0.
    private static let weights = [0.1, 0.3, 0.3, 0.3]

    @Test(arguments: [UInt64(42), 1, 999])
    func sameSeedReproducesTheSameDraw(seed: UInt64) {
        let first = SlotOdds.plan(reels: 7, weights: Self.weights, seed: seed)
        let second = SlotOdds.plan(reels: 7, weights: Self.weights, seed: seed)
        #expect(first == second)
    }

    @Test
    func drawHasOneIndexPerReel() {
        #expect(SlotOdds.plan(reels: 5, weights: Self.weights, seed: 7).count == 5)
        #expect(SlotOdds.plan(reels: 2, weights: Self.weights, seed: 7).count == 2)
        #expect(SlotOdds.plan(reels: 9, weights: Self.weights, seed: 7).count == 9)
    }

    @Test
    func everyIndexIsWithinTheSymbolRange() {
        let landings = SlotOdds.plan(reels: 9, weights: Self.weights, seed: 12345)
        #expect(landings.allSatisfy { (0 ..< Self.weights.count).contains($0) })
    }

    @Test
    func certainJackpotWeightAlwaysLandsOnIndexZero() {
        // weights = [1, 0, 0, 0] → every reel must draw index 0 (the jackpot).
        let landings = SlotOdds.plan(reels: 9, weights: [1, 0, 0, 0], seed: 999)
        #expect(landings.allSatisfy { $0 == 0 })
    }

    @Test
    func zeroJackpotWeightNeverLandsOnIndexZero() {
        // weights = [0, ...] → index 0 has no mass, so it must never be drawn.
        let landings = SlotOdds.plan(reels: 9, weights: [0, 0.5, 0.5], seed: 555)
        #expect(landings.allSatisfy { $0 != 0 })
    }

    @Test
    func differentSeedsGenerallyDiffer() {
        // Not a guarantee for any single pair, but over many reels two seeds should diverge.
        let first = SlotOdds.plan(reels: 9, weights: Self.weights, seed: 1)
        let second = SlotOdds.plan(reels: 9, weights: Self.weights, seed: 2)
        #expect(first != second)
    }

    @Test
    func seededDrawIsStableAcrossRuns() {
        // Golden vector: pins the exact SplitMix64 + cumulative-distribution output so an
        // accidental change to the draw math is caught. Recorded from a known run.
        let landings = SlotOdds.plan(reels: 7, weights: Self.weights, seed: 42)
        #expect(landings == Self.goldenSeed42)
    }

    /// Hard-coded golden vector; see seededDrawIsStableAcrossRuns. Replace only if the draw
    /// math intentionally changes.
    private static let goldenSeed42 = [3, 2, 2, 3, 3, 1, 1]
}
