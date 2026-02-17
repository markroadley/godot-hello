extends Control
class_name DeploymentUI

## Player's hand of Minis - drag and drop from tray to field

signal mini_dropped(mini_data: Dictionary, position: Vector2)

@export var max_hand_size: int = 6

var hand: Array[Dictionary] = []
var selected_index: int = -1
var dragging_card: Dictionary = {}
var dragging = false
var drag_start_pos = Vector2.ZERO

@onready var hand_container = $HandContainer

func _ready():
	print("DeploymentUI _ready called")
	draw_initial_cards()

func draw_initial_cards():
	var deck = get_default_deck()
	for i in range(min(4, deck.size())):
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
	
	# Create a panel for the card with drag support
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(70, 90)
	
	# Create label for name and cost
	var label = Label.new()
	label.text = "%s\n$%d" % [card_data.get("name", "?"), card_data.get("cost", 0)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(5, 25)
	label.size = Vector2(60, 40)
	panel.add_child(label)
	
	# Store card data on the panel
	panel.set_meta("card_data", card_data)
	panel.set_meta("card_index", hand.size() - 1)
	
	# Connect mouse events for drag
	panel.gui_input.connect(_on_card_input.bind(hand.size() - 1, card_data))
	
	hand_container.add_child(panel)

func _on_card_input(event, index: int, card_data: Dictionary):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				dragging = true
				dragging_card = card_data
				drag_start_pos = event.position
				print("Started dragging: ", card_data.get("name"))
			else:
				# Released - check if it was a drag or click
				if dragging:
					dragging = false
					dragging_card = {}

func _gui_input(event):
	# Handle drag and drop to field
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and dragging and not dragging_card.is_empty():
				# Get global position for drop
				var global_pos = get_global_mouse_position()
				print("Dragging to: ", global_pos)
				
				# Check if we're in the game field (above this UI)
				# This UI is at the bottom, so if mouse is above, it's in field
				if global_pos.y < 854 - 120:  # Above the UI area
					# Drop the mini!
					emit_signal("mini_dropped", dragging_card, global_pos)
					print("Dropped: ", dragging_card.get("name"), " at ", global_pos)
					dragging = false
					dragging_card = {}
	elif event is InputEventMouseMotion and dragging:
		# Update drag visual if needed
		pass

func _process(delta):
	# Handle drag release anywhere
	if dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pass
	elif dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Mouse released, check if in drop zone
		var global_pos = get_global_mouse_position()
		if global_pos.y < 854 - 120:  # Above UI
			emit_signal("mini_dropped", dragging_card, global_pos)
		dragging = false
		dragging_card = {}
