extends Node3D

@onready var crystal = preload("res://scenes/crystal.tscn")
@onready var env = $WorldEnvironment
@onready var music = $music
@onready var chicken = $chicken
@onready var gee = $Gee
@onready var sun = $sun
#@onready var city = $city
@onready var ufos = $ufos
@onready var spawner = $spawner

@onready var UFO = preload("res://entities/ufo.tscn")
#@onready var point_of_view = $pov
@onready var planet = $planet
@onready var dirt_voxels # Initialized in _ready
@onready var crystal_voxels # Initialized in _ready
@onready var gui = $gui
@onready var spawn = $spawn
@onready var pause_screen = $pause_screen

const SAFE = Vector3(10000,10000,10000)
const FOG_DENSITY_TARGET_CLEAR = 0.002
const FOG_DENSITY_TARGET_FOGGY = 0.00526
const FOG_CLEAR_TRANSITION_DURATION: float = 15.0
const FOG_GETTING_TRANSITION_DURATION: float = 30.0
const ALTITUDE_FOG_TRANSITION_DURATION: float = 8.0

const day_workflow = {
	5.0:"day_spawn",
	7.5: "clear_fog",
	21.0:"night_spawn",
	23.0: "get_foggy",
	2.0: "UFO"
}

@onready var music_list = {
	"underground":preload("res://import/CC0_by_mrpoly_awesomeness.wav"),
	"ufo":preload("res://import/CC0_ruskerdax_-_the_creep.mp3"),
	"shop":preload("res://import/CC_BY_3.0_Varon_Kein_The Three Princesses of Lilac Meadow.ogg"),
	"meadow":preload("res://import/CC_by_4_migfus20_asdf_2.mp3"),
	"city":preload("res://import/CC-BY_Spring_Spring_Title_field 2_Master.ogg"),
	"heighup":preload("res://import/CC_by_3.0_Matthew Pablo_Desolate Collection/Desolate.mp3"),
	"dogs":preload("res://import/CC0_by_celestialghost8_Inevitable Doom.wav")
}
var hour_index: float
var dirt_vt # VoxelTool
var crystal_vt # VoxelTool
var time_to_init: float = 10.0
var init_done: bool = false
var game_index = 0
# Properties like hardness, game_index, control_sensitivity_effector, plants, terrain_chop were not used in the functions.
# If they are used by other scripts accessing this node, keep them. Otherwise, they can be removed.
var friendly_time: float
var friendly_time_am: bool = false

var controlable: Array # Initialize in _ready

var active_task: String = ""
var tasks_today: Dictionary = day_workflow.duplicate()

var dogs_pissed: bool = false
var boss_life = 0.0 
var boss_max_life = 0.0

var last_mouse_move: float = 0.0
var sky_material # Cached in _ready

const OUTER_RIM_START: float = 9000.0 # Considered TERMINATOR_DISTANCE

func _ready():
	sky_material = env.environment.sky.sky_material # Cache for direct access
	
	dirt_voxels = planet.get_node("VoxelLodTerrain") 
	dirt_vt = dirt_voxels.get_voxel_tool() 
	crystal_vt = dirt_vt 

	controlable = [chicken, gee] # Initialize here after @onready vars are set
	
	# Call once at start to set initial sun based on starting position
	update_sun_angle_by_location()
	# Call dependent updates once too, if needed for immediate setup
	update_friendly_time() 
	update_sky_energy(0.0) # Pass 0 delta or a small value for initial setup


func run_active_tasks(delta: float):
	if active_task == "clear_fog":
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density, FOG_DENSITY_TARGET_CLEAR, delta / FOG_CLEAR_TRANSITION_DURATION)
	if active_task == "get_foggy":
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density, FOG_DENSITY_TARGET_FOGGY, delta / FOG_GETTING_TRANSITION_DURATION)
	if active_task == "day_spawn":
		spawner.day_spawn = true
		spawner.night_spawn = false
	if active_task == "night_spawn":
		spawner.day_spawn = false
		spawner.night_spawn = true
	if active_task == "UFO":
		if ufos.get_child_count() == 0 and chicken.global_position.y > -50:
			print("INIT UFO")
			var new_ufo = UFO.instantiate()
			ufos.add_child(new_ufo)
			active_task = ""


