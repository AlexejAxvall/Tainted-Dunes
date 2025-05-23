#Deck scene root node script

extends Control

@onready var main_scene = get_parent().get_parent()
@onready var card = get_node("Card")
@onready var hand = get_parent().get_node("Hand")


var deck_of_cards: Array = []
var discard_pile: Array = []
@export var move_cards_in_starting_deck = 5
@export var attack_cards_in_starting_deck = 3
@export var resource_cards_in_starting_deck = 2

var card_dimensions: Vector2 = Vector2(192, 256)
var card_scale: Vector2 = Vector2(1, 1)

func _ready():
	hand.card_dimensions = card_dimensions
	hand.card_scale = card_scale
	create_deck()

func create_deck():
	var card_scene = preload("res://card.tscn")
	for i in range(move_cards_in_starting_deck):
		var card = card_scene.instantiate()
		card.main_scene = main_scene
		card.card_owner = main_scene.which_players_turn
		card.size = card_dimensions
		card.card_dictionary["Name"] = "Movement"
		card.card_dictionary["Text"] = "Move a unit"
		card.card_dictionary["Category"] = "Movement"
		card.card_dictionary["Effects"] = {
			"Enable_movement": {"Movements_enabled": 1}
			}
		deck_of_cards.append(card)
	for j in range(attack_cards_in_starting_deck):
		var card = card_scene.instantiate()
		card.main_scene = main_scene
		card.card_owner = main_scene.which_players_turn
		card.size = card_dimensions
		card.card_dictionary["Name"] = "Attack"
		card.card_dictionary["Text"] = "Attack a tile"
		card.card_dictionary["Category"] = "Attack"
		card.card_dictionary["Effects"] = {
			"Enable_attack": {"Attacks_enabled": 1}
			}
		deck_of_cards.append(card)
	for k in range(attack_cards_in_starting_deck):
		var card = card_scene.instantiate()
		card.main_scene = main_scene
		card.card_owner = main_scene.which_players_turn
		card.size = card_dimensions
		card.card_dictionary["Name"] = "Resources"
		card.card_dictionary["Text"] = "Gather resources"
		card.card_dictionary["Category"] = "Resources"
		card.card_dictionary["Effects"] = {
			"Gather_resources": {"Resources_gathered": 1}
			}
		deck_of_cards.append(card)
	deck_of_cards.shuffle()
	#print("Deck: " + str(deck_of_cards))
	
func draw_card():
	if deck_of_cards.is_empty():
		reshuffle_discard()
	return deck_of_cards.pop_front() if !deck_of_cards.is_empty() else null

func reshuffle_discard():
	deck_of_cards = discard_pile.duplicate()
	discard_pile.clear()
	deck_of_cards.shuffle()
