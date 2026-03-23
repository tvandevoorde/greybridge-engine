## InteractionPrompt
## UI class that tracks the visibility state of the overworld interaction
## prompt and the handler it is currently pointing at.
##
## Architecture: extends Node. Dumb UI — contains no game logic.
## Connect to NpcController.dialogue_started or proximity signals from the
## scene layer to drive show_prompt / hide_prompt.
class_name InteractionPrompt
extends Node

## True when the interaction prompt is visible.
var is_visible: bool = false

## The handler id (e.g. NPC npc_id) the prompt is currently associated with.
var current_handler_id: String = ""


## Show the prompt for the given [param handler_id].
func show_prompt(handler_id: String) -> void:
	is_visible = true
	current_handler_id = handler_id


## Hide the prompt and clear the handler reference.
func hide_prompt() -> void:
	is_visible = false
	current_handler_id = ""
