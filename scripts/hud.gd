extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.set_hud(self)
	get_node("End").hide()
	get_node("Indicators").get_node("CreatingRouteIndicator").hide()

func set_score(score):
	get_node("Score").get_node("ScoreLabel").text = str(score)

func show_end():
	get_node("End").show()

func toggle_creating_route_indicator():
	if get_node("Indicators").get_node("CreatingRouteIndicator").is_visible():
		get_node("Indicators").get_node("CreatingRouteIndicator").hide()
	else:
		get_node("Indicators").get_node("CreatingRouteIndicator").show()

# start button pressed
func _on_start_button_pressed() -> void:
	get_node("Start").hide()
	Game.start()
