extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func start_game(save_file) -> void:
	# Create a new config file
	var config = ConfigFile.new()
	
	# Set the value
	config.set_value("Save", "active_save", save_file)
	
	# Save to file
	config.save("user://active_save.cfg")
	
	# Change scene
	get_tree().change_scene_to_file("res://level_bits/level_loader.tscn")


func _on_play_1_pressed() -> void:
	start_game(1)


func _on_play_2_pressed() -> void:
	start_game(2)


func _on_play_3_pressed() -> void:
	start_game(3)


func _on_play_4_pressed() -> void:
	start_game(4)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://2d_interfaces/Title.tscn")


func _on_remove_saves_pressed() -> void:
	$kill_it.show()


func _on_kill_it_pressed() -> void:
	var dir = DirAccess.open("user://")
	dir.remove("user://save_1.cfg")
	dir.remove("user://save_2.cfg") 
	dir.remove("user://save_3.cfg")
	dir.remove("user://save_4.cfg")
	$kill_it.hide()
