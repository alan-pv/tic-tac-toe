class_name BotPlayer
extends Player

## The machine.
##
## Everything except the decision itself is already here: the pause before
## moving, the cancelling when the scene goes away, and the signal. All you owe
## this class is a cell number.


## Emitted the first time the bot has to fall back to a random cell because
## choose_move() gave it nothing. game.gd shows it on screen.
signal played_at_random

var think_time: float = 0.45

## 0.0 = play at random, 1.0 = play as well as you can. Yours to honour.
var skill: float = 0.8

## Bumped on every request and on every cancel. A pick that comes back from its
## await holding an old token knows the world moved on and stays quiet.
var _pick_token: int = 0

var _warned: bool = false


func setup(p_index: int, p_name: String, p_mark: int, config: GameConfig) -> void:
	super.setup(p_index, p_name, p_mark, config)
	is_human = false
	if config != null:
		think_time = config.bot_think_time
		skill = config.bot_skill


func request_pick(state: GameState) -> void:
	_pick_token += 1
	var token := _pick_token

	if think_time > 0.0:
		await get_tree().create_timer(think_time).timeout
	if token != _pick_token:
		return

	var index := choose_move(state.board, mark)

	if not state.can_play(index):
		index = _random_free_cell(state.board)
		if not _warned:
			_warned = true
			played_at_random.emit()

	if index < 0:
		push_error("The bot found nowhere to play. Is the board full?")
		return
	picked.emit(index)


func cancel_pick() -> void:
	_pick_token += 1


# ---------------------------------------------------------------- your work


## Picks the cell to play. The one interesting function in this file.
##
## Answer -1, or anything illegal, and the bot quietly plays a random legal
## cell instead. That is why the game is fully playable before you write a
## single line of this.
##
## A ladder worth climbing one rung at a time, each rung a visibly better rival:
##   1. play any free cell
##   2. if you can complete a line this move, complete it
##   3. if the rival would complete a line next move, block that cell
##   4. otherwise prefer the centre, then the corners, then the sides
##   5. look ahead: for every free cell, play it on a clone of the board, let the
##      rival answer with their best reply, and keep the cell whose worst
##      outcome is the least bad
##   6. spend `skill` to decide how often the bot bothers to be right, so the
##      easy presets feel careless instead of slow
##
## Infinite mode is the part worth thinking about before writing anything.
## Marks vanish, so there is no final position and a search that runs "until the
## board is full" never finishes. Cap how deep you look and judge the position
## you land in instead. And remember the bot's own oldest mark disappears the
## moment it plays again: a line it was one move from completing can undo itself.
##
## Godot you may not know yet:
##   BoardState.clone()      an independent copy: play on it, read it, drop it
##   Array.pick_random()     one random element
##   Array.shuffle()         shuffles in place, so ties stop being broken the
##                           same way every game and the bot stops feeling like
##                           a machine
##   randf()                 random float in 0..1, the natural partner of `skill`
##   INF / -INF              the usual starting points when you keep a best score
func choose_move(board: BoardState, my_mark: int) -> int:
	# TODO(you)
	return -1


# ---------------------------------------------------------------- plumbing


func _random_free_cell(board: BoardState) -> int:
	var free := board.free_indices()
	if free.is_empty():
		return -1
	return free.pick_random()
