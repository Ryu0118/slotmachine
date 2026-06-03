# 🎰 slotmachine

A terminal slot machine with real slot-machine odds. Spin a row of reels — or a
3×3 grid that pays on rows and diagonals — and chase the `7`s. Built on
[SlotKit](https://github.com/Ryu0118/SlotKit).

```
╔══════╗╔══════╗╔══════╗
║██████║║██████║║██████║
║   ██ ║║   ██ ║║   ██ ║
║  ██  ║║  ██  ║║  ██  ║
║ ██   ║║ ██   ║║ ██   ║
║ ██   ║║ ██   ║║ ██   ║
╚══════╝╚══════╝╚══════╝
🎰 JACKPOT! 🎰
```

Every reel scrolls its faces vertically — like a real machine — and lands on a
face. Line them all up to win; line up the `7`s for the jackpot. The odds are
real — by default a `7` lands on a reel one time in ten, so a 3-reel jackpot is
1 in 1,000.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ryu0118/slotmachine/main/install.sh | bash
```

### Other methods

#### Nest ([mtj0928/nest](https://github.com/mtj0928/nest))

```bash
nest install Ryu0118/slotmachine
```

#### Mise ([jdx/mise](https://github.com/jdx/mise))

```bash
mise use -g ubi:Ryu0118/slotmachine
```

#### Build from source

Requires Swift 6.2+:

```bash
git clone https://github.com/Ryu0118/slotmachine
cd slotmachine
swift build -c release
cp .build/release/slotmachine /usr/local/bin/
```

## Usage

```bash
slotmachine                 # single row of 3 reels; press a key to stop each in turn
slotmachine -n 7            # 7 reels — chase 7777777
slotmachine --grid          # a 3×3 machine that pays on rows AND diagonals
slotmachine --games 10      # play 10 games back to back, then session stats
slotmachine --auto          # press once, then the reels stop on their own
slotmachine --odds 0.5      # easier: a 7 lands half the time
slotmachine --seed 42       # reproducible spin
slotmachine --silent        # no animation, print the result line only
```

On a terminal you **stop the reels yourself** — a real skill stop. Press any key
(Enter, Space, …) to stop the next reel (or column), left to right, and it lands on
**whatever's spinning by at that instant**. A `7` only scrolls past about `--odds`
of the time, so catching one is genuinely hard.

With `--auto` the reels stop on their own — and because a fixed interval can't
"aim", auto draws each outcome up front at the configured odds (so it still wins at
the right rate instead of never).

`--games N` plays `N` games in a row and ends with a **session stats** panel:
games, wins and win rate, jackpots, your best streak, and total lines, with a
win-rate bar that lights up. You still stop each game yourself by keypress — add
`--auto` to let them run hands-free. With `--seed` the whole session is
reproducible (each game still differs).

A single row (`--reels`) pays when every reel matches. The `--grid` board is a 3×3
machine that pays along any of its three rows or two diagonals — line up the `7`s
on any line for the jackpot. The eight faces are `7` (the jackpot), `BAR`, cherry,
bell, plum, orange, grape, and diamond.

| Flag | Meaning |
|------|---------|
| `-n`, `--reels` | Reels in a single-row machine, 1–10 (default 3) |
| `--grid` | Play the 3×3 machine (rows + diagonals) |
| `--games` | Play N games in a row, then show session stats (default 1) |
| `--odds` | Chance a `7` shows, 0–1 (default `0.1`). 'odds' = probability |
| `--auto` | Stop the reels on a timer (drawn up front) instead of by hand |
| `--seed` | Seed for a reproducible spin |
| `--silent`, `--plain` | Disable the animation; print the result only |
| `--version` | Print the version |

A full line of `7`s has probability `odds^length`, so longer lines get rare fast —
at the default odds, nine `7`s (`--reels 9`) is about 1 in a billion. That's a
real slot machine; it's meant to almost never line up. Lower the bar with `--odds`.

## Terminal size

The animated grid needs `(cell_width + 2) × columns` columns and a matching number
of rows. When the terminal is too small in either dimension, `slotmachine` falls
back to the plain result line so the animation never wraps and tears.

## How the odds work

`--odds` is the chance the `7` shows on a cell (it means *probability*, 0–1 — not an
odd number).

- **Hand stop** (the default): the reels scroll a weighted strip of faces in which the
  `7` appears about `--odds` of the time. You stop on whatever's showing, so catching a
  `7` is a matter of timing and luck — like a real machine. `--seed` doesn't make this
  reproducible (your reflexes decide it).
- **`--auto`**: the whole grid is drawn up front at `--odds`, then revealed on a timer —
  a fixed interval can't aim, so drawing up front keeps the win rate honest. `--seed`
  reproduces an auto session exactly.

## License

slotmachine is released under the MIT License.
