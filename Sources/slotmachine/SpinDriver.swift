import Foundation
import SlotKit
import SlotMachineCore

/// Drives a spin: builds the reels behind a ``ReelGate`` and advances the gate by keypress, so
/// columns stop one after another, left to right. The hand path lands each column on the face
/// showing at the keypress; the non-animated (piped / non-TTY) path settles its cells up front.
enum SpinDriver {
    /// Columns with no gate — each immediately returns its drawn cells. For the plain
    /// (non-animated) grid path.
    static func immediateGridColumns(drawn: [[Int]]) -> [GridReel] {
        drawn.map { column in GridReel { column } }
    }

    /// Builds `count` skill-stop columns, each gated on its turn. A column carries no
    /// predetermined symbol — its turn (a keypress) is the stop signal, and SlotKit lands it
    /// on the face showing at that instant. The skill-stop, gated left to right.
    static func skillColumns(count: Int, gate: ReelGate) -> [SkillReel] {
        (0 ..< count).map { index in
            SkillReel { await gate.awaitTurn(index) }
        }
    }
}
