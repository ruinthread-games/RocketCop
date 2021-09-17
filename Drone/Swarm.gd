extends Spatial

onready var base_drone = load("res://Drone/Drone.tscn")
onready var base_drone_ui = load("res://Drone/DroneUI.tscn")

onready var swarm_ui_container = $SwarmStatusContainer/SwarmUIContainer

func spawn_new_drone():
	var drone_instance = base_drone.instance()
	add_child(drone_instance)
	
	var drone_ui_instance = base_drone_ui.instance()
	swarm_ui_container.add_child(drone_ui_instance)
	
func _ready():
	spawn_new_drone()

func _process(delta):
	pass
