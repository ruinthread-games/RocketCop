tool
extends KinematicBody

enum { STATE_IDLE, STATE_ATTACKING, STATE_RUNNING, STATE_DEAD }
var current_state = STATE_IDLE

var can_shoot : bool = true
var aim_down_sights_progress : float = 0.0
const MAX_SIGHT_RANGE : float = 200.0
var player_is_visible : bool = false
onready var mesh : Spatial = $MeshPivot/Armature
onready var enemy_mesh_pivot : Spatial = $MeshPivot
onready var animation_tree : AnimationTree = $MeshPivot/AnimationTree

onready var projectile_base = load("res://Enemies/Projectile/Projectile.tscn")
onready var gunshot_stream = load("res://Assets/Audio/Gunshot.ogg")

var player : KinematicBody

var aim_bias : Vector3

const AIM_BIAS_BASE_MAGNITUDE :float = 2.0

var distance_to_player : float

const TARGET_PLAYER_AIM_RATE :float = 0.5
const LOST_PLAYER_AIM_RATE :float = -1.0

const RUNNING_SPEED : float = 15.0

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
const DEATH_TWEEN_DURATION : float = 1.0

var threat_level : float = 0.0
const EXPLOSION_THREAT_INCREASE_RATE : float = 100.0
const SEES_PLAYER_THREAT_DECREASE_RATE : float = -0.01
const LOST_PLAYER_THREAT_DECREASE_RATE : float = -0.1
const THREAT_RETREAT_THRESHOLD : float = 0.7

var threat_location = null

const MOVEMENT_LENGTH = 10.0
const MAXIMUM_SAFE_DROP_HEIGHT = 25.0

const HITSCAN_MUZZLE_VELOCITY = 300.0

var thug_death_streams = []
var thug_fall_death_streams = []
var thug_target_spotted_streams = []
var thug_taunt_streams = []

var can_play_voiceline = true

func load_thug_voicelines():
	for i in range(11):
		thug_death_streams.append(load("res://Assets/Audio/npc_die_%02d.wav" % (i+1)))
	for i in range(5):
		thug_fall_death_streams.append(load("res://Assets/Audio/npc_die_falling_%02d.wav" % (i+1)))
	for i in range(14):
		thug_target_spotted_streams.append(load("res://Assets/Audio/npc_target_spotted_%02d.wav" % (i+1)))
	for i in range(7):
		thug_taunt_streams.append(load("res://Assets/Audio/npc_taunt_%02d.wav" % (i+1)))

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

