extends RigidBody3D

@onready var bullet = preload("res://scenes/bullet.tscn")
@onready var laser = preload("res://scenes/laser.tscn")
@onready var animation_tree = get_node("chicken_wings/AnimationTree")
@onready var camera = $head_piv/Camera3D
@onready var head_mesh = $head_piv/chicken_head
@onready var head_piv = $head_piv
#@onready var target = $Label3D
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
@onready var weckingball_skin = $weckingball_skin
@onready var legs = $LegsNode
@onready var vox = $head_piv/VoxelViewer
var active = true
var collision_size_at_rest = .075
var laser_obj
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
var og_head_piv_angle
var dead = false
var dead_reset_counter = 0

var throttle = 0.0
@export var ground_detection_ray_length : float = 20.0 # You can adjust this in the Inspector
var _height_from_ground : float = -1.0
var is_walking = false
var walk_when = .2
#var max_throttle = 3.5
var max_throttle = 3.9

var yaw = 0.0
var yaw_to_use = 0.0
var yaw_speed = 3

var pitch = 0.0
var pitch_speed = 5
var cam_pitch = 0.0
var cam_roll = 0.0
var feet_on_ground = false

var roll = 0.0
var roll_speed = 5
var tp_cooldown = 0
var world
var last_velocity = Vector3(0,0,0)
var tutorial_mode = false

var cam_inti_rot
var cam_pitch_add = 0.0
var skeleton
var control_lock_yaw = false
var control_lock_tilt = false
var vt
var joy_stick_speed = 5.0
var landed = false

#var throttle_center = -1.0
var throttle_center = -1.0
# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_parent()
	global_position = world.find_child("spawn").global_position
	skeleton = mesh.find_child("Skeleton3D")
	if get_parent().find_child("is_tutorial"):
		tutorial_mode = true
		inventory = {"crystals":0, "using":"gun"}
	if not tutorial_mode:
		vt = world.find_child("VoxelLodTerrain").get_voxel_tool()
		save_index = get_parent().game_index
		save_file = "user://savegame_" + str(save_index) + ".json"
		inventory = load_save(save_file)
	
	og_head_piv_angle = head_piv.rotation_degrees
	cam_inti_rot = head_piv.rotation




func save_game():
	if not save_file:
		return
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
		save_data["using"] = "gun"
		return(save_data)


func get_throttle():
	#inventory init this really should not be here
	if "throttle_zero_centered" not in inventory:
		inventory["throttle_zero_centered"] = false
	
	
	if inventory["throttle_zero_centered"]:
		throttle_center = 0.0
		return(control_ajust(throttle))
	throttle_center = -1.0
	var corrected_throttle = (((throttle/max_throttle) - throttle_center)/2) * max_throttle
	return(control_ajust(corrected_throttle))

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
	new_bullet.apply_impulse(-head_piv.global_transform.basis.z *  shoot_speed)
	apply_impulse(global_transform.basis.z * .1)
	get_parent().add_child(new_bullet)

func fire_laser():
		if laser_obj == null and  power_cell > fire_cost + 1:
			draw_power(fire_cost)
			laser_obj = laser.instantiate()
			laser_obj.name = "laser"
			head_piv.find_child("drone_gun").add_child(laser_obj)
			#laser_obj.rotate_y(PI/2)
			#laser_obj.rotate_z(PI/2)
			#laser_obj.rotation = head_piv.rotation
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
	new_bullet.apply_impulse(-head_piv.global_transform.basis.z *  shoot_speed)
	apply_impulse(global_transform.basis.z * .1)
	get_parent().add_child(new_bullet)
	
func get_max_throttle():
	var effect = 1 - power_cell/100
	#print(effect)
	return(max_throttle - (effect * 1.9))

func _unhandled_input(event):
	if not active:
		global_position = get_viewport().get_camera_3d().global_position + Vector3(0,10,0)
		return
	if event.is_action_pressed("select_gun"):
		inventory["using"] = "gun"
	if "land_making_gun" in inventory and event.is_action_pressed("select_build"):
		inventory["using"] = "land_making_gun"
	if "laser_gun" in inventory and event.is_action_pressed("select_laser"):
		inventory["using"] = "laser_gun"
	if "weckingball" in inventory and event.is_action_pressed("select_ball"):
		inventory["using"] = "weckingball"
	if is_paused():
		return
	
	#if event.is_action("throttle"):
	#	print(event.value)
	if power_cell > fire_cost + 1:
		if event.is_action_pressed("fire"):
			if inventory["using"] == "gun":
				draw_power(fire_cost)
				fire_normal()
			if inventory["using"] == "land_making_gun":
				draw_power(fire_cost)
				fire_landgun()
			#if inventory["using"] == "laser_gun":
			#	fire_laser()
			#if inventory["using"] == "weckingball":
			#	ball_mode()
	
	# aim mode
	if Input.is_action_pressed("aim"):
		aim_mode_unhandled_input(event)
		return
	if Input.is_action_just_released("aim"):
		#throttle =  get_throttle()
		#print(Input.get_action_strength("throttle"))
	#	throttle = 0.0
		throttle = -event.axis_value * get_max_throttle()

	
	# normal mode
	if event.is_action("throttle"):
		#print(-event.axis_value)
		throttle = -event.axis_value * get_max_throttle()
		#if throttle_center == 0.0:
			#if throttle < - .8:
			#	print("Enabled full axis mode for throttle.")
			#	world.message("Enabled full axis mode for throttle.")
			#	throttle_center = -1.0
		#throttle = get_throttle()
	if event.is_action("yaw"):
		if control_lock_yaw:
			return
		#yaw = -event.axis_value
		#print(event.axis_value)
		yaw = control_ajust(-event.axis_value)
		#Odd bug fix Range is 1-0 but jumps to -1 at most right
		#not sure why it jumps to -1
		#if yaw == -1:
		#	yaw = 0
		#yaw = (yaw * 2) - 1
		
		#print(event.axis_value)
	if control_lock_tilt:
		return
	if event.is_action("pitch"):
		if not is_walking:
			pitch = control_ajust(event.axis_value)
	if event.is_action("roll"):
		roll = control_ajust(-event.axis_value)
	
	if is_walking:
		pitch = -get_throttle() /15
		#print(event)

