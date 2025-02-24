extends RigidBody3D
class_name Key

@export var key_id := 1

@onready var drop_sound_player: AudioStreamPlayer3D = $DropSoundPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_picked := false

func _ready():
	contact_monitor = true
	continuous_cd = true
	max_contacts_reported = 100

	# 确保使用凸包形状（ConvexPolygonShape3D）
	var mesh: Mesh = $"环体_003".mesh
	if mesh:
		# 生成凸包时启用精简和简化（提高性能）
		var convex_shape = mesh.create_convex_shape()
		$CollisionShape3D.shape = convex_shape
	connect("body_entered", _on_body_entered)

func try_pick_up(player: Player) -> bool:
	if !is_picked:
		is_picked = true
		freeze = true
		visible = false
		collision_shape.set_deferred("disabled", true)
		return true
	return false

func drop(pos: Vector3, force: Vector3):
	is_picked = false
	# 立即启用碰撞形状（下一帧物理步骤前）
	collision_shape.disabled = false
	freeze = false
	visible = true
	# 重置物理状态
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform.origin = pos
	# 确保物理更新
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_SLEEPING, false)
	apply_central_impulse(force)

func _on_body_entered(body):
	print("碰撞对象:", body.name, " | 是否地板组:", body.is_in_group("Floor"))
	if body.is_in_group("Floor"):
		var current_time = Time.get_ticks_msec()
		var impact_speed = linear_velocity.length()
		print("碰撞速度:", impact_speed)
		drop_sound_player.play()
