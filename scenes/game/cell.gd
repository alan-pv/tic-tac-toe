class_name Cell
extends Button

## One square of the board. It owns nothing and decides nothing: the mark drawn
## here is a copy of what BoardState holds, never a second source of truth.
##
## Three things move independently, so they each get their own channel and never
## fight over one another:
##
##   self_modulate     how lit the square is, which is how a turn is announced
##   %Symbol           the mark landing, leaving or winning
##   %Symbol's alpha   how close that mark is to being pushed off the board


signal clicked(index: int)

const COLOR_X := Color(0, 0.49803922, 0.37254903, 1)
const COLOR_O := Color(0.909804, 0.929412, 0.952941, 1)

## The winning line, and the square under it.
const COLOR_WIN := Color(0.24, 0.78, 0.44, 1)
const COLOR_WIN_BOX := Color(0.09, 0.24, 0.16, 1)

## How faint the mark about to be pushed off the board gets. It never reaches
## zero: a mark you cannot see is a mark you cannot plan around.
const FADE_FLOOR := 0.3

## How lit a square that cannot be clicked is. Dark enough to read as "not your
## turn", far from the background colour, so the board never goes anywhere.
const DIM := Color(0.55, 0.55, 0.55, 1)

const PLACE_TIME := 0.22
const VANISH_TIME := 0.28
const WIN_TIME := 0.18
const FADE_TIME := 0.25
const DIM_TIME := 0.2

@onready var _symbol: Label = %Symbol

var index: int = -1

var mark: int = Mark.Value.NONE

## 1.0 is a mark in no danger, FADE_FLOOR one that goes on its owner's next move.
var fade: float = 1.0

## The square's own box, so the win can tint it and the disabled state can stop
## being invisible.
var _box: StyleBoxFlat
var _box_bg: Color
var _box_border: Color

var _anim: Tween
var _fade_tween: Tween
var _dim_tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func() -> void: clicked.emit(index))
	_adopt_box()
	_refresh()


func setup(p_index: int) -> void:
	index = p_index


func set_mark(new_mark: int) -> void:
	mark = new_mark
	if mark == Mark.Value.NONE:
		set_fade(1.0, false)
	_refresh()


## How close this mark is to being pushed off the board, as 1.0 down to 0.0.
func set_fade(value: float, animate: bool = true) -> void:
	var target := lerpf(FADE_FLOOR, 1.0, clampf(value, 0.0, 1.0))
	if is_equal_approx(fade, target):
		return
	fade = target
	if _symbol == null:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if not animate:
		_symbol.self_modulate.a = fade
		return
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.tween_property(_symbol, "self_modulate:a", fade, FADE_TIME)


## Whose turn it is, said by lighting the square rather than by removing it.
func set_interactive(value: bool) -> void:
	var was_interactive := not disabled
	if was_interactive == value:
		return
	disabled = not value
	_light(Color.WHITE if value else DIM)


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


## This cell is part of the line that just won the round: it goes green and it
## stays green until the next round clears the board. Called on all three at
## once; only the last one is awaited.
func play_win() -> void:
	if _symbol == null:
		return
	# The board stopped taking clicks a moment ago and every square went dim.
	# The line that just won is the one thing worth looking at, so it comes back
	# up to full, at full strength, however close to leaving the marks were.
	_light(Color.WHITE)
	set_fade(1.0)
	_start_anim()
	_anim.set_trans(Tween.TRANS_SINE)
	_anim.tween_method(_paint_win, 0.0, 1.0, WIN_TIME)
	_anim.parallel().tween_property(_symbol, "scale", Vector2(1.3, 1.3), WIN_TIME)
	_anim.tween_property(_symbol, "scale", Vector2.ONE, WIN_TIME)
	await _anim.finished


## How lit the square is, on a tween of its own so it never fights the mark's.
## self_modulate and not modulate: this is the square, not what is drawn on it.
func _light(target: Color) -> void:
	if _dim_tween != null and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = create_tween()
	_dim_tween.set_trans(Tween.TRANS_SINE)
	_dim_tween.tween_property(self, "self_modulate", target, DIM_TIME)


## The theme paints a disabled button in the background colour, which would make
## every square vanish the moment the board stopped taking clicks. The square
## keeps its own box instead, and wears it disabled or not.
func _adopt_box() -> void:
	var themed := get_theme_stylebox("normal") as StyleBoxFlat
	if themed == null:
		return
	_box = themed.duplicate() as StyleBoxFlat
	_box_bg = _box.bg_color
	_box_border = _box.border_color
	add_theme_stylebox_override("normal", _box)
	add_theme_stylebox_override("disabled", _box)


func _refresh() -> void:
	# @onready vars do not exist until the node is inside the tree, and setup()
	# may well arrive first. Bail out quietly instead of crashing on Nil.
	if _symbol == null:
		return
	_symbol.text = Mark.to_symbol(mark)
	_paint_win(0.0)


## Somewhere between the mark's own colour and the winning green.
func _paint_win(amount: float) -> void:
	var base := COLOR_X if mark == Mark.Value.X else COLOR_O
	_symbol.add_theme_color_override("font_color", base.lerp(COLOR_WIN, amount))
	if _box == null:
		return
	_box.bg_color = _box_bg.lerp(COLOR_WIN_BOX, amount)
	_box.border_color = _box_border.lerp(COLOR_WIN, amount)


## One animation at a time, around the middle of the symbol. Left at zero the
## pivot would grow the mark out of its own top left corner.
func _start_anim() -> void:
	if _anim != null and _anim.is_valid():
		_anim.kill()
	_reset_symbol()
	_symbol.pivot_offset = _symbol.size * 0.5
	_anim = create_tween()


## Undoes the animation channel only. How faded the mark is belongs to
## set_fade(), and survives.
func _reset_symbol() -> void:
	_symbol.scale = Vector2.ONE
	_symbol.rotation_degrees = 0.0
	_symbol.modulate.a = 1.0
