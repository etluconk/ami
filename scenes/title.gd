extends Node2D

var elapsed_time := 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	elapsed_time += delta

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	pass
