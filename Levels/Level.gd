extends Spatial

const CELL_WIDTH = 10
const GRID_WIDTH = 8

onready var wall_segment_base = load("res://Levels/Modules/BrickWall/BrickWall.tscn")
onready var floor_base = load("res://Levels/Modules/ConcreteFloor/ConcreteFloor.tscn")
onready var foundation = load("res://Levels/Modules/Foundation/Foundation.tscn")
onready var rooftop = load("res://Levels/Modules/Rooftop/Rooftop.tscn")

onready var enemy_thug_base = load("res://Enemies/EnemyThug.tscn")

onready var cell_parent = $GeneratedCells
onready var enemy_parent = $SpawnedEnemies

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

func generate_structure(offset_indices : Vector3):
	var rooftop_indices : Array = []
	
	var num_layers = int(rand_range(3,6))
	var num_rows = int(rand_range(3,7))
	var num_cols = int(rand_range(3,7))
	print('gen structure of dims: ', num_rows, '-',num_cols,'-', num_layers)
	for ind_row in range(offset_indices.x-1, offset_indices.x + num_rows+1):
		for ind_col in range(offset_indices.z-1, offset_indices.z + num_cols +1):
			var ind_layer = offset_indices.y - 1
			var foundation_instance = foundation.instance()
			cell_parent.add_child(foundation_instance)
			foundation_instance.set_owner(get_tree().edited_scene_root)
#			foundation_instance.row = offset_indices.x + ind_row
#			foundation_instance.col = offset_indices.z + ind_col
#			foundation_instance.layer = offset_indices.y + ind_layer
			foundation_instance.global_transform.origin = spatial_index_to_coord(ind_row,ind_col,ind_layer)
	
	for ind_layer in range(offset_indices.y,offset_indices.y + num_layers):
		for ind_row in range(offset_indices.x, offset_indices.x + num_rows):
			for ind_col in range(offset_indices.z, offset_indices.z + num_cols):
				var floor_instance = floor_base.instance()
				cell_parent.add_child(floor_instance)
				floor_instance.set_owner(get_tree().edited_scene_root)
				floor_instance.row = offset_indices.x + ind_row
				floor_instance.col = offset_indices.z + ind_col
				floor_instance.layer = offset_indices.y + ind_layer
				floor_instance.global_transform.origin = spatial_index_to_coord(ind_row,ind_col,ind_layer)
				
				if (ind_row != offset_indices.x and ind_row != offset_indices.x + num_rows - 1) and (ind_col != offset_indices.z and ind_col != offset_indices.z + num_cols - 1):
					if rand_range(0,1) < 0.5 or (ind_layer > 0 and not cell_below_is_occupied(ind_row,ind_col,ind_layer)):
						continue
				var wall_instance = wall_segment_base.instance()
				cell_parent.add_child(wall_instance)
				wall_instance.set_owner(get_tree().edited_scene_root)
				wall_instance.row = ind_row
				wall_instance.col = ind_col
				wall_instance.layer = ind_layer
				wall_instance.global_transform.origin = spatial_index_to_coord(ind_row,ind_col,ind_layer)
				register_new_cell(wall_instance)
				
	for ind_row in range(offset_indices.x, offset_indices.x + num_rows):
		for ind_col in range(offset_indices.z, offset_indices.z + num_cols):
			var ind_layer = offset_indices.y + num_layers
			var rooftop_instance = rooftop.instance()
			cell_parent.add_child(rooftop_instance)
			rooftop_instance.set_owner(get_tree().edited_scene_root)
			rooftop_instance.row = offset_indices.x + ind_row
			rooftop_instance.col = offset_indices.z + ind_col
			rooftop_instance.layer = offset_indices.y + ind_layer
			rooftop_instance.global_transform.origin = spatial_index_to_coord(ind_row,ind_col,ind_layer)
			rooftop_indices.push_back(Vector3(ind_row,ind_layer,ind_col))
			
	return rooftop_indices

func spawn_enemy(spatial_index):
	var enemy_instance = enemy_thug_base.instance()
	enemy_instance.global_transform.origin = spatial_index_to_coord(spatial_index.x,spatial_index.z,spatial_index.y)
	enemy_parent.add_child(enemy_instance)
	enemy_instance.set_owner(get_tree().edited_scene_root)

func generate_level():
	print('generating level')
	cell_list = []
	cell_index_dict = {}
	randomize()
	for child in cell_parent.get_children():
		child.queue_free()
	
	for i in range(5):
		for j in range(1):
			var random_offset = Vector3(int(rand_range(0,3)),0,int(rand_range(-GRID_WIDTH,GRID_WIDTH)))
			var grid_offset = Vector3(GRID_WIDTH*i,0,GRID_WIDTH*j) + random_offset
			var rooftop_indices = generate_structure(grid_offset)
			if i == 0 and j == 0:
				Globals.current_player.global_transform.origin = spatial_index_to_coord(rooftop_indices[0].x,rooftop_indices[0].z,rooftop_indices[0].y)
			else:
				var num_enemies : int = int(rand_range(0.3 * len(rooftop_indices), 0.75*len(rooftop_indices)))
				print('platform ', i, ' w. ', len(rooftop_indices), ' rooftop tiles gets ', num_enemies, ' enemies')
				var occupied_indices = []
				while len(occupied_indices) < num_enemies:
					var random_rooftop_index = randi() % len(rooftop_indices)
					if not random_rooftop_index in occupied_indices:
						occupied_indices.push_back(random_rooftop_index)
						var rooftop_index = rooftop_indices[random_rooftop_index]
						spawn_enemy(rooftop_index)
					
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
