## EnemyTurnController
## Combat runtime class — extends Node.
## Executes a single enemy combatant's turn using the rules-engine AI decision
## engine, movement resolver, attack resolver, and damage calculator.
##
## Responsibilities:
##   - Asks EnemyAI (rules_engine) for the turn decision.
##   - Validates and applies movement to the grid via MovementResolver.
##   - Resolves the attack roll and damage via AttackResolver and DamageCalculator.
##   - Spends action and movement slots in the ActionEconomy.
##   - Emits signals so the UI and other runtime systems can react.
##
## This class contains no 5e math.  All game-logic calculations are delegated
## to the rules engine.
class_name EnemyTurnController
extends Node

const EnemyAIClass          = preload("res://rules_engine/core/enemy_ai.gd")
const MovementResolverClass = preload("res://rules_engine/core/movement_resolver.gd")
const AttackResolverClass   = preload("res://rules_engine/core/attack_resolver.gd")
const DamageCalculatorClass = preload("res://rules_engine/core/damage_calculator.gd")
const DiceRollerClass       = preload("res://rules_engine/core/dice_roller.gd")
const CombatGridClass       = preload("res://rules_engine/core/combat_grid.gd")
const ActionEconomyClass    = preload("res://rules_engine/core/action_economy.gd")

## Emitted once the movement phase of the enemy turn is resolved.
## enemy_id : String — the acting enemy.
## path     : Array  — tiles visited in order (empty if no movement occurred).
## cost_ft  : int    — movement cost in feet (0 if no movement occurred).
signal enemy_moved(enemy_id: String, path: Array, cost_ft: int)

## Emitted once the attack phase of the enemy turn is resolved.
## attacker_id : String — the acting enemy.
## target_id   : String — the targeted combatant.
## attack_type : String — "melee" or "ranged".
## hit         : bool   — true if the attack hit.
## critical    : bool   — true if the roll was a natural 20.
## damage      : int    — damage dealt (0 on a miss).
signal enemy_attacked(
	attacker_id: String,
	target_id: String,
	attack_type: String,
	hit: bool,
	critical: bool,
	damage: int
)

## Emitted after all phases (movement and optional attack) of the turn are done.
## enemy_id : String — the enemy whose turn just finished.
signal turn_complete(enemy_id: String)

var _ai: EnemyAIClass
var _movement_resolver: MovementResolverClass
var _attack_resolver: AttackResolverClass


func _init() -> void:
	_ai = EnemyAIClass.new()
	_movement_resolver = MovementResolverClass.new()
	_attack_resolver = AttackResolverClass.new()


## Execute the full AI turn for one enemy.
##
## enemy_id    : String — ID of the enemy taking the turn (must be on the grid).
## enemy_stats : Dictionary with keys (all optional; defaults shown):
##   "melee_range_ft"   : int    — melee reach in feet (default 5).
##   "ranged_range_ft"  : int    — ranged range in feet; 0 means no ranged (default 0).
##   "speed_ft"         : int    — movement speed in feet (default 30).
##   "ability_modifier" : int    — STR or DEX modifier for attack and damage (default 0).
##   "proficiency_bonus": int    — proficiency bonus added to attack rolls (default 2).
##   "damage_dice_count": int    — number of damage dice, e.g. 1 for "1d6" (default 1).
##   "damage_dice_faces": int    — die size, e.g. 6 for "1d6" (default 6).
##   "damage_type"      : String — SRD damage type label, e.g. "slashing" (default "bludgeoning").
## participants : Array of Dictionaries describing all combatants in the encounter:
##   { "id": String, "side": String, "current_hp": int, "armor_class": int }
##   Living player-side entries (current_hp > 0) are treated as attack targets.
## grid         : CombatGrid  — current grid state; mutated when movement occurs.
## economy      : ActionEconomy — the enemy's current turn economy; mutated.
## roller       : DiceRoller  — injected for determinism in tests.
func execute_turn(
	enemy_id: String,
	enemy_stats: Dictionary,
	participants: Array,
	grid: CombatGridClass,
	economy: ActionEconomyClass,
	roller: DiceRollerClass,
) -> void:
	# Build the candidates list with grid positions for the AI.
	var candidates: Array = []
	for p in participants:
		var cid: String = p.get("id", "")
		if cid == enemy_id:
			continue
		var pos: Vector2i = grid.get_position(cid)
		if pos == CombatGridClass.INVALID_POSITION:
			continue
		candidates.append({
			"id": cid,
			"position": pos,
			"side": p.get("side", ""),
			"current_hp": p.get("current_hp", 0),
		})

	# Ask the AI for the turn decision.
	var decision: Dictionary = _ai.decide(enemy_id, enemy_stats, candidates, grid, economy)

	# --- Movement phase ---
	var move_path: Array = decision.get("move_path", [])
	var actual_path: Array = []
	var move_cost_ft: int = 0
	if move_path.size() > 0 and economy.movement_remaining_ft > 0:
		var enemy_pos: Vector2i = grid.get_position(enemy_id)
		var move_result: Dictionary = _movement_resolver.resolve(
			move_path,
			enemy_pos,
			economy.movement_remaining_ft,
			grid,
			enemy_id,
			[]  # Opportunity Attack resolution not in scope for basic V1 AI movement
		)
		var tiles_moved: int = move_result.get("tiles_moved", 0)
		move_cost_ft = move_result.get("cost_ft", 0)
		if tiles_moved > 0:
			var end_pos: Vector2i = move_path[tiles_moved - 1]
			grid.move_combatant(enemy_id, end_pos)
			economy.use_movement(move_cost_ft)
			actual_path = move_path.slice(0, tiles_moved)

	enemy_moved.emit(enemy_id, actual_path, move_cost_ft)

	# --- Attack phase ---
	var attack_type: String = decision.get("attack_type", "none")
	var target_id: String = decision.get("target_id", "")

	if attack_type != "none" and target_id != "" and economy.is_action_available():
		# Look up the target's AC from participants.
		var target_ac: int = 10
		for p in participants:
			if p.get("id", "") == target_id:
				target_ac = p.get("armor_class", 10)
				break

		var d20_roll: int = roller.roll(20)
		var ability_mod: int = enemy_stats.get("ability_modifier", 0)
		var prof_bonus: int = enemy_stats.get("proficiency_bonus", 2)
		var attack_result = _attack_resolver.resolve(d20_roll, ability_mod, prof_bonus, target_ac)

		var damage: int = 0
		if attack_result.hit:
			var dice_count: int = enemy_stats.get("damage_dice_count", 1)
			var dice_faces: int = enemy_stats.get("damage_dice_faces", 6)
			var dmg_type: String = enemy_stats.get("damage_type", "bludgeoning")
			# Critical hit: double the damage dice per 5e SRD.
			if attack_result.critical:
				dice_count *= 2
			var dmg_result: Dictionary = DamageCalculatorClass.calculate(
				dice_count, dice_faces, dmg_type, roller, ability_mod
			)
			damage = dmg_result.get("amount", 0)

		economy.use_action()
		enemy_attacked.emit(
			enemy_id, target_id, attack_type,
			attack_result.hit, attack_result.critical, damage
		)

	turn_complete.emit(enemy_id)
