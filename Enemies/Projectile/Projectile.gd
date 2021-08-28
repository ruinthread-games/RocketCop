extends RigidBody

var barrel_transform : Transform
var marksman : KinematicBody

const MUZZLE_VELOCITY : float = 100.0
const DESPAWN_DISTANCE_THRESHOLD : float = 200.0

func set_barrel_transform(transform : Transform):
	barrel_transform = transform
	linear_velocity = MUZZLE_VELOCITY * -1 * barrel_transform.basis.y
	#$CollisionShape.transform = $CollisionShape.transform.looking_at(barrel_transform.basis.y,Vector3.UP)
	#MeshInstance.transform = $MeshInstance.transform.looking_at()

func set_marksman(marksman_in):
	marksman = marksman_in
	
func _ready():
	$ExpirationTimer.connect("timeout",self,"on_expiration_timer_timeout")
	$ExpirationTimer.start()

func on_expiration_timer_timeout():
	queue_free()

func _process(delta):
	if barrel_transform.origin.distance_squared_to(global_transform.origin) > DESPAWN_DISTANCE_THRESHOLD * DESPAWN_DISTANCE_THRESHOLD:
		queue_free()


func _on_RigidBody_body_entered(body):
	if body != marksman:
		queue_free()
	if body == Globals.current_player:
		marksman.play_taunt_voiceline()
		body.register_hit()