func randomise_appearance():
	print('randomise thug appearance')
	randomize()
	var head_covering = ['Beret','Hoodie','Mohawk']
	var random_head_covering = head_covering[randi() % len(head_covering)]
	$MeshPivot/Armature/Skeleton/Beret.visible = false
	$MeshPivot/Armature/Skeleton/Hoodie.visible = false
	$MeshPivot/Armature/Skeleton/Mohawk.visible = false
	
	match random_head_covering:
		'Beret':
			$MeshPivot/Armature/Skeleton/Beret.visible = true
		'Hoodie':
			$MeshPivot/Armature/Skeleton/Hoodie.visible = true
		'Mohawk':
			$MeshPivot/Armature/Skeleton/Mohawk.visible = true
	$MeshPivot/Armature/Skeleton/Sunglasses.visible = rand_range(0,1) < 0.5
	$MeshPivot/Armature/Skeleton/Beard.visible = rand_range(0,1) < 0.5
	
	#pants / skin / jacket / trimming
	var colours = [Color(1,0,0),Color(0,1,0),Color(0,0,1),Color(1,1,0)]
	var pants_colours = [Color('#C5FFFD'),Color('#88D9E6'),Color('#8B8BAE'),Color('#526760'),Color('#374B4A')]
	var skin_colours = [Color('#8D5524'),Color('#C68642'),Color('#E0AC69'),Color('#F1C27D'),Color('#FFDBAC')]
	var jacket_colours = [Color('#121420'),Color('#1B2432'),Color('#403233'),Color('#272727'),Color('#520F00')]
	var shoe_sole_colours = [Color('17A398'),Color('#3F88C5'),Color('#E94F37')]
	
	for i in range($MeshPivot/Armature/Skeleton/Goon.mesh.get_surface_count()):
		var material : Material = $MeshPivot/Armature/Skeleton/Goon.mesh.surface_get_material(i).duplicate()
		if i == 0:
			material.albedo_color = pants_colours[randi() % len(pants_colours)]
		if i == 1:
			material.albedo_color = skin_colours[randi() % len(skin_colours)]
			var ear_material : Material = $MeshPivot/Armature/Skeleton/Ears.mesh.surface_get_material(0).duplicate()
			ear_material.albedo_color = material.albedo_color
			$MeshPivot/Armature/Skeleton/Ears.set_surface_material(0,ear_material)
		if i == 2:
			material.albedo_color = jacket_colours[randi() % len(jacket_colours)]
			if random_head_covering == 'Hoodie':
				var hoodie_material = $MeshPivot/Armature/Skeleton/Hoodie.mesh.surface_get_material(0).duplicate()
				hoodie_material.albedo_color = material.albedo_color
				$MeshPivot/Armature/Skeleton/Hoodie.set_surface_material(0,hoodie_material)
			if random_head_covering == 'Beret':
				var beret_material = $MeshPivot/Armature/Skeleton/Beret.mesh.surface_get_material(0).duplicate()
				beret_material.albedo_color = material.albedo_color
				$MeshPivot/Armature/Skeleton/Beret.set_surface_material(0,beret_material)
		if i == 3:
			material.albedo_color = shoe_sole_colours[randi() % len(shoe_sole_colours)]
		$MeshPivot/Armature/Skeleton/Goon.set_surface_material(i,material)
	

func _ready():
	create_master_animations()
	randomise_appearance()
	load_thug_voicelines()
	player = Globals.current_player
	change_aim_down_sights_progress(0)
	aim_bias = AIM_BIAS_BASE_MAGNITUDE * Vector3(rand_range(0,1),rand_range(0,1),rand_range(0,1)).normalized()
	add_to_group(Globals.DESTRUCTIBLE_GROUP)
	add_to_group(Globals.ENEMY_GROUP)
	$ShootingTimer.connect("timeout",self,"on_shooting_timer_timeout")
	$ProjectileTimeOfFlightTimer.connect("timeout",self,"on_projecitle_time_of_flight_timer_timeout")
	$DebugLabel.rect_position = Vector2(900, 100 + 20 * thug_index)
	toggle_xray(false)
	$RunningDirectionUpdateTimer.connect("timeout",self,"on_running_direction_update_timer_timeout")
	# desynchronise timers
	$RunningDirectionUpdateTimer.wait_time = (thug_index + 1) * 0.05
	$RunningDirectionUpdateTimer.start()
	
	$VoiceLineTimer.connect("timeout",self,"on_voiceline_timer_timeout")
	
	
func _process(delta):
	if is_dead:
		return
	
	if player_is_visible:
		change_threat_level(SEES_PLAYER_THREAT_DECREASE_RATE * delta)
	else:
		change_threat_level(LOST_PLAYER_THREAT_DECREASE_RATE)
		
	match current_state:
		STATE_IDLE:
			change_aim_down_sights_progress(LOST_PLAYER_AIM_RATE * delta)
		STATE_ATTACKING:
			change_aim_down_sights_progress(TARGET_PLAYER_AIM_RATE * delta)
			if can_shoot:
				fire_at_player()
		STATE_RUNNING:
			change_aim_down_sights_progress(LOST_PLAYER_AIM_RATE * delta)

func on_running_direction_update_timer_timeout():
	$RunningDirectionUpdateTimer.wait_time = 0.1
	if not update_running_direction():
		change_threat_level(-1)