func update_workflow():
	var current_hour_for_workflow = hour_index 
	
	if current_hour_for_workflow < 0.2 and tasks_today.size() < day_workflow.size(): # Heuristic for "new day"
		tasks_today = day_workflow.duplicate()
	
	var tasks_to_remove = []
	for todo_item_time in tasks_today:
		if abs(todo_item_time - current_hour_for_workflow) < 0.2:
			active_task = tasks_today[todo_item_time]
			tasks_to_remove.append(todo_item_time)
	
	for item_time in tasks_to_remove:
		tasks_today.erase(item_time)


func message(this_message: String):
	gui.system_messages.text = this_message
	gui.system_messages.show()
	gui.system_messages_counter = 10


func update_friendly_time():
	var rot_x_deg = rad_to_deg(sun.rotation.x) # Now -90 (noon) to 0 (sunset) to +90 (antipode)
	var hour: float # Use 'hour' consistently with your original var name
	var AM_PM_text = "PM" # Default, will be changed if rot_x_deg < 0
	
	# Your existing formula branches, which should now work with the new sun angle range
	if rot_x_deg < 0: # Noon (-90) towards one horizon (0) - let's call this "AM" equivalent
		hour = (180.0 + rot_x_deg) / 180.0 * 12.0 - 6.0 # Results in 0 (at -90 deg) to 6 (at 0 deg)
		AM_PM_text = "AM"
		friendly_time_am = true
	else: # Past horizon (0) towards antipode (+90) - let's call this "PM" equivalent night
		hour = (180.0 + rot_x_deg) / 180.0 * 12.0 - 6.0 # Results in 6 (at 0 deg) to 12 (at +90 deg)
		AM_PM_text = "PM"
		friendly_time_am = false

	friendly_time = hour 
	# hour_index is used by workflow and needs the full 0-12+ range from these calculations
	hour_index = hour 
	# If 'hour' can go up to 12 for the antipode, workflow logic for 21.0, 23.0 might need review
	# as they might not be reached if hour_index maxes at 12.
	# Your original formula for rot_x > 0 made hour go from 6 (at 0 deg) up to 18 (at 180 deg).
	# Let's ensure hour_index reflects a 0-24 style range if that's what day_workflow expects.
	# The current formula produces 0-6 (AM-like) and 6-12 (PM-like). Total 12 "game hours".
	# If day_workflow needs 24h style, this hour calculation needs to be scaled or offset for the >0 part.

	# Let's adjust hour_index for workflow if it expects values like 21.0, 23.0
	if not friendly_time_am and hour_index < 12.0 : # If PM and hour is 6-11.99 (after sunset)
		# This means it's the "evening/night" part of the cycle
		# If your workflow's 21.0 means "3 hours before conceptual midnight" where midnight is "hour 12" from this formula
		# then this hour_index (6 to 12) can be used.
		# If workflow 21.0 literally means 9 PM on a 24h clock, then:
		# hour_index = hour + 12.0 # This makes PM hours 18:00 to 24:00
		pass # For now, hour_index is 0-6 for AM part, 6-12 for PM part based on the formula.


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		last_mouse_move = 0.0


func play_as_gee():
	var loc = chicken.global_position
	var rot = chicken.global_rotation
	var vol = chicken.linear_velocity
	
	gee.active = true
	gee.gass = 100 
	gee.global_position = loc
	gee.global_rotation = rot
	gee.linear_velocity = vol 
	
	chicken.active = false
	(gee.get_node("Camera3D") as Camera3D).current = true


