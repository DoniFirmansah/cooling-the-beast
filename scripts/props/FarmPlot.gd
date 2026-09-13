extends StaticBody2D
class_name FarmPlot

@export var plot_id: int = 1
@export var base_dry_rate: float = 3.2
@export var irrigate_rate: float = 38.0
@export var water_cost_per_sec: float = 12.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var moisture_bar: ProgressBar = $MoistureBar
@onready var label_status: Label = $LabelStatus

const TEX_MATURE = preload("res://assets/environment/farmland/plot_crop_mature.png")
const TEX_SPROUT = preload("res://assets/environment/farmland/plot_crop_sprout.png")
const TEX_WILTED = preload("res://assets/environment/farmland/plot_crop_wilted.png")
const TEX_DEAD = preload("res://assets/environment/farmland/plot_dry_32.png")

var moisture: float = 100.0
var is_dead: bool = false
var is_targeted: bool = false
var was_interacted_this_frame: bool = false
var zero_moisture_timer: float = 0.0
const MAX_ZERO_TIME: float = 6.0

func _ready() -> void:
	y_sort_enabled = true
	splash_particles.emitting = false
	_update_visuals()

func _process(delta: float) -> void:
	if not GameManager.is_game_active or is_dead:
		splash_particles.emitting = false
		return
	
	# Stop splash if not actively irrigated this frame
	if not was_interacted_this_frame:
		splash_particles.emitting = false
	was_interacted_this_frame = false
	
	var shift_progress: float = 1.0 - (GameManager.time_left / GameManager.SHIFT_DURATION)
	var current_dry_rate: float = base_dry_rate * (1.0 + shift_progress * 0.7)
	
	moisture = max(0.0, moisture - current_dry_rate * delta)
	
	if moisture <= 0.0:
		zero_moisture_timer += delta
		if zero_moisture_timer >= MAX_ZERO_TIME:
			_trigger_crop_death()
			return
	else:
		zero_moisture_timer = 0.0
	
	_update_visuals()

func _update_visuals() -> void:
	if not moisture_bar:
		return
	
	moisture_bar.value = moisture
	
	if is_dead:
		sprite.texture = TEX_DEAD
		sprite.modulate = Color(0.5, 0.45, 0.4)
		moisture_bar.modulate = Color(0.3, 0.3, 0.3)
		if label_status:
			label_status.text = "MATI"
			label_status.modulate = Color(0.8, 0.2, 0.2)
	elif moisture >= 60.0:
		sprite.texture = TEX_MATURE
		sprite.modulate = Color(1.25, 1.25, 1.25) if is_targeted else Color.WHITE
		moisture_bar.modulate = Color(0.2, 0.9, 0.3)
		if label_status:
			label_status.text = "%d%%" % int(moisture)
			label_status.modulate = Color.WHITE
	elif moisture >= 25.0:
		sprite.texture = TEX_SPROUT
		sprite.modulate = Color(1.25, 1.2, 1.1) if is_targeted else Color(0.95, 0.9, 0.8)
		moisture_bar.modulate = Color(0.9, 0.8, 0.2)
		if label_status:
			label_status.text = "%d%%" % int(moisture)
			label_status.modulate = Color(1.0, 0.9, 0.4)
	else:
		sprite.texture = TEX_WILTED
		sprite.modulate = Color(1.2, 1.0, 0.8) if is_targeted else Color(0.85, 0.7, 0.5)
		moisture_bar.modulate = Color(1.0, 0.3, 0.1)
		if label_status:
			var countdown: int = int(ceil(MAX_ZERO_TIME - zero_moisture_timer))
			if moisture <= 0.0:
				label_status.text = "LAYU! %ds" % countdown
			else:
				label_status.text = "%d%%" % int(moisture)
			label_status.modulate = Color(1.0, 0.2, 0.2)

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	_update_visuals()

func interact_tick(delta: float, _player: Node) -> bool:
	if is_dead:
		splash_particles.emitting = false
		return false
	
	if moisture >= 98.0:
		splash_particles.emitting = false
		return false
	
	var water_needed: float = water_cost_per_sec * delta
	var has_water: bool = GameManager.use_water(water_needed, "crop")
	if not has_water:
		splash_particles.emitting = false
		return false
	
	was_interacted_this_frame = true
	moisture = min(100.0, moisture + irrigate_rate * delta)
	zero_moisture_timer = 0.0
	splash_particles.emitting = true
	_update_visuals()
	return true

func _trigger_crop_death() -> void:
	is_dead = true
	moisture = 0.0
	splash_particles.emitting = false
	_update_visuals()
	GameManager.damage_food_security(25.0)

