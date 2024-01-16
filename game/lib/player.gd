class_name Player extends CharacterBody3D

@onready var camera:Camera3D = $Camera
@onready var character:Node3D = $Character
@onready var joystick_left:VirtualJoystick = $Joysticks/Left
@onready var joystick_right:VirtualJoystick = $Joysticks/Right

const walking_speed:float = 5
const running_speed:float = 8
const jump_speed:float = 5
const mouse_sensitivity:float = 0.005
const joystick_sensitivity:float = 0.05
const max_camera_angle_up:float = deg_to_rad(60)
const max_camera_angle_down:float = -deg_to_rad(75)

var anim:AnimationPlayer
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_sensitivity:float
var mouse_captured:bool = false
var look_up_action:String = "look_up"
var look_down_action:String = "look_down"
var mouse_y_axis:int = -1
var previous_position:Vector3
var hand_attachement:Node3D
var touch_controls:bool = false

func _ready():
	touch_controls = Tools.is_mobile()
	anim = character.get_node("AnimationPlayer")
	hand_attachement = character.get_node("Armature/Skeleton3D/HandAttachment/AttachmentPoint")
	if (GameState.player_state.position != Vector3.ZERO):
		set_pos()
	set_y_axis()
	if touch_controls: 
		look_sensitivity = joystick_sensitivity
	else:
		look_sensitivity = mouse_sensitivity
		capture_mouse()
	anim.play(Consts.ANIM_IDLE)

func _input(event):
	if (event is InputEventScreenDrag) or (mouse_captured and (event is InputEventMouseMotion)):
		rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(event.relative.y * look_sensitivity * mouse_y_axis)
		camera.rotation.x = clampf(camera.rotation.x, max_camera_angle_down, max_camera_angle_up)
	if mouse_captured and Input.is_action_just_pressed("cancel"):
		release_mouse()

func _physics_process(delta):
	if (mouse_captured):
		var joypad_dir: Vector2 = Input.get_vector("look_left", "look_right", look_up_action, look_down_action)
		if joypad_dir.length() > 0:
			var look_dir = joypad_dir * delta
			rotate_y(-look_dir.x * 2.0)
			camera.rotate_x(-look_dir.y)
			camera.rotation.x = clamp(camera.rotation.x - look_dir.y,  max_camera_angle_down, max_camera_angle_up)
	var on_floor = is_on_floor_only() 
	if not on_floor:
		velocity.y += -gravity * delta
	var run = Input.is_action_pressed("run")
	var speed = running_speed if run else walking_speed
	var direction = Vector3.ZERO
	if (touch_controls):
		direction = transform.basis * Vector3(joystick_left.output.x, 0, joystick_left.output.y)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
		direction = transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if  direction != Vector3.ZERO:
		if not touch_controls and not mouse_captured:
			capture_mouse()
		if run:
			if (anim.current_animation != Consts.ANIM_RUNNING):
				anim.play(Consts.ANIM_RUNNING)
		else:
			if (anim.current_animation != Consts.ANIM_WALKING):
				anim.play(Consts.ANIM_WALKING)
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			if collider == null:
				continue
			if collider.is_in_group("stairs"):
				velocity.y = 1.5
	else:
		anim.play(Consts.ANIM_IDLE)
	previous_position = position
	move_and_slide()
	if (previous_position == position):
		anim.play(Consts.ANIM_IDLE)
	if on_floor and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed

func move(pos:Vector3, rot:Vector3):
	position = pos
	rotation = rot

func handle_item():
	hand_attachement.add_child(GameState.current_item)

func unhandle_item():
	hand_attachement.remove_child(GameState.current_item)

func set_y_axis():
	if (GameState.settings.mouse_y_axis_inverted):
		mouse_y_axis = 1
	else:
		mouse_y_axis = -1
	if (GameState.settings.joypad_y_axis_inverted):
		look_up_action = "look_down"
		look_down_action = "look_up"
	else:
		look_up_action = "look_up"
		look_down_action = "look_down"

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	
func set_pos():
	position = GameState.player_state.position
	rotation = GameState.player_state.rotation
