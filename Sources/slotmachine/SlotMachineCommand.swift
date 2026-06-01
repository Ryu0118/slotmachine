import ArgumentParser
import Foundation
import SlotKit
import SlotMachineCore

/// `slotmachine` — spin an ASCII slot machine in your terminal with real slot-machine odds.
@main
struct SlotMachineCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slotmachine",
        abstract: "Spin an ASCII slot machine with real slot-machine odds.",
        version: SlotMachineVersion.current,
    )

    @Option(name: [.customShort("n"), .customLong("reels")], help: "How many reels to spin (2…9).")
    var reels = 3

    @Option(name: .customLong("odds"), help: "Per-reel chance of the 7 (the jackpot face), in (0, 1].")
    var odds = 0.1

    @Option(name: .customLong("seed"), help: "Seed for a reproducible spin.")
    var seed: UInt64?

    @Flag(name: [.customLong("silent"), .customLong("plain")], help: "Disable the animation; print the result only.")
    var silent = false

    mutating func run() async throws {
        let theme = try SevenTheme.make()
        let config = try SlotConfig(reels: reels, odds: odds, symbolCount: theme.symbols.count)
        let landings = SlotOdds.plan(reels: config.reels, weights: config.weights, seed: seed)

        let result = await SlotMachine.spinSymbols(
            reels(for: landings),
            theme: theme,
            plain: plain(config: config, cellWidth: theme.cellWidth),
        )
        Self.report(result)
    }

    /// Whether to skip the animation: `true` when `--silent` is set, or when the terminal is
    /// known to be narrower than the reel grid (where the in-place redraw would desync). A
    /// `nil` lets SlotKit auto-detect the TTY when the width is unknown or roomy enough.
    private func plain(config: SlotConfig, cellWidth: Int) -> Bool? {
        if silent { return true }
        if let columns = TerminalWidth.columns, columns < config.requiredWidth(cellWidth: cellWidth) {
            return true
        }
        return nil
    }

    /// Wraps each pre-drawn landing index in a reel whose draw simply returns it — the
    /// outcome is fixed up front (so `--seed` reproduces), SlotKit only animates the reveal.
    private func reels(for landings: [Int]) -> [SymbolReel] {
        landings.map { index in SymbolReel { index } }
    }

    private static func report(_ result: SymbolSpinResult) {
        let line = result.outcomes.map(\.landedIndex).map(String.init).joined(separator: " ")
        let verdict = if result.isJackpot {
            "🎰 JACKPOT! 🎰"
        } else if result.allSame {
            "🎉 winner!"
        } else {
            "no win. spin again."
        }
        emitLine("\(line)  — \(verdict)")
    }

    private static func emitLine(_ text: String) {
        FileHandle.standardOutput.write(Data("\(text)\n".utf8))
    }
}
