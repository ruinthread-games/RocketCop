extends KinematicBody

onready var player = Globals.current_player

onready var mesh : Spatial = $Mesh
onready var drone_mesh_pivot : MeshInstance = $Mesh/MeshInstance
onready var instruction_graph : GraphEdit = $DroneUI/InstructionGraph

onready var velocity : Vector3 = Vector3.ZERO
onready var direction : Vector3 = Vector3.ZERO
onready var speed : float = 15.0
var last_velocity : Vector3
var acceleration : Vector3
var tilt : Vector3
var target_position : Vector3
var rotation_transform : Transform
var up_down_movement : Vector3 = Vector3.ZERO

const ACCELERATION_RATE : float = 3.0
const TURN_RATE : float = 3.0
const TILT_RATE : float = 3.0
const TILT_SCALE : float = 0.2
const GRAVITY : float = 70.0
const TERMINAL_GRAVITY_VELOCITY_Y : float = -50.0

enum { DRONE_IDLE, DRONE_MOVE, DRONE_ATTACK }

func _input(event):
	if event.is_action_pressed("toggle_drone_graph"):
		$DroneUI.visible = not $DroneUI.visible

func _ready():
	$DroneUI.visible = false
	global_transform.origin = player.global_transform.origin

func get_graph_input():
	return null

func process_graph_output():
	return

func _process(delta):
	var player_transform : Transform = player.global_transform
	var target = player_transform.origin + 5.0 * player_transform.basis.x
	direction = -(global_transform.origin - target).normalized()
	$DebugLabel.text = str('drone pos is: ', global_transform.origin)
	#var graph_output = instruction_graph.evaluate_graph(get_graph_input())
	#process_graph_output()
	
func _physics_process(delta):
	calculate_velocity(delta)
	find_velocity_facing_direction()
	find_acceleration()
	find_tilt_vector()
	find_last_velocity()
	move()
	apply_gravity(delta)
	#rotate_towards_acceleration(delta)
	rotate_towards_velocity(delta)

func move():
	velocity = move_and_slide(velocity,Vector3.UP)

func calculate_velocity(delta):
	if direction != Vector3.ZERO:
		velocity = velocity.linear_interpolate(direction*speed,ACCELERATION_RATE * delta)
	else:
		velocity = velocity.linear_interpolate(Vector3.ZERO,ACCELERATION_RATE * delta)

func find_velocity_facing_direction():
	if velocity != Vector3.ZERO and velocity.length() != 0.0:
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
		drone_mesh_pivot.rotation = lerp(drone_mesh_pivot.rotation, -tilt * TILT_SCALE, TILT_RATE * delta)

func apply_gravity(delta):
	if !is_on_floor():
		up_down_movement.y -= GRAVITY * delta
		up_down_movement.y = clamp(up_down_movement.y,TERMINAL_GRAVITY_VELOCITY_Y,0)
#		up_down_movement = move_and_slide(up_down_movement,Vector3.UP)
	else:
		up_down_movement.y = 0
