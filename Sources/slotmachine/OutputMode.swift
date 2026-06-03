import Foundation
#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

/// The single source of truth for whether this run animates.
///
/// Both the animation and the interactive keypress stop need a real terminal, and the
/// plain-text verdict must appear exactly when the animation does not. Deciding that once,
/// here, keeps those three in lockstep — otherwise a run could animate but skip the verdict,
/// or (worse) do neither and print nothing.
enum OutputMode {
    /// `true` when stdout is an interactive TTY with color allowed (`NO_COLOR` unset,
    /// `TERM` not `dumb`). Drives animation, the keypress stop, and verdict suppression.
    static func shouldAnimate(forcePlain: Bool) -> Bool {
        if forcePlain { return false }
        let environment = ProcessInfo.processInfo.environment
        if environment["NO_COLOR"] != nil { return false }
        if environment["TERM"] == "dumb" { return false }
        return isInteractive
    }

    /// `true` when both stdout and stdin are real terminals — i.e. there's a keyboard to
    /// hand-stop with and a window to draw in. A piped/redirected run is not interactive and
    /// must never be treated as a too-small terminal (it has no size to outgrow).
    static var isInteractive: Bool {
        isatty(STDOUT_FILENO) != 0 && isatty(STDIN_FILENO) != 0
    }
}
