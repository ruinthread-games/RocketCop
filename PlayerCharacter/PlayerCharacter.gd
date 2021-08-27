extends KinematicBody

var capture_mouse : bool = false

onready var player_mesh_pivot : Spatial = $MeshPivot
onready var mesh : Spatial = $MeshPivot/Armature
onready var animation_tree : AnimationTree = $MeshPivot/AnimationTree
onready var camera_pivot : Spatial = $CameraPivot

var camera_offset : Vector3 = Vector3(0,0,0)
var camera_transform : Transform

const SPRINTING_SPEED = 35.0
const RUNNING_SPEED = 25.0
const AIMING_RUN_SPEED = 5.0

var is_sprinting : bool = false

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
const JETPACK_ACCELERATION : float = 130.0
const BOUNCE_FORCE : float = 20.0

var jetpack_charge : float = 1.0
var JETPACK_DEPLETION_RATE : float = 0.5
var JETPACK_RECHARGE_RATE : float = 0.45

onready var jetpack_charge_bar = $PlayerUI/StatusBarContainer/JetpackCharge
onready var health_bar = $PlayerUI/StatusBarContainer/HealthBar

var aim_down_sights_progress : float = 0.0
var AIM_DOWN_SIGHTS_SPEED : float = 2.0
var UNAIM_DOWN_SIGHTS_SPEED : float = 4.0
var AIM_DOWN_SIGHTS_LOST_ON_HIT : float = 0.1

var GRENADES_PER_CLIP = 6
var ammo_in_clip = GRENADES_PER_CLIP
onready var projectile_base = load("res://PlayerCharacter/Projectile/Projectile.tscn")

var is_dead : bool = false
const MAX_HEALTH : float = 1.0
var current_health : float = MAX_HEALTH
var is_regenerating_health : bool = true
const HEALTH_LOST_ON_HIT : float = -0.1
const HEALTH_REGENERATION_RATE : float = 0.25

func create_master_animations():
	var delete_extra_keyframes_anims = ["Run1","Run2","Run3","Run4","Idle1","Idle2","Aiming"]
	
	for anim_label in delete_extra_keyframes_anims:
		var anim = $MeshPivot/AnimationPlayer.get_animation(anim_label)
		for track_index in range(anim.get_track_count()):
#			print('track', track_index, anim.track_get_path(track_index))
			for key_index in range(anim.track_get_key_count(track_index)):
				var time = anim.track_get_key_time(track_index,key_index)
				if time != 0:
#					print('track ind', track_index, 'key ind', key_index, 'time: ', time)
					anim.track_remove_key(track_index,key_index)
#			anim.track_remove_key_at_position(track_index,0.04)
#		var track_index = anim.find_track("Armature/Skeleton")
#		print('del keyframes track index', track_index)
	
	if Engine.editor_hint:
		if $MeshPivot/AnimationPlayer.has_animation("IdleMaster"):
			print('idle animation already exists!')
		else:
			var idle_master_animation = Animation.new()
			var idle_master_track_index = idle_master_animation.add_track(Animation.TYPE_VALUE)
			idle_master_animation.track_set_path(idle_master_track_index, "AnimationTree:parameters/Idle/BlendSpace1D/blend_position")
			idle_master_animation.track_insert_key(idle_master_track_index, 0, -1)
			idle_master_animation.track_insert_key(idle_master_track_index, 0.5, 1)
			idle_master_animation.loop = true
			$MeshPivot/AnimationPlayer.add_animation("IdleMaster",idle_master_animation)
			
		if $MeshPivot/AnimationPlayer.has_animation("RunningMaster"):
			print('running anim already exists!')
		else:
			var running_master_animation = Animation.new()
			var running_master_track_index = running_master_animation.add_track(Animation.TYPE_VALUE)
			running_master_animation.track_set_path(running_master_track_index, "AnimationTree:parameters/Running/BlendSpace2D/blend_position")
			running_master_animation.track_insert_key(running_master_track_index, 0, Vector2(-1,0),2.0)
			running_master_animation.track_insert_key(running_master_track_index, 0.2, Vector2(0,1),0.5)
			running_master_animation.track_insert_key(running_master_track_index, 0.4, Vector2(1,0),2.0)
			running_master_animation.track_insert_key(running_master_track_index, 0.6, Vector2(0,-1),0.5)
			var running_bounce_track_index = running_master_animation.add_track(Animation.TYPE_METHOD)
			running_master_animation.track_set_path(running_bounce_track_index, ".")
			running_master_animation.track_insert_key(running_bounce_track_index,0.2,{"method":"bounce","args":[]})
			running_master_animation.track_insert_key(running_bounce_track_index,0.6,{"method":"bounce","args":[]})
			running_master_animation.loop = true
			running_master_animation.set_length(0.8)
			$MeshPivot/AnimationPlayer.add_animation("RunningMaster",running_master_animation)

func _init():
	Globals.current_player = self

func _ready():
	camera_pivot.set_as_toplevel(true)
	mesh.connect("bounce",self,"on_bounce")
	$HealthRegenerationTimer.connect("timeout",self,"on_health_regeneration_timer_timeout")
	$ReloadTimer.connect("timeout",self,"on_reload_timer_timeout")
	
func _process(delta):
#	create_master_animations()
	if is_dead:
		return
	if Engine.editor_hint:
		return
		
	if is_regenerating_health:
		change_health(HEALTH_REGENERATION_RATE * delta)
		
	set_camera_follow()
	get_camera_transform()
	update_run_speed()
	get_input(delta)
	recharge_jetpack(delta)
