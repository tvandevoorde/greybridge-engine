## AoETemplate
## Pure data class — no Node, no UI, no scene references.
## Defines constants and factory methods for building Area of Effect (AoE)
## template data objects consumed by AoEResolver.
##
## Templates describe a geometric region on the grid; call get_affected_tiles()
## to retrieve every grid tile that falls inside a given template.
##
## Grid convention: one tile = FEET_PER_TILE feet (5e SRD default 5 ft).
## Tile coordinates use Vector2i where (0, 0) is an arbitrary reference point.
class_name AoETemplate

## Template type identifiers — use these constants instead of raw strings.
const TYPE_CONE: String = "cone"
const TYPE_RADIUS: String = "radius"

## Feet represented by one grid tile (5e SRD standard).
const FEET_PER_TILE: int = 5


## Build a cone template data object.
##
## origin     : grid tile at the tip of the cone (the caster's tile)
## direction  : world-space direction the cone faces; will be normalised
## length_ft  : maximum reach of the cone in feet (e.g. 15 for Burning Hands)
##
## Cone geometry (SRD): at distance d along the axis the cone's half-width is
## also d, producing a 90-degree cone.  The origin tile itself is not included.
static func make_cone(origin: Vector2i, direction: Vector2, length_ft: int) -> Dictionary:
	return {
		"type": TYPE_CONE,
		"origin": origin,
		"direction": direction.normalized(),
		"length_ft": length_ft,
	}


## Build a radius (sphere/circle) template data object.
##
## center    : grid tile at the centre of the effect (e.g. impact point)
## radius_ft : radius of the area in feet (e.g. 20 for Fireball)
##
## The centre tile is always included.
static func make_radius(center: Vector2i, radius_ft: int) -> Dictionary:
	return {
		"type": TYPE_RADIUS,
		"center": center,
		"radius_ft": radius_ft,
	}


## Return every grid tile covered by the given template.
##
## template : a Dictionary produced by make_cone() or make_radius()
##
## Returns Array[Vector2i] — may be empty if length_ft / radius_ft is 0.
static func get_affected_tiles(template: Dictionary) -> Array[Vector2i]:
	match template["type"]:
		TYPE_CONE:
			return _cone_tiles(template)
		TYPE_RADIUS:
			return _radius_tiles(template)
	var empty: Array[Vector2i] = []
	return empty


## Internal — compute tiles for a radius template.
static func _radius_tiles(template: Dictionary) -> Array[Vector2i]:
	var center: Vector2i = template["center"]
	var radius_tiles: float = float(template["radius_ft"]) / float(FEET_PER_TILE)
	var bound: int = int(ceil(radius_tiles))
	var tiles: Array[Vector2i] = []
	for dx in range(-bound, bound + 1):
		for dy in range(-bound, bound + 1):
			# Include tile when its centre is within the radius (Euclidean).
			if (dx * dx + dy * dy) <= (radius_tiles * radius_tiles):
				tiles.append(Vector2i(center.x + dx, center.y + dy))
	return tiles


## Internal — compute tiles for a cone template.
## SRD cone: at projected distance d along the axis, half-width = d (90° cone).
static func _cone_tiles(template: Dictionary) -> Array[Vector2i]:
	var origin: Vector2i = template["origin"]
	var dir: Vector2 = template["direction"]
	var length_tiles: float = float(template["length_ft"]) / float(FEET_PER_TILE)
	var bound: int = int(ceil(length_tiles))
	var tiles: Array[Vector2i] = []
	for dx in range(-bound, bound + 1):
		for dy in range(-bound, bound + 1):
			# Projection onto the cone axis and perpendicular distance.
			var proj: float = dx * dir.x + dy * dir.y
			# Must be strictly in front of origin and within length.
			if proj <= 0.0 or proj > length_tiles:
				continue
			# Perpendicular distance must not exceed projection (90° half-angle).
			var perp: float = absf(dx * dir.y - dy * dir.x)
			if perp <= proj:
				tiles.append(Vector2i(origin.x + dx, origin.y + dy))
	return tiles
