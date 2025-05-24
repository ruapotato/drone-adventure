extends VoxelLodTerrain

@onready var Instancer = $VoxelInstancer

var drone
var setup = false


func _ready():
	drone = get_drone()


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func update_color(delta):
	#Broken
	print(drone.global_position.y)
	if drone.global_position.y < 0:
		pass
	#.set("shader_parameter/TopColor") = Color("#007d00")
	#print(material.get_method_list())
	#var color_now = material.get_shader_parameter("TopColor")
	if drone.global_position.y < 0:
		material.set_shader_parameter("TopColor",Color("#007d00"))
		#material.set_shader_parameter("TopColor",color_now.lerp("#007d00", delta))
	else:
		material.set_shader_parameter("TopColor",Color("#ffffff"))
		#material.set_shader_parameter("TopColor",color_now.lerp("#11117d", delta))

	#SetShaderParameter("mesh:material:shader_parameter/TopColor",Color("#007d00"))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#update_color(delta)
	if not setup and drone:
		#stream.database_path = OS.get_user_data_dir() + "/world_" + str(drone.save_index) + ".sql"
		#var test = VoxelInstanceLibrary.new()
		#test.clear()
		#Instancer.library.remove_item()
		#print(stream.database_path)
		setup = true
