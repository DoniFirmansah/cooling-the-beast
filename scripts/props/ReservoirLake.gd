extends StaticBody2D
class_name ReservoirLake

const SFX_REFILL = preload("res://assets/audio/sfx/switch_001.ogg")
const MAX_DEPTH_METERS: float = 3.5

@export var refill_rate: float = 70.0

@onready var basin_frame: Sprite2D = $BasinFrame
@onready var water_container: Node2D = $WaterContainer
@onready var water_surface: Sprite2D = $WaterContainer/WaterSurface
@onready var water_mid: Sprite2D = $WaterContainer/WaterMid
@onready var water_deep: Sprite2D = $WaterContainer/WaterDeep
@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $InteractionArea

var refill_audio: AudioStreamPlayer2D
var is_targeted: bool = false
var was_interacted_this_frame: bool = false
var current_depth_meters: float = 3.5
var wave_time: float = 0.0

func _ready() -> void:
	add_to_group("water_source")
	splash_particles.emitting = false
	prompt_label.visible = false
	
	refill_audio = AudioStreamPlayer2D.new()
	refill_audio.stream = SFX_REFILL
	refill_audio.bus = &"Master"
	add_child(refill_audio)
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	_update_water_depth(false)

func _process(delta: float) -> void:
	wave_time += delta
	_update_water_depth(true)
	
	if not was_interacted_this_frame:
		splash_particles.emitting = false
	was_interacted_this_frame = false
	
	_update_prompt()

func _update_water_depth(_animate: bool) -> void:
	var max_res: float = maxf(GameManager.max_reservoir_shift, 1.0)
	var water_ratio: float = clampf(GameManager.reservoir_water / max_res, 0.0, 1.0)
	current_depth_meters = water_ratio * MAX_DEPTH_METERS
	
	if GameManager.reservoir_water <= 0.0:
		# Danau kering total: air surut seutuhnya, memperlihatkan dasar retak & tanda 0.0m
		water_container.visible = false
		basin_frame.modulate = Color(0.9, 0.75, 0.65) # Kering kerontang
	else:
		water_container.visible = true
		basin_frame.modulate = Color.WHITE
		
		# Gelombang air halus
		var wave_pulse: float = 1.0 + 0.015 * sin(wave_time * 2.2)
		
		# Permukaan air utama (menyusut bertahap mengikuti volume dan garis kedalaman)
		var surf_scale: float = lerpf(0.38, 1.0, sqrt(water_ratio)) * wave_pulse
		water_surface.scale = Vector2(surf_scale, surf_scale)
		water_surface.modulate.a = clampf(water_ratio * 1.6, 0.35, 1.0)
		
		# Lapisan air menengah: aktif pada kedalaman > 0.8m
		if water_ratio > 0.22:
			water_mid.visible = true
			var mid_ratio: float = clampf((water_ratio - 0.22) / 0.78, 0.0, 1.0)
			var mid_scale: float = lerpf(0.25, 1.0, mid_ratio)
			water_mid.scale = Vector2(mid_scale, mid_scale)
			water_mid.modulate.a = clampf(mid_ratio * 1.3, 0.0, 1.0)
		else:
			water_mid.visible = false
		
		# Lapisan palung dalam: aktif pada kedalaman > 2.0m (air melimpah)
		if water_ratio > 0.55:
			water_deep.visible = true
			var deep_ratio: float = clampf((water_ratio - 0.55) / 0.45, 0.0, 1.0)
			var deep_scale: float = lerpf(0.25, 1.0, deep_ratio)
			water_deep.scale = Vector2(deep_scale, deep_scale)
			water_deep.modulate.a = clampf(deep_ratio * 1.5, 0.0, 1.0)
		else:
			water_deep.visible = false

func _update_prompt() -> void:
	if prompt_label.visible or is_targeted:
		prompt_label.visible = true
		var water_val: int = int(GameManager.reservoir_water)
		
		if GameManager.reservoir_water <= 0.0:
			prompt_label.text = "⚠️ DANAU KERING TOTAL!\n(0L | Kedalaman: 0.0m)"
			prompt_label.modulate = Color(1.0, 0.25, 0.25)
		elif GameManager.current_water >= GameManager.MAX_BACKPACK_WATER:
			prompt_label.text = "TANGKI PENUH\n(Danau: %dL | Kedalaman: %.1fm)" % [water_val, current_depth_meters]
			prompt_label.modulate = Color(0.4, 1.0, 0.4)
		else:
			if current_depth_meters < 1.0:
				prompt_label.text = "[SPASI] TIMBA AIR (KRITIS)\n(Danau: %dL | Kedalaman: %.1fm)" % [water_val, current_depth_meters]
				prompt_label.modulate = Color(1.0, 0.65, 0.2)
			else:
				prompt_label.text = "[SPASI] TIMBA AIR DANAU\n(Danau: %dL | Kedalaman: %.1fm)" % [water_val, current_depth_meters]
				prompt_label.modulate = Color(0.35, 0.9, 1.0)
	else:
		prompt_label.visible = false

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	if is_targeted:
		basin_frame.modulate = Color(1.2, 1.2, 1.2)
	else:
		basin_frame.modulate = Color.WHITE

func interact_tick(delta: float, _player: Node) -> bool:
	if GameManager.current_water >= GameManager.MAX_BACKPACK_WATER or GameManager.reservoir_water <= 0.0:
		splash_particles.emitting = false
		return false
	
	was_interacted_this_frame = true
	var success: bool = GameManager.refill_water(refill_rate * delta)
	if success:
		splash_particles.emitting = true
		if refill_audio and not refill_audio.playing:
			refill_audio.play()
		return true
	else:
		splash_particles.emitting = false
		return false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		prompt_label.visible = false
		splash_particles.emitting = false

