## OverworldDebugOverlay
## Overworld runtime class — extends Node.
## Unified dev-only debug overlay controller for the overworld.
##
## Aggregates all four debug-overlay features in a single hub:
##   1. Collision tile visualization toggle.
##   2. Trigger tile visualization toggle.
##   3. Player tile coordinate display.
##   4. Active quest flag display.
##
## The scene layer (Node2D / CanvasItem) subscribes to the signals emitted here
## and performs all actual rendering.  No rendering is done in this class.
##
## Architecture: extends Node.  No rules logic.  No direct UI drawing.
##
## Dev-only: this node should only be added to the scene tree in debug/editor
## builds.  It has no effect on gameplay logic.
class_name OverworldDebugOverlay
extends Node

## Emitted when the collision debug visualization is toggled.
## visible : bool — true when collision tiles should be drawn.
signal collision_debug_toggled(visible: bool)

## Emitted when the trigger debug visualization is toggled.
## visible : bool — true when trigger tiles should be drawn.
signal trigger_debug_toggled(visible: bool)

## Emitted when the player's current grid tile changes.
## tile : Vector2i — the player's new tile position.
signal player_tile_changed(tile: Vector2i)

## Emitted when the active quest flags are updated.
## flags : Dictionary — snapshot of the current quest flag state.
signal quest_flags_changed(flags: Dictionary)

var _collision_debug_visible: bool = false
var _trigger_debug_visible: bool = false
var _player_tile: Vector2i = Vector2i(0, 0)
var _quest_flags: Dictionary = {}


## Toggle the collision debug overlay on or off and emit collision_debug_toggled.
func toggle_collision_debug() -> void:
	_collision_debug_visible = not _collision_debug_visible
	collision_debug_toggled.emit(_collision_debug_visible)


## Toggle the trigger debug overlay on or off and emit trigger_debug_toggled.
func toggle_trigger_debug() -> void:
	_trigger_debug_visible = not _trigger_debug_visible
	trigger_debug_toggled.emit(_trigger_debug_visible)


## Update the displayed player tile coordinate and emit player_tile_changed.
##
## tile : Vector2i — the player's current grid tile position.
func update_player_tile(tile: Vector2i) -> void:
	_player_tile = tile
	player_tile_changed.emit(_player_tile)


## Replace the active quest flags and emit quest_flags_changed.
## A defensive copy is stored so external mutations do not affect internal state.
##
## flags : Dictionary — current quest flag state (key → value).
func update_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()
	quest_flags_changed.emit(_quest_flags.duplicate())


## Returns true when the collision debug overlay is currently visible.
func is_collision_debug_visible() -> bool:
	return _collision_debug_visible


## Returns true when the trigger debug overlay is currently visible.
func is_trigger_debug_visible() -> bool:
	return _trigger_debug_visible


## Returns the player's last known grid tile position.
func get_player_tile() -> Vector2i:
	return _player_tile


## Returns a copy of the active quest flags.
func get_quest_flags() -> Dictionary:
	return _quest_flags.duplicate()
