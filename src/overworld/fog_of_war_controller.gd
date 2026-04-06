## FogOfWarController
## Overworld runtime class — extends Node.
## Manages the fog-of-war visibility state for the current map.
## Tracks which tiles are visible based on the player's position and
## the configured visibility radius.  Can be enabled or disabled per map.
##
## Architecture: extends Node.  Delegates tile calculation to
## VisibilityCalculator (rules_engine).  Emits signals for the scene/UI
## layer to react to.  Does not manipulate any visual node directly.
class_name FogOfWarController
extends Node

const VisibilityCalculatorClass = preload("res://rules_engine/core/visibility_calculator.gd")

## Emitted when the set of visible tiles changes.
## visible_tiles : Array[Vector2i] — all tiles currently visible to the player.
## When fog is disabled this signal is NOT emitted; all tiles are visible.
signal visibility_changed(visible_tiles: Array)

## True while fog of war is active on the current map.
var fog_enabled: bool = false

## Number of tiles the player can see in each direction (Chebyshev radius).
var visibility_radius: int = 5

var _calculator: VisibilityCalculatorClass = VisibilityCalculatorClass.new()
var _visible_tiles: Array[Vector2i] = []


## Enable fog of war with the given visibility radius.
## Does not update the visible tile set until update_position() is called.
func enable(radius: int) -> void:
	fog_enabled = true
	visibility_radius = radius


## Disable fog of war.
## Clears the visible tile cache and emits visibility_changed with an empty
## array to signal that fog has been lifted (all tiles should be revealed).
func disable() -> void:
	fog_enabled = false
	_visible_tiles = []
	visibility_changed.emit(_visible_tiles)


## Recompute visible tiles around [param pos] and emit visibility_changed.
## Has no effect when fog is disabled.
##
## pos : Vector2i — the player's current grid tile.
func update_position(pos: Vector2i) -> void:
	if not fog_enabled:
		return
	_visible_tiles = _calculator.compute_visible_tiles(pos, visibility_radius)
	visibility_changed.emit(_visible_tiles)


## Returns the most recently computed set of visible tiles.
## Returns an empty array when fog is disabled or before the first
## update_position() call.
func get_visible_tiles() -> Array[Vector2i]:
	return _visible_tiles
