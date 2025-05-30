extends Node2D

@onready var game = preload("res://scenes/world.tscn")
@onready var tutorial_mode = preload("res://scenes/world.tscn")
@onready var hardness_menu = $hardness
@onready var setting_screen = get_parent().find_child("SettingsScreen")
#@onready var control_sensitivity_effector
@onready var effects_effector

@onready var tutorial_button = $tutorial_mode
@onready var save1_button = $Save1
@onready var save2_button = $Save2
@onready var save3_button = $Save3

@onready var delete1_button = $Delete1
@onready var delete2_button = $Delete2
@onready var delete3_button = $Delete3

@onready var button_order = [tutorial_button,save1_button,save2_button,save3_button,delete1_button,delete2_button,delete3_button]
var button_index = 1
var control_sensitivity_effector

var saved_games = {}

var new_game = null
var game_started = false
var game_save_index = null
# Called when the node enters the scene tree for the first time.

func load_save(save_file):
	var save_game = FileAccess.open(save_file, FileAccess.READ)
	var json_string = save_game.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	print(parse_result)
	if parse_result == 0:
		var save_data = json.get_data()
		return(save_data)

func show_selected():
	var selected = button_order[button_index]
	selected.add_theme_color_override("font_color", Color(1,0,0))
	
	for i in range(0, len(button_order)):
		if i != button_index:
			var not_selected = button_order[i]
			not_selected.add_theme_color_override("font_color", Color(1,1,1))

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	if FileAccess.file_exists("user://savegame_1.json"):
		saved_games[1] = load_save("user://savegame_1.json")
		$Save1.text = "File 1: " + str(saved_games[1]["name"])
	else:
		$Save1.text = "File 1: New"
	
	
	if FileAccess.file_exists("user://savegame_2.json"):
		saved_games[2] = load_save("user://savegame_2.json")
		$Save2.text = "File 2: " + str(saved_games[2]["name"])
	else:
		$Save2.text = "File 2: New"
	
	if FileAccess.file_exists("user://savegame_3.json"):
		saved_games[3] = load_save("user://savegame_3.json")
		$Save3.text = "File 3: " + str(saved_games[3]["name"])
	else:
		$Save3.text = "File 3: New"
	
	#print(mouse_sensitivity_effector)

	#control_sensitivity_effector =  setting_screen.find_child("ControlSensitivity").Value

func _unhandled_input(event):
	var in_sub_menu = $setup.visible
	if event.is_action_pressed("menu_select") and not in_sub_menu:
		if visible:
			button_order[button_index].emit_signal("button_down")
			button_order[button_index].emit_signal("pressed")
	if not in_sub_menu:
		if Input.is_action_just_pressed("menu_down"):
			button_index += 1
		if Input.is_action_just_pressed("menu_up"):
			button_index -= 1
	
	if Input.is_action_just_pressed("menu_close"):
		if not $setup.visible and visible:
			#for body in get_parent().get_children():
			#	body.queue_free()
			#Reset
			get_tree().reload_current_scene()
			queue_free()
		else:
			$setup.visible = false
	
	#Start new file
	if in_sub_menu and event.is_action_pressed("menu_select"):
		$setup/Button.emit_signal("pressed")
	
	if button_index > len(button_order) - 1:
		button_index =  len(button_order) -1
	if button_index < 0:
		button_index = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	show_selected()
#	print(hardness_menu.value)


func start_game():
	if not game_started:
		if new_game != null:
			new_game.queue_free()

		new_game = game.instantiate()
		#new_game.hardness = hardness_menu.value/100
		#new_game.control_sensitivity_effector = control_sensitivity_effector
		new_game.game_index = game_save_index
		#call_deferred("hide")
		hide()

		add_child(new_game)
		game_started = true
		print("started....")
		print(game_save_index)


func reset_game():
	Engine.time_scale = 1.0
	if new_game != null:
		new_game.queue_free()
		new_game = null
	get_tree().reload_current_scene()
	queue_free()
	#game_started = false
	#if new_game != null:
	#	new_game.queue_free()
	#	new_game = null
	#show()

func _on_save_1_button_down():
	game_save_index = 1
	if 1 in saved_games:
		print("We have a save...")
		start_game()
	else:
		print("Setup new game...")
		$setup.visible = true


func _on_save_2_button_down():
	game_save_index = 2
	if 2 in saved_games:
		print("We have a save...")
		start_game()
	else:
		print("Setup new game...")
		$setup.visible = true

func _on_save_3_button_down():
	game_save_index = 3
	if 3 in saved_games:
		print("We have a save...")
		start_game()
	else:
		print("Setup new game...")
		$setup.visible = true

func setup_init_save(p_name, index):
	var _save_file = "user://savegame_" + str(index) + ".json"
	var save_game = FileAccess.open(_save_file, FileAccess.WRITE)
	var empty_items = [[{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}]]
	var init_inventory = {"crystals": 0}
	init_inventory["throttle_zero_centered"] = true
	init_inventory["name"] = p_name
	var save_data = JSON.stringify(init_inventory)
	saved_games[index] = init_inventory
	save_game.store_line(save_data)

func _on_button_pressed():
	var new_player_name = $setup/name_picked.text
	if new_player_name == "":
		new_player_name = "Tiny chicken"
	setup_init_save(new_player_name, game_save_index)
	$setup.visible = false
	start_game()


func _on_delete_1_pressed():
	var dir = DirAccess.open("user://")
	dir.remove_absolute("user://savegame_1.json")
	saved_games.erase(1)
	$Save1.text = "File 1: New"


func _on_delete_2_pressed():
	var dir = DirAccess.open("user://")
	dir.remove_absolute("user://savegame_2.json")
	saved_games.erase(2)
	$Save2.text = "File 2: New"

func _on_delete_3_pressed():
	var dir = DirAccess.open("user://")
	dir.remove_absolute("user://savegame_3.json")
	saved_games.erase(3)
	$Save3.text = "File 3: New"


func _on_tutorial_mode_pressed():
	var new_game = tutorial_mode.instantiate()
	#new_game.control_sensitivity_effector = control_sensitivity_effector
	add_child(new_game)
	self.hide()
