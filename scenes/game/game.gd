extends Control

## Match coordinator: builds everything, wires it together, and drives the loop.
##
## The shape of a turn, end to end:
##
##   game.gd asks the player for a cell   -> player.request_pick(state)
##   the player answers                   -> await player.picked
##   the rules are applied                -> state.play(index) -> MoveResult
##   the result is animated               -> await board.place() / board.vanish()
##   the round ends, or the turn passes
##
## Online it is the identical loop: a NetPlayer answers picked() with a cell the
## referee confirmed instead of one it chose, and nothing else changes.


const ROUND_GUARD := 99
const MOVE_GUARD := BoardState.CELL_COUNT * 6

@onready var board: Board = %Board
@onready var hud: HUD = %HUD
@onready var pause_menu: PauseMenu = %PauseMenu

var config: GameConfig
var state: GameState
var players: Array[Player] = []

## Only exists in an online match. When it is null this file behaves exactly as
## it did before the network existed.
var online: OnlineMatch = null

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

	if config.online:
		_create_online()

	_create_players()
	_connect_signals()

	if online != null:
		online.bind_state(state, players)

	hud.setup(config)
	board.build()
	board.set_interactive(false)

	_run_match()


## Sets the network side up before the seats exist, so they can ask it who they
## belong to. The room it reads was left there by the lobby.
func _create_online() -> void:
	online = OnlineMatch.new()
	online.name = "OnlineMatch"
	add_child(online)
	online.prepare(config)
	online.message.connect(_on_online_message)
	online.aborted.connect(_on_online_aborted)
	pause_menu.set_online(true)
	# Folded away to start with: the board is what the screen is for, and the
	# dot on the bar is enough to say something was said.
	RoomChat.spawn(self, false)


func _create_players() -> void:
	players.clear()

	for i in GameConfig.PLAYER_COUNT:
		var player := _player_for_seat(i)
		player.name = "Seat%d" % i
		player.setup(i, config.player_names[i], state.mark_for_player(i), config)
		add_child(player)
		if player is NetPlayer:
			(player as NetPlayer).attach(online, online.owns_seat(i), online.referees_seat(i))
		players.append(player)


## Online, both seats are a NetPlayer on both clients: yours and theirs alike.
## They wait for the same confirms, so every client runs the identical loop.
func _player_for_seat(index: int) -> Player:
	if config.online:
		return NetPlayer.new()
	if index == 1 and config.opponent == GameConfig.Opponent.BOT:
		return BotPlayer.new()
	return HumanPlayer.new()


func _connect_signals() -> void:
	board.cell_clicked.connect(_on_board_cell_clicked)
	state.score_changed.connect(hud.set_score)
	state.turn_changed.connect(hud.set_turn)
	hud.pause_pressed.connect(_open_pause)
	pause_menu.resume_requested.connect(_close_pause)
	pause_menu.restart_requested.connect(_restart)
	pause_menu.quit_requested.connect(_quit_to_menu)


# ---------------------------------------------------------------- the loop


func _run_match() -> void:
	_running = true

	if online != null:
		hud.show_message("Waiting for everyone...", 0.0)
		await online.wait_for_everyone()
		if not _running:
			return
		hud.show_message("", 0.0)

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

		# They take turns opening, so nobody keeps the first-move advantage.
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
			push_error("GameState.play() refused cell %d." % index)
			return

		await board.place(result.index, result.mark)
		if result.vanished_index >= 0:
			await board.vanish(result.vanished_index)
		if not _running:
			return

		# The move is on every board now, so the next one can be asked for.
		if online != null:
			online.end_turn()

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
	if online != null:
		online.finish()

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
	# Every player hears every click; only the one waiting for a move answers.
	for player in players:
		player.on_cell_clicked(index)


func _on_online_message(text: String) -> void:
	hud.show_message(text, 2.0)


## The referee left, or the connection died. There is no rules engine any more,
## so the match stops here instead of drifting out of sync in silence.
func _on_online_aborted(reason: String) -> void:
	if not _running:
		return
	_stop()
	board.set_interactive(false)
	hud.show_message(reason, 0.0)
	await get_tree().create_timer(2.5).timeout
	SceneSwitcher.go_to(SceneSwitcher.MAIN_MENU, false)


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
	if online != null:
		Rooms.leave()
	SceneSwitcher.go_to(SceneSwitcher.MAIN_MENU, false)


func _stop() -> void:
	_running = false
	for player in players:
		player.cancel_pick()
