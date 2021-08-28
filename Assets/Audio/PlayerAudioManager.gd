extends Node

var jet_fly
var jet_start

onready var player = get_node("../..") # player node

# audio stream players
onready var thrustplayer = $ThrustPlayer
onready var jetpackplayer = $JetPlayer
onready var gunplayer = $GunPlayer
onready var dialogueplayer = $DialoguePlayer
onready var extraplayer = $ExtraPlayer

var player_velocity
var isAirborn
var isRocketing
var file_paths = ["Assets/Audio/jet_engage.ogg", "Assets/Audio/jet_fly.ogg", "Assets/Audio/shoot_grenade.ogg"]

var streams = Array()
var taunt_lines = Array()

var jet_engage_audio = null
var jet_fly_audio = null
var shoot_grenade_audio = null

var isDying = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	print("\nloading player audio...")
	
	
	streams = []
	
	for i in range(file_paths.size()):
		print("...found %s [%s]" % [file_paths[i], String(i)])
		var audio = load(file_paths[i]) 
		streams.append(audio)
		
	for i in range(7):
		var taunt = load("res://Assets/Audio/pc_taunt_0"+str(i+1)+".wav")
		taunt_lines.append(taunt)

func PlayPlayerDeath():
	dialogueplayer.stream = load("res://Assets/Audio/pc_die_01.wav")
	dialogueplayer.play()

func PlayPlayerDying():
	extraplayer.stream = load("res://Assets/Audio/player_dying.ogg")
	#extraplayer.stream.loop = false
	print('player dying sound!')
	extraplayer.play()

func PlayPlayerTauntEnemy():
	dialogueplayer.stream = taunt_lines[randi()%len(taunt_lines)]
	dialogueplayer.play()

func PlayJetEngage(jetpackplayer):
	jetpackplayer.stream = streams[0]
	jetpackplayer.stream.loop = false
	jetpackplayer.play()

func PlayJetFly(jetpackplayer):
	if isRocketing:
		jetpackplayer.stream = streams[1]
		jetpackplayer.play()
		

func PlayJetDisengage(jetpackplayer):
	pass

func ModJetPitch(streamplayer):
	# is updated every frame depending on what the charge is at for the jetpack
	# AudioServer is how you access the audio busses	
	var ratio = player.jetpack_charge 
	#print("Ptch ratio = %.2f" % ratio  )
	AudioServer.get_bus_effect(3,0).set_pitch_scale(max(0.0,float(ratio)))


func PlayFireGrenade(gunplayer):
	gunplayer.stream = streams[2]
	gunplayer.stream.loop = false
	gunplayer.play()

func _get_input():
	#jetpack sounds
	if Input.is_action_just_pressed("engage_jetpack"):
		
		PlayJetEngage(thrustplayer)
		isRocketing = true
		PlayJetFly(jetpackplayer)
	
	if Input.is_action_just_released("engage_jetpack") || player.jetpack_charge <= 0:
		jetpackplayer.stop()
		isRocketing = false
	
	if Input.is_action_just_pressed("fire_grenade") && player.aim_down_sights_progress == 1:
		if player.ammo_in_clip > 0:
			PlayFireGrenade(gunplayer)
			
	
	# if the gunplayer is not stopped it will stay in the 'play' state and loop the gun sound

func player_health_changed():
	if player.current_health < 0.5 * player.MAX_HEALTH and not player.is_regenerating_health :
		if not isDying:
			PlayPlayerDying()
			isDying = true
	else:
		extraplayer.stop()
		isDying = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_get_input()
	ModJetPitch(jetpackplayer)
	
	
