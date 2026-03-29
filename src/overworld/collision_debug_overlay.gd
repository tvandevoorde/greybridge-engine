## CollisionDebugOverlay
## Overworld runtime class — extends Node.
## Manages the dev-only debug state for the collision layer visualization.
##
## This class holds the blocked-tile data and visibility toggle, and emits
## a signal whenever the debug view is toggled on or off.  The scene layer
## (a Node2D or CanvasItem) subscribes to debug_visibility_changed and
## performs the actual drawing.  No rendering is done here.
##
## Architecture: extends Node.  No rules logic.  No direct UI drawing.
##   Visibility state → emits signal → scene layer draws debug overlay.
##
## Dev-only: this node should only be added to the scene tree in debug/editor
## builds.  It has no effect on gameplay logic.
class_name CollisionDebugOverlay
extends Node

## Emitted when the debug overlay visibility is toggled.
## visible : bool  — true when the overlay should be drawn.
signal debug_visibility_changed(visible: bool)

var _tiles: Array = []
var _tile_size: int = 32
var _debug_visible: bool = false


## Set the blocked tile positions and tile size for the overlay.
##
## tiles     : Array of Vector2i — blocked tile grid coordinates.
## tile_size : int               — pixel size of one tile.
func set_tiles(tiles: Array, tile_size: int) -> void:
	_tiles = tiles.duplicate()
	_tile_size = tile_size


## Toggle the debug overlay on or off.
##
## When [param visible] differs from the current state, emits
## debug_visibility_changed.  Repeated calls with the same value are no-ops.
func set_debug_visible(visible: bool) -> void:
	if _debug_visible == visible:
		return
	_debug_visible = visible
	debug_visibility_changed.emit(_debug_visible)


## Returns true when the debug overlay is currently visible.
func is_debug_visible() -> bool:
	return _debug_visible


## Returns a copy of the blocked tile positions currently stored.
func get_tiles() -> Array:
	return _tiles.duplicate()


## Returns the pixel tile size currently stored.
func get_tile_size() -> int:
	return _tile_size
