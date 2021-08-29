extends Node

var current_player

const DESTRUCTIBLE_GROUP = 'Destructibles'
const ENEMY_GROUP = 'Enemies'
const FOUNDATION_GROUP = 'Foundations'

var collateral_damage_caused : int = 0
var living_thugs : int
var total_thugs : int

var current_level = "res://Levels/TestLevel.tscn"

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
