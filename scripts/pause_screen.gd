extends Node2D

@onready var reuseme_button = $resume
@onready var settings_button = $settings
@onready var exit_button = $exit

@onready var button_order = [reuseme_button,settings_button,exit_button]
var button_index = 0

var chicken
var world
var startup_screen

# Called when the node enters the scene tree for the first time.
func _ready():
	chicken = get_chicken()
	world = chicken.get_parent()
	startup_screen = world.get_parent()

func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))
	
func show_selected():
	var selected = button_order[button_index]
	selected.add_theme_color_override("font_color", Color(1,0,0))
	
	for i in range(0, len(button_order)):
		if i != button_index:
			var not_selected = button_order[i]
			not_selected.add_theme_color_override("font_color", Color(1,1,1))


func _unhandled_input(event):
	var in_sub_menu = $SettingsScreen.visible
	if event.is_action_pressed("pause"):
		if visible:
			Engine.time_scale = 1.0
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
		else:
			Engine.time_scale = 0.01
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		visible = !visible
	if visible and not in_sub_menu:
		if event.is_action_pressed("menu_select"):
			button_order[button_index].emit_signal("button_down")
			button_order[button_index].emit_signal("pressed")
		
		if Input.is_action_just_pressed("menu_down"):
			button_index += 1
		if Input.is_action_just_pressed("menu_up"):
			button_index -= 1
		
		if button_index == 1 and not $settings.visible:
			if Input.is_action_just_pressed("menu_down"):
				button_index = 2
			if Input.is_action_just_pressed("menu_up"):
				button_index = 0
		if button_index > len(button_order) - 1:
			button_index =  len(button_order) -1
		if button_index < 0:
			button_index = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not visible:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			#print("MOUSE BUG")
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	if visible:
		show_selected()
		if chicken.tutorial_mode:
			if $contols.visible:
				$contols.visible = false
		#if "lander_skin" in chicken.inventory:
		#	if not $settings.visible:
		#		$settings.visible = true


func _on_reuseme_pressed():
	Engine.time_scale = 1.0
	hide()


#func _on_settings_pressed():
#	if "lander_skin" in chicken.inventory:
#		chicken.inventory["lander_skin"] = !chicken.inventory["lander_skin"]
#		world.pause()


func _on_exit_pressed():
	startup_screen.reset_game()
	#get_tree().quit()
	#for body in get_parent().get_children():
	#	body.queue_free()
	#get_tree().reload_current_scene()


func _on_settings_pressed():
	$SettingsScreen.visible = true
