extends Area3D
# Store all spike references
@onready var spikes = {
	"Cone_001": $spikes2/Cone_001,
	"Cone_002": $spikes2/Cone_002,
	"Cone_003": $spikes2/Cone_003,
	"Cone_004": $spikes2/Cone_004,
	"Cone_005": $spikes2/Cone_005,
	"Cone_006": $spikes2/Cone_006,
	"Cone_007": $spikes2/Cone_007,
	"Cone_008": $spikes2/Cone_008,
	"Cone_009": $spikes2/Cone_009
}
var level_loader
var player
var original_material = preload("res://native/spike_tip.tres")
var red_spike_material = preload("res://native/spike_tip_red.tres")

func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")

func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "level_loader":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null

func find_nearest_spike(pos: Vector3) -> MeshInstance3D:
	var nearest = null
	var nearest_dist = INF
	
	for spike in spikes.values():
		var spike_pos = spike.get_node("pos").global_position
		var dist = spike_pos.distance_to(pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = spike
	
	return nearest

func _process(delta: float) -> void:
	if player in get_overlapping_bodies():
		var nearest_spike = find_nearest_spike(player.global_position - Vector3(0,1,0))
		nearest_spike.material_override = red_spike_material
		
		# Calculate knockback direction away from the spike
		var knockback_direction = (player.global_position - nearest_spike.global_position).normalized()
		# Call take_damage with damage amount and knockback direction
		player.take_damage(1, knockback_direction)
