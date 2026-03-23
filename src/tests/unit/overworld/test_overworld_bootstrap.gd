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


func _make_map_def(map_id: String, x: int, y: int, col: int, inter: int) -> MapDefinitionClass:
	var def := MapDefinitionClass.new()
	def.map_id = map_id
	def.spawn_point = Vector2i(x, y)
	def.collision_layer = col
	def.interaction_layer = inter
	return def


func _run_all_tests() -> void:
	_test_not_bootstrapped_by_default()
	_test_current_map_null_by_default()
	_test_bootstrap_sets_is_bootstrapped()
	_test_bootstrap_sets_current_map()
	_test_bootstrap_emits_map_loaded()
	_test_bootstrap_emits_player_spawned()
	_test_bootstrap_emits_layers_initialized()
	_test_bootstrap_emits_camera_follow_initialized()
	_test_camera_follow_position_matches_spawn_point()
	_test_bootstrap_no_combat_systems_active()
	_test_bootstrap_overwrites_previous_state()


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
