/// The deterministic draw at the heart of a spin.
///
/// `plan` decides, **up front and sequentially**, which symbol every reel lands on. The
/// outcome is fixed before any reel animates, so a `seed` reproduces a spin exactly
/// regardless of the concurrent reveal order in the animation layer. This is the pure,
/// dependency-free seam the tests pin against.
public enum SlotOdds {
    /// Draws a landing symbol index for each of `reels`, weighted by `weights`.
    ///
    /// Each reel independently draws a value in `[0, 1)` and maps it through the cumulative
    /// distribution of `weights`, so symbol `i` is chosen with probability `weights[i]`
    /// (the weights should sum to 1). With a `seed` the sequence is reproducible; without
    /// one it uses the system generator.
    ///
    /// - Parameters:
    ///   - reels: how many indices to draw (one per reel).
    ///   - weights: per-symbol probabilities; index 0 is the jackpot symbol.
    ///   - seed: an optional seed for a reproducible draw.
    /// - Returns: `reels` symbol indices into the weight table.
    public static func plan(reels: Int, weights: [Double], seed: UInt64?) -> [Int] {
        if let seed {
            var generator = SeededRNG(seed: seed)
            return draw(reels: reels, weights: weights, using: &generator)
        }
        var generator = SystemRandomNumberGenerator()
        return draw(reels: reels, weights: weights, using: &generator)
    }

    /// Draws a `cols × rows` grid: one weighted index per cell, returned **column by column**
    /// (each inner array is a column's `rows` cells, top to bottom). Like ``plan(reels:weights:seed:)``
    /// the draw is up front and seedable, so `--seed` reproduces the whole grid exactly.
    public static func gridPlan(rows: Int, cols: Int, weights: [Double], seed: UInt64?) -> [[Int]] {
        let flat = plan(reels: rows * cols, weights: weights, seed: seed)
        return (0 ..< cols).map { col in Array(flat[(col * rows) ..< (col * rows + rows)]) }
    }

    private static func draw(
        reels: Int,
        weights: [Double],
        using generator: inout some RandomNumberGenerator,
    ) -> [Int] {
        (0 ..< reels).map { _ in pick(weights: weights, using: &generator) }
    }

    /// Maps one `[0, 1)` draw through the cumulative distribution of `weights`. Falls back
    /// to the last index if rounding leaves the draw just past the final boundary.
    private static func pick(weights: [Double], using generator: inout some RandomNumberGenerator) -> Int {
        let roll = Double.random(in: 0 ..< 1, using: &generator)
        var cumulative = 0.0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if roll < cumulative { return index }
        }
        return weights.indices.last ?? 0
    }
}
