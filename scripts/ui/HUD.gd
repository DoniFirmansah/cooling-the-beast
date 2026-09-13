extends CanvasLayer

const SFX_CLICK = preload("res://assets/audio/sfx/click_001.ogg")
const SFX_WIN = preload("res://assets/audio/sfx/confirmation_001.ogg")
const SFX_FAIL = preload("res://assets/audio/sfx/error_001.ogg")

@onready var water_bar: ProgressBar = %WaterBar
@onready var water_label: Label = %WaterLabel
@onready var reservoir_bar: ProgressBar = %ReservoirBar
@onready var reservoir_label: Label = %ReservoirLabel
@onready var shift_label: Label = %ShiftLabel
@onready var timer_label: Label = %TimerLabel
@onready var server_bar: ProgressBar = %ServerBar
@onready var server_label: Label = %ServerLabel
@onready var food_bar: ProgressBar = %FoodBar
@onready var food_label: Label = %FoodLabel

@onready var objective_tracker: PanelContainer = %ObjectiveTracker
@onready var objective_dir: Label = %ObjectiveDir
@onready var objective_icon: Label = %ObjectiveIcon
@onready var objective_title: Label = %ObjectiveTitle
@onready var objective_subtext: Label = %ObjectiveSubtext
@onready var objective_dist: Label = %ObjectiveDist

@onready var intermission_screen: Control = %IntermissionScreen
@onready var shift_log_title: Label = %ShiftLogTitle
@onready var shift_log_desc: Label = %ShiftLogDesc
@onready var btn_next_shift: Button = %BtnNextShift

@onready var end_screen: Control = %EndScreen
@onready var end_title: Label = %EndTitle
@onready var end_reason: Label = %EndReason
@onready var end_stats: Label = %EndStats
@onready var end_moral: Label = %EndMoral
@onready var btn_restart: Button = %BtnRestart
@onready var btn_end_menu: Button = %BtnEndMenu

@onready var pause_screen: Control = %PauseScreen
@onready var btn_resume: Button = %BtnResume
@onready var btn_pause_restart: Button = %BtnPauseRestart
@onready var btn_pause_menu: Button = %BtnPauseMenu

var audio_player: AudioStreamPlayer

var guide_connected: bool = false

func _process(_delta: float) -> void:
	if not guide_connected:
		var guides: Array[Node] = get_tree().get_nodes_in_group("objective_guide")
		if not guides.is_empty() and is_instance_valid(guides[0]):
			var guide: Node = guides[0]
			if guide.has_signal("objective_changed"):
				guide.connect("objective_changed", Callable(self, "_on_objective_changed"))
				guide_connected = true

func _on_objective_changed(data: Dictionary) -> void:
	if not objective_tracker:
		return
	if objective_title:
		objective_title.text = data.get("title", "")
		objective_title.modulate = data.get("color", Color.WHITE)
	if objective_subtext:
		objective_subtext.text = data.get("subtext", "")
	if objective_icon:
		objective_icon.text = data.get("icon", "💧")
	if objective_dir:
		objective_dir.text = data.get("dir_arrow", "►")
		objective_dir.modulate = data.get("color", Color.WHITE)
	if objective_dist:
		var dist_px: float = data.get("distance", 0.0)
		var dist_m: int = int(dist_px / 16.0)
		if data.get("is_near", false):
			objective_dist.text = "[TEKAN SPASI]"
			objective_dist.modulate = Color(0.2, 1.0, 0.4)
		else:
			objective_dist.text = "%dm" % dist_m
			objective_dist.modulate = data.get("color", Color.WHITE)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	end_screen.visible = false
	pause_screen.visible = false
	if intermission_screen:
		intermission_screen.visible = false
	
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = &"Master"
	add_child(audio_player)
	
	GameManager.water_changed.connect(_on_water_changed)
	GameManager.reservoir_changed.connect(_on_reservoir_changed)
	GameManager.food_security_changed.connect(_on_food_security_changed)
	GameManager.server_integrity_changed.connect(_on_server_integrity_changed)
	GameManager.time_tick.connect(_on_time_tick)
	GameManager.shift_started.connect(_on_shift_started)
	GameManager.shift_intermission.connect(_on_shift_intermission)
	GameManager.game_finished.connect(_on_game_finished)
	
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_pause_restart.pressed.connect(_on_restart_pressed)
	if btn_end_menu:
		btn_end_menu.pressed.connect(_on_menu_pressed)
	if btn_pause_menu:
		btn_pause_menu.pressed.connect(_on_menu_pressed)
	if btn_next_shift:
		btn_next_shift.pressed.connect(_on_next_shift_pressed)
	
	_on_water_changed(GameManager.current_water, GameManager.MAX_BACKPACK_WATER)
	_on_reservoir_changed(GameManager.reservoir_water, GameManager.max_reservoir_shift)
	_on_food_security_changed(GameManager.food_security)
	_on_server_integrity_changed(GameManager.server_integrity)
	_on_time_tick(int(GameManager.SHIFT_DURATION))
	_on_shift_started(1, "SHIFT 1: PROTOKOL STANDAR (2049)")


