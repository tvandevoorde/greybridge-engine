## TurnLifecycleController
## Combat runtime class — extends Node.
## Orchestrates the strict per-actor turn lifecycle for a combat encounter,
## enforcing the D&D 5e SRD action economy.
##
## Lifecycle per actor turn:
##   IDLE → START → MOVEMENT → ACTION → BONUS_ACTION → END → (advance) → IDLE
##
## begin_turn()  kicks off the lifecycle for the current actor.
## end_turn()    finalises the turn, fires the END hook, and advances to the next actor.
##
## Signals are emitted at each phase change for the UI and other systems to react.
## The ActionEconomy for the current actor is reset (start_turn()) at the top of each turn.
class_name TurnLifecycleController
extends Node

const CombatStateManagerClass = preload("res://combat_runtime/combat_state_manager.gd")
const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")

## The ordered phases of a single combatant's turn.
enum TurnPhase {
	IDLE,
	START,
	MOVEMENT,
	ACTION,
	BONUS_ACTION,
	END,
}

## Emitted when the START-of-turn hook fires for the current actor.
## combatant_id : String — ID of the actor whose turn begins.
## round        : int    — current round number.
signal turn_started(combatant_id: String, round: int)

## Emitted whenever the active phase changes.
## phase        : TurnPhase — the newly entered phase.
## combatant_id : String    — ID of the active actor.
signal phase_changed(phase: TurnPhase, combatant_id: String)

## Emitted when the END-of-turn hook fires (before advancing to the next actor).
## combatant_id : String — ID of the actor whose turn is ending.
signal turn_ended(combatant_id: String)

## Emitted after the state manager advances to the next actor.
## new_combatant_id : String — ID of the actor who now holds the turn.
## round            : int    — current round number (may have incremented).
signal turn_advanced(new_combatant_id: String, round: int)

## Emitted when the initiative order cycles back to index 0 and a new round begins.
## round : int — the new (incremented) round number.
signal round_started(round: int)

var _state_manager: CombatStateManagerClass
var _action_economies: Dictionary  # combatant_id: String → ActionEconomy
var _current_phase: TurnPhase = TurnPhase.IDLE


## Attach the controller to a CombatStateManager and per-actor ActionEconomy map.
##
## state_manager    : CombatStateManager — provides current actor ID and round.
## action_economies : Dictionary mapping combatant_id (String) → ActionEconomy.
##                    Each actor that will take a turn must have an entry here.
func setup(state_manager: CombatStateManagerClass, action_economies: Dictionary) -> void:
	_state_manager = state_manager
	_action_economies = action_economies


## Begin the turn for the current actor (as reported by the state manager).
##
## Lifecycle: IDLE → START → MOVEMENT
##   1. Resets the actor's ActionEconomy via start_turn().
##   2. Emits turn_started (START-of-turn hook).
##   3. Emits phase_changed for START, then for MOVEMENT.
##
## Has no effect when no combat is active or the controller has not been set up.
func begin_turn() -> void:
	if _state_manager == null or not _state_manager.is_active():
		return

	var combatant_id: String = _state_manager.get_current_combatant_id()
	var round: int = _state_manager.get_round()

	# Reset the actor's action economy for this turn.
	if _action_economies.has(combatant_id):
		_action_economies[combatant_id].start_turn()

	# START phase — start-of-turn hook.
	_set_phase(TurnPhase.START, combatant_id)
	turn_started.emit(combatant_id, round)

	# Automatically enter MOVEMENT phase.
	_set_phase(TurnPhase.MOVEMENT, combatant_id)


## Finalise the current actor's turn and advance to the next actor.
##
## Lifecycle: current_phase → END → (advance) → IDLE
##   1. Emits phase_changed for END.
##   2. Emits turn_ended (END-of-turn hook).
##   3. Calls CombatStateManager.advance_turn().
##   4. Emits turn_advanced with the new actor's ID and updated round.
##   5. Emits round_started if the initiative order cycled into a new round.
##   6. Resets phase to IDLE.
##
## Has no effect when no combat is active or the controller is already IDLE.
func end_turn() -> void:
	if _state_manager == null or not _state_manager.is_active():
		return
	if _current_phase == TurnPhase.IDLE:
		return

	var ending_combatant_id: String = _state_manager.get_current_combatant_id()
	var prev_round: int = _state_manager.get_round()

	# END phase — end-of-turn hook.
	_set_phase(TurnPhase.END, ending_combatant_id)
	turn_ended.emit(ending_combatant_id)

	# Advance to the next actor in the initiative order.
	_state_manager.advance_turn()

	var new_combatant_id: String = _state_manager.get_current_combatant_id()
	var new_round: int = _state_manager.get_round()

	_current_phase = TurnPhase.IDLE
	turn_advanced.emit(new_combatant_id, new_round)

	# Emit round_started when the initiative order has cycled into a new round.
	if new_round > prev_round:
		round_started.emit(new_round)


## Returns the phase the controller is currently in.
func get_current_phase() -> TurnPhase:
	return _current_phase


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _set_phase(phase: TurnPhase, combatant_id: String) -> void:
	_current_phase = phase
	phase_changed.emit(phase, combatant_id)
