extends "res://Levels/Modules/BaseCellRigid.gd"

func _ready():
	occupied = true
	cell_type = 'brick_wall'

func update(cardinal_neighbours):
#	print('upd cell w', cardinal_neighbours)
	set_visibility(cardinal_neighbours[0],cardinal_neighbours[1],cardinal_neighbours[2],cardinal_neighbours[3])

func set_visibility(north,east,south,west):
	$West.visible = west
	$East.visible = east
	$North.visible = north
	$South.visible = south
	
	$West/CollisionShape.disabled = not west
	$East/CollisionShape.disabled = not east
	$North/CollisionShape.disabled = not north
	$South/CollisionShape.disabled = not south
