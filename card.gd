extends Control

@onready var parent = get_parent()

@onready var texture_rect = $TextureRect
@onready var label = $TextureRect/Label
@onready var button = $TextureRect/Button
@onready var text_edit = $TextureRect/TextEdit

@onready var left_box = $Left_box
@onready var left_box_collision_shape2D = $Left_box/CollisionShape2D
@onready var centre_box = $Centre_box
@onready var centre_box_collision_shape2D = $Centre_box/CollisionShape2D
@onready var right_box = $Right_box
@onready var right_box_collision_shape2D = $Right_box/CollisionShape2D

var id

var viewport_size

var texture_rect_size
var card_dimensions
var card_scale

var is_hovering = false
var time_hovered = 0.0
var time_hovered_threshold = 0.1 # seconds

@export var card_texture: Texture

var is_instantiate = false

var card_dictionary = {
	"Name": "",
	"Cost": null,
	"Type": null,
	"ID": null,
}
var is_playable: bool = false

var highlighting = false
var recieved_z_index # Recieved by parent
var recieved_position
var recieved_rotation

func _ready():
	#print("Card initialized:", self)
	#print("Parent: " + str(parent))
	if recieved_z_index != null:
		z_index = recieved_z_index
		#print("Z_index: " + str(z_index))
	
	texture_rect.texture = preload("res://Images/Card_frame.png")
	
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
	#print("\n=== Checking Mouse Filters ===")
	#_check_mouse_filter(self)
	#print("=== Mouse Filter Check Complete ===")
	#
	#print("=== Scene Tree Structure for Card ===")
	#_print_tree(self, 0)  # Prints the hierarchy
	
	texture_rect_size = texture_rect.size
	
	card_dimensions = texture_rect_size
	
	left_box.position = Vector2(-card_dimensions.x * 0.375, -card_dimensions.y * 0.5)
	var left_box_shape = RectangleShape2D.new()
	left_box_shape.extents = Vector2(card_dimensions.x * 0.125, card_dimensions.y * 0.5)
	left_box_collision_shape2D.shape = left_box_shape
	
	centre_box.position = Vector2(0, -card_dimensions.y * 0.5)
	var centre_box_shape = RectangleShape2D.new()
	centre_box_shape.extents = Vector2(card_dimensions.x * 0.25, card_dimensions.y * 0.5)
	centre_box_collision_shape2D.shape = centre_box_shape
	
	right_box.position = Vector2(card_dimensions.x * 0.375, -card_dimensions.y * 0.5)
	var right_box_shape = RectangleShape2D.new()
	right_box_shape.extents = Vector2(card_dimensions.x * 0.125, card_dimensions.y * 0.5)
	right_box_collision_shape2D.shape = left_box_shape
	
	if is_instantiate != true:
		parent.card_dimensions = card_dimensions
	
	card_scale = texture_rect.scale
	if is_instantiate != true:
		parent.card_scale = card_scale
	
	label.size.x = texture_rect_size.x * 0.91666666666
	label.size.y = texture_rect_size.y * 0.15625
	label.text = card_dictionary["Name"]


func _process(delta):
	if highlighting != true:
		if is_hovering:
			time_hovered += delta
			if time_hovered >= time_hovered_threshold:
				highlight_card()
		else:
			time_hovered = 0  # Reset if not hovering

func _input(event):
	if event is InputEventMouseMotion:
		if get_global_rect().has_point(event.position):
			pass
			#print("Mouse is currently over the card (manual check).")

	if is_playable and event is InputEventMouseButton and event.pressed:
		if get_global_rect().has_point(event.position):
			play_card()

func highlight_card():
	highlighting = true
	parent.is_card_highlighted = true
	z_index = 100
	parent.hand_dictionary["Card_" + str(id)]["Z_index"] = z_index
	global_position.y = parent.viewport_size.y
	rotation = 0
	scale = Vector2(2, 2)
	#print("Self and adjacent z_index: ")
	
	var loop_amount
	var offset_1 = 0
	
	#if id == 1:
		#loop_amount = 2
		#offset_1 = 1
	#elif id == parent.hand_size:
		#loop_amount = 2
	#else:
		#loop_amount = 3
	#for i in range(loop_amount):
			#print(str(parent.hand_dictionary["Card_" + str(id - 1 + offset_1 + i)]["Z_index"]))
	
func play_card():
	#print("Played:", card_dictionary["Name"])
	get_parent().remove_card(self)
	queue_free()

func _on_texture_rect_mouse_entered():
	if parent.is_card_highlighted != true:
		#print("Mouse entered card: " + str(id))
		is_hovering = true

func _on_texture_rect_mouse_exited():
	#print("Mouse exited card: " + str(id))
	if highlighting:
		highlighting = false
		z_index = recieved_z_index
		parent.hand_dictionary["Card_" + str(id)]["Z_index"] = recieved_z_index
		position = recieved_position
		rotation = recieved_rotation
		scale = Vector2(1, 1)
		parent.is_card_highlighted = false
	is_hovering = false
	time_hovered = 0.0
	
#func _print_tree(node, level):
	#print("  ".repeat(level) + node.name + " (" + node.get_class() + ")")
	#for child in node.get_children():
		#_print_tree(child, level + 1)
		
#func _check_mouse_filter(node):
	#if node is Control:  # Only check Control nodes, skip Area2D and others
		#print(node.name, " (", node.get_class(), ") - mouse_filter:", node.mouse_filter)
	#else:
		#print(node.name, " (", node.get_class(), ") - ❌ Skipped (Not a Control)")
	#print()
	#
	#for child in node.get_children():
		#_check_mouse_filter(child)


#func fetch_new_data():

#func update_mouse_filter(list):
	#for node in list:
		#node.mouse_filter = Control.MOUSE_FILTER_IGNORE
