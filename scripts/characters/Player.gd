extends CharacterBody2D
class_name Player

@export var move_speed: float = 145.0
@export var dash_speed_multiplier: float = 1.55

@onready var sprite: Sprite2D = $Sprite2D
@onready var water_particles: CPUParticles2D = $WaterParticles
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer

var nearby_interactables: Array[Node] = []
var current_interactable: Node = null
var facing_direction: Vector2 = Vector2.DOWN
var is_spraying: bool = false
var anim_timer: float = 0.0
var anim_frame: int = 0

func _ready() -> void:
	y_sort_enabled = true
	water_particles.emitting = false
	if interaction_detector:
		interaction_detector.area_entered.connect(_on_interaction_area_entered)
		interaction_detector.area_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if not GameManager.is_game_active:
		velocity = Vector2.ZERO
		move_and_slide()
		_clear_target()
		return
	
	_update_best_target()
	_handle_movement(delta)
	_handle_interaction(delta)
	_update_animation(delta)

func _update_best_target() -> void:
	# Clean up any freed or invalid nodes
	nearby_interactables = nearby_interactables.filter(func(node: Node) -> bool:
		return is_instance_valid(node)
	)
	
	var best_node: Node = null
	var min_distance: float = 999999.0
	
	for target in nearby_interactables:
		var dist: float = global_position.distance_to(target.global_position)
		if dist < min_distance:
			min_distance = dist
			best_node = target
	
	if current_interactable != best_node:
		if current_interactable != null and is_instance_valid(current_interactable):
			if current_interactable.has_method("set_target_highlight"):
				current_interactable.set_target_highlight(false)
		
		current_interactable = best_node
		
		if current_interactable != null and is_instance_valid(current_interactable):
			if current_interactable.has_method("set_target_highlight"):
				current_interactable.set_target_highlight(true)

func _clear_target() -> void:
	if current_interactable != null and is_instance_valid(current_interactable):
		if current_interactable.has_method("set_target_highlight"):
			current_interactable.set_target_highlight(false)
	current_interactable = null
	nearby_interactables.clear()
	is_spraying = false
	water_particles.emitting = false

func _handle_movement(_delta: float) -> void:
	var input_dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
		facing_direction = input_dir
	
	var current_speed: float = move_speed
	if Input.is_action_pressed("dash"):
		current_speed *= dash_speed_multiplier
	
	velocity = input_dir * current_speed
	move_and_slide()

func _handle_interaction(delta: float) -> void:
	is_spraying = false
	
	if Input.is_action_pressed("interact") and current_interactable != null and is_instance_valid(current_interactable):
		if current_interactable.has_method("interact_tick"):
			var success: bool = current_interactable.interact_tick(delta, self)
			# Only emit water particles if spraying server or crop (not refilling water station)
			if success and not (current_interactable is WaterStation):
				is_spraying = true
	
	# Update water particles
	if is_spraying:
		if not water_particles.emitting:
			water_particles.emitting = true
		var spray_dir: Vector2 = facing_direction
		if current_interactable != null and is_instance_valid(current_interactable):
			spray_dir = (current_interactable.global_position - global_position).normalized()
		water_particles.direction = spray_dir
	else:
		if water_particles.emitting:
			water_particles.emitting = false

func _update_animation(delta: float) -> void:
	var row: int = 0
	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x < 0:
			row = 1 # Left
		else:
			row = 2 # Right
	else:
		if facing_direction.y < 0:
			row = 3 # Up
		else:
			row = 0 # Down
	
	if velocity.length_squared() > 10.0:
		anim_timer += delta * 8.0
		if anim_timer >= 1.0:
			anim_timer = 0.0
			anim_frame = (anim_frame + 1) % 4
	else:
		anim_frame = 0
		anim_timer = 0.0
	
	sprite.frame = (row * 4) + anim_frame

func _on_interaction_area_entered(area: Area2D) -> void:
	var parent_node: Node = area.get_parent()
	if parent_node.has_method("interact_tick") and parent_node not in nearby_interactables:
		nearby_interactables.append(parent_node)

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent_node: Node = area.get_parent()
	nearby_interactables.erase(parent_node)
	if current_interactable == parent_node:
		if current_interactable.has_method("set_target_highlight"):
			current_interactable.set_target_highlight(false)
		current_interactable = null
		is_spraying = false
		water_particles.emitting = false

func play_sfx(stream: AudioStream) -> void:
	if sfx_player and stream:
		sfx_player.stream = stream
		sfx_player.play()

