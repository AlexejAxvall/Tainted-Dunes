#Card.gd
extends TextureRect

@export var card_texture: Texture

var main_scene
@onready var parent = get_parent()
@onready var label     = $Label
@onready var text_edit = $TextEdit

@onready var mouse_ignore_list = [self, label, text_edit]

var hand

var playable = true

var id
var card_owner
var recieved_z_index
var recieved_position
var recieved_rotation

var viewport_size

var card_dictionary = {
	"Name":    "",
	"Cost":    null,
	"Type":    null,
	"ID":      null,
	"Effects": null,
}

var is_instantiate = false
var card_dimensions: Vector2
var card_scale:      Vector2

func _ready():
	texture = card_texture

	card_scale      = scale
	print(size)
	card_dimensions = size

	for c in mouse_ignore_list:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if recieved_z_index != null:
		z_index = recieved_z_index

	label.size = Vector2(size.x * 0.92, size.y * 0.16)
	label.text = card_dictionary["Name"]

func enter_highlight():
	z_index    = 100
	scale      = Vector2(1.2, 1.2)
	rotation  = 0
	global_position.y = viewport_size.y - card_dimensions.y * scale.y
	print(global_position)

func exit_highlight():
	z_index   = recieved_z_index
	scale     = Vector2(1, 1)
	position  = recieved_position
	rotation  = recieved_rotation

func update_mouse_filter(nodes):
	for n in nodes:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
