extends Control

#@onready var highest_parent = null

@onready var deck = get_parent().get_node("Deck")

@export var max_hand_size: int = 10
var hand_of_cards: Array = []
var hand_size = 0
var card_rotation
var card_rotations = []
var max_card_rotation: float = 30 #deg
var angle_step: float #deg
var index_centre
var hand_offset
var card_positions = []
@export var hand_radius: float = 100

func _ready():
	if max_hand_size % 2 == 0:
		angle_step = 2.0 * max_card_rotation / max_hand_size
		for i in range(max_hand_size + 1):
			card_rotations.append(-max_card_rotation + angle_step * i)
		index_centre = max_hand_size / 2
	else:
		print(max_card_rotation / max_hand_size)
		angle_step = max_card_rotation / (max_hand_size / 2)
		for i in range(max_hand_size):
			card_rotations.append(-max_card_rotation + angle_step * i)
		index_centre = max_hand_size / 2 + 1
	print("Angle step: " + str(angle_step))
	
	for i in range(max_hand_size):
		card_positions.append(Vector2())
	
	print(card_rotations)
	#while self.get_parent() != null:
		#highest_parent = self.get_parent()

func draw_card(deck):
	hand_size = hand_of_cards.size()
	if hand_size < max_hand_size and deck.deck_of_cards.size() != 0:
		var card = deck.draw_card()
		if card:
			hand_of_cards.append(card)
			hand_size = hand_of_cards.size()
			add_child(card)
			arrange_cards()
			print("Hand: " + str(hand_of_cards))

func arrange_cards():
	if hand_size % 2 == 0:
		hand_offset = hand_size / 2
		print("Hand offset: " + str(hand_offset))
	elif hand_size != 1:
		hand_offset = hand_size / 2
		print("Hand offset: " + str(hand_offset))
	elif hand_size == 1:
		hand_offset = 0
		print("Hand offset: " + str(hand_offset))
	
	print("Hand size: " + str(hand_size))
	var calibrator = 0
	for i in range(hand_size):
		hand_of_cards[i].position = Vector2(i * deck.card_dimensions.x * deck.card_scale.x, 0)
		if hand_of_cards[i]:
			if hand_size % 2 == 0:
				if i == hand_offset - 1:
					print("Index: 2")
					print("Rotation deg: " + str(card_rotations[index_centre - 1]))
					print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre - 1])))
					card_rotation = deg_to_rad(card_rotations[index_centre - 1])
				elif i == hand_offset:
					print("Index: 4")
					print("Rotation deg: " + str(card_rotations[index_centre + 1]))
					print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre + 1])))
					card_rotation = deg_to_rad(card_rotations[index_centre + 1])
					calibrator = 1
				else:
					print("Index: " + str(index_centre - hand_offset + i + calibrator))
					print("Rotation deg: " + str(card_rotations[index_centre - hand_offset + i + calibrator]))
					print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre - hand_offset + i + calibrator])))
					card_rotation = deg_to_rad(card_rotations[index_centre - hand_offset + i + calibrator])	
			else:
				print("Index: " + str(index_centre - hand_offset + i - 1))
				print("Rotation deg: " + str(card_rotations[index_centre - hand_offset + i - 1]))
				print("Rotation rad: " + str(deg_to_rad(card_rotations[index_centre - hand_offset + i - 1])))
				card_rotation = deg_to_rad(card_rotations[index_centre - hand_offset + i])
			hand_of_cards[i].rotation = card_rotation

func remove_card(card):
	hand_of_cards.erase(card)
	hand_size = hand_of_cards.size()
	arrange_cards()
