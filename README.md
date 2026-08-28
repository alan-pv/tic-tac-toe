# Tic Tac Toe

Three in a row, and an infinite mode where it never ends.

Godot 4.7. Turn **infinite mode** on and each player may only keep three marks
on the board: the fourth one you place pushes your oldest one off. The board
never fills up, nothing you build is ever safe, and no round can end in a draw.
The mark about to disappear is drawn faded, so you can see it coming.

- One human against the bot, or two people on the same device.
- Matches are played to a number of rounds, and the loser opens the next one.
- Three bot difficulties, kept as editable `.tres` files.

## Running it

Open the project in Godot 4.7 and press F5.

The tests live in `tests/`: open `tests/tests.tscn` and press **F6**, or run
`godot --headless --script res://tests/run_tests.gd`.

## State of the project

The plumbing is finished and the game is assembled. The interesting parts are
still empty, each one marked `# TODO(you)` with a description of what it has to
do and which trap is waiting inside it. `ARCHITECTURE.md` has the ordered list
of missions; `WORKING-METHOD.md` explains why the project is handed over this
way.

Reused from Memorandum without changes: `audio_manager.gd`, `scene_switcher.gd`,
`ui_intro.gd`, `ui_sounds.gd`, the theme and the sound effects.

## Palette

| | |
|---|---|
| `#121212` | background |
| `#1E1E1E` | panels |
| `#3A3A3A` | cells and buttons |
| `#007F5F` | X, focus, accents |
| `#b2b2b278` | the mark about to vanish, secondary text |

MIT licensed.
