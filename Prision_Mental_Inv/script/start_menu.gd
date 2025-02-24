extends Node2D

func _on_start_pressed() -> void:
	SceneManager.change_scene("res://scena/hospital.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
