## OverworldBootstrap
## Orchestrates the overworld scene bootstrap sequence.
## Extends Node — lives in the overworld layer.
##
## Bootstrap sequence (no combat systems started):
##   1. Load the map definition.
##   2. Spawn the player at the map-defined spawn point.
##   3. Initialize collision and interaction layers.
##   4. Initialize camera follow at the spawn world position.
##
## Architecture: extends Node. Emits signals for the scene/UI layer to react to.
## Delegates data parsing to MapDefinition.
class_name OverworldBootstrap
extends Node

const MapDefinitionClass = preload("res://overworld/map_definition.gd")

## Pixel size of one grid tile, used to convert spawn_point to world position.
const TILE_SIZE: int = 32

## Emitted once the map definition has been loaded.
signal map_loaded(map_def)

## Emitted with the player's spawn position in grid coordinates.
signal player_spawned(position: Vector2i)

## Emitted when the collision and interaction layers are initialized.
signal layers_initialized(collision_layer: int, interaction_layer: int)

## Emitted when the camera follow target is set, carrying the world position.
signal camera_follow_initialized(position: Vector2)

## Emitted with the pixel-space bounding rect of the map (origin at (0, 0)).
## Consumers should pass this to OverworldCameraController.set_map_bounds().
signal camera_bounds_initialized(bounds: Rect2)

## True after bootstrap() completes successfully.
var is_bootstrapped: bool = false

## The currently loaded MapDefinition. Null if not bootstrapped yet.
var current_map: MapDefinitionClass = null


## Runs the full overworld bootstrap sequence for [param map_def].
## Emits map_loaded, player_spawned, layers_initialized,
## and camera_follow_initialized in order.
## No combat systems are started.
##
## map_def : A valid MapDefinition (use MapLoader to construct one).
func bootstrap(map_def: MapDefinitionClass) -> void:
	is_bootstrapped = false
	current_map = map_def
	map_loaded.emit(map_def)
	player_spawned.emit(map_def.spawn_point)
	layers_initialized.emit(map_def.collision_layer, map_def.interaction_layer)
	var world_pos := Vector2(
		map_def.spawn_point.x * TILE_SIZE,
		map_def.spawn_point.y * TILE_SIZE
	)
	camera_follow_initialized.emit(world_pos)
	var map_width_px := float(map_def.map_width * TILE_SIZE)
	var map_height_px := float(map_def.map_height * TILE_SIZE)
	camera_bounds_initialized.emit(Rect2(0.0, 0.0, map_width_px, map_height_px))
	is_bootstrapped = true
