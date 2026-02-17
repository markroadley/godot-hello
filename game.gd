extends Control

var score := 0
var time_left := 10.0

func _ready():
	$CenterContainer/VBox/Timer.text = "Time: %.1f" % time_left
	$CenterContainer/VBox/Score.text = "Score: %d" % score

func _process(delta):
	time_left -= delta
	$CenterContainer/VBox/Timer.text = "Time: %.1f" % time_left
	$CenterContainer/VBox/Score.text = "Score: %d" % score
	
	if time_left <= 0:
		get_tree().change_scene_to_file("res://game_over.tscn")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		score += 1
		spawn_click_effect(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		score += 1
		spawn_click_effect(event.position)

func spawn_click_effect(pos):
	var circle = ColorRect.new()
	circle.size = Vector2(30, 30)
	circle.position = pos - Vector2(15, 15)
	circle.color = Color(1, 0.5, 0, 0.8)
	circle.modulate = Color(1, 1, 1, 1)
	add_child(circle)
	
	var tween = create_tween()
	tween.tween_property(circle, "modulate:a", 0.0, 0.3)
	tween.tween_property(circle, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_callback(circle.queue_free)
