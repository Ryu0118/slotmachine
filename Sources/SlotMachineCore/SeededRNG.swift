/// A small, deterministic `RandomNumberGenerator` for reproducible spins.
///
/// Implements SplitMix64 — a fast, well-distributed 64-bit generator with a single
/// `UInt64` of state. Seeding it with the same value always yields the same sequence, so a
/// `--seed` flag can reproduce a spin exactly (handy for tests and for sharing a result).
/// Foundation-free, so it compiles unchanged on every platform.
public struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    /// Creates a generator seeded with `seed`. The same seed always produces the same sequence.
    public init(seed: UInt64) {
        state = seed
    }

    /// Returns the next 64-bit value and advances the state (SplitMix64).
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
