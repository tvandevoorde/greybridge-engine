## test_combat_grid.gd
## Unit tests for CombatGrid (src/rules_engine/core/combat_grid.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_combat_grid.gd
extends SceneTree

const CombatGrid = preload("res://rules_engine/core/combat_grid.gd")

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
	_test_place_combatant_succeeds()
	_test_place_combatant_fails_if_position_occupied()
	_test_place_combatant_fails_if_combatant_already_placed()
	_test_remove_combatant_succeeds()
	_test_remove_combatant_fails_if_not_present()
	_test_move_combatant_succeeds()
	_test_move_combatant_fails_if_target_occupied()
	_test_move_combatant_fails_if_not_on_grid()
	_test_is_occupied()
	_test_get_combatant_at()
	_test_get_position()
	_test_has_combatant()
	_test_is_adjacent_cardinal()
	_test_is_adjacent_diagonal()
	_test_is_adjacent_self_is_false()
	_test_is_adjacent_far_tiles_false()
	_test_distance_ft_cardinal()
	_test_distance_ft_diagonal_chebyshev()
	_test_distance_ft_same_tile()
	_test_is_within_reach()
	_test_feet_per_tile_constant()


# ---------------------------------------------------------------------------
# place_combatant
# ---------------------------------------------------------------------------
func _test_place_combatant_succeeds() -> void:
	print("_test_place_combatant_succeeds")
	var grid := CombatGrid.new()
	_check(grid.place_combatant("a", Vector2i(0, 0)) == true, "place succeeds on empty grid")
	_check(grid.is_occupied(Vector2i(0, 0)), "tile is now occupied")
	_check(grid.get_position("a") == Vector2i(0, 0), "position recorded correctly")


func _test_place_combatant_fails_if_position_occupied() -> void:
	print("_test_place_combatant_fails_if_position_occupied")
	var grid := CombatGrid.new()
	grid.place_combatant("a", Vector2i(1, 1))
	_check(grid.place_combatant("b", Vector2i(1, 1)) == false, "cannot place on occupied tile")
	_check(grid.get_combatant_at(Vector2i(1, 1)) == "a", "original occupant unchanged")


func _test_place_combatant_fails_if_combatant_already_placed() -> void:
	print("_test_place_combatant_fails_if_combatant_already_placed")
	var grid := CombatGrid.new()
	grid.place_combatant("a", Vector2i(0, 0))
	_check(grid.place_combatant("a", Vector2i(1, 1)) == false, "cannot place same combatant twice")
	_check(grid.get_position("a") == Vector2i(0, 0), "original position unchanged")


# ---------------------------------------------------------------------------
# remove_combatant
# ---------------------------------------------------------------------------
func _test_remove_combatant_succeeds() -> void:
	print("_test_remove_combatant_succeeds")
	var grid := CombatGrid.new()
	grid.place_combatant("a", Vector2i(2, 3))
	_check(grid.remove_combatant("a") == true, "remove returns true")
	_check(grid.has_combatant("a") == false, "combatant no longer on grid")
	_check(grid.is_occupied(Vector2i(2, 3)) == false, "tile no longer occupied")


func _test_remove_combatant_fails_if_not_present() -> void:
	print("_test_remove_combatant_fails_if_not_present")
	var grid := CombatGrid.new()
	_check(grid.remove_combatant("ghost") == false, "remove unknown combatant returns false")


# ---------------------------------------------------------------------------
# move_combatant
# ---------------------------------------------------------------------------
func _test_move_combatant_succeeds() -> void:
	print("_test_move_combatant_succeeds")
	var grid := CombatGrid.new()
	grid.place_combatant("a", Vector2i(0, 0))
	_check(grid.move_combatant("a", Vector2i(1, 0)) == true, "move succeeds to empty tile")
	_check(grid.get_position("a") == Vector2i(1, 0), "new position recorded")
	_check(grid.is_occupied(Vector2i(1, 0)), "new tile occupied")
	_check(grid.is_occupied(Vector2i(0, 0)) == false, "old tile freed")


func _test_move_combatant_fails_if_target_occupied() -> void:
	print("_test_move_combatant_fails_if_target_occupied")
	var grid := CombatGrid.new()
	grid.place_combatant("a", Vector2i(0, 0))
	grid.place_combatant("b", Vector2i(1, 0))
	_check(grid.move_combatant("a", Vector2i(1, 0)) == false, "cannot move onto occupied tile")
	_check(grid.get_position("a") == Vector2i(0, 0), "position unchanged after failed move")


func _test_move_combatant_fails_if_not_on_grid() -> void:
	print("_test_move_combatant_fails_if_not_on_grid")
	var grid := CombatGrid.new()
	_check(grid.move_combatant("ghost", Vector2i(0, 0)) == false, "move unknown combatant returns false")


# ---------------------------------------------------------------------------
# is_occupied / get_combatant_at
# ---------------------------------------------------------------------------
func _test_is_occupied() -> void:
	print("_test_is_occupied")
	var grid := CombatGrid.new()
	_check(grid.is_occupied(Vector2i(5, 5)) == false, "empty tile not occupied")
	grid.place_combatant("a", Vector2i(5, 5))
	_check(grid.is_occupied(Vector2i(5, 5)) == true, "tile occupied after placement")
	grid.remove_combatant("a")
	_check(grid.is_occupied(Vector2i(5, 5)) == false, "tile freed after removal")


func _test_get_combatant_at() -> void:
	print("_test_get_combatant_at")
	var grid := CombatGrid.new()
	_check(grid.get_combatant_at(Vector2i(0, 0)) == "", "empty tile returns empty string")
	grid.place_combatant("fighter", Vector2i(0, 0))
	_check(grid.get_combatant_at(Vector2i(0, 0)) == "fighter", "occupied tile returns combatant id")


