extends Node
## GameManager.gd - 3-Shift progression and moral dilemma endings.

signal water_changed(current: float, max_amount: float)
signal reservoir_changed(current: float, max_amount: float)
signal food_security_changed(percentage: float)
signal server_integrity_changed(percentage: float)
signal time_tick(seconds_left: int)
signal shift_started(shift_num: int, shift_title: String)
signal shift_intermission(shift_completed: int, log_title: String, log_desc: String)
signal game_finished(ending_code: String, title: String, narrative: String, stats: Dictionary)

const SHIFT_DURATION: float = 60.0
const MAX_BACKPACK_WATER: float = 120.0
const MAX_WATER: float = MAX_BACKPACK_WATER
const TOTAL_BASIN_CAPACITY: float = 280.0

const TIMELINE_MODE: String = "monthly" # "monthly" (Hari 1, 15, 30), "consecutive" (Hari 1, 2, 3), "seasonal" (Hari 1, 45, 90)

const TIMELINES: Dictionary = {
	"monthly": {
		1: {"day": 1, "day_label": "HARI KE-1", "date": "1 AGUSTUS 2049", "time_jump": "FASE AWAL: PROTOKOL STANDAR"},
		2: {"day": 15, "day_label": "HARI KE-15", "date": "15 AGUSTUS 2049", "time_jump": "+14 HARI BERLALU (2 MINGGU KEMUDIAN)"},
		3: {"day": 30, "day_label": "HARI KE-30", "date": "30 AGUSTUS 2049", "time_jump": "+15 HARI BERLALU (TOTAL 1 BULAN SEJAK AWAL)"}
	},
	"consecutive": {
		1: {"day": 1, "day_label": "HARI KE-1", "date": "SENIN, 1 AGUSTUS 2049", "time_jump": "FASE AWAL: PROTOKOL STANDAR"},
		2: {"day": 2, "day_label": "HARI KE-2", "date": "SELASA, 2 AGUSTUS 2049", "time_jump": "+24 JAM BERLALU (KEESOKAN HARINYA)"},
		3: {"day": 3, "day_label": "HARI KE-3", "date": "RABU, 3 AGUSTUS 2049", "time_jump": "+24 JAM BERLALU (PUNCAK DARURAT HARI KE-3)"}
	},
	"seasonal": {
		1: {"day": 1, "day_label": "HARI KE-1", "date": "BULAN KE-1 (FASE TANAM)", "time_jump": "FASE AWAL: PROTOKOL STANDAR"},
		2: {"day": 45, "day_label": "HARI KE-45", "date": "BULAN KE-2 (FASE PERTUMBUHAN)", "time_jump": "+44 HARI BERLALU (1.5 BULAN KEMUDIAN)"},
		3: {"day": 90, "day_label": "HARI KE-90", "date": "BULAN KE-3 (FASE PANEN RAYA)", "time_jump": "+45 HARI BERLALU (PUNCAK 3 BULAN PENUH)"}
	}
}

const SHIFT_CONFIG: Dictionary = {
	1: {
		"title": "HARI 1: PROTOKOL STANDAR (2049)",
		"reservoir": 280.0,
		"heat_mult": 0.85,
		"dry_mult": 0.85,
		"next_title": "LAPORAN AKHIR HARI KE-1 [AQUA-7]",
		"next_desc": "[STATUS: +14 HARI BERLALU // MEMASUKI HARI KE-15]\nOperasi awal terkendali. Laporan Satelit: Pelatihan model AI 2.0T parameter telah berjalan penuh selama 2 pekan terakhir dan menyedot cadangan air tanah secara masif. Gelombang panas melanda, cadangan danau dipangkas ke 190L!"
	},
	2: {
		"title": "HARI 15: BEBAN KOMPUTASI MASIF",
		"reservoir": 190.0,
		"heat_mult": 1.15,
		"dry_mult": 1.10,
		"next_title": "LAPORAN AKHIR HARI KE-15 [AQUA-7]",
		"next_desc": "[STATUS: +15 HARI BERLALU // MEMASUKI HARI KE-30 (PUNCAK KRISIS)]\nKrisis Ekstrem: Di akhir bulan, gelombang panas mencapai rekor suhu tertinggi. Pipa suplai regional terputus! Kuota sumber air danau darurat HANYA tersisa 110L untuk kedua sektor."
	},
	3: {
		"title": "HARI 30: DILEMA PENGORBANAN (ZERO-SUM)",
		"reservoir": 110.0,
		"heat_mult": 1.45,
		"dry_mult": 1.35,
		"next_title": "",
		"next_desc": ""
	}
}

