class_name Mark
extends RefCounted

## The three things a cell can hold.
##
## Everything in the core moves marks around as plain ints taken from
## Mark.Value. There is no Mark instance anywhere: this class exists only to
## give those ints a name and two helpers.


enum Value {
	NONE, ## An empty cell.
	X,
	O,
}


## Gives back the rival of a mark.
##
## WHAT IT SHOULD DO:
##   if the mark is X, answer O
##   if the mark is O, answer X
##   anything else has no rival: answer NONE
##
## This is the only place in the whole project that knows the two marks take
## turns. Get it wrong and the turn order breaks everywhere at once, which will
## look like a bug in game.gd instead of a bug here. tests/test_mark.gd covers it.
static func opponent(mark: int) -> int:
	# TODO(you)
	return Value.NONE


## The text a cell shows for a mark. Presentation only, already done.
static func to_symbol(mark: int) -> String:
	match mark:
		Value.X:
			return "X"
		Value.O:
			return "O"
		_:
			return ""


## Handy in error messages and in the board's _to_string().
static func to_debug_char(mark: int) -> String:
	var symbol := to_symbol(mark)
	return symbol if symbol != "" else "."
