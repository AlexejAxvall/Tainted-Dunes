#Hand scene root node script

extends Control

@onready var deck = get_parent().get_node("Deck")
@onready var pointer_1 = $Pointer_1 #Area2D
@onready var pointer_2 = $Pointer_2 #Area2D

@export var max_hand_size: int = 10
var hand_dictionary = {}
var hand_array: Array = []
var hand_size = 0

var hand_position

var a

var card_dimensions: Vector2 = Vector2(192, 256)
var card_scale

var hovered_card

var card_rotations = []
var max_card_rotation: float#+- deg
var angle_step: float #deg
var card_positions = []
@export var hand_radius: float

var viewport_size

var offset = 0

var update_count = 0

func _ready():
	print(card_dimensions)
	update_variables()


func update_variables():
	#print("Updating variables")
	update_count += 1
	viewport_size = get_viewport_rect().size
	a = viewport_size.x * 0.8
	hand_radius = clamp(hand_radius, a - viewport_size.x / 2 + 800, 10000000)
	hand_position = Vector2(viewport_size.x / 2, viewport_size.y - card_dimensions.y * card_scale.y + hand_radius)
	
	for card in hand_array:
		card.viewport_size = viewport_size
	
	var base
	var height
	if len(find_intersection(hand_position, hand_radius, a)) > 0:
		var triangle_base_height = find_intersection(hand_position, hand_radius, a)[1]
		#print("Triangle_base_height: " + str(triangle_base_height))
		base = triangle_base_height.x
		#print("Base: " + str(base))
		height = triangle_base_height.y
		#print("Height: " + str(height))
		#print("Intersections: " + str(len(find_intersection(hand_position, hand_radius, a))))
		#print()
	elif len(find_intersection(hand_position, hand_radius, a)) == 0:
		pass
		#print("Error!")
		#print("Intersections: " + str(len(find_intersection(hand_position, hand_radius, a))))
		#print()
		
	if height != null:
		max_card_rotation = 90 - rad_to_deg(atan(height / base))
	else:
		pass
		#print("Error!")
		
	#print("Max_card_rotation deg: " + str(max_card_rotation))
	
	if max_hand_size % 2 == 0:
		angle_step = max_card_rotation / (max_hand_size / 2.0)
	else:
		angle_step = max_card_rotation / (max_hand_size / 2.0 - 0.5)
	
	#print("Angle step: " + str(angle_step))
	#print("Angle step * max hand size: " + str(angle_step * max_hand_size))
	card_rotations.clear()
	card_positions.clear()
	var card_rotations_deg = []
	for i in range(max_hand_size):
		card_rotations_deg.append(-max_card_rotation + angle_step * i)
		card_rotations.append(deg_to_rad(-max_card_rotation + angle_step * i))
	for i in range(max_hand_size):
		card_positions.append(Vector2(hand_radius * cos(deg_to_rad(90 + max_card_rotation - angle_step * i)) - card_dimensions.x * 0.5, -hand_radius * sin(deg_to_rad(90 + max_card_rotation - angle_step * i)) - card_dimensions.y))
		#print("angle: " + str(90 + max_card_rotation - angle_step * i))
	#print()
	
	#print("Card positions: " + str(card_positions))
	#print()
	#print("Card rotations deg: " + str(card_rotations_deg))
	#print()
	
	arrange_cards()

func draw_card(deck):
	update_variables()
	find_intersection(hand_position, hand_radius, a)
	hand_size = hand_array.size()
	
	if hand_size < max_hand_size and deck.deck_of_cards.size() != 0:
		var card = deck.draw_card()
		if card:
			card.hand = self
			card.id = hand_size + 1
			card.is_instantiate = true
			card.viewport_size = viewport_size
			card.recieved_z_index = hand_size + 1
			
			var card_key = "Card_" + str(hand_size + 1)
			hand_dictionary[card_key] = {"ID": hand_size + 1, "Node": card, "Z_index": hand_size + 1}

			hand_array.append(card)
			hand_size = hand_array.size()
			add_child(card)
			arrange_cards()
			#print("Hand:", hand_array)
			queue_redraw()