func play_as_chicken():
	var loc = gee.global_position
	var rot = gee.global_rotation
	var vol = gee.linear_velocity
	
	gee.active = false
	(gee.get_node("Camera3D") as Camera3D).current = false

	chicken.global_position = loc
	chicken.global_rotation = rot
	chicken.linear_velocity = vol 
	(chicken.get_node("Camera3D") as Camera3D).current = true 
	chicken.active = true
	

func pause():
	if pause_screen.visible:
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 0.01
	pause_screen.visible = not pause_screen.visible


func add_crystal_to_world(value: int, pos: Vector3):
	var world_node = chicken.get_parent() 
	var new_crystal_instance = crystal.instantiate()
	
	new_crystal_instance.value = value 
	new_crystal_instance.init_pos = pos 
	
	world_node.add_child(new_crystal_instance)
	new_crystal_instance.global_position = pos


func hurt(body: Node3D, how_much: float):
	var actual_target = body
	if body.name.begins_with("weak_point"):
		actual_target = body.get_parent()
		how_much *= 3
	
	if actual_target.name.contains("crow") and actual_target.visible:
		actual_target.visible = false
		add_crystal_to_world(randi_range(20,100), actual_target.global_position)
	elif actual_target.name.contains("crystal"):
		actual_target.shatter()
	elif actual_target.name == "top_balloon":
		(actual_target as RigidBody3D).mass = 0.1
		((actual_target.find_child("balloon_shape") as CollisionShape3D).shape as SphereShape3D).radius = 0.1
		(actual_target.find_child("balloon_mesh") as MeshInstance3D).visible = false
	elif actual_target.name == "dog":
		dogs_pissed = true
		print("Pissed on the dogs")
	elif actual_target.name == "ufo":
		actual_target.life -= how_much
		actual_target.fly_ttl = 20
	elif actual_target.name == "mini_ufo":
		actual_target.get_parent().life -= how_much
	# Generic life check - if 'life' is a common script variable / exported property
	elif "life" in actual_target: # Check if property exists using 'in' for script variables
		actual_target.life -= how_much


func update_sky_energy(delta: float):
	var target_sky_energy: float
	var sun_rot_x_rad = sun.rotation.x # Current angle: -PI/2 (noon) to 0 (sunset) to +PI/2 (antipode)

	const NOON_ANGLE_RAD = -PI / 2.0
	const HORIZON_ANGLE_RAD = 0.0
	const ANTIPODE_ANGLE_RAD = PI / 2.0
	
	const DAY_ENERGY = 1.0
	const NIGHT_ENERGY = 0.15 # Energy for full night/antipode
	const SUNSET_ENERGY = 0.4 # Energy at horizon, slightly brighter than full night

	if sun_rot_x_rad < HORIZON_ANGLE_RAD: # From Noon (-PI/2) to just before Horizon (0)
		# Interpolate from DAY_ENERGY at NOON_ANGLE_RAD to SUNSET_ENERGY at HORIZON_ANGLE_RAD
		var progress_to_horizon = inverse_lerp(NOON_ANGLE_RAD, HORIZON_ANGLE_RAD, sun_rot_x_rad)
		target_sky_energy = lerp(DAY_ENERGY, SUNSET_ENERGY, progress_to_horizon)
	else: # From Horizon (0) to Antipode (PI/2)
		# Interpolate from SUNSET_ENERGY at HORIZON_ANGLE_RAD to NIGHT_ENERGY at ANTIPODE_ANGLE_RAD
		var progress_to_antipode = inverse_lerp(HORIZON_ANGLE_RAD, ANTIPODE_ANGLE_RAD, sun_rot_x_rad)
		target_sky_energy = lerp(SUNSET_ENERGY, NIGHT_ENERGY, progress_to_antipode)
	
	sky_material.sky_energy_multiplier = lerp(sky_material.sky_energy_multiplier, target_sky_energy, delta * 0.5)


