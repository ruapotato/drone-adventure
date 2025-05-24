extends VoxelInstancer


var checked = []

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()


func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if checked != get_children():
		checked = get_children()
		for might_need_despawn in checked:
			#print(might_need_despawn.get_children())
			var t_name = might_need_despawn.get_child(0).name
			t_name += "~" + str(might_need_despawn.global_position.x)
			t_name += "~" + str(might_need_despawn.global_position.y)
			t_name += "~" + str(might_need_despawn.global_position.z)
			#Remove things we have already mined
			#if t_name in player.inventory["graveyard"]:
			#	might_need_despawn.queue_free()
				#print(t_name)
			#else:
			#	print(t_name)
	#print(get_children())
