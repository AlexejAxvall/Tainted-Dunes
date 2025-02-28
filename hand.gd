#Hand scene root node script

extends Control

#@onready var highest_parent = null


@onready var deck = get_parent().get_node("Deck")

@export var max_hand_size: int = 10
var hand_array: Array = []
var hand_size = 0

var hand_width #80% of viewport width
var hand_position

var circle_center: Vector2
var a

var card_dimensions
var card_scale

var card_rotation
var card_rotations = []
var max_card_rotation: float#+- deg
var angle_step: float #deg
var index_centre
var hand_offset
var card_positions = []
@export var hand_radius: float

var viewport_size

var offset = 0

func _ready():	
	viewport_size = get_viewport_rect().size
	a = viewport_size.x * 0.8
	
	hand_radius = clamp(hand_radius, (a - viewport_size.x / 2), 10000000)
	print("A: " + str(a))
	print("Global position: " + str(global_position))
	print("Hand radius: " + str(hand_radius))
	print("Half of viewport: " + str(viewport_size.x / 2))
	print("Dif: " + str(a - hand_radius))
	print("A distance from half of viewport: " + str(a - viewport_size.x / 2))
	
	print(deck.card_dimensions.y * deck.card_scale.y)
	hand_position = Vector2(viewport_size.x / 2, viewport_size.y - card_dimensions.y * card_scale.y + hand_radius)
	var base
	var height
	if len(find_intersection(hand_position, hand_radius, a)) > 0:
		var triangle_base_height = find_intersection(hand_position, hand_radius, a)[0]
		base = triangle_base_height.x
		height = triangle_base_height.y
		print("Intersections: " + str(len(find_intersection(hand_position, hand_radius, a))))
		print()
	elif len(find_intersection(hand_position, hand_radius, a)) == 0:
		print("Error!")
		print("Intersections: " + str(len(find_intersection(hand_position, hand_radius, a))))
		print()
		
	if height != null:
		max_card_rotation = 90 - rad_to_deg(atan(height / base))
	else:
		max_card_rotation = 30
	print("Max_rot: " + str(max_card_rotation))
	
	if max_hand_size % 2 == 0:
		angle_step = 2.0 * max_card_rotation / max_hand_size
		print("Angle step: " + str(angle_step))
		print("Angle step * max hand size: " + str(angle_step * max_hand_size))
		for i in range((max_hand_size + 1)):
			card_rotations.append(-max_card_rotation + angle_step * i)
		index_centre = max_hand_size / 2
		for i in range((max_hand_size + 1)):
			card_positions.append(Vector2(500, -500))
			#card_positions.append(Vector2(hand_radius * cos(deg_to_rad(90 + max_card_rotation - angle_step * i)), -hand_radius * sin(deg_to_rad(90 + max_card_rotation - angle_step * i))))
			print("angle: " + str(90 + max_card_rotation - angle_step * i))
	else:
		angle_step = max_card_rotation / (max_hand_size / 2)
		for i in range(max_hand_size):
			card_rotations.append(-max_card_rotation + angle_step * i)
		
		for i in range(max_hand_size):
			card_positions.append(Vector2(100 * i, 500))
			#card_positions.append(Vector2(hand_radius * cos(deg_to_rad(90 + max_card_rotation - angle_step * i)), -hand_radius * sin(deg_to_rad(90 + max_card_rotation - angle_step * i))))
	
		index_centre = max_hand_size / 2 + 1
	
	print("Card positions: " + str(card_positions))
	print("Card rotations: " + str(card_rotations))
	#print("Angle step: " + str(angle_step))
	#print("Card rotations: " + str(card_rotations))
	#print("Card positions: " + str(card_positions))

	
	
	#while self.get_parent() != null:
		#highest_parent = self.get_parent()

func draw_card(deck):
	hand_size = hand_array.size()
	if hand_size < max_hand_size and deck.deck_of_cards.size() != 0:
		var card = deck.draw_card()
		if card:
			hand_array.append(card)
			hand_size = hand_array.size()
			add_child(card)
			arrange_cards()
			#print("Hand: " + str(hand_array))
			viewport_size = get_viewport_rect().size
			a = viewport_size.x * 0.8
			hand_radius = clamp(hand_radius, a - viewport_size.x / 2, 100000)
			queue_redraw()

func arrange_cards():
	if hand_size % 2 == 0:
		hand_offset = hand_size / 2.0
		#print("Hand offset: " + str(hand_offset))
	elif hand_size != 1:
		hand_offset = hand_size / 2.0
		#print("Hand offset: " + str(hand_offset))
	elif hand_size == 1:
		hand_offset = 0
		#print("Hand offset: " + str(hand_offset))
	
	#print("Hand size: " + str(hand_size))
	var calibrator = 0
	for i in range(hand_size):
		hand_array[i].position = card_positions[i]
		#hand_array[i].position = Vector2(192 * i, -hand_radius)
		if hand_array[i]:
			if hand_size % 2 == 0:
				if i == hand_offset - 1:
					#print("Index: 2")
					#print("Rotation deg: " + str(card_rotations[index_centre - 1]))
					#print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre - 1])))
					card_rotation = deg_to_rad(card_rotations[index_centre - 1])
				elif i == hand_offset:
					#print("Index: 4")
					#print("Rotation deg: " + str(card_rotations[index_centre + 1]))
					#print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre + 1])))
					card_rotation = deg_to_rad(card_rotations[index_centre + 1])
					calibrator = 1
				else:
					#print("Index: " + str(index_centre - hand_offset + i + calibrator))
					#print("Rotation deg: " + str(card_rotations[index_centre - hand_offset + i + calibrator]))
					#print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre - hand_offset + i + calibrator])))
					card_rotation = deg_to_rad(card_rotations[index_centre - hand_offset + i + calibrator])	
			else:
				#print("Index: " + str(index_centre - hand_offset + i - 1))
				#print("Rotation deg: " + str(card_rotations[index_centre - hand_offset + i - 1]))
				#print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre - hand_offset + i - 1])))
				card_rotation = deg_to_rad(card_rotations[index_centre - hand_offset + i])
			hand_array[i].rotation = card_rotation

func remove_card(card):
	hand_array.erase(card)
	hand_size = hand_array.size()
	arrange_cards()

func _draw():
	draw_circle(Vector2.ZERO, hand_radius, Color(255, 0, 0), false, -1.0, true)

func find_intersection(circle_global_position: Vector2, r: float, a: float) -> Array:
	var discriminant = r * r - (a - circle_global_position.x) * (a - circle_global_position.x)
	if discriminant < 0:
		return []
	elif discriminant == 0:
		return [Vector2(a, circle_global_position.y)]
	else:
		var sqrt_d = sqrt(discriminant)
		var y2 = circle_global_position.y + sqrt_d
		var y1 = circle_global_position.y - sqrt_d
		return [Vector2(a, y1), Vector2(a, y2)]
