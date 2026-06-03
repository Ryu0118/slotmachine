/// The deterministic reel-stop draw at the heart of a spin.
///
/// A reel is a strip of faces. Stopping it lands on whatever face is showing — and because the
/// cells of a column are *consecutive* positions on that strip, a column lands on `rows` adjacent
/// strip faces. The draw picks one stop position per column, up front and seedably, so `--seed`
/// reproduces a spin exactly and the landed board is always something the spinning reel could
/// actually show (no impossible vertical triples on a strip of distinct faces).
public enum SlotOdds {
    /// Draws a stop position for each of `reels` columns: a uniform index into a strip of
    /// `stripLength` faces. With a `seed` the sequence is reproducible; without one it uses the
    /// system generator.
    ///
    /// - Parameters:
    ///   - reels: how many stop positions to draw (one per column).
    ///   - stripLength: the number of positions on the reel strip.
    ///   - seed: an optional seed for a reproducible draw.
    /// - Returns: `reels` stop positions in `0 ..< stripLength`.
    public static func stops(reels: Int, stripLength: Int, seed: UInt64?) -> [Int] {
        guard stripLength > 0 else { return Array(repeating: 0, count: reels) }
        if let seed {
            var generator = SeededRNG(seed: seed)
            return draw(reels: reels, stripLength: stripLength, using: &generator)
        }
        var generator = SystemRandomNumberGenerator()
        return draw(reels: reels, stripLength: stripLength, using: &generator)
    }

    /// Draws a `cols × rows` grid of landed face indices by stopping each column on the shared
    /// `strip` (a list of face indices) at a uniform position, then reading the `rows`
    /// consecutive strip faces under the window (wrapping at the end). Returned **column by
    /// column** (each inner array is a column's `rows` cells, top to bottom). The draw is up
    /// front and seedable, so `--seed` reproduces the whole grid exactly — and every column is a
    /// real reel position, so the board is always something the reel could show.
    public static func gridStops(rows: Int, cols: Int, strip: [Int], seed: UInt64?) -> [[Int]] {
        let length = strip.count
        let positions = stops(reels: cols, stripLength: length, seed: seed)
        return positions.map { stop in
            (0 ..< rows).map { row in strip[(stop + row) % length] }
        }
    }

    private static func draw(
        reels: Int,
        stripLength: Int,
        using generator: inout some RandomNumberGenerator,
    ) -> [Int] {
        (0 ..< reels).map { _ in Int.random(in: 0 ..< stripLength, using: &generator) }
    }
}
