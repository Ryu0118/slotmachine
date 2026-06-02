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

    @Flag(name: .customLong("auto"), help: "Press once to spin; reels then stop on their own (ka-chunk, ka-chunk).")
    var auto = false

    @Flag(name: [.customLong("silent"), .customLong("plain")], help: "Disable the animation; print the result only.")
    var silent = false

    mutating func run() async throws {
        let theme = try SevenTheme.make()
        let config = try SlotConfig(reels: reels, odds: odds, symbolCount: theme.symbols.count)
        let drawn = SlotOdds.plan(reels: config.reels, weights: config.weights, seed: seed)

        // One decision drives everything: a roomy interactive TTY animates, anything else
        // (pipe, CI, NO_COLOR, --silent, too-narrow window) prints the plain verdict instead.
        let narrow = (TerminalWidth.columns ?? .max) < config.requiredWidth(cellWidth: theme.cellWidth)
        guard OutputMode.shouldAnimate(forcePlain: silent || narrow) else {
            let reels = SpinDriver.immediateReels(drawn: drawn)
            let result = await SlotMachine.spinSymbols(reels, theme: theme, plain: true)
            Self.printVerdict(result)
            return
        }
        await animate(drawn: drawn, theme: theme)
    }

    /// Spins with the animation and the keypress / auto stop. Prints no verdict — the reels
    /// and the closing flash are the result.
    private func animate(drawn: [Int], theme: SlotTheme) async {
        let gate = ReelGate()
        let reels = SpinDriver.reels(drawn: drawn, gate: gate)
        await KeyReader.withKeys { keys in
            async let spin: SymbolSpinResult = SlotMachine.spinSymbols(reels, theme: theme, plain: false)
            await drive(keys: keys, gate: gate, reelCount: drawn.count)
            _ = await spin
        }
    }

    /// Releases the reels: in `--auto`, wait for one keypress then stop them on a timer; by
    /// default, stop one reel per keypress.
    private func drive(keys: AsyncStream<UInt8>, gate: ReelGate, reelCount: Int) async {
        if auto {
            var iterator = keys.makeAsyncIterator()
            _ = await iterator.next() // one key to start the auto spin
            await SpinDriver.driveByTimer(gate: gate, reelCount: reelCount, stagger: Self.stagger)
        } else {
            await SpinDriver.driveByKeys(keys, gate: gate, reelCount: reelCount)
        }
    }

    /// Seconds between reels in the auto stop.
    private static let stagger = 0.28

    private static func printVerdict(_ result: SymbolSpinResult) {
        let verdict = if result.isJackpot {
            "🎰 JACKPOT! 🎰"
        } else if result.allSame {
            "🎉 winner!"
        } else {
            "no win — spin again."
        }
        FileHandle.standardOutput.write(Data("\(verdict)\n".utf8))
    }
}
