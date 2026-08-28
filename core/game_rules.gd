class_name GameRules
extends RefCounted

## The rulebook: which cells win and when a round is dead.
##
## Everything here is static and pure. It never stores anything, never touches a
## node, and only ever reads a BoardState. That is what makes it testable from
## tests/ without opening a single scene.


## Every line that wins a round: the rows, the columns and the two diagonals.
## Eight of them on a 3x3 board.
##
## WHAT IT SHOULD DO:
##   start with an empty list of lines
##   for each row, first to last:
##       collect the cells of that row, left to right, and add them as one line
##   for each column, first to last:
##       collect the cells of that column, top to bottom, and add them as one line
##   add the diagonal that runs from the top-left corner to the bottom-right one
##   add the diagonal that runs from the top-right corner to the bottom-left one
##   answer the list
##
## BoardState.index_of(row, column) turns a pair into a cell number, so you never
## have to type the eight lines out by hand. On the first diagonal the row and the
## column are equal; on the second one they add up to SIZE - 1.
##
## Mind the loop bounds: `for row in BoardState.SIZE` walks 0, 1, 2. If a test
## reports 7 or 9 lines instead of 8, the diagonals are where to look.
##
## Godot you may not know yet:
##   PackedInt32Array([a, b, c])   a compact, cheap array of ints
##   Array.append(x)               adds one element at the end
##   static var                    a variable that belongs to the class instead
##                                 of an instance. If you would rather build the
##                                 eight lines once and reuse them forever, this
##                                 is the tool for it.
static func all_lines() -> Array[PackedInt32Array]:
	# TODO(you)
	return []


## The line that `mark` has completed, or an empty array if it has not.
##
## WHAT IT SHOULD DO:
##   for every line the rulebook knows:
##       if all of its cells hold `mark`: answer that line
##   answer an empty array
##
## Answer the line and not just true/false: the board needs those three cells to
## light them up, and the bot needs to tell a win from a loss, not just spot one.
##
## Godot you may not know yet:
##   PackedInt32Array()          an empty one
##   Array.is_empty()            true when there is nothing in it
static func winning_line(board: BoardState, mark: int) -> PackedInt32Array:
	# TODO(you)
	return PackedInt32Array()


## True when the board is full and nobody owns a line.
##
##   there has to be nowhere left to play, and no winner
##
## In infinite mode this never happens, and that is the point of the mode.
static func is_draw(board: BoardState) -> bool:
	# TODO(you)
	return false


# ---------------------------------------------------------------- plumbing


## Whoever owns a line right now, or NONE. Built on winning_line(), so it starts
## working the moment that one does.
static func winner(board: BoardState) -> int:
	if not winning_line(board, Mark.Value.X).is_empty():
		return Mark.Value.X
	if not winning_line(board, Mark.Value.O).is_empty():
		return Mark.Value.O
	return Mark.Value.NONE


## True when nothing more can happen in this round.
static func is_round_over(board: BoardState) -> bool:
	return winner(board) != Mark.Value.NONE or is_draw(board)
