## test_map_loading.gd
## Integration test: loads src/content/maps/road_approach.json via MapLoader
## and validates all layers are present and correctly structured.
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/integration/test_map_loading.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const MapLoaderClass     = preload("res://rules_engine/core/map_loader.gd")
const MapDefinitionClass = preload("res://rules_engine/core/map_definition.gd")

const MAP_PATH := "res://content/maps/road_approach.json"

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


func _run_all_tests() -> void:
	_test_file_exists()
	_test_loads_without_error()
	_test_definition_is_valid()
	_test_map_size()
	_test_tileset_ref()
	_test_ground_layer_present_and_sized()
	_test_props_layer_present_and_sized()
	_test_collision_layer_present_and_sized()
	_test_triggers_layer_present_and_sized()
	_test_ground_layer_has_road_tiles()
	_test_collision_matches_props_trees()
	_test_trigger_cell_is_dictionary()
	_test_trigger_has_type_and_encounter_id()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _load_definition():
	var file := FileAccess.open(MAP_PATH, FileAccess.READ)
	if file == null:
		return null
	var json_text := file.get_as_text()
	file.close()
	var loader := MapLoaderClass.new()
	return loader.load_from_json(json_text)


# ---------------------------------------------------------------------------
# File presence
# ---------------------------------------------------------------------------
func _test_file_exists() -> void:
	print("_test_file_exists")
	_check(FileAccess.file_exists(MAP_PATH), "road_approach.json exists at %s" % MAP_PATH)


# ---------------------------------------------------------------------------
# Loads without error
# ---------------------------------------------------------------------------
func _test_loads_without_error() -> void:
	print("_test_loads_without_error")
	var def = _load_definition()
	_check(def != null, "map definition loaded without error")


# ---------------------------------------------------------------------------
# MapDefinition validity
# ---------------------------------------------------------------------------
func _test_definition_is_valid() -> void:
	print("_test_definition_is_valid")
	var def = _load_definition()
	if def == null:
		_check(false, "definition is valid (skipped — could not load)")
		return
	_check(def.is_valid(), "definition passes is_valid()")


# ---------------------------------------------------------------------------
# Map size metadata
# ---------------------------------------------------------------------------
func _test_map_size() -> void:
	print("_test_map_size")
	var def = _load_definition()
	if def == null:
		_check(false, "map size (skipped — could not load)")
		return
	_check(def.map_width == 10,  "map_width is 10")
	_check(def.map_height == 8, "map_height is 8")


# ---------------------------------------------------------------------------
# Tileset reference
# ---------------------------------------------------------------------------
func _test_tileset_ref() -> void:
	print("_test_tileset_ref")
	var def = _load_definition()
	if def == null:
		_check(false, "tileset_ref (skipped — could not load)")
		return
	_check(not def.tileset_ref.is_empty(), "tileset_ref is not empty")
	_check(def.tileset_ref == "res://content/tilesets/road.tres",
		"tileset_ref matches expected path")


# ---------------------------------------------------------------------------
# Layer presence and dimensions
# ---------------------------------------------------------------------------
func _test_ground_layer_present_and_sized() -> void:
	print("_test_ground_layer_present_and_sized")
	var def = _load_definition()
	if def == null:
		_check(false, "ground layer (skipped — could not load)")
		return
	_check(def.layers.has("ground"), "layers contains 'ground'")
	var ground: Array = def.layers["ground"]
	_check(ground.size() == 8,   "ground layer has 8 rows")
	_check(ground[0].size() == 10, "ground layer row 0 has 10 columns")


func _test_props_layer_present_and_sized() -> void:
	print("_test_props_layer_present_and_sized")
	var def = _load_definition()
	if def == null:
		_check(false, "props layer (skipped — could not load)")
		return
	_check(def.layers.has("props"), "layers contains 'props'")
	var props: Array = def.layers["props"]
	_check(props.size() == 8,    "props layer has 8 rows")
	_check(props[0].size() == 10, "props layer row 0 has 10 columns")


