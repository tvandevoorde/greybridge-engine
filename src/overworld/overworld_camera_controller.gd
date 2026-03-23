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


## Begin following the target at [param position] in world space.
## Emits camera_follow_requested with the new position.
func follow_target(position: Vector2) -> void:
	_follow_position = position
	camera_follow_requested.emit(position)


## Returns the current camera follow position.
func get_follow_position() -> Vector2:
	return _follow_position
