extends VBoxContainer

@onready var pausa_pantalla = $"."

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://scena/main_menu.tscn")

func _on_continuar_pressed() -> void:
	get_tree().paused = !get_tree().paused
	pausa_pantalla.hide()
	capture_mouse()
	
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
