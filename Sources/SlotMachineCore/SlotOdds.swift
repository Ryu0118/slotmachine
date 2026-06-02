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

    /// Builds a spinning pool (a list of symbol indices to scroll through) where the jackpot
    /// symbol (index 0) appears about `jackpotOdds` of the time and the other symbols share the
    /// rest evenly. Stopping at a random instant then lands on the jackpot with probability
    /// ≈ `jackpotOdds` — the skill-stop's odds live in the pool, not an up-front draw. The pool
    /// is interleaved (not blocked) so the jackpot is spread across the spin, and contains every
    /// symbol at least once.
    public static func weightedPool(symbolCount: Int, jackpotOdds: Double, length: Int) -> [Int] {
        guard symbolCount >= 2, length >= symbolCount else {
            return Array(0 ..< max(symbolCount, 1))
        }
        let others = symbolCount - 1
        let jackpots = max(1, min(length - others, Int((Double(length) * jackpotOdds).rounded())))
        var pool: [Int] = []
        var otherCursor = 0
        for slot in 0 ..< length {
            // A slot is a jackpot when it crosses one of `jackpots` evenly-spaced boundaries;
            // the gaps cycle through the other symbols so every face appears.
            if (slot * jackpots) / length != ((slot + 1) * jackpots) / length {
                pool.append(0)
            } else {
                pool.append(1 + (otherCursor % others))
                otherCursor += 1
            }
        }
        return pool
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