func _test_collision_layer_present_and_sized() -> void:
	print("_test_collision_layer_present_and_sized")
	var def = _load_definition()
	if def == null:
		_check(false, "collision layer (skipped — could not load)")
		return
	_check(def.layers.has("collision"), "layers contains 'collision'")
	var collision: Array = def.layers["collision"]
	_check(collision.size() == 8,    "collision layer has 8 rows")
	_check(collision[0].size() == 10, "collision layer row 0 has 10 columns")


func _test_triggers_layer_present_and_sized() -> void:
	print("_test_triggers_layer_present_and_sized")
	var def = _load_definition()
	if def == null:
		_check(false, "triggers layer (skipped — could not load)")
		return
	_check(def.layers.has("triggers"), "layers contains 'triggers'")
	var triggers: Array = def.layers["triggers"]
	_check(triggers.size() == 8,    "triggers layer has 8 rows")
	_check(triggers[0].size() == 10, "triggers layer row 0 has 10 columns")


# ---------------------------------------------------------------------------
# Content spot-checks
# ---------------------------------------------------------------------------
func _test_ground_layer_has_road_tiles() -> void:
	print("_test_ground_layer_has_road_tiles")
	var def = _load_definition()
	if def == null or not def.layers.has("ground"):
		_check(false, "ground tile values (skipped — could not load)")
		return
	var ground: Array = def.layers["ground"]
	# Columns 3,4,5 are road (tile ID 2), columns 0,1,2 are grass (tile ID 1)
	_check(ground[0][0] == 1, "ground[0][0] is grass (1)")
	_check(ground[0][3] == 2, "ground[0][3] is road (2)")
	_check(ground[7][5] == 2, "ground[7][5] is road (2)")


func _test_collision_matches_props_trees() -> void:
	print("_test_collision_matches_props_trees")
	var def = _load_definition()
	if def == null or not def.layers.has("collision") or not def.layers.has("props"):
		_check(false, "collision/props consistency (skipped — could not load)")
		return
	var props: Array     = def.layers["props"]
	var collision: Array = def.layers["collision"]
	# Row 1, col 0: tree (props=3) → blocked (collision=1)
	_check(props[1][0] == 3,     "props[1][0] is a tree (3)")
	_check(collision[1][0] == 1, "collision[1][0] is blocked (1)")
	# Row 0, col 0: no prop (props=0) → passable (collision=0)
	_check(props[0][0] == 0,     "props[0][0] is empty (0)")
	_check(collision[0][0] == 0, "collision[0][0] is passable (0)")


func _test_trigger_cell_is_dictionary() -> void:
	print("_test_trigger_cell_is_dictionary")
	var def = _load_definition()
	if def == null or not def.layers.has("triggers"):
		_check(false, "trigger cell type (skipped — could not load)")
		return
	var triggers: Array = def.layers["triggers"]
	# Row 4, col 3 should be a trigger dictionary
	_check(triggers[4][3] is Dictionary, "triggers[4][3] is a Dictionary")


func _test_trigger_has_type_and_encounter_id() -> void:
	print("_test_trigger_has_type_and_encounter_id")
	var def = _load_definition()
	if def == null or not def.layers.has("triggers"):
		_check(false, "trigger fields (skipped — could not load)")
		return
	var triggers: Array = def.layers["triggers"]
	var trigger = triggers[4][3]
	if not trigger is Dictionary:
		_check(false, "trigger type field (skipped — cell is not a Dictionary)")
		_check(false, "trigger encounter_id field (skipped — cell is not a Dictionary)")
		return
	_check(trigger.has("type"),         "trigger has 'type' key")
	_check(trigger["type"] == "combat_start",
		"trigger type is 'combat_start'")
	_check(trigger.has("encounter_id"), "trigger has 'encounter_id' key")
	_check(trigger["encounter_id"] == "bandit_ambush",
		"trigger encounter_id is 'bandit_ambush'")
