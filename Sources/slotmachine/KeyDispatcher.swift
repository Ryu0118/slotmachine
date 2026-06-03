import SlotMachineCore

/// Routes a session's keypresses to the game that is currently accepting them, and **drops the
/// rest**. One dispatcher consumes the whole `AsyncStream` for the session (the stream allows a
/// single iterator), so a key is never left buffered to bleed into the next game.
///
/// The fix it exists for: stopping the reels takes one key per column, but the finale flash (and
/// any over-pressing) happens *between* a game's accepting window and the next one's. Without a
/// single gate-keeper those extra keys queue in the stream and the next game consumes them
/// instantly — the next reels stop on their own. Here every byte hits one decision point: if no
/// game is accepting, it's dropped; once a game's last reel is released, the window closes.
actor KeyDispatcher {
    private var gate: ReelGate?
    private var remaining = 0

    /// Opens the accepting window for a game: keys now advance `gate`, up to `reelCount` of them.
    /// Closing the previous game's window (done when its last reel released) means keys pressed
    /// in between — during the finale — were dropped, not queued.
    func beginGame(gate: ReelGate, reelCount: Int) {
        self.gate = reelCount > 0 ? gate : nil
        remaining = reelCount
    }

    /// Handles one keypress: advances the current game's gate if it's still accepting, otherwise
    /// drops the key. Closes the window when the last reel of the game has been released.
    func handle() async {
        guard remaining > 0, let gate else { return }
        await gate.advance()
        remaining -= 1
        if remaining == 0 { self.gate = nil }
    }
}
