extends StaticBody2D
class_name ReservoirLake

const SFX_REFILL = preload("res://assets/audio/sfx/switch_001.ogg")
const MAX_DEPTH_METERS: float = 3.5

@export var refill_rate: float = 160.0

@onready var basin_frame: Sprite2D = $BasinFrame
@onready var dry_bed: Sprite2D = $DryBed
@onready var water_container: Node2D = $WaterContainer
@onready var water_surface: Sprite2D = $WaterContainer/WaterSurface
@onready var water_mid: Sprite2D = $WaterContainer/WaterMid
@onready var water_deep: Sprite2D = $WaterContainer/WaterDeep
@onready var wooden_dock: Sprite2D = $WoodenDock
@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $InteractionArea

# Shoreline decorations
@onready var stone1: Sprite2D = $ShoreDecorations/Stone1
@onready var stone2: Sprite2D = $ShoreDecorations/Stone2
@onready var stone3: Sprite2D = $ShoreDecorations/Stone3
@onready var flower1: Sprite2D = $ShoreDecorations/Flower1
@onready var flower2: Sprite2D = $ShoreDecorations/Flower2

var refill_audio: AudioStreamPlayer2D
var is_targeted: bool = false
var was_interacted_this_frame: bool = false
var current_depth_meters: float = 3.5
var wave_time: float = 0.0

# Base tint targets according to current shift
var target_water_surf_col: Color = Color(0.25, 0.88, 1.0, 0.95)
var target_water_mid_col: Color = Color(0.15, 0.55, 0.90, 0.85)
var target_water_deep_col: Color = Color(0.08, 0.35, 0.75, 0.90)
var target_dry_bed_col: Color = Color(0.60, 0.50, 0.42, 0.45)
var target_basin_col: Color = Color(1.0, 1.0, 1.0)
var target_dock_col: Color = Color(1.0, 1.0, 1.0)
var target_stones_col: Color = Color(1.0, 1.0, 1.0)
var target_flowers_col: Color = Color(1.0, 1.0, 1.0)

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
	
	GameManager.shift_started.connect(_on_shift_started)
	_apply_shift_theme(GameManager.current_shift, false)
	_update_water_depth(false)

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_theme(shift_num, true)

func _apply_shift_theme(shift_num: int, animate: bool) -> void:
	match shift_num:
		1:
			target_water_surf_col = Color(0.25, 0.88, 1.0, 0.95)
			target_water_mid_col = Color(0.15, 0.55, 0.90, 0.85)
			target_water_deep_col = Color(0.08, 0.35, 0.75, 0.90)
			target_dry_bed_col = Color(0.60, 0.50, 0.42, 0.40)
			target_basin_col = Color(1.0, 1.0, 1.0)
			target_dock_col = Color(1.0, 1.0, 1.0)
			target_stones_col = Color(1.0, 1.0, 1.0)
			target_flowers_col = Color(1.0, 1.0, 1.0)
			splash_particles.color = Color(0.35, 0.90, 1.0, 0.90)
		2:
			target_water_surf_col = Color(0.32, 0.78, 0.65, 0.90)
			target_water_mid_col = Color(0.20, 0.48, 0.50, 0.75)
			target_water_deep_col = Color(0.12, 0.28, 0.40, 0.50)
			target_dry_bed_col = Color(0.88, 0.78, 0.62, 0.85)
			target_basin_col = Color(0.92, 0.85, 0.75)
			target_dock_col = Color(0.88, 0.80, 0.68)
			target_stones_col = Color(0.88, 0.82, 0.72)
			target_flowers_col = Color(0.85, 0.78, 0.48)
			splash_particles.color = Color(0.40, 0.80, 0.70, 0.85)
		3:
			target_water_surf_col = Color(0.68, 0.38, 0.26, 0.82)
			target_water_mid_col = Color(0.48, 0.25, 0.18, 0.60)
			target_water_deep_col = Color(0.0, 0.0, 0.0, 0.0)
			target_dry_bed_col = Color(1.08, 0.85, 0.75, 1.0)
			target_basin_col = Color(0.68, 0.52, 0.45)
			target_dock_col = Color(0.58, 0.44, 0.36)
			target_stones_col = Color(0.65, 0.52, 0.45)
			target_flowers_col = Color(0.40, 0.28, 0.22)
			splash_particles.color = Color(0.70, 0.45, 0.30, 0.80)
	
	if animate:
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(basin_frame, "modulate", target_basin_col, 2.0)
		if dry_bed: tw.tween_property(dry_bed, "modulate", target_dry_bed_col, 2.0)
		if wooden_dock: tw.tween_property(wooden_dock, "modulate", target_dock_col, 2.0)
		if stone1: tw.tween_property(stone1, "modulate", target_stones_col, 2.0)
		if stone2: tw.tween_property(stone2, "modulate", target_stones_col, 2.0)
		if stone3: tw.tween_property(stone3, "modulate", target_stones_col, 2.0)
		if flower1: tw.tween_property(flower1, "modulate", target_flowers_col, 2.0)
		if flower2: tw.tween_property(flower2, "modulate", target_flowers_col, 2.0)
	else:
		basin_frame.modulate = target_basin_col
		if dry_bed: dry_bed.modulate = target_dry_bed_col
		if wooden_dock: wooden_dock.modulate = target_dock_col
		if stone1: stone1.modulate = target_stones_col
		if stone2: stone2.modulate = target_stones_col
		if stone3: stone3.modulate = target_stones_col
		if flower1: flower1.modulate = target_flowers_col
		if flower2: flower2.modulate = target_flowers_col

func _process(delta: float) -> void:
	wave_time += delta
	_update_water_depth(true)
	
	if not was_interacted_this_frame:
		splash_particles.emitting = false
	was_interacted_this_frame = false
	
	_update_prompt()

