class_name GameConfig
extends Resource

## The settings of a match and their validation.
##
## Built by the setup screen, parked in GameSettings, read by game.gd. It is a
## Resource, so it can also be saved as a .tres and edited in the inspector.


enum Opponent {
	BOT,   ## One human against the machine.
	HUMAN, ## Two people on the same device, taking turns.
}

@export var opponent: Opponent = Opponent.BOT

@export var player_names: PackedStringArray = PackedStringArray(["You", "Bot"])

@export_group("The twist")

## When true the board never fills up: placing your (max + 1)th mark removes
## your oldest one.
@export var infinite_mode: bool = false

## How many marks one player may have on the board at once in infinite mode.
@export_range(2, 4, 1) var max_marks_per_player: int = 3

## Fade the mark that is about to disappear, so the player can see it coming.
@export var telegraph_vanish: bool = true

@export_group("Match")

## Rounds a player must win to take the match.
@export_range(1, 9, 1) var rounds_to_win: int = 3

@export_group("Bot")

@export var difficulty_id: StringName = &"sharp"

## Seconds the bot pretends to think before playing.
@export_range(0.0, 2.0, 0.05) var bot_think_time: float = 0.45

## 0.0 plays at random, 1.0 plays perfectly. It is up to BotPlayer to honour it.
@export_range(0.0, 1.0, 0.05) var bot_skill: float = 0.8


## How many marks each player may keep on the board.
## 0 means "no limit": the classic game.
func max_marks() -> int:
	return max_marks_per_player if infinite_mode else 0


func is_valid() -> bool:
	return validation_error() == ""


func validation_error() -> String:
	if player_names.size() != 2:
		return "A match needs exactly two players."
	if rounds_to_win < 1:
		return "A match must be at least one round long."
	if infinite_mode:
		if max_marks_per_player < 2:
			return "With fewer than two marks each nobody could ever line up three."
		if max_marks_per_player * 2 >= BoardState.CELL_COUNT:
			return "Too many marks allowed: the board could fill up and infinite mode would stall."
	return ""


func clone() -> GameConfig:
	return duplicate(true) as GameConfig


func _to_string() -> String:
	var mode := "infinite(%d)" % max_marks_per_player if infinite_mode else "classic"
	return "GameConfig(%s, %s, first to %d)" % [
		"vs bot" if opponent == Opponent.BOT else "hotseat", mode, rounds_to_win
	]
