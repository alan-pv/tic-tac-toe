class_name Board
extends AspectRatioContainer

## The board on screen: nine cells, and the translation from cell numbers into
## things you can watch. It knows nothing about turns, rules or scores.


signal cell_clicked(index: int)

@export var cell_scene: PackedScene

@onready var _grid: GridContainer = %Grid

var _cells: Array[Cell] = []


func build() -> void:
	clear_cells()
	if cell_scene == null:
		push_error("Board: cell_scene is not assigned in the inspector.")
		return

	_grid.columns = BoardState.SIZE
	for i in BoardState.CELL_COUNT:
		var cell := cell_scene.instantiate() as Cell
		cell.clicked.connect(_on_cell_clicked)
		# add_child BEFORE setup: @onready vars do not exist until the node is
		# in the tree, and setup() touches them.
		_grid.add_child(cell)
		cell.setup(i)
		_cells.append(cell)


## Wipes every mark without rebuilding the nodes. Called between rounds.
func clear_board() -> void:
	for cell in _cells:
		cell.set_mark(Mark.Value.NONE)


func clear_cells() -> void:
	for cell in _cells:
		cell.queue_free()
	_cells.clear()


func get_cell(index: int) -> Cell:
	if index < 0 or index >= _cells.size():
		return null
	return _cells[index]


func set_interactive(value: bool) -> void:
	for cell in _cells:
		cell.set_interactive(value)


## Shows a mark landing. Awaited: the turn does not go on until it is done.
func place(index: int, mark: int) -> void:
	var cell := get_cell(index)
	if cell == null:
		push_warning("Board: nothing to place at index %d." % index)
		return
	cell.set_mark(mark)
	AudioManager.play_sfx(AudioManager.SFX_PLACE)
	await cell.play_place()


## Shows a mark being pushed off the board, then empties the cell.
func vanish(index: int) -> void:
	var cell := get_cell(index)
	if cell == null:
		return
	AudioManager.play_sfx(AudioManager.SFX_VANISH)
	await cell.play_vanish()
	cell.set_mark(Mark.Value.NONE)


## Lights up the three cells that won the round. They all start together and
## only the last one is awaited, so the line reads as one gesture.
func highlight(line: PackedInt32Array) -> void:
	if line.is_empty():
		return
	for i in line.size():
		var cell := get_cell(line[i])
		if cell == null:
			continue
		if i == line.size() - 1:
			await cell.play_win()
		else:
			cell.play_win()


## Fades every mark by how soon its owner will push it off the board: the one
## going next is faintest, the one just played is untouched. Pass false to leave
## the whole board at full strength.
func show_lifetimes(state_board: BoardState, enabled: bool) -> void:
	var limit := state_board.max_marks_per_player
	for i in _cells.size():
		if not enabled or limit < 2:
			_cells[i].set_fade(1.0)
			continue
		var remaining := state_board.moves_until_vanish(i)
		# The scale runs from the mark that goes next to the one with a full
		# quota ahead of it, so a two mark limit still reads as two steps.
		_cells[i].set_fade(1.0 if remaining == 0 else float(remaining - 1) / float(limit - 1))


func _on_cell_clicked(index: int) -> void:
	cell_clicked.emit(index)