func _update_water_depth(_animate: bool) -> void:
	var total_cap: float = GameManager.TOTAL_BASIN_CAPACITY
	var water_ratio: float = clampf(GameManager.reservoir_water / total_cap, 0.0, 1.0)
	current_depth_meters = water_ratio * MAX_DEPTH_METERS
	
	if GameManager.reservoir_water <= 0.0:
		# Danau kering total: dasar retak terhampar seutuhnya
		water_container.visible = false
		if dry_bed:
			dry_bed.visible = true
			dry_bed.modulate = Color(1.15, 0.80, 0.70, 1.0)
		basin_frame.modulate = Color(0.70, 0.52, 0.42)
	else:
		water_container.visible = true
		if dry_bed:
			dry_bed.visible = true
		
		# Denyut gelombang air halus (makin surut, riak makin melemah)
		var wave_strength: float = lerpf(0.006, 0.018, water_ratio)
		var wave_pulse: float = 1.0 + wave_strength * sin(wave_time * 2.2)
		
		# Skala permukaan air non-linear: semakin sedikit air, garis air semakin mundur ke tengah dan memperlihatkan dasar retak
		var surf_scale_x: float = lerpf(0.18, 1.0, pow(water_ratio, 0.75)) * wave_pulse
		var surf_scale_y: float = lerpf(0.18, 1.0, pow(water_ratio, 0.85)) * wave_pulse
		water_surface.scale = Vector2(surf_scale_x, surf_scale_y)
		
		# Gradasi warna permukaan air
		var surf_col: Color = target_water_surf_col
		surf_col.a = clampf(water_ratio * 1.5, 0.45, target_water_surf_col.a)
		water_surface.modulate = surf_col
		
		# Ketinggian air sedikit turun ke arah ceruk tengah saat air menyusut
		var y_offset: float = lerpf(3.5, 0.0, water_ratio)
		water_container.position.y = y_offset
		
		# Lapisan air menengah: aktif pada kedalaman > 0.6m (rasio > 18%)
		if water_ratio > 0.18:
			water_mid.visible = true
			var mid_ratio: float = clampf((water_ratio - 0.18) / 0.82, 0.0, 1.0)
			var mid_scale: float = lerpf(0.18, 1.0, pow(mid_ratio, 0.8))
			water_mid.scale = Vector2(mid_scale, mid_scale)
			var mid_col: Color = target_water_mid_col
			mid_col.a = clampf(mid_ratio * 1.2, 0.0, target_water_mid_col.a)
			water_mid.modulate = mid_col
		else:
			water_mid.visible = false
		
		# Lapisan palung dalam: aktif pada kedalaman > 1.6m (rasio > 45%, otomatis hilang saat Shift 3 krisis)
		if water_ratio > 0.45:
			water_deep.visible = true
			var deep_ratio: float = clampf((water_ratio - 0.45) / 0.55, 0.0, 1.0)
			var deep_scale: float = lerpf(0.20, 1.0, deep_ratio)
			water_deep.scale = Vector2(deep_scale, deep_scale)
			var deep_col: Color = target_water_deep_col
			deep_col.a = clampf(deep_ratio * 1.4, 0.0, target_water_deep_col.a)
			water_deep.modulate = deep_col
		else:
			water_deep.visible = false

func _update_prompt() -> void:
	if prompt_label.visible or is_targeted:
		prompt_label.visible = true
		var water_val: int = int(GameManager.reservoir_water)
		
		if GameManager.reservoir_water <= 0.0:
			prompt_label.text = "⚠️ SUMBER AIR KERING TOTAL!\n(0L / 280L | Kedalaman: 0.0m)"
			prompt_label.modulate = Color(1.0, 0.25, 0.25)
		elif GameManager.current_water >= GameManager.MAX_BACKPACK_WATER:
			prompt_label.text = "TANGKI PENUH\n(Sumber Air: %dL / 280L | Kedalaman: %.1fm)" % [water_val, current_depth_meters]
			prompt_label.modulate = Color(0.4, 1.0, 0.4)
		else:
			var status_hint: String = ""
			if current_depth_meters < 1.0:
				status_hint = " (KRITIS - DASAR RETAK)"
				prompt_label.modulate = Color(1.0, 0.45, 0.2)
			elif current_depth_meters < 2.0:
				status_hint = " (SURUT PARAH)"
				prompt_label.modulate = Color(1.0, 0.70, 0.25)
			elif current_depth_meters < 3.0:
				status_hint = " (SURUT)"
				prompt_label.modulate = Color(1.0, 0.90, 0.35)
			else:
				status_hint = " (MELIMPAH)"
				prompt_label.modulate = Color(0.35, 0.9, 1.0)
			
			prompt_label.text = "[SPASI] AMBIL AIR BERSIH%s\n(Sisa: %dL / 280L | Kedalaman: %.1fm)" % [status_hint, water_val, current_depth_meters]
	else:
		prompt_label.visible = false

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	if is_targeted:
		basin_frame.modulate = target_basin_col * 1.2
	else:
		basin_frame.modulate = target_basin_col

func interact_tick(delta: float, player: Node) -> bool:
	if GameManager.current_water >= GameManager.MAX_BACKPACK_WATER or GameManager.reservoir_water <= 0.0:
		splash_particles.emitting = false
		return false
	
	was_interacted_this_frame = true
	var success: bool = GameManager.refill_water(refill_rate * delta)
	if success:
		splash_particles.emitting = true
		if player != null and is_instance_valid(player) and player is Node2D:
			var p_node: Node2D = player as Node2D
			var dir_to_player: Vector2 = (p_node.global_position - global_position).normalized()
			splash_particles.position = dir_to_player * 24.0
			splash_particles.direction = dir_to_player
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

