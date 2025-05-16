# Pathfinding/PathFinder.gd
extends Node

var tile_dictionary: Dictionary = {}

func init(_tile_dictionary: Dictionary) -> void:
	tile_dictionary = _tile_dictionary
	#print("[PathFinder.init] Got tile_dictionary with %d entries" % tile_dictionary.size())

func find_path(start_key: String, end_key: String, unit_node) -> Array:
	var move_type       = unit_node.move_type
	var movement_points = unit_node.movement_points
	#print("\n[PathFinder.find_path] from=%s to=%s mt=%s mp=%d" %
		#[start_key, end_key, move_type, movement_points])

	const INF = 1e9
	var open_set    : Array      = []
	var closed_set  : Dictionary = {}
	var g_score     : Dictionary = {}
	var came_from   : Dictionary = {}

	g_score[start_key] = 0
	open_set.append(start_key)

	while open_set.size() > 0:
		# pick the lowest‐g_score node
		var current = open_set[0]
		for key in open_set:
			if g_score.get(key, INF) < g_score[current]:
				current = key

		#print("  exploring:", current, "g_score=", g_score[current])

		if current == end_key:
			var path = _reconstruct_path(came_from, current)
			#print("  reconstructed path:", path)
			return path

		open_set.erase(current)
		closed_set[current] = true

		# check all 6 neighbours
		for i in range(1, 7):
			var nd = tile_dictionary[current]["Neighbour_%d" % i]
			var nk = nd.get("Tile_key")
			#print("    neighbour slot %d -> %s" % [i, nk])

			if nk == null:
				#print("      → null, skipping")
				continue

			var passable = nd.get("Passable", {}).get(move_type, false)
			var wall     = nd.get("Wall", false)
			var occ      = nd.get("Occupied", false)
			var cost     = nd.get("Movement_cost", INF)

			#print("      passable=%s wall=%s occupied=%s cost=%s" %
				#[passable, wall, occ, cost])

			if not passable or wall or occ:
				#print("      → impassable, skipping")
				continue

			var tentative_g = g_score[current] + cost
			if tentative_g > movement_points:
				#print("      → tentative_g %s > mp %s, skipping" %
					#[tentative_g, movement_points])
				continue

			if closed_set.has(nk) and tentative_g >= g_score.get(nk, INF):
				continue

			if not open_set.has(nk) or tentative_g < g_score.get(nk, INF):
				came_from[nk]   = current
				g_score[nk]     = tentative_g
				if not open_set.has(nk):
					open_set.append(nk)
					#print("      → adding to open_set:", nk)

	#print("  → no path found")
	return []


func _reconstruct_path(came_from: Dictionary, current: String) -> Array:
	var total_path := [current]
	while came_from.has(current):
		current = came_from[current]
		total_path.insert(0, current)
	return total_path
