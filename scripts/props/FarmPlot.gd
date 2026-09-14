extends StaticBody2D
class_name FarmPlot

@export var plot_id: int = 1
@export var base_dry_rate: float = 1.8
@export var irrigate_rate: float = 95.0
@export var water_cost_per_sec: float = 6.5


@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var moisture_bar: ProgressBar = $MoistureBar
@onready var label_status: Label = $LabelStatus
@onready var prompt_label: Label = $PromptLabel
@onready var soil_bed: Sprite2D = $SoilBed if has_node("SoilBed") else null

const TEX_MATURE = preload("res://assets/environment/farmland/plot_crop_mature.png")
const TEX_SPROUT = preload("res://assets/environment/farmland/plot_crop_sprout.png")
const TEX_WILTED = preload("res://assets/environment/farmland/plot_crop_wilted.png")
const TEX_DEAD = preload("res://assets/environment/farmland/plot_crop_dead.png")

const TEX_BED_WET = preload("res://assets/environment/farmland/furrow_bed_wet.png")
const TEX_BED_DRY = preload("res://assets/environment/farmland/furrow_bed_dry.png")

var moisture: float = 100.0
var is_dead: bool = false
var is_targeted: bool = false
var was_interacted_this_frame: bool = false
var zero_moisture_timer: float = 0.0
const MAX_ZERO_TIME: float = 12.0

var crop_sprites: Array[Sprite2D] = []

func _ready() -> void:
	add_to_group("farm_plots")
	
	# Detect all crop sprites in this row
	for child in get_children():
		if child is Sprite2D and child.name.begins_with("Crop"):
			crop_sprites.append(child)
	
	splash_particles.emitting = false
	_update_visuals()

func reset_plot_state() -> void:
	is_dead = false
	moisture = 100.0
	is_targeted = false
	was_interacted_this_frame = false
	zero_moisture_timer = 0.0
	if splash_particles:
		splash_particles.emitting = false
	if soil_bed:
		soil_bed.texture = TEX_BED_WET
		soil_bed.modulate = Color.WHITE
	_update_visuals()

func _process(delta: float) -> void:
	if not GameManager.is_game_active or is_dead:
		splash_particles.emitting = false
		return
	
	if not was_interacted_this_frame:
		splash_particles.emitting = false
	was_interacted_this_frame = false
	
	var shift_progress: float = 1.0 - (GameManager.time_left / GameManager.SHIFT_DURATION)
	var cascade_mult: float = GameManager.get_cascading_dry_multiplier()
	var current_dry_rate: float = base_dry_rate * GameManager.get_dry_multiplier() * cascade_mult * (1.0 + shift_progress * 0.5)
	
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
	if prompt_label:
		prompt_label.visible = is_targeted and not is_dead
	
	if moisture_bar:
		moisture_bar.value = moisture
	
	var target_tex: Texture2D = TEX_MATURE
	var target_mod: Color = Color.WHITE
	
	if is_dead:
		target_tex = TEX_DEAD
		target_mod = Color(0.55, 0.5, 0.45)
		if moisture_bar:
			moisture_bar.modulate = Color(0.3, 0.3, 0.3)
		if label_status:
			label_status.text = "ROW #%d: MATI" % plot_id
			label_status.modulate = Color(0.8, 0.2, 0.2)
		if soil_bed:
			soil_bed.texture = TEX_BED_DRY
			soil_bed.modulate = Color(0.65, 0.6, 0.55)
	elif moisture >= 60.0:
		target_tex = TEX_MATURE
		target_mod = Color(1.25, 1.25, 1.25) if is_targeted else Color.WHITE
		if moisture_bar:
			moisture_bar.modulate = Color(0.2, 0.9, 0.3)
		if label_status:
			label_status.text = "ROW #" + str(plot_id) + ": " + str(int(moisture)) + "%"
			label_status.modulate = Color.WHITE
		if soil_bed:
			soil_bed.texture = TEX_BED_WET
			soil_bed.modulate = Color.WHITE
	elif moisture >= 25.0:
		target_tex = TEX_SPROUT
		target_mod = Color(1.25, 1.2, 1.1) if is_targeted else Color(0.95, 0.9, 0.8)
		if moisture_bar:
			moisture_bar.modulate = Color(0.9, 0.8, 0.2)
		if label_status:
			label_status.text = "ROW #" + str(plot_id) + ": " + str(int(moisture)) + "%"
			label_status.modulate = Color(1.0, 0.9, 0.4)
		if soil_bed:
			soil_bed.texture = TEX_BED_DRY
			soil_bed.modulate = Color(1.05, 1.0, 0.95)
	else:
		target_tex = TEX_WILTED
		target_mod = Color(1.2, 1.0, 0.8) if is_targeted else Color(0.85, 0.7, 0.5)
		if moisture_bar:
			moisture_bar.modulate = Color(1.0, 0.3, 0.1)
		if label_status:
			var countdown: int = int(ceil(MAX_ZERO_TIME - zero_moisture_timer))
			if moisture <= 0.0:
				label_status.text = "ROW #" + str(plot_id) + " LAYU! " + str(countdown) + "s"
			else:
				label_status.text = "ROW #" + str(plot_id) + ": " + str(int(moisture)) + "%"
			label_status.modulate = Color(1.0, 0.2, 0.2)

		if soil_bed:
			soil_bed.texture = TEX_BED_DRY
			soil_bed.modulate = Color(1.1, 0.95, 0.85)

	for s in crop_sprites:
		if is_instance_valid(s):
			s.texture = target_tex
			s.modulate = target_mod

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
	if GameManager.cheat_god_mode:
		moisture = 100.0
		zero_moisture_timer = 0.0
		return
	is_dead = true
	moisture = 0.0
	splash_particles.emitting = false
	_update_visuals()
	var plots = get_tree().get_nodes_in_group("farm_plots")
	var count = max(1, plots.size())
	var dmg: float = 100.0 / float(count)
	GameManager.damage_food_security(dmg)
	GameManager.report_crop_death(plot_id)


