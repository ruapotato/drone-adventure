extends RigidBody3D
@onready var shape = $lava_blob_shape
var drone
var world
var SPEED = 3
var spawn_pos
var size
var rest = 4
var eat_speed = 1
var max_size = 20
var min_size = .5
var evaporate = .5
# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()
	world = drone.world
	spawn_pos = global_position
	#vt = world.find_child("VoxelLodTerrain").get_voxel_tool()
	size = randf_range(.5,20)
	set_size(size)

func set_size(new_size):
	if new_size > max_size:
		new_size = max_size
	size = new_size
	if size < min_size:
		queue_free()
	$CollisionShape3D.shape.radius = size
	$lava_blob_shape/CollisionShape3D.shape.radius = size * 1.1
	$MeshInstance3D.mesh.radius = size
	$MeshInstance3D.mesh.height = size * 2
	#$lava_blob_shape/CollisionShape3D.shape.radius = size * 2
	#$MeshInstance3D.scale = size/1.5 * Vector3(1,1,1)
	#$CollisionShape3D.shape.radius = size

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))


func _integrate_forces(state):
	#if SPEED < 0:
	#	if is_equal_approx(linear_velocity.y, 0.0):
	#		SPEED = abs(SPEED)
	linear_velocity.y =  SPEED
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Up and down
	if global_position.distance_to(drone.global_position) < 200:
		if global_position.distance_to(spawn_pos) > size * 4:
			if len(shape.get_overlapping_bodies()) > 1:
				rest -= delta
				if rest < 0:
					SPEED = abs(SPEED) * -1
				else:
					set_size(size - (delta * evaporate))
					#return
		if global_position.y < spawn_pos.y + 1:
			SPEED = abs(SPEED)
			rest = 4
		
		# Eat
		for area in $lava_blob_shape.get_overlapping_areas():
			if area.name == "lava_blob_shape":
				var body = area.get_parent()
				if body.size > size:
					body.set_size(body.size  + eat_speed * delta)
					set_size(size - eat_speed * delta)
				else:
					body.set_size(body.size  - eat_speed * delta)
					set_size(size + eat_speed * delta)

