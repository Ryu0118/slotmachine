# 🎰 slotmachine

**Pull the lever. Stop the reels yourself. Chase the `7`.**

A real slot machine, right in your terminal — and the reels actually *scroll*,
faces flying down the window like the machine on the casino floor. No timer, no
autoplay: you slam each reel to a halt by hand, key by key, and pray it lands on
the `7`. Catch three and the screen goes off.

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

Line the `7`s up — across any **row** or **diagonal** — and you hit it. Here a
diagonal of `7`s pays:

```
╔════════╗╔════════╗╔════════╗
║ ██████ ║║   __   ║║  o o   ║
║    ██  ║║  /  \  ║║ o o o  ║
║    ██  ║║ |    | ║║  o o   ║
║   ██   ║║  \__/  ║║   o    ║
║   ██   ║║        ║║        ║
╠════════╣╠════════╣╠════════╣
║  .--.  ║║ ██████ ║║  /\    ║
║ / XX \ ║║    ██  ║║ /  \   ║
║ \ XX / ║║    ██  ║║<    >  ║
║  '--'  ║║   ██   ║║ \  /   ║
║        ║║   ██   ║║  \/    ║
╠════════╣╠════════╣╠════════╣
║  ▄▄    ║║  .--.  ║║ ██████ ║
║ ▟██▙   ║║ / XX \ ║║    ██  ║
║ ████   ║║ \ XX / ║║    ██  ║
║ ████   ║║  '--'  ║║   ██   ║
║  ▀▀    ║║        ║║   ██   ║
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

## How to play

```bash
slotmachine                 # the 3×3 board — smash ⏎ to stop each reel in turn
slotmachine -n 7            # a single row of 7 reels — chase 7777777
slotmachine --games 10      # 10 games back to back, then your session stats
```

By default you get the **3×3 board** — it pays along any of its three rows or two
diagonals. Line up the `7`s on any of those and it's a jackpot. Want a single row
instead? `-n N` gives you N reels (1–10) that pay when they all match.

**You stop the reels yourself.** Hit any key (Enter, Space, …) to slam the next
reel — left to right — and it locks onto **whatever face is flying past at that
exact instant**. That's the skill stop. That's the whole game.

The eight faces: `7` (the jackpot), `BAR`, cherry, bell, plum, orange, grape, and
diamond.

## Every flag

| Flag | Meaning |
|------|---------|
| `-n`, `--reels` | Play a single row of N reels, 1–10 (default: the 3×3 board) |
| `--games` | Play N games in a row, then show session stats (default 1) |
| `--version` | Print the version |

## Terminal too small?

The animated grid needs `(cell_width + 2) × columns` columns and a matching number
of rows. When the terminal is too small in either dimension, `slotmachine` falls
back to the plain result line so the animation never wraps and tears.

## License

slotmachine is released under the MIT License.
