# 玩家角色脚本，继承自 CharacterBody3D
# Script de personaje del jugador, que hereda de CharacterBody3D
class_name Player extends CharacterBody3D

# 使用 @export 分类和范围限制在编辑器中暴露参数
# Utiliza @export para categorizar y limitar rangos al exponer parámetros en el editor
@export_category("Player")
@export_range(1, 35, 1) var speed: float = 10       # 移动速度 (米/秒)
												   # Velocidad de movimiento (m/s)
@export_range(10, 400, 1) var acceleration: float = 100  # 加速度 (米/秒²)
													   # Aceleración (m/s²)

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1  # 跳跃高度 (米)
													   # Altura de salto (m)
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1  # 鼠标灵敏度
																	  # Sensibilidad del ratón
@export_range(0.5, 1.0, 0.1) var crouch_speed_multiplier: float = 0.5  # 蹲下时速度倍率
																	   # Multiplicador de velocidad al agacharse
@export_range(0.5, 2.0, 0.1) var crouch_camera_height: float = 0.5     # 蹲下时相机高度调整
																	   # Ajuste de altura de la cámara al agacharse
@export_range(0.5, 2.0, 0.1) var crouch_collision_height: float = 1.0  # 蹲下时碰撞体高度
																	   # Altura de colisión al agacharse
@export var pickup_range := 3.0  # 拾取距离（米）

# 状态变量
# Variables de estado
var jumping: bool = false          # 是否正在跳跃
								   # Indica si se está saltando
var mouse_captured: bool = false   # 是否捕获鼠标
								   # Indica si el ratón está capturado
var crouching: bool = false        # 是否处于蹲下状态
								   # Indica si se está agachando

# 物理参数
# Parámetros físicos
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")  # 从项目设置获取重力值
																			   # Obtiene el valor de la gravedad desde la configuración del proyecto

# 移动和视角方向
# Direcciones de movimiento y de la vista
var move_dir: Vector2  # 移动输入方向（键盘输入）
					   # Dirección de movimiento (entrada del teclado)
var look_dir: Vector2  # 视角移动方向（鼠标输入）
					   # Dirección de la vista (entrada del ratón)

# 速度分量
# Componentes de velocidad
var walk_vel: Vector3  # 行走速度
					   # Velocidad de caminar
var grav_vel: Vector3  # 重力速度
					   # Velocidad de la gravedad
var jump_vel: Vector3  # 跳跃速度
					   # Velocidad de salto

var current_key_id := -1          # 当前手持钥匙ID

var held_key_instance: RigidBody3D  = null # 持有的钥匙实例

var keys_in_inventory: Array = []  # 背包钥匙数组（存储字典{id, instance}）

var last_seen_key: Node = null

# 节点引用
# Referencias a nodos
@onready var camera: Camera3D = $Camera  # 摄像机节点
										  # Nodo de la cámara
@onready var collision_shape: CollisionShape3D = $CShape  # 碰撞形状节点
														   # Nodo de la forma de colisión
@onready var default_camera_height: float = camera.transform.origin.y  # 默认摄像机高度
																	   # Altura predeterminada de la cámara
@onready var default_collision_height: float = (collision_shape.shape as CapsuleShape3D).height  # 默认碰撞高度
																								   # Altura predeterminada de colisión
@onready var pausa_pantalla = $"../Pausa_pantalla/Pausa" # 暂停菜单界面
																  # Interfaz del menú de pausa
@onready var salir_seguro = $"../Pausa_pantalla/Pausa_seguro"  # 暂停菜单界面
																  # Interfaz del menú de pausa
@onready var she_xian = $Camera/RayCast3D

@onready var hand_position: Marker3D = $Camera/HandPosition  # 手持位置节点

@onready var interaction_label: Label = $"../HUD/InteractionPrompt"

@onready var punto_medio = $Punto_Medio

var current_target: Node = null  # 当前瞄准的可交互对象

func _ready() -> void:
	capture_mouse()    # 游戏开始时捕获鼠标
					   # Al inicio del juego, captura el ratón
	pausa_pantalla.hide()  # 隐藏暂停菜单
	salir_seguro.hide()	   # Oculta el menú de pausa


