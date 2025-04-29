extends Node2D

@onready var tile_scene: PackedScene = preload("res://tile.tscn")
@onready var unit_scene: PackedScene = preload("res://unit.tscn")
@onready var camera: Camera2D = $Camera2D

@onready var canvas_layer = $CanvasLayer
@onready var deck = $CanvasLayer/Deck
@onready var hand = $CanvasLayer/Hand
@onready var line_2D = $CanvasLayer/Line2D
@onready var line_2D2 = $CanvasLayer/Line2D2
@onready var line_2D3 = $CanvasLayer/Line2D3
@onready var line_2D4 = $CanvasLayer/Line2D4

var previous_window_size = DisplayServer.window_get_size()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		print("Window minimized!")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		print("Window maximized/restored!")

@export var grid_radius = 5

var max_sight_range = 5
var me_modulate = Color(0.5, 0.5, 0.5)

var viewport_visible_rect
var viewport_size
var camera_viewport_size

var hand_position

var tile_position_initial: Vector2
var tile_side_length
var tile_dictionary = {}
var tile_matrix = []
var tile_radius
var tile_diameter
var previously_seen_tiles = []

var selected_node
var old_selected_node

var image_dictionary = {}
var image_scale
var image_modulate

var unit_clicked = false
var tile_clicked = false
var click_blocked = false

var middle_row

var secant_global_position

var view_cone_dictionary = {}
var direction_to_step_dictionary = {
	"1" : [1, 0],
	"2" : [0, 1],
	"3" : [-1, 1],
	"4" : [-1, 0],
	"5" : [-1, -1],
	"6" : [0, -1],
}



func _ready():
	middle_row = grid_radius
	
	viewport_visible_rect = get_viewport().get_visible_rect()
	viewport_size = get_viewport_rect().size
	
	secant_global_position = Vector2(viewport_size.x / 2.0, viewport_size.y + hand.hand_radius - 100)
	
	camera.position = viewport_visible_rect.size / 2
	
	initialise_image_folder()
	initialise_grid()
	initialise_unit()
	initialise_view_angles()
	update_hand_position()

func _process(delta):
	var current_window_size = DisplayServer.window_get_size()
	if current_window_size != previous_window_size:
		previous_window_size = current_window_size
		update_hand_position()
		print("Window resized/maximized: ", current_window_size)
		hand.update_variables()