func control_ajust(value):
	#print(value)
	return((value ** 1/3) * 3)

func figure_damage():
	var damge_vector = last_velocity - linear_velocity
	last_velocity = linear_velocity
	if damge_vector.length() > 4:
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
		head_piv.rotation_degrees = lerp(head_piv.rotation_degrees, randome_angle, .03 * shake)
		shake -= delta
	elif shake < 0:
		shake = 0
	else:
		if not Input.is_action_pressed("aim"):
			head_piv.rotation_degrees = lerp(head_piv.rotation_degrees, og_head_piv_angle, .03)

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
		pitch = event.axis_value/10
	if event.is_action("yaw"):
		roll = -event.axis_value/10
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
		yaw = -event.axis_value/2
		yaw = -event.axis_value/2
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
	if power_cell - 1 > abs(throttle) * delta * power_cost:
		apply_impulse(global_transform.basis.y * delta * throttle)
		draw_power(abs(throttle) * delta * power_cost)

	
		
	if abs(yaw) > .01:
		rotate_y((yaw/50) * (joy_stick_speed + world.control_sensitivity_effector))
	
	var pitch_change = 0.0
	if abs(pitch) > .01:
		#rotation.x = (pitch * PI)/2
		pitch_change = lerp(rotation.x,  (pitch * PI)/2, delta * (joy_stick_speed + world.control_sensitivity_effector))
		rotation.x = pitch_change
	else:
		pitch_change = lerp(rotation.x,  0.0, delta * 5)
		rotation.x  = pitch_change
	if abs(roll) > .01:
		#rotation.z = (roll * PI)/2
		rotation.z = lerp(rotation.z,  (roll * PI)/2, delta * (joy_stick_speed + world.control_sensitivity_effector))
	else:
		rotation.z = lerp(rotation.z, 0.0, delta * 5)
	
	if pitch_change != 0.0:
		head_piv.rotation.x = -pitch_change
		#head_piv.rotation.x = lerp(head_piv.rotation.x,-pitch_change, delta * 50)
	#if abs(cam_pitch) > .01:
	cam_pitch_add += cam_pitch * delta * (joy_stick_speed + world.control_sensitivity_effector) * .5
	#head_piv.rotation.x += cam_pitch_add
	#if Input.is_action_just_pressed("aim"):
	#	cam_pitch_add += rotation.x
	head_piv.rotate_x(cam_pitch_add)
	head_piv.rotate_x(cam_inti_rot.x)
	head_piv.rotate_x(rotation.x)
	if cam_pitch_add > PI * 2:
		cam_pitch_add -= PI * 2
	if -cam_pitch_add > PI * 2:
		cam_pitch_add += PI * 2
	head_piv.rotation.y = 0.0
	head_piv.rotation.z = 0.0
	#print(head_piv.rotation)
	#print(cam_pitch_add)
		#head_piv.rotation.x = (cam_pitch * PI)/2
	#head_piv.rotation.x = head_piv.rotation.x + (1 * delta)

	#if abs(cam_roll) > .01:
	#	head_piv.rotation.z = (cam_pitch * PI)/2

func on_ground():
	if linear_velocity.length() < 1 and throttle < 1:
		return(true)
	return(feet_on_ground)

func ball_mode(delta):
	vt.mode = VoxelTool.MODE_REMOVE
	vt.grow_sphere(global_position,  linear_velocity.length()/20, delta * clamp(linear_velocity.length(),1,60))
	mass = 1000
	weckingball_skin.visible = true
	if $drone_sound.playing:
		$drone_sound.stop()
	