#	$DebugLabel.text = str('u/d vel: ',up_down_movement.y)
	
func _physics_process(delta):
	if is_dead:
		return
	if Engine.editor_hint:
		return
	$DebugLabel2.text = str('u/d movment: ', up_down_movement)
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
	up_down_movement.x = 0
	up_down_movement.z = 0
	
func recharge_jetpack(delta):
	if not Input.is_action_pressed("engage_jetpack"):
		change_jetpack_charge(JETPACK_RECHARGE_RATE * delta)
	
func change_jetpack_charge(delta_charge):
	jetpack_charge = clamp(jetpack_charge + delta_charge, -1.0, 1.0)
	jetpack_charge_bar.value = jetpack_charge
	
func change_health(delta_health):
	current_health = clamp(current_health + delta_health, 0, MAX_HEALTH)
	if current_health == 0:
		die()
	health_bar.value = current_health
	health_bar.max_value = MAX_HEALTH
	
func die():
	is_dead = true
	
func set_camera_follow():
	camera_pivot.follow_me(translation + camera_offset)
	
func get_camera_transform():
	camera_transform = camera_pivot.give_direction()

func get_input(delta):
	direction_forward_axis = (-Input.get_action_strength("move_forward") + Input.get_action_strength("move_backwards")) * camera_transform.basis.z
	direction_side_axis = (-Input.get_action_strength("move_left") + Input.get_action_strength("move_right")) * camera_transform.basis.x
	direction = (direction_forward_axis + direction_side_axis).normalized()
	
	is_sprinting = Input.is_action_pressed("sprint")
	
	if not is_sprinting and Input.is_action_pressed("aim_down_sights"):
		change_aim_down_sights_progress(AIM_DOWN_SIGHTS_SPEED * delta)
	else:
		change_aim_down_sights_progress(-UNAIM_DOWN_SIGHTS_SPEED * delta)
		
	if Input.is_action_just_pressed("fire_grenade"):
		fire_grenade()
		
	if Input.is_action_just_pressed("reload"):
		reload()
		
func _input(event):
	if event is InputEventMouseButton:
		if not capture_mouse:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			capture_mouse = true
	
	

func change_ammo_in_clip(delta_ammo):
	ammo_in_clip = clamp(ammo_in_clip+delta_ammo,0,GRENADES_PER_CLIP)
	$PlayerUI/Crosshair/AmmoLabel.text = str(ammo_in_clip)
	
func reload():
	$ReloadTimer.start()

func fire_grenade():
	if aim_down_sights_progress == 1:
		if ammo_in_clip > 0:
			change_ammo_in_clip(-1)
			var fired_projectile = projectile_base.instance()
			fired_projectile.global_transform.origin = $MeshPivot/Armature/Skeleton/GrenadeLauncherBarrelBoneAttachment/Spatial.global_transform.origin
			fired_projectile.set_barrel_transform($MeshPivot/Armature/Skeleton/GrenadeLauncherBarrelBoneAttachment/Spatial.global_transform)
			get_parent().add_child(fired_projectile)

func change_aim_down_sights_progress(delta_ads):
	aim_down_sights_progress = clamp(aim_down_sights_progress + delta_ads, 0.0, 1.0)
	var crosshair_alpha = aim_down_sights_progress
	if aim_down_sights_progress == 1.0:
		$PlayerUI/Crosshair.modulate = Color(1,0,0,crosshair_alpha)
		$MeshPivot/Armature/Skeleton/SkeletonIK.start()
	else:
		$PlayerUI/Crosshair.modulate = Color(1,1,1,crosshair_alpha)
		$MeshPivot/Armature/Skeleton/SkeletonIK.stop()
	$CameraPivot/CameraPivot/SpringArm.spring_length = lerp(5.0,2.5,aim_down_sights_progress)
	camera_offset = lerp(Vector3.ZERO,Vector3(0,1,0)+camera_pivot.global_transform.basis.x,aim_down_sights_progress)
	
	$MeshPivot/AnimationTree.set("parameters/ADSBlend/blend_amount",aim_down_sights_progress)

func update_run_speed():
	speed = lerp(SPRINTING_SPEED if is_sprinting and is_on_floor() else RUNNING_SPEED,AIMING_RUN_SPEED,aim_down_sights_progress)
	$DebugLabel.text = str('max speed: ', speed)

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
		
	if aim_down_sights_progress == 1:
		mesh.transform = mesh.transform.looking_at(camera_transform.basis.z,Vector3.UP)

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
	if Input.is_action_pressed("engage_jetpack"):
		if jetpack_charge > 0:
			up_down_movement.y += JETPACK_ACCELERATION * delta
		elif jetpack_charge > -0.25:
			up_down_movement.y += (1-abs(jetpack_charge))*GRAVITY * delta #limited overcharge jetpack for 'hang time'
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

func register_hit():
	change_aim_down_sights_progress(AIM_DOWN_SIGHTS_LOST_ON_HIT)
	change_health(HEALTH_LOST_ON_HIT)
	print('register hit on player, cur health ', current_health)
	$HealthRegenerationTimer.start()
	is_regenerating_health = false

func on_health_regeneration_timer_timeout():
	is_regenerating_health = true
	
func on_reload_timer_timeout():
	change_ammo_in_clip(GRENADES_PER_CLIP)
