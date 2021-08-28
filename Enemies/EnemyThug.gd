tool
extends KinematicBody

enum { STATE_IDLE, STATE_ATTACKING, STATE_RUNNING }
var current_state = STATE_IDLE

var can_shoot : bool = true
var aim_down_sights_progress : float = 0.0
var player_is_visible : bool = false
onready var mesh : Spatial = $MeshPivot/Armature
onready var enemy_mesh_pivot : Spatial = $MeshPivot
onready var animation_tree : AnimationTree = $MeshPivot/AnimationTree

onready var projectile_base = load("res://Enemies/Projectile/Projectile.tscn")
onready var gunshot_stream = load("res://Assets/Audio/Gunshot.ogg")

var player : KinematicBody

var aim_bias : Vector3

const AIM_BIAS_BASE_MAGNITUDE :float = 4.0

const TARGET_PLAYER_AIM_RATE :float = 0.5
const LOST_PLAYER_AIM_RATE :float = -1.0

const RUNNING_SPEED : float = 25.0

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
const BOUNCE_FORCE : float = 20.0

var is_dead = false

var thug_index : int

var death_tween : Tween = null

func create_master_animations():
	var delete_extra_keyframes_anims = ["Run1","Run2","Run3","Run4","Idle1","Idle2","Aiming","TPose","GrenadeBlast","Dead"]
	
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
			
		if $MeshPivot/AnimationPlayer.has_animation("GrenadeBlastMaster"):
			print('grenade blast already exists')
		else:
			var grenade_blast_animation = Animation.new()
			var grenade_blast_track_index = grenade_blast_animation.add_track(Animation.TYPE_VALUE)
			grenade_blast_animation.track_set_path(grenade_blast_track_index, "AnimationTree:parameters/GrenadeBlast/BlendSpace1D/blend_position")
			grenade_blast_animation.track_insert_key(grenade_blast_track_index, 0, -1)
			grenade_blast_animation.track_insert_key(grenade_blast_track_index, 2, 1)
			grenade_blast_animation.loop = false
			$MeshPivot/AnimationPlayer.add_animation("GrenadeBlastMaster",grenade_blast_animation)

func _ready():
	create_master_animations()
	player = Globals.current_player
	change_aim_down_sights_progress(0)
	aim_bias = AIM_BIAS_BASE_MAGNITUDE * Vector3(rand_range(0,1),rand_range(0,1),rand_range(0,1)).normalized()
	add_to_group(Globals.DESTRUCTIBLE_GROUP)
	$ShootingTimer.connect("timeout",self,"on_shooting_timer_timeout")
	

func _process(delta):
	if is_dead:
		return
	
	if player_is_visible:
		if can_shoot:
			fire_at_player()

func fire_at_player():
	var fired_projectile = projectile_base.instance()
	fired_projectile.global_transform = $MeshPivot/Armature/Skeleton/GunBarrelBoneAttachment/Spatial.global_transform
	fired_projectile.set_barrel_transform($MeshPivot/Armature/Skeleton/GunBarrelBoneAttachment/Spatial.global_transform)
	fired_projectile.set_marksman(self)
	get_parent().add_child(fired_projectile)
	can_shoot = false
	$ShootingTimer.start()
	$GunshotPlayer.play()
	

func on_shooting_timer_timeout():
	can_shoot = true
#	print('thug, index ', thug_index, ' can shoot!')

func _physics_process(delta):
	if Engine.editor_hint:
		return
	
	if is_dead:
		calculate_velocity(delta)
		move()
		apply_gravity(delta)
		return
	
	calculate_velocity(delta)
	find_velocity_facing_direction()
	find_acceleration()
	find_tilt_vector()
	find_last_velocity()
	move()
	apply_gravity(delta)
	#rotate_towards_acceleration(delta)
	rotate_towards_velocity(delta)
	blend_idle_run()
	up_down_movement.x = 0
	up_down_movement.z = 0
	
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(global_transform.origin+Vector3(0,0,0),player.global_transform.origin+Vector3(0,-1,0),[self])
	$DebugLabel.text = ''
	var aim_position = Vector3.ZERO
	if result:
		aim_position = result.position + (1-aim_down_sights_progress) * aim_bias
		$RayCastTarget.global_transform.origin = aim_position#result.position
		player_is_visible = result.collider == player
		$DebugLabel.text = str(result.collider.get_name()) 
	else:
		$RayCastTarget.global_transform.origin = global_transform.origin
		
	change_aim_down_sights_progress(TARGET_PLAYER_AIM_RATE * delta if player_is_visible else LOST_PLAYER_AIM_RATE * delta)
	$DebugLabel.text += str('aim: ', aim_down_sights_progress)
	var to_player = to_local(aim_position)
	var to_player_xz = to_player
	#$SpineIK.global_transform.origin = player.global_transform.origin + Vector3(0,7,0) # $SpineIK.transform.origin#looking_at(-to_player,Vector3.UP)
	to_player_xz.y = 0
	mesh.transform = mesh.transform.looking_at(-to_player_xz,Vector3.UP)
	$SpineIK.transform = $SpineIK.transform.looking_at(-to_player,Vector3.UP)

func change_aim_down_sights_progress(delta_ads):
	aim_down_sights_progress = clamp(aim_down_sights_progress + delta_ads, 0.0, 1.0)
	$MeshPivot/AnimationTree.set("parameters/ADSBlend/blend_amount",aim_down_sights_progress)
	
	if aim_down_sights_progress == 1:
		$MeshPivot/Armature/Skeleton/SkeletonIK.start()
	else:
		$MeshPivot/Armature/Skeleton/SkeletonIK.stop()

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
		enemy_mesh_pivot.rotation = lerp(enemy_mesh_pivot.rotation, -tilt * TILT_SCALE, TILT_RATE * delta)

func blend_idle_run():
	if is_on_floor():
		animation_tree.set("parameters/IdleRunBlend/blend_amount",clamp(velocity.length()/RUNNING_SPEED,0,1))
	else:
		animation_tree.set("parameters/IdleRunBlend/blend_amount",0)

func apply_gravity(delta):
	$DebugLabel.text = str('is on floor: ', is_on_floor())
	if !is_on_floor():
		$DebugLabel.text += str(' u/d vel: ', up_down_movement.y)
		up_down_movement.y -= GRAVITY * delta
		up_down_movement.y = clamp(up_down_movement.y,TERMINAL_GRAVITY_VELOCITY_Y,0)
		up_down_movement = move_and_slide(up_down_movement,Vector3.UP)
	else:
		up_down_movement.y = 0

func on_bounce(my_mesh):
	if is_on_floor() and my_mesh == mesh:
		if velocity.length() > BOUNCE_THRESHOLD:
			up_down_movement.y = BOUNCE_FORCE / velocity.length()
			move_and_slide(up_down_movement,Vector3.UP)


func destroy(body,blast_origin):
	if is_dead:
		return
	var to_blast_origin_xz = global_transform.origin - blast_origin
	to_blast_origin_xz.y = 0
	velocity = to_blast_origin_xz.normalized() * 20.0 + Vector3(0,20.0,0)
	print('thug destroy!')
	die()

func die():
	is_dead = true
	death_tween = Tween.new()
	add_child(death_tween)
	death_tween.connect("tween_all_completed",self,"on_death_tween_complete")
	death_tween.interpolate_property($MeshPivot/AnimationTree,"parameters/DeathBlend/blend_amount",0,1,2,Tween.TRANS_LINEAR,Tween.EASE_IN,0)
	death_tween.start()

func on_death_tween_complete():
	print('finish death tween, yo!')
