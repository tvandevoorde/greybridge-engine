## test_overworld_bootstrap.gd
## Unit tests for OverworldBootstrap (src/overworld/overworld_bootstrap.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_overworld_bootstrap.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const MapDefinitionClass = preload("res://overworld/map_definition.gd")
const OverworldBootstrapClass = preload("res://overworld/overworld_bootstrap.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	_run_all_tests()
	print("\nResults: %d passed, %d failed" % [_pass_count, _fail_count])
	quit(1 if _fail_count > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: %s" % description)
		_pass_count += 1
	else:
		print("  FAIL: %s" % description)
		_fail_count += 1


func _make_map_def(map_id: String, x: int, y: int, col: int, inter: int, w: int = 0, h: int = 0) -> MapDefinitionClass:
	var def := MapDefinitionClass.new()
	def.map_id = map_id
	def.spawn_point = Vector2i(x, y)
	def.collision_layer = col
	def.interaction_layer = inter
	def.map_width = w
	def.map_height = h
	return def

func _run_all_tests() -> void:
	_test_not_bootstrapped_by_default()
	_test_current_map_null_by_default()
	_test_bootstrap_sets_is_bootstrapped()
	_test_bootstrap_sets_current_map()
	_test_bootstrap_emits_map_loaded()
	_test_bootstrap_emits_player_spawned()
	_test_bootstrap_emits_layers_initialized()
	_test_bootstrap_emits_collision_tiles_ready()
	_test_bootstrap_collision_tiles_match_map_def()
	_test_bootstrap_emits_camera_follow_initialized()
	_test_camera_follow_position_matches_spawn_point()
	_test_bootstrap_emits_camera_bounds_initialized()
	_test_camera_bounds_match_map_dimensions()
	_test_bootstrap_no_combat_systems_active()
	_test_bootstrap_overwrites_previous_state()
	_test_bootstrap_emits_music_track_requested_when_track_set()
	_test_bootstrap_does_not_emit_music_track_requested_when_no_track()

	_test_bootstrap_emits_transitions_ready()
	_test_bootstrap_at_uses_override_spawn_for_player_spawned()
	_test_bootstrap_at_uses_override_spawn_for_camera()
	_test_bootstrap_at_sets_is_bootstrapped()
	_test_bootstrap_at_emits_transitions_ready()
	_test_transitions_ready_carries_map_transitions()
	_test_bootstrap_emits_fog_of_war_ready()
	_test_bootstrap_fog_of_war_ready_carries_enabled_flag()
	_test_bootstrap_fog_of_war_ready_carries_visibility_radius()
	_test_bootstrap_fog_of_war_ready_when_fog_disabled()
	_test_bootstrap_at_emits_fog_of_war_ready()

# ---------------------------------------------------------------------------
# is_bootstrapped is false by default
# ---------------------------------------------------------------------------
func _test_not_bootstrapped_by_default() -> void:
	print("_test_not_bootstrapped_by_default")
	var ob := OverworldBootstrapClass.new()
	_check(ob.is_bootstrapped == false, "is_bootstrapped is false by default")
	ob.free()


# ---------------------------------------------------------------------------
# current_map is null by default
# ---------------------------------------------------------------------------
func _test_current_map_null_by_default() -> void:
	print("_test_current_map_null_by_default")
	var ob := OverworldBootstrapClass.new()
	_check(ob.current_map == null, "current_map is null by default")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() sets is_bootstrapped to true
# ---------------------------------------------------------------------------
func _test_bootstrap_sets_is_bootstrapped() -> void:
	print("_test_bootstrap_sets_is_bootstrapped")
	var ob := OverworldBootstrapClass.new()
	var def := _make_map_def("test_map", 2, 3, 1, 2)
	ob.bootstrap(def)
	_check(ob.is_bootstrapped == true, "is_bootstrapped is true after bootstrap()")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() sets current_map
# ---------------------------------------------------------------------------
func _test_bootstrap_sets_current_map() -> void:
	print("_test_bootstrap_sets_current_map")
	var ob := OverworldBootstrapClass.new()
	var def := _make_map_def("road_to_greybridge", 2, 3, 1, 2)
	ob.bootstrap(def)
	_check(ob.current_map != null, "current_map is set after bootstrap()")
	_check(ob.current_map.map_id == "road_to_greybridge", "current_map.map_id matches")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() emits map_loaded
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_map_loaded() -> void:
	print("_test_bootstrap_emits_map_loaded")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.map_loaded.connect(func(md) -> void:
		received.append(md)
	)
	var def := _make_map_def("road_to_greybridge", 0, 0, 1, 2)
	ob.bootstrap(def)
	_check(received.size() == 1, "map_loaded emitted once")
	_check(received[0].map_id == "road_to_greybridge", "map_loaded payload has correct map_id")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() emits player_spawned with the map spawn point
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_player_spawned() -> void:
	print("_test_bootstrap_emits_player_spawned")
	var ob := OverworldBootstrapClass.new()
	var received_positions: Array = []
	ob.player_spawned.connect(func(pos: Vector2i) -> void:
		received_positions.append(pos)
	)
	var def := _make_map_def("test_map", 4, 7, 1, 2)
	ob.bootstrap(def)
	_check(received_positions.size() == 1, "player_spawned emitted once")
	_check(received_positions[0] == Vector2i(4, 7), "player_spawned position matches spawn_point")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() emits layers_initialized with collision and interaction layers
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_layers_initialized() -> void:
	print("_test_bootstrap_emits_layers_initialized")
	var ob := OverworldBootstrapClass.new()
	var col_received: Array = []
	var inter_received: Array = []
	ob.layers_initialized.connect(func(col: int, inter: int) -> void:
		col_received.append(col)
		inter_received.append(inter)
	)
	var def := _make_map_def("test_map", 0, 0, 3, 5)
	ob.bootstrap(def)
	_check(col_received.size() == 1, "layers_initialized emitted once")
	_check(col_received[0] == 3, "collision_layer in signal matches map def")
	_check(inter_received[0] == 5, "interaction_layer in signal matches map def")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() emits collision_tiles_ready
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_collision_tiles_ready() -> void:
	print("_test_bootstrap_emits_collision_tiles_ready")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.collision_tiles_ready.connect(func(tiles: Array) -> void:
		received.append(tiles)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap(def)
	_check(received.size() == 1, "collision_tiles_ready emitted once")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() collision_tiles_ready carries blocked tiles from the map def
# ---------------------------------------------------------------------------
func _test_bootstrap_collision_tiles_match_map_def() -> void:
	print("_test_bootstrap_collision_tiles_match_map_def")
	var ob := OverworldBootstrapClass.new()
	var received_tiles: Array = []
	ob.collision_tiles_ready.connect(func(tiles: Array) -> void:
		received_tiles.append_array(tiles)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	def.blocked_tiles = [Vector2i(1, 2), Vector2i(3, 4)]
	ob.bootstrap(def)
	_check(received_tiles.size() == 2, "collision_tiles_ready carries 2 blocked tiles")
	_check(received_tiles.has(Vector2i(1, 2)), "tile (1,2) present in signal payload")
	_check(received_tiles.has(Vector2i(3, 4)), "tile (3,4) present in signal payload")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() emits camera_follow_initialized
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_camera_follow_initialized() -> void:
	print("_test_bootstrap_emits_camera_follow_initialized")
	var ob := OverworldBootstrapClass.new()
	var received_positions: Array = []
	ob.camera_follow_initialized.connect(func(pos: Vector2) -> void:
		received_positions.append(pos)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap(def)
	_check(received_positions.size() == 1, "camera_follow_initialized emitted once")
	ob.free()


# ---------------------------------------------------------------------------
# camera_follow_initialized position corresponds to spawn_point * TILE_SIZE
# ---------------------------------------------------------------------------
func _test_camera_follow_position_matches_spawn_point() -> void:
	print("_test_camera_follow_position_matches_spawn_point")
	var ob := OverworldBootstrapClass.new()
	var received_positions: Array = []
	ob.camera_follow_initialized.connect(func(pos: Vector2) -> void:
		received_positions.append(pos)
	)
	var def := _make_map_def("test_map", 3, 5, 1, 2)
	ob.bootstrap(def)
	var tile_size: int = OverworldBootstrapClass.TILE_SIZE
	var expected := Vector2(3 * tile_size, 5 * tile_size)
	_check(received_positions[0] == expected, "camera position is spawn_point * TILE_SIZE")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() emits camera_bounds_initialized
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_camera_bounds_initialized() -> void:
	print("_test_bootstrap_emits_camera_bounds_initialized")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.camera_bounds_initialized.connect(func(bounds: Rect2) -> void:
		received.append(bounds)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2, 20, 15)
	ob.bootstrap(def)
	_check(received.size() == 1, "camera_bounds_initialized emitted once")
	ob.free()


# ---------------------------------------------------------------------------
# camera_bounds_initialized rect dimensions match map_width/height * TILE_SIZE
# ---------------------------------------------------------------------------
func _test_camera_bounds_match_map_dimensions() -> void:
	print("_test_camera_bounds_match_map_dimensions")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.camera_bounds_initialized.connect(func(bounds: Rect2) -> void:
		received.append(bounds)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2, 20, 15)
	ob.bootstrap(def)
	var tile_size: int = OverworldBootstrapClass.TILE_SIZE
	var expected := Rect2(0.0, 0.0, float(20 * tile_size), float(15 * tile_size))
	_check(received[0] == expected, "camera_bounds rect matches map_width/height * TILE_SIZE")
	ob.free()


# ---------------------------------------------------------------------------
# no combat systems are active after bootstrap
# ---------------------------------------------------------------------------
func _test_bootstrap_no_combat_systems_active() -> void:
	print("_test_bootstrap_no_combat_systems_active")
	var ob := OverworldBootstrapClass.new()
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap(def)
	# OverworldBootstrap must not expose a combat_ready signal, confirming
	# no combat system was started during the overworld bootstrap.
	_check(not ob.has_signal("combat_ready"), "no combat_ready signal on bootstrap")
	ob.free()


# ---------------------------------------------------------------------------
# calling bootstrap() twice updates state to the new map
# ---------------------------------------------------------------------------
func _test_bootstrap_overwrites_previous_state() -> void:
	print("_test_bootstrap_overwrites_previous_state")
	var ob := OverworldBootstrapClass.new()
	var def1 := _make_map_def("map_one", 1, 1, 1, 2)
	var def2 := _make_map_def("map_two", 9, 9, 3, 4)
	ob.bootstrap(def1)
	ob.bootstrap(def2)
	_check(ob.current_map.map_id == "map_two", "current_map updated to second map")
	_check(ob.is_bootstrapped == true, "is_bootstrapped remains true after second bootstrap")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() emits music_track_requested when map has a non-empty music_track
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_music_track_requested_when_track_set() -> void:
	print("_test_bootstrap_emits_music_track_requested_when_track_set")
	var ob := OverworldBootstrapClass.new()
	var received_tracks: Array = []
	ob.music_track_requested.connect(func(track_id: String) -> void:
		received_tracks.append(track_id)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	def.music_track = "forest_theme"
	ob.bootstrap(def)
	_check(received_tracks.size() == 1, "music_track_requested emitted once")
	_check(received_tracks[0] == "forest_theme", "music_track_requested carries the correct track id")
# bootstrap() emits transitions_ready
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_transitions_ready() -> void:
	print("_test_bootstrap_emits_transitions_ready")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.transitions_ready.connect(func(_t: Array) -> void:
		received.append(true)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap(def)
	_check(received.size() == 1, "transitions_ready emitted once during bootstrap()")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap() does NOT emit music_track_requested when map has no music_track
# ---------------------------------------------------------------------------
func _test_bootstrap_does_not_emit_music_track_requested_when_no_track() -> void:
	print("_test_bootstrap_does_not_emit_music_track_requested_when_no_track")
	var ob := OverworldBootstrapClass.new()
	var received_tracks: Array = []
	ob.music_track_requested.connect(func(track_id: String) -> void:
		received_tracks.append(track_id)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	# def.music_track is "" by default
	ob.bootstrap(def)
	_check(received_tracks.size() == 0, "music_track_requested not emitted when track is empty")
	ob.free()
# transitions_ready carries the map's transition list
# ---------------------------------------------------------------------------
func _test_transitions_ready_carries_map_transitions() -> void:
	print("_test_transitions_ready_carries_map_transitions")
	var ob := OverworldBootstrapClass.new()
	var received_lists: Array = []
	ob.transitions_ready.connect(func(t: Array) -> void:
		received_lists.append(t)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	def.transitions = [{"tile": {"x": 5, "y": 0}, "target_map": "greybridge_town",
		"target_spawn": {"x": 1, "y": 8}, "required_flags": {}}]
	ob.bootstrap(def)
	_check(received_lists.size() == 1, "transitions_ready emitted once")
	_check(received_lists[0].size() == 1, "transitions_ready payload has 1 transition")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap_at() uses the supplied spawn point for player_spawned
# ---------------------------------------------------------------------------
func _test_bootstrap_at_uses_override_spawn_for_player_spawned() -> void:
	print("_test_bootstrap_at_uses_override_spawn_for_player_spawned")
	var ob := OverworldBootstrapClass.new()
	var received_positions: Array = []
	ob.player_spawned.connect(func(pos: Vector2i) -> void:
		received_positions.append(pos)
	)
	var def := _make_map_def("test_map", 1, 1, 1, 2)
	ob.bootstrap_at(def, Vector2i(7, 3))
	_check(received_positions.size() == 1, "player_spawned emitted once from bootstrap_at()")
	_check(received_positions[0] == Vector2i(7, 3),
		"player_spawned uses the override spawn, not map default")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap_at() uses the override spawn for camera_follow_initialized
# ---------------------------------------------------------------------------
func _test_bootstrap_at_uses_override_spawn_for_camera() -> void:
	print("_test_bootstrap_at_uses_override_spawn_for_camera")
	var ob := OverworldBootstrapClass.new()
	var received_positions: Array = []
	ob.camera_follow_initialized.connect(func(pos: Vector2) -> void:
		received_positions.append(pos)
	)
	var def := _make_map_def("test_map", 1, 1, 1, 2)
	ob.bootstrap_at(def, Vector2i(7, 3))
	var tile_size: int = OverworldBootstrapClass.TILE_SIZE
	var expected := Vector2(7 * tile_size, 3 * tile_size)
	_check(received_positions.size() == 1, "camera_follow_initialized emitted once from bootstrap_at()")
	_check(received_positions[0] == expected,
		"camera follow uses override spawn * TILE_SIZE")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap_at() sets is_bootstrapped
# ---------------------------------------------------------------------------
func _test_bootstrap_at_sets_is_bootstrapped() -> void:
	print("_test_bootstrap_at_sets_is_bootstrapped")
	var ob := OverworldBootstrapClass.new()
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap_at(def, Vector2i(2, 5))
	_check(ob.is_bootstrapped == true, "is_bootstrapped is true after bootstrap_at()")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap_at() emits transitions_ready
# ---------------------------------------------------------------------------
func _test_bootstrap_at_emits_transitions_ready() -> void:
	print("_test_bootstrap_at_emits_transitions_ready")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.transitions_ready.connect(func(_t: Array) -> void:
		received.append(true)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap_at(def, Vector2i(0, 0))
	_check(received.size() == 1, "transitions_ready emitted once during bootstrap_at()")
	ob.free()



# ---------------------------------------------------------------------------
# bootstrap() emits fog_of_war_ready
# ---------------------------------------------------------------------------
func _test_bootstrap_emits_fog_of_war_ready() -> void:
	print("_test_bootstrap_emits_fog_of_war_ready")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.fog_of_war_ready.connect(func(_e: bool, _r: int) -> void:
		received.append(true)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap(def)
	_check(received.size() == 1, "fog_of_war_ready emitted once during bootstrap()")
	ob.free()


# ---------------------------------------------------------------------------
# fog_of_war_ready carries fog_enabled flag from the map definition
# ---------------------------------------------------------------------------
func _test_bootstrap_fog_of_war_ready_carries_enabled_flag() -> void:
	print("_test_bootstrap_fog_of_war_ready_carries_enabled_flag")
	var ob := OverworldBootstrapClass.new()
	var enabled_values: Array = []
	ob.fog_of_war_ready.connect(func(e: bool, _r: int) -> void:
		enabled_values.append(e)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	def.fog_of_war_enabled = true
	ob.bootstrap(def)
	_check(enabled_values.size() == 1, "fog_of_war_ready emitted once")
	_check(enabled_values[0] == true, "fog_of_war_ready carries fog_enabled = true")
	ob.free()


# ---------------------------------------------------------------------------
# fog_of_war_ready carries visibility_radius from the map definition
# ---------------------------------------------------------------------------
func _test_bootstrap_fog_of_war_ready_carries_visibility_radius() -> void:
	print("_test_bootstrap_fog_of_war_ready_carries_visibility_radius")
	var ob := OverworldBootstrapClass.new()
	var radius_values: Array = []
	ob.fog_of_war_ready.connect(func(_e: bool, r: int) -> void:
		radius_values.append(r)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	def.fog_of_war_enabled = true
	def.visibility_radius = 7
	ob.bootstrap(def)
	_check(radius_values.size() == 1, "fog_of_war_ready emitted once")
	_check(radius_values[0] == 7, "fog_of_war_ready carries the correct visibility_radius")
	ob.free()


# ---------------------------------------------------------------------------
# fog_of_war_ready emitted with fog_enabled = false when map has no fog
# ---------------------------------------------------------------------------
func _test_bootstrap_fog_of_war_ready_when_fog_disabled() -> void:
	print("_test_bootstrap_fog_of_war_ready_when_fog_disabled")
	var ob := OverworldBootstrapClass.new()
	var enabled_values: Array = []
	ob.fog_of_war_ready.connect(func(e: bool, _r: int) -> void:
		enabled_values.append(e)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	# def.fog_of_war_enabled is false by default
	ob.bootstrap(def)
	_check(enabled_values.size() == 1, "fog_of_war_ready emitted even when fog is disabled")
	_check(enabled_values[0] == false, "fog_of_war_ready carries fog_enabled = false")
	ob.free()


# ---------------------------------------------------------------------------
# bootstrap_at() emits fog_of_war_ready
# ---------------------------------------------------------------------------
func _test_bootstrap_at_emits_fog_of_war_ready() -> void:
	print("_test_bootstrap_at_emits_fog_of_war_ready")
	var ob := OverworldBootstrapClass.new()
	var received: Array = []
	ob.fog_of_war_ready.connect(func(_e: bool, _r: int) -> void:
		received.append(true)
	)
	var def := _make_map_def("test_map", 0, 0, 1, 2)
	ob.bootstrap_at(def, Vector2i(3, 1))
	_check(received.size() == 1, "fog_of_war_ready emitted once during bootstrap_at()")
	ob.free()
