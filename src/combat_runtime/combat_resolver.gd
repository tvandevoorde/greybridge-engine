## CombatResolver
## Combat runtime class — extends Node.
## Detects when one side has no conscious actors, collects loot/rewards from
## defeated enemies, clears combat state, and signals the scene to return to
## the overworld.
##
## Architecture: extends Node. Delegates state clearing to CombatStateManager.
## No 5e math here.
##
## Participant dictionaries are expected to contain:
##   "id"         : String — unique actor identifier
##   "side"       : String — "player" or "enemy"
##   "current_hp" : int    — current hit points (0 means unconscious/defeated)
##   "loot"       : Array  — (optional) reward items dropped on defeat (enemy side only)
class_name CombatResolver
extends Node

const CombatStateManagerClass = preload("res://combat_runtime/combat_state_manager.gd")

## Emitted when combat ends with an outcome.
## outcome : Dictionary with keys:
##   "result"  : String — "player_victory" or "player_defeat"
##   "rewards" : Array  — collected loot items (empty on defeat)
signal combat_ended(outcome: Dictionary)

## Emitted with the collected reward items when the player wins.
## rewards : Array of reward items gathered from defeated enemies.
signal loot_ready(rewards: Array)

## Emitted after combat state is cleared, signalling that the scene should
## transition back to the overworld.
signal return_to_overworld()


## Checks whether one side has no conscious actors.
##
## participants : Array of Dictionaries, each with "side" and "current_hp".
##
## Returns:
##   "player_victory" — all enemies have current_hp <= 0 (and at least one enemy exists)
##   "player_defeat"  — all players have current_hp <= 0 (and at least one player exists)
##   ""               — combat is still ongoing (both sides have conscious actors,
##                      or a required side is absent)
func check_for_combat_end(participants: Array) -> String:
	var player_all_down: bool = true
	var enemy_all_down: bool = true
	var has_player: bool = false
	var has_enemy: bool = false

	for p in participants:
		var side: String = p.get("side", "")
		var hp: int = p.get("current_hp", 0)
		if side == "player":
			has_player = true
			if hp > 0:
				player_all_down = false
		elif side == "enemy":
			has_enemy = true
			if hp > 0:
				enemy_all_down = false

	if has_player and has_enemy:
		if enemy_all_down:
			return "player_victory"
		if player_all_down:
			return "player_defeat"
	return ""


## Collects loot from all defeated (current_hp <= 0) enemy participants.
##
## participants : Array of Dictionaries, each with "side", "current_hp",
##               and an optional "loot" Array.
##
## Returns an Array of all loot items gathered from defeated enemies.
func collect_rewards(participants: Array) -> Array:
	var rewards: Array = []
	for p in participants:
		if p.get("side", "") == "enemy" and p.get("current_hp", 0) <= 0:
			var loot: Array = p.get("loot", [])
			rewards.append_array(loot)
	return rewards


## Resolve end-of-combat: detect the winning side, collect rewards, clear
## combat state, and emit the appropriate signals.
##
## Does nothing if combat is still ongoing (both sides have conscious actors).
##
## state_manager : CombatStateManager instance to clear when combat ends.
## participants  : Array of Dictionaries (same schema as check_for_combat_end).
func resolve(state_manager: CombatStateManagerClass, participants: Array) -> void:
	var result: String = check_for_combat_end(participants)
	if result == "":
		return

	var rewards: Array = []
	if result == "player_victory":
		rewards = collect_rewards(participants)

	state_manager.end_combat()

	var outcome: Dictionary = {"result": result, "rewards": rewards}
	combat_ended.emit(outcome)

	if result == "player_victory":
		loot_ready.emit(rewards)

	return_to_overworld.emit()
