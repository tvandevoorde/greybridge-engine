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

## Emitted with the blocked tile positions derived from the map definition.
## blocked_tiles : Array of Vector2i — tiles the player cannot enter.
signal collision_tiles_ready(blocked_tiles: Array)

## Emitted when the camera follow target is set, carrying the world position.
signal camera_follow_initialized(position: Vector2)

## Emitted with the raw transition Array from the map definition.
## Connect to MapTransitionController.load_transitions() in the scene layer.
signal transitions_ready(transitions: Array)

## True after bootstrap() completes successfully.
var is_bootstrapped: bool = false

## The currently loaded MapDefinition. Null if not bootstrapped yet.
var current_map: MapDefinitionClass = null


## Runs the full overworld bootstrap sequence for [param map_def],
## using the map's own spawn_point as the player starting position.
## Emits map_loaded, player_spawned, layers_initialized,
## collision_tiles_ready, transitions_ready, and camera_follow_initialized.
## No combat systems are started.
##
## map_def : A valid MapDefinition (use MapLoader to construct one).
func bootstrap(map_def: MapDefinitionClass) -> void:
	bootstrap_at(map_def, map_def.spawn_point)


## Runs the full overworld bootstrap sequence for [param map_def],
## placing the player at [param spawn] instead of the map default.
## Use this when transitioning from another map so the player arrives at
## the transition's target_spawn rather than the map's default spawn_point.
##
## Emits map_loaded, player_spawned, layers_initialized,
## collision_tiles_ready, transitions_ready, and camera_follow_initialized.
## No combat systems are started.
##
## map_def : A valid MapDefinition (use MapLoader to construct one).
## spawn   : Grid tile to place the player on.
func bootstrap_at(map_def: MapDefinitionClass, spawn: Vector2i) -> void:
	is_bootstrapped = false
	current_map = map_def
	map_loaded.emit(map_def)
	player_spawned.emit(spawn)
	layers_initialized.emit(map_def.collision_layer, map_def.interaction_layer)
	collision_tiles_ready.emit(map_def.blocked_tiles)
	transitions_ready.emit(map_def.transitions)
	var world_pos := Vector2(
		spawn.x * TILE_SIZE,
		spawn.y * TILE_SIZE
	)
	camera_follow_initialized.emit(world_pos)
	is_bootstrapped = true
