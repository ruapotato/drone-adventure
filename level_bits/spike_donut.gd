extends Area3D
const WHOLE_SIZE = 3
const PULL_STRENGTH = 1000.0  # Adjust this to control pull force strength
var level_loader
var player

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

func can_hurt():
	# Create temporary positions that ignore Y axis
	var flat_position = global_position
	var flat_player_position = player.global_position
	flat_position.y = 0
	flat_player_position.y = 0
	
	# Compare distance only on X and Z axes
	if flat_position.distance_to(flat_player_position) > WHOLE_SIZE:
		return false
	return true
		
func _process(delta: float) -> void:
	if player in get_overlapping_bodies():
		# Create flat positions for distance check
		var flat_position = global_position
		var flat_player_position = player.global_position
		flat_position.y = 0
		flat_player_position.y = 0
		
		var flat_distance = flat_position.distance_to(flat_player_position)
		
		if flat_distance < WHOLE_SIZE:
			# Calculate direction to center (excluding y component)
			var direction = global_position - player.global_position
			direction.y = 0  # Keep y movement unaffected
			direction = direction.normalized()
			
			# Calculate force strength that decreases as player gets closer
			var force_strength = PULL_STRENGTH * (flat_distance / WHOLE_SIZE)
			
			# Apply the force to the player
			player.apply_central_force(direction * force_strength)
		else:
			player.die()
