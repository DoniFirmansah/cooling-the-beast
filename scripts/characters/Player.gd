extends CharacterBody2D
class_name Player

@export var move_speed: float = 190.0
@export var dash_speed_multiplier: float = 1.65

@onready var sprite: Sprite2D = $Sprite2D
@onready var water_particles: CPUParticles2D = $WaterParticles
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer

# Floating Water Indicator above Player
@onready var water_bar: ProgressBar = $WaterIndicator/WaterBar
@onready var water_label: Label = $WaterIndicator/WaterLabel
@onready var objective_guide: Node2D = get_node_or_null("ObjectiveGuide")

# Tutorial & Control Gating Signals
signal tutorial_moved(amount: float)
signal tutorial_sprinted(duration: float)
signal tutorial_water_refilled(amount: float)
signal tutorial_target_sprayed(amount: float)

var can_move: bool = true
var can_dash: bool = true
var can_interact: bool = true
var tutorial_allow_refill_only: bool = false

var nearby_interactables: Array[Node] = []
var current_interactable: Node = null
var facing_direction: Vector2 = Vector2.DOWN
var is_spraying: bool = false
var walk_timer: float = 0.0
var speed_modifier: float = 1.0
var active_slow_sources: int = 0
var occluding_sources_count: int = 0

const SPRITE_BASE_Y: float = -24.0

func add_slow_effect(factor: float = 0.55) -> void:
	active_slow_sources += 1
	speed_modifier = factor

func remove_slow_effect() -> void:
	active_slow_sources = max(0, active_slow_sources - 1)
	if active_slow_sources == 0:
		speed_modifier = 1.0

func set_occluded(active: bool) -> void:
	if active:
		occluding_sources_count += 1
	else:
		occluding_sources_count = max(0, occluding_sources_count - 1)
	_update_occlusion_shader()

func _update_occlusion_shader() -> void:
	if not sprite:
		return
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("is_occluded", occluding_sources_count > 0)


func _ready() -> void:
	add_to_group("player")
	water_particles.emitting = false
	sprite.position.y = SPRITE_BASE_Y
	
	if interaction_detector:
		interaction_detector.area_entered.connect(_on_interaction_area_entered)
		interaction_detector.area_exited.connect(_on_interaction_area_exited)
	
	GameManager.water_changed.connect(_on_water_changed)
	_on_water_changed(GameManager.current_water, GameManager.MAX_WATER)


func _physics_process(delta: float) -> void:
	if not GameManager.is_game_active:
		velocity = Vector2.ZERO
		move_and_slide()
		_clear_target()
		return
	
	_update_best_target()
	_handle_movement(delta)
	_handle_interaction(delta)
	_update_animation_and_bobbing(delta)

func _update_best_target() -> void:
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

func _handle_movement(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
		facing_direction = input_dir
	
	var is_dashing: bool = can_dash and Input.is_action_pressed("dash")
	var current_speed: float = move_speed * speed_modifier
	if is_dashing:
		current_speed *= dash_speed_multiplier
	
	velocity = input_dir * current_speed
	move_and_slide()
	
	if input_dir.length_squared() > 0.0:
		tutorial_moved.emit(velocity.length() * delta)
		if is_dashing:
			tutorial_sprinted.emit(delta)

func _handle_interaction(delta: float) -> void:
	is_spraying = false
	if not can_interact:
		return

	if Input.is_action_pressed("interact"):
		nearby_interactables = nearby_interactables.filter(func(node: Node) -> bool:
			return is_instance_valid(node)
		)
		
		# 1. Prioritaskan isi air jika berada di dekat danau / water source
		var at_water_source: bool = false
		for target in nearby_interactables:
			if target is ReservoirLake or target.is_in_group("water_source") or target is WaterStation:
				at_water_source = true
				if target.has_method("interact_tick"):
					var old_w: float = GameManager.current_water
					target.interact_tick(delta, self)
					var diff: float = GameManager.current_water - old_w
					if diff > 0.0:
						tutorial_water_refilled.emit(diff)
				break
		
		# Jika mode tutorial allow_refill_only aktif, jangan izinkan menyiram non-water source
		if tutorial_allow_refill_only:
			return

		# 2. Jika bukan di sumber air, siram semua target valid (multi-target spraying)
		if not at_water_source:
			var sprayed_any: bool = false
			for target in nearby_interactables:
				if not target.is_in_group("water_source") and target.has_method("interact_tick"):
					var old_w: float = GameManager.current_water
					if target.interact_tick(delta, self):
						sprayed_any = true
						var diff_sprayed: float = old_w - GameManager.current_water
						if diff_sprayed > 0.0:
							tutorial_target_sprayed.emit(diff_sprayed)
			
			if sprayed_any:
				is_spraying = true
	
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

func _update_animation_and_bobbing(delta: float) -> void:
	# Direction frames in player.png:
	# Frame 0: Front (Down)
	# Frame 1: Back (Up)
	# Frame 2: Side Right
	# Frame 3: Side Left
	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x < 0:
			sprite.frame = 3 # Left
		else:
			sprite.frame = 2 # Right
	else:
		if facing_direction.y < 0:
			sprite.frame = 1 # Up (Back view)
		else:
			sprite.frame = 0 # Down (Front view)
	
	# Walking bobbing & squash-and-stretch
	if velocity.length_squared() > 10.0:
		walk_timer += delta * 14.0
		var bob: float = sin(walk_timer) * 1.5
		sprite.position.y = SPRITE_BASE_Y + bob
		sprite.scale.x = 1.0 + sin(walk_timer * 2.0) * 0.05
		sprite.scale.y = 1.0 - sin(walk_timer * 2.0) * 0.05
	else:
		walk_timer = 0.0
		sprite.position.y = SPRITE_BASE_Y
		sprite.scale = Vector2.ONE

func _on_water_changed(current: float, max_amount: float) -> void:
	if water_bar:
		water_bar.max_value = max_amount
		water_bar.value = current
		if current <= 20.0:
			water_bar.modulate = Color(1.0, 0.2, 0.2)
		elif current <= 50.0:
			water_bar.modulate = Color(1.0, 0.8, 0.2)
		else:
			water_bar.modulate = Color(0.2, 0.8, 1.0)
	if water_label:
		water_label.text = "💧%dL" % int(current)

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


