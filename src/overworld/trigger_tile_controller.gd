## TriggerTileController
## Overworld runtime class — extends Node.
## Monitors the tile the player steps onto and fires the appropriate event
## when a trigger tile is entered and its conditions are met.
##
## Architecture: extends Node. Delegates condition evaluation to
## TriggerTileResolver (rules_engine). Emits signals for the scene and UI
## layers to react to. Does not implement any game logic directly.
##
## Usage:
##   1. Call load_triggers() with the triggers layer from map data.
##   2. Connect on_stepped() to GridMovementController.stepped.
##   3. Call set_quest_flags() whenever quest state changes.
##   4. Subscribe to combat_trigger_fired / dialogue_trigger_fired /
##      flag_trigger_fired / teleport_trigger_fired as needed.
class_name TriggerTileController
extends Node

const TriggerTileResolverClass = preload("res://rules_engine/core/trigger_tile_resolver.gd")

## Emitted when a "combat_start" trigger fires.
## encounter_id : String — identifier of the encounter to start.
signal combat_trigger_fired(encounter_id: String)

## Emitted when a "dialogue_start" trigger fires.
## dialogue_id  : String — identifier of the dialogue tree to start.
signal dialogue_trigger_fired(dialogue_id: String)

## Emitted when a "set_flag" trigger fires.
## flag_key   : String — the quest flag to set.
## flag_value : bool   — the value to assign to the flag.
signal flag_trigger_fired(flag_key: String, flag_value: bool)

## Emitted when a "teleport" trigger fires.
## target_map : String   — map identifier to transition to.
## target_pos : Vector2i — spawn position on the target map.
signal teleport_trigger_fired(target_map: String, target_pos: Vector2i)

## Tile-position → trigger Dictionary, populated by load_triggers().
var _trigger_map: Dictionary = {}

## IDs of one-time triggers that have already fired this session.
var _fired_ids: Array = []

## Current quest-flag state used for condition evaluation.
var _quest_flags: Dictionary = {}

var _resolver: TriggerTileResolverClass = TriggerTileResolverClass.new()


## Loads the trigger layer from map data.
##
## trigger_layer : Array — 2-D array (rows × columns) of trigger Dictionaries
##                         or null. Non-null entries are registered at their
##                         (column, row) tile position.
func load_triggers(trigger_layer: Array) -> void:
	_trigger_map.clear()
	for row_idx in range(trigger_layer.size()):
		var row: Array = trigger_layer[row_idx]
		for col_idx in range(row.size()):
			var entry = row[col_idx]
			if entry != null and entry is Dictionary:
				_trigger_map[Vector2i(col_idx, row_idx)] = entry


## Replaces the quest-flag state used for trigger condition checks.
##
## flags : Dictionary — current quest flags (flag name → bool).
func set_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()


## Called when the player steps to a new tile.
## Checks whether the destination tile has a trigger and, if the resolver
## approves, marks one-time triggers fired and emits the appropriate signal.
##
## from : Vector2i — tile the player left.
## to   : Vector2i — tile the player entered.
func on_stepped(from: Vector2i, to: Vector2i) -> void:
	if not _trigger_map.has(to):
		return

	var trigger: Dictionary = _trigger_map[to]
	var result: Dictionary = _resolver.resolve(trigger, _fired_ids, _quest_flags)
	if not result["should_fire"]:
		return

	# Mark one-time triggers as fired so they cannot fire again.
	var id: String = trigger.get("id", "")
	var one_time: bool = trigger.get("one_time", false)
	if one_time and id != "" and id not in _fired_ids:
		_fired_ids.append(id)

	# Dispatch the correct signal based on action type.
	var action_type: String = trigger.get("type", "")
	match action_type:
		"combat_start":
			combat_trigger_fired.emit(trigger.get("encounter_id", ""))
		"dialogue_start":
			dialogue_trigger_fired.emit(trigger.get("dialogue_id", ""))
		"set_flag":
			flag_trigger_fired.emit(
				trigger.get("flag_key", ""),
				trigger.get("flag_value", false)
			)
		"teleport":
			var raw_pos: Dictionary = trigger.get("target_pos", {"x": 0, "y": 0})
			teleport_trigger_fired.emit(
				trigger.get("target_map", ""),
				Vector2i(int(raw_pos.get("x", 0)), int(raw_pos.get("y", 0)))
			)
