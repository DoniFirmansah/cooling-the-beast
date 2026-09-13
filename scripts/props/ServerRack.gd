extends StaticBody2D
class_name ServerRack

const SFX_ALERT = preload("res://assets/audio/sfx/bong_001.ogg")

@export var rack_id: int = 1
@export var base_heat_rate: float = 4.0
@export var cool_rate: float = 32.0
@export var water_cost_per_sec: float = 14.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var steam_particles: CPUParticles2D = $SteamParticles
@onready var smoke_particles: CPUParticles2D = $SmokeParticles
@onready var fire_particles: CPUParticles2D = $FireParticles
@onready var temp_bar: ProgressBar = $TempBar
@onready var label_temp: Label = $LabelTemp

var temperature: float = 45.0
var is_broken: bool = false
var is_targeted: bool = false
var was_interacted_this_frame: bool = false
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
		steam_particles.emitting = false
		return
	
	# Stop steam if not actively cooled this frame
	if not was_interacted_this_frame:
		steam_particles.emitting = false
	was_interacted_this_frame = false
	
	var shift_progress: float = 1.0 - (GameManager.time_left / GameManager.SHIFT_DURATION)
	var current_heat_rate: float = base_heat_rate * (1.0 + shift_progress * 0.75)
	
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
	
	if is_broken:
		temp_bar.modulate = Color(0.2, 0.2, 0.2)
		if label_temp:
			label_temp.text = "OFFLINE"
			label_temp.modulate = Color(0.6, 0.6, 0.6)
	elif temperature >= 90.0:
		temp_bar.modulate = Color(1.0, 0.1, 0.1)
		if label_temp:
			label_temp.text = "%d°C KRITIS!" % int(temperature)
			label_temp.modulate = Color(1.0, 0.2, 0.2)
	elif temperature >= 75.0:
		temp_bar.modulate = Color(1.0, 0.5, 0.0)
		if label_temp:
			label_temp.text = "%d°C PANAS" % int(temperature)
			label_temp.modulate = Color(1.0, 0.6, 0.1)
	elif temperature >= 60.0:
		temp_bar.modulate = Color(1.0, 0.9, 0.2)
		if label_temp:
			label_temp.text = "%d°C" % int(temperature)
			label_temp.modulate = Color(1.0, 0.9, 0.3)
	else:
		temp_bar.modulate = Color(0.2, 0.8, 1.0)
		if label_temp:
			label_temp.text = "%d°C SEJUK" % int(temperature)
			label_temp.modulate = Color(0.4, 0.9, 1.0)
	
	# Visual highlight when targeted by player
	if is_targeted and not is_broken:
		sprite.modulate = Color(1.3, 1.3, 1.3)
	elif not is_broken:
		sprite.modulate = Color.WHITE

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	_update_ui()

func interact_tick(delta: float, _player: Node) -> bool:
	if is_broken:
		steam_particles.emitting = false
		return false
	
	if temperature <= 32.0:
		steam_particles.emitting = false
		return false
	
	var water_needed: float = water_cost_per_sec * delta
	var has_water: bool = GameManager.use_water(water_needed, "server")
	if not has_water:
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
	sprite.modulate = Color(0.25, 0.25, 0.3)
	smoke_particles.amount = 35
	smoke_particles.emitting = true
	fire_particles.emitting = false
	steam_particles.emitting = false
	_update_ui()
	GameManager.damage_server_integrity(25.0)