func update_running_direction():
	direction = Vector3.ZERO
	var directions = []
	if threat_level > THREAT_RETREAT_THRESHOLD and threat_location:
		var to_threat = threat_location - global_transform.origin
		to_threat.y = 0
		to_threat = to_threat.normalized()
		# backwards
		directions.append(-to_threat)
		# flank left
		directions.append(to_threat.cross(Vector3.UP))
		# flank right
		directions.append(to_threat.cross(Vector3.DOWN))
	elif threat_level > THREAT_RETREAT_THRESHOLD:
		directions.append(global_transform.basis.z)
		directions.append(global_transform.basis.x)
		directions.append(-global_transform.basis.x)
		directions.append(-global_transform.basis.z)
		
	for direction_to_test in directions:
		var space_state = get_world().direct_space_state
		var target_point = global_transform.origin+ MOVEMENT_LENGTH*direction_to_test
		var horizontal_collision = space_state.intersect_ray(global_transform.origin+Vector3(0,0,0),target_point,[self])
		if not horizontal_collision:
			var vertical_collision = space_state.intersect_ray(target_point, target_point - Vector3(0,MAXIMUM_SAFE_DROP_HEIGHT,0))
			if vertical_collision:
				$RunningTarget.global_transform.origin = target_point
				direction = direction_to_test
				return true
	return false

func fire_at_player():
	if Globals.enemy_fire_mode == Globals.FIRE_MODE_PROJECTILES:
		var fired_projectile = projectile_base.instance()
		fired_projectile.global_transform = $MeshPivot/Armature/Skeleton/GunBarrelBoneAttachment/Spatial.global_transform
		fired_projectile.set_barrel_transform($MeshPivot/Armature/Skeleton/GunBarrelBoneAttachment/Spatial.global_transform)
		fired_projectile.set_marksman(self)
		get_parent().add_child(fired_projectile)
	else:
		$ProjectileTimeOfFlightTimer.wait_time = distance_to_player / HITSCAN_MUZZLE_VELOCITY
		$ProjectileTimeOfFlightTimer.start()
	can_shoot = false
	$GunshotPlayer.play()
	$ShootingTimer.start()
	
	
func on_projecitle_time_of_flight_timer_timeout():
	if player_is_visible:
		var hit_probability = rand_range(0,1)
		var range_check = exp(-0.1*distance_to_player)
		#print('check hit prob', hit_probability, ' against', range_check, ' for dist', distance_to_player)
		if hit_probability < range_check:
			Globals.current_player.register_hit()


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
	
	if check_for_impending_fall_death():
		play_fall_death_voiceline()
	
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
	
	var aim_position = to_global(Vector3(0,0,1))
	distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
	if distance_to_player < MAX_SIGHT_RANGE:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(global_transform.origin+Vector3(0,0,0),player.global_transform.origin+Vector3(0,-1,0),[self])
		$DebugLabel.text = ''
		if result:
			aim_position = result.position + (1-aim_down_sights_progress) * aim_bias
			$RayCastTarget.global_transform.origin = aim_position
			var previous_player_is_visible = player_is_visible
			player_is_visible = result.collider == player
			
			if player_is_visible and not previous_player_is_visible:
				play_target_spotted_voiceline()
			$DebugLabel.text = str(result.collider.get_name()) 
		else:
			$RayCastTarget.global_transform.origin = global_transform.origin
		
		var to_player = to_local(aim_position)
		var to_player_xz = to_player
		#$SpineIK.global_transform.origin = player.global_transform.origin + Vector3(0,7,0) # $SpineIK.transform.origin#looking_at(-to_player,Vector3.UP)
		to_player_xz.y = 0
		if current_state == STATE_ATTACKING:
			mesh.transform = mesh.transform.looking_at(-to_player_xz,Vector3.UP)
			$SpineIK.transform = $SpineIK.transform.looking_at(-to_player,Vector3.UP)
	else:
		player_is_visible = false
		
	$DebugLabel.text += str('aim: ', aim_down_sights_progress)
	$DebugLabel.text += str('threat: ', threat_level)
	$DebugLabel.text += str('state: ', get_state_label())
	
	
		

