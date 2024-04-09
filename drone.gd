extends RigidBody3D

@onready var bullet = preload("res://bullet.tscn")
@onready var camera = $Camera3D
@onready var target = $Label3D
@onready var shoot_from = $shoot_from
@onready var back_cam_mount = $back_cam_mount
@onready var speed_collision = $speedCollision
@onready var shield = $shield
@onready var shield_sound = $shield_sound
@onready var shield_cam = $shield/shield_camera
@onready var expload_effect = $expload_effect
@onready var expload_sound = $expload_sound
@onready var ingenuity_mesh = $ingenuity_mesh
@onready var mesh = $mesh
@onready var pause_screen = $"../pause_screen"
var collision_size_at_rest = .075

var save_index = null
var inventory = null
var save_file = null
var unlocked_gun = true
var shoot_speed = 34
var wind_effect = -.0005
var power_cell = 100
var extra_power_cell = 0
var extra_power_per_upgrade = 10

var power_gain = 1
var power_gain_at_rest = 25
var power_cost = .5
var fire_cost = 3
var shake = 0.0
var og_camera_angle
var dead = false
var dead_reset_counter = 0

var throttle = 0.0
#var max_throttle = 3.5
var max_throttle = 3.9

var yaw = 0.0
var yaw_speed = 3

var pitch = 0.0
var pitch_speed = 5
var cam_pitch = 0.0
var cam_roll = 0.0

var roll = 0.0
var roll_speed = 5
var tp_cooldown = 0
var world
var last_velocity = Vector3(0,0,0)
var tutorial_mode = false

var cam_inti_rot
var cam_pitch_add = 0.0
var skeleton
# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_parent()
	skeleton = mesh.find_child("Skeleton3D")
	if get_parent().find_child("is_tutorial"):
		tutorial_mode = true
		inventory = {"crystals":0}
	if not tutorial_mode:
		save_index = get_parent().game_index
		save_file = "user://savegame_" + str(save_index) + ".json"
		inventory = load_save(save_file)
	
	og_camera_angle = camera.rotation_degrees
	cam_inti_rot = camera.rotation

func save_game():
	var save_game = FileAccess.open(save_file, FileAccess.WRITE)
	#var save_data = JSON.stringify({"crystals":gender,
	#"name":player_picked_name})
	save_game.store_line(JSON.stringify(inventory))

func load_save(save_file):
	var save_game = FileAccess.open(save_file, FileAccess.READ)
	var json_string = save_game.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	#print(parse_result)
	if parse_result == 0:
		var save_data = json.get_data()
		return(save_data)

func fire_landgun():
	if not "land_making_gun" in inventory:
		return
	var new_bullet = bullet.instantiate()
	new_bullet.set_deferred("global_position", shoot_from.global_position)
	new_bullet.add_mode = true
	#new_bullet.init_pos = shoot_from.global_position
	#new_bullet.init_vel = linear_velocity + (-global_transform.basis.z *  shoot_speed)
	#new_bullet.init_vel = (-global_transform.basis.z *  shoot_speed)
	
	
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_impulse(-camera.global_transform.basis.z *  shoot_speed)
	apply_impulse(global_transform.basis.z * .1)
	get_parent().add_child(new_bullet)

func fire_normal():
	if not unlocked_gun:
		return
	var new_bullet = bullet.instantiate()
	new_bullet.set_deferred("global_position", shoot_from.global_position)
	new_bullet.add_mode = false
	#new_bullet.init_pos = shoot_from.global_position
	#new_bullet.init_vel = linear_velocity + (-global_transform.basis.z *  shoot_speed)
	#new_bullet.init_vel = (-global_transform.basis.z *  shoot_speed)
	
	
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_impulse(-camera.global_transform.basis.z *  shoot_speed)
	apply_impulse(global_transform.basis.z * .1)
	get_parent().add_child(new_bullet)
	
func get_max_throttle():
	var effect = 1 - power_cell/100
	#print(effect)
	return(max_throttle - (effect * 1.9))

func _unhandled_input(event):
	if is_paused():
		return
		
	if power_cell > fire_cost:
		if event.is_action_pressed("fire_right"):
			draw_power(fire_cost)
			#power_cell -= fire_cost
			fire_normal()
		if event.is_action_pressed("fire_left"):
			draw_power(fire_cost)
			#power_cell -= fire_cost
			fire_landgun()
	
	# aim mode
	if Input.is_action_pressed("aim"):
		aim_mode_unhandled_input(event)
		return
	if Input.is_action_just_released("aim"):
		throttle = Input.get_action_strength("throttle") * get_max_throttle()
		#print(Input.get_action_strength("throttle"))
	#	throttle = 0.0
		#throttle = -event.axis_value * get_max_throttle()
	
	# normal mode
	if event.is_action("throttle"):
		#print(-event.axis_value)
		throttle = -event.axis_value * get_max_throttle()
	if event.is_action("yaw"):
		yaw = -event.axis_value
		#print(event.axis_value)
		yaw = -event.axis_value
		#Odd bug fix Range is 1-0 but jumps to -1 at most right
		#not sure why it jumps to -1
		#if yaw == -1:
		#	yaw = 0
		#yaw = (yaw * 2) - 1
		
		#print(event.axis_value)
	if event.is_action("pitch"):
		pitch = event.axis_value
	if event.is_action("roll"):
		roll = -event.axis_value
		#print(event)


