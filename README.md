# Tic Tac Toe

Three in a row, and an infinite mode where it never ends. Built with
**Godot 4.7** (GDScript).

Turn **infinite mode** on and each player may only keep a few marks on the
board: the next one you place pushes your oldest one off. The board never fills
up, nothing you build is ever safe, and no round can end in a draw. The mark
about to disappear is drawn faded, so you can see it coming.

## What it does

- **Classic or infinite**, three marks each, and a match is played to a number
  of rounds with the players taking turns opening. Every mark is drawn
  faded by how soon its owner will push it off, so the whole board can be read
  at a glance instead of only the next casualty.
- **Against the bot**, which is a depth-limited minimax with alpha-beta
  pruning: at full skill it never loses. Three difficulties, kept as editable
  `.tres` resources, so balancing it is not programming.
- **Two people on the same device**, taking turns.
- **Two people online**, in a browser or on the desktop: browse rooms, create
  one with an optional password, agree on the settings and play. The chat sits
  in the corner of the room, of the match and of the results. If your opponent
  walks off mid-match a bot takes their seat and the game carries on.
- Sound effects and **background music**, with a volume slider per audio bus,
  remembered between runs; a staggered UI intro and a shared theme.

## Running it

Open the project folder with Godot 4.7 or newer and press <kbd>F5</kbd>. There
is nothing to install and no plugins to enable. The main scene is
`scenes/main_menu/main_menu.tscn`.

The tests live in `tests/`: open `tests/tests.tscn` and press <kbd>F6</kbd>, or
run `godot --headless --script res://tests/run_tests.gd`.

Online play needs a relay to sit between the players, because a browser can
open connections but never accept them. This game ships pointing at a public
one; `net/net_settings.gd` holds the address and the `game_id` that keeps one
relay usable by several games at once.

## Architecture

Four layers, with dependencies pointing only downwards:

```
  4. SCREENS    scenes/     what you see and click
  3. ACTORS     players/    who decides where to play
  2. CORE       core/       pure logic, zero nodes, testable
  1. SERVICES   autoloads/  things that survive a scene change

     NETWORK    net/        the wire, bolted on at the services layer
```

The rules that hold it together:

- The **core** never mentions a node type, which is what makes it testable.
- **One coordinator** (`scenes/game/game.gd`) knows every other piece; nobody
  else knows more than its immediate neighbours.
- **Call downwards, emit upwards** — a child never reaches for its parent.
- **Single source of truth**: `BoardState` owns what is on the board, and a
  `Cell` only draws a copy of it.
- **Base contract plus implementations** (`Player` → `HumanPlayer` /
  `BotPlayer` / `NetPlayer`), so there is not one `if is_bot:` in the project.

Online play adds one idea rather than a second code path. The relay is
**game-agnostic** — it knows peers, rooms and passwords, and forwards the rest
without looking inside. The client that created the room acts as **referee**: a
click only *asks*, and the turn loop advances for everyone on the referee's
confirmation. The game is deterministic given the config and the sequence of
confirmed cells, so both clients run the same `game.gd` and the entire
networked state of a match is a list of integers.

Some pieces are written to be copied straight out of here, and none of them
knows what tic tac toe is:

| Piece | Files |
|---|---|
| Chat | `scenes/common/chat_panel.gd`, `chat_dock.gd`, `net/room_chat.gd` |
| Audio | `autoloads/audio_manager.gd`, `resources/audio/default_bus_layout.tres`, `scenes/common/audio_settings.gd` |
| Rooms | `net/`, the `Net` and `Rooms` autoloads |
| Screens | `autoloads/scene_switcher.gd`, `ui_intro.gd`, `ui_sounds.gd` |

Music is a convention rather than a setting: `AudioManager` plays
`assets/audio/music.ogg` if the file is there, in every scene, and the Music
slider appears by itself because the settings panel builds one row per bus the
project has.

## Palette

| | |
|---|---|
| `#121212` | background |
| `#1E1E1E` | panels and text fields |
| `#2B2B2B` | cells and buttons at rest (`#3B3B3B` hovered), outlined in `#151515` |
| `#007F5F` | X, focus rings, panel accents |
| `#E8EDF3` | O and body text |
| `#b2b2b278` | the mark about to vanish, secondary text |

The theme also carries named button variants for the screens that need one:
`BlueButton` `#2196F3`, `GreenButton` `#4CAF50`, `RedButton` `#F44336`,
`PinkButton` `#F06292`.

## Assets

The code is MIT. Everything under `assets/` is third-party and keeps its own
licence — check each one before reusing this repository as a starting point:

| | |
|---|---|
| `assets/fonts/Silkscreen-Regular.ttf` | SIL Open Font License 1.1 |
| `assets/fonts/Daydream DEMO.otf` | demo release, free for personal use only |
| `assets/audio/` | sound effects and music, third-party |

## License

MIT. See [LICENSE](LICENSE).