func _input(event):
	if event.is_action_pressed("m"):
		var mouse_pos = get_viewport().get_mouse_position()
		print("Mouse Position: ", mouse_pos)
	
	if event is InputEventMouseButton:
		if event.pressed:
			old_selected_node = selected_node
			await get_tree().create_timer(0).timeout
			if not unit_clicked and not tile_clicked:
				if event.button_index == MOUSE_BUTTON_LEFT:
					pass
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					if selected_node:
						selected_node.is_selected = false
						selected_node = null
			elif unit_clicked:
				click_blocked = true
			elif tile_clicked:
				click_blocked = false
			unit_clicked = false
			tile_clicked = false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera.zoom *= Vector2(1.1, 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera.zoom *= Vector2(0.9, 0.9)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		camera.position -= event.relative / camera.zoom

func update_hand_position():
	var viewport_size = get_viewport_rect().size
	
	line_2D.clear_points()
	line_2D.width = 3
	line_2D.default_color = Color.RED
	line_2D.add_point(Vector2(0, viewport_size.y - 100))
	line_2D.add_point(Vector2(viewport_size.x, viewport_size.y - 100))
	
	line_2D2.clear_points()
	line_2D2.width = 3
	line_2D2.default_color = Color.RED
	line_2D2.add_point(Vector2(viewport_size.x * 0.2, -viewport_size.y))
	line_2D2.add_point(Vector2(viewport_size.x * 0.2, 2 * viewport_size.y))
		
	line_2D3.clear_points()
	line_2D3.width = 3
	line_2D3.default_color = Color.RED
	line_2D3.add_point(Vector2(viewport_size.x * 0.8, -viewport_size.y))
	line_2D3.add_point(Vector2(viewport_size.x * 0.8, 2 * viewport_size.y))
	
	line_2D4.clear_points()
	line_2D4.width = 3
	line_2D4.default_color = Color.RED
	line_2D4.add_point(Vector2(0, viewport_size.y))
	line_2D4.add_point(Vector2(viewport_size.x, viewport_size.y))
	
	hand_position = Vector2(viewport_size.x / 2, viewport_size.y + hand.hand_radius)
	hand.hand_position = hand_position
	hand.position = hand_position

func initialise_image_folder():
	var texture_folder_path = "res://Images/"
	var dir = DirAccess.open(texture_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				var texture = load(texture_folder_path + file_name)
				var key = file_name.get_basename()
				image_dictionary[key] = texture
			file_name = dir.get_next()
		dir.list_dir_end()

func initialise_grid():
	tile_position_initial = viewport_visible_rect.size / 2
	
	var tile_initial = tile_scene.instantiate()
	tile_side_length = tile_initial.tile_side_length
	
	tile_radius = sqrt(pow(tile_side_length, 2) - pow(tile_side_length / 2, 2))
	tile_diameter = 2 * tile_radius
	
	var angle_degrees = 240
	var angle_radians = deg_to_rad(angle_degrees)
	var direction_initial = Vector2(cos(angle_radians), sin(angle_radians))
	var offset_initial = direction_initial * tile_radius * 2 * grid_radius
	var offset = offset_initial
	
	var count = 0
	var tile_number = 1
	var tile_types = ["plain", "mountain", "ruin", "water"]
	
	for i in range(grid_radius * 2 + 1):
		tile_matrix.append([])
		for j in range(grid_radius * 2 + 1 - abs(grid_radius - i)):
			var tile = tile_scene.instantiate()
			tile.parent = self
			tile.id = tile_number
			tile.tile_key = "Tile_" + str(tile_number)
			tile.position = tile_position_initial + offset
			add_child(tile)
			
			var tile_position = tile.position
			var type = tile_types[randi_range(0, 1)]
			var image
			var in_sight = false
			var height
			var passable_ground = false
			var passable_water = false
			var passable_air = false
			var movement_cost
			var range_bonus
			var defence_bonus
			
			if type == "plain":
				image = image_dictionary[type]
				image_modulate = Color(1, 0.5, 0)
				image_scale = Vector2(2 * tile_radius / 360, 2 * tile_radius / 360)
				height = 0
				passable_ground = true
				passable_water = false
				passable_air = true
				movement_cost = 1
				range_bonus = 0
				defence_bonus = 0
			elif type == "ruin":
				height = 0
				passable_ground = true
				passable_water = false
				passable_air = true
				movement_cost = 2
				range_bonus = 0
				defence_bonus = 1
			elif type == "mountain":
				image = image_dictionary[type]
				image_modulate = Color(0.5, 0.5, 0.5)
				image_scale = Vector2(2 * tile_radius / 360, 2 * tile_radius / 360)
				passable_ground = false
				passable_water = false
				passable_air = true
				height = 1
				movement_cost = 3
				range_bonus = 2
				defence_bonus = 2
			elif type == "water":
				passable_ground = false
				passable_water = true
				passable_air = true
				height = null
				movement_cost = null
				range_bonus = null
				defence_bonus = null
			
			tile.update_image(1, image, image_scale, image_modulate)
			
			var background_image = image_dictionary["green"]
			var background_image_scale = Vector2(0.02 + 2 * tile_radius / 360, 0.02 + 2 * tile_radius / 360)
			
			var tile_key = "Tile_" + str(tile_number)
			tile_dictionary[tile_key] = {
				"Node": tile,
				"ID": tile_number,
				"Tile_key": tile_key,
				"Index": Vector2(j, i),
				"Coordinates": Vector2(j, i),
				"Position": tile_position,
				"Type": type,
				"Image": image,
				"Image_scale": image_scale,
				"Image_modulate": image_modulate,
				"Darkened": false,
				"See_through": false,
				"In_sight": false,
				"Been_seen": false,
				"Height": height,
				"Passable" : {"Ground": false, "Water": false, "Air": false},
				"Movement_cost": movement_cost,
				"Range_bonus": range_bonus,
				"Defence_bonus": defence_bonus,
				"Hide": false,
				"Neighbour_1": {"Node": null, "ID": null, "Tile_key" : null, "Coordinates": null, "Available": false, "Movement_cost": null, "See_through": false, "Passable": {"Ground": false, "Water": false, "Air": false}, "Wall": false},
				"Neighbour_2": {"Node": null, "ID": null, "Tile_key" : null, "Coordinates": null, "Available": false, "Movement_cost": null, "See_through": false, "Passable": {"Ground": false, "Water": false, "Air": false}, "Wall": false},
				"Neighbour_3": {"Node": null, "ID": null, "Tile_key" : null, "Coordinates": null, "Available": false, "Movement_cost": null, "See_through": false, "Passable": {"Ground": false, "Water": false, "Air": false}, "Wall": false},
				"Neighbour_4": {"Node": null, "ID": null, "Tile_key" : null, "Coordinates": null, "Available": false, "Movement_cost": null, "See_through": false, "Passable": {"Ground": false, "Water": false, "Air": false}, "Wall": false},
				"Neighbour_5": {"Node": null, "ID": null, "Tile_key" : null, "Coordinates": null, "Available": false, "Movement_cost": null, "See_through": false, "Passable": {"Ground": false, "Water": false, "Air": false}, "Wall": false},
				"Neighbour_6": {"Node": null, "ID": null, "Tile_key" : null, "Coordinates": null, "Available": false, "Movement_cost": null, "See_through": false, "Passable": {"Ground": false, "Water": false, "Air": false}, "Wall": false},
			}
			
			if not in_sight:
				tile.update_image(1, image_dictionary["fog"], image_scale, null)
			
			tile_matrix[i].append(tile_key)
			tile_number += 1
			offset.x += tile_radius * 2
			count += 1
		
		#print(tile_matrix[i])
		
		if i - grid_radius != 0 and (i - grid_radius) / abs(i - grid_radius) != 0:
			if (i - grid_radius) / abs(i - grid_radius) < 0:
				offset.x -= tile_radius * 2 * count + tile_radius
			elif (i - grid_radius) / abs(i - grid_radius) > 0:
				offset.x -= tile_radius * 2 * count - tile_radius
		else:
			offset.x -= tile_radius * 2 * count - tile_radius
		
		offset.y += tile_side_length / 2 + tile_side_length
		count = 0
	
	tile_number = 0
	var neighbour_assignment_order = [5, 6, 4, 1, 3, 2]
	for y in range(tile_matrix.size()):
		for x in range(tile_matrix[y].size()):
			tile_number += 1
			var current_tile_key = tile_matrix[y][x]
			var neighbour_count = 1
			var calibrator = 0
			for row in range(3):
				var ny = y - 1 + row
				var local_column_count = 3 if row == 1 else 2
				if row > 1 and y < middle_row:
					calibrator = 1
				elif row < 1 and y > middle_row:
					calibrator = 1
				else:
					calibrator = 0
				for column in range(local_column_count):
					var nx = x - 1 + column + calibrator    
					if ny == y and nx == x:
						continue
					var neighbour_tile_key = get_tile_key_at(ny, nx)
					if neighbour_tile_key == null:
						neighbour_count += 1
						continue
					
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["Node"] = tile_dictionary[neighbour_tile_key]["Node"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["Tile_key"] = tile_dictionary[neighbour_tile_key]["Tile_key"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["ID"] = tile_dictionary[neighbour_tile_key]["ID"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["Coordinates"] = tile_dictionary[neighbour_tile_key]["Coordinates"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["Type"] = tile_dictionary[neighbour_tile_key]["Type"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["Image"] = tile_dictionary[neighbour_tile_key]["Image"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["Movement_cost"] = tile_dictionary[neighbour_tile_key]["Movement_cost"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_assignment_order[neighbour_count - 1])]["Passable"] = tile_dictionary[neighbour_tile_key]["Passable"]
					
					neighbour_count += 1
					if neighbour_count > 6:
						break
				if neighbour_count > 6:
					break

func get_tile_key_at(row: int, col: int):
	if row < 0 or row >= tile_matrix.size():
		return null
	if col < 0 or col >= tile_matrix[row].size():
		return null
	return tile_matrix[row][col]

func initialise_unit():
	var unit = unit_scene.instantiate()
	unit.parent = self
	add_child(unit)
	unit.position = viewport_visible_rect.size / 2
	unit.update_image(tile_radius)

func _on_button_pressed():
	hand.draw_card(deck)
	update_hand_position()

func initialise_view_angles():
	var calibrator = 0
	
	for layer in range(1, 3 + 1):
		var coefficient_y = 1
		var coefficient_x = -1
		var side_length = layer + 1
		var toggle_y = true
		var toggle_x = true
		var toggle_cooldown_y = side_length - 1
		var toggle_cooldown_x = 2 * layer
		var switch_cooldown = side_length - 1
		var switch_count = 0
		#print("Switch cooldown: " + str(switch_cooldown))
		
		view_cone_dictionary["Layer_" + str(layer)] = {}
		
		var checked_tile_position = Vector2(tile_diameter * layer - tile_radius, 1.5 * tile_side_length)
		view_cone_dictionary["Layer_" + str(layer)]["0.0_degrees"] = [6, 2]
		view_cone_dictionary["Layer_" + str(layer)]["-180.0_degrees"] = [3, 5]
		print()
		
		switch_cooldown -= 1
		for i in range(layer * 3 - 1):
			#print("Checked tile position: " + str(checked_tile_position))
			#print("Switch cooldown: " + str(switch_cooldown))
			
			if switch_cooldown == 0:
				switch_cooldown = side_length - 1
				switch_count += 1
				if switch_count == 1:
					coefficient_x *= 2
					coefficient_y = 0
				if switch_count == 2:
					coefficient_x *= 0.5
					coefficient_y = -1
			
			switch_cooldown -= 1
			
			var angle_from_unit = - round(rad_to_deg((checked_tile_position).angle()) * 10) / 10.0
			#print("Angle from unit: " + str(angle_from_unit))
			
			var cone_args_negative = []
			var cone_args_positive = []
			
			
			if layer == 1:
				if angle_from_unit == -60:
					cone_args_negative = [1, 3]
					cone_args_positive = [5, 1]
				elif angle_from_unit == -120:
					cone_args_negative = [2, 4]
					cone_args_positive = [4, 6]
			elif layer == 2:
				if angle_from_unit == -30:
					cone_args_negative = [1, 2]
					cone_args_positive = [6, 1]
				elif angle_from_unit == -60:
					cone_args_negative = [1, 3]
					cone_args_positive = [5, 1]
				elif angle_from_unit == -90:
					cone_args_negative = [2, 3]
					cone_args_positive = [5, 6]
				elif angle_from_unit == -120:
					cone_args_negative = [2, 4]
					cone_args_positive = [4, 6]
				elif angle_from_unit == -150:
					cone_args_negative = [3, 4]
					cone_args_positive = [4, 5]
			elif layer == 3:
				if angle_from_unit == -19.1:
					cone_args_negative = [1, 2]
					cone_args_positive = [6, 1]
				elif angle_from_unit == -40.9:
					cone_args_negative = [1, 2]
					cone_args_positive = [6, 1]
				elif angle_from_unit == -60:
					cone_args_negative = [1, 3]
					cone_args_positive = [5, 1]
				elif angle_from_unit == -79.1:
					cone_args_negative = [2, 3]
					cone_args_positive = [5, 6]
				elif angle_from_unit == -100.9:
					cone_args_negative = [2, 3]
					cone_args_positive = [5, 6]
				elif angle_from_unit == -120:
					cone_args_negative = [2, 4]
					cone_args_positive = [4, 6]
				elif angle_from_unit == -139.1:
					cone_args_negative = [3, 4]
					cone_args_positive = [4, 5]
				elif angle_from_unit == -160.9:
					cone_args_negative = [3, 4]
					cone_args_positive = [4, 5]
			
			view_cone_dictionary["Layer_" + str(layer)][str(angle_from_unit) + "_degrees"] = cone_args_negative
			
			view_cone_dictionary["Layer_" + str(layer)][str(-angle_from_unit) + "_degrees"] = cone_args_positive
			
			checked_tile_position.x += coefficient_x * tile_radius
			checked_tile_position.y += coefficient_y * (1.5 * tile_side_length)
			
			
			
	#print("View cone dictionary: " + str(view_cone_dictionary))


func update_fog(current_tile_key, previous_tile_key, unit_node):
	print("Moved!-----------------------------------------------------------------------------------")
	
	var unit_tile = tile_dictionary[current_tile_key]
	var unit_node_coordinates = tile_dictionary[current_tile_key]["Coordinates"]
	
	var sight_range = unit_node.sight_range
	var seen_tiles_matrix = []
	var seen_tiles = []
	var memory_matrix = []
	var columns_on_rows = []
	
	var search_range_2 = 2 * sight_range + 1
	var offset_2 = 0
	
	if unit_node_coordinates.y + sight_range > tile_matrix.size() - 1:
		search_range_2 = 2 * sight_range + 1 + ((tile_matrix.size() - 1) - (unit_node_coordinates.y + sight_range))
		offset_2 = ((tile_matrix.size() - 1) - (unit_node_coordinates.y + sight_range))
	
	if unit_node_coordinates.y - sight_range < 0:
		search_range_2 = 2 * sight_range + 1 + (unit_node_coordinates.y - sight_range)
		offset_2 += unit_node_coordinates.y - sight_range

	#print("Search_range_2: " + str(search_range_2))
	#print("Offset 2: " + str(offset_2))
	
	for i in range(search_range_2):
		var index_2 = unit_node_coordinates.y - sight_range
		index_2 = clamp(index_2, 0, 1000)
		#print("Count:" + str(i))
		#print("index_2 + i: " + str(index_2 + i))
		if index_2 + i <= tile_matrix.size() - 1:
			columns_on_rows.append(tile_matrix[index_2 + i].size())
			
	#print(columns_on_rows)
	#print()
	var coefficient = 1
	var calibrator = 0
	var search_range = 0
	#print("Unit coordinates: " + str(unit_node_coordinates))
	var search_ranges = []
	for row in range(sight_range + 1):
		if row == 0:
			search_ranges.append(sight_range + 1 + row)
			search_ranges.append(sight_range + 1 + row)
		elif row == sight_range:
			search_ranges.insert(sight_range, sight_range + 1 + row)
		else:
			search_ranges.insert(row, sight_range + 1 + row)
			search_ranges.insert(search_ranges.size() - 1 - row, sight_range + 1 + row)
	#print("Search_ranges: " + str(search_ranges))
	
	var columns_on_rows_index = -1
	var tile_matrix_centre = Vector2(tile_matrix[tile_matrix.size() / 2].size() / 2, tile_matrix.size() / 2)
	
	for row in range(1 + 2 * sight_range):
		if unit_node_coordinates.y + row - sight_range >= 0 and unit_node_coordinates.y + row - sight_range <= tile_matrix.size() - 1:
			seen_tiles_matrix.append([])
			columns_on_rows_index += 1
			
			var offset_left = 0
			var offset_right = 0
			var offset_range = 0
			
			if unit_node_coordinates.y == tile_matrix_centre.y:
				calibrator = 0
			elif unit_node_coordinates.y > tile_matrix_centre.y:
				if unit_node_coordinates.y - sight_range + row < tile_matrix_centre.y:
					calibrator = unit_node_coordinates.y - tile_matrix_centre.y
				elif row < sight_range:
					calibrator = sight_range - row
				elif row >= sight_range:
					calibrator = 0
			elif unit_node_coordinates.y < tile_matrix_centre.y:
				if unit_node_coordinates.y - sight_range + row > tile_matrix_centre.y:
					calibrator = tile_matrix_centre.y - unit_node_coordinates.y
				elif row < sight_range:
					calibrator = 0
				elif row >= sight_range:
					calibrator = row - sight_range
				
			if row > sight_range:
				coefficient = -1
			
			#print("Calibrator: " + str(calibrator))
			search_range = search_ranges[row]
			#print("Search ranges[row]: " + str(search_range))
			
			if unit_node_coordinates.x - sight_range + calibrator < 0:
				offset_left = sight_range - (unit_node_coordinates.x + calibrator)
				#print("Too left")
			if unit_node_coordinates.x - sight_range + calibrator + search_range > columns_on_rows[columns_on_rows_index]:
				offset_right = unit_node_coordinates.x - sight_range + calibrator + search_range - (columns_on_rows[columns_on_rows_index])
				#print("Too right")
			
			search_range -= offset_left
			search_range -= offset_right
			
			#print("Offset left: " + str(offset_left))
			#print("Global currently searched row: " + str(unit_node_coordinates.y + row - sight_range))
			#print("Columns on row index: " + str(columns_on_rows_index))
			#print("Columns on row - 1: " + str(columns_on_rows[columns_on_rows_index] - 1))
			#print("End of search index: " + str(unit_node_coordinates.x + calibrator - sight_range + search_range))
			#print("Offset right: " + str(offset_right))
			#print("Offset range: " + str(offset_range))
			#print("Search range: " + str(search_range))
			
			var y_index = 0
			var x_index = 0
			for column in range(search_range):
				#print("unit_node_coordinates.x + calibrator + offset_left - offset_right + column - sight_range: " + str(unit_node_coordinates.x + calibrator + offset_left - offset_right + column - sight_range))
				y_index = unit_node_coordinates.y - sight_range + row
				x_index = unit_node_coordinates.x - sight_range + calibrator + offset_left + column
				var minimum = 0
				var maximum = unit_node_coordinates.x - sight_range + calibrator + offset_left + column 
				x_index = clamp(x_index, minimum, maximum)
				#print("x_index: " + str(x_index) + ", y_index: " + str(y_index))
				var calculated_tile = tile_dictionary[tile_matrix[y_index][x_index]]
				seen_tiles_matrix[seen_tiles_matrix.size() - 1].append(tile_matrix[y_index][x_index])
				seen_tiles.append(tile_matrix[y_index][x_index])
				var node = calculated_tile["Node"]
				#print("Calculated tile: " + str(calculated_tile["ID"]))
			#print()
		elif unit_node_coordinates.y + row - sight_range < 0:
			pass
			#print("Relative row " + str(-sight_range + row) + " doesnt exist")
		elif unit_node_coordinates.y + row - sight_range > tile_matrix.size() - 1:
			pass
			#print("Relative row " + str(-sight_range + row) + " doesnt exist")
	print()
	#print("Seen matrix og: " + str(seen_tiles_matrix))
	
	var matrix_of_layers_of_tiles_keys = []
	var unit_tile_index = tile_dictionary[current_tile_key]["Index"]
	#print("Updated index: " + str(unit_tile_index.x) + ", " + str(unit_tile_index.y))
	
	calibrator = 0
	
	
	var shadow_list = []
	#print("Layers:")
	for layer in range(1, sight_range + 1):
		var offset_x = layer
		var offset_y = 0
		var coefficient_y = 1
		var coefficient_x = -1
		var side_length = layer + 1
		var toggle_y = true
		var toggle_x = true
		var toggle_cooldown_y = side_length - 1
		var toggle_cooldown_x = 2 * layer
		var switch_cooldown = 2 * layer
		#print("Switch cooldown: " + str(switch_cooldown))
		
		matrix_of_layers_of_tiles_keys.append([])
		
		for i in range(1, 6 * layer + 1):
			#print("Side length: " + str(side_length))
			
			if offset_y == 0:
				calibrator = 0
			elif unit_tile_index.y == tile_matrix_centre.y:
				calibrator = 0
			elif unit_tile_index.y < tile_matrix_centre.y:
				if offset_y < 0:
					calibrator = 0
				elif unit_tile_index.y + offset_y == tile_matrix_centre.y:
					calibrator = offset_y
				elif unit_tile_index.y + offset_y < tile_matrix_centre.y:
					calibrator = offset_y
				elif unit_tile_index.y + offset_y > tile_matrix_centre.y:
					calibrator = tile_matrix_centre.y - unit_tile_index.y
			elif unit_tile_index.y > tile_matrix_centre.y:
				if offset_y > 0:
					calibrator = 0
				elif unit_tile_index.y + offset_y == tile_matrix_centre.y:
					calibrator = -offset_y
				elif unit_tile_index.y + offset_y < tile_matrix_centre.y:
					calibrator = unit_tile_index.y - tile_matrix_centre.y
				elif unit_tile_index.y + offset_y > tile_matrix_centre.y:
					calibrator = -offset_y
			#print("Calibrator: " + str(calibrator))
			
			if unit_tile_index.y + offset_y >= 0 and unit_tile_index.y + offset_y <= tile_matrix.size() - 1:
				if unit_tile_index.x + offset_x + calibrator >= 0 and unit_tile_index.x + offset_x + calibrator <= tile_matrix[unit_tile_index.y + offset_y].size() - 1:
					#print("Offset y: " + str(offset_y))
					#print("Offset x: " + str(offset_x))
					#print("Unit tile index: " + str(unit_tile_index))
					#print("Offsets: (" + str(offset_y) + ", " + str(offset_x + calibrator) + ")")
					#print("Tile: " + str(tile_matrix[unit_tile_index.y + offset_y ][unit_tile_index.x + offset_x + calibrator]))
					#print()
					var checked_tile = tile_dictionary[tile_matrix[unit_tile_index.y + offset_y][unit_tile_index.x + offset_x + calibrator]]
					var checked_tile_key = tile_matrix[unit_tile_index.y + offset_y][unit_tile_index.x + offset_x + calibrator]
					matrix_of_layers_of_tiles_keys[layer - 1].append(checked_tile_key)
					
					if checked_tile["Type"] == "mountain":
						print()
						print(checked_tile_key, checked_tile["Index"], " is a mountain!", )
						var angle_from_unit = - round(rad_to_deg((checked_tile["Position"] - unit_tile["Position"]).angle()) * 10) / 10.0
						var layer_range = sight_range - layer
						var interval = view_cone_dictionary["Layer_" + str(layer)][str(angle_from_unit) + "_degrees"]
						shadow_list.append_array(iterate_around_tile(checked_tile["Tile_key"], layer_range, interval))

				else:
					pass
					#print("Offset y: " + str(offset_y))
					#print("Offset x: " + str(offset_x))
					#print("Unit tile index: " + str(unit_tile_index))
					#print("(" + str(unit_tile_index.y + offset_y) + ", " + str(unit_tile_index.x + offset_x + calibrator) + "): doesnt exist")
					#print()
			
			else:
				pass
				#print("Offset y: " + str(offset_y))
				#print("Offset x: " + str(offset_x))
				#print("Unit tile index: " + str(unit_tile_index))
				#print("(" + str(unit_tile_index.y + offset_y) + ", " + str(unit_tile_index.x + offset_x + calibrator) + "): doesnt exist")
				#print()
				
			if toggle_y:
				if offset_y != coefficient_y * (side_length - 1):
					offset_y += coefficient_y
				else:
					#print("Y_switched!")
					toggle_y = false
			
			if not toggle_y:
				toggle_cooldown_y -= 1
				if toggle_cooldown_y == 0:
					toggle_cooldown_y = side_length - 1
					toggle_y = true
					coefficient_y *= -1
			
			if toggle_x:
				if switch_cooldown != 0:
					offset_x += coefficient_x
					switch_cooldown -= 1
				else:
					#print("X_switched!")
					switch_cooldown = 2 * side_length - 1
					toggle_x = false
			
			if not toggle_x:
				toggle_cooldown_x -= 1
				if toggle_cooldown_x == 0:
					toggle_cooldown_x = 2 * side_length - 1
					toggle_x = true
					coefficient_x *= -1
		#print(matrix_of_layers_of_tiles_keys[layer - 1])
	
	#print("Seen tile: " + str(seen_tiles))
	
	shadow_list.sort()

	var pp = 0

	while pp + 1 < shadow_list.size():
		if shadow_list[pp] == shadow_list[pp + 1]:
			shadow_list.remove_at(pp + 1)
		else:
			pp += 1

	for i in range(shadow_list.size()):
		if seen_tiles.has(shadow_list[i]):
			seen_tiles.remove_at(seen_tiles.find(shadow_list[i]))
		
		var tile = tile_dictionary[shadow_list[i]]
		if not tile["Darkened"] and tile["Been_seen"]:
			var node = tile["Node"]
			node.update_image(1, tile["Image"], tile["Image_scale"], me_modulate)
	
	if previously_seen_tiles.size() != 0:
		print("Yahoo")
		for i in range(previously_seen_tiles.size()):
			var calculated_tile = tile_dictionary[previously_seen_tiles[i]]
			calculated_tile["In_sight"] = false
			var node = calculated_tile["Node"]
			node.update_image(1, calculated_tile["Image"], image_scale, me_modulate)
		
	
	for i in range(seen_tiles.size()):
		var calculated_tile = tile_dictionary[seen_tiles[i]]
		calculated_tile["In_sight"] = true
		calculated_tile["Been_seen"] = true
		var node = calculated_tile["Node"]
		node.update_image(1, calculated_tile["Image"], image_scale, null)
	
	previously_seen_tiles = seen_tiles

func iterate_around_tile(centre_tile_key, layers, interval):
	var shadow_list = []
	
	var index_start = interval[0]
	var index_end = interval[1]
	var index_centre = tile_dictionary[centre_tile_key]["Index"]
	var scale_constant = ((index_end - index_start) % 6 + 6) % 6
	
	var initial_tile_index = Vector2i(index_centre.x, index_centre.y)
	var tile_matrix_centre = Vector2i(tile_matrix[tile_matrix.size() / 2].size() / 2, tile_matrix.size() / 2)

	
	for layer in range(layers):
		print("Layer ", layer + 1, ":")
		var step = direction_to_step_dictionary[str(index_start)]
	
		var calibrator1 = 0
		if initial_tile_index.y == tile_matrix_centre.y:
			if step[1] < 0:
				print("	Above meridian")
			elif step[1] == 0:
				print("	On meridian")
			elif step[1] > 0:
				print("	Below meridian")
			calibrator1 = 0
		elif initial_tile_index.y < tile_matrix_centre.y:
			if step[1] > 0:
				if initial_tile_index.y + step[1] == tile_matrix_centre.y:
					print("	On meridian")
				else:
					print("	Above meridian")
				calibrator1 = 1
			else:
				calibrator1 = 0
		elif initial_tile_index.y > tile_matrix_centre.y:
			if step[1] < 0:
				if initial_tile_index.y + step[1] == tile_matrix_centre.y:
					print("	On meridian")
				else:
					print("	Below meridian")
				calibrator1 = 1
			else:
				calibrator1 = 0
		
		initial_tile_index.x += step[0] + calibrator1
		initial_tile_index.y += step[1]
		

		var index_revolving = index_start
		var offset_index = 1
		var side_length = layer + 2
		var switch_cooldown = -2 + side_length + 1
		
		if initial_tile_index.y < tile_matrix.size() and initial_tile_index.x < tile_matrix[initial_tile_index.y].size():
			if tile_dictionary.has(tile_matrix[initial_tile_index.y][initial_tile_index.x]):
				var initial_tile = tile_dictionary[tile_matrix[initial_tile_index.y][initial_tile_index.x]]
				shadow_list.append(initial_tile["Tile_key"])
				print("	Step: ", index_revolving, step, ", Calibrator: ", calibrator1, ", Tile key: ", initial_tile["Tile_key"])
		else:
			print("	Step: ", index_revolving, step, ", Calibrator: ", calibrator1)
		
		var initial_tile_index_2 = initial_tile_index
		for n in range(scale_constant + scale_constant * layer):
			if n == 0:
				offset_index = 2
				index_revolving = (index_revolving % 6 + offset_index) % 7
				index_revolving = clamp(index_revolving, 1, 6)
				
				if switch_cooldown != 0:
					switch_cooldown -= 1
				else:
					switch_cooldown = side_length
			else:
				offset_index = 1
			
				if switch_cooldown != 0:
					switch_cooldown -= 1
				else:
					switch_cooldown = side_length
					index_revolving = (index_revolving % 6 + offset_index) % 7
					index_revolving = clamp(index_revolving, 1, 6)
					print("	Switch!")
			
			step = direction_to_step_dictionary[str(index_revolving)]
			
			var calibrator2 = 0
			if initial_tile_index_2.y == tile_matrix_centre.y:
				if step[1] < 0:
					print("	Above meridian")
				elif step[1] == 0:
					print("	On meridian")
				elif step[1] > 0:
					print("	Below meridian")
				calibrator2 = 0
			elif initial_tile_index_2.y < tile_matrix_centre.y:
				if step[1] > 0:
					if initial_tile_index_2.y + step[1] == tile_matrix_centre.y:
						print("	On meridian")
					else:
						print("	Above meridian")
					calibrator2 = 1
				else:
					calibrator2 = 0
			elif initial_tile_index_2.y > tile_matrix_centre.y:
				if step[1] < 0:
					if initial_tile_index_2.y + step[1] == tile_matrix_centre.y:
						print("	On meridian")
					else:
						print("Below meridian")
					calibrator2 = 1
				else:
					calibrator2 = 0
			
			initial_tile_index_2.x += step[0] + calibrator2
			initial_tile_index_2.y += step[1]
			
			if initial_tile_index_2.y < tile_matrix.size() and initial_tile_index_2.x < tile_matrix[initial_tile_index_2.y].size():
				if tile_dictionary.has(tile_matrix[initial_tile_index_2.y][initial_tile_index_2.x]):
					var initial_tile_2 = tile_dictionary[tile_matrix[initial_tile_index_2.y][initial_tile_index_2.x]]
					shadow_list.append(initial_tile_2["Tile_key"])
					print("	Step: ", index_revolving, step, ", Calibrator: ", calibrator1, ", Tile key: ", initial_tile_2["Tile_key"])
			else:
				print("	Step: ", index_revolving, step, ", Calibrator: ", calibrator1)
		print()
	
	return shadow_list
