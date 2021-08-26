extends Node

var jet_fly
var jet_start

onready var player = get_node("../..") # player node

# audio stream players
var jetpackplayer
var gunplayer

var player_velocity
var isAirborn
var isRocketing
var file_paths = ["Assets/Audio/jet_engage.ogg", "Assets/Audio/jet_fly.ogg", "Assets/Audio/shoot_grenade.ogg"]
var streams = Array()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	print("\nloading player audio...")
	
	jetpackplayer = get_child(0)
	gunplayer = get_child(1)
	
	for i in range(file_paths.size()):
		if File.new().file_exists(file_paths[i]):
			print("...found %s [%s]" % [file_paths[i], String(i)])
			var audio = load(file_paths[i]) 
			streams.append(audio)


func PlayJetEngage(jetpackplayer):
	jetpackplayer.stream = streams[0]
	jetpackplayer.play()

func PlayJetFly(jetpackplayer):
	if isRocketing:
		jetpackplayer.stream = streams[1]
		jetpackplayer.play()

func PlayJetDisengage(jetpackplayer):
	pass
func PlayFireGrenade(gunplayer):
	
	gunplayer.stream = streams[2]
	gunplayer.stream.loop = false
	gunplayer.play()

func _get_input():
	#jetpack sounds
	if Input.is_action_just_pressed("engage_jetpack"):
		
		PlayJetEngage(jetpackplayer)
		isRocketing = true
		PlayJetFly(jetpackplayer)
	
	if Input.is_action_just_released("engage_jetpack"):
		jetpackplayer.stop()
		isRocketing = false
	
	if Input.is_action_just_pressed("fire_grenade") && Input.is_action_pressed("aim_down_sights"):
		if player.ammo_in_clip > 0:
			PlayFireGrenade(gunplayer)
	
	# if the gunplayer is not stopped it will stay in the 'play' state and loop the gun sound



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_get_input()
