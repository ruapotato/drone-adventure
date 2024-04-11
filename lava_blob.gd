extends RigidBody3D
@onready var shape = $lava_blob_shape
var drone
var world
var vt
var SPEED = 3
var spawn_pos
var size
# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()
	world = drone.world
	spawn_pos = global_position
	vt = world.find_child("VoxelLodTerrain").get_voxel_tool()
	size = randf_range(1.5,5)
	$lava_blob_shape/CollisionShape3D.shape.radius = size * 2
	$MeshInstance3D.mesh.radius = size
	$MeshInstance3D.mesh.height = size * 2
	#$MeshInstance3D.scale = size/1.5 * Vector3(1,1,1)
	$CollisionShape3D.shape.radius = size

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func grow(delta):
	if global_position.distance_to(spawn_pos) > size * 4:
		if shape.get_overlapping_bodies():
			#vt.grow_sphere(global_position, 3, delta * power)
			vt.mode = VoxelTool.MODE_REMOVE
			#vt.do_sphere(global_position - Vector3(0,3,0), 2)
			vt.do_sphere(global_position, size * 1.5)
	global_position.y += delta * SPEED
	#vt.mode = VoxelTool.MODE_ADD
	#vt.do_sphere(global_position, 1.5)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.y > 0:
		global_position = spawn_pos
	if global_position.distance_to(drone.global_position) < 100:
		
		grow(delta)