# ---------------------------------------------------------------------------
# get_position / has_combatant
# ---------------------------------------------------------------------------
func _test_get_position() -> void:
	print("_test_get_position")
	var grid := CombatGrid.new()
	_check(grid.get_position("nobody") == CombatGrid.INVALID_POSITION, "unknown combatant returns INVALID_POSITION")
	grid.place_combatant("a", Vector2i(3, 4))
	_check(grid.get_position("a") == Vector2i(3, 4), "correct position returned")


func _test_has_combatant() -> void:
	print("_test_has_combatant")
	var grid := CombatGrid.new()
	_check(grid.has_combatant("a") == false, "not present initially")
	grid.place_combatant("a", Vector2i(0, 0))
	_check(grid.has_combatant("a") == true, "present after placement")
	grid.remove_combatant("a")
	_check(grid.has_combatant("a") == false, "not present after removal")


# ---------------------------------------------------------------------------
# is_adjacent
# ---------------------------------------------------------------------------
func _test_is_adjacent_cardinal() -> void:
	print("_test_is_adjacent_cardinal")
	var grid := CombatGrid.new()
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(1, 0)) == true, "east is adjacent")
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(-1, 0)) == true, "west is adjacent")
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(0, 1)) == true, "south is adjacent")
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(0, -1)) == true, "north is adjacent")


func _test_is_adjacent_diagonal() -> void:
	print("_test_is_adjacent_diagonal")
	var grid := CombatGrid.new()
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(1, 1)) == true, "SE diagonal is adjacent")
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(-1, -1)) == true, "NW diagonal is adjacent")
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(1, -1)) == true, "NE diagonal is adjacent")
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(-1, 1)) == true, "SW diagonal is adjacent")


func _test_is_adjacent_self_is_false() -> void:
	print("_test_is_adjacent_self_is_false")
	var grid := CombatGrid.new()
	_check(grid.is_adjacent(Vector2i(2, 2), Vector2i(2, 2)) == false, "tile is not adjacent to itself")


func _test_is_adjacent_far_tiles_false() -> void:
	print("_test_is_adjacent_far_tiles_false")
	var grid := CombatGrid.new()
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(2, 0)) == false, "2 tiles apart not adjacent")
	_check(grid.is_adjacent(Vector2i(0, 0), Vector2i(2, 2)) == false, "2 diagonal tiles not adjacent")


# ---------------------------------------------------------------------------
# distance_ft
# ---------------------------------------------------------------------------
func _test_distance_ft_cardinal() -> void:
	print("_test_distance_ft_cardinal")
	var grid := CombatGrid.new()
	_check(grid.distance_ft(Vector2i(0, 0), Vector2i(1, 0)) == 5, "1 tile east = 5 ft")
	_check(grid.distance_ft(Vector2i(0, 0), Vector2i(6, 0)) == 30, "6 tiles east = 30 ft")
	_check(grid.distance_ft(Vector2i(0, 0), Vector2i(0, 4)) == 20, "4 tiles south = 20 ft")


func _test_distance_ft_diagonal_chebyshev() -> void:
	print("_test_distance_ft_diagonal_chebyshev")
	var grid := CombatGrid.new()
	# Chebyshev: max(|dx|, |dy|) — diagonal costs same as cardinal (5-5-5 rule)
	_check(grid.distance_ft(Vector2i(0, 0), Vector2i(1, 1)) == 5, "diagonal 1,1 = 5 ft (5-5-5 rule)")
	_check(grid.distance_ft(Vector2i(0, 0), Vector2i(3, 4)) == 20, "diagonal 3,4 = 20 ft (max=4)")
	_check(grid.distance_ft(Vector2i(0, 0), Vector2i(4, 3)) == 20, "diagonal 4,3 = 20 ft (max=4)")
	_check(grid.distance_ft(Vector2i(0, 0), Vector2i(2, 2)) == 10, "diagonal 2,2 = 10 ft")


func _test_distance_ft_same_tile() -> void:
	print("_test_distance_ft_same_tile")
	var grid := CombatGrid.new()
	_check(grid.distance_ft(Vector2i(5, 5), Vector2i(5, 5)) == 0, "same tile = 0 ft")


# ---------------------------------------------------------------------------
# is_within_reach
# ---------------------------------------------------------------------------
func _test_is_within_reach() -> void:
	print("_test_is_within_reach")
	var grid := CombatGrid.new()
	var origin := Vector2i(0, 0)
	# Standard melee reach: 5 ft (1 tile)
	_check(grid.is_within_reach(origin, Vector2i(0, 0), 5) == true, "same tile within 5 ft reach")
	_check(grid.is_within_reach(origin, Vector2i(1, 0), 5) == true, "adjacent tile within 5 ft reach")
	_check(grid.is_within_reach(origin, Vector2i(1, 1), 5) == true, "diagonal adjacent within 5 ft reach (Chebyshev)")
	_check(grid.is_within_reach(origin, Vector2i(2, 0), 5) == false, "2 tiles away exceeds 5 ft reach")
	# 10 ft reach
	_check(grid.is_within_reach(origin, Vector2i(2, 0), 10) == true, "2 tiles away within 10 ft reach")
	_check(grid.is_within_reach(origin, Vector2i(3, 0), 10) == false, "3 tiles away exceeds 10 ft reach")


# ---------------------------------------------------------------------------
# FEET_PER_TILE constant
# ---------------------------------------------------------------------------
func _test_feet_per_tile_constant() -> void:
	print("_test_feet_per_tile_constant")
	_check(CombatGrid.FEET_PER_TILE == 5, "1 tile equals 5 feet")
