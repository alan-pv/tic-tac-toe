# Working method — Alan + Claude

Portable document. Copy it to the root of the next project and hand it over at
the start of the session. It summarises how **Memorandum** (a memory match game,
Godot 4.7, August 2026) and **Tic Tac Toe** (three in a row with an infinite
mode, August 2026) were built, and what to adjust next time.

**Keep it current.** Whenever a session settles a rule, finds a trap or proves a
piece reusable, it goes in here before the session ends. This document is the
only thing that travels between projects; a lesson that stays in a chat log is a
lesson paid for twice.

---

## 1. The split

**Alan writes the code. Claude designs the architecture and guides.**

Claude delivers the project **assembled and runnable**, but with the core empty:

| Delivered COMPLETE (plumbing) | Left EMPTY (Alan's work) |
|---|---|
| Autoloads and global services | Game rules |
| Scene navigation | Algorithms (shuffle, search, decide) |
| Scene structure and layout | State and transitions |
| Async loops and signal ordering | Opponent AI |
| Signal wiring between nodes | Animations |
| Test scaffolding | |

The criterion: **if it is boring and hard to debug, Claude does it. If it is
interesting, Alan does it.** `await` loops and signal connection order fall
under "boring and hard to debug" — getting stuck there teaches nothing.

Every empty function looks like this:

```gdscript
func descriptive_name(param: Type) -> ReturnType:
    # TODO(you)
    return <safe value>
```

The safe return value matters: the project has to **start without blowing up**
even with nothing implemented. Seeing an empty board with a "implement
DeckBuilder" message is a far better starting point than a wall of errors.

---

## 2. Guidance: pseudocode, not code

In Memorandum the guidance above each function mixed prose with almost
copy-pasteable GDScript. **Too much code.** Tic Tac Toe was written to the rule
below and it holds up: keep it.

### The rule

> Describe **what** has to happen and **in what order**, not **how it is
> written**. Single exception: when a Godot built-in is needed that Alan
> probably does not know, name it with its exact signature and say what it does.

### Example — NOT like this

```
## WHAT IT SHOULD DO:
##   1. var deck: Array[CardData] = []
##   2. if not config.is_valid():
##          push_error("Invalid configuration: " + config.validation_error())
##          return deck
##   3. for value in range(1, groups + 1):
##          var color := CardPalette.color_for_value(value, groups)
##          for copy in config.group_size:
##              deck.append(CardData.new(value, color, copy))
```

That is the solution, written out. Copying it teaches nothing.

### Example — like THIS

```
## Builds the full deck, already shuffled.
##
##   if the configuration is not valid:
##       warn and return an empty deck (nobody should receive garbage)
##
##   work out how many distinct groups there are
##   for each group, first to last:
##       ask CardPalette for its color
##       create as many copies of that card as the group needs
##   shuffle and return
##
## Mind the loop bounds: in Godot `for i in n` walks 0..n-1, while
## `range(a, b)` walks a..b-1. Pick the wrong one and you end up with one
## group too many or too few.
##
## Godot you may not know yet:
##   Array.shuffle()      shuffles in place, returns nothing
##   push_error(text)     prints a red error WITHOUT stopping execution
```

Note the three parts: **steps in prose**, **the specific trap** (unsolved), and
**the Godot vocabulary** to go look up.

### What counts as "a built-in I probably don't know"

Always name these, with signature: `Array.shuffle()`, `randi_range(a, b)`,
`Color.from_hsv(h, s, v)`, `create_tween()`, `tween_callback()`,
`Callable.bind()`, `FileAccess.open()`, `JSON.parse_string()`,
`get_tree().create_timer(s).timeout`, `Dictionary.erase()`,
`Array.pick_random()`, `Array.slice(from, to)`.

No need to explain: `if`, `for`, `while`, `return`, arithmetic, `%`,
comparisons, or how to declare a variable.

---

## 3. The architecture that worked (reuse it if the project allows)

Four layers, and **dependencies only ever point downwards**:

```
  4. SCREENS    scenes/     what you see and click
  3. ACTORS     players/    who makes decisions
  2. CORE       core/       pure logic, ZERO nodes, testable
  1. SERVICES   autoloads/  things that survive a scene change
```

The concrete rules that held it together:

- **The core cannot mention a single node type.** Not `Node`, not `Control`, not
  a scene name. If it can't, it is testable.
- **One coordinator.** A single file (`game.gd`) knows all the others; nobody
  else knows more than its immediate neighbours. When something breaks, it is
  either in an isolated piece or in the wiring — and all the wiring is in one
  place.
- **Call downwards, emit upwards.** A child never reaches for its parent with
  `get_parent()`; it emits a signal and whoever cares listens.
- **Single source of truth.** A piece of data lives in exactly one place. Never
  duplicate "this card is face up" between the model and the visual node.
- **Base contract plus implementations.** `Player` → `HumanPlayer` /
  `BotPlayer`. The result: not one `if is_bot:` anywhere in the project.
- **Configuration as data, not code.** The difficulties were `.tres` files
  editable in the inspector. Balancing stopped being programming.

If the next project does not fit these four layers (something physics-heavy, or
with a lot of real-time state), **say so up front and propose the structure that
does fit.** Do not force this one.

---

## 4. The portable base

Four autoloads have now survived two projects without a line changing. They are
the starting kit: copy them before anything else exists.

| File | What it does | How portable |
|---|---|---|
| `autoloads/audio_manager.gd` | A pool of eight `AudioStreamPlayer`s, `play_sfx(path)` callable from anywhere, slight pitch variation, volume read from `GameSettings` | Verbatim. Only the `SFX_*` constants change |
| `autoloads/scene_switcher.gd` | `go_to(path)` and `go_back()` with a fade to black, a history stack, and the wait until `current_scene` really exists | Verbatim. Only the scene path constants change |
| `autoloads/ui_intro.gd` | Animates every screen into view; each scene tunes it with an optional `_intro_config()` on its root script | Verbatim |
| `autoloads/ui_sounds.gd` | Hover and click sound plus a bounce on every `BaseButton` in the project, wired automatically through `node_added` | Verbatim |

Travelling with them: `resources/themes/main_theme.tres` and the `.wav` files.
The theme cannot load without its font, so the font comes too, or the
`default_font` line has to go with it.

**`GameSettings` is not portable.** It holds whatever this particular game needs
to carry across a scene change. Rewrite it every time.

The palette is decided before a single scene exists and lives only in the theme.
Memorandum and Tic Tac Toe share it:

```
#121212  background          #1E1E1E  panels           #3A3A3A  buttons, cells
#007F5F  accent and focus    #b2b2b278  secondary text, faded things
```

---

## 5. The rhythm

1. Claude asks only what is essential **before** writing anything. Four
   questions was the right number for Tic Tac Toe: how far the scope reaches (a
   fixed 3x3 or a configurable board), who you play against, which assets carry
   over from the last project, and what the thing is called. Ask about anything
   that would change the architecture; decide anything with an obvious default
   without asking.
2. Claude assembles the whole project: folders, scenes, services, scaffolding.
3. Claude hands over an **ordered list of missions**, arranged so each step
   unlocks something visible. This worked very well: "after step 3 cards appear
   on the table", "after step 6 the game can be finished".
4. Alan implements. When something breaks, **he asks only for the location of
   the error, not the fix.**
5. Claude points at the file and line, explains **why** it fails, and stops
   there.
6. At the end, Claude strips the guidance and leaves clean files with a
   one-line header.

### When Alan reports an error

This is what worked best; keep it:

- Give the **exact file and line**.
- Explain the **concept** that is failing (`@onready` is not resolved until the
  node enters the tree; `push_error` does not halt execution; a `Dictionary`
  stores `Variant` and loses the array's type).
- **Do not write the corrected code.** Not even "it would be something like...".
- If the bug is Claude's (it happened twice), say so plainly and move on.
- Point at which test in `tests/` covers that failure, to close the loop.

---

## 6. Fixed conventions

- **Everything in English**: code, comments, documentation and UI strings.
  (Memorandum started with Spanish comments and was converted at the end; skip
  that detour next time.)
- An `ARCHITECTURE.md` with: folder map, layer diagram, the path of one action
  end to end, and the ordered mission table.
- Core tests from day one, with a ~40-line mini framework. No plugin needed.
  Watching a test go from `FAIL` to `PASS` is the best feedback loop there is.
- Guidance comments **during** development, stripped **at the end**. This
  project is the proof that the cycle works.
- Run `git init` at the start. Memorandum had no repository and every bulk edit
  had to be backed up by hand.
- **The repository is Alan's and only Alan's.** Commit as `APV-DevGame
  <alanpomaresv@gmail.com>`, with no `Co-Authored-By` and no session trailer.
  These are personal projects and the history should read like one.

---

## 7. Godot traps that already cost time

Worth flagging up front in the next project:

| Trap | Symptom |
|---|---|
| `@onready` does not exist until `add_child()` | *"...on a base object of type 'Nil'"* when configuring a freshly instantiated node |
| `push_error()` does not stop execution | The code carries on with invalid data |
| `Dictionary` stores `Variant`, loses `Array[int]` | *"Trying to assign an array of type Array to a variable of type Array[int]"* |
| You cannot annotate a type in `dict[key]: Type = []` | Syntax error; create the typed variable separately |
| `for i in n` walks 0..n-1, `range(a,b)` walks a..b-1 | One element too many or too few |
| `visible = false` removes the node from the container layout | Everything else re-flows |
| Scaling a container's direct child does not work | The container fights you; an intermediate `Pivot` node is needed |
| A pause menu freezes with `get_tree().paused` | It needs `PROCESS_MODE_WHEN_PAUSED` |
| Emitting a signal before anyone `await`s it | The `await` hangs forever; use `call_deferred` |
| A full-screen `ColorRect` eats every click | `MOUSE_FILTER_IGNORE` |
| A `PopupMenu` overlays the controls beneath it | Selecting an item can land the mouse release on the button underneath |
| `const X := PackedStringArray([...])` | *"Assigned value for constant isn't a constant expression"*. `Vector2()` and `Color()` are fine inside a `const`; the packed-array constructors are not. Use a plain `[...]` literal |
| Awaiting a function that never pauses | REDUNDANT_AWAIT. Expected while the animations are still empty stubs, and it clears itself once there is a tween |
| Two tweens pulling on the same property | `ui_sounds.gd` already bounces every button. An animation that also tweens that button's `scale` fights it; animate a child instead |

---

## 8. Outstanding

**Memorandum**

- `core/save_manager.gd` — deliberately left unimplemented. Records and
  preferences are not persisted; everything else works.
- Customisation with Alan's own art, sound and animation.

**Tic Tac Toe**

- The nine missions in its `ARCHITECTURE.md`.
- Nothing is persisted either: volumes, the last setup and the results all die
  with the process.
