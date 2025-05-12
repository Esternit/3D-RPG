extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#Stores X/Y direction the player is trying to look in
var _look = Vector2.ZERO

@export var mouse_sensitivity = 0.00075
@export var min_boundary: float = -60
@export var max_boundary: float = 10
@export var animation_decay: float = 20.0



@onready var horizontal_pivot: Node3D = $HorizontalPivot
@onready var vertical_pivot: Node3D = $HorizontalPivot/VerticalPivot
@onready var rig_pivot = $RigPivot
@onready var rig = $RigPivot/Rig


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	frame_camera_rotation()

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := get_movement_direction()
	
	rig.update_animation_tree(direction)
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_toward_direction(direction, delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	
	move_and_slide()
	
	
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_look = -event.relative * mouse_sensitivity
	
	if rig.is_idle() and event.is_action_pressed("click"):
		slash_attack()

func get_movement_direction() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_vector := Vector3(input_dir.x, 0, input_dir.y).normalized()
	return horizontal_pivot.global_transform.basis * input_vector


func frame_camera_rotation():
	horizontal_pivot.rotate_y(_look.x)
	vertical_pivot.rotate_x(_look.y)
	
	vertical_pivot.rotation.x = clampf(
		vertical_pivot.rotation.x, 
		deg_to_rad(min_boundary), 
		deg_to_rad(max_boundary)
		)

	_look = Vector2.ZERO
	
func look_toward_direction(direction: Vector3, delta: float) -> void:
	var target_transform: Transform3D = rig_pivot.global_transform.looking_at(
		rig_pivot.global_position + direction,
		Vector3.UP,
		true
	)
	
	rig_pivot.global_transform = rig_pivot.global_transform.interpolate_with(
		target_transform,
		1.0 - exp(-animation_decay * delta)
	)

func slash_attack() -> void:
	rig.travel("Slash")



