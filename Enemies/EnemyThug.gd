tool
extends KinematicBody

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
	pass

func _process(delta):
#	print('abc')
#	create_master_animations()
	pass
