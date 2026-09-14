extends Node2D
class_name LevelManager

@onready var hud: CanvasLayer = $HUD
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var env_modulate: CanvasModulate = $EnvModulate
@onready var background_skyline: Sprite2D = $BackgroundSkyline
@onready var grass_floor: TextureRect = $Floors/GrassFloorAgriDome
@onready var stone_plaza_floor: TextureRect = $Floors/CentralPlaza
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
	
	if hud:
		if hud.has_signal("cutscene_camera_pan"):
			hud.connect("cutscene_camera_pan", Callable(self, "pan_camera_to"))
		if hud.has_signal("cutscene_camera_return"):
			hud.connect("cutscene_camera_return", Callable(self, "return_camera_to_player"))
		if hud.has_signal("cutscene_ended"):
			hud.connect("cutscene_ended", Callable(self, "_on_cutscene_ended"))
	
	if GameManager.current_shift == 1 and not GameManager.prologue_seen:
		GameManager.is_game_active = false
		if hud and hud.has_method("start_prologue_cutscene"):
			get_tree().create_timer(0.2).timeout.connect(func():
				hud.call("start_prologue_cutscene")
			)
	else:
		GameManager.is_game_active = true

func _setup_audio() -> void:
	if bgm_player and bgm_player.stream:
		bgm_player.play()

func _process(delta: float) -> void:
	if strobe_warning_bar and warning_light_bar:
		strobe_timer += delta * strobe_speed
		var flash: float = (sin(strobe_timer) + 1.0) * 0.5
		warning_light_bar.modulate = strobe_color.lerp(Color(0.2, 0.2, 0.25), flash * 0.75)
	
	_update_dynamic_diurnal_lighting(delta)

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_environment(shift_num, true)
	_trigger_shift_transition_effects(shift_num)

func _apply_shift_environment(shift_num: int, animate: bool) -> void:
	var target_sky_color: Color = Color.WHITE
	var target_bg_color: Color = Color.WHITE
	var target_grass_color: Color = Color(0.80, 0.95, 0.78)
	var target_stone_color: Color = Color.WHITE
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
			target_sky_color = Color(1.06, 0.96, 0.88)
			target_bg_color = Color(1.12, 0.96, 0.90)
			target_grass_color = Color(0.82, 0.98, 0.80)
			target_stone_color = Color(1.0, 1.0, 1.0)
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
			target_sky_color = Color(1.08, 0.94, 0.76)
			target_bg_color = Color(1.12, 0.92, 0.70)
			target_grass_color = Color(0.85, 0.74, 0.46)
			target_stone_color = Color(0.92, 0.88, 0.78)
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
			target_sky_color = Color(0.95, 0.50, 0.35)
			target_bg_color = Color(1.0, 0.42, 0.30)
			target_grass_color = Color(0.42, 0.30, 0.22)
			target_stone_color = Color(0.65, 0.48, 0.40)
			strobe_warning_bar = true
			strobe_color = Color(1.0, 0.15, 0.15)
			strobe_speed = 12.0
			emit_embers = true
			ember_amount = 80
			ember_color = Color(1.0, 0.35, 0.1, 0.9)
			leaf_amount = 85
			leaf_color = Color(0.32, 0.20, 0.16, 0.95)
			leaf_gravity = Vector2(100, 50)
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
		if background_skyline:
			tween.tween_property(background_skyline, "modulate", target_bg_color, 2.5)
		if grass_floor:
			tween.tween_property(grass_floor, "modulate", target_grass_color, 2.5)
		if stone_plaza_floor:
			tween.tween_property(stone_plaza_floor, "modulate", target_stone_color, 2.5)
	else:
		if env_modulate:
			env_modulate.color = target_sky_color
		if background_skyline:
			background_skyline.modulate = target_bg_color
		if grass_floor:
			grass_floor.modulate = target_grass_color
		if stone_plaza_floor:
			stone_plaza_floor.modulate = target_stone_color

