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

# SFX streams (preloaded)
const SFX_WATER_FILL_STREAM: AudioStream = preload("res://assets/audio/sfx/sfx_water_fill.mp3")
const SFX_WATER_POUR_STREAM: AudioStream = preload("res://assets/audio/sfx/sfx_water_pour.mp3")
const SFX_FOOTSTEP_STREAM: AudioStream  = preload("res://assets/audio/sfx/sfx_footstep.mp3")

# SFX AudioStreamPlayer2D nodes (dibuat di _ready)
var sfx_water_fill: AudioStreamPlayer2D  # loop saat mengambil air dari reservoir
var sfx_water_pour: AudioStreamPlayer2D  # one-shot saat menyemprot / irigasi
var sfx_footstep: AudioStreamPlayer2D    # saat karakter berjalan

# Footstep timing
const FOOTSTEP_INTERVAL: float = 0.42   # jarak antar langkah (detik), sinkron siklus bobbing ~0.45s
var _footstep_timer: float = 0.0
var _is_filling: bool = false            # sedang ambil air dari reservoir
var _pour_cooldown: float = 0.0          # cooldown one-shot pour agar tidak spam

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

	# --- SFX Water Fill (loop saat mengambil air dari reservoir) ---
	sfx_water_fill = AudioStreamPlayer2D.new()
	sfx_water_fill.stream = SFX_WATER_FILL_STREAM
	sfx_water_fill.bus = &"Master"
	sfx_water_fill.volume_db = -6.0
	sfx_water_fill.max_distance = 800.0
	add_child(sfx_water_fill)

	# --- SFX Water Pour (one-shot saat menyemprot / irigasi) ---
	sfx_water_pour = AudioStreamPlayer2D.new()
	sfx_water_pour.stream = SFX_WATER_POUR_STREAM
	sfx_water_pour.bus = &"Master"
	sfx_water_pour.volume_db = -8.0
	sfx_water_pour.max_distance = 600.0
	add_child(sfx_water_pour)

	# --- SFX Footstep (dipicu per interval saat WASD ditekan) ---
	sfx_footstep = AudioStreamPlayer2D.new()
	sfx_footstep.stream = SFX_FOOTSTEP_STREAM
	sfx_footstep.bus = &"Master"
	sfx_footstep.volume_db = -4.0
	sfx_footstep.max_distance = 400.0
	add_child(sfx_footstep)


func _physics_process(delta: float) -> void:
	if not GameManager.is_game_active:
		velocity = Vector2.ZERO
		move_and_slide()
		_clear_target()
		_stop_all_sfx()
		return
	
	_update_best_target()
	_handle_movement(delta)
	_handle_interaction(delta)
	_update_animation_and_bobbing(delta)
	_update_sfx(delta)

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
	_is_filling = false

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
						_is_filling = true

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
		water_label.text = "%dL" % int(current)

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

## Update semua SFX berdasarkan state player saat ini
func _update_sfx(delta: float) -> void:
	# --- SFX Water Fill: loop saat mengambil air ---
	if _is_filling:
		if not sfx_water_fill.playing:
			sfx_water_fill.play()
	else:
		if sfx_water_fill.playing:
			sfx_water_fill.stop()

	# --- SFX Water Pour: one-shot saat menyemprot (dengan cooldown) ---
	_pour_cooldown = max(0.0, _pour_cooldown - delta)
	if is_spraying and _pour_cooldown <= 0.0:
		if not sfx_water_pour.playing:
			sfx_water_pour.play()
			_pour_cooldown = 0.55  # jeda antar trigger ulang
	if not is_spraying:
		if sfx_water_pour.playing:
			sfx_water_pour.stop()

	# --- SFX Footstep: dipicu per langkah berdasarkan input WASD aktif ---
	var input_x: float = Input.get_axis("move_left", "move_right")
	var input_y: float = Input.get_axis("move_up", "move_down")
	var is_moving: bool = can_move and (input_x * input_x + input_y * input_y) > 0.0
	if is_moving:
		_footstep_timer += delta
		if _footstep_timer >= FOOTSTEP_INTERVAL:
			_footstep_timer = 0.0
			if not sfx_footstep.playing:
				sfx_footstep.pitch_scale = randf_range(0.92, 1.08)
				sfx_footstep.play()
	else:
		_footstep_timer = 0.0

## Hentikan semua SFX gameplay saat game tidak aktif
func _stop_all_sfx() -> void:
	if sfx_water_fill and sfx_water_fill.playing:
		sfx_water_fill.stop()
	if sfx_water_pour and sfx_water_pour.playing:
		sfx_water_pour.stop()
	if sfx_footstep and sfx_footstep.playing:
		sfx_footstep.stop()


func play_sfx(stream: AudioStream) -> void:
	if sfx_player and stream:
		sfx_player.stream = stream
		sfx_player.play()


