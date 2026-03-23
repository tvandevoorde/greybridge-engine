## OverworldCameraController
## Manages camera follow behaviour during overworld exploration.
## Extends Node — lives in the overworld layer.
##
## Responsibilities:
##   - Accepts a world-space follow target position.
##   - Emits camera_follow_requested so consumers (e.g. a Camera2D tween)
##     can interpolate to the new position.
##
## This class contains NO rules logic and performs NO 5e math.
## Connect its signal from the scene layer; call follow_target() from the
## overworld bootstrap or player controller.
class_name OverworldCameraController
extends Node

## Emitted whenever the camera should move to follow a new world position.
## Consumers (e.g. a Camera2D tween) should interpolate to this position.
signal camera_follow_requested(position: Vector2)

var _follow_position: Vector2 = Vector2.ZERO
var _map_width_px: float = 0.0
var _map_height_px: float = 0.0
var _bounds_set: bool = false


## Configure the map pixel dimensions used to clamp the follow position.
## Call this before the first follow_target() to enable edge clamping.
func set_map_bounds(map_width_px: float, map_height_px: float) -> void:
	_map_width_px = map_width_px
	_map_height_px = map_height_px
	_bounds_set = true


## Begin following the target at [param position] in world space.
## When map bounds have been set the position is clamped to the map rectangle
## before being stored and emitted, preventing the camera from drifting beyond
## map edges.
func follow_target(position: Vector2) -> void:
	var clamped := _clamp_to_bounds(position)
	_follow_position = clamped
	camera_follow_requested.emit(clamped)


## Returns the current camera follow position.
func get_follow_position() -> Vector2:
	return _follow_position


## Clamps [param position] to the configured map rectangle.
## Returns the position unchanged when no bounds have been set.
func _clamp_to_bounds(position: Vector2) -> Vector2:
	if not _bounds_set:
		return position
	return Vector2(
		clamp(position.x, 0.0, _map_width_px),
		clamp(position.y, 0.0, _map_height_px)
	)
