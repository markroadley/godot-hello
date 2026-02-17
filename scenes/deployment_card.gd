extends ColorRect

var card_data: Dictionary = {}
var _is_selected: bool = false

func setup(data: Dictionary):
	card_data = data
	$Name.text = data.get("name", "Unit")
	$Cost.text = str(data.get("cost", 3))
	$Icon.color = data.get("color", Color(0.8, 0.8, 0.8))

func set_selected(selected: bool):
	_is_selected = selected
	if selected:
		color = Color(0.5, 0.5, 0.3, 1)
	else:
		color = Color(0.2, 0.2, 0.25, 1)
