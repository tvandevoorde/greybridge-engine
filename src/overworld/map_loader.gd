## MapLoader
## Pure utility class for loading MapDefinition from Dictionary or JSON file.
##
## Architecture: pure GDScript class — NOT a Node. No scene access.
extends RefCounted

const MapDefinitionClass = preload("res://overworld/map_definition.gd")


## Constructs a MapDefinition from a Dictionary.
## Useful for tests and in-memory construction.
static func load_from_dict(data: Dictionary) -> MapDefinitionClass:
	return MapDefinitionClass.from_dict(data)


## Loads a MapDefinition from a JSON file at [param path].
## [param path] may be a "res://" path or an absolute filesystem path.
## Returns null if the file cannot be found, read, or parsed.
static func load_from_path(path: String) -> MapDefinitionClass:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json_text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		return null
	if not json.data is Dictionary:
		return null
	return MapDefinitionClass.from_dict(json.data)
