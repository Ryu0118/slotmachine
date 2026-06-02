/// The outcome of one game, fed into ``GameStats``.
public struct GameOutcome: Sendable, Equatable {
    /// Whether any payline paid.
    public let didWin: Bool
    /// Whether the win was a jackpot (a line of the jackpot symbol).
    public let isJackpot: Bool
    /// How many paylines paid this game.
    public let lineCount: Int

    /// Creates a game outcome.
    public init(didWin: Bool, isJackpot: Bool, lineCount: Int) {
        self.didWin = didWin
        self.isJackpot = isJackpot
        self.lineCount = lineCount
    }
}

/// Running tallies across a session of games — the numbers the closing stats screen shows.
///
/// Pure value accumulator: ``recording(_:)`` returns a new tally, so a session folds its
/// outcomes into one `GameStats` with no shared state. Rates are computed, never stored.
public struct GameStats: Sendable, Equatable {
    /// How many games have been played.
    public let games: Int
    /// How many games paid at least one line.
    public let wins: Int
    /// How many games hit the jackpot.
    public let jackpots: Int
    /// The total number of paying lines across all games.
    public let totalLines: Int
    /// The longest run of consecutive winning games.
    public let bestStreak: Int
    /// The current run of consecutive winning games (resets to 0 on a loss).
    public let currentStreak: Int

    /// An empty tally — no games yet.
    public static let empty = GameStats(games: 0, wins: 0, jackpots: 0, totalLines: 0, bestStreak: 0, currentStreak: 0)

    /// The fraction of games that won, in `0...1` (0 when no games played).
    public var winRate: Double {
        games == 0 ? 0 : Double(wins) / Double(games)
    }

    /// The fraction of games that hit the jackpot, in `0...1` (0 when no games played).
    public var jackpotRate: Double {
        games == 0 ? 0 : Double(jackpots) / Double(games)
    }

    /// Returns a new tally with `outcome` folded in.
    public func recording(_ outcome: GameOutcome) -> GameStats {
        let streak = outcome.didWin ? currentStreak + 1 : 0
        return GameStats(
            games: games + 1,
            wins: wins + (outcome.didWin ? 1 : 0),
            jackpots: jackpots + (outcome.isJackpot ? 1 : 0),
            totalLines: totalLines + outcome.lineCount,
            bestStreak: max(bestStreak, streak),
            currentStreak: streak,
        )
    }

    /// Creates a tally with explicit fields. Prefer ``empty`` + ``recording(_:)``.
    public init(games: Int, wins: Int, jackpots: Int, totalLines: Int, bestStreak: Int, currentStreak: Int) {
        self.games = games
        self.wins = wins
        self.jackpots = jackpots
        self.totalLines = totalLines
        self.bestStreak = bestStreak
        self.currentStreak = currentStreak
    }
}
