import Foundation
#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

/// Reads the terminal's size so the CLI can fall back to plain output when the grid would be
/// wider or taller than the window (where the animated in-place redraw desyncs).
enum TerminalSize {
    /// The terminal width in columns, or `nil` when the size can't be read. Prefers the
    /// `ioctl` window size and falls back to the `COLUMNS` environment.
    static var columns: Int? {
        windowSize?.ws_col.intIfPositive ?? envInt("COLUMNS")
    }

    /// The terminal height in rows, or `nil` when the size can't be read. Prefers the `ioctl`
    /// window size and falls back to the `LINES` environment.
    static var rows: Int? {
        windowSize?.ws_row.intIfPositive ?? envInt("LINES")
    }

    private static var windowSize: winsize? {
        var size = winsize()
        guard ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) == 0 else { return nil }
        return size
    }

    private static func envInt(_ name: String) -> Int? {
        guard let value = ProcessInfo.processInfo.environment[name], let parsed = Int(value), parsed > 0 else {
            return nil
        }
        return parsed
    }
}

private extension UInt16 {
    var intIfPositive: Int? {
        self > 0 ? Int(self) : nil
    }
}
