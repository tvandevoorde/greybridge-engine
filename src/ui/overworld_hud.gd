## OverworldHud
## UI layer class — extends Node.
## Displays a minimal heads-up display during overworld exploration showing
## the player's current HP and an optional active quest objective.
##
## Responsibilities:
##   - Store the latest HP snapshot (current / max).
##   - Store the current quest-objective text (empty when none is active).
##   - Allow the HUD to be toggled on/off without losing its data.
##   - Emit signals whenever the displayed data or visibility changes.
##
## This class contains NO rules logic and performs NO 5e math.
## It must NOT reference combat-only UI or combat state.
##
## Usage:
##   hud.refresh_hp(8, 10)
##   hud.set_quest_objective("Reach Greybridge")
##   hud.toggle()                     # hide
##   hud.toggle()                     # show again
##
##   hud.get_current_hp()             # → 8
##   hud.get_max_hp()                 # → 10
##   hud.get_quest_objective()        # → "Reach Greybridge"
##   hud.has_quest_objective()        # → true
##   hud.is_visible                   # → true
##
## Wire-up example (scene layer):
##   overworld_bootstrap.player_spawned.connect(func(pos): hud.refresh_hp(max_hp, max_hp))
##   npc_controller.quest_flag_set.connect(func(k,v): hud.set_quest_objective(...))
class_name OverworldHud
extends Node

## Emitted after every refresh_hp() call.
signal hp_updated(current_hp: int, max_hp: int)

## Emitted after every set_quest_objective() call.
signal quest_objective_updated(text: String)

## Emitted when show_hud(), hide_hud(), or toggle() changes visibility.
signal visibility_changed(is_visible: bool)

## True while the HUD is shown; false when toggled off.
var is_visible: bool = true

var _current_hp: int = 0
var _max_hp: int = 0
var _quest_objective: String = ""


## Update the HP readout.
## current_hp must be >= 0; max_hp must be >= 1.
## Clamps current_hp to [0, max_hp].
func refresh_hp(current_hp: int, max_hp: int) -> void:
	_max_hp = max(1, max_hp)
	_current_hp = clamp(current_hp, 0, _max_hp)
	hp_updated.emit(_current_hp, _max_hp)


## Returns the last stored current HP value.
## Returns 0 before the first refresh_hp() call.
func get_current_hp() -> int:
	return _current_hp


## Returns the last stored maximum HP value.
## Returns 0 before the first refresh_hp() call.
func get_max_hp() -> int:
	return _max_hp


## Set the active quest-objective text shown in the HUD.
## Pass an empty string to clear the objective display.
func set_quest_objective(text: String) -> void:
	_quest_objective = text
	quest_objective_updated.emit(_quest_objective)


## Returns the current quest-objective text.
## Returns "" when no objective is set.
func get_quest_objective() -> String:
	return _quest_objective


## Returns true when a non-empty quest objective is set.
func has_quest_objective() -> bool:
	return _quest_objective != ""


## Make the HUD visible.
## Emits visibility_changed only when the state actually changes.
func show_hud() -> void:
	if not is_visible:
		is_visible = true
		visibility_changed.emit(is_visible)


## Hide the HUD.
## Emits visibility_changed only when the state actually changes.
func hide_hud() -> void:
	if is_visible:
		is_visible = false
		visibility_changed.emit(is_visible)


## Toggle HUD visibility.
## Emits visibility_changed after each call.
func toggle() -> void:
	is_visible = not is_visible
	visibility_changed.emit(is_visible)
