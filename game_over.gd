extends Node2D

var final_score := 0

func _ready():
	var game_scene = get_tree().current_scene
	if game_scene.has_method("get_score"):
		final_score = game_scene.get("score")
	
	$UI/FinalScore.text = "Score: %d" % final_score
	$RestartButton.pressed.connect(_on_restart_pressed)
	$MenuButton.pressed.connect(_on_menu_pressed)

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://game.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
