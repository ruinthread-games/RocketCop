extends "res://Levels/Modules/BaseCell.gd"

var my_awesome_variable = 5

func _ready():
	occupied = true
	cell_type = 'brick_wall'
	print('brick wall ready!', row, col, layer)

func update(cardinal_neighbours):
	print('upd cell w', cardinal_neighbours)
	set_visibility(cardinal_neighbours[0],cardinal_neighbours[1],cardinal_neighbours[2],cardinal_neighbours[3])

func set_visibility(north,east,south,west):
	$West.visible = west
	$East.visible = east
	$North.visible = north
	$South.visible = south
	
	$West/StaticBody/CollisionShape.disabled = not west
	$East/StaticBody/CollisionShape.disabled = not east
	$North/StaticBody/CollisionShape.disabled = not north
	$South/StaticBody/CollisionShape.disabled = not south
