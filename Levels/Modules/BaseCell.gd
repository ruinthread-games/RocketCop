extends Spatial

var row
var col
var layer

var occupied

var cell_type

func _ready():
	add_to_group(Globals.DESTRUCTIBLE_GROUP)

func check_if_fully_destroyed():
	var all_hidden = true
	for child in get_children():
		if child.visible:
			all_hidden = false
			break
	return all_hidden

func destroy(body, blast_origin):
	for child in get_children():
		var static_body = child.get_child(0)
		if body == static_body:
			child.visible = false
			static_body.get_child(0).disabled = true
			Globals.collateral_damage_caused += 1
	if check_if_fully_destroyed():
		Globals.current_level_instance.trigger_collapse(row,col,layer)
		queue_free()

func activate_rigid():
	pass

func replace_static_with_rigid():
	# loop over mesh instances
	for mesh_instance in get_children():
		if not mesh_instance is MeshInstance:
			continue
		# create a rigid body to replace the static body
		var rigid_body_proxy : RigidBody = RigidBody.new()
		if mesh_instance.get_child(0) is StaticBody:
			var static_body : StaticBody = mesh_instance.get_child(0)
			var collision_shape : CollisionShape = static_body.get_child(0)
			
			add_child(rigid_body_proxy)
			remove_child(mesh_instance)
			rigid_body_proxy.add_child(mesh_instance)
			mesh_instance.set_owner(rigid_body_proxy)
			
			static_body.remove_child(collision_shape)
			rigid_body_proxy.add_child(collision_shape)
			collision_shape.set_owner(rigid_body_proxy)
			static_body.queue_free()
