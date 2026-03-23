## MapLoader
## Parses map definition JSON into MapDefinition instances.
##
## Architecture: NOT a Node. Pure logic — no UI, no scene references.
## Accepts raw JSON text or a pre-parsed Dictionary.
class_name MapLoader

const MapDefinitionClass = preload("res://rules_engine/core/map_definition.gd")

## Parse a map definition from a pre-parsed Dictionary.
##
## Required keys: "tileset_ref" (String), "map_width" (int), "map_height" (int)
## Optional key:  "layers" (Dictionary — layer_name → Array of rows)
##
## Returns a MapDefinition on success, or null when required fields are absent
## or have invalid types.
func load_from_dict(data: Dictionary):
	if not data.has("tileset_ref") or not data.has("map_width") or not data.has("map_height"):
		return null
	if not data["tileset_ref"] is String:
		return null
	if not data["map_width"] is float and not data["map_width"] is int:
		return null
	if not data["map_height"] is float and not data["map_height"] is int:
		return null

	var def := MapDefinitionClass.new()
	def.tileset_ref = data["tileset_ref"]
	def.map_width   = int(data["map_width"])
	def.map_height  = int(data["map_height"])

	if data.has("layers") and data["layers"] is Dictionary:
		def.layers = data["layers"].duplicate(true)

	return def


## Parse a map definition from a JSON string.
##
## Returns a MapDefinition on success, or null when the JSON is malformed
## or required fields are missing.
func load_from_json(json_text: String):
	var json := JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		return null
	var data = json.data
	if not data is Dictionary:
		return null
	return load_from_dict(data)