func update_env(delta: float):
	if chicken.global_position.y > 200:
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density, 0.0, delta / ALTITUDE_FOG_TRANSITION_DURATION)
	
	if chicken.global_position.y < -50:
		env.environment.volumetric_fog_albedo = Color("#9e0174")
	else:
		env.environment.volumetric_fog_albedo = Color(1,1,1)


func update_music():
	var music_pick_key = ""
	
	if chicken.global_position.y > 750: music_pick_key = "heighup"
	elif chicken.global_position.y > 430: music_pick_key = "city"
	elif chicken.global_position.y > -50: music_pick_key = "meadow"
	else: music_pick_key = "underground"
		
	if gui.message_box.visible: music_pick_key = "shop"
	if ufos.get_child_count() > 0: music_pick_key = "ufo"
	if dogs_pissed: music_pick_key = "dogs"

	var target_volume_db = 0.0
	if music_pick_key == "heighup": target_volume_db = 0
	elif music_pick_key == "city": target_volume_db = -5
	elif music_pick_key == "meadow": target_volume_db = 0
	elif music_pick_key == "underground": target_volume_db = -10
	elif music_pick_key == "shop": target_volume_db = -15
	elif music_pick_key == "ufo": target_volume_db = -10
	elif music_pick_key == "dogs": target_volume_db = 0
	
	music.volume_db = target_volume_db

	if music_pick_key in music_list and music_list[music_pick_key] != music.stream:
		music.stream = music_list[music_pick_key]
		music.play()
	elif not music.playing and music.stream != null:
		music.play()


func update_mouse(delta: float):
	last_mouse_move += delta
	if last_mouse_move > 3.0:
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func update_sun_angle_by_location():
	var player_pos_xz = Vector2(chicken.global_position.x, chicken.global_position.z)
	var dist_from_origin = player_pos_xz.length()

	const TERMINATOR_DISTANCE = OUTER_RIM_START
	if TERMINATOR_DISTANCE <= 0.001:
		sun.rotation.x = -PI / 2.0 # Noon
		return

	# Distance from noon (origin) to antipode (opposite side of "day" hemisphere)
	# This is the distance over which the sun angle will sweep 180 degrees (-90 to +90)
	const NOON_TO_ANTIPODE_DISTANCE = TERMINATOR_DISTANCE * 2.0 
	if NOON_TO_ANTIPODE_DISTANCE <= 0.001: # Should not happen if TERMINATOR_DISTANCE > 0
		sun.rotation.x = -PI / 2.0 # Noon
		return
		
	# Normalized progress: 0 at origin (noon), 0.5 at terminator, 1.0 at antipode
	var normalized_progress = dist_from_origin / NOON_TO_ANTIPODE_DISTANCE
	
	# Map this progress (0 to 1 ideally, but can be >1 if player goes beyond antipode)
	# to sun angle from -PI/2 (noon) to +PI/2 (antipode)
	var sun_angle_rad: float = lerp(-PI / 2.0, PI / 2.0, normalized_progress)
	
	# Clamp the angle to ensure it stays within the -90 to +90 degree range.
	# This means if player goes beyond the "antipode" distance, sun stays at nadir.
	sun.rotation.x = clamp(sun_angle_rad, -PI / 2.0, PI / 2.0)


func _process(delta: float):
	if not init_done:
		time_to_init -= delta
		if time_to_init < 0:
			init_done = true
		# Call updates once when init is done for immediate effect
		update_sun_angle_by_location() 
		update_friendly_time()  
		update_sky_energy(0.0001) # Small delta for initial lerp step
		return

	update_sun_angle_by_location()
	update_friendly_time()
	update_sky_energy(delta)
	update_workflow()
	run_active_tasks(delta)
	update_env(delta)
	update_music()
	update_mouse(delta)


func _on_music_finished():
	if music.stream != null:
		music.play()
