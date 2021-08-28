extends Node

var current_player

const DESTRUCTIBLE_GROUP = 'Destructibles'
const ENEMY_GROUP = 'Enemies'
const FOUNDATION_GROUP = 'Foundations'

var collateral_damage_caused : int = 0
var living_thugs : int
var total_thugs : int

var current_level = "res://Levels/TestLevel.tscn"

enum { FIRE_MODE_HITSCAN, FIRE_MODE_PROJECTILES }

var enemy_fire_mode = FIRE_MODE_PROJECTILES

func _init():
	pass
	
func _enter_tree():
	pass
