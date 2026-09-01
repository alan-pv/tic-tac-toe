class_name BoardState
extends RefCounted

## The 3x3 grid, plus the order in which each player placed their marks.
##
## Pure data, and cheap on purpose: the bot clones it many times per turn.
##
##     0 | 1 | 2
##    ---+---+---
##     3 | 4 | 5
##    ---+---+---
##     6 | 7 | 8


const SIZE := 3
const CELL_COUNT := 9

## One Mark.Value per cell, CELL_COUNT of them.
var cells: Array[int] = []

## 0 means classic rules: marks stay on the board forever. Anything else is the
## infinite mode limit for each player.
var max_marks_per_player: int = 0

var _order_x: Array[int] = []
var _order_o: Array[int] = []


func _init(p_max_marks_per_player: int = 0) -> void:
	max_marks_per_player = p_max_marks_per_player
	reset()


## Empties the board and forgets every placement order.
func reset() -> void:
	cells.resize(CELL_COUNT)
	cells.fill(Mark.Value.NONE)
	_order_x.clear()
	_order_o.clear()


## The cells a mark occupies, oldest first. This is the live array, not a copy:
## place() appends to it. Duplicate it yourself for a snapshot.
func order_for(mark: int) -> Array[int]:
	return _order_x if mark == Mark.Value.X else _order_o


static func is_inside(index: int) -> bool:
	return index >= 0 and index < CELL_COUNT


static func index_of(row: int, column: int) -> int:
	return row * SIZE + column


static func row_of(index: int) -> int:
	return index / SIZE


static func column_of(index: int) -> int:
	return index % SIZE


## What is sitting in a cell. Never crashes: the bot reads indices it computed.
func mark_at(index: int) -> int:
	return cells[index] if is_inside(index) else Mark.Value.NONE


func is_free(index: int) -> bool:
	return is_inside(index) and cells[index] == Mark.Value.NONE


func free_indices() -> Array[int]:
	var free: Array[int] = []
	for i in CELL_COUNT:
		if is_free(i):
			free.append(i)
	return free


## Puts a mark on the board and answers the cell that had to be emptied to make
## room, or -1 if none was.
##
## The eviction happens before the placement: the other way round, a player
## sitting at the limit would evict the mark they just played.
func place(index: int, mark: int) -> int:
	if not is_free(index):
		push_warning("BoardState: cell %d is not free." % index)
		return -1

	var order := order_for(mark)
	var vanished := -1

	if max_marks_per_player != 0 and order.size() >= max_marks_per_player:
		vanished = order.pop_front()
		cells[vanished] = Mark.Value.NONE

	cells[index] = mark
	order.append(index)
	return vanished


## Which cell of that player their NEXT move will empty, or -1. The board fades
## that mark as a warning, so this must not change anything.
func next_to_vanish(mark: int) -> int:
	var order := order_for(mark)
	if max_marks_per_player != 0 and order.size() >= max_marks_per_player:
		return order[0]
	return -1


func is_full() -> bool:
	return free_indices().is_empty()


## An independent copy, for the bot to try a move on.
func clone() -> BoardState:
	var copy := BoardState.new(max_marks_per_player)
	copy.cells = cells.duplicate()
	copy._order_x = _order_x.duplicate()
	copy._order_o = _order_o.duplicate()
	return copy


func _to_string() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for row in SIZE:
		var cells_in_row: PackedStringArray = PackedStringArray()
		for column in SIZE:
			cells_in_row.append(Mark.to_debug_char(cells[index_of(row, column)]))
		lines.append(" ".join(cells_in_row))
	return "\n".join(lines)
