@testable import SlotMachineCore
import Testing

struct SeededRNGTests {
    private static func sequence(seed: UInt64, count: Int) -> [UInt64] {
        var generator = SeededRNG(seed: seed)
        return (0 ..< count).map { _ in generator.next() }
    }

    @Test
    func sameSeedProducesTheSameSequence() {
        #expect(Self.sequence(seed: 42, count: 8) == Self.sequence(seed: 42, count: 8))
    }

    @Test(arguments: [(UInt64(1), UInt64(2)), (0, 100), (7, 8)])
    func differentSeedsProduceDifferentSequences(seedA: UInt64, seedB: UInt64) {
        #expect(Self.sequence(seed: seedA, count: 8) != Self.sequence(seed: seedB, count: 8))
    }

    @Test
    func successiveDrawsAdvanceTheState() {
        // A well-mixed generator should not repeat its first value on the next draw.
        var generator = SeededRNG(seed: 123)
        let first = generator.next()
        let second = generator.next()
        #expect(first != second)
    }

    @Test
    func seedZeroIsDeterministicNotDegenerate() {
        // SplitMix64 must mix even the all-zero seed into a varied stream.
        let values = Self.sequence(seed: 0, count: 4)
        #expect(Set(values).count == values.count) // no immediate repeats
    }
}
