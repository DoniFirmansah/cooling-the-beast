extends StaticBody2D
class_name ServerRack

const SFX_ALERT = preload("res://assets/audio/sfx/bong_001.ogg")

@export var rack_id: int = 1
@export var base_heat_rate: float = 4.5
@export var cool_rate: float = 30.0
@export var water_cost_per_sec: float = 15.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var steam_particles: CPUParticles2D = $SteamParticles
@onready var smoke_particles: CPUParticles2D = $SmokeParticles
@onready var fire_particles: CPUParticles2D = $FireParticles
@onready var temp_bar: ProgressBar = $TempBar
@onready var label_temp: Label = $LabelTemp

var temperature: float = 45.0
var is_broken: bool = false
var alert_audio: AudioStreamPlayer2D

func _ready() -> void:
	y_sort_enabled = true
	steam_particles.emitting = false
	smoke_particles.emitting = false
	fire_particles.emitting = false
	
	alert_audio = AudioStreamPlayer2D.new()
	alert_audio.stream = SFX_ALERT
	alert_audio.bus = &"Master"
	add_child(alert_audio)
	
	_update_ui()

func _process(delta: float) -> void:
	if not GameManager.is_game_active or is_broken:
		return
	
	var shift_progress: float = 1.0 - (GameManager.time_left / GameManager.SHIFT_DURATION)
	var current_heat_rate: float = base_heat_rate * (1.0 + shift_progress * 0.8)
	
	temperature = min(100.0, temperature + current_heat_rate * delta)
	_check_temperature_states()
	_update_ui()

func _check_temperature_states() -> void:
	if temperature >= 100.0 and not is_broken:
		_trigger_breakdown()
		return
	
	if temperature >= 75.0:
		smoke_particles.emitting = true
	else:
		smoke_particles.emitting = false
	
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
	if label_temp:
		label_temp.text = "%d°C" % int(temperature)
	
	if is_broken:
		temp_bar.modulate = Color(0.2, 0.2, 0.2)
		if label_temp:
			label_temp.text = "OFFLINE"
	elif temperature >= 90.0:
		temp_bar.modulate = Color(1.0, 0.1, 0.1)
	elif temperature >= 75.0:
		temp_bar.modulate = Color(1.0, 0.5, 0.0)
	elif temperature >= 60.0:
		temp_bar.modulate = Color(1.0, 0.9, 0.2)
	else:
		temp_bar.modulate = Color(0.2, 0.8, 1.0)

func interact_tick(delta: float, _player: Node) -> bool:
	if is_broken:
		return false
	
	if temperature <= 35.0:
		steam_particles.emitting = false
		return false
	
	var water_needed: float = water_cost_per_sec * delta
	var has_water: bool = GameManager.use_water(water_needed, "server")
	if not has_water:
		steam_particles.emitting = false
		return false
	
	temperature = max(30.0, temperature - cool_rate * delta)
	steam_particles.emitting = true
	_update_ui()
	return true

func _trigger_breakdown() -> void:
	is_broken = true
	temperature = 100.0
	sprite.modulate = Color(0.3, 0.3, 0.35)
	smoke_particles.amount = 40
	smoke_particles.emitting = true
	fire_particles.emitting = false
	steam_particles.emitting = false
	_update_ui()
	GameManager.damage_server_integrity(25.0)

