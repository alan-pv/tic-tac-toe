class_name Cell
extends Button

## One square of the board. It owns nothing and decides nothing: the mark drawn
## here is a copy of what BoardState holds, never a second source of truth.
##
## Everything is animated on %Symbol rather than on the cell itself, because
## ui_sounds.gd already bounces every button on the screen and two tweens
## pulling on the same scale fight each other.


signal clicked(index: int)

const COLOR_X := Color(0, 0.49803922, 0.37254903, 1)
const COLOR_O := Color(0.909804, 0.929412, 0.952941, 1)
const COLOR_GHOST := Color(0.69803923, 0.69803923, 0.69803923, 0.47058824)

const PLACE_TIME := 0.22
const VANISH_TIME := 0.28
const WIN_TIME := 0.18

@onready var _symbol: Label = %Symbol

var index: int = -1

var mark: int = Mark.Value.NONE

## True while this mark is the next one to disappear in infinite mode.
var is_ghost: bool = false

var _anim: Tween


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


## The mark landing. Awaited by the board, so it delays the rest of the turn.
func play_place() -> void:
	if _symbol == null:
		return
	_start_anim()
	_symbol.scale = Vector2.ZERO
	_symbol.rotation_degrees = -25.0
	_anim.set_parallel(true)
	_anim.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim.tween_property(_symbol, "scale", Vector2.ONE, PLACE_TIME)
	_anim.tween_property(_symbol, "rotation_degrees", 0.0, PLACE_TIME)
	await _anim.finished


## The mark being pushed off the board in infinite mode. The board empties the
## cell as soon as this returns, so the disappearance has to be readable: it is
## the whole point of the mode and the player has to see whose mark went.
func play_vanish() -> void:
	if _symbol == null:
		return
	_start_anim()
	_anim.set_parallel(true)
	_anim.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_anim.tween_property(_symbol, "scale", Vector2.ZERO, VANISH_TIME)
	_anim.tween_property(_symbol, "rotation_degrees", 35.0, VANISH_TIME)
	_anim.tween_property(_symbol, "modulate:a", 0.0, VANISH_TIME)
	await _anim.finished
	_reset_symbol()


## This cell is part of the line that just won the round. Called on all three at
## once; only the last one is awaited.
func play_win() -> void:
	if _symbol == null:
		return
	_start_anim()
	_anim.set_trans(Tween.TRANS_SINE)
	_anim.tween_property(_symbol, "scale", Vector2(1.35, 1.35), WIN_TIME)
	_anim.tween_property(_symbol, "scale", Vector2.ONE, WIN_TIME)
	await _anim.finished


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


## One tween at a time, around the middle of the symbol. Left at zero the pivot
## would grow the mark out of its own top left corner.
func _start_anim() -> void:
	if _anim != null and _anim.is_valid():
		_anim.kill()
	_reset_symbol()
	_symbol.pivot_offset = _symbol.size * 0.5
	_anim = create_tween()


func _reset_symbol() -> void:
	_symbol.scale = Vector2.ONE
	_symbol.rotation_degrees = 0.0
	_symbol.modulate.a = 1.0
