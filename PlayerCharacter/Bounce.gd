extends Spatial

signal bounce(this)

func bounce():
	emit_signal("bounce",self)
