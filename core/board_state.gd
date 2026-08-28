class_name BoardState
extends RefCounted

## The 3x3 grid, plus the order in which each player placed their marks.
##
## Pure data: no signals, no nodes, nothing to await. The bot will clone this
## object many times per turn while it looks ahead, so it stays cheap on purpose.
##
## Cells are numbered left to right, top to bottom:
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

## 0 means classic rules: marks stay on the board forever.
## Anything else is the infinite mode limit for each player.
var max_marks_per_player: int = 0

## The cells each mark occupies, oldest placement first. Two plain arrays and
## not one Dictionary keyed by mark: a Dictionary stores Variant and would hand
## these back as untyped Arrays, which is one of the traps in WORKING-METHOD.md.
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


## The list of cells a mark occupies, oldest first.
##
## This hands back the REAL array, not a copy: appending to what you get here
## appends to the board. That is deliberate, place() needs it. Call
## Array.duplicate() yourself if you want a snapshot that will not move.
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


# ---------------------------------------------------------------- your work


## What is sitting in a cell.
##
## WHAT IT SHOULD DO:
##   if the index is outside the board: answer NONE
##   otherwise: answer whatever `cells` holds there
##
## Never let this crash. The bot explores the board by asking about indices it
## computed, and an out-of-range read here would take the whole match down
## instead of just pruning a branch.
func mark_at(index: int) -> int:
	# TODO(you)
	return Mark.Value.NONE


## True when a mark can still be placed in that cell.
##
##   the cell has to be inside the board, and it has to hold NONE
func is_free(index: int) -> bool:
	# TODO(you)
	return false


## Every cell that can still be played, in board order.
##
##   walk every cell, first to last
##   keep the ones that are free
##
## Mind the loop bounds: `for i in CELL_COUNT` walks 0..8, which is what you
## want here, while `range(1, CELL_COUNT)` would quietly skip the top-left
## corner and the bot would never play there.
func free_indices() -> Array[int]:
	# TODO(you)
	return []


## Puts a mark on the board.
## Answers the cell that had to be emptied to make room, or -1 if none was.
##
## WHAT IT SHOULD DO:
##   if the cell is not free: warn and answer -1, changing nothing
##
##   get the placement order of that mark (order_for gives you the live array,
##   so appending to it really does update the board)
##
##   if there is a limit and this player has already reached it:
##       their oldest mark is the one that has been in that list the longest
##       drop it from the list, empty its cell, and remember which cell it was
##
##   write the mark into the cell, and append the cell to the end of the list
##   answer the emptied cell, or -1 if nothing was emptied
##
## The trap: evict BEFORE placing. If you place first and evict afterwards, a
## player sitting at the limit evicts the mark they just played, and a piece
## vanishes from the board with no explanation. This is the single most likely
## bug in the whole project, and tests/test_board_state.gd aims straight at it.
##
## Godot you may not know yet:
##   Array.pop_front()    removes and returns the FIRST element
##   Array.pop_back()     removes and returns the LAST element
##   Array.is_empty()     true when it has no elements
##   push_warning(text)   yellow message in Output, does NOT stop execution
func place(index: int, mark: int) -> int:
	# TODO(you)
	return -1


## Which cell of that player will be emptied by their NEXT move, or -1 if their
## next move will not empty anything. The board fades that mark as a warning,
## so it must not change the board in any way.
##
##   with no limit, nothing ever vanishes
##   if the player is still below the limit, nothing vanishes yet either
##   otherwise it is their oldest mark
func next_to_vanish(mark: int) -> int:
	# TODO(you)
	return -1


## True when there is nowhere left to play.
##
##   the board is full when not a single cell is free
##
## In infinite mode this should never become true: that is exactly why
## GameConfig refuses limits that would let both players fill the board.
func is_full() -> bool:
	# TODO(you)
	return false


# ---------------------------------------------------------------- plumbing


## An independent copy. The bot needs this to try a move without touching the
## real board: clone, place, look at the result, throw the clone away.
func clone() -> BoardState:
	var copy := BoardState.new(max_marks_per_player)
	copy.cells = cells.duplicate()
	copy._order_x = _order_x.duplicate()
	copy._order_o = _order_o.duplicate()
	return copy


## Prints the board as three lines of text. Invaluable when a test fails.
func _to_string() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for row in SIZE:
		var cells_in_row: PackedStringArray = PackedStringArray()
		for column in SIZE:
			cells_in_row.append(Mark.to_debug_char(cells[index_of(row, column)]))
		lines.append(" ".join(cells_in_row))
	return "\n".join(lines)
