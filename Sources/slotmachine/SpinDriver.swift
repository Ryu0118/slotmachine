import Foundation
import SlotKit
import SlotMachineCore

/// Drives a spin: builds the reels behind a ``ReelGate`` and advances the gate either by
/// keypress (interactive) or on a timer (auto), so reels stop one after another. The landed
/// symbols are decided up front, so the gate only controls *when* each reel reveals — the
/// outcome is fixed (and `--seed`-reproducible) regardless of how the stop is driven.
enum SpinDriver {
    /// Columns with no gate — each immediately returns its drawn cells. For the plain
    /// (non-animated) grid path.
    static func immediateGridColumns(drawn: [[Int]]) -> [GridReel] {
        drawn.map { column in GridReel { column } }
    }

    /// Builds one grid column per drawn column, each gated on its turn so columns stop left
    /// to right. A column reveals all its cells the instant its turn comes.
    static func gridColumns(drawn: [[Int]], gate: ReelGate) -> [GridReel] {
        drawn.enumerated().map { index, column in
            GridReel {
                await gate.awaitTurn(index)
                return column
            }
        }
    }

    /// Builds `count` skill-stop columns, each gated on its turn. A column carries no
    /// predetermined symbol — its turn (a keypress) is the stop signal, and SlotKit lands it
    /// on the face showing at that instant. The skill-stop, gated left to right.
    static func skillColumns(count: Int, gate: ReelGate) -> [SkillReel] {
        (0 ..< count).map { index in
            SkillReel { await gate.awaitTurn(index) }
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
