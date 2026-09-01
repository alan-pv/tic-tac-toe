class_name Mark
extends RefCounted

## The three things a cell can hold, as plain ints with a name.


enum Value {
	NONE, ## An empty cell.
	X,
	O,
}


## The rival of a mark, or NONE for anything that has no rival.
static func opponent(mark: int) -> int:
	if mark == Value.X:
		return Value.O
	if mark == Value.O:
		return Value.X
	return Value.NONE


## The text a cell shows for a mark.
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
