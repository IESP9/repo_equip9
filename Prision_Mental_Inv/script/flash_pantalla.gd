extends Control



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "salir":
		$AnimationPlayer.play("entra")
		
	if anim_name == "entra":
		get_tree().change_scene_to_file("res://scena/main_menu.tscn")