func toggle_xray(new_xray):
	if new_xray:
		$MeshPivot/Armature/Skeleton/Goon.visible = false
		$MeshPivot/Armature/Skeleton/XrayGoon.visible = true
	else:
		$MeshPivot/Armature/Skeleton/Goon.visible = true
		$MeshPivot/Armature/Skeleton/XrayGoon.visible = false

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
	if is_dead:
		return
	is_dead = true
	death_tween = Tween.new()
	add_child(death_tween)
	death_tween.connect("tween_all_completed",self,"on_death_tween_complete")
	death_tween.interpolate_property($MeshPivot/AnimationTree,"parameters/DeathBlend/blend_amount",0,1,DEATH_TWEEN_DURATION,Tween.TRANS_LINEAR,Tween.EASE_IN,0)
	death_tween.start()
	$RunningDirectionUpdateTimer.stop()
	Globals.register_thug_death()
	play_death_voiceline()

func on_death_tween_complete():
	pass

func change_threat_level(delta_threat):
	var previous_threat_level =threat_level
	
	threat_level = clamp(threat_level + delta_threat, 0, 1.0)
	
	if previous_threat_level > THREAT_RETREAT_THRESHOLD and threat_level < THREAT_RETREAT_THRESHOLD:
		play_taunt_voiceline()
	
	if player_is_visible and threat_level < THREAT_RETREAT_THRESHOLD:
		change_state(STATE_ATTACKING)
	elif threat_level < THREAT_RETREAT_THRESHOLD:
		change_state(STATE_IDLE)
	elif threat_level >= THREAT_RETREAT_THRESHOLD:
		change_state(STATE_RUNNING)

func change_state(new_state):
	current_state = new_state

func get_state_label():
	match current_state:
		STATE_ATTACKING:
			return 'attacking'
		STATE_IDLE:
			return 'idle'
		STATE_RUNNING:
			return 'running'
		STATE_DEAD:
			return 'dead'
	return 'invalid'

func alert_to_explosion(explosion_location):
	var explosion_distance = global_transform.origin.distance_to(explosion_location)
	var threat_from_explosion = EXPLOSION_THREAT_INCREASE_RATE / pow(explosion_distance,2.0)
	change_threat_level(threat_from_explosion)
	if threat_location:
		if threat_location.distance_to(global_transform.origin) > explosion_distance:
			threat_location = explosion_location
	else:
		threat_location = explosion_location
	$ThreatLocationIndicator.global_transform.origin = threat_location

func check_for_impending_fall_death() -> bool:
	var space_state = get_world().direct_space_state
	var target_point = global_transform.origin - Vector3(0,100,0)
	var result = space_state.intersect_ray(global_transform.origin+Vector3(0,0,0),target_point,[self])
	if result:
		return false
	else:
		return true

func play_death_voiceline():
	$VoiceLinePlayer.stream = thug_death_streams[randi() % len(thug_death_streams)]
	$VoiceLinePlayer.play()

func play_taunt_voiceline():
	if Globals.play_cut_voicelines:
		$VoiceLinePlayer.stream = thug_taunt_streams[randi() % len(thug_taunt_streams)]
		$VoiceLinePlayer.play()
	
func play_fall_death_voiceline():
	if Globals.play_cut_voicelines:
		$VoiceLinePlayer.stream = thug_fall_death_streams[randi() % len(thug_fall_death_streams)]
		$VoiceLinePlayer.play()
	
func play_target_spotted_voiceline():
	if not Globals.play_cut_voicelines:
		return
	if distance_to_player < 30 and rand_range(0,1) < 0.4:
		$VoiceLinePlayer.stream = thug_target_spotted_streams[randi() % len(thug_target_spotted_streams)]
		$VoiceLinePlayer.play()
	can_play_voiceline = false
	$VoiceLineTimer.start()

func on_voiceline_timer_timeout():
	can_play_voiceline = true
