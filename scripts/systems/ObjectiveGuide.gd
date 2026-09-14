extends Node2D
class_name ObjectiveGuide

signal objective_changed(data: Dictionary)

@export var orbit_radius: float = 46.0

var current_target: Node2D = null
var current_title: String = "AMBIL AIR BERSIH"
var current_subtext: String = "Isi tangki robot di Danau Tengah"
var current_icon: String = "💧"
var current_color: Color = Color(0.2, 0.9, 1.0)
var current_distance: float = 0.0
var is_near_target: bool = false
var urgency_level: int = 1
var pulse_time: float = 0.0

var update_interval: float = 0.15
var update_timer: float = 0.0

func _ready() -> void:
	add_to_group("objective_guide")
	z_index = 20
	z_as_relative = true
	_evaluate_objective()

func _process(delta: float) -> void:
	pulse_time += delta
	update_timer += delta
	
	if update_timer >= update_interval:
		update_timer = 0.0
		_evaluate_objective()
	
	if current_target != null and is_instance_valid(current_target):
		var target_pos: Vector2 = current_target.global_position
		var to_target: Vector2 = target_pos - global_position
		current_distance = to_target.length()
		is_near_target = (current_distance <= 55.0)
		
		if to_target.length_squared() > 1.0:
			var target_angle: float = to_target.angle()
			rotation = lerp_angle(rotation, target_angle, delta * 14.0)
	
func _evaluate_objective() -> void:
	if not GameManager.is_game_active:
		current_target = null
		_emit_hud_update()
		return
	
	var water_source: Node2D = null
	var lake_nodes: Array[Node] = get_tree().get_nodes_in_group("water_source")
	if not lake_nodes.is_empty() and is_instance_valid(lake_nodes[0]):
		water_source = lake_nodes[0] as Node2D
	
	var server_nodes: Array[Node] = get_tree().get_nodes_in_group("server_racks")
	var crop_nodes: Array[Node] = get_tree().get_nodes_in_group("farm_plots")
	
	var hottest_server: ServerRack = null
	var max_temp: float = -999.0
	for node in server_nodes:
		if is_instance_valid(node) and node is ServerRack:
			var s: ServerRack = node as ServerRack
			if not s.is_broken and s.temperature > max_temp:
				max_temp = s.temperature
				hottest_server = s
	
	var driest_crop: FarmPlot = null
	var min_moisture: float = 999.0
	for node in crop_nodes:
		if is_instance_valid(node) and node is FarmPlot:
			var c: FarmPlot = node as FarmPlot
			if not c.is_dead and c.moisture < min_moisture:
				min_moisture = c.moisture
				driest_crop = c
	
	# Priority 1: Tangki air robot kosong / kritis (< 20L)
	if GameManager.current_water < 20.0 and GameManager.reservoir_water > 0.0 and water_source != null:
		current_target = water_source
		current_icon = "💧"
		current_title = "AMBIL AIR BERSIH [SPASI]"
		current_subtext = "Tangki robot hampir habis (%dL)! Ambil air di Danau" % int(GameManager.current_water)
		current_color = Color(0.15, 0.9, 1.0)
		urgency_level = 3
	
	# Priority 2: Server Overheat Kritis (>= 75°C) & punya air
	elif GameManager.current_water >= 8.0 and hottest_server != null and max_temp >= 75.0:
		current_target = hottest_server
		current_icon = "🔥"
		current_title = "SERVER OVERHEAT! (%d°C)" % int(max_temp)
		current_subtext = "Sektor Barat: Dinginkan Server #%d [SPASI]" % hottest_server.rack_id
		current_color = Color(1.0, 0.25, 0.2)
		urgency_level = 3
	
	# Priority 3: Tanaman Sawah Kering Kritis (<= 30%) & punya air
	elif GameManager.current_water >= 8.0 and driest_crop != null and min_moisture <= 30.0:
		current_target = driest_crop
		current_icon = "🥀"
		current_title = "SAWAH KERING! (" + str(int(min_moisture)) + "%)"
		current_subtext = "Sektor Timur: Siram Tanaman #%d [SPASI]" % driest_crop.plot_id
		current_color = Color(1.0, 0.75, 0.15)
		urgency_level = 3
	
	# Priority 4: Normal tutorial / perawatan rutin
	elif GameManager.current_water < 60.0 and GameManager.reservoir_water > 0.0 and water_source != null:
		current_target = water_source
		current_icon = "💧"
		current_title = "CADANGAN AIR: ISI TANGKI"
		current_subtext = "Isi air di Danau Tengah untuk putaran berikutnya"
		current_color = Color(0.3, 0.85, 1.0)
		urgency_level = 1
	else:
		if hottest_server != null and max_temp >= 52.0:
			current_target = hottest_server
			current_icon = "❄️"
			current_title = "DINGINKAN SERVER #%d (%d°C)" % [hottest_server.rack_id, int(max_temp)]
			current_subtext = "Sektor Barat: Cegah akumulasi panas data center"
			current_color = Color(0.35, 0.85, 1.0)
			urgency_level = 1
		elif driest_crop != null and min_moisture < 85.0:
			current_target = driest_crop
			current_icon = "🌱"
			current_title = "SIRAM SAWAH #" + str(driest_crop.plot_id) + " (" + str(int(min_moisture)) + "%)"
			current_subtext = "Sektor Timur: Jaga kelembapan pangan warga"
			current_color = Color(0.35, 0.95, 0.35)
			urgency_level = 1

		else:
			current_target = hottest_server if hottest_server != null else water_source
			current_icon = "✨"
			current_title = "KONDISI STABIL"
			current_subtext = "Kedua sektor dalam parameter normal."
			current_color = Color(0.4, 0.9, 0.7)
			urgency_level = 0
	
	_emit_hud_update()

