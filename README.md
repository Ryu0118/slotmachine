# 🎰 slotmachine

A terminal slot machine with real slot-machine odds. Spin a row of reels — or a
square grid that pays on rows and diagonals — and chase the `7`s. Built on
[SlotKit](https://github.com/Ryu0118/SlotKit).

```
╔══════╗╔══════╗╔══════╗
║██████║║██████║║██████║
║   ██ ║║   ██ ║║   ██ ║
║  ██  ║║  ██  ║║  ██  ║
║ ██   ║║ ██   ║║ ██   ║
║ ██   ║║ ██   ║║ ██   ║
╚══════╝╚══════╝╚══════╝
  0 0 0  — 🎰 JACKPOT! 🎰
```

Every reel spins in parallel and lands on a face. Line them all up to win; line up
the `7`s for the jackpot. The odds are real — by default a `7` lands on a reel one
time in ten, so a 3-reel jackpot is 1 in 1,000.

## Install

```bash
swift build -c release
.build/release/slotmachine
```

## Usage

```bash
slotmachine                 # single row of 3 reels; press a key to stop each in turn
slotmachine -n 7            # 7 reels — chase 7777777
slotmachine --grid 3        # a 3×3 machine that pays on rows AND diagonals
slotmachine --grid 5        # a 5×5 machine (5 rows + 2 diagonals = 7 lines)
slotmachine --games 10      # play 10 games back to back, then session stats
slotmachine --auto          # press once, then the reels stop on their own
slotmachine --odds 0.5      # easier: a 7 lands half the time
slotmachine --seed 42       # reproducible spin
slotmachine --silent        # no animation, print the result line only
```

On a terminal the reels spin and you **stop them yourself**: press any key
(Enter, Space, …) to stop the next reel (or column), left to right. With `--auto`,
one keypress starts the spin and the reels stop one after another on their own.

`--games N` plays `N` games in a row and ends with a **session stats** panel:
games, wins and win rate, jackpots, your best streak, and total lines, with a
win-rate bar that lights up. You still stop each game yourself by keypress — add
`--auto` to let them run hands-free. With `--seed` the whole session is
reproducible (each game still differs).

A single row (`--reels`) pays when every reel matches. A square grid (`--grid N`)
pays along any of its `N` rows or two diagonals — line up the `7`s on any line for
the jackpot. The eight faces are `7` (the jackpot), `BAR`, cherry, bell, plum,
orange, grape, and diamond.

| Flag | Meaning |
|------|---------|
| `-n`, `--reels` | Reels in a single-row machine, 1–10 (default 3) |
| `--grid` | Play a square N×N machine, 3–9 (rows + diagonals) |
| `--games` | Play N games in a row, then show session stats (default 1) |
| `--odds` | Per-cell chance of a `7`, in `(0, 1]` (default `0.1`) |
| `--auto` | Press once to spin; reels then stop on their own |
| `--seed` | Seed for a reproducible spin |
| `--silent`, `--plain` | Disable the animation; print the result only |
| `--version` | Print the version |

A full line of `7`s has probability `odds^length`, so longer lines and bigger grids
get rare fast — at the default odds, nine `7`s is about 1 in a billion. That's a
real slot machine; it's meant to almost never line up. Lower the bar with `--odds`.

## Terminal size

The animated grid needs `(cell_width + 2) × columns` columns and a matching number
of rows. When the terminal is too small in either dimension, `slotmachine` falls
back to the plain result line so the animation never wraps and tears.

## How the odds work

The jackpot symbol (`7`) lands on each cell with probability `--odds`; the remaining
probability is split evenly across the other faces. The whole grid is drawn up front,
so `--seed` reproduces a spin exactly — the animation only reveals what was already
drawn.

## License

slotmachine is released under the MIT License.
