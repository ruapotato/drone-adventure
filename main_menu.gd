extends Node2D

@onready var game = preload("res://startup_screen.tscn")

@onready var play_button = $play
@onready var help_button = $help
@onready var quit_button = $quit
@onready var setting_button = $settings

@onready var button_order = [play_button,setting_button,help_button,quit_button]
var button_index = 0

var new_game = null
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.show()
	pass # Replace with function body.


func show_selected():
	var selected = button_order[button_index]
	selected.add_theme_color_override("font_color", Color(1,0,0))
	
	for i in range(0, len(button_order)):
		if i != button_index:
			var not_selected = button_order[i]
			not_selected.add_theme_color_override("font_color", Color(1,1,1))
	#selected.get_theme().
	#theme_override_colors.font_color = Color(1,0,0)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	show_selected()

func _unhandled_input(event):
	if event.is_action_pressed("menu_select"):
		if visible:
			button_order[button_index].emit_signal("pressed")
	
	if event.is_action_pressed("menu_down"):
		button_index += 1
	if event.is_action_pressed("menu_up"):
		button_index -= 1
	
	
	if button_index > len(button_order) - 1:
		button_index =  len(button_order) -1
	if button_index < 0:
		button_index = 0
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
