extends Node2D

@onready var game = preload("res://startup_screen.tscn")
var new_game = null
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.show()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#func _unhandled_input(event):
#	if Input.is_action_just_pressed("quit"):
#		get_tree().quit()

func _on_button_pressed():
	if new_game != null:
		new_game.queue_free()
	new_game = game.instantiate()
	
	new_game.mouse_sensitivity_effector = $SettingsScreen.find_child("MouseSensitivity").value
	new_game.effects_effector = $SettingsScreen.find_child("Effects").value
	self.hide()
	get_parent().add_child(new_game)


func _on_quit_pressed():
	get_tree().quit()


func _on_info_pressed():
	$Credit.visible = true


func _on_settings_pressed():
	$SettingsScreen.visible = true
