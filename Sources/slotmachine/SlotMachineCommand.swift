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

    @Option(name: .customLong("games"), help: "How many games to play in a row; prints session stats at the end.")
    var games = 1

    @Flag(
        name: .customLong("auto-next"),
        help: "In a multi-game run, roll straight into the next game instead of waiting for a key.",
    )
    var autoNext = false

    mutating func run() async throws {
        guard games >= 1 else { throw ValidationError("games must be at least 1 (got \(games))") }
        // Each reel weights the 7 differently (generous first reel, scarce last), so the board
        // is what a real machine shows. You stop the reels by hand and they land on whatever's
        // showing on that reel; a non-TTY / piped run (no keyboard) stops each reel's strip at a
        // random position. The column count decides how many per-lane strips the theme carries.
        let config = try makeConfig(symbolCount: SevenTheme.symbolCount)
        let theme = try SevenTheme.make(laneCount: config.cols)
        let paylines = config.rows == 1 ? [Payline.row(0)] : Payline.allLines(forSquare: config.rows)
        // On a real terminal the reels need room to scroll; rather than silently degrade to a
        // one-line verdict, tell the player to enlarge the window and exit. A piped / non-TTY
        // run has no size to outgrow, so it keeps the plain draw.
        if OutputMode.isInteractive, !fits(config, theme: theme) {
            throw TerminalTooSmall(
                neededColumns: config.requiredWidth(cellWidth: theme.cellWidth),
                neededRows: config.requiredHeight(cellHeight: theme.cellHeight),
                haveColumns: TerminalSize.columns,
                haveRows: TerminalSize.rows,
            )
        }
        let animated = OutputMode.shouldAnimate(forcePlain: !fits(config, theme: theme))

        let strips = SevenTheme.laneStripIndices(laneCount: config.cols)
        let context = SpinContext(config: config, paylines: paylines, theme: theme, strips: strips)
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
        /// The per-lane reel strips as ``SlotTheme/symbols`` indices — what a non-TTY / piped run
        /// (no keyboard) stops each column on at a random position. The same strips the reels
        /// scroll, so that landing is a real reel stop too, with the 7 weighted per reel.
        let strips: [[Int]]
    }

    /// Plays the whole session animated. Opens the key reader ONCE (raw mode entered once) and
    /// runs a single consumer over the key stream for the whole session: a ``KeyDispatcher``
    /// routes each press to the game that's currently accepting and drops the rest, so keys
    /// mashed during the finale flash don't bleed into the next game.
    private func playAnimatedSession(_ context: SpinContext) async -> GameStats {
        await KeyReader.withKeys { keys in
            let dispatcher = KeyDispatcher()
            return await withTaskGroup(of: GameStats.self) { group in
                group.addTask { await consumeKeys(keys, into: dispatcher) }
                let stats = await playGames(context, dispatcher: dispatcher)
                group.cancelAll() // stop the consumer; raw mode is restored by withKeys
                return stats
            }
        }
    }

    /// The single consumer of the session's key stream: every press goes through `dispatcher`,
    /// which routes it to the accepting game or drops it. Returns `.empty` so the task group is
    /// homogeneous; the real stats come from `playGames`.
    private func consumeKeys(_ keys: AsyncStream<UInt8>, into dispatcher: KeyDispatcher) async -> GameStats {
        for await byte in keys {
            await dispatcher.handle(byte)
        }
        return .empty
    }

    /// Plays every game in the session, recording stats. Each game opens its own accepting window
    /// on the dispatcher, so finale-time keys between games are dropped.
    private func playGames(_ context: SpinContext, dispatcher: KeyDispatcher) async -> GameStats {
        var stats = GameStats.empty
        for game in 0 ..< games {
            let result = await animateGame(game: game, context: context, dispatcher: dispatcher)
            stats = stats.recording(outcome(result))
        }
        return stats
    }

    private func playPlainSession(_ context: SpinContext) async -> GameStats {
        var stats = GameStats.empty
        for _ in 0 ..< games {
            let drawn = drawnGrid(context: context)
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

    /// The non-TTY landing: stop each column at a random position on the same reel strip the
    /// reels scroll, so the board is always a real reel position (no impossible vertical
    /// triples). Used only when there's no keyboard to hand-stop with — a fresh random board
    /// each play.
    private func drawnGrid(context: SpinContext) -> [[Int]] {
        SlotOdds.gridStops(
            rows: context.config.rows,
            cols: context.config.cols,
            strips: context.strips,
            seed: nil,
        )
    }

    /// Animates one game: you skill-stop each column by hand (land on the showing face) via
    /// `spinGridSkill`. Opens this game's accepting window on the dispatcher so its keys advance
    /// this game's gate. When another game follows (and not `--auto-next`), the finale **holds**
    /// — a win keeps flashing — until one more Enter/Space, then the next game redraws over this.
    private func animateGame(game: Int, context: SpinContext, dispatcher: KeyDispatcher) async -> GridSpinResult {
        let config = context.config
        let gate = ReelGate()
        await dispatcher.beginGame(gate: gate, reelCount: config.cols)
        let hasNext = games > 1 && game < games - 1 && !autoNext
        // Arm the advance window *now*, before the spin, so the instant the last reel stops the
        // dispatcher hands the next press to it with no gap — a finale-time Enter advances rather
        // than being dropped. A mash that's already over-pressing the reels rolls straight into
        // this one press too (advancing immediately), which is the intended "mash to skip" path.
        var hold: (@Sendable () async -> Void)?
        if hasNext {
            let advance = ReelGate()
            await dispatcher.armNext(gate: advance)
            hold = { await advance.awaitTurn(0) }
        }
        let result = await spinSkill(context: context, gate: gate, hold: hold)
        guard hasNext else { return result }
        // Redraw the next game over this one so the session plays in place instead of scrolling.
        let gridLines = config.requiredHeight(cellHeight: context.theme.cellHeight) - 1
        emit("\u{1B}[\(gridLines)A")
        return result
    }

    private func spinSkill(
        context: SpinContext,
        gate: ReelGate,
        hold: (@Sendable () async -> Void)?,
    ) async -> GridSpinResult {
        let columns = SpinDriver.skillColumns(count: context.config.cols, gate: gate)
        return await SlotMachine.spinGridSkill(
            columns,
            rows: context.config.rows,
            paylines: context.paylines,
            theme: context.theme,
            plain: false,
            finaleHold: hold,
        )
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
