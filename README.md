# 🎰 slotmachine

**A real slot machine. In your terminal. With real odds.**

The reels actually *scroll* — faces flying down the window like the machine on the
casino floor. You stop them **yourself**, by hand, key by key. And the `7` only
flashes past one time in ten… so landing it is all you.

```
╔════════╗╔════════╗╔════════╗
║   ▄▄   ║║  ████  ║║  o o   ║   ← the reels are
║  ▟██▙  ║║  ████  ║║   o    ║      flying right now,
║  ████  ║║   ▀▀   ║║        ║      each one at its
║  ████  ║║   __   ║║   /\   ║      own speed
║   ▀▀   ║║  /  \  ║║  /  \  ║
╚════════╝╚════════╝╚════════╝
        smash ⏎ to stop the next reel →
```

Catch three `7`s and the screen goes off:

```
╔════════╗╔════════╗╔════════╗
║ ██████ ║║ ██████ ║║ ██████ ║
║    ██  ║║    ██  ║║    ██  ║
║    ██  ║║    ██  ║║    ██  ║
║   ██   ║║   ██   ║║   ██   ║
║   ██   ║║   ██   ║║   ██   ║
╚════════╝╚════════╝╚════════╝
        🎰  J A C K P O T !  🎰
```

## Install it. Right now.

```bash
curl -fsSL https://raw.githubusercontent.com/Ryu0118/slotmachine/main/install.sh | bash
```

Then just type `slotmachine`. That's it. Go chase a `7`.

<details>
<summary>Other ways to install</summary>

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

</details>

## The hit you came for

Play a run of games and the screen rewards you for it — a stats panel that lights
up the more you win:

```
╔══════════════════════════════════╗
║🎰  S E S S I O N   S T A T S  🎰 ║
╠══════════════════════════════════╣
║ Games: 5                         ║
║ Wins: 3  (60%)                   ║
║ Win rate ████████░░░░░░ 60%      ║
║ Jackpots: 3  ★ JACKPOT ★        ║
║ Jackpot rate ████████░░░░░░ 60%  ║
║ Best streak: 2 🔥🔥              ║
║ Total lines: 3                   ║
╚══════════════════════════════════╝
```

A rainbow title, a green bar that fills as you win, a gold jackpot rate, a 🔥
streak counter, a blinking ★ when you hit the big one. Pure dopamine.

## How to play

```bash
slotmachine                 # 3 reels — smash ⏎ to stop each one in turn
slotmachine -n 7            # 7 reels — chase 7777777
slotmachine --grid          # a 3×3 board: rows AND diagonals pay
slotmachine --games 10      # 10 games back to back, then the stats panel
slotmachine --auto          # hands free — one press, the reels stop themselves
slotmachine --odds 0.5      # crank the luck: a 7 lands half the time
slotmachine --seed 42       # reproducible run
slotmachine --silent        # no animation, just the result
```

**You stop the reels yourself.** Hit any key (Enter, Space, …) to slam the next
reel — left to right — and it locks onto **whatever face is flying past at that
exact instant**. The `7` only scrolls by about `--odds` of the time, so catching
one is pure timing and nerve. That's the skill stop. That's the whole game.

Too fast? Hit `--auto` and let the machine stop itself — it still wins at the real
rate (it draws each outcome up front so a fixed timer can't cheat the odds).

## The odds are real

By default a `7` lands on a reel **one time in ten**. So:

| You're chasing | The odds |
|----------------|----------|
| 3 in a row (`slotmachine`) | 1 in 1,000 |
| 7 in a row (`-n 7`) | 1 in 10 million |
| a 3×3 board (`--grid`) | rows *and* both diagonals can pay |
| 9 in a row (`-n 9`) | about 1 in a **billion** |

That's a real machine — it's *meant* to almost never line up. Want a softer ride?
`--odds 0.5` drops the bar and the `7`s rain down.

The eight faces: `7` (the jackpot), `BAR`, cherry, bell, plum, orange, grape, and
diamond.

## Every flag

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

## How the odds actually work

`--odds` is the chance the `7` shows on a cell (it means *probability*, 0–1 — not an
odd number).

- **Hand stop** (the default): the reels scroll a weighted strip of faces in which the
  `7` appears about `--odds` of the time. You stop on whatever's showing, so catching a
  `7` is a matter of timing and luck — like a real machine. `--seed` doesn't make this
  reproducible (your reflexes decide it).
- **`--auto`**: the whole grid is drawn up front at `--odds`, then revealed on a timer —
  a fixed interval can't aim, so drawing up front keeps the win rate honest. `--seed`
  reproduces an auto session exactly.

## Terminal too small?

The animated grid needs `(cell_width + 2) × columns` columns and a matching number
of rows. When the terminal is too small in either dimension, `slotmachine` falls
back to the plain result line so the animation never wraps and tears.

## License

slotmachine is released under the MIT License.
