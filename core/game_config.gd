class_name GameConfig
extends Resource

## The settings of a match and their validation.
##
## Built by the setup screen or by the room lobby, parked in GameSettings, read
## by game.gd. It is a Resource, so it can also be edited in the inspector.


const PLAYER_COUNT := 2

## Long enough for any name the lobby lets somebody type.
const MAX_NAME_LENGTH := 16

enum Opponent {
	BOT,   ## One human against the machine.
	HUMAN, ## Two people, on the same device or on two of them.
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

@export var difficulty_id: StringName = &"normal"

## Seconds the bot pretends to think before playing.
@export_range(0.0, 2.0, 0.05) var bot_think_time: float = 0.45

## 0.0 plays at random, 1.0 plays as well as it can.
@export_range(0.0, 1.0, 0.05) var bot_skill: float = 0.8

@export_group("Online")

## True once the match is driven by the network. Read by game.gd to decide
## where moves come from; nothing in core/ cares.
@export var online: bool = false

## Which device owns each seat. All zeros offline. A seat owned by the referee
## while the match is online is a seat a bot took over.
@export var peer_ids: PackedInt32Array = PackedInt32Array([0, 0])


## How many marks each player may keep on the board. 0 means the classic game.
func max_marks() -> int:
	return max_marks_per_player if infinite_mode else 0


func owner_of(player_index: int) -> int:
	if player_index < 0 or player_index >= peer_ids.size():
		return 0
	return peer_ids[player_index]


func is_valid() -> bool:
	return validation_error() == ""


func validation_error() -> String:
	if player_names.size() != PLAYER_COUNT:
		return "A match needs exactly two players."
	if rounds_to_win < 1:
		return "A match must be at least one round long."
	if infinite_mode:
		if max_marks_per_player < 2:
			return "With fewer than two marks each nobody could ever line up three."
		if max_marks_per_player * PLAYER_COUNT >= BoardState.CELL_COUNT:
			return "Too many marks allowed: the board could fill up and infinite mode would stall."
	return ""


func clone() -> GameConfig:
	return duplicate(true) as GameConfig


func to_dict() -> Dictionary:
	return {
		"names": Array(player_names),
		"infinite": infinite_mode,
		"marks": max_marks_per_player,
		"telegraph": telegraph_vanish,
		"rounds": rounds_to_win,
		"skill": bot_skill,
		"think": bot_think_time,
		"peers": Array(peer_ids),
	}


## Rebuilds a config from the wire. Every field arrives from another client, so
## every one of them is clamped into a range this build can actually play.
static func from_dict(data: Dictionary) -> GameConfig:
	var config := GameConfig.new()
	config.opponent = Opponent.HUMAN
	config.online = true

	var names := PackedStringArray()
	for entry in Array(data.get("names", [])).slice(0, PLAYER_COUNT):
		names.append(str(entry).substr(0, MAX_NAME_LENGTH))
	while names.size() < PLAYER_COUNT:
		names.append("Player %d" % (names.size() + 1))
	config.player_names = names

	config.infinite_mode = bool(data.get("infinite", false))
	config.max_marks_per_player = clampi(int(data.get("marks", 3)), 2, 4)
	config.telegraph_vanish = bool(data.get("telegraph", true))
	config.rounds_to_win = clampi(int(data.get("rounds", 3)), 1, 9)
	config.bot_skill = clampf(float(data.get("skill", 0.8)), 0.0, 1.0)
	config.bot_think_time = clampf(float(data.get("think", 0.45)), 0.0, 2.0)

	var peers := PackedInt32Array()
	for entry in Array(data.get("peers", [])).slice(0, PLAYER_COUNT):
		peers.append(int(entry))
	while peers.size() < PLAYER_COUNT:
		peers.append(0)
	config.peer_ids = peers

	return config


func _to_string() -> String:
	var mode := "classic"
	if infinite_mode:
		mode = "infinite(%d marks each)" % max_marks_per_player
	var rival := "vs bot" if opponent == Opponent.BOT else "two players"
	return "GameConfig(%s, %s, first to %d)" % [rival, mode, rounds_to_win]
