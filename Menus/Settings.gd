extends Spatial


func _init():
	Globals.settings_menu = self
	
func _ready():
	set_visible(false)

func set_visible(new_visible):
	$VBoxContainer.visible = new_visible

func _on_ToggleFullscreenButton_button_up():
	OS.window_fullscreen = not OS.window_fullscreen


func _on_BackButton_button_up():
	set_visible(false)
	Globals.main_menu.set_visible(true)
