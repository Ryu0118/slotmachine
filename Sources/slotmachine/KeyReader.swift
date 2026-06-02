import Foundation
import Synchronization
#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

/// Reads single keypresses from the terminal in raw mode for the interactive stop.
///
/// Raw mode is entered for the duration of ``withKeys(_:)`` and **always restored** on the
/// way out — normal return, thrown error, or cancellation — so the user's shell is never
/// left in a broken state. Keys are delivered through an `AsyncStream` fed by a dedicated
/// reader thread, so a blocking `read(2)` never starves the cooperative pool the animation
/// runs on.
enum KeyReader {
    /// Runs `body` with terminal raw mode active and an `AsyncStream` of keypresses. Each
    /// element is one byte the user typed (Enter, Space, or any key). Raw mode is restored
    /// before this returns, whatever happens inside `body`.
    static func withKeys<Result>(_ body: (AsyncStream<UInt8>) async throws -> Result) async rethrows -> Result {
        let original = enableRawMode()
        defer { if let original { restore(original) } }

        let stop = StopFlag()
        let stream = AsyncStream<UInt8> { continuation in
            let thread = Thread { pump(into: continuation, stop: stop) }
            thread.stackSize = 1 << 16
            thread.start()
            continuation.onTermination = { _ in stop.set() }
        }
        return try await body(stream)
    }

    /// The reader thread's loop: block on `read(2)` one byte at a time and forward each to
    /// the stream until the stream is torn down (`stop`) or stdin closes. Extracted so the
    /// thread body stays shallow.
    private static func pump(into continuation: AsyncStream<UInt8>.Continuation, stop: StopFlag) {
        var byte: UInt8 = 0
        while !stop.isSet {
            guard read(STDIN_FILENO, &byte, 1) == 1 else { break }
            continuation.yield(byte)
        }
        continuation.finish()
    }

    /// A reference-typed stop flag the reader thread polls and the stream's termination sets.
    /// A `final class` (not a bare `Mutex`, which is noncopyable) so it can be shared by both
    /// the thread closure and the termination handler; the `Mutex` makes it thread-safe.
    private final class StopFlag: Sendable {
        private let flag = Mutex(false)
        var isSet: Bool {
            flag.withLock { $0 }
        }

        func set() {
            flag.withLock { $0 = true }
        }
    }

    private static func enableRawMode() -> termios? {
        guard isatty(STDIN_FILENO) != 0 else { return nil }
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else { return nil }
        var raw = original
        raw.c_lflag &= ~(UInt(ECHO) | UInt(ICANON))
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)
        return original
    }

    private static func restore(_ original: termios) {
        var original = original
        tcsetattr(STDIN_FILENO, TCSANOW, &original)
    }
}
