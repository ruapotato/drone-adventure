extends Node

@onready var stream = $steam
var level_loader
var player
var music_score = {
	"hub": preload("res://AI_GEN/music/Chiptune-folk fusion - Game time.wav"),
	"level1": preload("res://AI_GEN/music/level1.wav"),
	"level3": preload("res://AI_GEN/music/Chiptune-folk fusion - Game time.wav"),
	"boss1": preload("res://AI_GEN/music/boss1.wav"),
	"end": preload("res://AI_GEN/music/end_song.wav"),
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")

func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "level_loader":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null

func play_song():
	if level_loader and level_loader.loaded_level in music_score:
		# Stop current music if playing
		if stream.playing:
			stream.stop()
		
		# Set the new audio stream
		stream.stream = music_score[level_loader.loaded_level]
		
		# Play the new music
		stream.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_steam_finished() -> void:
	stream.play()
