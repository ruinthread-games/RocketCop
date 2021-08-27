extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var file_paths = ["Assets/Audio/Mus_Menu_01.ogg", "Assets/Audio/Mus_RocketCop_Action_01.ogg"]
var streams = Array()
var idx_song
var curr_vol
var max_vol
var streamplayer
var rocketing = false # bool
# Called when the node enters the scene tree for the first time.
func _ready():
	print("\nloading music...")
	streamplayer = get_child(0)
	for i in range(file_paths.size()):
		if File.new().file_exists(file_paths[i]):
			print("...found %s [%s]" % [file_paths[i], String(i)])
			var audio = load(file_paths[i]) 
			streams.append(audio) # streams appends the loaded file stream
			
	PlayMusic(0)


func PlayMusic(idx):
	idx_song = idx
	streamplayer.stream = streams[idx]
	streamplayer.play()

# unhandled input function is called like late update in Unity

func _unhandled_input(event):
	if event.is_action_pressed("vUp"):
		print("vol++")
		streamplayer.volume_db += 4
		
	if event.is_action_pressed("vDown"):
		print("vol--")
		streamplayer.volume_db -= 4
		
	if event.is_action_pressed("CycleMusic"):
		idx_song += 1
		if idx_song > streams.size() - 1:
			idx_song = 0
		PlayMusic(idx_song)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
