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
## Drag-Drop System
var is_dragging: bool = false
var drag_position: Vector2 = Vector2.ZERO
var ghost_preview: Sprite2D = null
var deployment_zone: ColorRect = null
var selected_card_index: int = -1

# Deployment zone config (y-position where valid drop ends)
const TRAY_HEIGHT = 120
const DEPLOY_ZONE_TOP = 400  # How far up the deployment zone extends

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
	
	# Show version
	_create_version_display()
	
	print("GameManager ready!")

func _create_version_display():
	var version = Label.new()
	version.text = "v0.1.2"
	version.position = Vector2(400, 10)
	version.add_theme_font_size_override("font_size", 16)
	version.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	game_layer.add_child(version)

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
	var cost = card_data.get("cost", 3)
	
	# Check if player has enough gold
	if gold_manager.gold < cost:
		gold_display.text = "Need $%d more!" % (cost - gold_manager.gold)
		await get_tree().create_timer(1.0).timeout
		_on_gold_changed(gold_manager.gold)
		return
	
	# Enter drag mode - don't spawn yet
	selected_mini_data = card_data
	selected_card_index = index
	is_dragging = true
	
	gold_display.text = "Drag to deploy"
	
	# Create ghost preview
	_create_ghost_preview(card_data)
	
	# Show deployment zone
	_create_deployment_zone()
	
	# Highlight selected card
	for i in range(hand_buttons.size()):
		var btn = hand_buttons[i]
		var style = btn.get_theme_stylebox("normal").duplicate()
		if i == index:
			style.bg_color = Color(0.5, 0.5, 0.3, 1)
		else:
			style.bg_color = Color(0.2, 0.2, 0.25, 1)
		btn.add_theme_stylebox_override("normal", style)
	
	print("Started dragging: ", card_data.get("name"))

func _create_ghost_preview(card_data: Dictionary):
	# Remove existing ghost
	if ghost_preview:
		ghost_preview.queue_free()
	
	# Create ghost sprite
	ghost_preview = Sprite2D.new()
	var color = card_data.get("color", Color.CYAN)
	
	# Create a simple circle texture
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 28:
				img.set_pixel(x, y, color)
	
	var tex = ImageTexture.create_from_image(img)
	ghost_preview.texture = tex
	ghost_preview.modulate.a = 0.7
	ghost_preview.scale = Vector2(0.8, 0.8)
	game_layer.add_child(ghost_preview)
	ghost_preview.visible = false

func _create_deployment_zone():
	# Remove existing zone
	if deployment_zone:
		deployment_zone.queue_free()
	
	# Create deployment zone (blue rectangle showing valid drop area)
	deployment_zone = ColorRect.new()
	deployment_zone.color = Color(0.2, 0.4, 1.0, 0.3)  # Semi-transparent blue
	deployment_zone.position = Vector2(0, DEPLOY_ZONE_TOP)
	deployment_zone.size = Vector2(480, 854 - TRAY_HEIGHT - DEPLOY_ZONE_TOP)
	game_layer.add_child(deployment_zone)
	deployment_zone.visible = false

func _input(event):
	if is_dragging:
		# Cancel drag with escape or right-click
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_end_drag()
			gold_display.text = "Cancelled"
			return
		
		# Track drag position
		if event is InputEventMouseMotion:
			drag_position = event.position
			_update_ghost_position(drag_position)
		elif event is InputEventScreenTouch:
			if event.position != Vector2.ZERO:
				drag_position = event.position
				_update_ghost_position(drag_position)
		
		# Handle release - drop the unit
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_handle_drop(drag_position)
		elif event is InputEventScreenTouch:
			if not event.pressed:
				_handle_drop(drag_position)

func _update_ghost_position(screen_pos: Vector2):
	if ghost_preview and deployment_zone:
		var in_zone = _is_valid_drop_position(screen_pos)
		ghost_preview.visible = true
		ghost_preview.position = screen_pos
		
		# Change color based on valid/invalid
		if in_zone:
			ghost_preview.modulate = Color(0.3, 1.0, 0.3, 0.7)  # Green = valid
		else:
			ghost_preview.modulate = Color(1.0, 0.3, 0.3, 0.7)  # Red = invalid

func _is_valid_drop_position(screen_pos: Vector2) -> bool:
	# Must be above tray
	if screen_pos.y > 854 - TRAY_HEIGHT:
		return false
	# Must be in deployment zone (below the top line)
	if screen_pos.y < DEPLOY_ZONE_TOP:
		return false
	# Must have enough gold
	var cost = selected_mini_data.get("cost", 3)
	if gold_manager.gold < cost:
		return false
	return true

func _handle_drop(screen_pos: Vector2):
	if not is_dragging:
		return
	
	# Check if valid drop position
	if _is_valid_drop_position(screen_pos):
		var cost = selected_mini_data.get("cost", 3)
		if gold_manager.spend(cost):
			# Spawn at drop position
			spawn_mini(selected_mini_data, screen_pos, 0, PLAYER_TEAM)
			_on_gold_changed(gold_manager.gold)
			gold_display.text = "Deployed %s!" % selected_mini_data.get("name", "Unit")
			print("Dropped unit at: ", screen_pos)
		else:
			gold_display.text = "Not enough gold!"
	else:
		gold_display.text = "Invalid drop zone!"
		print("Invalid drop at: ", screen_pos)
	
	# End drag mode
	_end_drag()

func _end_drag():
	is_dragging = false
	selected_mini_data = {}
	selected_card_index = -1
	
	# Clean up visuals
	if ghost_preview:
		ghost_preview.queue_free()
		ghost_preview = null
	if deployment_zone:
		deployment_zone.queue_free()
		deployment_zone = null
	
	# Reset button highlights
	for btn in hand_buttons:
		var style = btn.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color(0.2, 0.2, 0.25, 1)
		btn.add_theme_stylebox_override("normal", style)
	
	_on_gold_changed(gold_manager.gold)

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
