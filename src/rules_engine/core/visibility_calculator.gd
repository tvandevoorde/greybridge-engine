## VisibilityCalculator
## Pure logic class that computes visible tiles around a center position.
## Uses Chebyshev distance (square-shaped area): all tiles where
## max(|dx|, |dy|) <= radius are considered visible.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name VisibilityCalculator
extends RefCounted


## Returns all grid tiles within [param radius] Chebyshev steps of [param center].
## The center tile itself is always included; a radius of 0 returns only the center.
##
## center : Vector2i — the player's current grid position.
## radius : int      — visibility radius in tile units (must be >= 0).
func compute_visible_tiles(center: Vector2i, radius: int) -> Array[Vector2i]:
	var visible: Array[Vector2i] = []
	var r: int = maxi(radius, 0)
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			visible.append(Vector2i(center.x + dx, center.y + dy))
	return visible
