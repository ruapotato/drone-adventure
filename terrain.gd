extends VoxelLodTerrain

@onready var Instancer = $VoxelInstancer

var player
var setup = false


func _ready():
	player = get_player()
	pass # Replace with function body.

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not setup and player:
		#stream.database_path = OS.get_user_data_dir() + "/world_" + str(player.save_index) + ".sql"
		#var test = VoxelInstanceLibrary.new()
		#test.clear()
		#Instancer.library.remove_item()
		#print(stream.database_path)
		setup = true
