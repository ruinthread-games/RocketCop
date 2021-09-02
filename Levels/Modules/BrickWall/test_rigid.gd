#tool
extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh_instance = $MeshInstance2
	
	if mesh_instance.get_child(0) is StaticBody:
		var mesh_transform = mesh_instance.global_transform
		
		# create a rigid body to replace the static body
		var rigid_body_proxy : RigidBody = RigidBody.new()
		rigid_body_proxy.set_collision_mask_bit(0,true)
		rigid_body_proxy.set_collision_layer_bit(0,true)
		rigid_body_proxy.global_transform = mesh_transform
		
		mesh_instance.transform.rotate
		var static_body : StaticBody = mesh_instance.get_child(0)
		var collision_shape : CollisionShape = static_body.get_child(0)
		
		add_child(rigid_body_proxy)
		rigid_body_proxy.set_owner(get_tree().edited_scene_root)
		remove_child(mesh_instance)
		rigid_body_proxy.add_child(mesh_instance)
		mesh_instance.set_owner(self)
		
		static_body.remove_child(collision_shape)
		rigid_body_proxy.add_child(collision_shape)
		collision_shape.set_owner(self)
		static_body.queue_free()

func _physics_process(delta):
	pass
