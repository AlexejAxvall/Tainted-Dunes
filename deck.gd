#Deck scene root node script

extends Control

@onready var card = get_parent().get_node("Card")
@onready var hand = get_parent().get_node("Hand")


var deck_of_cards: Array = []
var discard_pile: Array = []
@export var move_cards_in_starting_deck = 5
@export var attack_cards_in_starting_deck = 3
@export var resource_cards_in_starting_deck = 2

var card_dimensions: Vector2
var card_scale: Vector2

func _ready():
	hand.card_dimensions = card_dimensions
	hand.card_scale = card_scale
	create_deck()

func create_deck():
	var card_scene = preload("res://card.tscn")
	for i in range(move_cards_in_starting_deck):
		var card = card_scene.instantiate()
		card.card_dictionary["Name"] = "Movement"
		deck_of_cards.append(card)
	for j in range(attack_cards_in_starting_deck):
		var card = card_scene.instantiate()
		card.card_dictionary["Name"] = "Attack"
		deck_of_cards.append(card)
	for k in range(attack_cards_in_starting_deck):
		var card = card_scene.instantiate()
		card.card_dictionary["Name"] = "Resources"
		deck_of_cards.append(card)
	deck_of_cards.shuffle()
	print("Deck: " + str(deck_of_cards))
	
func draw_card():
	if deck_of_cards.is_empty():
		reshuffle_discard()
	return deck_of_cards.pop_front() if !deck_of_cards.is_empty() else null

func reshuffle_discard():
	deck_of_cards = discard_pile.duplicate()
	discard_pile.clear()
	deck_of_cards.shuffle()
