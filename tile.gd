# Tile.gd
extends Node2D

# assigned by main scene when instancing
var parent

# pathfinder singleton
var pathfinder: Node

# will point at your preview Line2D
var path_line: Line2D

@onready var collision_polygon_2D = $Area2D/CollisionPolygon2D
@onready var area2D               = $Area2D
@onready var sprite2D_1           = $Sprite2D
@onready var sprite2D_2           = $Sprite2D2
@onready var label                = $Label

@export var tile_side_length: float = 50.0

var id
var tile_key
var contains_unit: bool = false
var is_selected:   bool = false
var image
var in_sight = false


func _ready():
	pathfinder = PathFinder
	# since PathLine2D is a direct child of the same Node2D…
	if parent.has_node("PathLine2D"):
		path_line = parent.get_node("PathLine2D")
	else:
		push_error("🛑 PathLine2D not found under %s" % parent.name)
		return


	#print("[Tile._ready] key=%s   path_line=%s" % [tile_key, path_line])

	# 3) wire up all your signals
	area2D.connect("input_event",   Callable(self, "_on_area2d_input_event"))
	area2D.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	area2D.connect("mouse_exited",  Callable(self, "_on_mouse_exited"))
	area2D.connect("area_entered",  Callable(self, "_on_area_2d_area_entered"))
	area2D.connect("area_exited",   Callable(self, "_on_area_2d_area_shape_entered"))

	# 4) draw the hex collision
	collision_polygon_2D.polygon = calculate_hexagon(tile_side_length)

	# 5) label it
	label.text = str(id)
	label.add_theme_color_override("font_color", Color.RED)


func calculate_hexagon(side_length: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(6):
		var ang = deg_to_rad(30 + 60 * i)
		verts.append(Vector2(cos(ang), sin(ang)) * side_length)
	return verts


func _on_mouse_entered():
	#print("▶ _on_mouse_entered on ", tile_key, " — selected_node is: ", parent.selected_node)
	var sel = parent.selected_node
	if sel and sel.is_in_group("Unit") and in_sight:
		var path = pathfinder.find_path(sel.current_tile_key, tile_key, sel)
		#print("   → computed path: ", path)
		_draw_preview(path)


func _draw_preview(path: Array) -> void:
	path_line.clear_points()
	path_line.width = 4
	path_line.default_color = Color.GREEN
	for key in path:
		# world‐space coords, straight from your tile_dictionary
		path_line.add_point(parent.tile_dictionary[key]["Position"])



# ─── CLICK → move if valid ───────────────────────────
func _on_area2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#print("[Tile._on_click] key=", tile_key)
		if not parent.tile_dictionary[tile_key]["In_sight"]:
			#print(" → not in sight")
			return
		else:
			_draw_preview([])
		
		parent.tile_clicked = true
		await get_tree().create_timer(0.1).timeout
		if parent.click_blocked:
			#print(" → click_blocked")
			return

		if parent.old_selected_node and parent.old_selected_node.is_in_group("Unit"):
			var u = parent.old_selected_node
			#print(" → attempt move: start=%s mp=%s mt=%s" %
				  #[u.current_tile_key, u.movement_points, u.move_type])
			var p = pathfinder.find_path(u.current_tile_key, tile_key, u)
			#print(" → path returned:", p)
			if p.size() > 0:
				#print(" → valid; moving")
				# move the unit:
				var count = 1
				for point in p.slice(1, p.size()):
					parent.update_fog(point, p[count - 1], u)
					print("Current point: ", point, ", Previous point: ", p[count - 1])
					count += 1
				
				u.position = position
				
				is_selected = true
				parent.selected_node = self
				parent.click_blocked = true
				
				# now consume movement:
				var total_cost := 0
				# skip index 0 because that's the start tile:
				for i in range(1, p.size()):
					total_cost += parent.tile_dictionary[p[i]]["Movement_cost"]
				u.stats_dictionary["Movement_points"] -= total_cost
				#print("   → spent %d MP, %d left" % [total_cost, u.movement_points])
			else:
				#print(" → invalid; not moving")
				_draw_preview([])



# ─── UNIT ENTER/EXIT for tracking current_tile_key ─────
func _on_area_2d_area_entered(area):
	if area.is_in_group("Unit"):
		contains_unit = true
		var u = area.get_parent()
		#print("[Tile._on_area_entered] setting current_tile_key to", tile_key)
		u.current_tile_key = tile_key


func _on_area_2d_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	if area.is_in_group("Unit"):
		contains_unit = false


func _on_area_2d_2_area_entered(area):
	if area.is_in_group("Unit"):
		var u = area.get_parent()
		parent.update_fog("Tile_%d" % id, u.previous_tile_id, u)
		u.previous_tile_id = id


func update_image(sprite_id: int, image_name: Texture2D, image_scale: Vector2, image_modulate):
	if sprite_id == 1:
		sprite2D_1.texture       = image_name
		sprite2D_1.self_modulate = image_modulate if image_modulate != null else Color(1,1,1,1)
		sprite2D_1.scale         = image_scale
	else:
		sprite2D_2.texture = image_name
		sprite2D_2.scale   = image_scale
