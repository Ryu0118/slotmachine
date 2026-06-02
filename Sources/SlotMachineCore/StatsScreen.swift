import Foundation

/// Renders the closing session stats — the dopamine screen after a `--games N` run.
///
/// On a color terminal it draws a bright double-ruled panel with a win-rate bar and a
/// jackpot callout; on a plain pipe it prints the same numbers without escapes, so the
/// output stays readable and byte-stable.
public enum StatsScreen {
    /// The full stats panel for `stats`, colored when `color` is set.
    public static func render(_ stats: GameStats, color: Bool) -> String {
        let lines = color ? colored(stats) : plain(stats)
        return lines.joined(separator: "\n") + "\n"
    }

    /// The on-screen column width of `text` (ANSI-stripped, wide glyphs as two) — exposed so
    /// tests can assert the colored panel's rows line up with its border.
    public static func width(of text: String) -> Int {
        displayWidth(text)
    }

    /// The colored panel as individual lines — exposed for alignment tests.
    public static func coloredLines(_ stats: GameStats) -> [String] {
        colored(stats)
    }

    private static func plain(_ stats: GameStats) -> [String] {
        [
            "── SESSION STATS ──",
            "games:    \(stats.games)",
            "wins:     \(stats.wins)  (\(percent(stats.winRate)))",
            "jackpots: \(stats.jackpots)  (\(percent(stats.jackpotRate)))",
            "best streak: \(stats.bestStreak)",
            "total lines: \(stats.totalLines)",
        ]
    }

    private static func colored(_ stats: GameStats) -> [String] {
        let width = 34
        var out: [String] = []
        out.append(bold(cyan("╔" + String(repeating: "═", count: width) + "╗")))
        out.append(bold(cyan("║")) + rainbow(center("🎰  S E S S I O N   S T A T S  🎰", width)) + bold(cyan("║")))
        out.append(bold(cyan("╠" + String(repeating: "═", count: width) + "╣")))
        out.append(row("Games", "\(stats.games)", width))
        out.append(row("Wins", "\(stats.wins)  " + dim("(\(percent(stats.winRate)))"), width))
        out.append(barRow("Win rate", stats.winRate, width, color: green))
        out.append(jackpotRow(stats, width))
        out.append(barRow("Jackpot rate", stats.jackpotRate, width, color: gold))
        out.append(row("Best streak", flames(stats.bestStreak), width))
        out.append(row("Total lines", "\(stats.totalLines)", width))
        out.append(bold(cyan("╚" + String(repeating: "═", count: width) + "╝")))
        return out
    }

    private static func jackpotRow(_ stats: GameStats, _ width: Int) -> String {
        let value = stats.jackpots > 0
            ? blink(gold("\(stats.jackpots)  ★ JACKPOT ★"))
            : dim("0")
        return row("Jackpots", value, width)
    }

    // MARK: - Layout

    private static func row(_ label: String, _ value: String, _ width: Int) -> String {
        let body = " " + bold(label) + ": " + value
        return bold(cyan("║")) + pad(body, to: width) + bold(cyan("║"))
    }

    private static func barRow(_ label: String, _ fraction: Double, _ width: Int, color: (String) -> String) -> String {
        let barWidth = 14
        let filled = Int((fraction * Double(barWidth)).rounded())
        let bar = color(String(repeating: "█", count: filled)) + dim(String(repeating: "░", count: barWidth - filled))
        let body = " " + bold(label) + " " + bar + " " + color(percent(fraction))
        return bold(cyan("║")) + pad(body, to: width) + bold(cyan("║"))
    }

    /// Pads `text` to `width` *display* columns, ignoring ANSI escapes and counting wide
    /// glyphs (emoji, CJK) as two columns — so a row with a 🎰 still lines up with the border.
    private static func pad(_ text: String, to width: Int) -> String {
        text + String(repeating: " ", count: max(0, width - displayWidth(text)))
    }

    private static func center(_ text: String, _ width: Int) -> String {
        let pad = max(0, width - displayWidth(text))
        let left = pad / 2
        return String(repeating: " ", count: left) + text + String(repeating: " ", count: pad - left)
    }

    /// The on-screen column width of `text`: ANSI escapes count for nothing, wide glyphs
    /// (emoji and East-Asian wide/fullwidth) for two columns, everything else for one.
    private static func displayWidth(_ text: String) -> Int {
        let stripped = text.replacing(/\u{1B}\[[0-9;]*m/, with: "")
        return stripped.unicodeScalars.reduce(0) { total, scalar in
            total + (isWide(scalar) ? 2 : 1)
        }
    }

    private static func isWide(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x1100 ... 0x115F, 0x2E80 ... 0xA4CF, 0xAC00 ... 0xD7A3, 0xF900 ... 0xFAFF,
             0xFE30 ... 0xFE4F, 0xFF00 ... 0xFF60, 0xFFE0 ... 0xFFE6,
             0x1F300 ... 0x1FAFF, 0x2600 ... 0x27BF, 0x1F000 ... 0x1F02F:
            true
        default:
            false
        }
    }

    private static func flames(_ count: Int) -> String {
        count == 0 ? dim("0") : "\(count) " + String(repeating: "🔥", count: min(count, 5))
    }

    private static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    // MARK: - ANSI

    private static func bold(_ text: String) -> String {
        "\u{1B}[1m\(text)\u{1B}[22m"
    }

    private static func dim(_ text: String) -> String {
        "\u{1B}[2m\(text)\u{1B}[22m"
    }

    private static func blink(_ text: String) -> String {
        "\u{1B}[5m\(text)\u{1B}[25m"
    }

    private static func cyan(_ text: String) -> String {
        "\u{1B}[36m\(text)\u{1B}[39m"
    }

    private static func green(_ text: String) -> String {
        "\u{1B}[38;2;0;255;120m\(text)\u{1B}[39m"
    }

    private static func gold(_ text: String) -> String {
        "\u{1B}[38;2;255;215;0m\(text)\u{1B}[39m"
    }

    /// Colors each character along a scrolling hue wheel — the arcade title look.
    private static func rainbow(_ text: String) -> String {
        var out = ""
        for (offset, character) in text.enumerated() {
            if character == " " { out.append(character); continue }
            let hue = Double((offset * 12) % 360)
            let (red, grn, blu) = hueToRGB(hue)
            out += "\u{1B}[1;38;2;\(red);\(grn);\(blu)m\(character)"
        }
        return out + "\u{1B}[0m"
    }

    private static func hueToRGB(_ hue: Double) -> (Int, Int, Int) {
        let sector = hue / 60
        let secondary = 1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1)
        let (red, grn, blu): (Double, Double, Double) = switch Int(sector) % 6 {
        case 0: (1, secondary, 0)
        case 1: (secondary, 1, 0)
        case 2: (0, 1, secondary)
        case 3: (0, secondary, 1)
        case 4: (secondary, 0, 1)
        default: (1, 0, secondary)
        }
        return (Int(red * 255), Int(grn * 255), Int(blu * 255))
    }
}
