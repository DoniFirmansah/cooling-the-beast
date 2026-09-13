extends Node2D
class_name LevelManager

@onready var hud: CanvasLayer = $HUD
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var env_modulate: CanvasModulate = $EnvModulate
@onready var grass_floor: TextureRect = $Floors/GrassFloorAgriDome
@onready var heat_ember_particles: CPUParticles2D = $HeatEmberParticles

func _ready() -> void:
	GameManager.reset_state()
	_setup_audio()
	GameManager.shift_started.connect(_on_shift_started)
	_apply_shift_environment(GameManager.current_shift, false)

func _setup_audio() -> void:
	if bgm_player and bgm_player.stream:
		bgm_player.play()

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_environment(shift_num, true)

func _apply_shift_environment(shift_num: int, animate: bool) -> void:
	var target_sky_color: Color = Color.WHITE
	var target_grass_color: Color = Color(0.75, 0.85, 0.72)
	var emit_embers: bool = false
	
	match shift_num:
		1:
			# Shift 1: Subur, sejuk, asri
			target_sky_color = Color(1.0, 1.0, 1.0)
			target_grass_color = Color(0.75, 0.85, 0.72)
			emit_embers = false
		2:
			# Shift 2: Mulai mengering, hangat, gersang
			target_sky_color = Color(1.05, 0.95, 0.78)
			target_grass_color = Color(0.85, 0.78, 0.55)
			emit_embers = false
		3:
			# Shift 3: Chaos, krisis air total, langit merah membara, abu/bara api berterbangan
			target_sky_color = Color(0.95, 0.65, 0.45)
			target_grass_color = Color(0.62, 0.46, 0.35)
			emit_embers = true
	
	if heat_ember_particles:
		heat_ember_particles.emitting = emit_embers
	
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