func _update_dynamic_diurnal_lighting(delta: float) -> void:
	var clock: Dictionary = GameManager.get_clock_info()
	var progress: float = clock.get("progress", 0.0)
	var shift: int = GameManager.current_shift
	
	# Setiap shift berjalan 1 hari penuh dari Pagi (06:00) s/d Malam (21:00).
	# Keyframe: 0.0 (Dawn/Pagi), 0.35 (Noon/Siang), 0.70 (Sunset/Senja), 1.0 (Night/Malam)
	var c_dawn_sky: Color
	var c_dawn_bg: Color
	var c_dawn_grass: Color
	
	var c_noon_sky: Color
	var c_noon_bg: Color
	var c_noon_grass: Color
	
	var c_dusk_sky: Color
	var c_dusk_bg: Color
	var c_dusk_grass: Color
	
	var c_night_sky: Color
	var c_night_bg: Color
	var c_night_grass: Color
	
	match shift:
		1:
			# Hari 1: Lingkungan Alami, Sehat & Sejuk
			c_dawn_sky = Color(1.06, 0.98, 0.90)
			c_dawn_bg = Color(1.10, 0.98, 0.92)
			c_dawn_grass = Color(0.84, 0.98, 0.82)
			
			c_noon_sky = Color(1.0, 1.0, 1.0)
			c_noon_bg = Color(1.0, 1.0, 1.0)
			c_noon_grass = Color(0.80, 0.96, 0.78)
			
			c_dusk_sky = Color(1.08, 0.84, 0.65)
			c_dusk_bg = Color(1.10, 0.82, 0.62)
			c_dusk_grass = Color(0.86, 0.82, 0.60)
			
			c_night_sky = Color(0.55, 0.62, 0.82)
			c_night_bg = Color(0.52, 0.58, 0.78)
			c_night_grass = Color(0.42, 0.52, 0.55)
			
		2:
			# Hari 15: Gelombang Panas Melanda, Kering & Berdebu
			c_dawn_sky = Color(1.06, 0.94, 0.78)
			c_dawn_bg = Color(1.08, 0.92, 0.74)
			c_dawn_grass = Color(0.86, 0.85, 0.62)
			
			c_noon_sky = Color(1.12, 0.95, 0.70)
			c_noon_bg = Color(1.14, 0.92, 0.66)
			c_noon_grass = Color(0.85, 0.74, 0.44)
			
			c_dusk_sky = Color(1.14, 0.72, 0.48)
			c_dusk_bg = Color(1.16, 0.68, 0.42)
			c_dusk_grass = Color(0.72, 0.55, 0.35)
			
			c_night_sky = Color(0.62, 0.45, 0.42)
			c_night_bg = Color(0.60, 0.40, 0.38)
			c_night_grass = Color(0.45, 0.36, 0.28)
			
		3:
			# Hari 30: Puncak Krisis Iklim & Panas Ekstrem (Zero-Sum)
			c_dawn_sky = Color(1.05, 0.65, 0.50)
			c_dawn_bg = Color(1.08, 0.60, 0.45)
			c_dawn_grass = Color(0.58, 0.42, 0.32)
			
			c_noon_sky = Color(1.18, 0.60, 0.36)
			c_noon_bg = Color(1.20, 0.52, 0.30)
			c_noon_grass = Color(0.48, 0.32, 0.22)
			
			c_dusk_sky = Color(0.96, 0.42, 0.28)
			c_dusk_bg = Color(0.98, 0.36, 0.24)
			c_dusk_grass = Color(0.40, 0.26, 0.18)
			
			c_night_sky = Color(0.44, 0.22, 0.20)
			c_night_bg = Color(0.42, 0.18, 0.16)
			c_night_grass = Color(0.28, 0.18, 0.14)
	
	var target_sky: Color
	var target_bg: Color
	var target_grass: Color
	
	if progress <= 0.35:
		var t: float = progress / 0.35
		target_sky = c_dawn_sky.lerp(c_noon_sky, t)
		target_bg = c_dawn_bg.lerp(c_noon_bg, t)
		target_grass = c_dawn_grass.lerp(c_noon_grass, t)
	elif progress <= 0.70:
		var t: float = (progress - 0.35) / 0.35
		target_sky = c_noon_sky.lerp(c_dusk_sky, t)
		target_bg = c_noon_bg.lerp(c_dusk_bg, t)
		target_grass = c_noon_grass.lerp(c_dusk_grass, t)
	else:
		var t: float = (progress - 0.70) / 0.30
		target_sky = c_dusk_sky.lerp(c_night_sky, t)
		target_bg = c_dusk_bg.lerp(c_night_bg, t)
		target_grass = c_dusk_grass.lerp(c_night_grass, t)
	
	if env_modulate:
		env_modulate.color = env_modulate.color.lerp(target_sky, delta * 3.0)
	if background_skyline:
		background_skyline.modulate = background_skyline.modulate.lerp(target_bg, delta * 3.0)
	if grass_floor:
		grass_floor.modulate = grass_floor.modulate.lerp(target_grass, delta * 3.0)
	if stone_plaza_floor:
		var target_stone: Color = Color.WHITE
		match shift:
			1: target_stone = Color(1.0, 1.0, 1.0)
			2: target_stone = Color(0.92, 0.88, 0.78)
			3: target_stone = Color(0.65, 0.48, 0.40)
		stone_plaza_floor.modulate = stone_plaza_floor.modulate.lerp(target_stone, delta * 3.0)


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


# ==============================================================================
# CINEMATIC CAMERA SYSTEM
# ==============================================================================

func pan_camera_to(target_pos: Vector2, duration: float = 1.4) -> void:
	if not player:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if not cam:
		return
	cam.top_level = true
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam, "global_position", target_pos, duration)

func return_camera_to_player(duration: float = 1.0) -> void:
	if not player:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if not cam:
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam, "global_position", player.global_position, duration)
	await tween.finished
	if is_instance_valid(cam):
		cam.top_level = false
		cam.position = Vector2.ZERO

func _on_cutscene_ended() -> void:
	GameManager.prologue_seen = true
	GameManager.is_game_active = true
	return_camera_to_player(0.8)




