extends Spatial

const CELL_WIDTH = 10

onready var wall_segment_base = load("res://Levels/Modules/BrickWall/BrickWall.tscn")
onready var floor_base = load("res://Levels/Modules/ConcreteFloor/ConcreteFloor.tscn")

onready var cell_parent = $Navigation/NavigationMeshInstance/GeneratedCells

var cell_index_dict = {}
var cell_list = []

var needs_generate_level = true

func _ready():
	generate_level()
	if Engine.editor_hint:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func spatial_index_to_coord(row,col,layer):
	return Vector3(CELL_WIDTH*row,CELL_WIDTH*layer,CELL_WIDTH*col)

func to_key(row,col,layer):
	return Vector3(int(floor(row)),int(floor(col)),int(floor(layer)))

func register_new_cell(new_cell):
	cell_index_dict[to_key(new_cell.row,new_cell.col,new_cell.layer)] = len(cell_list)
	cell_list.push_back(new_cell)

func get_cardinal_neighbours(cell):
	var neighbours = [null, null, null, null]
	if cell == null:
		return neighbours
	else:
		var key = to_key(cell.row+1,cell.col,cell.layer)
		if key in cell_index_dict:
			neighbours[1] = cell_list[cell_index_dict[key]]
			
		key = to_key(cell.row-1,cell.col,cell.layer)
		if key in cell_index_dict:
			neighbours[3] = cell_list[cell_index_dict[key]]
			
		key = to_key(cell.row,cell.col+1,cell.layer)
		if key in cell_index_dict:
			neighbours[0] = cell_list[cell_index_dict[key]]
			
		key = to_key(cell.row,cell.col-1,cell.layer)
		if key in cell_index_dict:
			neighbours[2] = cell_list[cell_index_dict[key]]
	return neighbours

func cell_below_is_occupied(row,col,layer):
	return to_key(row,col,layer-1) in cell_index_dict

func generate_level():
	print('generating level')
	cell_list = []
	cell_index_dict = {}
	for child in cell_parent.get_children():
		child.queue_free()
	
	for ind_layer in range(4):
		for ind_row in range(4):
			for ind_col in range(4):
				var floor_instance = floor_base.instance()
				cell_parent.add_child(floor_instance)
				floor_instance.set_owner(get_tree().edited_scene_root)
				floor_instance.row = ind_row
				floor_instance.col = ind_col
				floor_instance.layer = ind_layer
				floor_instance.global_transform.origin = spatial_index_to_coord(ind_row,ind_col,ind_layer)
				
				if (ind_row == 1 or ind_row == 2) and (ind_col == 1 or ind_col == 2):
					if rand_range(0,1) < 0.2 or (ind_layer > 0 and not cell_below_is_occupied(ind_row,ind_col,ind_layer)):
						continue
				var wall_instance = wall_segment_base.instance()
				cell_parent.add_child(wall_instance)
				wall_instance.set_owner(get_tree().edited_scene_root)
				print(wall_instance.my_awesome_variable)
				wall_instance.row = ind_row
				wall_instance.col = ind_col
				wall_instance.layer = ind_layer
				wall_instance.global_transform.origin = spatial_index_to_coord(ind_row,ind_col,ind_layer)
				register_new_cell(wall_instance)
				
	for cell in cell_list:
		var cardinal_neighbours = get_cardinal_neighbours(cell)
		var needs_wall_segment  = [false,false,false,false]
		for i in range(4):
			needs_wall_segment[i] = true if cardinal_neighbours[i] != null else false
		cell.update(needs_wall_segment)

func _process(delta):
	pass
#	if Engine.editor_hint:
#		if needs_generate_level:
#			generate_level()
#			needs_generate_level = false
