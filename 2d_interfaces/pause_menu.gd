extends Node2D


var level_loader
var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_loader = get_parent()
	player = level_loader.find_child("player")
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_resume_pressed() -> void:
	level_loader.hide_menu()


func _on_exit_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://2d_interfaces/Title.tscn")


func _on_reload_pressed() -> void:
	level_loader.hide_menu()
	player.call_deferred("load_check_point")


func _on_back_to_hub_pressed() -> void:
	level_loader.hide_menu()
	level_loader.call_deferred('load_level', 'hub')


func _on_reset_level_pressed() -> void:
	level_loader.hide_menu()
	level_loader.call_deferred('load_level', level_loader.loaded_level)