func figure_damage():
	var damge_vector = last_velocity - linear_velocity
	last_velocity = linear_velocity
	if damge_vector.length() > 5:
		print("Smaked! " + str(damge_vector.length()))
		shake = .3
		draw_power(abs(damge_vector.length()))
		if power_cell > 0:
			shield_sound.play()
		else:
			expload_sound.play()
	#print(power_cell)
	if power_cell < 0:
		print("You are dead!")
		expload_effect.emitting = true
		dead_reset_counter = 2
		dead = true
	if power_cell > 100:
		power_cell = 100


func do_shake(delta):
	if shake > 0:
		var randome_angle = Vector3(randf_range(-180,180),randf_range(-180,180),randf_range(-180,180))
		camera.rotation_degrees = lerp(camera.rotation_degrees, randome_angle, .03 * shake)
		shake -= delta
	elif shake < 0:
		shake = 0
	else:
		if not Input.is_action_pressed("aim"):
			camera.rotation_degrees = lerp(camera.rotation_degrees, og_camera_angle, .03)

func add_wind_push():
	var wind_force = linear_velocity * wind_effect
	apply_impulse(wind_force)

func cooldowns(delta):
	if tp_cooldown > 0:
		tp_cooldown -= delta
	
func update_shield():
	if shield_sound.playing:
		shield.visible = true
		shield_cam.visible = true
	else:
		shield.visible = false
		shield_cam.visible = false

func update_collision_size():
	if linear_velocity.length() > 5:
		speed_collision.shape.radius = collision_size_at_rest * ((linear_velocity.length()/5) + 1)
	else:
		speed_collision.shape.radius = collision_size_at_rest

func add_power(power_to_add):
	if power_cell < 100:
		power_cell += power_to_add
		if power_cell > 100:
			power_to_add = power_cell - 100
			power_cell = 100
		else:
			return
	
	if "extra_power" in inventory:
		var max_extra_power = extra_power_per_upgrade * inventory["extra_power"]
		if extra_power_cell < max_extra_power:
			extra_power_cell += power_to_add
			if extra_power_cell > max_extra_power:
				extra_power_cell = max_extra_power
		else:
			power_cell += power_to_add

func is_paused():
	return(pause_screen.visible)

func draw_power(power_to_draw):
	var power_left_to_draw = power_to_draw
	if extra_power_cell > 0:
		if extra_power_cell >= power_left_to_draw:
			extra_power_cell -= power_left_to_draw
			#print(extra_power_cell)
			return(true)
		else:
			power_left_to_draw -= extra_power_cell
			extra_power_cell = 0
	if power_cell > power_left_to_draw:
		power_cell -= power_left_to_draw
		return(true)
	else:
		power_cell = -1
		return(false)
		

func aim_mode_unhandled_input(event):
	# Remap Yaw/throttle to moving
	if event.is_action("throttle"):
		#print(-event.axis_value)
		pitch = event.axis_value/5
	if event.is_action("yaw"):
		roll = -event.axis_value/5
		#print(event.axis_value)
	#if event.is_action("throttle"):
	#	throttle = -needed_throttle * get_max_throttle()
	#if event.is_action("yaw"):
	#	yaw = -event.axis_value
	#	yaw = -event.axis_value
	if event.is_action("pitch"):
		cam_pitch = event.axis_value
	# remap roll to yaw
	if event.is_action("roll"):
		yaw = -event.axis_value
		yaw = -event.axis_value
		#cam_roll = -event.axis_value



