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
		var rigid_body = child
		if body == rigid_body:
			child.visible = false
			rigid_body.get_child(1).disabled = true
			Globals.collateral_damage_caused += 1
	if check_if_fully_destroyed():
		Globals.current_level_instance.trigger_collapse(row,col,layer)
		queue_free()

func activate_rigid():
	print('\tactivating rigid', row, '-', col, '-', layer, '(', cell_type, ')')
	for child in get_children():
		if child is RigidBody:
			child.mode = RigidBody.MODE_RIGID
