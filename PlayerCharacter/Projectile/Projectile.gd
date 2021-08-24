extends RigidBody


var barrel_transform : Transform

const MUZZLE_VELOCITY : float = 100.0

func _ready():
	pass # Replace with function body.

func set_barrel_transform(transform : Transform):
	barrel_transform = transform
	linear_velocity = MUZZLE_VELOCITY * -1 * barrel_transform.basis.y

func _physics_process(delta):
	pass