func remove_card(card):
	var index_of_removed = hand_array.find(card)
	for i in range(hand_array.size() - 1 - index_of_removed):
		var card_index = index_of_removed + 1 + i
		hand_dictionary["Card_" + str(card_index)]["ID"] -= 1
		hand_dictionary["Card_" + str(card_index)]["Node"].recieved_z_index -= 1
		hand_dictionary["Card_" + str(card_index)]["Z_index"] -= 1

	hand_array.erase(card)
	hand_size = hand_array.size()
	arrange_cards()


func arrange_cards():
	#print("From arrange_cards")
	#print("Hand size: " + str(hand_size))
	#print("Hand_position: " + str(hand_position))
	#print("Viewport_size: " + str(viewport_size))
	#print("Viewport_size.x / 2: " + str(viewport_size.x / 2))
	#print("a: " + str(a))
	#print("a - viewport_size.x / 2: " + str(a - viewport_size.x / 2))
	#print("Hand_radius: " + str(hand_radius))
	#print()
	
	var index_hand_middle = len(hand_array) / 2
	#print("Index_hand_middle: " + str(index_hand_middle))
	var index_positions_middle = len(card_positions) / 2
	#print("Index_positions_middle: " + str(index_positions_middle))
	var index_rotations_middle = len(card_rotations) / 2
	#print("Index_rotations_middle: " + str(index_rotations_middle))
	var offset = hand_size / 2
	
	for i in range(hand_size):
		hand_array[i].position = card_positions[index_positions_middle - offset + i]
		hand_array[i].recieved_position = card_positions[index_positions_middle - offset + i]
		if hand_array[i]:
			hand_array[i].rotation = card_rotations[index_rotations_middle - offset + i]
			hand_array[i].recieved_rotation = card_rotations[index_rotations_middle - offset + i]

#func _draw():
	#draw_circle(Vector2.ZERO, hand_radius, Color(255, 0, 0), false, 1.0, true)

func find_intersection(circle_global_position: Vector2, r: float, a: float) -> Array:
	#print()
	#print("From find_intersection")
	#print("Hand_position: " + str(hand_position))
	#print("Viewport_size: " + str(viewport_size))
	#print("Viewport_size.x / 2: " + str(viewport_size.x / 2))
	#print("a: " + str(a))
	#print("a - viewport_size.x / 2: " + str(a - viewport_size.x / 2))
	#print("Circle_global_position: " + str(circle_global_position))
	#print("Circle_global_position.y - viewport_size.y: " + str(circle_global_position.y - viewport_size.y))
	#print("Circle_radius: " + str(r))
	#print()
	
	var discriminant = r * r - (a - circle_global_position.x) * (a - circle_global_position.x)
	if discriminant < 0:
		return []
	elif discriminant == 0:
		pointer_1.position = Vector2(a, circle_global_position.y)
		#print("Intersection points: " + str(Vector2(a, circle_global_position.y)))
		#print("Arc tan: " + str(rad_to_deg(atan(circle_global_position.y / a))))
		#print()
		return [Vector2(a, circle_global_position.y)]
	else:
		var sqrt_d = sqrt(discriminant)
		var x2 = a - circle_global_position.x
		var x1 = a - circle_global_position.x
		var y2 = sqrt_d
		var y1 = -sqrt_d
		pointer_1.position = Vector2(x1, y1)
		pointer_2.position = Vector2(x2, y2)
		#print("Intersection points relative to circle centre: " + str(Vector2(x1, y1)) + " " + str(Vector2(x2, y2)))
		#print("hand_position.y - y2: " + str(hand_position.y - y2))
		#print("Viewport_size.y: " + str(viewport_size.y))
		#print("Arc tan y1: " + str(rad_to_deg(atan(y1 / x1))))
		#print("Arc tan y2: " + str(rad_to_deg(atan(y2 / x2))))
		#print()
		return [Vector2(x1, y1), Vector2(x2, y2)]

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		pass
		#print("Update count: " + str(update_count))

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var mouse_pos = get_viewport().get_mouse_position()
		var top_card = null

		# Single pass: find the hovered card with the highest z_index
		for card in hand_array:
			if card.get_global_rect().has_point(mouse_pos):
				print(card)
				if top_card == null or card.recieved_z_index > top_card.recieved_z_index:
					top_card = card

		# Fire enter/exit only on real changes
		if top_card != hovered_card:
			if hovered_card:
				hovered_card.exit_highlight()
			if top_card:
				top_card.enter_highlight()
			hovered_card = top_card
