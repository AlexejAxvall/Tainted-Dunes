extends Node2D

var parent

@onready var collisio_shape_2D = $Area2D/CollisionShape2D
@onready var area2D = $Area2D
@onready var sprite2D = $Sprite2D


var team
var type
var id

var is_selected = false
var toggle : bool

var stats_dictionary = {
	"Type" : null,
	"ID" : null,
	"Health" : null,
	"Movement_type" : null,
	"Movement_points" : null,
	"Sight_range" : null,
	"Damage" : null,
	"Range" : null,
	"Shot_elevation" : null,
	"Rotation" : null,
}

func _ready():
	area2D.connect("input_event", Callable(self, "_on_area2d_input_event"))
	sprite2D.scale = Vector2()

func deselect(event):
	is_selected = false

func _on_area2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		parent.unit_clicked = true
		print()
		print("Unit clicked!")
		is_selected = true
		parent.selected_node = self
		print("Selected node: " + str(self))
		parent.click_blocked = false
		
func update_image(tile_radius : float):
	sprite2D.scale = Vector2(2 * tile_radius / 360, 2 * tile_radius / 360)

func set_radius(radius : float):
	collisio_shape_2D.shape.radius = radius
