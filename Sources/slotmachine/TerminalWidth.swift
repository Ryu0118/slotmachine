import Foundation
#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

/// Reads the terminal's column count so the CLI can fall back to plain output when the
/// reel grid would be wider than the window (where the animated in-place redraw desyncs).
enum TerminalWidth {
    /// The terminal width in columns, or `nil` when stdout isn't a terminal whose size can
    /// be read. Prefers the `ioctl` window size and falls back to the `COLUMNS` environment.
    static var columns: Int? {
        var size = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) == 0, size.ws_col > 0 {
            return Int(size.ws_col)
        }
        if let columns = ProcessInfo.processInfo.environment["COLUMNS"], let value = Int(columns), value > 0 {
            return value
        }
        return nil
    }
}
