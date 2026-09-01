class_name Board
extends AspectRatioContainer

## The board on screen: nine cells, and the translation from cell numbers into
## things you can watch. It knows nothing about turns, rules or scores.


signal cell_clicked(index: int)

@export var cell_scene: PackedScene

@onready var _grid: GridContainer = %Grid

var _cells: Array[Cell] = []
var _ghost_index: int = -1


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
	_ghost_index = -1
	for cell in _cells:
		cell.set_ghost(false)
		cell.set_mark(Mark.Value.NONE)


func clear_cells() -> void:
	for cell in _cells:
		cell.queue_free()
	_cells.clear()
	_ghost_index = -1


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
	cell.set_ghost(false)
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
	cell.set_ghost(false)
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


## Fades the mark the current player is about to lose. Pass -1 for none.
func show_ghost(index: int) -> void:
	if _ghost_index == index:
		return
	var previous := get_cell(_ghost_index)
	if previous != null:
		previous.set_ghost(false)
	_ghost_index = index
	var next := get_cell(index)
	if next != null:
		next.set_ghost(true)


func _on_cell_clicked(index: int) -> void:
	cell_clicked.emit(index)
