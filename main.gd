extends Node2D

var time := 0.0

func _process(delta):
	time += delta
	$Label.scale = Vector2.ONE * (1.0 + sin(time * 2.0) * 0.1)
