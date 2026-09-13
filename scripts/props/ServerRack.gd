extends StaticBody2D
class_name ServerRack

const SFX_ALERT = preload("res://assets/audio/sfx/bong_001.ogg")
const TEX_CLUSTER_A = preload("res://assets/environment/server_room/server_cluster_a.png")
const TEX_CLUSTER_B = preload("res://assets/environment/server_room/server_cluster_b.png")
const TEX_LEDS_A = preload("res://assets/environment/server_room/server_cluster_a_leds.png")
const TEX_LEDS_B = preload("res://assets/environment/server_room/server_cluster_b_leds.png")

@export_enum("cluster_a", "cluster_b") var rack_variant: String = "cluster_a"
@export var rack_id: int = 1
@export var base_heat_rate: float = 4.0
@export var cool_rate: float = 34.0
@export var water_cost_per_sec: float = 14.0

@onready var cabinet_sprite: Sprite2D = $CabinetSprite
@onready var led_overlay: Sprite2D = $LedOverlay
@onready var steam_particles: CPUParticles2D = $SteamParticles
@onready var smoke_particles: CPUParticles2D = $SmokeParticles
@onready var fire_particles: CPUParticles2D = $FireParticles
@onready var temp_bar: ProgressBar = $ThermalDisplay/TempBar
@onready var label_temp: Label = $ThermalDisplay/LabelTemp
@onready var prompt_badge: Control = $PromptBadge

var temperature: float = 45.0
var is_broken: bool = false
var is_targeted: bool = false
var was_interacted_this_frame: bool = false
var alert_audio: AudioStreamPlayer2D
var led_timer: float = 0.0
var pulse_timer: float = 0.0

func _ready() -> void:
	steam_particles.emitting = false
	smoke_particles.emitting = false
	fire_particles.emitting = false
	
	if cabinet_sprite:
		if rack_variant == "cluster_b":
			cabinet_sprite.texture = TEX_CLUSTER_B
			if led_overlay:
				led_overlay.texture = TEX_LEDS_B
		else:
			cabinet_sprite.texture = TEX_CLUSTER_A
			if led_overlay:
				led_overlay.texture = TEX_LEDS_A
	
	alert_audio = AudioStreamPlayer2D.new()
	alert_audio.stream = SFX_ALERT
	alert_audio.bus = &"Master"
	alert_audio.volume_db = -5.0
	alert_audio.max_distance = 1500.0
	add_child(alert_audio)
	
	_update_ui()

func _process(delta: float) -> void:
	if not GameManager.is_game_active or is_broken:
		steam_particles.emitting = false
		return
	
	if not was_interacted_this_frame:
		steam_particles.emitting = false
	was_interacted_this_frame = false
	
	var shift_progress: float = 1.0 - (GameManager.time_left / GameManager.SHIFT_DURATION)
	var current_heat_rate: float = base_heat_rate * GameManager.get_heat_multiplier() * (1.0 + shift_progress * 0.75)
	
	temperature = min(100.0, temperature + current_heat_rate * delta)
	_check_temperature_states()
	_animate_leds(delta)
	_update_ui()

func _animate_leds(delta: float) -> void:
	if not led_overlay or is_broken:
		if led_overlay:
			led_overlay.visible = false
		return
	
	led_timer += delta
	pulse_timer += delta
	
	var blink_rate: float = 0.3
	if temperature >= 90.0:
		blink_rate = 0.08
	elif temperature >= 75.0:
		blink_rate = 0.16
	
	if led_timer >= blink_rate:
		led_timer = 0.0
		led_overlay.visible = not led_overlay.visible
	
	if temperature >= 90.0:
		led_overlay.modulate = Color(1.0, 0.15, 0.15, 1.0)
		var heat_glow: float = 1.0 + 0.3 * sin(pulse_timer * 12.0)
		cabinet_sprite.modulate = Color(heat_glow, 0.6, 0.6)
	elif temperature >= 75.0:
		led_overlay.modulate = Color(1.0, 0.55, 0.0, 1.0)
		var heat_glow: float = 1.0 + 0.2 * sin(pulse_timer * 6.0)
		cabinet_sprite.modulate = Color(heat_glow, 0.8, 0.7)
	elif temperature >= 60.0:
		led_overlay.modulate = Color(1.0, 0.9, 0.2, 1.0)
		cabinet_sprite.modulate = Color(1.25, 1.25, 1.25) if is_targeted else Color.WHITE
	else:
		led_overlay.modulate = Color(0.3, 0.9, 1.0, 1.0)
		cabinet_sprite.modulate = Color(1.3, 1.3, 1.3) if is_targeted else Color.WHITE

func _check_temperature_states() -> void:
	if temperature >= 100.0 and not is_broken:
		_trigger_breakdown()
		return
	
	smoke_particles.emitting = (temperature >= 75.0)
	
	if temperature >= 90.0:
		fire_particles.emitting = true
		if alert_audio and not alert_audio.playing:
			alert_audio.play()
	else:
		fire_particles.emitting = false

func _update_ui() -> void:
	if not temp_bar:
		return
	
	temp_bar.value = temperature
	
	if is_broken:
		temp_bar.modulate = Color(0.25, 0.25, 0.25)
		if label_temp:
			label_temp.text = "OFFLINE"
			label_temp.modulate = Color(0.6, 0.6, 0.6)
	elif temperature >= 90.0:
		temp_bar.modulate = Color(1.0, 0.15, 0.15)
		if label_temp:
			label_temp.text = "%d°C KRITIS!" % int(temperature)
			label_temp.modulate = Color(1.0, 0.25, 0.25)
	elif temperature >= 75.0:
		temp_bar.modulate = Color(1.0, 0.55, 0.0)
		if label_temp:
			label_temp.text = "%d°C PANAS" % int(temperature)
			label_temp.modulate = Color(1.0, 0.65, 0.1)
	elif temperature >= 60.0:
		temp_bar.modulate = Color(1.0, 0.9, 0.2)
		if label_temp:
			label_temp.text = "%d°C HANGAT" % int(temperature)
			label_temp.modulate = Color(1.0, 0.95, 0.3)
	else:
		temp_bar.modulate = Color(0.2, 0.85, 1.0)
		if label_temp:
			label_temp.text = "%d°C SEJUK" % int(temperature)
			label_temp.modulate = Color(0.4, 0.9, 1.0)
	
	if prompt_badge:
		prompt_badge.visible = is_targeted and not is_broken

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	_update_ui()

func interact_tick(delta: float, _player: Node) -> bool:
	if is_broken or temperature <= 30.0:
		steam_particles.emitting = false
		return false
	
	var water_needed: float = water_cost_per_sec * delta
	if not GameManager.use_water(water_needed, "server"):
		steam_particles.emitting = false
		return false
	
	was_interacted_this_frame = true
	temperature = max(28.0, temperature - cool_rate * delta)
	steam_particles.emitting = true
	_update_ui()
	return true

func _trigger_breakdown() -> void:
	is_broken = true
	temperature = 100.0
	cabinet_sprite.modulate = Color(0.25, 0.25, 0.3)
	if led_overlay:
		led_overlay.visible = false
	smoke_particles.amount = 35
	smoke_particles.emitting = true
	fire_particles.emitting = false
	steam_particles.emitting = false
	_update_ui()
	GameManager.damage_server_integrity(25.0)



