extends RigidBody3D
@onready var fog = $FogVolume
var fog_colors = ["#FF0000","#FF7F00","#FFFF00","#00FF00","#0000FF","#4B0082","#9400D3"]
var color_index = 0.0
var gee
var ttl = 3
# Called when the node enters the scene tree for the first time.
func _ready():
	gee = get_gee()
	color_index = Time.get_ticks_msec()


func get_gee():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("Gee"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ttl -= delta
	if ttl < 0:
		queue_free()
	color_index += delta * 5
	var wanted_color = Color(fog_colors[int(color_index)%len(fog_colors)])
	#var dist = global_position.distance_to(gee.global_position) 
	# 3000 = volumetric fog length
	#if dist > 3000:
		#fog.visible = false
	#fog.material.albedo = fog.material.albedo.lerp(wanted_color, delta * 10)
	fog.material.emission = fog.material.emission.lerp(wanted_color, delta * 10)
	#fog.material.emission = fog.material.albedo
	#fog.get_active_material(0).albedo_color = fog.get_active_material(0).albedo_color.lerp(wanted_color, delta * 10)
	#fog.get_active_material(0).emission = fog.get_active_material(0).albedo_color
