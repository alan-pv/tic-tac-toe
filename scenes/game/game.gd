extends Control

## Match coordinator: builds everything, wires it together, and drives the loop.
##
## This is the one file that knows every other one. Nobody else knows more than
## its immediate neighbours, so when something misbehaves it is either inside an
## isolated piece or in the wiring right here.
##
## The shape of a turn, end to end:
##
##   game.gd asks the player for a cell   -> player.request_pick(state)
##   the player answers                   -> await player.picked
##   the rules are applied                -> state.play(index) -> MoveResult
##   the result is animated               -> await board.place() / board.vanish()
##   the round ends, or the turn passes


const ROUND_GUARD := 99
const MOVE_GUARD := BoardState.CELL_COUNT * 6

@onready var board: Board = %Board
@onready var hud: HUD = %HUD
@onready var pause_menu: PauseMenu = %PauseMenu

var config: GameConfig
var state: GameState
var players: Array[Player] = []

var elapsed_seconds: float = 0.0

var _running: bool = false


func _ready() -> void:
	config = GameSettings.config
	if config == null:
		push_warning("No GameConfig in GameSettings: falling back to a default one.")
		config = GameConfig.new()
		GameSettings.config = config

	state = GameState.new()
	state.setup(config)

	_create_players()
	_connect_signals()

	hud.setup(config)
	board.build()
	board.set_interactive(false)

	var missing := _unimplemented_pieces()
	if not missing.is_empty():
		hud.show_message("Nothing to play yet.\nImplement %s" % missing[0], 0.0)
		return

	_run_match()


func _create_players() -> void:
	players.clear()

	var first := HumanPlayer.new()
	first.name = "Player1"
	first.setup(0, config.player_names[0], state.mark_for_player(0), config)
	add_child(first)
	players.append(first)

	var second: Player
	if config.opponent == GameConfig.Opponent.BOT:
		second = BotPlayer.new()
		second.name = "Bot"
		(second as BotPlayer).played_at_random.connect(_on_bot_played_at_random)
	else:
		second = HumanPlayer.new()
		second.name = "Player2"
	second.setup(1, config.player_names[1], state.mark_for_player(1), config)
	add_child(second)
	players.append(second)


func _connect_signals() -> void:
	board.cell_clicked.connect(_on_board_cell_clicked)
	state.score_changed.connect(hud.set_score)
	state.turn_changed.connect(_on_turn_changed)
	hud.pause_pressed.connect(_open_pause)
	pause_menu.resume_requested.connect(_close_pause)
	pause_menu.restart_requested.connect(_restart)
	pause_menu.quit_requested.connect(_quit_to_menu)


# ---------------------------------------------------------------- the loop


func _run_match() -> void:
	_running = true
	var starting_player := 0
	var rounds := 0

	while _running and not state.is_match_over() and rounds < ROUND_GUARD:
		rounds += 1
		state.start_round(starting_player)
		board.clear_board()
		hud.set_round(state.round_number, config.rounds_to_win)
		hud.set_turn(state.current_player)

		await _play_round()
		if not _running:
			return

		# The loser opens the next round, so nobody keeps the first-move edge.
		starting_player = state.opponent_of(starting_player)

	if not _running:
		return
	_finish_match()


func _play_round() -> void:
	var moves := 0

	while _running and moves < MOVE_GUARD:
		moves += 1
		var player := players[state.current_player]
		board.set_interactive(player.is_human)
		_refresh_ghost()

		# call_deferred: a bot with think_time 0 would emit picked before the
		# await below is listening, and the turn would hang forever.
		player.request_pick.call_deferred(state)
		var index: int = await player.picked
		if not _running:
			return

		board.set_interactive(false)
		board.show_ghost(-1)

		var result := state.play(index)
		if not result.is_valid():
			hud.show_message("GameState.play() refused cell %d." % index, 0.0)
			return

		await board.place(result.index, result.mark)
		if result.vanished_index >= 0:
			await board.vanish(result.vanished_index)
		if not _running:
			return

		if result.is_win():
			await _win_round(result)
			return
		if result.is_draw:
			await _draw_round()
			return

		hud.set_turn(state.current_player)

	if moves >= MOVE_GUARD:
		push_error("A round ran past %d moves: nothing is ending it." % MOVE_GUARD)