func _emit_hud_update() -> void:
	var dir_arrow: String = "►"
	if current_target != null and is_instance_valid(current_target):
		var diff: Vector2 = current_target.global_position - global_position
		if abs(diff.x) > abs(diff.y):
			dir_arrow = "◄" if diff.x < 0 else "►"
		else:
			dir_arrow = "▲" if diff.y < 0 else "▼"
	
	var data: Dictionary = {
		"target": current_target,
		"title": current_title,
		"subtext": current_subtext,
		"icon": current_icon,
		"color": current_color,
		"distance": current_distance,
		"is_near": is_near_target,
		"urgency": urgency_level,
		"dir_arrow": dir_arrow
	}
	objective_changed.emit(data)

func _draw() -> void:
	if current_target == null or not is_instance_valid(current_target) or not GameManager.is_game_active:
		return
	
	var pulse: float = sin(pulse_time * 6.0)
	var glow_alpha: float = 0.75 + 0.25 * pulse
	
	if is_near_target:
		var ring_color: Color = Color(0.2, 1.0, 0.4, glow_alpha)
		var ring_r: float = 24.0 + pulse * 3.0
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, ring_color, 2.0, true)
	else:
		var bob_radius: float = orbit_radius + pulse * 4.0
		var arrow_pos: Vector2 = Vector2(bob_radius, 0.0)
		
		var shadow_points: PackedVector2Array = [
			arrow_pos + Vector2(16, 0),
			arrow_pos + Vector2(-6, -11),
			arrow_pos + Vector2(-2, 0),
			arrow_pos + Vector2(-6, 11)
		]
		draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.6))
		
		var outline_color: Color = Color.WHITE
		if urgency_level >= 3:
			outline_color = Color(1.0, 0.95, 0.4)
		draw_polyline(shadow_points, outline_color, 1.5, true)
		
		var inner_color: Color = Color(current_color.r, current_color.g, current_color.b, glow_alpha)
		var inner_points: PackedVector2Array = [
			arrow_pos + Vector2(14, 0),
			arrow_pos + Vector2(-5, -8),
			arrow_pos + Vector2(-1, 0),
			arrow_pos + Vector2(-5, 8)
		]
		draw_colored_polygon(inner_points, inner_color)
		
		var trail_points: PackedVector2Array = [
			arrow_pos + Vector2(-8, 0),
			arrow_pos + Vector2(-14, -5),
			arrow_pos + Vector2(-11, 0),
			arrow_pos + Vector2(-14, 5)
		]
		draw_colored_polygon(trail_points, Color(inner_color.r, inner_color.g, inner_color.b, 0.6))

	queue_redraw()
