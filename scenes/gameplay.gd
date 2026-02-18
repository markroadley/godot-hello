extends Node2D
class_name GameManager

## Main game manager for the battle

signal game_over(winner: int)

@onready var gold_manager = $GoldManager
@onready var gold_display = $GoldDisplay
@onready var player_base = $Bases/PlayerBase
@onready var enemy_base = $Bases/EnemyBase
@onready var minis_container = $Minis
@onready var game_layer = $GameLayer

var game_time: float = 0.0
var is_game_over: bool = false
var selected_mini_data: Dictionary = {}

# UI Elements
var tray_panel: Panel
var hand_container: HBoxContainer
var hand_buttons: Array = []
var deck: Array = []

const PLAYER_TEAM = 0
const ENEMY_TEAM = 1

func _ready():
	# Setup gold manager
	gold_manager.gold = 5
	gold_manager._ready()
	
	# Connect signals
	gold_manager.gold_changed.connect(_on_gold_changed)
	
	# Add bases to groups
	enemy_base.add_to_group("bases")
	player_base.add_to_group("bases")
	enemy_base.base_destroyed.connect(_on_enemy_base_destroyed)
	player_base.base_destroyed.connect(_on_player_base_destroyed)
	
	# Create the tray UI
	_create_tray_ui()
	
	# Start enemy AI
	start_enemy_spawns()
	
	# Initial gold display
	_on_gold_changed(gold_manager.gold)
	
	print("GameManager ready!")

func _create_tray_ui():
	print("Creating tray UI...")
	# Create tray panel at bottom
	tray_panel = Panel.new()
	# Position at bottom of screen - use explicit position, not anchors
	tray_panel.position = Vector2(0, 734)  # Bottom of 854 height
	tray_panel.size = Vector2(480, 120)
	tray_panel.color = Color(0.15, 0.15, 0.2, 1)
	
	print("Adding tray to game_layer...")
	game_layer.add_child(tray_panel)
	print("Tray added to game_layer")
	
	# Create hand container with explicit positioning
	hand_container = HBoxContainer.new()
	hand_container.position = Vector2(40, 20)  # Offset within tray
	hand_container.size = Vector2(400, 80)
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	tray_panel.add_child(hand_container)
	print("Hand container created")
	
	# Create deck
	deck = [
		{"id": "knight", "name": "Knight", "cost": 3, "hp": 120, "damage": 15, "speed": 40, "range": 25, "attack_speed": 1.0, "color": Color(0.8, 0.8, 0.8)},
		{"id": "archer", "name": "Archer", "cost": 2, "hp": 60, "damage": 12, "speed": 50, "range": 100, "attack_speed": 1.2, "color": Color(0.2, 0.8, 0.2)},
		{"id": "mage", "name": "Mage", "cost": 4, "hp": 50, "damage": 25, "speed": 35, "range": 80, "attack_speed": 0.8, "color": Color(0.3, 0.3, 1.0)},
		{"id": "tank", "name": "Tank", "cost": 5, "hp": 200, "damage": 8, "speed": 25, "range": 20, "attack_speed": 0.6, "color": Color(0.6, 0.4, 0.2)},
	]
	
	# Create buttons for each card
	print("Creating ", deck.size(), " card buttons")
	for i in range(deck.size()):
		var card_data = deck[i]
		var btn = _create_card_button(card_data, i)
		hand_container.add_child(btn)
		hand_buttons.append(btn)
	
	print("Tray UI creation complete!")

func _create_card_button(card_data: Dictionary, index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 100)
	btn.text = "%s\n$%d" % [card_data.get("name", "?"), card_data.get("cost", 0)]
	btn.pressed.connect(_on_card_pressed.bind(index, card_data))
	
	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.35, 1)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", style_hover)
	
	return btn

func _on_card_pressed(index: int, card_data: Dictionary):
	selected_mini_data = card_data
	
	# Try to spawn directly - for now spawn in middle lane at bottom
	var cost = card_data.get("cost", 3)
	
	if gold_manager.spend(cost):
		# Spawn in lane 1 (middle) at position near player's base
		var spawn_pos = Vector2(240, 700)  # Near bottom
		spawn_mini(card_data, spawn_pos, 1, PLAYER_TEAM)
		_on_gold_changed(gold_manager.gold)
		gold_display.text = "Deployed %s!" % card_data.get("name", "Unit")
		await get_tree().create_timer(0.5).timeout
		_on_gold_changed(gold_manager.gold)
	else:
		gold_display.text = "Need $%d more!" % (cost - gold_manager.gold)
		await get_tree().create_timer(1.0).timeout
		_on_gold_changed(gold_manager.gold)
	
	# Highlight selected
	for i in range(hand_buttons.size()):
		var btn = hand_buttons[i]
		var style = btn.get_theme_stylebox("normal").duplicate()
		if i == index:
			style.bg_color = Color(0.5, 0.5, 0.3, 1)
		else:
			style.bg_color = Color(0.2, 0.2, 0.25, 1)
		btn.add_theme_stylebox_override("normal", style)
	
	print("Card pressed: ", card_data.get("name"))

