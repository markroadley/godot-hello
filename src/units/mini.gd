extends Node2D
class_name Mini

## Base class for all deployable units (Minis)

@export var max_hp: int = 100
@export var damage: int = 10
@export var attack_speed: float = 1.0  # Attacks per second
@export var move_speed: float = 50.0
@export var range_: float = 30.0
@export var cost: int = 3
@export var team: int = 0  # 0 = player, 1 = enemy
@export var lane: int = 1  # 0, 1, 2 (left, center, right)

var current_hp: int
var last_attack_time: float = 0.0
var target: Node2D = null
var is_dead: bool = false

signal died(mini: Mini)
signal took_damage(mini: Mini, amount: int)

func _ready():
	current_hp = max_hp

func _process(delta):
	if is_dead:
		return
	
	# Find target if none
	if not is_instance_valid(target):
		target = find_nearest_target()
	
	# Move toward target or lane direction
	if is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= range_:
			attack(delta)
		else:
			move_toward(target.global_position, delta)
	else:
		# Move along lane toward enemy base
		move_along_lane(delta)

func find_nearest_target() -> Node2D:
	var targets = get_tree().get_nodes_in_group("minis")
	var nearest: Node2D = null
	var nearest_dist = INF
	
	for t in targets:
		if t.team != team and not t.is_dead:
			# Prefer units in same lane
			var lane_bonus = 0 if t.lane == lane else 1000
			var dist = global_position.distance_to(t.global_position) + lane_bonus
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = t
	
	# If no unit found, target enemy base
	if not nearest:
		nearest = get_enemy_base()
	
	return nearest

func get_enemy_base() -> Node2D:
	var bases = get_tree().get_nodes_in_group("bases")
	for b in bases:
		if b.team != team:
			return b
	return null

func move_toward(pos: Vector2, delta: float):
	var dir = (pos - global_position).normalized()
	global_position += dir * move_speed * delta
	# Clamp to lane bounds
	global_position.y = clamp(global_position.y, 0, 854)

func move_along_lane(delta: float):
	var dir = Vector2.RIGHT if team == 0 else Vector2.LEFT
	global_position += dir * move_speed * delta
	global_position.y = lane * (854.0 / 3.0) + (854.0 / 6.0)

func attack(delta: float):
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_attack_time >= attack_speed:
		last_attack_time = now
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)

func take_damage(amount: int):
	current_hp -= amount
	took_damage.emit(self, amount)
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	died.emit(self)
	queue_free()
