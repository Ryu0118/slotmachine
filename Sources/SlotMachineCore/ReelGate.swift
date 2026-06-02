/// Coordinates the order in which reels are allowed to stop.
///
/// SlotKit spins every reel's closure concurrently, so without coordination the reels would
/// race to stop in an unpredictable order. `ReelGate` serializes them: reel `i` calls
/// ``awaitTurn(_:)`` and suspends until exactly `i` reels have been released, and each
/// ``advance()`` (one per keypress, or one per timer tick in auto mode) releases the next
/// reel left to right. This is the pure, testable core of the interactive stop — given a
/// reel count and a number of advances, the release order is deterministic.
public actor ReelGate {
    private var released = 0
    private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]

    /// Creates a gate with no reels released yet.
    public init() {}

    /// Suspends until `index` reels have been released — i.e. until it is reel `index`'s turn
    /// to stop. Returns immediately if its turn has already come.
    public func awaitTurn(_ index: Int) async {
        if index < released { return }
        await withCheckedContinuation { continuation in
            waiters[index] = continuation
        }
    }

    /// Releases the next reel in order (left to right). One call per keypress / timer tick.
    /// Extra advances past the last reel are harmless no-ops.
    public func advance() {
        let next = released
        released += 1
        if let continuation = waiters.removeValue(forKey: next) {
            continuation.resume()
        }
    }

    /// How many reels have been released so far.
    public var releasedCount: Int {
        released
    }
}
