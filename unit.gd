#unit.gd(Unit scene script)
extends Node2D

var parent

# which tile the unit is currently standing on
var current_tile_key: String = ""
# optionally put yourself in the "Unit" group
# so tiles can detect you via `is_in_group("Unit")`

# so PathFinder can just use these directly:
var move_type: String          # e.g. "Ground", "Water" or "Air"
var movement_points: int

func _enter_tree():
	add_to_group("Unit")
# ──────────────────────────

@onready var collisio_polygon_2D = $Area2D/CollisionPolygon2D
@onready var area2D              = $Area2D
@onready var sprite2D            = $Sprite2D

@export var tile_side_length = 50

var team
var type
var id

var selectable = true
var is_selected = false
var toggle : bool

var previous_tile_id = null

var was_just_deployed = true
var sight_range      = 3

var stats_dictionary = {
	"Type": null,
	"ID": null,
	"Health_base": null,
	"Health": null,
	"Movement_type" : null,
	"Movement_points_base": null,
	"Movement_points": null,
	"Sight_range_base": null,
	"Sight_range": null,
	"Damage_base": null,
	"Damage": null,
	"Range_base": null,
	"Range": null,
	"Elevation": null,
}


func _ready():
	move_type = stats_dictionary["Movement_type"]
	movement_points = stats_dictionary["Movement_points"]
	area2D.connect("input_event", Callable(self, "_on_area2d_input_event"))
	collisio_polygon_2D.polygon = calculate_hexagon(tile_side_length)
	sprite2D.scale = Vector2()

func _on_area2d_input_event(viewport, event, shape_idx):
	if selectable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Selected unit")
		parent.unit_clicked    = true
		is_selected            = true
		parent.selected_node   = self
		parent.click_blocked   = false

func update_image(tile_radius : float):
	sprite2D.scale = Vector2(2 * tile_radius / 360, 2 * tile_radius / 360)

func calculate_hexagon(tile_side_length):
	var vertices = []
	for i in range(6):
		var angle = deg_to_rad(30 + 60 * i)
		vertices.append(Vector2(
			tile_side_length * 0.9 * cos(angle),
			tile_side_length * 0.9 * sin(angle)
		))
	return vertices
