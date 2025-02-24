class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1
@export_range(0.5, 1.0, 0.1) var crouch_speed_multiplier: float = 0.5 # Speed multiplier while crouching
@export_range(0.5, 2.0, 0.1) var crouch_camera_height: float = 0.5 # Height adjustment for the camera when crouching
@export_range(0.5, 2.0, 0.1) var crouch_collision_height: float = 1.0 # Height of the collision shape when crouching

var jumping: bool = false
var mouse_captured: bool = false
var crouching: bool = false # Variable to track crouching state

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var camera: Camera3D = $Camera # Reference to the Camera node
@onready var collision_shape: CollisionShape3D = $CShape # Reference to the CShape node
@onready var default_camera_height: float = camera.transform.origin.y # Store the default camera height
@onready var default_collision_height: float = (collision_shape.shape as CapsuleShape3D).height # Store the default collision height
@onready var pausa_pantalla = $"../CanvasLayer/VBoxContainer"


func _ready() -> void:
	capture_mouse()
	pausa_pantalla.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	if Input.is_action_just_pressed("jump") and not crouching: # Desactivar saltos mientras se está agachado
		jumping = true
	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()
	if Input.is_action_just_pressed("exit"):
		get_tree().paused = true
		release_mouse()
		pausa_pantalla.show()
		mouse_captured = true
"
func pause_state():
	if not pausa_pantalla.visibile:
		pausa_pantalla.show()
		get_tree().paused = true
	else:
		get_tree().paused = false
		pausa_pantalla.hide()"
	

func _physics_process(delta: float) -> void:
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)


func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	var current_speed = speed * (crouch_speed_multiplier if crouching else 1.0)
	walk_vel = walk_vel.move_toward(walk_dir * current_speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func toggle_crouch() -> void:
	crouching = not crouching

	var target_camera_height = default_camera_height - crouch_camera_height if crouching else default_camera_height
	camera.transform.origin.y = target_camera_height

	var shape = collision_shape.shape as CapsuleShape3D
	shape.height = crouch_collision_height if crouching else default_collision_height


	var collision_transform = collision_shape.transform
	collision_transform.origin.y = shape.height / 2 if crouching else default_collision_height / 2
	collision_shape.transform = collision_transform