func _input(event):
	# Handle tap/drop - add debug
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed and not selected_mini_data.is_empty():
				print("Mouse release at: ", event.position, " selected: ", selected_mini_data.get("name"))
				_handle_drop(event.position)
	elif event is InputEventScreenTouch:
		if not event.pressed and not selected_mini_data.is_empty():
			print("Touch release at: ", event.position, " selected: ", selected_mini_data.get("name"))
			_handle_drop(event.position)

func _handle_drop(screen_pos: Vector2):
	# Check if drop is in game area (above tray)
	if screen_pos.y < 734:  # Above tray
		var cost = selected_mini_data.get("cost", 3)
		if gold_manager.spend(cost):
			var lane = int(screen_pos.x / 160)
			lane = clamp(lane, 0, 2)
			spawn_mini(selected_mini_data, screen_pos, lane, PLAYER_TEAM)
			_on_gold_changed(gold_manager.gold)
			gold_display.text = "Deployed!"
			await get_tree().create_timer(0.5).timeout
			_on_gold_changed(gold_manager.gold)
		else:
			gold_display.text = "Need $%d more!" % (cost - gold_manager.gold)
			await get_tree().create_timer(1.0).timeout
			_on_gold_changed(gold_manager.gold)
	
	# Clear selection
	selected_mini_data = {}
	for btn in hand_buttons:
		var style = btn.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color(0.2, 0.2, 0.25, 1)
		btn.add_theme_stylebox_override("normal", style)

func _process(delta):
	if is_game_over:
		return
	
	game_time += delta
	
	# Check win condition
	if enemy_base.get_hp() <= 0:
		end_game(PLAYER_TEAM)
		return
	
	if player_base.get_hp() <= 0:
		end_game(ENEMY_TEAM)
		return

func _on_gold_changed(amount):
	gold_display.text = "Gold: %d" % amount

func spawn_mini(mini_data: Dictionary, position: Vector2, lane: int, team: int):
	var mini = preload("res://src/units/mini.gd").new()
	
	mini.max_hp = mini_data.get("hp", 100)
	mini.damage = mini_data.get("damage", 10)
	mini.move_speed = mini_data.get("speed", 50)
	mini.range_ = mini_data.get("range", 30)
	mini.cost = mini_data.get("cost", 3)
	mini.attack_speed = mini_data.get("attack_speed", 1.0)
	mini.team = team
	mini.lane = lane
	
	position.x = clamp(position.x, 20, 460)
	position.y = clamp(position.y, 50, 700)
	mini.position = position
	
	minis_container.add_child(mini)
	mini.add_to_group("minis")
	
	print("Spawned: ", mini_data.get("name"), " at ", position)
	
	return mini

func _on_enemy_base_destroyed(team):
	end_game(PLAYER_TEAM)

func _on_player_base_destroyed(team):
	end_game(ENEMY_TEAM)

func end_game(winner: int):
	is_game_over = true
	game_over.emit(winner)
	print("Game Over! Winner: ", winner)

# Simple enemy AI
func start_enemy_spawns():
	var enemy_deck = [
		{"id": "goblin", "name": "Goblin", "cost": 2, "hp": 50, "damage": 8, "speed": 60, "range": 20, "attack_speed": 1.5, "color": Color(0.5, 0.8, 0.3)},
		{"id": "orc", "name": "Orc", "cost": 4, "hp": 100, "damage": 15, "speed": 35, "range": 25, "attack_speed": 0.8, "color": Color(0.4, 0.6, 0.3)},
	]
	
	while not is_game_over:
		await get_tree().create_timer(randf_range(3.0, 6.0)).timeout
		if is_game_over:
		 break
		
		var card = enemy_deck.pick_random()
		var lane = randi() % 3
		var x_pos = 80 + lane * 160 + 80
		var spawn_pos = Vector2(x_pos, 60)
		
		spawn_mini(card, spawn_pos, lane, ENEMY_TEAM)
