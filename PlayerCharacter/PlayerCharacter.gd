extends KinematicBody

onready var player_mesh_pivot : Spatial = $MeshPivot
onready var mesh : Spatial = $MeshPivot/Armature
onready var animation_tree : AnimationTree = $MeshPivot/AnimationTree
onready var camera_pivot : Spatial = $CameraPivot

var camera_offset : Vector3 = Vector3(0,0,0)
var camera_transform : Transform

const RUNNING_SPEED = 30.0
const AIMING_RUN_SPEED = 5.0

var direction_forward_axis : Vector3
var direction_side_axis :Vector3
var direction : Vector3
var speed : float = RUNNING_SPEED
var velocity : Vector3
var last_velocity : Vector3
var acceleration : Vector3
var tilt : Vector3
var target_position : Vector3
var rotation_transform : Transform
var up_down_movement : Vector3 = Vector3.ZERO

const BOUNCE_THRESHOLD : float = 10.0
const ACCELERATION_RATE : float = 3.0
const TURN_RATE : float = 3.0
const TILT_RATE : float = 3.0
const TILT_SCALE : float = 0.2
const GRAVITY : float = 70.0
const TERMINAL_GRAVITY_VELOCITY_Y : float = -50.0
const TERMINAL_JETPACK_VELOCITY_Y : float = 50.0
const JETPACK_ACCELERATION : float = 100.0
const BOUNCE_FORCE : float = 20.0

var jetpack_charge : float = 1.0
var JETPACK_DEPLETION_RATE : float = 0.5
var JETPACK_RECHARGE_RATE : float = 0.5

onready var jetpack_charge_bar = $PlayerUI/JetpackCharge

var aim_down_sights_progress : float = 0.0
var AIM_DOWN_SIGHTS_SPEED : float = 2.0
var UNAIM_DOWN_SIGHTS_SPEED : float = 4.0

func _ready():
	camera_pivot.set_as_toplevel(true)
	mesh.connect("bounce",self,"on_bounce")
	
func _process(delta):
	set_camera_follow()
	get_camera_transform()
	get_input(delta)
	recharge_jetpack(delta)
#	$DebugLabel.text = str('u/d vel: ',up_down_movement.y)
	
func _physics_process(delta):
	calculate_velocity(delta)
	find_velocity_facing_direction()
	find_acceleration()
	find_tilt_vector()
	find_last_velocity()
	move()
	apply_gravity(delta)
	apply_jetpack(delta)
	rotate_towards_acceleration(delta)
	rotate_towards_velocity(delta)
	blend_idle_run()
	
func recharge_jetpack(delta):
	if not Input.is_action_pressed("engage_jetpack"):
		change_jetpack_charge(JETPACK_RECHARGE_RATE * delta)
	
func change_jetpack_charge(delta_charge):
	jetpack_charge = clamp(jetpack_charge + delta_charge, 0.0, 1.0)
	jetpack_charge_bar.value = jetpack_charge
	
func set_camera_follow():
	camera_pivot.follow_me(translation + camera_offset)
	
func get_camera_transform():
	camera_transform = camera_pivot.give_direction()

func get_input(delta):
	direction_forward_axis = (-Input.get_action_strength("move_forward") + Input.get_action_strength("move_backwards")) * camera_transform.basis.z
	direction_side_axis = (-Input.get_action_strength("move_left") + Input.get_action_strength("move_right")) * camera_transform.basis.x
	direction = (direction_forward_axis + direction_side_axis).normalized()
	
	if Input.is_action_pressed("aim_down_sights"):
		change_aim_down_sights_progress(AIM_DOWN_SIGHTS_SPEED * delta)
	else:
		change_aim_down_sights_progress(-UNAIM_DOWN_SIGHTS_SPEED * delta)

func change_aim_down_sights_progress(delta_ads):
	aim_down_sights_progress = clamp(aim_down_sights_progress + delta_ads, 0.0, 1.0)
	var crosshair_alpha = aim_down_sights_progress
	if aim_down_sights_progress == 1.0:
		$PlayerUI/Crosshair.modulate = Color(1,0,0,crosshair_alpha)
	else:
		$PlayerUI/Crosshair.modulate = Color(1,1,1,crosshair_alpha)
	$CameraPivot/CameraPivot/SpringArm.spring_length = lerp(5.0,2.5,aim_down_sights_progress)
	camera_offset = lerp(Vector3.ZERO,Vector3(0,1,0)+camera_pivot.global_transform.basis.x,aim_down_sights_progress)
	speed = lerp(RUNNING_SPEED,AIMING_RUN_SPEED,aim_down_sights_progress)

func move():
	velocity = move_and_slide(velocity,Vector3.UP)

func calculate_velocity(delta):
	if direction != Vector3.ZERO:
		velocity = velocity.linear_interpolate(direction*speed,ACCELERATION_RATE * delta)
	else:
		velocity = velocity.linear_interpolate(Vector3.ZERO,ACCELERATION_RATE * delta)

func find_velocity_facing_direction():
	if velocity != Vector3.ZERO:
		rotation_transform = mesh.transform.looking_at(-velocity,Vector3.UP)

func rotate_towards_velocity(delta):
	if rotation_transform != null:
		mesh.transform = mesh.transform.interpolate_with(rotation_transform, TURN_RATE * delta)

func find_last_velocity():
	last_velocity = velocity

func find_acceleration():
	acceleration = velocity - last_velocity

func find_tilt_vector():
	tilt = acceleration.cross(Vector3.UP)
	
func rotate_towards_acceleration(delta):
	if tilt != null:
		player_mesh_pivot.rotation = lerp(player_mesh_pivot.rotation, -tilt * TILT_SCALE, TILT_RATE * delta)

func blend_idle_run():
	if is_on_floor():
		animation_tree.set("parameters/IdleRunBlend/blend_amount",clamp(velocity.length()/RUNNING_SPEED,0,1))
	else:
		animation_tree.set("parameters/IdleRunBlend/blend_amount",0)

func apply_jetpack(delta):
	if Input.is_action_pressed("engage_jetpack") and jetpack_charge > 0:
		print('jetpack activate!')
		up_down_movement.y += JETPACK_ACCELERATION * delta
		up_down_movement.y = clamp(up_down_movement.y,TERMINAL_GRAVITY_VELOCITY_Y,TERMINAL_JETPACK_VELOCITY_Y)
		up_down_movement = move_and_slide(up_down_movement,Vector3.UP)
		change_jetpack_charge(- JETPACK_DEPLETION_RATE * delta)
		

func apply_gravity(delta):
	$DebugLabel.text = str('is on floor: ', is_on_floor())
	if !is_on_floor():
		$DebugLabel.text += str(' u/d vel: ', up_down_movement.y)
		up_down_movement.y -= GRAVITY * delta
		up_down_movement.y = clamp(up_down_movement.y,TERMINAL_GRAVITY_VELOCITY_Y,TERMINAL_JETPACK_VELOCITY_Y)
		up_down_movement = move_and_slide(up_down_movement,Vector3.UP)
	else:
		up_down_movement.y = 0

func on_bounce(my_mesh):
	if is_on_floor() and my_mesh == mesh:
		if velocity.length() > BOUNCE_THRESHOLD:
			up_down_movement.y = BOUNCE_FORCE / velocity.length()
			move_and_slide(up_down_movement,Vector3.UP)