const SAVE_PATH: String = "user://aqua7_save.json"

var current_shift: int = 1
var saved_shift: int = 1
var unlocked_endings: Dictionary = {}
var current_water: float = 120.0
var reservoir_water: float = 280.0
var max_reservoir_shift: float = 280.0
var food_security: float = 100.0
var server_integrity: float = 100.0
var time_left: float = SHIFT_DURATION
var is_game_active: bool = true
var prologue_seen: bool = false
var total_water_used_servers: float = 0.0
var total_water_used_crops: float = 0.0

# Developer Cheat States
var cheat_god_mode: bool = false
var cheat_fast_time: bool = false
var dev_time_multiplier: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save_file()
	start_new_game()

func load_save_file() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text: String = file.get_as_text()
		var data = JSON.parse_string(text)
		if data is Dictionary:
			if data.has("unlocked_endings") and data["unlocked_endings"] is Dictionary:
				unlocked_endings = data["unlocked_endings"]
			if data.has("saved_shift"):
				saved_shift = int(data["saved_shift"])

func save_game_data() -> void:
	var data: Dictionary = {
		"unlocked_endings": unlocked_endings,
		"saved_shift": current_shift
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func unlock_ending(code: String) -> void:
	unlocked_endings[code] = true
	save_game_data()

func is_ending_unlocked(code: String) -> bool:
	return unlocked_endings.get(code, false)

func start_new_game_from_menu() -> void:
	current_shift = 1
	saved_shift = 1
	food_security = 100.0
	server_integrity = 100.0
	prologue_seen = false
	total_water_used_servers = 0.0
	total_water_used_crops = 0.0
	save_game_data()
	get_tree().change_scene_to_file("res://scenes/levels/MainLevel.tscn")

func start_loaded_game() -> void:
	load_save_file()
	current_shift = saved_shift
	food_security = 100.0
	server_integrity = 100.0
	total_water_used_servers = 0.0
	total_water_used_crops = 0.0
	get_tree().change_scene_to_file("res://scenes/levels/MainLevel.tscn")

func start_new_game() -> void:
	current_shift = 1
	food_security = 100.0
	server_integrity = 100.0
	total_water_used_servers = 0.0
	total_water_used_crops = 0.0
	get_tree().paused = false
	_setup_shift(1)

func reset_state() -> void:
	start_new_game()


func _setup_shift(shift_num: int) -> void:
	current_shift = shift_num
	var cfg: Dictionary = SHIFT_CONFIG.get(shift_num, SHIFT_CONFIG[1])
	max_reservoir_shift = cfg["reservoir"]
	reservoir_water = max_reservoir_shift
	current_water = MAX_BACKPACK_WATER
	time_left = SHIFT_DURATION
	is_game_active = true
	var tree: SceneTree = get_tree()
	if tree:
		tree.paused = false
	
	water_changed.emit(current_water, MAX_BACKPACK_WATER)
	reservoir_changed.emit(reservoir_water, TOTAL_BASIN_CAPACITY)
	food_security_changed.emit(food_security)
	server_integrity_changed.emit(server_integrity)
	shift_started.emit(current_shift, cfg["title"])

func _process(delta: float) -> void:
	if not is_game_active or get_tree().paused:
		return
	time_left = max(0.0, time_left - delta * dev_time_multiplier)
	time_tick.emit(int(ceil(time_left)))
	if time_left <= 0.0:
		_on_shift_timer_expired()

func _on_shift_timer_expired() -> void:
	if current_shift < 3:
		is_game_active = false
		var cfg: Dictionary = SHIFT_CONFIG[current_shift]
		shift_intermission.emit(current_shift, cfg["next_title"], cfg["next_desc"])
	else:
		_evaluate_final_endings()

func advance_to_next_shift() -> void:
	if current_shift < 3:
		_setup_shift(current_shift + 1)

# Developer Cheat & Test Controls
func toggle_cheat_god_mode() -> bool:
	cheat_god_mode = not cheat_god_mode
	if cheat_god_mode:
		server_integrity = 100.0
		food_security = 100.0
		current_water = MAX_BACKPACK_WATER
		server_integrity_changed.emit(server_integrity)
		food_security_changed.emit(food_security)
		water_changed.emit(current_water, MAX_BACKPACK_WATER)
		var tree: SceneTree = get_tree()
		if tree:
			for rack in tree.get_nodes_in_group("server_racks"):
				if is_instance_valid(rack) and rack.has_method("_update_ui"):
					rack.set("temperature", 30.0)
					rack.set("is_broken", false)
					rack.call("_update_ui")
			for plot in tree.get_nodes_in_group("farm_plots"):
				if is_instance_valid(plot) and plot.has_method("_update_visuals"):
					plot.set("moisture", 100.0)
					plot.set("is_dead", false)
					plot.call("_update_visuals")
	return cheat_god_mode

func toggle_cheat_fast_time() -> float:
	if dev_time_multiplier == 1.0:
		dev_time_multiplier = 5.0
		cheat_fast_time = true
	elif dev_time_multiplier == 5.0:
		dev_time_multiplier = 10.0
		cheat_fast_time = true
	else:
		dev_time_multiplier = 1.0
		cheat_fast_time = false
	return dev_time_multiplier

func cheat_finish_shift_instantly() -> void:
	if not is_game_active:
		return
	time_left = 0.2
	time_tick.emit(0)

func get_day_info(shift_num: int = -1) -> Dictionary:
	var s: int = current_shift if shift_num <= 0 else shift_num
	var tl: Dictionary = TIMELINES.get(TIMELINE_MODE, TIMELINES["monthly"])
	return tl.get(s, {"day": s, "day_label": "HARI KE-%d" % s, "date": "2049", "time_jump": ""})

func get_current_day_label() -> String:
	return get_day_info().get("day_label", "HARI KE-1")

func get_current_date_str() -> String:
	return get_day_info().get("date", "2049")

func get_clock_info() -> Dictionary:
	var progress: float = clampf(1.0 - (time_left / SHIFT_DURATION), 0.0, 1.0)
	# Setiap shift dihitung 1 hari penuh dari Pagi (06:00) sampai Malam (21:00)
	var start_hour: float = 6.0
	var end_hour: float = 21.0
	var cur_hour: float = lerpf(start_hour, end_hour, progress)
	
	var period: String = "PAGI"
	if cur_hour >= 18.5:
		period = "MALAM"
	elif cur_hour >= 15.5:
		period = "SENJA"
	elif cur_hour >= 11.0:
		period = "SIANG"
	else:
		period = "PAGI"
	
	var h: int = int(cur_hour)
	var m: int = int((cur_hour - float(h)) * 60.0)
	var time_str: String = "%02d:%02d" % [h, m]
	var day_label: String = get_current_day_label()
	var display_str: String = "%s • %s %s" % [day_label, time_str, period]
	
	return {
		"time_str": time_str,
		"period": period,
		"display": display_str,
		"progress": progress,
		"hour": cur_hour,
		"day_label": day_label
	}

func jump_to_shift(shift_num: int) -> void:
	if shift_num < 1 or shift_num > 3:
		return
	current_shift = shift_num
	food_security = 100.0
	server_integrity = 100.0
	_setup_shift(shift_num)
	var tree: SceneTree = get_tree()
	if tree:
		for rack in tree.get_nodes_in_group("server_racks"):
			if is_instance_valid(rack) and rack.has_method("_update_ui"):
				rack.set("temperature", 30.0)
				rack.set("is_broken", false)
				rack.call("_update_ui")
		for plot in tree.get_nodes_in_group("farm_plots"):
			if is_instance_valid(plot) and plot.has_method("_update_visuals"):
				plot.set("moisture", 100.0)
				plot.set("is_dead", false)
				plot.call("_update_visuals")

func use_water(amount: float, target_type: String) -> bool:
	if cheat_god_mode:
		current_water = MAX_BACKPACK_WATER
		water_changed.emit(current_water, MAX_BACKPACK_WATER)
		if target_type == "server":
			total_water_used_servers += amount
		elif target_type == "crop":
			total_water_used_crops += amount
		return true
	if current_water <= 0.0:
		return false
	var actual: float = min(current_water, amount)
	current_water -= actual
	if target_type == "server":
		total_water_used_servers += actual
	elif target_type == "crop":
		total_water_used_crops += actual
	water_changed.emit(current_water, MAX_BACKPACK_WATER)
	return true

func refill_water(amount: float) -> bool:
	if cheat_god_mode:
		current_water = MAX_BACKPACK_WATER
		water_changed.emit(current_water, MAX_BACKPACK_WATER)
		return true
	if current_water >= MAX_BACKPACK_WATER or reservoir_water <= 0.0:
		return false
	var needed: float = MAX_BACKPACK_WATER - current_water
	var actual: float = min(amount, needed, reservoir_water)
	reservoir_water -= actual
	current_water += actual
	water_changed.emit(current_water, MAX_BACKPACK_WATER)
	reservoir_changed.emit(reservoir_water, TOTAL_BASIN_CAPACITY)
	return true

func get_heat_multiplier() -> float:
	if cheat_god_mode:
		return 0.0
	return SHIFT_CONFIG.get(current_shift, {}).get("heat_mult", 1.0)

func get_dry_multiplier() -> float:
	if cheat_god_mode:
		return 0.0
	return SHIFT_CONFIG.get(current_shift, {}).get("dry_mult", 1.0)

func damage_server_integrity(amount: float) -> void:
	if not is_game_active or cheat_god_mode:
		return
	server_integrity = max(0.0, server_integrity - amount)
	server_integrity_changed.emit(server_integrity)
	_check_early_failure()

func damage_food_security(amount: float) -> void:
	if not is_game_active or cheat_god_mode:
		return
	food_security = max(0.0, food_security - amount)
	food_security_changed.emit(food_security)
	_check_early_failure()

func _check_early_failure() -> void:
	if current_shift < 3:
		if server_integrity <= 0.0:
			_trigger_early_defeat("Sistem AI Blackout! Data Center Terbakar Sebelum Shift Selesai.")
		elif food_security <= 0.0:
			_trigger_early_defeat("Krisis Pangan! Sawah Warga Mati Total Sebelum Shift Selesai.")
	else:
		if server_integrity <= 0.0 and food_security <= 0.0:
			_trigger_early_defeat("Runtuhnya Ekosistem! Seluruh Server dan Tanaman Hancur Total.")

func _trigger_early_defeat(reason: String) -> void:
	is_game_active = false
	unlock_ending("TOTAL_COLLAPSE")
	game_finished.emit("TOTAL_COLLAPSE", "BENCANA EKOLOGI TOTAL", reason, _get_stats())

func _evaluate_final_endings() -> void:
	is_game_active = false
	var stats: Dictionary = _get_stats()
	if food_security >= 35.0 and server_integrity >= 25.0:
		unlock_ending("HARMONY")
		game_finished.emit(
			"HARMONY",
			"ENDING 1/3: KESEIMBANGAN RAPUH (TRUE ENDING)",
			"Melalui kalkulasi presisi mikroliter, Unit AQUA-7 berhasil mempertahankan kedua sektor di tepi jurang kehancuran. Manusia dan kecerdasan buatan bertahan hidup berdampingan. Bukti bahwa teknologi masa depan tidak harus membunuh bumi tempatnya berpijak.",
			stats
		)
	elif food_security > server_integrity:
		unlock_ending("ORGANIC")
		game_finished.emit(
			"ORGANIC",
			"ENDING 2/3: NURANI ORGANIK (PANGAN DISELAMATKAN)",
			"Unit AQUA-7 melanggar direktif korporasi komputasi demi mengalirkan sisa air terakhir ke sawah warga. Model AI gagal dilatih, namun ratusan keluarga petani selamat dari kelaparan. Logika mesin tunduk pada nurani kehidupan.",
			stats
		)
	else:
		unlock_ending("SILICON")
		game_finished.emit(
			"SILICON",
			"ENDING 3/3: GURUN SILIKON (SERVER DISELAMATKAN)",
			"Unit AQUA-7 mematuhi direktif korporasi AI global. Mega server berhasil didinginkan, namun sawah warga mati menjadi debu tandus. AI tercerdas di dunia kini berpikir di atas bumi yang mati kelaparan.",
			stats
		)


func _get_stats() -> Dictionary:
	return {
		"shift": current_shift,
		"servers_used_water": total_water_used_servers,
		"crops_used_water": total_water_used_crops,
		"food_security": food_security,
		"server_integrity": server_integrity
	}

func restart_current_game() -> void:
	start_new_game()
	get_tree().reload_current_scene()

