extends RayCast3D

@onready var mesh = $MeshInstance3D
@onready var laser_effect = $laser_effect

var damage = 100
var time_alive = 0
var ttl = .4
var size = 0
var drone
var max_size = 100
var world
var vt
var dig_radius = 1.5
var strength = 90

# Called when the node enters the scene tree for the first time.
func _ready():
	print("hi")
	drone = get_drone()
	world = drone.world
	$shot.play()
	add_exception(drone)
	mesh.mesh.height = max_size
	mesh.position.z = max_size/2
	vt = world.find_child("VoxelLodTerrain").get_voxel_tool()
	#mesh.material_override("res://native/laser_L1.tres")

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_alive += delta
	var ray_cast_point
	var body = null
	force_raycast_update()
	#print(rotation)
	if is_colliding():
		ray_cast_point = to_local(get_collision_point())
		body = get_collider()
		print(body.name)
		world.hurt(body, damage * delta)
		if body.name == "VoxelLodTerrain":
			world.dirt_vt.mode = VoxelTool.MODE_REMOVE
			world.dirt_vt.grow_sphere(get_collision_point(), dig_radius, strength * delta)
		elif body.name == "VoxelLodTerrain2":
			world.crystal_vt.mode = VoxelTool.MODE_REMOVE
			world.crystal_vt.grow_sphere(get_collision_point(), dig_radius, strength * delta)
		mesh.mesh.height = ray_cast_point.z
		mesh.position.z = ray_cast_point.z/2
		laser_effect.position.z = ray_cast_point.z/2
	else:
		mesh.mesh.height = max_size
		mesh.position.z = max_size/2
		laser_effect.position.z = max_size/2
	


		#rotation = Vector3(0,0,0)
	#rotation = Vector3(-PI/2,PI/2,0)
		#for sig in get_collider().get_signal_list():
		#	if sig.name == "no_damage":
		#		get_collider().emit_signal("no_damage")

		#	if sig.name == "damage_me":
		#		#print("hi")
		#		get_collider().emit_signal("damage_me", damage * delta)
		#		$hit.play()
	
	#scale beem up and down
	#var size = ((int(time_alive * 100) % 30) -15) / 10000.0
	var size_to_be = (time_alive - ttl)/1500.0
	size = lerp(float(size), float(size_to_be), delta * 10)
	mesh.mesh.top_radius = size
	mesh.mesh.bottom_radius = size
	if ttl < time_alive:
		queue_free()
		#print("HIT!")
