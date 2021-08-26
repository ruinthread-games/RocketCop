extends Spatial

var row
var col
var layer

var occupied

var cell_type

func _ready():
	add_to_group(Globals.DESTRUCTIBLE_GROUP)

func destroy(body, blast_origin):
	for child in get_children():
		var static_body = child.get_child(0)
		if body == static_body:
			child.visible = false
			static_body.get_child(0).disabled = true
