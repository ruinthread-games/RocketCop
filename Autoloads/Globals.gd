extends Node

var current_player

const DESTRUCTIBLE_GROUP = 'Destructibles'
const ENEMY_GROUP = 'Enemies'
const FOUNDATION_GROUP = 'Foundations'

var collateral_damage_caused : int = 0
var living_thugs : int
var total_thugs : int

var current_level_scene = "res://Levels/TestLevel.tscn"
var current_level_instance = null

var main_menu = null
var settings_menu = null
var music_manager = null

const MUSIC_MENU = 0
const MUSIC_ACTION = 1
const MUSIC_VICTORY = 2
const MUSIC_FAILURE = 3


enum { FIRE_MODE_HITSCAN, FIRE_MODE_PROJECTILES }

var enemy_fire_mode = FIRE_MODE_PROJECTILES

var level_index = 0

var cut_voice_lines_unlocked : bool = false
var play_cut_voicelines : bool = false

func _init():
	pass
	
func _enter_tree():
	pass

func register_thug_death():
	living_thugs -= 1
	if living_thugs == 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		current_player.mouse_control_camera = false
		current_player.set_ui_visible(false)
		main_menu.trigger_victory()
		music_manager.PlayMusic(MUSIC_VICTORY,2)

func unlock_cut_voicelines():
	cut_voice_lines_unlocked = true
	current_player.show_cut_voice_lines_howto()
	

func _input(event):
	if cut_voice_lines_unlocked and event.is_action_pressed("toggle_cut_voice_lines"):
		play_cut_voicelines = not play_cut_voicelines
		if play_cut_voicelines:
			current_player.play_taunt()
