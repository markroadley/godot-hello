extends Node2D
class_name Mini

## Base class for all deployable units (Minis)

@export var max_hp: int = 100
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var move_speed: float = 50.0
@export var range_: float = 30.0
@export var cost: int = 3
@export var team: int = 0  # 0 = player, 1 = enemy
@export var lane: int = 1

var current_hp: int
var last_attack_time: float = 0.0
var target: Node2D = null
var is_dead: bool = false

# Visuals
var _sprite: ColorRect

signal died(mini: Mini)
signal took_damage(mini: Mini, amount: int)

func _ready():
	current_hp = max_hp
	
	# Create simple sprite
	_sprite = ColorRect.new()
	_sprite.size = Vector2(24, 24)
	_sprite.position = Vector2(-12, -12)
	_sprite.color = Color(0.8, 0.8, 0.8) if team == 0 else Color(0.8, 0.3, 0.3)
	add_child(_sprite)
	
	# Create HP bar
	var hp_bar = ColorRect.new()
	hp_bar.size = Vector2(20, 4)
	hp_bar.position = Vector2(-10, -20)
	hp_bar.color = Color(0.2, 0.8, 0.2)
	add_child(hp_bar)

func _process(delta):
	if is_dead:
		return
	
	# Find target
	if not is_instance_valid(target):
		target = find_target()
	
	# Move or attack
	if is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= range_:
			attack()
		else:
			move_toward(target.global_position, delta)
	else:
		# Move toward enemy base
		move_toward_base(delta)

func find_target() -> Node2D:
	var targets = get_tree().get_nodes_in_group("minis")
	var nearest: Node2D = null
	var nearest_dist = INF
	
	for t in targets:
		if t.team != team and not t.is_dead:
			var dist = global_position.distance_to(t.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = t
	
	# If no unit, target base
	if not nearest:
		var bases = get_tree().get_nodes_in_group("bases")
		for b in bases:
			if b.team != team:
				return b
	
	return nearest

func move_toward(pos: Vector2, delta: float):
	var dir = (pos - global_position).normalized()
	global_position += dir * move_speed * delta

func move_toward_base(delta: float):
	# Move toward enemy base Y position
	var target_y = 30 if team == 0 else 820
	var dir = Vector2.DOWN if team == 0 else Vector2.UP
	global_position += dir * move_speed * delta

func attack():
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_attack_time >= attack_speed:
		last_attack_time = now
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
			# Attack effect
			var flash = ColorRect.new()
			flash.size = Vector2(30, 30)
			flash.position = Vector2(-15, -15)
			flash.color = Color(1, 1, 0, 0.5)
			flash.modulate = Color(1, 1, 1, 1)
			add_child(flash)
			var tween = create_tween()
			tween.tween_property(flash, "modulate:a", 0.0, 0.2)
			tween.tween_callback(flash.queue_free)

func take_damage(amount: int):
	current_hp -= amount
	took_damage.emit(self, amount)
	
	# Flash red
	modulate = Color(1, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	died.emit(self)
	queue_free()
