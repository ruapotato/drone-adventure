extends RigidBody3D

@onready var mini_ufo = preload("res://mini_ufo.tscn")
@onready var expload_effect = $expload_effect
@onready var flash_light = $flash_light
@onready var mesh = $ufo2
@onready var flash_sound = $flash_sound
@onready var weak_point = $weak_point
var SPEED = 300

var spawn_point = Vector3(0,1000,0)
var hover_point = Vector3(0,0,0)

var active_task = "drop"
var fly_ttl = 30
var start_life = 84
var life = start_life
var last_updated_life = life
var hurt_counter = 0
var drone
var world
var dead = false
var dead_reset_counter = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	weak_point.add_collision_exception_with(self)
	gravity_scale = 0
	drone = get_drone()
	world = drone.world
	global_position = spawn_point
	var parent_pos = drone.global_position
	spawn_point.x = parent_pos.x
	spawn_point.z = parent_pos.z
	hover_point.x = parent_pos.x
	hover_point.z = parent_pos.z
	hover_point.y = parent_pos.y + 30
	world.boss_max_life = life
	world.boss_life = life

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func spawn_mini():
	flash_sound.play()
	var new_mini_ufo = mini_ufo.instantiate()
	world.add_child(new_mini_ufo)
	new_mini_ufo.global_position = global_position - Vector3(0,1,0)
	
	#effects
	flash_light.light_energy = 50
	if drone.shake < 0.2:
		drone.shake += .05

func process_light(delta):
	if flash_light.light_energy > 0:
		flash_light.light_energy = lerp(flash_light.light_energy, 0.0, delta * 10)

func update_life():
	if world.boss_life != life:
		world.boss_life = life

func _physics_process(delta):
	weak_point.position = Vector3(0,0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_life()
	if dead:
		if dead_reset_counter > 0:
			mesh.scale = mesh.scale.lerp(Vector3(.05,.05,.05), delta)
			rotation_degrees.z = lerp(rotation_degrees.z, 180.0, delta)
			dead_reset_counter -= delta
		else:
			print("Ufo done")
			spawn_mini()
			queue_free()
		return
	
	if life != last_updated_life:
		hurt_counter += last_updated_life - life
		last_updated_life = life
	
	var needed_to_spawn = (life/start_life) * 12
	needed_to_spawn += .3
	#print(needed_to_spawn)
	if hurt_counter > needed_to_spawn:
		hurt_counter -= needed_to_spawn
		spawn_mini()

	if life <= 0:
		expload_effect.emitting = true
		dead_reset_counter = 7
		drone.shake = .5
		flash_light.light_energy = 50.0
		dead = true
		world.boss_max_life = null
		world.boss_life = null
		drone.world.add_crystal_to_world(randi_range(100,300),global_position)
		#queue_free()

	if global_position.distance_to(hover_point) < 2:
		#print("UFO flying")
		active_task = "fly"
		linear_velocity = Vector3(randf_range(-20,20),0,randf_range(-20,20))
	
	if active_task == "fly":
		fly_ttl -= delta
		if fly_ttl < 0:
			active_task = "run"
	if active_task == "run":
		global_position = global_position.move_toward(spawn_point, delta * SPEED)
	if active_task == "drop":
		global_position = global_position.move_toward(hover_point, delta * SPEED)
	if active_task == "run" and global_position.distance_to(spawn_point) < 2:
		#print("UFO done")
		world.boss_max_life = null
		world.boss_life = null
		queue_free()
	
	process_light(delta)


func _on_flying_finished():
	$flying.play()
