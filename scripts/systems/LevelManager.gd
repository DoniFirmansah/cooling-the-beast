extends Node2D
class_name LevelManager

@onready var hud: CanvasLayer = $HUD
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var env_modulate: CanvasModulate = $EnvModulate
@onready var grass_floor: TextureRect = $Floors/GrassFloorAgriDome
@onready var heat_ember_particles: CPUParticles2D = $HeatEmberParticles
@onready var forest_leaf_particles: CPUParticles2D = $ForestLeafParticles
@onready var warning_light_bar: Sprite2D = $YSortEntities/WarningLightBar
@onready var player: CharacterBody2D = $YSortEntities/Player

var strobe_warning_bar: bool = false
var strobe_color: Color = Color.WHITE
var strobe_speed: float = 4.0
var strobe_timer: float = 0.0

func _ready() -> void:
	GameManager.reset_state()
	_setup_audio()
	GameManager.shift_started.connect(_on_shift_started)
	_apply_shift_environment(GameManager.current_shift, false)

func _setup_audio() -> void:
	if bgm_player and bgm_player.stream:
		bgm_player.play()

func _process(delta: float) -> void:
	if strobe_warning_bar and warning_light_bar:
		strobe_timer += delta * strobe_speed
		var flash: float = (sin(strobe_timer) + 1.0) * 0.5
		warning_light_bar.modulate = strobe_color.lerp(Color(0.2, 0.2, 0.25), flash * 0.75)

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_environment(shift_num, true)
	_trigger_shift_transition_effects(shift_num)

func _apply_shift_environment(shift_num: int, animate: bool) -> void:
	var target_sky_color: Color = Color.WHITE
	var target_grass_color: Color = Color(0.80, 0.95, 0.78)
	var emit_embers: bool = false
	var ember_amount: int = 20
	var ember_color: Color = Color(1.0, 0.75, 0.35, 0.45)
	
	var leaf_amount: int = 25
	var leaf_color: Color = Color(0.45, 0.88, 0.38, 0.85)
	var leaf_gravity: Vector2 = Vector2(20, 25)
	var leaf_vel_min: float = 20.0
	var leaf_vel_max: float = 45.0
	
	match shift_num:
		1:
			# Shift 1: Subur, sejuk, asri (Protokol Standar 2049)
			target_sky_color = Color(1.0, 1.0, 1.0)
			target_grass_color = Color(0.80, 0.95, 0.78)
			strobe_warning_bar = false
			if warning_light_bar:
				warning_light_bar.modulate = Color(0.35, 0.85, 1.0)
			emit_embers = false
			
			leaf_amount = 25
			leaf_color = Color(0.45, 0.88, 0.38, 0.85)
			leaf_gravity = Vector2(20, 25)
			leaf_vel_min = 20.0
			leaf_vel_max = 45.0
			
		2:
			# Shift 2: Gelombang panas, kering, dedaunan rontok menguning
			target_sky_color = Color(1.08, 0.94, 0.76)
			target_grass_color = Color(0.85, 0.74, 0.46)
			strobe_warning_bar = true
			strobe_color = Color(1.0, 0.8, 0.25)
			strobe_speed = 5.0
			emit_embers = true
			ember_amount = 25
			ember_color = Color(1.0, 0.75, 0.35, 0.45)
			
			leaf_amount = 55
			leaf_color = Color(0.92, 0.68, 0.24, 0.88)
			leaf_gravity = Vector2(55, 38)
			leaf_vel_min = 35.0
			leaf_vel_max = 70.0
			
		3:
			# Shift 3: Krisis Zero-Sum, langit merah membara, abu/bara api, dedaunan gosong
			target_sky_color = Color(0.95, 0.50, 0.35)
			target_grass_color = Color(0.42, 0.30, 0.22)
			strobe_warning_bar = true
			strobe_color = Color(1.0, 0.15, 0.15)
			strobe_speed = 12.0 # Strobo darurat cepat
			emit_embers = true
			ember_amount = 80
			ember_color = Color(1.0, 0.35, 0.1, 0.9)
			
			leaf_amount = 85
			leaf_color = Color(0.32, 0.20, 0.16, 0.95) # Daun hangus kehitaman
			leaf_gravity = Vector2(100, 50) # Angin kencang
			leaf_vel_min = 60.0
			leaf_vel_max = 120.0
	
	if heat_ember_particles:
		heat_ember_particles.emitting = emit_embers
		heat_ember_particles.amount = ember_amount
		heat_ember_particles.color = ember_color
	
	if forest_leaf_particles:
		forest_leaf_particles.emitting = true
		forest_leaf_particles.amount = leaf_amount
		forest_leaf_particles.color = leaf_color
		forest_leaf_particles.gravity = leaf_gravity
		forest_leaf_particles.initial_velocity_min = leaf_vel_min
		forest_leaf_particles.initial_velocity_max = leaf_vel_max
	
	if animate:
		var tween: Tween = create_tween().set_parallel(true)
		if env_modulate:
			tween.tween_property(env_modulate, "color", target_sky_color, 2.5)
		if grass_floor:
			tween.tween_property(grass_floor, "modulate", target_grass_color, 2.5)
	else:
		if env_modulate:
			env_modulate.color = target_sky_color
		if grass_floor:
			grass_floor.modulate = target_grass_color

func _trigger_shift_transition_effects(shift_num: int) -> void:
	if not player:
		return
	
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if not cam:
		return
	
	if shift_num == 2:
		# Getaran halus gelombang panas
		var shake_tween: Tween = create_tween()
		for i in range(4):
			var shake_offset: Vector2 = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
			shake_tween.tween_property(cam, "offset", shake_offset, 0.08)
		shake_tween.tween_property(cam, "offset", Vector2.ZERO, 0.12)
		
	elif shift_num == 3:
		# Guncangan dramatis aktivasi beban komputasi maksimal AI 2.0T
		var shake_tween: Tween = create_tween()
		for i in range(8):
			var shake_offset: Vector2 = Vector2(randf_range(-5.0, 5.0), randf_range(-4.0, 4.0))
			shake_tween.tween_property(cam, "offset", shake_offset, 0.07)
		shake_tween.tween_property(cam, "offset", Vector2.ZERO, 0.15)




