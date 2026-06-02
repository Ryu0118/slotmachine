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

    @Option(name: .customLong("games"), help: "How many games to play in a row; prints session stats at the end.")
    var games = 1

    @Flag(name: [.customLong("silent"), .customLong("plain")], help: "Disable the animation; print the result only.")
    var silent = false

    mutating func run() async throws {
        guard games >= 1 else { throw ValidationError("games must be at least 1 (got \(games))") }
        let theme = try SevenTheme.make()
        let config = try makeConfig(symbolCount: theme.symbols.count)
        let paylines = config.rows == 1 ? [Payline.row(0)] : Payline.allLines(forSquare: config.rows)
        let animated = OutputMode.shouldAnimate(forcePlain: silent || !fits(config, theme: theme))

        var stats = GameStats.empty
        for game in 0 ..< games {
            let result = await play(game: game, config: config, paylines: paylines, theme: theme, animated: animated)
            stats = stats.recording(GameOutcome(
                didWin: result.didWin,
                isJackpot: result.isJackpot,
                lineCount: result.winningLines.count,
            ))
        }
        if games > 1 {
            emit(StatsScreen.render(stats, color: animated))
        }
    }

    /// Plays one game and returns its result. A single interactive game animates with the
    /// keypress / auto stop; in a multi-game session every game auto-spins (no key per game)
    /// and prints a one-line verdict, so a 10-game run flies by. The non-animated path spins
    /// plainly and prints the verdict.
    private func play(
        game: Int,
        config: GridConfig,
        paylines: [Payline],
        theme: SlotTheme,
        animated: Bool,
    ) async -> GridSpinResult {
        let drawn = SlotOdds.gridPlan(
            rows: config.rows,
            cols: config.cols,
            weights: config.weights,
            seed: gameSeed(game),
        )
        guard animated else {
            let result = await SlotMachine.spinGrid(
                SpinDriver.immediateGridColumns(drawn: drawn),
                rows: config.rows,
                paylines: paylines,
                theme: theme,
                plain: true,
            )
            emit(games > 1 ? Self.verdictLine(game: game, result: result) : Self.verdict(result))
            return result
        }
        let result = await animate(drawn: drawn, rows: config.rows, paylines: paylines, theme: theme)
        if games > 1 {
            emit(Self.verdictLine(game: game, result: result))
            // Redraw the next game over this one: move the cursor back up over the grid and
            // its verdict line so the session plays in place instead of scrolling away.
            if game < games - 1 {
                let gridLines = config.requiredHeight(cellHeight: theme.cellHeight) - 1
                emit("\u{1B}[\(gridLines + 1)A")
            }
        }
        return result
    }

    /// The seed for game `game`: derived from `--seed` so a session is reproducible yet every
    /// game differs; `nil` when no seed was given (each game uses the system generator).
    private func gameSeed(_ game: Int) -> UInt64? {
        seed.map { $0 &+ UInt64(game) }
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

    /// Spins one game with the animation, stopping by keypress or `--auto`. Returns the
    /// game's result; the reels and closing flash are its on-screen outcome.
    private func animate(
        drawn: [[Int]],
        rows: Int,
        paylines: [Payline],
        theme: SlotTheme,
    ) async -> GridSpinResult {
        let gate = ReelGate()
        let columns = SpinDriver.gridColumns(drawn: drawn, gate: gate)
        return await KeyReader.withKeys { keys in
            async let spin: GridSpinResult = SlotMachine.spinGrid(
                columns,
                rows: rows,
                paylines: paylines,
                theme: theme,
                plain: false,
            )
            await drive(keys: keys, gate: gate, columnCount: drawn.count)
            return await spin
        }
    }

    /// Releases the columns. The stop style is chosen by `--auto` alone (independent of how
    /// many games): with `--auto` the columns stop on a timer; otherwise one column per
    /// keypress. So `--games 10` is ten hand-stopped games; add `--auto` to let them run.
    private func drive(keys: AsyncStream<UInt8>, gate: ReelGate, columnCount: Int) async {
        if auto {
            await SpinDriver.driveByTimer(gate: gate, reelCount: columnCount, stagger: Self.stagger)
        } else {
            await SpinDriver.driveByKeys(keys, gate: gate, reelCount: columnCount)
        }
    }

    /// Seconds between columns in the auto stop.
    private static let stagger = 0.28

    /// A single game's one-line verdict.
    private static func verdict(_ result: GridSpinResult) -> String {
        let text = if result.isJackpot {
            "🎰 JACKPOT! 🎰"
        } else if result.didWin {
            "🎉 \(result.winningLines.count) line(s)!"
        } else {
            "no win — spin again."
        }
        return text + "\n"
    }

    /// A numbered verdict line for a game in a multi-game session.
    private static func verdictLine(game: Int, result: GridSpinResult) -> String {
        "Game \(game + 1): " + verdict(result)
    }

    private func emit(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }
}