func _win_round(result: MoveResult) -> void:
	# play() does not hand over the turn when the round ends, so the current
	# player is still the one who just won.
	await board.highlight(result.line)
	AudioManager.play_sfx(AudioManager.SFX_ROUND_WON)
	hud.show_message("%s wins the round" % players[state.current_player].display_name, 1.2)
	await get_tree().create_timer(1.5).timeout


func _draw_round() -> void:
	AudioManager.play_sfx(AudioManager.SFX_DRAW)
	hud.show_message("Nobody wins this one", 1.2)
	await get_tree().create_timer(1.5).timeout


func _finish_match() -> void:
	_running = false
	board.set_interactive(false)

	GameSettings.last_result = {
		"scores": state.scores.duplicate(),
		"names": config.player_names,
		"winner": state.match_winner(),
		"rounds_played": state.round_number,
		"seconds": elapsed_seconds,
	}
	AudioManager.play_sfx(AudioManager.SFX_MATCH_WON)
	await get_tree().create_timer(0.6).timeout
	SceneSwitcher.go_to(SceneSwitcher.RESULTS, false)


## Fades the mark the current player is about to lose, if the mode calls for it.
func _refresh_ghost() -> void:
	if not config.infinite_mode or not config.telegraph_vanish:
		board.show_ghost(-1)
		return
	board.show_ghost(state.board.next_to_vanish(state.current_mark()))


# ---------------------------------------------------------------- wiring


func _on_board_cell_clicked(index: int) -> void:
	# Every human hears every click; only the one waiting for a pick answers.
	for player in players:
		if player is HumanPlayer:
			(player as HumanPlayer).on_cell_clicked(index)


func _on_turn_changed(player_index: int) -> void:
	hud.set_turn(player_index)


func _on_bot_played_at_random() -> void:
	hud.show_message("The bot is guessing.\nImplement BotPlayer.choose_move()", 2.5)


func _process(delta: float) -> void:
	if not _running:
		return
	elapsed_seconds += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if pause_menu.visible:
			_close_pause()
		else:
			_open_pause()


func _open_pause() -> void:
	pause_menu.open()


func _close_pause() -> void:
	pause_menu.close()


func _restart() -> void:
	_stop()
	pause_menu.close()
	SceneSwitcher.go_to(SceneSwitcher.GAME, false)


func _quit_to_menu() -> void:
	_stop()
	pause_menu.close()
	SceneSwitcher.go_to(SceneSwitcher.MAIN_MENU, false)


func _stop() -> void:
	_running = false
	for player in players:
		player.cancel_pick()


# ---------------------------------------------------------------- scaffolding


## Pokes the core with harmless questions to work out what is still a stub, so
## the first run says what to write instead of hanging on a board that ignores
## every click. Delete this function once the missions are done.
func _unimplemented_pieces() -> Array[String]:
	var missing: Array[String] = []

	if Mark.opponent(Mark.Value.X) != Mark.Value.O:
		missing.append("Mark.opponent()")

	var probe := BoardState.new(0)
	if probe.free_indices().size() != BoardState.CELL_COUNT:
		missing.append("BoardState.free_indices()")
	elif probe.place(0, Mark.Value.X) != -1 or probe.mark_at(0) != Mark.Value.X:
		missing.append("BoardState.place() / BoardState.mark_at()")

	var scratch := GameState.new()
	scratch.setup(config)
	if not scratch.can_play(0):
		missing.append("GameState.can_play()")
	elif not scratch.play(0).is_valid():
		missing.append("GameState.play()")

	scratch.start_round(1)
	if scratch.round_number < 1 or scratch.current_player != 1 or not scratch.board.is_free(0):
		missing.append("GameState.start_round()")

	if GameRules.all_lines().size() != 8:
		missing.append("GameRules.all_lines()")

	scratch.scores[0] = config.rounds_to_win
	if not scratch.is_match_over():
		missing.append("GameState.is_match_over()")

	return missing
