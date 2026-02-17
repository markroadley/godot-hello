extends Node2D
class_name GameManager

## Main game manager for the battle

signal game_over(winner: int)

@onready var gold_manager = $GoldManager
@onready var gold_display = $GoldDisplay
@onready var deployment_ui = $DeploymentUI
@onready var minis_container = $Minis
@onready var player_base = $Bases/PlayerBase
@onready var enemy_base = $Bases/EnemyBase

var game_time: float = 0.0
var is_game_over: bool = false
var selected_mini_data: Dictionary = {}

const PLAYER_TEAM = 0
const ENEMY_TEAM = 1

func _ready():
	# Setup gold manager
	gold_manager.gold = 5
	gold_manager._ready()
	
	# Connect signals
	gold_manager.gold_changed.connect(_on_gold_changed)
	deployment_ui.mini_selected.connect(_on_mini_selected)
	deployment_ui.mini_deselected.connect(_on_mini_deselected)
	
	# Add bases to groups
	enemy_base.add_to_group("bases")
	player_base.add_to_group("bases")
	enemy_base.base_destroyed.connect(_on_enemy_base_destroyed)
	player_base.base_destroyed.connect(_on_player_base_destroyed)
	
	# Start enemy AI
	start_enemy_spawns()
	
	# Initial gold display
	_on_gold_changed(gold_manager.gold)
	
	# Connect tap area for input
	$TapArea.gui_input.connect(_on_tap_area_input)
	
	print("GameManager ready!")
	print("Viewport size: ", get_viewport().get_visible_rect().size)

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

func _input(event):
	# For HTML5, mouse and touch are often merged
	# Check for any press event
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var is_pressed = false
		var pos = Vector2.ZERO
		
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_pressed = event.pressed
				pos = event.position
		elif event is InputEventScreenTouch:
			is_pressed = event.pressed
			pos = event.position
		
		if is_pressed and pos != Vector2.ZERO:
			print("Input event at: ", pos)
			_handle_tap(pos)

func _on_tap_area_input(event):
	# Alternative input via gui_input on Control node
	print("TapArea received: ", event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("TapArea mouse click: ", event.position)
			_handle_tap(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			print("TapArea touch: ", event.position)
			_handle_tap(event.position)

func _handle_tap(screen_pos: Vector2):
	print("Handle tap at: ", screen_pos, " selected: ", selected_mini_data)
	
	if selected_mini_data.is_empty():
		print("No mini selected")
		return
	
	var cost = selected_mini_data.get("cost", 3)
	print("Cost: ", cost, " gold: ", gold_manager.gold)
	
	if gold_manager.spend(cost):
		# Determine lane from tap position
		var lane = int(screen_pos.x / 160)
		lane = clamp(lane, 0, 2)
		
		# Spawn mini at tap position
		spawn_mini(selected_mini_data, screen_pos, lane, PLAYER_TEAM)
		
		# Clear selection
		selected_mini_data.clear()
		_on_gold_changed(gold_manager.gold)
		
		# Clear UI selection
		deployment_ui.clear_selection()
	else:
		# Not enough gold
		gold_display.text = "Need $%d more!" % (cost - gold_manager.gold)
		await get_tree().create_timer(1.0).timeout
		_on_gold_changed(gold_manager.gold)

func _on_gold_changed(amount):
	gold_display.text = "Gold: %d" % amount

func _on_mini_selected(mini_data):
	selected_mini_data = mini_data
	gold_display.text = "Tap field to deploy %s ($%d)" % [mini_data.get("name", "Unit"), mini_data.get("cost", 3)]

func _on_mini_deselected():
	selected_mini_data.clear()
	_on_gold_changed(gold_manager.gold)

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
	
	# Set position - clamp to valid area
	position.x = clamp(position.x, 20, 460)
	position.y = clamp(position.y, 50, 750)
	mini.position = position
	
	minis_container.add_child(mini)
	mini.add_to_group("minis")
	
	print("Spawned mini: ", mini_data.get("name", "?"), " at ", position, " lane ", lane, " team ", team)
	
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
		
		# Random spawn
		var card = enemy_deck.pick_random()
		var lane = randi() % 3
		
		# Spawn at top of lane
		var x_pos = 80 + lane * 160 + 80
		var spawn_pos = Vector2(x_pos, 60)
		
		spawn_mini(card, spawn_pos, lane, ENEMY_TEAM)
