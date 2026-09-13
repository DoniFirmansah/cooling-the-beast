extends Node
## GameManager.gd
## Core game loop, hydrological resource balancing, and end-state manager.

signal water_changed(current: float, max_amount: float)
signal food_security_changed(percentage: float)
signal server_integrity_changed(percentage: float)
signal time_tick(seconds_left: int)
signal game_finished(is_victory: bool, reason: String, stats: Dictionary)

const SHIFT_DURATION: float = 90.0
const MAX_WATER: float = 100.0

var current_water: float = 100.0
var food_security: float = 100.0
var server_integrity: float = 100.0
var time_left: float = SHIFT_DURATION
var is_game_active: bool = true

var total_water_used_servers: float = 0.0
var total_water_used_crops: float = 0.0
var servers_failed_count: int = 0
var crops_wilted_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_state()

func reset_state() -> void:
	current_water = MAX_WATER
	food_security = 100.0
	server_integrity = 100.0
	time_left = SHIFT_DURATION
	is_game_active = true
	total_water_used_servers = 0.0
	total_water_used_crops = 0.0
	servers_failed_count = 0
	crops_wilted_count = 0
	get_tree().paused = false

func _process(delta: float) -> void:
	if not is_game_active or get_tree().paused:
		return
	
	time_left -= delta
	if time_left < 0.0:
		time_left = 0.0
	
	time_tick.emit(int(ceil(time_left)))
	
	if time_left <= 0.0:
		_trigger_end_game(true, "Shift Selesai! Keseimbangan Air Berhasil Dijaga.")

func use_water(amount: float, target_type: String) -> bool:
	if current_water <= 0.0:
		return false
	
	var actual_use: float = min(current_water, amount)
	current_water -= actual_use
	
	if target_type == "server":
		total_water_used_servers += actual_use
	elif target_type == "crop":
		total_water_used_crops += actual_use
	
	water_changed.emit(current_water, MAX_WATER)
	return true

func refill_water(amount: float) -> void:
	if current_water >= MAX_WATER:
		return
	current_water = min(MAX_WATER, current_water + amount)
	water_changed.emit(current_water, MAX_WATER)

func damage_server_integrity(amount: float) -> void:
	if not is_game_active:
		return
	server_integrity = max(0.0, server_integrity - amount)
	servers_failed_count += 1
	server_integrity_changed.emit(server_integrity)
	
	if server_integrity <= 0.0:
		_trigger_end_game(false, "Sistem AI Blackout! Data Center Terbakar Akibat Overheat.")

func damage_food_security(amount: float) -> void:
	if not is_game_active:
		return
	food_security = max(0.0, food_security - amount)
	crops_wilted_count += 1
	food_security_changed.emit(food_security)
	
	if food_security <= 0.0:
		_trigger_end_game(false, "Krisis Pangan! Sawah Warga Mengering dan Mati Total.")

func _trigger_end_game(victory: bool, reason: String) -> void:
	if not is_game_active:
		return
	is_game_active = false
	
	var stats: Dictionary = {
		"victory": victory,
		"servers_used_water": total_water_used_servers,
		"crops_used_water": total_water_used_crops,
		"food_security": food_security,
		"server_integrity": server_integrity,
		"servers_failed": servers_failed_count,
		"crops_wilted": crops_wilted_count
	}
	game_finished.emit(victory, reason, stats)

func restart_current_game() -> void:
	reset_state()
	get_tree().paused = false
	get_tree().reload_current_scene()
