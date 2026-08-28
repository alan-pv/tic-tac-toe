class_name Cell
extends Button

## One square of the board.
##
## It owns nothing and decides nothing: it is told what to show. The mark drawn
## here is a copy of what BoardState holds, never a second source of truth.


signal clicked(index: int)

const COLOR_X := Color(0, 0.49803922, 0.37254903, 1)                   ## #007F5F
const COLOR_O := Color(0.909804, 0.929412, 0.952941, 1)                ## near white
const COLOR_GHOST := Color(0.69803923, 0.69803923, 0.69803923, 0.47058824)  ## #b2b2b278

@onready var _symbol: Label = %Symbol

var index: int = -1

var mark: int = Mark.Value.NONE

## True while this mark is the next one to disappear in infinite mode.
var is_ghost: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func() -> void: clicked.emit(index))
	_refresh()


func setup(p_index: int) -> void:
	index = p_index


func set_mark(new_mark: int) -> void:
	mark = new_mark
	_refresh()


func set_ghost(value: bool) -> void:
	if is_ghost == value:
		return
	is_ghost = value
	_refresh()


func set_interactive(value: bool) -> void:
	disabled = not value


func _refresh() -> void:
	# @onready vars do not exist until the node is inside the tree, and setup()
	# may well arrive first. Bail out quietly instead of crashing on Nil.
	if _symbol == null:
		return
	_symbol.text = Mark.to_symbol(mark)
	_symbol.add_theme_color_override("font_color", _color_for_state())


func _color_for_state() -> Color:
	if is_ghost:
		return COLOR_GHOST
	return COLOR_X if mark == Mark.Value.X else COLOR_O


# ---------------------------------------------------------------- your work


## The mark landing. Called right after set_mark(), and awaited by the board, so
## whatever happens here delays the rest of the turn.
##
##   the symbol is already on screen and already the right colour
##   make it arrive: grow it out of nothing, drop it in, spin it a quarter turn
##   wait for your own animation before returning, or nobody else will wait either
##
## Until you write this, the editor will warn REDUNDANT_AWAIT on the call in
## board.gd: awaiting something that never pauses. The warning is correct, it is
## harmless, and it goes away by itself the moment there is a tween here.
##
## Animate %Symbol, not the cell itself: ui_sounds.gd already bounces every
## button on the screen, and two tweens pulling on the same scale property fight
## each other in ways that look like a physics bug.
##
## Godot you may not know yet:
##   create_tween()                       a tween owned by this node, dies with it
##   Tween.tween_property(obj, "property", final_value, seconds)
##   Tween.set_trans(Tween.TRANS_BACK)    the overshoot that makes things pop
##   Tween.set_ease(Tween.EASE_OUT)
##   Tween.set_parallel(true)             everything after this runs at once
##   await tween.finished
##   Control.pivot_offset                 scaling and rotation happen around this
##                                        point. Leave it at zero and the mark
##                                        grows out of its top-left corner
func play_place() -> void:
	# TODO(you)
	pass


## The mark being pushed off the board in infinite mode. The board empties the
## cell as soon as this returns, so make the disappearance readable: this is the
## whole point of the mode and the player has to see whose mark went and why.
func play_vanish() -> void:
	# TODO(you)
	pass


## This cell is part of the line that just won the round. Called on all three at
## once; only the last one is awaited.
func play_win() -> void:
	# TODO(you)
	pass
