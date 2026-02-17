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

const PLAYER_TEAM = 0
const ENEMY_TEAM = 1

func _ready():
	gold_manager.gold_changed.connect(_on_gold_changed)
	deployment_ui.mini_selected.connect(_on_mini_selected)
	enemy_base.add_to_group("bases")
	player_base.add_to_group("bases")
	
	# Start enemy AI
	start_enemy_spawns()

func _process(delta):
	if is_game_over:
		return
	
	game_time += delta
	
	# Update gold display
	gold_display.text = "Gold: %d" % gold_manager.gold
	
	# Check win condition
	if enemy_base.has_method("get_hp"):
		if enemy_base.get("current_hp", 1000) <= 0:
			end_game(PLAYER_TEAM)
	
	if player_base.has_method("get_hp"):
		if player_base.get("current_hp", 1000) <= 0:
			end_game(ENEMY_TEAM)

func _on_gold_changed(amount):
	gold_display.text = "Gold: %d" % amount

func _on_mini_selected(mini_data):
	# Player has selected a mini to deploy
	# Next tap on the map will spawn it
	pass

func spawn_mini(mini_data: Dictionary, lane: int, team: int):
	var mini = preload("res://src/units/mini.gd").new()
	
	mini.max_hp = mini_data.get("hp", 100)
	mini.damage = mini_data.get("damage", 10)
	mini.move_speed = mini_data.get("speed", 50)
	mini.range_ = mini_data.get("range", 30)
	mini.cost = mini_data.get("cost", 3)
	mini.attack_speed = mini_data.get("attack_speed", 1.0)
	mini.team = team
	mini.lane = lane
	
	# Set position based on lane and team
	var x_pos = 80 if team == PLAYER_TEAM else 400
	var y_pos = lane * (854.0 / 3.0) + (854.0 / 6.0)
	mini.position = Vector2(x_pos, y_pos)
	
	minis_container.add_child(mini)
	mini.add_to_group("minis")
	
	return mini

func end_game(winner: int):
	is_game_over = true
	game_over.emit(winner)

# Simple enemy AI
func start_enemy_spawns():
	var enemy_deck = [
		{"id": "goblin", "name": "Goblin", "cost": 2, "hp": 50, "damage": 8, "speed": 60, "range": 20, "attack_speed": 1.5, "color": Color(0.5, 0.8, 0.3)},
		{"id": "orc", "name": "Orc", "cost": 4, "hp": 100, "damage": 15, "speed": 35, "range": 25, "attack_speed": 0.8, "color": Color(0.4, 0.6, 0.3)},
	]
	
	while not is_game_over:
		await get_tree().create_timer(5.0).timeout
		if is_game_over:
			break
		
		# Random spawn
		var card = enemy_deck.pick_random()
		var lane = randi() % 3
		spawn_mini(card, lane, ENEMY_TEAM)