func _play_sfx(stream: AudioStream) -> void:
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not end_screen.visible and not (intermission_screen and intermission_screen.visible):
			_toggle_pause()
	elif event.is_action_pressed("interact"):
		if intermission_screen and intermission_screen.visible:
			_on_next_shift_pressed()

func _toggle_pause() -> void:
	var is_paused: bool = not get_tree().paused
	get_tree().paused = is_paused
	pause_screen.visible = is_paused
	_play_sfx(SFX_CLICK)

func _on_resume_pressed() -> void:
	_play_sfx(SFX_CLICK)
	get_tree().paused = false
	pause_screen.visible = false

func _on_restart_pressed() -> void:
	_play_sfx(SFX_CLICK)
	GameManager.restart_current_game()

func _on_menu_pressed() -> void:
	_play_sfx(SFX_CLICK)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_next_shift_pressed() -> void:
	_play_sfx(SFX_CLICK)
	if intermission_screen:
		intermission_screen.visible = false
	GameManager.advance_to_next_shift()

func _on_shift_started(shift_num: int, _shift_title: String) -> void:
	if shift_label:
		shift_label.text = "SHIFT %d/3" % shift_num
	if timer_label:
		timer_label.text = "01:00"

func _on_shift_intermission(shift_completed: int, log_title: String, log_desc: String) -> void:
	_play_sfx(SFX_WIN)
	if intermission_screen:
		intermission_screen.visible = true
	if shift_log_title:
		shift_log_title.text = log_title
	if shift_log_desc:
		shift_log_desc.text = log_desc
	if btn_next_shift:
		btn_next_shift.text = "MULAI SHIFT %d [SPASI]" % (shift_completed + 1)

func _on_water_changed(current: float, max_amount: float) -> void:
	if water_bar:
		water_bar.max_value = max_amount
		water_bar.value = current
	if water_label:
		water_label.text = "%d / %dL" % [int(current), int(max_amount)]
		water_label.modulate = Color(1.0, 0.3, 0.3) if current < 20.0 else Color.WHITE

func _on_reservoir_changed(current: float, max_amount: float) -> void:
	if reservoir_bar:
		reservoir_bar.max_value = max_amount
		reservoir_bar.value = current
	if reservoir_label:
		var depth_m: float = (current / maxf(max_amount, 1.0)) * 3.5
		if current <= 0.0:
			reservoir_label.text = "KERING (0L | 0.0m)"
			reservoir_label.modulate = Color(1.0, 0.2, 0.2)
		elif current < 50.0:
			reservoir_label.text = "%dL (%.1fm)" % [int(current), depth_m]
			reservoir_label.modulate = Color(1.0, 0.7, 0.2)
		else:
			reservoir_label.text = "%dL (%.1fm)" % [int(current), depth_m]
			reservoir_label.modulate = Color(0.3, 0.85, 1.0)

func _on_time_tick(seconds_left: int) -> void:
	if timer_label:
		var mins: int = seconds_left / 60
		var secs: int = seconds_left % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		timer_label.modulate = Color(1.0, 0.2, 0.2) if seconds_left <= 15 else Color.WHITE

func _on_server_integrity_changed(val: float) -> void:
	if server_bar:
		server_bar.value = val
	if server_label:
		server_label.text = "%d%%" % int(val)
		server_label.modulate = Color(1.0, 0.2, 0.2) if val <= 25.0 else Color.WHITE

func _on_food_security_changed(val: float) -> void:
	if food_bar:
		food_bar.value = val
	if food_label:
		food_label.text = "%d%%" % int(val)
		food_label.modulate = Color(1.0, 0.2, 0.2) if val <= 25.0 else Color.WHITE

func _on_game_finished(ending_code: String, title: String, narrative: String, stats: Dictionary) -> void:
	end_screen.visible = true
	if ending_code == "HARMONY":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.3, 1.0, 0.4)
	elif ending_code == "ORGANIC":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.4, 0.9, 0.5)
	elif ending_code == "SILICON":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.3, 0.85, 1.0)
	else:
		_play_sfx(SFX_FAIL)
		end_title.modulate = Color(1.0, 0.2, 0.2)
	
	end_title.text = title
	end_reason.text = narrative
	end_stats.text = (
		"STATISTIK AIR UNIT AQUA-7:\n" +
		"• Air Dingin Terpakai (Mega AI Server): %d Liter\n" % int(stats.get("servers_used_water", 0)) +
		"• Air Bersih Terpakai (Sawah Warga): %d Liter\n" % int(stats.get("crops_used_water", 0)) +
		"• Integritas Server Akhir: %d%%\n" % int(stats.get("server_integrity", 0)) +
		"• Ketahanan Pangan Akhir: %d%%" % int(stats.get("food_security", 0))
	)
	end_moral.text = "Tema Grafika Gametastic 2026: Save the Earth. Setiap tetes air pendingin komputasi di dunia nyata diambil dari hak alam dan kehidupan sekitar. Bisakah manusia dan teknologi tumbuh berdampingan secara bijak?"


