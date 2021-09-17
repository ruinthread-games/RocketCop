extends GraphNode

var value = "OutputNode"
# Called when the node enters the scene tree for the first time.
func _ready():
	# move
	set_slot(0,true, 0, Color(1,1,1,1),false,0,Color(0))
	set_slot(1,true, 0, Color(0,1,1,1),false,0,Color(0))
	set_slot(2,true, 0, Color(0,1,1,1),false,0,Color(0))
	set_slot(3,true, 0, Color(0,1,1,1),false,0,Color(0))
	
