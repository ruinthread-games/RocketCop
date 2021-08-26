extends RigidBody

var is_exploded : bool = false
var barrel_transform : Transform

const MUZZLE_VELOCITY : float = 100.0

func _ready():
	$AudioStreamPlayer3D.stream = load("res://Assets/Audio/extremely_carefully_crafted_grenade_explosion_sound.ogg")
	$AudioStreamPlayer3D.connect("finished", self, "on_explosion_SFX_finished")
	$ExplosionTimer.connect("timeout",self,"on_explosion_timer_timeout")

func set_barrel_transform(transform : Transform):
	barrel_transform = transform
	linear_velocity = MUZZLE_VELOCITY * -1 * barrel_transform.basis.y

func _physics_process(delta):
	pass

func on_explosion_SFX_finished():
	$AudioStreamPlayer3D.stop()
	queue_free()

func _on_Projectile_body_entered(body):
	if not is_exploded:
		#print('projectile hit', body)
		$ExplosionTimer.start()
		is_exploded = true

func on_explosion_timer_timeout():
	$AudioStreamPlayer3D.play()
	$GrenadeMesh.visible = false
	
	for body in $BlastRadius.get_overlapping_bodies():
		print('explosion: ', body.get_name(), body.get_parent().get_name())
		
		if body.is_in_group(Globals.DESTRUCTIBLE_GROUP):
			body.destroy(body,global_transform.origin)
		
		var destructible_root = body.get_parent()
		if destructible_root.is_in_group(Globals.DESTRUCTIBLE_GROUP):
			destructible_root.destroy(body,global_transform.origin)
			
		destructible_root = body.get_parent().get_parent()
		if destructible_root.is_in_group(Globals.DESTRUCTIBLE_GROUP):
			destructible_root.destroy(body,global_transform.origin)
