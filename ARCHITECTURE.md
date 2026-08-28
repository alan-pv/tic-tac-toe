# Tic Tac Toe — architecture

Godot 4.7. Classic three in a row, plus an **infinite mode** in which each
player keeps only a fixed number of marks on the board: the next one you place
pushes your oldest one off, so the board never fills and no round ever dies in a
draw.

Same four layers as Memorandum, same rule: **dependencies only point downwards.**

```
  4. SCREENS    scenes/     what you see and click
  3. ACTORS     players/    who decides where to play
  2. CORE       core/       pure logic, ZERO nodes, testable
  1. SERVICES   autoloads/  things that survive a scene change
```

- `core/` does not mention a single node type. That is why `tests/` can run it
  without opening a scene.
- One coordinator: `scenes/game/game.gd`. It knows every other file; nobody else
  knows more than its immediate neighbours.
- Call downwards, emit upwards. No `get_parent()` anywhere.
- Single source of truth. `BoardState` owns what is on the board; a `Cell` only
  displays a copy of it.
- `Player` -> `HumanPlayer` / `BotPlayer`, so there is not one `if is_bot:` in
  the project.
- Configuration as data: the bot difficulties are `.tres` files in
  `resources/difficulties/`.

---

## Folder map

```
autoloads/          services, alive for the whole run
  game_settings.gd    the config for the next match, the result of the last one
  scene_switcher.gd   screen changes with a fade                    (from Memorandum)
  audio_manager.gd    a pool of sound players                       (from Memorandum)
  ui_sounds.gd        hover/click sound and bounce on every button  (from Memorandum)
  ui_intro.gd         animates each screen into view                (from Memorandum)

core/               pure logic, no nodes, no signals except in game_state
  mark.gd             the enum: NONE / X / O, and two helpers
  board_state.gd      the 3x3 grid and the placement order of each player
  game_rules.gd       which lines win, what counts as a draw
  move_result.gd      what one move produced, as a typed object
  game_state.gd       the match: board, turn, rounds won
  game_config.gd      the settings of a match, and their validation
  difficulty_preset.gd  a bot difficulty as an editable resource

players/            who decides
  player.gd           the contract: request_pick(state) -> picked(index)
  human_player.gd     waits for a legal click
  bot_player.gd       waits, thinks, answers

scenes/             what you see
  main_menu/          title, how to play, quit
  setup/              builds the GameConfig for the next match
  game/               game.gd (coordinator), board, cell, hud, pause menu
  results/            who won

tests/              a forty-line framework and four suites
resources/          the theme and the three bot difficulties
assets/             the font and the sounds
```

---

## One turn, end to end

```
  the player clicks a cell
      Cell.pressed              -> clicked(index)
      Board                     -> cell_clicked(index)
      game.gd                   -> hands the index to every HumanPlayer
      HumanPlayer               -> only the one waiting answers: picked(index)

  game.gd was already waiting on `await player.picked`

      game.gd  -> state.play(index)
                     GameState asks BoardState to place the mark
                     BoardState may push the player's oldest mark off
                     GameState asks GameRules whether that made a line
                     GameState scores it, or hands the turn over
                 <- MoveResult

      game.gd  -> await board.place(result.index, result.mark)
                  await board.vanish(result.vanished_index)   if one went
                  await board.highlight(result.line)          if it won

  and around again
```

Two details worth remembering:

- **The board on screen is not driven by GameState's signals.** `game.gd`
  animates it by hand, precisely so it can `await` one animation before starting
  the next. `turn_changed` and `score_changed` only feed the HUD.
- **`request_pick` is called with `call_deferred`.** A bot with a think time of
  zero would emit `picked` before the `await` below it is listening, and the
  turn would hang forever.

---

## The missions

Run the tests as you go: open `tests/tests.tscn` and press **F6**, or
`godot --headless --script res://tests/run_tests.gd`. They all fail right now.
That is the starting line.

Until mission 4 is done, the game screen tells you what is still missing instead
of sitting there ignoring your clicks.

| # | Where | What you write | What it unlocks |
|---|---|---|---|
| 1 | `core/mark.gd` | `opponent()` | `test_mark` goes green |
| 2 | `core/board_state.gd` | `mark_at()`, `is_free()`, `free_indices()`, `is_full()` | the board can answer questions about itself |
| 3 | `core/board_state.gd` | `place()`, classic half only | marks can be put down |
| 4 | `core/game_state.gd` | `can_play()`, `play()`, `start_round()` | **clicking drops marks on the board and the turn alternates** |
| 5 | `core/game_rules.gd` | `all_lines()`, `winning_line()` | **rounds can be won and the line lights up** |
| 6 | `core/game_rules.gd`, `core/game_state.gd` | `is_draw()`, `is_match_over()` | **matches end and the results screen appears** |
| 7 | `core/board_state.gd` | the eviction half of `place()`, `next_to_vanish()` | **infinite mode, and the faded warning** |
| 8 | `players/bot_player.gd` | `choose_move()` | **a rival worth playing.** Until then the bot plays at random and says so |
| 9 | `scenes/game/cell.gd` | `play_place()`, `play_vanish()`, `play_win()` | **it stops looking like a prototype** |

Missions 5 and 7 are independent of each other. Everything else runs in order.

---

## Traps already paid for

The ones from `WORKING-METHOD.md` that this project is most likely to hit again:

| Trap | Symptom |
|---|---|
| `@onready` does not exist until `add_child()` | *"...on a base object of type 'Nil'"*. `Board.build()` adds the cell before calling `setup()` for exactly this reason |
| Emitting a signal before anyone awaits it | The turn hangs. That is why `request_pick` is deferred |
| `visible = false` drops the node out of the layout | The setup screen uses it on purpose to hide whole rows |
| `push_error()` does not stop execution | The code carries on with invalid data |
| `Dictionary` stores `Variant` and loses `Array[int]` | Why `MoveResult` is a class and why `BoardState` keeps two arrays instead of one dictionary |
| `for i in n` walks 0..n-1, `range(a, b)` walks a..b-1 | One line too many or too few in `all_lines()` |
| Awaiting a function that never pauses | The REDUNDANT_AWAIT warning on the empty animations in `cell.gd`. Harmless, and it goes away by itself |

---

## Not done on purpose

- Nothing is saved: volumes, the last setup and the results all die with the
  process. There is no `save_manager` yet.
- The bot difficulties differ only in `bot_think_time` and `bot_skill`. What
  `bot_skill` actually means is up to `choose_move()`.
