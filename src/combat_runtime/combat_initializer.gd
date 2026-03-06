## CombatInitializer
## Combat runtime class — extends Node.
## Handles combat initialization: rolls initiative via the rules engine,
## sorts the turn order, and emits combat_ready with the result.
##
## Architecture: calls rules engine (InitiativeRoller). No 5e math here.
## Emits combat_ready(turn_order, positions) when initialization completes.
class_name CombatInitializer
extends Node

const InitiativeRollerClass = preload("res://rules_engine/core/initiative.gd")
const DiceRollerClass = preload("res://rules_engine/core/dice_roller.gd")

## Emitted once initiative is rolled and the turn order is determined.
## turn_order : Array of Dictionaries (initiative results, sorted descending).
##              Each entry contains: { "id", "roll", "modifier", "total", "dex_score" }
## positions  : Dictionary mapping actor id (String) → Vector2i grid position.
signal combat_ready(turn_order: Array, positions: Dictionary)


## Begin combat with the given actors and their starting grid positions.
##
## actors    : Array of Dictionaries, each with:
##   "id"        : String — unique actor identifier
##   "dex_score" : int    — DEX ability score (used for initiative)
##
## positions : Dictionary mapping actor id (String) → Vector2i grid position.
##
## roller    : DiceRoller instance (inject a seeded roller for deterministic tests).
##
## Returns a Dictionary:
##   "turn_order" : Array      — sorted initiative results (highest total first)
##   "positions"  : Dictionary — actor id → Vector2i grid position (preserved from input)
func initialize(actors: Array, positions: Dictionary, roller: DiceRollerClass) -> Dictionary:
	var ir := InitiativeRollerClass.new()
	var turn_order: Array = ir.roll_for_combatants(actors, roller)
	var result: Dictionary = {
		"turn_order": turn_order,
		"positions": positions,
	}
	combat_ready.emit(turn_order, positions)
	return result
