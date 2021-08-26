tool
extends KinematicBody

enum { STATE_IDLE, STATE_ATTACKING, STATE_RUNNING }
var current_state = STATE_IDLE

var aim_down_sights_progress : float = 0.0
var player_is_visible : bool = false
onready var mesh : Spatial = $MeshPivot/Armature

var player : KinematicBody

var aim_bias : Vector3

const AIM_BIAS_BASE_MAGNITUDE :float = 4.0

const TARGET_PLAYER_AIM_RATE :float = 0.5
const LOST_PLAYER_AIM_RATE :float = -1.0

var is_dead = false

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

func _ready():
	player = Globals.current_player
	change_aim_down_sights_progress(0)
	aim_bias = AIM_BIAS_BASE_MAGNITUDE * Vector3(rand_range(0,1),rand_range(0,1),rand_range(0,1)).normalized()
	add_to_group(Globals.DESTRUCTIBLE_GROUP)

func _process(delta):
	if is_dead:
		return
	
func _physics_process(delta):
	if is_dead:
		return
	
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

func destroy(body,blast_origin):
	print('thug destroy!')
	die()
	

func die():
	is_dead = true
