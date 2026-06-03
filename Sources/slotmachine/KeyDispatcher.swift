import SlotMachineCore

/// Routes a session's stop keys to the window that is currently accepting them, and **drops the
/// rest**. One dispatcher consumes the whole `AsyncStream` for the session (the stream allows a
/// single iterator), so a key is never left buffered to bleed into the next game.
///
/// A game registers two windows back to back: the reel window (one key per column) and a
/// one-key *advance* window for moving on after the finale. The advance window is **pre-armed**
/// (`armNext`) before the spin, so the moment the last reel is released the dispatcher hands the
/// very next key to the advance window with **no gap** — a key pressed during the finale flash
/// advances instead of being dropped. When a window's count runs out and nothing is armed
/// behind it, the dispatcher stops accepting, so keys mashed past the last reel of a game don't
/// bleed into the next game's reels (that window isn't armed until the next game sets it up).
///
/// Only **Enter and Space** count. Other keys are ignored — so an arrow or function key, sent
/// as a multi-byte escape sequence (`ESC [ A`), can't act as three presses: none of its bytes
/// is a stop key.
actor KeyDispatcher {
    /// The bytes that count as a press: carriage return / newline (Enter) and space.
    private static let stopBytes: Set<UInt8> = [0x0D, 0x0A, 0x20]

    /// One accepting window: a gate to advance and how many presses it still wants.
    private struct Window {
        var gate: ReelGate
        var remaining: Int
    }

    private var current: Window?
    private var pending: Window?

    /// Opens the reel window for a game: the next `reelCount` presses advance `gate`. Replaces
    /// any current window (a fresh game starts clean) but keeps anything armed behind it only if
    /// this is itself the armed window being promoted — callers always pair this with `armNext`.
    func beginGame(gate: ReelGate, reelCount: Int) {
        current = reelCount > 0 ? Window(gate: gate, remaining: reelCount) : nil
        pending = nil
    }

    /// Arms the one-key advance window that takes over the instant the current window is spent —
    /// with no gap, so a finale-time press advances rather than being dropped.
    func armNext(gate: ReelGate) {
        pending = Window(gate: gate, remaining: 1)
    }

    /// Handles one input byte: if it's a press and a window is accepting, advances that window's
    /// gate; otherwise drops it. When the current window is spent it is replaced by the armed
    /// `pending` window (if any) in the same step, so no press falls into a gap.
    func handle(_ byte: UInt8) async {
        guard Self.stopBytes.contains(byte), current != nil else { return }
        await current?.gate.advance()
        current?.remaining -= 1
        if current?.remaining == 0 {
            current = pending
            pending = nil
        }
    }
}