func drone_physics(delta):
	
	# laser_gun
	if inventory["using"] == "laser_gun" and Input.is_action_pressed("fire"):
		fire_laser()
	
	if Input.is_action_pressed("aim"):
		#print("Aim mode")
		drone_aim_mode(delta)
		return
	else:
		cam_pitch_add = 0.0
	
	# weckingball mode
	if inventory["using"] == "weckingball" and Input.is_action_pressed("fire"):
		draw_power(delta)
		ball_mode(delta)
		return
	else:
		if weckingball_skin.visible:
			mass = 0.22
			weckingball_skin.visible = false
			$drone_sound.play()
	
	#print("Normal mode")
	#print(throttle)
	#print(linear_velocity.y)
	if power_cell - 1 > abs(get_throttle()) * delta * power_cost:
		apply_impulse(global_transform.basis.y * delta * get_throttle())
		draw_power(abs(get_throttle()) * delta * power_cost)
	if on_ground():
		add_power(power_gain_at_rest * delta)
		landed = true
		#var max_extra_power = drone.extra_power_per_upgrade * drone.inventory["extra_power"]
	else:
		add_power(power_gain * delta)
		landed = false


	if landed:
		animation_tree.set("parameters/SPEED/scale", 0)
	else:
		animation_tree.set("parameters/SPEED/scale", get_throttle() * 15)

	if yaw != 0.0:
		#print(yaw)
		yaw_to_use = lerp(yaw_to_use, (yaw * yaw_speed * delta), delta*(joy_stick_speed + world.control_sensitivity_effector))
	else:
		yaw_to_use = lerp(yaw_to_use, 0.0,delta*5)
	if yaw_to_use != 0.0:
		rotate_y(yaw_to_use)
		
	if abs(pitch) > .01:
		#rotation.x = (pitch * PI)/2
		rotation.x = lerp(rotation.x,  (pitch * PI)/2, delta * (joy_stick_speed + world.control_sensitivity_effector))
	else:
		rotation.x = lerp(rotation.x,  0.0, delta * 4)

	if abs(roll) > .01:
		#rotation.z = (roll * PI)/2
		rotation.z = lerp(rotation.z,  (roll * PI)/2, delta * (joy_stick_speed + world.control_sensitivity_effector))
	else:
		#rotation.z = lerp(rotation.z, 0.0, delta * 4)
		rotation.z = lerp(rotation.z, 0.0, delta * (joy_stick_speed + world.control_sensitivity_effector))

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
		global_position = world.spawn.global_position
		inventory["crystals"] = 0
		power_cell = 100
		save_game()
		dead = false
	else:
		dead_reset_counter -= delta
		shield.visible = false
		shield_cam.visible = false
		linear_velocity = Vector3(0,0,0)

func ground_check(delta):
	var space_state = get_world_3d().direct_space_state
	if space_state: # Check if space_state is valid
		var query_parameters = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * ground_detection_ray_length) # Use new var name
		query_parameters.exclude = [self] # Exclude the drone itself
		# For the ray to hit anything, the drone's 'collision_mask' must include the layer of the ground.
		# And the ground's 'collision_layer' must be set.
		query_parameters.collision_mask = self.collision_mask # Use drone's own mask, or set a specific one for ground.
		var ray_cast_result_dict = space_state.intersect_ray(query_parameters) # Use new var name
		_height_from_ground = -1.0 # Default to -1 (no ground hit / out of range)
		if ray_cast_result_dict: # Check if the dictionary is not empty (i.e., ray hit something)
			_height_from_ground = global_position.distance_to(ray_cast_result_dict.position)
			# print("Current height from ground: ", _height_from_ground) # <<< UNCOMMENT THIS LINE TO SEE THE HEIGHT
		# else: # Optional: If you want to know when the ray specifically misses
			# print("No ground detected by ray within ", ground_detection_ray_length, "m.")
	else:
		print("ERROR: Could not get 3D physics space state for ground raycast.")
		_height_from_ground = -1.0 # Still set to default if space_state is null
	if _height_from_ground < walk_when and _height_from_ground > 0:
		is_walking = true
	else:
		is_walking = false

	
func _keep_head_upright():
	if Input.is_action_pressed("aim"):
		head_mesh.rotation = Vector3(0,0,0)
		return
	# Get the current global rotation (in Euler angles)
	var current_global_rot = head_mesh.global_rotation

	# Set X (pitch) and Z (roll) to zero
	current_global_rot.x = 0.0
	current_global_rot.z = 0.0
	current_global_rot.y = rotation.y

	# Apply the modified rotation back.
	# The 'y' rotation remains whatever it was, but x and z are forced to 0.
	head_mesh.global_rotation = current_global_rot
	
func walk(delta):
	if is_walking:
		#rotation.x = 0
		#rotation.y = 0
		legs.animate_legs(delta, linear_velocity.length())
	else:
		legs.animate_legs(delta, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not active:
		return
	_keep_head_upright()
	#print(world.control_sensitivity_effector)
	if dead:
		dead_logic(delta)
		return
	if is_paused():
		return
	if not tutorial_mode:
		cooldowns(delta)
		figure_damage()
		update_shield()
	
	ground_check(delta)
	walk(delta)
	do_shake(delta)
	update_collision_size()
	add_wind_push()
	drone_physics(delta)
	update_user_settings()
	update_gun_pos()
	



func _on_feet_area_area_entered(area):
	if area.name == "ground":
		feet_on_ground = true


func _on_feet_area_area_exited(area):
	if area.name == "ground":
		feet_on_ground = false
