extends Node
class_name GoldManager

## Manages gold economy for a team

signal gold_changed(new_amount: int)
signal gold_spent(amount: int)

@export var team: int = 0  # 0 = player, 1 = enemy
@export var starting_gold: int = 5
@export var gold_per_tick: float = 1.0  # Gold per second
@export var tick_interval: float = 1.0  # Seconds between ticks

var gold: int = 0
var _timer: float = 0.0

func _ready():
	gold = starting_gold
	gold_changed.emit(gold)

func _process(delta):
	_timer += delta
	if _timer >= tick_interval:
		_timer -= tick_interval
		add_gold(gold_per_tick)

func add_gold(amount: float):
	var amount_int = int(amount)
	if amount_int > 0:
		gold += amount_int
		gold_changed.emit(gold)

func spend(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_spent.emit(amount)
		gold_changed.emit(gold)
		return true
	return false

func can_afford(amount: int) -> bool:
	return gold >= amount
