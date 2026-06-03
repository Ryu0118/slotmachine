# 🎰 slotmachine

**A real slot machine. In your terminal.**

The reels actually *scroll* — faces flying down the window like the machine on the
casino floor. You stop them **yourself**, by hand, key by key. Catch the `7`s and
the screen goes off.

```
╔════════╗╔════════╗╔════════╗
║   ▄▄   ║║  ████  ║║  o o   ║
║  ▟██▙  ║║  ████  ║║   o    ║   ← the 3×3 board,
║  ████  ║║   ▀▀   ║║        ║      reels flying,
║  ████  ║║   __   ║║   /\   ║      each at its
║   ▀▀   ║║  /  \  ║║  /  \  ║      own speed
╠════════╣╠════════╣╠════════╣
║   __   ║║ |    | ║║ <    > ║
║  /  \  ║║  \__/  ║║  \  /  ║   ← smash ⏎ to stop
║ |    | ║║        ║║   \/   ║      the next reel →
║  \__/  ║║   ||   ║║ ██████ ║
╠════════╣╠════════╣╠════════╣
║   ▄▄   ║║  .--.  ║║  o o   ║
║  ▟██▙  ║║ / XX \ ║║ o o o  ║
║  ████  ║║ \ XX / ║║  o o   ║
║  ████  ║║  '--'  ║║   o    ║
║   ▀▀   ║║        ║║        ║
╚════════╝╚════════╝╚════════╝
```

Line the `7`s up — across any **row** or **diagonal** — and you hit it:

```
╔════════╗╔════════╗╔════════╗
║ ██████ ║║ ██████ ║║ ██████ ║
║    ██  ║║    ██  ║║    ██  ║
║    ██  ║║    ██  ║║    ██  ║
║   ██   ║║   ██   ║║   ██   ║
║   ██   ║║   ██   ║║   ██   ║
╠════════╣╠════════╣╠════════╣
║ ██████ ║║ ██████ ║║ ██████ ║
║    ██  ║║    ██  ║║    ██  ║
║    ██  ║║    ██  ║║    ██  ║
║   ██   ║║   ██   ║║   ██   ║
║   ██   ║║   ██   ║║   ██   ║
╠════════╣╠════════╣╠════════╣
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
slotmachine                 # the 3×3 board — smash ⏎ to stop each reel in turn
slotmachine -n 7            # a single row of 7 reels — chase 7777777
slotmachine --games 10      # 10 games back to back, then the stats panel
slotmachine --auto          # hands free — one press, the reels stop themselves
slotmachine --seed 42       # reproducible run
slotmachine --silent        # no animation, just the result
```

By default you get the **3×3 board** — it pays along any of its three rows or two
diagonals. Line up the `7`s on any of those and it's a jackpot. Want a single row
instead? `-n N` gives you N reels (1–10) that pay when they all match.

**You stop the reels yourself.** Hit any key (Enter, Space, …) to slam the next
reel — left to right — and it locks onto **whatever face is flying past at that
exact instant**. That's the skill stop. That's the whole game. Too quick for you?
`--auto` lets the machine stop itself, hands free.

The eight faces: `7` (the jackpot), `BAR`, cherry, bell, plum, orange, grape, and
diamond.

## Every flag

| Flag | Meaning |
|------|---------|
| `-n`, `--reels` | Play a single row of N reels, 1–10 (default: the 3×3 board) |
| `--games` | Play N games in a row, then show session stats (default 1) |
| `--auto` | Stop the reels on a timer instead of by hand |
| `--seed` | Seed for a reproducible spin |
| `--silent`, `--plain` | Disable the animation; print the result only |
| `--version` | Print the version |

## Terminal too small?

The animated grid needs `(cell_width + 2) × columns` columns and a matching number
of rows. When the terminal is too small in either dimension, `slotmachine` falls
back to the plain result line so the animation never wraps and tears.

## License

slotmachine is released under the MIT License.
