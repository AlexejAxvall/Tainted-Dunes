extends Control

@onready var texture_rect = $TextureRect
@onready var label = $TextureRect/Label
@onready var button = $TextureRect/Button
@onready var text_edit = $TextureRect/TextEdit

@export var card_texture: Texture

var card_dictionary = {
	"Name": "",
	"Cost": null,
	"Type": null,
	"ID": null,
}
var is_playable: bool = false

func _ready():
	texture_rect.texture = preload("res://Images/Card_frame.png")
	var texture_rect_size = texture_rect.size 
	label.size.x = texture_rect_size.x * 0.91666666666
	label.size.y = texture_rect_size.y * 0.15625
	label.text = card_dictionary["Name"]

func _input(event):
	if is_playable and event is InputEventMouseButton and event.pressed:
		if get_global_rect().has_point(event.position):
			play_card()

func play_card():
	print("Played: " + card_dictionary["Name"])
	get_parent().remove_card(self)
	queue_free()