func _unhandled_input(event: InputEvent) -> void:
	# 处理鼠标移动输入
	# Procesa la entrada de movimiento del ratón
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001  # 转换鼠标移动量为较小的值
										   # Convierte la cantidad de movimiento del ratón a un valor pequeño
		if mouse_captured:
			_rotate_camera()  # 旋转摄像机  # Rota la cámara
	
	if Input.is_action_just_pressed("jump") and not crouching:
		jumping = true	# 跳跃输入（蹲下时不可跳跃）
	# Entrada para salto (no se puede saltar mientras se agacha)
	

	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()	# 蹲下输入
	# Entrada para agacharse
	
	# 暂停游戏输入
	# Entrada para pausar el juego
	if Input.is_action_just_pressed("exit"):
		get_tree().paused = true  # 暂停游戏
								  # Pausa el juego
		release_mouse()           # 释放鼠标
								  # Libera el ratón
		pausa_pantalla.show()    # 显示暂停菜单
								  # Muestra el menú de pausa
		mouse_captured = true
		
	if Input.is_action_just_pressed("action_use"):
	# 优先处理门
		var handled_door = process_raycast()
	
	# 如果没有处理门，尝试拾取钥匙
		if !handled_door:
			try_pick_up_key()	
		
	if event.is_action_pressed("drop_key"):
		drop_key()


func try_pick_up_key():
	var space_state = get_world_3d().direct_space_state
	var camera_pos = camera.global_transform.origin
	var ray_end = camera_pos + -camera.global_transform.basis.z * pickup_range
	
	var query = PhysicsRayQueryParameters3D.create(camera_pos, ray_end)
	query.collide_with_bodies = true  # 仅检测刚体
	
	var result = space_state.intersect_ray(query)
	if result and result.collider is Key:  # 直接类型检查
		var key = result.collider
		if key.try_pick_up(self):
			collect_key(key.key_id, key)

func collect_key(key_id: int, key_instance: RigidBody3D):
	if current_key_id != -1:
		drop_key()
	
	current_key_id = key_id
	held_key_instance = key_instance
	show_key_in_hand(key_id)

func drop_key():
	if held_key_instance:
		var camera_forward = -camera.global_transform.basis.z.normalized()
		var ray_length = 1.5 # 射线检测距离
		
		# 执行射线检测避免穿墙
		var query = PhysicsRayQueryParameters3D.create(
			camera.global_position,
			camera.global_position + camera_forward * ray_length
		)
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		
		var drop_pos = camera.global_position + camera_forward * ray_length
		if result:
			drop_pos = result.position + result.normal * 0.2 # 沿法线方向偏移
		
		# 调整力度
		var throw_force = camera_forward * 4.0 + Vector3.UP * 1.5
		
		held_key_instance.drop(drop_pos, throw_force)
		clear_hand()

func show_key_in_hand(key_id: int):
	# 隐藏物理钥匙
	held_key_instance.visible = false
	# 显示手持模型（可选）
	var hand_model = preload("res://scena/Key.tscn").instantiate()
	hand_position.add_child(hand_model)

func clear_hand():
	current_key_id = -1
	for child in hand_position.get_children():
		child.queue_free()


# player.gd 修正后的process_raycast函数
func process_raycast() -> bool:
	if she_xian.is_colliding():
		var collider = she_xian.get_collider()
		if collider is Puerta:
			collider.action_use(self)
			return true  # 表示已处理门
	return false


func _update_interaction_prompt():
	var space_state = get_world_3d().direct_space_state
	var camera_pos = camera.global_transform.origin
	var ray_end = camera_pos + -camera.global_transform.basis.z * pickup_range
	
	var query = PhysicsRayQueryParameters3D.create(camera_pos, ray_end)
	query.collide_with_bodies = true  # 确保检测刚体
	
	var result = space_state.intersect_ray(query)
	
	# 重置提示
	punto_medio.visible = true
	interaction_label.visible = false
	current_target = null
	
# player.gd 的 _update_interaction_prompt 函数
	if result:
		var collider = result.collider
		if collider is Key:  # 直接类型检查更可靠
			var distance = global_position.distance_to(collider.global_position)
			if !collider.is_picked and distance <= pickup_range:
				current_target = collider
				_show_prompt("Ⓔ")
				punto_medio.visible = false
				
		# 检查是否是门
		elif collider is Puerta:
			punto_medio.visible = false  # 隐藏准星
			_show_prompt("Ⓔ")
				
	