func drone_aim_mode(delta):

	#var needed_throttle = clamp(linear_velocity.y,-.5,.5) * -1
	#throttle = .5 + needed_throttle
	if linear_velocity.y < 0:
		throttle = 1.0
	else:
		throttle = .5
	#var needed_throttle = 2.0 - linear_velocity.y
	throttle = throttle * get_max_throttle()
	#print(throttle)
	apply_impulse(global_transform.basis.y * delta * throttle)
	draw_power(abs(throttle) * delta * power_cost)
	if linear_velocity.length() < 1 and throttle < 1:
		add_power(power_gain_at_rest * delta)
		#var max_extra_power = drone.extra_power_per_upgrade * drone.inventory["extra_power"]
	else:
		add_power(power_gain * delta)

	if abs(yaw) > .01:
		#print(yaw)
		rotate_y(yaw * yaw_speed * delta)
	
	var pitch_change = 0.0
	if abs(pitch) > .01:
		#rotation.x = (pitch * PI)/2
		pitch_change = lerp(rotation.x,  (pitch * PI)/2, delta * 3)
		rotation.x = pitch_change
	else:
		pitch_change = lerp(rotation.x,  0.0, delta * 4)
		rotation.x  = pitch_change
	if abs(roll) > .01:
		#rotation.z = (roll * PI)/2
		rotation.z = lerp(rotation.z,  (roll * PI)/2, delta * 3)
	else:
		rotation.z = lerp(rotation.z, 0.0, delta * 4)
	
	if pitch_change != 0.0:
		camera.rotation.x = -pitch_change
		#camera.rotation.x = lerp(camera.rotation.x,-pitch_change, delta * 50)
	#if abs(cam_pitch) > .01:
	cam_pitch_add += cam_pitch * (yaw_speed/2) * delta
	#camera.rotation.x += cam_pitch_add
	#if Input.is_action_just_pressed("aim"):
	#	cam_pitch_add += rotation.x
	camera.rotate_x(cam_pitch_add)
	camera.rotate_x(cam_inti_rot.x)
	camera.rotate_x(rotation.x)
	if cam_pitch_add > PI * 2:
		cam_pitch_add -= PI * 2
	if -cam_pitch_add > PI * 2:
		cam_pitch_add += PI * 2
	camera.rotation.y = 0.0
	camera.rotation.z = 0.0
	#print(camera.rotation)
	#print(cam_pitch_add)
		#camera.rotation.x = (cam_pitch * PI)/2
	#camera.rotation.x = camera.rotation.x + (1 * delta)

	#if abs(cam_roll) > .01:
	#	camera.rotation.z = (cam_pitch * PI)/2


func drone_physics(delta):
	if Input.is_action_pressed("aim"):
		drone_aim_mode(delta)
		return
	else:
		cam_pitch_add = 0.0
	#print(throttle)
	#print(linear_velocity.y)
	apply_impulse(global_transform.basis.y * delta * throttle)
	#power_cell -= 
	draw_power(abs(throttle) * delta * power_cost)
	if linear_velocity.length() < 1 and throttle < 1:
		add_power(power_gain_at_rest * delta)
		#var max_extra_power = drone.extra_power_per_upgrade * drone.inventory["extra_power"]
	else:
		add_power(power_gain * delta)

	if abs(yaw) > .01:
		#print(yaw)
		rotate_y(yaw * yaw_speed * delta)
		
	if abs(pitch) > .01:
		#rotation.x = (pitch * PI)/2
		rotation.x = lerp(rotation.x,  (pitch * PI)/2, delta * 3)
	else:
		rotation.x = lerp(rotation.x,  0.0, delta * 4)

	if abs(roll) > .01:
		#rotation.z = (roll * PI)/2
		rotation.z = lerp(rotation.z,  (roll * PI)/2, delta * 3)
	else:
		rotation.z = lerp(rotation.z, 0.0, delta * 4)

func update_user_settings():
	
	# Skin
	if "lander_skin" in inventory:
		if inventory["lander_skin"]:
			if not ingenuity_mesh.visible:
				ingenuity_mesh.visible = true
				mesh.visible = false
			return
	if ingenuity_mesh.visible:
		ingenuity_mesh.visible = false
		mesh.visible = true

func update_gun_pos():
	pass
	#var tmp = Quaternion(rotation.x,rotation.x,rotation.x,0)
	#skeleton.set_bone_pose_rotation(skeleton.find_bone("gun"), tmp)

func dead_logic(delta):
	if dead_reset_counter < 0:
		if inventory["crystals"] > 0:
			world.add_crystal_to_world(inventory["crystals"],global_position + Vector3(0,1,0))
		global_position = Vector3(0,0,0)
		inventory["crystals"] = 0
		power_cell = 100
		save_game()
		dead = false
	else:
		dead_reset_counter -= delta
		shield.visible = false
		shield_cam.visible = false
		linear_velocity = Vector3(0,0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if dead:
		dead_logic(delta)
		return
	if is_paused():
		return
	if not tutorial_mode:
		cooldowns(delta)
		do_shake(delta)
		figure_damage()
		update_shield()
	
	update_collision_size()
	add_wind_push()
	drone_physics(delta)
	update_user_settings()
	update_gun_pos()
	

