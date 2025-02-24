extends VBoxContainer

@onready var pausa_pantalla = $"."
@onready var salir_seguro = $"../Pausa_seguro"

func _on_salir_pressed() -> void:
	pausa_pantalla.hide()
	salir_seguro.show()

func _on_continuar_pressed() -> void:
	get_tree().paused = !get_tree().paused
	pausa_pantalla.hide()
	capture_mouse()
	
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
