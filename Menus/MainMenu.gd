extends Spatial

func _init():
	Globals.main_menu = self

func _on_StartGameButton_button_up():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Globals.current_player.start_game()
	set_visible(false)
	Globals.music_manager.PlayMusic(1)

func _on_SettingsButton_button_up():
	set_visible(false)
	Globals.settings_menu.set_visible(true)

func set_visible(new_visible):
	$VBoxContainer.visible = new_visible
	$Title.visible = new_visible

func trigger_victory():
	$Victory.visible = true
	$VBoxContainer.visible = true
	$VBoxContainer/RestartGameButton.visible = true
	$VBoxContainer/StartGameButton.visible = false


func _on_RestartGameButton_button_up():
	get_tree().change_scene("res://Levels/TestLevel.tscn")