func _show_prompt(text: String):
	interaction_label.text = text
	interaction_label.visible = true

func _physics_process(delta: float) -> void:
	_update_interaction_prompt()
	var space_state = get_world_3d().direct_space_state
	var camera_pos = camera.global_transform.origin
	var ray_end = camera_pos + -camera.global_transform.basis.z * pickup_range
	
	var query = PhysicsRayQueryParameters3D.create(camera_pos, ray_end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_method("try_pick_up"):
		last_seen_key = result.collider
		# 显示UI提示（例如："按E拾取钥匙"）
	else:
		last_seen_key = null
	# 计算组合速度：行走 + 重力 + 跳跃
	# Calcula la velocidad resultante: caminar + gravedad + salto
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()  # 应用移动并处理碰撞
					  # Aplica el movimiento y maneja las colisiones

func capture_mouse() -> void:
	# 捕获鼠标并隐藏光标
	# Captura el ratón y oculta el cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	# 释放鼠标并显示光标
	# Libera el ratón y muestra el cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	# 水平旋转摄像机（左右看）
	# Rota horizontalmente la cámara (mirar a la izquierda y a la derecha)
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	# 垂直旋转摄像机（上下看），限制角度在 -90° 到 90° 之间
	# Rota verticalmente la cámara (mirar hacia arriba y hacia abajo), limitando el ángulo entre -90° y 90°
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _walk(delta: float) -> Vector3:
	# 获取键盘输入方向（WASD）
	# Obtiene la dirección de entrada del teclado (WASD)
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	
	# 根据摄像机方向计算移动方向
	# Calcula la dirección de movimiento basándose en la orientación de la cámara
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	
	# 计算当前速度（蹲下时应用速度倍率）
	# Calcula la velocidad actual (aplicando multiplicador si se está agachando)
	var current_speed = speed * (crouch_speed_multiplier if crouching else 1.0)
	
	# 使用加速度平滑调整速度
	# Ajusta la velocidad suavemente utilizando aceleración
	walk_vel = walk_vel.move_toward(walk_dir * current_speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	# 当接触地面时重置重力速度，否则应用重力加速度
	# Reinicia la velocidad de la gravedad al tocar el suelo, de lo contrario aplica aceleración gravitatoria
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		# 当在地面时计算跳跃初速度（使用动能公式 v = sqrt(2gh)）
		# Si está en el suelo, calcula la velocidad inicial del salto (usando la fórmula v = sqrt(2gh))
		if is_on_floor(): 
			jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	
	# 在空中时逐渐减少跳跃速度
	# Mientras está en el aire, reduce gradualmente la velocidad del salto
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func toggle_crouch() -> void:
	# 切换蹲下状态
	# Alterna el estado de agacharse
	crouching = not crouching

	# 调整摄像机高度
	# Ajusta la altura de la cámara
	var target_camera_height = default_camera_height - crouch_camera_height if crouching else default_camera_height
	camera.transform.origin.y = target_camera_height

	# 调整碰撞体形状
	# Ajusta la forma del colisionador
	var shape = collision_shape.shape as CapsuleShape3D
	shape.height = crouch_collision_height if crouching else default_collision_height

	# 调整碰撞体位置（保持底部对齐）
	# Ajusta la posición del colisionador (manteniendo la alineación inferior)
	var collision_transform = collision_shape.transform
	collision_transform.origin.y = shape.height / 2 if crouching else default_collision_height / 2
	collision_shape.transform = collision_transform



extends KinematicBody

var equipped_item : Item = null  # The currently equipped item
var inventory : Node  # Reference to the Inventory system

func _ready():
	inventory = get_node("/root/Inventory")  # Reference to the Inventory script

# Equip the selected item
func equip_item(item : Item):
	equipped_item = item
	print("Equipped item: ", item.name)
	# You can place the item in the player's hand, model, or whatever you'd like to show

# Drop the currently equipped item
func drop_item():
	if equipped_item != null:
		inventory.remove_item(equipped_item)  # Remove from inventory
		print("Dropped item: ", equipped_item.name)
		equipped_item = null  # Clear the equipped item
