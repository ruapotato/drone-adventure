extends RigidBody3D

@onready var nav = $NavigationAgent3D
@onready var collision_shape = $CollisionShape3D
@onready var head = $head
@onready var floorArea = $FloorArea3D

const SPEED = 5.0
const JUMP_linear_velocity = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var player
var drone
var world


var npc_type = "worker"

var active_task
var temper_base = 10
var temper_today = temper_base

var speed_today = SPEED

var npc_home_pos
var npc_work_pos
var npc_school_pos
var npc_bus_pos

var worker_workflow =   {7.0: "leave_for_work",
						17.0: "return_home"}

var todo_today = worker_workflow
#var bed_time =

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()
	drone = get_drone()
	world = player.get_parent()

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))


func is_on_floor():
	var floor = floorArea.has_overlapping_bodies()
	floor = floor and floorArea.has_overlapping_areas()
	return(floor)

func goto(where, delta):
	nav.target_position = where
	
	#look_at(nav.target_position)
	rotation.x = lerp(rotation.x, 0.0, delta * 5)
	rotation.z = lerp(rotation.z, 0.0, delta * 5)
	rotation.y = lerp(rotation.y, head.rotation.y * PI, delta * 5)
	#rotation.z = 0.0
	rotation.y = lerp_angle(rotation.y, atan2(-where.x, -where.z), delta * 18)
	head.look_at(nav.target_position)
	linear_velocity.y = lerp(linear_velocity.y, 0.0, delta)
	
	linear_velocity = global_position.direction_to(nav.get_next_path_position()) * SPEED
	#linear_velocity = linear_velocity.move_toward(nav.get_next_path_position(),delta * SPEED)
	#var direction = nav.get_next_path_position() - global_position
	#direction = direction.normalized()
	#if direction:
	#	linear_velocity.x = direction.x * SPEED
	#	linear_velocity.z = direction.z * SPEED
	#else:
	#	linear_velocity.x = move_toward(linear_velocity.x, 0, SPEED)
	#	linear_velocity.z = move_toward(linear_velocity.z, 0, SPEED)
	
	if global_position.distance_to(where) < 1.0:
		return true
	else:
		return false
	
func be_pissed(delta):
	#Run after drone and jump on it
	nav.target_position = drone.global_position
	
	look_at(nav.target_position)
	rotation.x = 0.0
	rotation.z = 0.0
	head.look_at(nav.target_position)
	
	var direction = nav.get_next_path_position() - global_position
	direction = direction.normalized()
	if direction:
		linear_velocity.x = direction.x * SPEED
		linear_velocity.z = direction.z * SPEED
	else:
		linear_velocity.x = move_toward(linear_velocity.x, 0, SPEED)
		linear_velocity.z = move_toward(linear_velocity.z, 0, SPEED)

func think_damnit():
	var hour_index = world.friendly_time
	if not hour_index:
		return
	if not world.friendly_time_am:
		hour_index += 12
	#print(hour_index)
	
	if hour_index < .2:
		#print("DAY reset")
		if npc_type == "worker":
			todo_today = worker_workflow
	
	for todo_item_time in todo_today:
		if abs(todo_item_time - hour_index) < .2:
			#print("new task")
			active_task = todo_today[todo_item_time]
			#todo_today.erase(todo_item_time)

func hide_npc():
	collision_shape.disabled = true
	linear_velocity = Vector3(0,0,0)
	hide()

func show_npc():
	collision_shape.disabled = false
	show()

func _physics_process(delta):
	if not world.city_running:
		return
	#print(active_task)
	# Add the gravity.
	if not is_on_floor() and not collision_shape.disabled:
		linear_velocity.y -= gravity * delta
		#print("Down")
	
	think_damnit()
	
	if active_task == "pissed":
		be_pissed(delta)
	
	if active_task == "leave_for_work":
		if goto(npc_work_pos, delta):
			hide_npc()
		else:
			show_npc()
	if active_task == "return_home":
		if goto(npc_home_pos, delta):
			hide_npc()
		else:
			show_npc()
	#move_and_slide()


func _on_blocked_area_area_entered(area):
	if is_on_floor() and not collision_shape.disabled:
		linear_velocity.y = JUMP_linear_velocity


func _on_blocked_area_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if is_on_floor() and not collision_shape.disabled:
		linear_velocity.y = JUMP_linear_velocity


