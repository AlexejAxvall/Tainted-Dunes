extends Node2D

var parent

@onready var collision_polygon_2D = $Area2D/CollisionPolygon2D
@onready var area2D = $Area2D
@onready var sprite2D_1 = $Sprite2D
@onready var sprite2D_2 = $Sprite2D2

@export var tile_side_length = 50

var id
var contains_unit = false
var is_selected = false

var image

func _ready():
	area2D.connect("input_event", Callable(self, "_on_area2d_input_event"))
	collision_polygon_2D.polygon = calculate_hexagon(tile_side_length)


func _process(delta):
	pass

func calculate_hexagon(tile_side_length):
	var vertices = []
	for i in range(6):
		var angle = deg_to_rad(30 + 60 * i)
		var x = tile_side_length * cos(angle)
		var y = tile_side_length * sin(angle)
		vertices.append(Vector2(x, y))
	return vertices


func _on_area_2d_body_entered(body):
	if body.has_group("Unit"):
		contains_unit = true
		print("Tile " + str(id) + " contains a unit: " + str(body))

func _on_area_2d_body_exited(body):
	if body.has_group("Unit"):
		contains_unit = false

func _on_area2d_input_event(viewport, event, shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			parent.tile_clicked = true
			await get_tree().create_timer(0.1).timeout
			if not parent.click_blocked:
				print()
				print("Tile " + str(id) + " is_selected")
				is_selected = true
				parent.selected_node = self
				print("Selected node: " + str(self))
				parent.click_blocked = true
				if parent.selected_node and parent.old_selected_node:
					if parent.old_selected_node.is_in_group("Unit"):
						parent.old_selected_node.position = parent.selected_node.position

func update_image(image_name : Texture2D, image_scale : Vector2, image_self_modulate : Color):
	sprite2D_1.texture = image_name
	sprite2D_1.self_modulate = image_self_modulate
	sprite2D_1.scale = image_scale

func update_background_image(image_name : Texture2D, image_scale : Vector2):
	sprite2D_2.texture = image_name
	sprite2D_2.scale = image_scale
