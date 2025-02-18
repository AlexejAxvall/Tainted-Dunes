extends Control

#@onready var highest_parent = null

@onready var deck = get_parent().get_node("Deck")

@export var max_hand_size: int = 5
var hand_of_cards: Array = []
var hand_size = 0

func _ready():
	pass
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
	for i in range(hand_of_cards.size()):
		hand_of_cards[i].position = Vector2(i * deck.card_dimensions.x * deck.card_scale.x, 0)

func remove_card(card):
	hand_of_cards.erase(card)
	hand_size = hand_of_cards.size()
	arrange_cards()
