extends VBoxContainer

@onready var pausa_pantalla = $"../Pausa"
@onready var salir_seguro = $"."


func _on_si_pressed() -> void:
	SceneManager.change_scene("res://scena/start_menu.tscn")
	get_tree().paused = !get_tree().paused


func _on_no_pressed() -> void:
	salir_seguro.hide()
	pausa_pantalla.show()

	
