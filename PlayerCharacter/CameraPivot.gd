extends Spatial

onready var inner_pivot : Spatial = $CameraPivot

var mouse_sensitivity : float = 0.1

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		inner_pivot.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		
func follow_me(position_to_follow):
	translation = position_to_follow
	
func give_direction() -> Transform:
	return transform
