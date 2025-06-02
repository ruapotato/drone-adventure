extends Node2D

@onready var game = preload("res://world.tscn")
@onready var hardness_menu = $hardness
@onready var setting_screen = get_parent().find_child("SettingsScreen")
@onready var mouse_sensitivity_effector
@onready var effects_effector
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

	#mouse_sensitivity_effector =  


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	print(hardness_menu.value)


func start_game():
	if not game_started:
		if new_game != null:
			new_game.queue_free()
		get_parent().find_child("EyeLand").visible = false
		get_parent().find_child("Red_Dwarf").visible = false
		get_parent().find_child("Space").queue_free()
		
		new_game = game.instantiate()
		new_game.hardness = hardness_menu.value/100
		var spawn_p = saved_games[game_save_index]["spawn_point"]
		var spawn_s = load("res://" + saved_games[game_save_index]["spawn_scene"] + ".tscn")
		new_game.init_load = [spawn_s, spawn_p]
		new_game.game_index = game_save_index
		self.hide()
		#get_parent().spin = false

		add_child(new_game)
		game_started = true



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

func setup_init_save(p_name, p_gender, index):
	var _save_file = "user://savegame_" + str(index) + ".json"
	var save_game = FileAccess.open(_save_file, FileAccess.WRITE)
	var empty_items = [[{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}],
	[{},{},{},{},{},{},{},{},{},{}]]
	var init_inventory = {"sword": 0, "shield": 0, "crystals": 0,"spawn_scene": "planet", "spawn_point": "main", "menu_items": empty_items}
	init_inventory["gender"] = p_gender
	init_inventory["name"] = p_name
	var save_data = JSON.stringify(init_inventory)
	saved_games[index] = init_inventory
	save_game.store_line(save_data)

func _on_button_pressed():
	var new_player_gender  = $setup/gender_picked.get_selected_items()
	if str(new_player_gender) == str([1]):
		new_player_gender = "male"
	else:
		new_player_gender = "female"
	var new_player_name = $setup/name_picked.text
	if new_player_name == "":
		new_player_name = "grisy"
	setup_init_save(new_player_name, new_player_gender, game_save_index)
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
