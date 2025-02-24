extends StaticBody3D
class_name Puerta

# 状态变量
var is_locked := true       # 是否上锁
var is_open := false        # 是否打开
var can_interact := true    # 是否可以交互（防止动画中途操作）
@export var required_key_id := 1  # 需要的钥匙ID（在编辑器中设置）
@export var needs_key := true     # 是否需要钥匙才能打开

# 节点引用
@onready var anim_player := $AnimationPlayer

func action_use(player: Player) -> void:
	if can_interact:
		if is_locked:
			try_unlock(player)
		else:
			toggle_door()

# 尝试用玩家持有的钥匙解锁
func try_unlock(player: Player) -> void:
	if needs_key:
		if player.current_key_id == required_key_id:
			is_locked = false
			can_interact = false
			anim_player.play("unlock")
		else:
			# 显示提示UI或播放拒绝音效
			print("需要钥匙ID: ", required_key_id)
			anim_player.play("Locked")
	else:
		is_locked = false

func toggle_door() -> void:
	can_interact = false
	if is_open:
		close_door()
	else:
		open_door()

func open_door() -> void:
	is_open = true
	anim_player.play("abrir")

func close_door() -> void:
	is_open = false
	anim_player.play("cerrar")

# 连接动画播放完成信号
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	can_interact = true
