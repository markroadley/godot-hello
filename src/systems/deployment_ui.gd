extends Control
class_name DeploymentUI

## Player's hand of Minis available to deploy

signal mini_selected(mini_data: Dictionary)

@export var max_hand_size: int = 6
@export var card_spacing: int = 70
@export var deck: Array[Dictionary] = []

var hand: Array[Dictionary] = []
var selected_index: int = -1

@onready var card_scene = preload("res://scenes/deployment_card.tscn")
@onready var hand_container = $HandContainer

func _ready():
	if deck.is_empty():
		deck = get_default_deck()
	draw_cards(3)

func get_default_deck() -> Array[Dictionary]:
	return [
		{"id": "knight", "name": "Knight", "cost": 3, "hp": 120, "damage": 15, "speed": 40, "range": 25, "attack_speed": 1.0, "color": Color(0.8, 0.8, 0.8)},
		{"id": "archer", "name": "Archer", "cost": 2, "hp": 60, "damage": 12, "speed": 50, "range": 100, "attack_speed": 1.2, "color": Color(0.2, 0.8, 0.2)},
		{"id": "mage", "name": "Mage", "cost": 4, "hp": 50, "damage": 25, "speed": 35, "range": 80, "attack_speed": 0.8, "color": Color(0.3, 0.3, 1.0)},
		{"id": "tank", "name": "Tank", "cost": 5, "hp": 200, "damage": 8, "speed": 25, "range": 20, "attack_speed": 0.6, "color": Color(0.6, 0.4, 0.2)},
	]

func draw_cards(count: int):
	for i in range(count):
		if hand.size() < max_hand_size and not deck.is_empty():
			var card_data = deck.pop_front()
			hand.append(card_data)
			create_card_ui(card_data, hand.size() - 1)
	
	if deck.is_empty():
		deck = get_default_deck()

func create_card_ui(card_data: Dictionary, index: int):
	var card = card_scene.instantiate()
	hand_container.add_child(card)
	card.setup(card_data)
	card.position.x = index * 80 + 10
	
	# Connect input
	card.gui_input.connect(_on_card_input.bind(index))

func _on_card_input(event, card_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_card(card_index)
	elif event is InputEventScreenTouch and event.pressed:
		_select_card(card_index)

func _select_card(index: int):
	if selected_index == index:
		selected_index = -1
		hand_container.get_child(index).set_selected(false)
	else:
		if selected_index >= 0 and selected_index < hand_container.get_child_count():
			hand_container.get_child(selected_index).set_selected(false)
		selected_index = index
		hand_container.get_child(index).set_selected(true)
		mini_selected.emit(hand[index])
