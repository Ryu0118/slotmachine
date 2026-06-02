import Foundation
import SlotKit
import SlotMachineCore

/// Drives a spin: builds the reels behind a ``ReelGate`` and advances the gate either by
/// keypress (interactive) or on a timer (auto), so reels stop one after another. The landed
/// symbols are decided up front, so the gate only controls *when* each reel reveals — the
/// outcome is fixed (and `--seed`-reproducible) regardless of how the stop is driven.
enum SpinDriver {
    /// Reels with no gate — each immediately returns its drawn symbol. For the plain
    /// (non-animated) path, where nothing drives a gate and the result is wanted at once.
    static func immediateReels(drawn: [Int]) -> [SymbolReel] {
        drawn.map { symbol in SymbolReel { symbol } }
    }

    /// Builds one reel per drawn index, each gated on its turn so reels stop in order. A reel
    /// reveals its symbol the instant its turn comes — the stop is immediate, no hold.
    static func reels(drawn: [Int], gate: ReelGate) -> [SymbolReel] {
        drawn.enumerated().map { index, symbol in
            SymbolReel {
                await gate.awaitTurn(index)
                return symbol
            }
        }
    }

    /// Advances the gate once per keypress, releasing reels left to right. Returns when every
    /// reel has been released (so the caller can stop reading keys). Ignores which key — any
    /// press (Enter, Space, …) stops the next reel.
    static func driveByKeys(_ keys: AsyncStream<UInt8>, gate: ReelGate, reelCount: Int) async {
        guard reelCount > 0 else { return }
        var released = 0
        for await _ in keys {
            await gate.advance()
            released += 1
            if released >= reelCount { return }
        }
    }

    /// Advances the gate on a timer: one reel every `stagger` seconds (the "ka-chunk,
    /// ka-chunk" auto stop). Returns once every reel has been released.
    static func driveByTimer(gate: ReelGate, reelCount: Int, stagger: Double) async {
        for index in 0 ..< reelCount {
            await gate.advance()
            if index < reelCount - 1, stagger > 0 {
                try? await Task.sleep(for: .seconds(stagger))
            }
        }
    }
}
