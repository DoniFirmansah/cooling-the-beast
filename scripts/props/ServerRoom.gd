extends Node2D
class_name ServerRoom

## In 2.5D top-down perspective, a building cannot be treated as a single Y-sort point.
## Top wall & roof must sort behind the player when inside, but in front when outside to the north.
## South wall & doorway must sort in front of the player when inside, but behind when outside to the south.
## Floor & decals must always sort beneath all actors.
## Server racks must sort individually with their respective base footprints.
## Side walls must remain behind interior occupants to prevent horizontal body-slicing.
##
## This script automatically configures the Y-Sort hierarchy at runtime so depth sorting
## works 100% authentically in all directions, while letting developers easily edit
## the entire room as a single prefab scene in the Godot Editor!

func _ready() -> void:
	var parent_container = get_parent()
	if not parent_container or not parent_container is Node2D:
		return
	
	# If parent is an active Y-Sort container (e.g. YSortEntities in MainLevel):
	if (parent_container as Node2D).y_sort_enabled:
		_unroll_for_depth_sorting.call_deferred(parent_container as Node2D)

func _unroll_for_depth_sorting(parent_container: Node2D) -> void:
	# 1. Floor & Floor Decals: Force absolute negative Z-index so they NEVER cover actors
	if has_node("Floors"):
		var floors_node = get_node("Floors") as CanvasItem
		floors_node.z_as_relative = false
		floors_node.z_index = -1
	
	for decal_name in ["Pixel-cyberpunk-interior4", "Pixel-cyberpunk-interior5"]:
		if has_node(decal_name):
			var decal = get_node(decal_name) as CanvasItem
			decal.z_as_relative = false
			decal.z_index = -1

	# 2. Group bottom corner pillars and decorations into DownWallColl
	# so they share the exact front-wall depth sorting boundary!
	var down_wall = get_node_or_null("DownWallColl") as Node2D
	if down_wall:
		for pillar_name in ["RightPillar", "Pixel-cyberpunk-interior2"]:
			if has_node(pillar_name):
				var pillar = get_node(pillar_name) as Node2D
				var gpos = pillar.global_position
				pillar.reparent(down_wall)
				pillar.global_position = gpos

	# 3. Group roof trim into TopWallColl so it sorts with the north wall
	var top_wall = get_node_or_null("TopWallColl") as Node2D
	if top_wall:
		if has_node("Pixel-cyberpunk-interior"):
			var roof = get_node("Pixel-cyberpunk-interior") as Node2D
			var gpos = roof.global_position
			roof.reparent(top_wall)
			roof.global_position = gpos

	# 4. Side walls: Set their depth sorting origin further north (above interior space)
	# so they NEVER slice into the player's shoulders when the player is inside the room!
	var left_wall = get_node_or_null("LeftWallColl") as Node2D
	var right_wall = get_node_or_null("RightWallColl") as Node2D

	# 5. Collect all nodes that need individual Y-sort tracking in the world
	var ysort_targets: Array[Node2D] = []
	
	if left_wall:
		ysort_targets.append(left_wall)
	if right_wall:
		ysort_targets.append(right_wall)
	if top_wall:
		ysort_targets.append(top_wall)
		
	if has_node("Racks"):
		var racks_container = get_node("Racks")
		for rack in racks_container.get_children():
			if rack is Node2D:
				ysort_targets.append(rack)

	if down_wall:
		ysort_targets.append(down_wall)

	# Reparent each target directly into parent_container while preserving global_position
	for target in ysort_targets:
		var gpos = target.global_position
		target.reparent(parent_container)
		target.global_position = gpos

	# Side walls: anchor Y to top wall so they stay behind interior occupants
	if left_wall and top_wall:
		left_wall.position.y = top_wall.position.y - 10.0
	if right_wall and top_wall:
		right_wall.position.y = top_wall.position.y - 10.0
