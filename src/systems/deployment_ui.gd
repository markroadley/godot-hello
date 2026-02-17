extends Control
class_name DeploymentUI

## Player's hand of Minis available to deploy

signal mini_selected(mini_data: Dictionary)
signal mini_deselected()

@export var max_hand_size: int = 6

var hand: Array[Dictionary] = []
var selected_index: int = -1

@onready var hand_container = $HandContainer

func _ready():
	draw_initial_cards()

func draw_initial_cards():
	var deck = get_default_deck()
	for i in range(min(3, deck.size())):
		add_card(deck[i])

func get_default_deck() -> Array[Dictionary]:
	return [
		{"id": "knight", "name": "Knight", "cost": 3, "hp": 120, "damage": 15, "speed": 40, "range": 25, "attack_speed": 1.0, "color": Color(0.8, 0.8, 0.8)},
		{"id": "archer", "name": "Archer", "cost": 2, "hp": 60, "damage": 12, "speed": 50, "range": 100, "attack_speed": 1.2, "color": Color(0.2, 0.8, 0.2)},
		{"id": "mage", "name": "Mage", "cost": 4, "hp": 50, "damage": 25, "speed": 35, "range": 80, "attack_speed": 0.8, "color": Color(0.3, 0.3, 1.0)},
		{"id": "tank", "name": "Tank", "cost": 5, "hp": 200, "damage": 8, "speed": 25, "range": 20, "attack_speed": 0.6, "color": Color(0.6, 0.4, 0.2)},
	]

func add_card(card_data: Dictionary):
	hand.append(card_data)
	
	# Create a simple button for the card
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(70, 90)
	btn.text = "%s\n$%d" % [card_data.get("name", "?"), card_data.get("cost", 0)]
	
	# Connect using callable
	btn.pressed.connect(_on_card_pressed.bind(hand.size() - 1))
	
	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("normal", style)
	
	hand_container.add_child(btn)

func _on_card_pressed(index: int):
	if selected_index == index:
		# Deselect
		selected_index = -1
		mini_deselected.emit()
	else:
		# Select
		selected_index = index
		mini_selected.emit(hand[index])
	
	_update_button_styles()

func _update_button_styles():
	for i in range(hand_container.get_child_count()):
		var btn = hand_container.get_child(i)
		var style_normal = btn.get_theme_stylebox("normal").duplicate()
		if i == selected_index:
			style_normal.bg_color = Color(0.5, 0.5, 0.3, 1)  # Gold when selected
		else:
			style_normal.bg_color = Color(0.2, 0.2, 0.25, 1)
		btn.add_theme_stylebox_override("normal", style_normal)

func clear_selection():
	selected_index = -1
	_update_button_styles()
