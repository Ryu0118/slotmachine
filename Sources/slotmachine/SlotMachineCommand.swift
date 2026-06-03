import ArgumentParser
import Foundation
import SlotKit
import SlotMachineCore

/// `slotmachine` — spin an ASCII slot machine in your terminal: scrolling reels, hand stops.
@main
struct SlotMachineCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slotmachine",
        abstract: "Spin an ASCII slot machine with scrolling reels you stop by hand.",
        version: SlotMachineVersion.current,
    )

    @Option(
        name: [.customShort("n"), .customLong("reels")],
        help: "Play a single row of this many reels (1…10) instead of the 3×3 board.",
    )
    var reels: Int?

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
        // Every face is equally likely; hand and auto stops share the one reel strip, so a
        // hand stop lands on whatever's showing and auto stops the same strip at a random
        // position. The config's symbol count is the same eight faces either way.
        let skillStop = !auto
        let theme = try SevenTheme.make()
        let config = try makeConfig(symbolCount: theme.symbols.count)
        let paylines = config.rows == 1 ? [Payline.row(0)] : Payline.allLines(forSquare: config.rows)
        let animated = OutputMode.shouldAnimate(forcePlain: silent || !fits(config, theme: theme))

        let strip = SevenTheme.stripIndices(for: theme)
        let context = SpinContext(
            config: config,
            paylines: paylines,
            theme: theme,
            skillStop: skillStop,
            strip: strip,
        )
        let stats = animated
            ? await playAnimatedSession(context)
            : await playPlainSession(context)
        if games > 1 {
            emit(StatsScreen.render(stats, color: animated))
        }
    }

    /// Everything a game needs, resolved once for the whole session.
    private struct SpinContext {
        let config: GridConfig
        let paylines: [Payline]
        let theme: SlotTheme
        let skillStop: Bool
        /// The reel strip as ``SlotTheme/symbols`` indices — what `--auto` stops on at a random
        /// position. The same faces the reels scroll, so the auto landing is a real reel stop.
        let strip: [Int]
    }

    /// Plays the whole session animated. Opens the key reader ONCE (raw mode entered once) and
    /// threads the key stream through every game — so the first reel never needs an extra
    /// press, and a 10-game run shares one keyboard.
    private func playAnimatedSession(_ context: SpinContext) async -> GameStats {
        await KeyReader.withKeys { keys in
            var stats = GameStats.empty
            for game in 0 ..< games {
                let result = await animateGame(game: game, context: context, keys: keys)
                stats = stats.recording(outcome(result))
            }
            return stats
        }
    }

    private func playPlainSession(_ context: SpinContext) async -> GameStats {
        var stats = GameStats.empty
        for game in 0 ..< games {
            let drawn = drawnGrid(game: game, context: context)
            let result = await SlotMachine.spinGrid(
                SpinDriver.immediateGridColumns(drawn: drawn),
                rows: context.config.rows,
                paylines: context.paylines,
                theme: context.theme,
                plain: true,
            )
            // A multi-game session shows only the closing stats; a single game prints its verdict.
            if games == 1 { emit(Self.verdict(result)) }
            stats = stats.recording(outcome(result))
        }
        return stats
    }

    private func outcome(_ result: GridSpinResult) -> GameOutcome {
        GameOutcome(didWin: result.didWin, isJackpot: result.isJackpot, lineCount: result.winningLines.count)
    }

    /// The auto-stop landing: stop each column at a random position on the same reel strip the
    /// reels scroll, so the board is always a real reel position (no impossible vertical
    /// triples) and `--auto` shares one model with the hand stop.
    private func drawnGrid(game: Int, context: SpinContext) -> [[Int]] {
        SlotOdds.gridStops(
            rows: context.config.rows,
            cols: context.config.cols,
            strip: context.strip,
            seed: gameSeed(game),
        )
    }

    /// Animates one game. Hand-stopped games skill-stop (land on the showing face) via
    /// `spinGridSkill`; `--auto` draws up front and reveals on a timer via `spinGrid`. In a
    /// multi-game session it prints a verdict line and redraws the next game over this one.
    private func animateGame(game: Int, context: SpinContext, keys: AsyncStream<UInt8>) async -> GridSpinResult {
        let config = context.config
        let gate = ReelGate()
        let result: GridSpinResult = if context.skillStop {
            await spinSkill(context: context, gate: gate, keys: keys)
        } else {
            await spinAuto(game: game, context: context, gate: gate)
        }
        // A multi-game session prints no per-game line — only the closing stats. Redraw the
        // next game over this one so the session plays in place instead of scrolling away.
        if games > 1, game < games - 1 {
            let gridLines = config.requiredHeight(cellHeight: context.theme.cellHeight) - 1
            emit("\u{1B}[\(gridLines)A")
        }
        return result
    }

    private func spinSkill(context: SpinContext, gate: ReelGate, keys: AsyncStream<UInt8>) async -> GridSpinResult {
        let columns = SpinDriver.skillColumns(count: context.config.cols, gate: gate)
        async let spin: GridSpinResult = SlotMachine.spinGridSkill(
            columns,
            rows: context.config.rows,
            paylines: context.paylines,
            theme: context.theme,
            plain: false,
        )
        await drive(keys: keys, gate: gate, columnCount: context.config.cols)
        return await spin
    }

    private func spinAuto(game: Int, context: SpinContext, gate: ReelGate) async -> GridSpinResult {
        let drawn = drawnGrid(game: game, context: context)
        let columns = SpinDriver.gridColumns(drawn: drawn, gate: gate)
        async let spin: GridSpinResult = SlotMachine.spinGrid(
            columns,
            rows: context.config.rows,
            paylines: context.paylines,
            theme: context.theme,
            plain: false,
        )
        await SpinDriver.driveByTimer(gate: gate, reelCount: context.config.cols, stagger: Self.stagger)
        return await spin
    }

    /// The seed for game `game`: derived from `--seed` so a session is reproducible yet every
    /// game differs; `nil` when no seed was given (each game uses the system generator).
    private func gameSeed(_ game: Int) -> UInt64? {
        seed.map { $0 &+ UInt64(game) }
    }

    /// The 3×3 board is the default; `--reels N` switches to a single row of N reels.
    private func makeConfig(symbolCount: Int) throws -> GridConfig {
        if let reels {
            return try GridConfig.singleRow(reels: reels, symbolCount: symbolCount)
        }
        return try GridConfig.square(symbolCount: symbolCount)
    }

    /// Whether the grid fits the terminal in both width and height; if either is too small the
    /// animated in-place redraw would wrap and tear, so the caller falls back to plain.
    private func fits(_ config: GridConfig, theme: SlotTheme) -> Bool {
        let wideEnough = (TerminalSize.columns ?? .max) >= config.requiredWidth(cellWidth: theme.cellWidth)
        let tallEnough = (TerminalSize.rows ?? .max) >= config.requiredHeight(cellHeight: theme.cellHeight)
        return wideEnough && tallEnough
    }

    /// Releases each column on a keypress, left to right — the hand stop. Used only on the
    /// skill-stop (hand) path; `--auto` drives by timer in `spinAuto`.
    private func drive(keys: AsyncStream<UInt8>, gate: ReelGate, columnCount: Int) async {
        await SpinDriver.driveByKeys(keys, gate: gate, reelCount: columnCount)
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

    private func emit(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }
}
