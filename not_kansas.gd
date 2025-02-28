#Main scene root node script

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

@export var grid_radius = 6

var viewport_visible_rect
var viewport_size
var camera_viewport_size

var hand_position

var tile_position_initial: Vector2
var tile_side_length
var tile_dictionary = {}
var tile_matrix = []
var tile_radius

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

func _ready():
	middle_row = grid_radius
	
	viewport_visible_rect = get_viewport().get_visible_rect()
	viewport_size = get_viewport_rect().size
	
	secant_global_position = Vector2(viewport_size.x / 2.0, viewport_size.y + hand.hand_radius - 100)
	hand.hand_width = 0.8 * viewport_size.x
	
	camera.position = viewport_visible_rect.size / 2
	
	initialize_image_folder()
	initialize_grid()
	initialize_unit()
	
	while hand.hand_size < 1:
		hand.draw_card(deck)
	
	
	update_hand_position()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			old_selected_node = selected_node
			await get_tree().create_timer(0.1).timeout
			if not unit_clicked and not tile_clicked:
				if event.button_index == MOUSE_BUTTON_LEFT:
					pass
					#print("\nLeft-click detected anywhere in the scene!")
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					#print("\nRight-click detected anywhere in the scene!")
					if selected_node:
						selected_node.is_selected = false
						selected_node = null
					#print("Selected node: " + str(selected_node))
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
	line_2D.add_point(Vector2(0, viewport_size.y + - 100))  # First point
	line_2D.add_point(Vector2(viewport_size.x, viewport_size.y - 100))  # Second point
	
	line_2D2.clear_points()
	line_2D2.width = 3
	line_2D2.default_color = Color.RED
	line_2D2.add_point(Vector2(viewport_size.x * 0.2, -viewport_size.y))  # First point
	line_2D2.add_point(Vector2(viewport_size.x * 0.2, 2 * viewport_size.y))  # Second point
		
	line_2D3.clear_points()
	line_2D3.width = 3
	line_2D3.default_color = Color.RED
	line_2D3.add_point(Vector2(viewport_size.x * 0.8, -viewport_size.y))  # First point
	line_2D3.add_point(Vector2(viewport_size.x * 0.8, 2 * viewport_size.y))  # Second point
	
	line_2D4.clear_points()
	line_2D4.width = 3
	line_2D4.default_color = Color.RED
	line_2D4.add_point(Vector2(0, viewport_size.y))  # First point
	line_2D4.add_point(Vector2(viewport_size.x, viewport_size.y))  # Second point
	
	##print("Hand global position: " + str(hand.global_position))
	#hand_position = Vector2(viewport_size.x / 2, viewport_size.y + hand.hand_radius - (deck.card_dimensions.y * deck.card_scale.y) / 2.0)
	hand_position = Vector2(viewport_size.x / 2, viewport_size.y + hand.hand_radius)
	hand.hand_position = hand_position
	#print("Card dimensions: " + str(deck.card_dimensions))
	#print("Card scale: " + str(deck.card_scale))
	hand.position = hand_position
	#deck.position = Vector2(100, viewport_size.y - 100)

func initialize_image_folder():
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

