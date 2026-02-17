extends Node2D
class_name Base

## Enemy or player base that can be destroyed

signal base_destroyed(team: int)

@export var team: int = 0  # 0 = player, 1 = enemy
@export var max_hp: int = 1000
@export var starting_hp: int = 1000

var current_hp: int

@onready var hp_bar = $HPBar
@onready var sprite = $Sprite

func _ready():
	current_hp = starting_hp

func take_damage(amount: int):
	current_hp -= amount
	
	# Update HP bar
	if hp_bar:
		var hp_pct = float(current_hp) / float(max_hp)
		hp_bar.size.x = 96 * hp_pct
	
	# Flash red
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		base_destroyed.emit(team)
		queue_free()

func get_hp() -> int:
	return current_hp
