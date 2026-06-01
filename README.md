# 🎰 slotmachine

A terminal slot machine with real slot-machine odds. Spin 2–9 reels and chase the
`7`s — built on [SlotKit](https://github.com/Ryu0118/SlotKit).

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
slotmachine                 # 3 reels, default odds
slotmachine -n 7            # 7 reels — chase 7777777
slotmachine --odds 0.5      # easier: a 7 lands half the time
slotmachine --seed 42       # reproducible spin
slotmachine --silent        # no animation, print the result line only
```

| Flag | Meaning |
|------|---------|
| `-n`, `--reels` | Number of reels, 2–9 (default 3) |
| `--odds` | Per-reel chance of a `7`, in `(0, 1]` (default `0.1`) |
| `--seed` | Seed for a reproducible spin |
| `--silent`, `--plain` | Disable the animation; print the result only |
| `--version` | Print the version |

The jackpot (all `7`s) has probability `odds^reels`, so high reel counts get rare
fast — at the default odds, nine `7`s is about 1 in a billion. That's a real slot
machine; it's meant to almost never line up. Lower the odds bar with `--odds`.

## Terminal width

The animated grid needs `(reel_width + 2) × reels` columns — about 72 for 9 reels.
On a narrower terminal `slotmachine` automatically falls back to the plain result
line so the animation never wraps and tears.

## How the odds work

The jackpot symbol (`7`) lands on each reel with probability `--odds`; the remaining
probability is split evenly across the other faces. The draw is decided up front, so
`--seed` reproduces a spin exactly — the animation only reveals what was already
drawn.

## License

slotmachine is released under the MIT License.
