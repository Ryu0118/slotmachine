# 🎰 slotmachine

### 🎰 A terminal slot machine for dopamine kids.

Reels rip down the screen. You smash each one dead with a key. Three `7`s line
up on any **row or diagonal** and it blows up in your face. No timer. No
autoplay. No mercy. Just you, your thumb, and one more pull:

<img width="251" height="338" alt="スクリーンショット 2026-06-03 23 37 11" src="https://github.com/user-attachments/assets/185270f5-9e58-42ed-9a7e-c22c7561bb68" />



## Install it. Right now.

Runs on **macOS and Linux** — every [release](https://github.com/Ryu0118/slotmachine/releases)
ships a macOS universal binary (arm64 + x86_64) and Linux builds for x86_64 and
arm64 (aarch64). The installer below grabs the one for your platform.

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
mise use -g github:Ryu0118/slotmachine
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
slotmachine                 # the 3×3 board: smash ⏎ to stop each reel in turn
slotmachine -n 7            # a single row of 7 reels: chase 7777777
slotmachine --games 10      # 10 games: press a key between each, then session stats
slotmachine --games 10 --auto-next   # …or roll straight into each next game
```

By default you get the **3×3 board**. It pays along any of its three rows or two
diagonals. Line up the `7`s on any of those and you win big. Want a single row
instead? `-n N` gives you N reels (1–10) that pay when they all match.

**You stop the reels yourself.** Hit **Enter or Space** to slam the next reel,
left to right, and it locks onto **whatever face is flying past at that exact
instant**. That's the skill stop. That's the whole game.

Playing a run with `--games`? A win **keeps flashing** until you press Enter or
Space for the next game, so you can savour the hit, and a miss holds its board
the same way. Pass `--auto-next` to roll straight through instead.

Like a real machine, **each reel is weighted differently**: the `7` is generous on
the first reel and scarce on the last, so you'll line up two and watch the final
reel come *so close*. The near-miss is by design, not bad luck.

The eight faces: `7` (the one you're chasing), `BAR`, cherry, bell, plum, orange,
grape, and diamond.

## Every flag

| Flag | Meaning |
|------|---------|
| `-n`, `--reels` | Play a single row of N reels, 1–10 (default: the 3×3 board) |
| `--games` | Play N games in a row, then show session stats (default 1) |
| `--auto-next` | In a multi-game run, roll into the next game instead of waiting for a key |
| `--version` | Print the version |

## Terminal too small?

The reels need room to scroll: `(cell_width + 2) × columns` columns and a matching
number of rows. If your terminal is too small for that, `slotmachine` tells you the
size it needs and exits (code `1`) instead of cramming a torn animation into the
window. Make it bigger and run it again. (A piped or non-interactive run has no
window to outgrow, so it just prints the plain result.)

## License

slotmachine is released under the MIT License.
