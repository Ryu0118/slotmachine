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

    @Option(name: [.customShort("n"), .customLong("reels")], help: "Reels in a single-row machine (1…10).")
    var reels = 3

    @Option(name: .customLong("grid"), help: "Play a square N×N machine that pays on rows and diagonals (3…9).")
    var grid: Int?

    @Option(name: .customLong("odds"), help: "Per-cell chance of the 7 (the jackpot face), in (0, 1].")
    var odds = 0.1

    @Option(name: .customLong("seed"), help: "Seed for a reproducible spin.")
    var seed: UInt64?

    @Flag(name: .customLong("auto"), help: "Press once to spin; reels then stop on their own (ka-chunk, ka-chunk).")
    var auto = false

    @Flag(name: [.customLong("silent"), .customLong("plain")], help: "Disable the animation; print the result only.")
    var silent = false

    mutating func run() async throws {
        let theme = try SevenTheme.make()
        let config = try makeConfig(symbolCount: theme.symbols.count)
        let drawn = SlotOdds.gridPlan(rows: config.rows, cols: config.cols, weights: config.weights, seed: seed)
        let paylines = config.rows == 1 ? [Payline.row(0)] : Payline.allLines(forSquare: config.rows)

        // One decision drives everything: a roomy interactive TTY animates, anything else
        // (pipe, CI, NO_COLOR, --silent, too-small window) prints the plain verdict instead.
        guard OutputMode.shouldAnimate(forcePlain: silent || !fits(config, theme: theme)) else {
            let columns = SpinDriver.immediateGridColumns(drawn: drawn)
            let result = await SlotMachine.spinGrid(
                columns,
                rows: config.rows,
                paylines: paylines,
                theme: theme,
                plain: true,
            )
            Self.printVerdict(result)
            return
        }
        await animate(drawn: drawn, rows: config.rows, paylines: paylines, theme: theme)
    }

    private func makeConfig(symbolCount: Int) throws -> GridConfig {
        if let grid {
            return try GridConfig.square(size: grid, odds: odds, symbolCount: symbolCount)
        }
        return try GridConfig.singleRow(reels: reels, odds: odds, symbolCount: symbolCount)
    }

    /// Whether the grid fits the terminal in both width and height; if either is too small the
    /// animated in-place redraw would wrap and tear, so the caller falls back to plain.
    private func fits(_ config: GridConfig, theme: SlotTheme) -> Bool {
        let wideEnough = (TerminalSize.columns ?? .max) >= config.requiredWidth(cellWidth: theme.cellWidth)
        let tallEnough = (TerminalSize.rows ?? .max) >= config.requiredHeight(cellHeight: theme.cellHeight)
        return wideEnough && tallEnough
    }

    /// Spins with the animation and the keypress / auto stop. Prints no verdict — the reels
    /// and the closing flash are the result.
    private func animate(drawn: [[Int]], rows: Int, paylines: [Payline], theme: SlotTheme) async {
        let gate = ReelGate()
        let columns = SpinDriver.gridColumns(drawn: drawn, gate: gate)
        await KeyReader.withKeys { keys in
            async let spin: GridSpinResult = SlotMachine.spinGrid(
                columns,
                rows: rows,
                paylines: paylines,
                theme: theme,
                plain: false,
            )
            await drive(keys: keys, gate: gate, columnCount: drawn.count)
            _ = await spin
        }
    }

    /// Releases the columns: in `--auto`, wait for one keypress then stop them on a timer; by
    /// default, stop one column per keypress.
    private func drive(keys: AsyncStream<UInt8>, gate: ReelGate, columnCount: Int) async {
        if auto {
            var iterator = keys.makeAsyncIterator()
            _ = await iterator.next() // one key to start the auto spin
            await SpinDriver.driveByTimer(gate: gate, reelCount: columnCount, stagger: Self.stagger)
        } else {
            await SpinDriver.driveByKeys(keys, gate: gate, reelCount: columnCount)
        }
    }

    /// Seconds between columns in the auto stop.
    private static let stagger = 0.28

    private static func printVerdict(_ result: GridSpinResult) {
        let verdict = if result.isJackpot {
            "🎰 JACKPOT! 🎰"
        } else if result.didWin {
            "🎉 \(result.winningLines.count) line(s)!"
        } else {
            "no win — spin again."
        }
        FileHandle.standardOutput.write(Data("\(verdict)\n".utf8))
    }
}
