extends Node2D

@onready var reuseme_button = $resume
@onready var toggle_skin_button = $toggle_skin
@onready var exit_button = $exit

@onready var button_order = [reuseme_button,toggle_skin_button,exit_button]
var button_index = 0

var drone
var world
var startup_screen

# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()
	world = drone.world
	startup_screen = world.get_parent()

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))
	
func show_selected():
	var selected = button_order[button_index]
	selected.add_theme_color_override("font_color", Color(1,0,0))
	
	for i in range(0, len(button_order)):
		if i != button_index:
			var not_selected = button_order[i]
			not_selected.add_theme_color_override("font_color", Color(1,1,1))


func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if visible:
			Engine.time_scale = 1.0
		else:
			Engine.time_scale = 0.01
		visible = !visible
	if visible:
		if event.is_action_pressed("menu_select"):
			button_order[button_index].emit_signal("button_down")
			button_order[button_index].emit_signal("pressed")
		
		if Input.is_action_just_pressed("menu_down"):
			button_index += 1
		if Input.is_action_just_pressed("menu_up"):
			button_index -= 1
		
		if button_index == 1 and not $toggle_skin.visible:
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
	if visible:
		show_selected()
		if drone.tutorial_mode:
			if $contols.visible:
				$contols.visible = false
		if "lander_skin" in drone.inventory:
			if not $toggle_skin.visible:
				$toggle_skin.visible = true


func _on_reuseme_pressed():
	Engine.time_scale = 1.0
	hide()


func _on_toggle_skin_pressed():
	if "lander_skin" in drone.inventory:
		drone.inventory["lander_skin"] = !drone.inventory["lander_skin"]
		world.pause()


func _on_exit_pressed():
	startup_screen.reset_game()
	#get_tree().quit()
	#for body in get_parent().get_children():
	#	body.queue_free()
	#get_tree().reload_current_scene()
