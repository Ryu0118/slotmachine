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
        gridStops(rows: rows, cols: cols, strips: Array(repeating: strip, count: cols), seed: seed)
    }

    /// Draws a `cols × rows` grid where each column stops on **its own** strip — so a reel can
    /// weight a symbol differently from its neighbours (a real machine's per-reel design). Column
    /// `col` stops on `strips[col % strips.count]` at a uniform position and reads the `rows`
    /// consecutive faces under the window. Returned column by column. Seedable for reproducibility.
    public static func gridStops(rows: Int, cols: Int, strips: [[Int]], seed: UInt64?) -> [[Int]] {
        guard !strips.isEmpty else { return Array(repeating: Array(repeating: 0, count: rows), count: cols) }
        var generator: any RandomNumberGenerator = seed.map { SeededRNG(seed: $0) } ?? SystemRandomNumberGenerator()
        return (0 ..< cols).map { col in
            let strip = strips[col % strips.count]
            let stop = strip.isEmpty ? 0 : Int.random(in: 0 ..< strip.count, using: &generator)
            return (0 ..< rows).map { row in strip.isEmpty ? 0 : strip[(stop + row) % strip.count] }
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