func initialize_grid():
	tile_position_initial = viewport_visible_rect.size / 2
	
	var tile_initial = tile_scene.instantiate()
	tile_side_length = tile_initial.tile_side_length
	
	tile_radius = sqrt(pow(tile_side_length, 2) - pow(tile_side_length / 2, 2))
	
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
				# image = image_dictionary[type]  # Optionally set an image.
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
				# image = image_dictionary[type]  # Optionally set an image.
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
			#tile.update_background_image(background_image, background_image_scale)
			
			var tile_key = "Tile_" + str(tile_number)
			tile_dictionary[tile_key] = {
				"Node": tile,
				"ID": tile_number,
				"Coordinates": [j, i],
				"Position": tile_position,
				"Type": type,
				"Image": image,
				"Image_scale": image_scale,
				"Image_modulate": image_modulate,
				"In_sight": false,
				"Height": height,
				"Passable" : {"Ground" : false, "Water" : false, "Air" : false},
				"Movement_cost": movement_cost,
				"Range_bonus": range_bonus,
				"Defence_bonus": defence_bonus,
				"Hide": false,
				"Neighbour_1": {"Node": null, "ID": null, "Coordinates": null, "Movement_cost" : null, "Passable" : {"Ground" : false, "Water" : false, "Air" : false}},
				"Neighbour_2": {"Node": null, "ID": null, "Coordinates": null, "Movement_cost" : null, "Passable" : {"Ground" : false, "Water" : false, "Air" : false}},
				"Neighbour_3": {"Node": null, "ID": null, "Coordinates": null, "Movement_cost" : null, "Passable" : {"Ground" : false, "Water" : false, "Air" : false}},
				"Neighbour_4": {"Node": null, "ID": null, "Coordinates": null, "Movement_cost" : null, "Passable" : {"Ground" : false, "Water" : false, "Air" : false}},
				"Neighbour_5": {"Node": null, "ID": null, "Coordinates": null, "Movement_cost" : null, "Passable" : {"Ground" : false, "Water" : false, "Air" : false}},
				"Neighbour_6": {"Node": null, "ID": null, "Coordinates": null, "Movement_cost" : null, "Passable" : {"Ground" : false, "Water" : false, "Air" : false}},
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
	
	
	
	
	# Assign neighbors with safe index checking.
	# For each tile, we check:
	#   - The row above (y - 1): 2 potential neighbor positions
	#   - The same row (y): 3 potential neighbor positions (skipping itself)
	#   - The row below (y + 1): 2 potential neighbor positions
	tile_number = 0
	
	for y in range(tile_matrix.size()):
		for x in range(tile_matrix[y].size()):
			tile_number += 1
			#print()
			#print("Tile " + str(tile_number))
			#print("Coordinates: " + str(tile_dictionary["Tile_" + str(tile_number)]["Coordinates"]))
			#print()
			var current_tile_key = tile_matrix[y][x]
			var neighbour_count = 1
			
			
			var calibrator = 0
			for row in range(3):
				var ny = y - 1 + row
				var local_column_count = 3 if row == 1 else 2
				if row > 1 and y < middle_row:
					calibrator = 1
				elif row < 1 and y > middle_row:
					#print("Y: " + str(y) + " , Row" + str(row))
					calibrator = 1
				else:
					calibrator = 0
				for column in range(local_column_count):
					var nx = x - 1 + column + calibrator    
					if ny == y and nx == x:
						
						continue
					var neighbour_tile_key = get_tile_key_at(ny, nx)
					if neighbour_tile_key == null:
						#print("Self Y = " + str(y))
						#print("Self X = " + str(x))
						#print("Neighbour tile key:" + str(neighbour_tile_key))
						#print("Neighbour " + str(neighbour_count) + ": ID: " + str(tile_dictionary["Tile_" + str(tile_number)]["Neighbour_" + str(neighbour_count)]["ID"]))
						#print("Coordinates: " + str(tile_dictionary["Tile_" + str(tile_number)]["Neighbour_" + str(neighbour_count)]["Coordinates"]))
						#print("Neighbour_" + str(neighbour_count) + " Relative Y = " + str(ny - y))
						#print("Neighbour_" + str(neighbour_count) + " Relative X = " + str(nx - x))
						#print()
						neighbour_count += 1
						continue
					
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_count)]["Node"] = tile_dictionary[neighbour_tile_key]["Node"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_count)]["ID"] = tile_dictionary[neighbour_tile_key]["ID"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_count)]["Coordinates"] = tile_dictionary[neighbour_tile_key]["Coordinates"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_count)]["Type"] = tile_dictionary[neighbour_tile_key]["Type"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_count)]["Image"] = tile_dictionary[neighbour_tile_key]["Image"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_count)]["Movement_cost"] = tile_dictionary[neighbour_tile_key]["Movement_cost"]
					tile_dictionary[current_tile_key]["Neighbour_" + str(neighbour_count)]["Passable"] = tile_dictionary[neighbour_tile_key]["Passable"]
					
					#print("Self Y = " + str(y))
					#print("Self X = " + str(x))
					#print("Neighbour tile key:" + str(neighbour_tile_key))
					#print("Neighbour " + str(neighbour_count) + ": ID: " + str(tile_dictionary["Tile_" + str(tile_number)]["Neighbour_" + str(neighbour_count)]["ID"]))
					#print("Coordinates: " + str(tile_dictionary["Tile_" + str(tile_number)]["Neighbour_" + str(neighbour_count)]["Coordinates"]))
					#print("Neighbour_" + str(neighbour_count) + " Relative Y = " + str(ny - y))
					#print("Neighbour_" + str(neighbour_count) + " Relative X = " + str(nx - x))
					#print()
					
					neighbour_count += 1
					if neighbour_count > 6:
						break
				if neighbour_count > 6:
					break
	
			#print(tile_dictionary["Tile_" + str(tile_number)])

func get_tile_key_at(row: int, col: int):
	if row < 0 or row >= tile_matrix.size():
		return null
	if col < 0 or col >= tile_matrix[row].size():
		return null
	return tile_matrix[row][col]

func initialize_unit():
	var unit = unit_scene.instantiate()
	unit.parent = self
	add_child(unit)
	unit.position = viewport_visible_rect.size / 2
	unit.update_image(tile_radius)

func _on_button_pressed():
	#print("Pressed!")
	hand.draw_card(deck)
	update_hand_position()

func update_fog(add_or_remove, tile_key):
	#print("Tile key: " + str(tile_key))
	if add_or_remove == "add":
		for i in range(6):
			var node = tile_dictionary["Tile_" + str(tile_key)]["Neighbour_" + str(i + 1)]["Node"]
			#print("Neighbour " + str(i + 1))
			if node!= null:
				node.update_image(1, image_dictionary["fog"], image_scale, null)
	elif add_or_remove == "remove":
		tile_dictionary["Tile_" + str(tile_key)]["Node"].update_image(1, tile_dictionary["Tile_" + str(tile_key)]["Image"], image_scale, null)
		for i in range(6):
			var node = tile_dictionary["Tile_" + str(tile_key)]["Neighbour_" + str(i + 1)]["Node"]
			#print("Neighbour " + str(i + 1))
			if node != null:
				node.update_image(1, tile_dictionary["Tile_" + str(tile_key)]["Neighbour_" + str(i + 1)]["Image"], image_scale, null)
