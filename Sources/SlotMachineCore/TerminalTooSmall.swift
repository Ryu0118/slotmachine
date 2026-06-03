/// Thrown when the terminal is too small to animate the reels. Carries the required and actual
/// dimensions so the message tells the player exactly how much bigger the window must be.
///
/// Conforms to `CustomStringConvertible` (not `LocalizedError`) so ArgumentParser prints just
/// this message to stderr and exits `1` — no usage string, no game verdict.
public struct TerminalTooSmall: Error, CustomStringConvertible {
    /// Columns the grid needs to draw without wrapping.
    public let neededColumns: Int
    /// Rows the grid needs to draw without scrolling off.
    public let neededRows: Int
    /// The terminal's actual column count, if known (`nil` when it couldn't be read).
    public let haveColumns: Int?
    /// The terminal's actual row count, if known (`nil` when it couldn't be read).
    public let haveRows: Int?

    /// Creates the error from the required and (optionally) actual terminal dimensions.
    public init(neededColumns: Int, neededRows: Int, haveColumns: Int?, haveRows: Int?) {
        self.neededColumns = neededColumns
        self.neededRows = neededRows
        self.haveColumns = haveColumns
        self.haveRows = haveRows
    }

    /// The one-line, stderr-bound message: required size, actual size, and what to do.
    public var description: String {
        let have = if let haveColumns, let haveRows {
            "the window is \(haveColumns)×\(haveRows)"
        } else {
            "the window is smaller than that"
        }
        return "Terminal too small: the reels need at least \(neededColumns)×\(neededRows), but "
            + "\(have). Make the window bigger and run it again."
    }
}
