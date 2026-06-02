@testable import SlotMachineCore
import Testing

struct ReelGateTests {
    @Test
    func reelsAreReleasedInOrderAsAdvancesArrive() async {
        let gate = ReelGate()
        let order = OrderRecorder()

        // Start three reels concurrently; each records itself once released.
        let reels = (0 ..< 3).map { index in
            Task { await gate.awaitTurn(index); await order.append(index) }
        }

        // Release them one at a time, waiting for each to land before the next.
        for expected in 1 ... 3 {
            await gate.advance()
            await order.waitForCount(expected)
        }

        for reel in reels {
            await reel.value
        }
        #expect(await order.values == [0, 1, 2])
    }

    @Test
    func turnAlreadyPassedReturnsImmediately() async {
        let gate = ReelGate()
        await gate.advance() // release reel 0 before anyone waits
        await gate.advance() // release reel 1
        // reel 0 and 1's turns have passed — these must not suspend forever.
        await gate.awaitTurn(0)
        await gate.awaitTurn(1)
        #expect(await gate.releasedCount == 2)
    }

    @Test
    func extraAdvancesPastTheLastReelAreHarmless() async {
        let gate = ReelGate()
        await gate.advance()
        await gate.advance() // advancing past the only reel must not crash
        await gate.awaitTurn(0) // reel 0's turn has long passed — returns immediately
        #expect(await gate.releasedCount == 2)
    }

    private actor OrderRecorder {
        private(set) var values: [Int] = []

        func append(_ value: Int) {
            values.append(value)
        }

        func waitForCount(_ count: Int) async {
            while values.count < count {
                await Task.yield()
            }
        }
    }
}
