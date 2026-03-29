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
## UI layer class — extends Node.
## Displays a contextual interaction hint when the player is adjacent to a
## registered interactable object.
##
## Responsibilities:
##   - Track whether a prompt is currently visible.
##   - Record the handler_id of the currently displayed interactable.
##   - Expose show_prompt() / hide_prompt() entry points to be called from
##     InteractionController signal handlers.
##
## This class never calculates game logic, reads input, or queries the grid.
## Connect InteractionController.prompt_show  → show_prompt(handler_id).
## Connect InteractionController.prompt_hide  → hide_prompt().
class_name InteractionPrompt
extends Node

## True while a prompt is being displayed to the player.
var is_visible: bool = false

## The handler_id of the interactable whose prompt is currently shown.
## Empty string when is_visible is false.
var current_handler_id: String = ""


## Display the interaction prompt for the given interactable handler.
## Call this when InteractionController emits prompt_show.
func show_prompt(handler_id: String) -> void:
	is_visible = true
	current_handler_id = handler_id


## Hide the prompt and clear the handler reference.
## Dismiss the currently displayed prompt.
## Call this when InteractionController emits prompt_hide.
func hide_prompt() -> void:
	is_visible = false
	current_handler_id = ""
