## MapDefinition
## Pure data class representing a loaded map definition.
##
## Architecture: NOT a Node. Contains no UI, no scene references.
## Holds the structured data parsed from a map JSON file.
class_name MapDefinition


## Path or identifier referencing the tileset to use for rendering.
## Example: "res://content/tilesets/road.tres"
var tileset_ref: String = ""

## Width of the map in tiles.
var map_width: int = 0

## Height of the map in tiles.
var map_height: int = 0

## Layer data keyed by layer name.
## Supported layer names: "ground", "props", "collision", "triggers"
## Each value is an Array of rows (Array of Array), with length == map_height,
## and each row having length == map_width.
##   ground   : Array[Array[int]]  — tile IDs (0 = empty)
##   props    : Array[Array[int]]  — prop tile IDs (0 = empty)
##   collision: Array[Array[int]]  — 0 = passable, 1 = blocked
##   triggers : Array[Array]       — null = no trigger, Dictionary = trigger data
var layers: Dictionary = {}


## Returns true when the definition contains all required fields.
func is_valid() -> bool:
	if tileset_ref.is_empty():
		return false
	if map_width <= 0 or map_height <= 0:
		return false
	return true
