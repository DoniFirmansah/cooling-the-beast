extends CanvasLayer

signal cutscene_camera_pan(target_pos: Vector2, duration: float)
signal cutscene_camera_return(duration: float)
signal cutscene_ended()

const SFX_CLICK = preload("res://assets/audio/sfx/click_001.ogg")
const SFX_WIN = preload("res://assets/audio/sfx/confirmation_001.ogg")
const SFX_FAIL = preload("res://assets/audio/sfx/error_001.ogg")

@onready var top_bar: PanelContainer = $TopBar
@onready var bottom_guide: HBoxContainer = $BottomGuide

@onready var water_bar: ProgressBar = %WaterBar
@onready var water_label: Label = %WaterLabel
@onready var reservoir_bar: ProgressBar = %ReservoirBar
@onready var reservoir_label: Label = %ReservoirLabel
@onready var shift_label: Label = %ShiftLabel
@onready var clock_label: Label = %ClockLabel
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

# Cinematic Cutscene Controls
@onready var cinematic_overlay: Control = %CinematicOverlay
@onready var top_letterbox: ColorRect = %TopLetterbox
@onready var bottom_letterbox: ColorRect = %BottomLetterbox
@onready var btn_skip_cutscene: Button = %BtnSkipCutscene
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var speaker_badge: Label = %SpeakerBadge
@onready var advance_prompt: Label = %AdvancePrompt
@onready var dialogue_text: RichTextLabel = %DialogueText

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

# Dev Cheat Controls
@onready var btn_cheat_god_mode: Button = %BtnCheatGodMode
@onready var btn_cheat_speed: Button = %BtnCheatSpeed
@onready var btn_cheat_finish_shift: Button = %BtnCheatFinishShift
@onready var btn_jump_shift1: Button = %BtnJumpShift1
@onready var btn_jump_shift2: Button = %BtnJumpShift2
@onready var btn_jump_shift3: Button = %BtnJumpShift3

var audio_player: AudioStreamPlayer
var guide_connected: bool = false

# Cutscene Controller State
var is_cutscene_running: bool = false
var current_beat_index: int = 0
var is_typewriting: bool = false
var typewriter_tween: Tween
var prompt_blink_timer: float = 0.0

const PROLOGUE_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "💧 🤖 AQUA-7 // PROTOKOL INTERNAL",
		"speaker_color": Color(0.15, 0.90, 1.0),
		"raw_text": "Inisialisasi sistem hidrolik selesai. Sumber air bersih terdeteksi [b]280 Liter[/b].\n[color=#66e5ff][b][TUTORIAL]:[/b] Berjalanlah ke tepi danau lalu tahan [b][SPASI][/b] untuk menyedot air bersih ke dalam tangki 120L robot.[/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "🔥 🖥️ DEEPBEAST-2.0T // DIRECTIVE ALPHA",
		"speaker_color": Color(1.0, 0.35, 0.25),
		"raw_text": "Peringatan Panas: 4 klaster rak server AI beroperasi pada daya komputasi tinggi.\n[color=#ff8a80][b][TUTORIAL]:[/b] Dekati rak server lalu semprot pendingin dengan [b][SPASI][/b]. Jika suhu menyentuh 90°C, kerusakan chip bersifat permanen![/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "🌱 🌾 PAK MARNO // KETUA TANI AGRI-DOME",
		"speaker_color": Color(0.40, 0.95, 0.45),
		"raw_text": "AQUA-7, dengarkan kami! Sawah ini adalah tumpuan pangan ratusan keluarga warga.\n[color=#8ce99a][b][TUTORIAL]:[/b] Lari melintasi jembatan ke timur. Semprot petak sawah dengan [b][SPASI][/b] agar kelembapan tanah tetap hijau di atas 30%![/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 65), # Karakter AQUA-7
		"speaker_badge": "⚡ ⚙️ STATUS OPERASIONAL // HARI KE-1",
		"speaker_color": Color(1.0, 0.85, 0.30),
		"raw_text": "[color=#ffe066][b][KONTROL]:[/b] [b][WASD][/b] Gerak • Tahan [b][SHIFT][/b] Lari Cepat • [b][SPASI][/b] Siram / Ambil Air.[/color]\nAir sangat terbatas dan beban krisis meningkat di hari-hari berikutnya. Selamat bertugas, Unit AQUA-7!",
		"prompt": "[SPASI] Mulai Operasi 🚀"
	}
]

func _process(delta: float) -> void:
	if is_cutscene_running and advance_prompt and advance_prompt.visible:
		prompt_blink_timer += delta * 4.0
		advance_prompt.modulate.a = 0.45 + 0.55 * ((sin(prompt_blink_timer) + 1.0) * 0.5)
	
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
	if cinematic_overlay:
		cinematic_overlay.visible = false
	if btn_skip_cutscene:
		btn_skip_cutscene.pressed.connect(skip_prologue_cutscene)
	
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
	
	# Connect Dev Cheat Controls
	if btn_cheat_god_mode:
		btn_cheat_god_mode.pressed.connect(_on_cheat_god_mode_pressed)
	if btn_cheat_speed:
		btn_cheat_speed.pressed.connect(_on_cheat_speed_pressed)
	if btn_cheat_finish_shift:
		btn_cheat_finish_shift.pressed.connect(_on_cheat_finish_shift_pressed)
	if btn_jump_shift1:
		btn_jump_shift1.pressed.connect(func(): _on_jump_shift_pressed(1))
	if btn_jump_shift2:
		btn_jump_shift2.pressed.connect(func(): _on_jump_shift_pressed(2))
	if btn_jump_shift3:
		btn_jump_shift3.pressed.connect(func(): _on_jump_shift_pressed(3))
	
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
	if is_cutscene_running:
		if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			skip_prologue_cutscene()
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			_on_cutscene_input_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_cutscene_input_pressed()
			get_viewport().set_input_as_handled()
			return
		return
	
	if event.is_action_pressed("pause"):
		if not end_screen.visible and not (intermission_screen and intermission_screen.visible):
			_toggle_pause()
	elif event.is_action_pressed("interact"):
		if intermission_screen and intermission_screen.visible:
			_on_next_shift_pressed()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_ev: InputEventKey = event as InputEventKey
		match key_ev.keycode:
			KEY_F1:
				_on_cheat_god_mode_pressed()
			KEY_F2:
				_on_cheat_speed_pressed()
			KEY_F3:
				_on_cheat_finish_shift_pressed()
			KEY_F4:
				_on_jump_shift_pressed(1)
			KEY_F5:
				_on_jump_shift_pressed(2)
			KEY_F6:
				_on_jump_shift_pressed(3)
			KEY_F7:
				if not is_cutscene_running:
					get_tree().paused = false
					pause_screen.visible = false
					start_prologue_cutscene()

func _toggle_pause() -> void:
	var is_paused: bool = not get_tree().paused
	get_tree().paused = is_paused
	pause_screen.visible = is_paused
	if is_paused:
		_update_cheat_ui()
	_play_sfx(SFX_CLICK)

func _update_cheat_ui() -> void:
	if btn_cheat_god_mode:
		if GameManager.cheat_god_mode:
			btn_cheat_god_mode.text = "🛡️ KEBAL DURABILITAS: AKTIF (GOD MODE)"
			btn_cheat_god_mode.modulate = Color(0.35, 1.0, 0.5)
		else:
			btn_cheat_god_mode.text = "🛡️ KEBAL DURABILITAS: NONAKTIF"
			btn_cheat_god_mode.modulate = Color.WHITE
	
	if btn_cheat_speed:
		if GameManager.dev_time_multiplier == 1.0:
			btn_cheat_speed.text = "⚡ KECEPATAN WAKTU: 1X (NORMAL)"
			btn_cheat_speed.modulate = Color.WHITE
		elif GameManager.dev_time_multiplier == 5.0:
			btn_cheat_speed.text = "⚡ KECEPATAN WAKTU: 5X (CEPAT)"
			btn_cheat_speed.modulate = Color(1.0, 0.9, 0.3)
		else:
			btn_cheat_speed.text = "⚡ KECEPATAN WAKTU: 10X (ULTRA CEPAT)"
			btn_cheat_speed.modulate = Color(1.0, 0.45, 0.35)

func _on_cheat_god_mode_pressed() -> void:
	_play_sfx(SFX_CLICK)
	GameManager.toggle_cheat_god_mode()
	_update_cheat_ui()

func _on_cheat_speed_pressed() -> void:
	_play_sfx(SFX_CLICK)
	GameManager.toggle_cheat_fast_time()
	_update_cheat_ui()

func _on_cheat_finish_shift_pressed() -> void:
	_play_sfx(SFX_WIN)
	pause_screen.visible = false
	get_tree().paused = false
	GameManager.cheat_finish_shift_instantly()

func _on_jump_shift_pressed(shift_num: int) -> void:
	_play_sfx(SFX_WIN)
	pause_screen.visible = false
	get_tree().paused = false
	GameManager.jump_to_shift(shift_num)

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
		shift_label.text = "%s (SHIFT %d/3)" % [GameManager.get_current_day_label(), shift_num]
	if timer_label:
		timer_label.text = "01:00"
	if clock_label:
		var clock_info: Dictionary = GameManager.get_clock_info()
		clock_label.text = "🕒 " + clock_info.get("time_str", "06:00") + " (" + clock_info.get("period", "PAGI") + ")"

func _on_shift_intermission(shift_completed: int, log_title: String, log_desc: String) -> void:
	_play_sfx(SFX_WIN)
	if intermission_screen:
		intermission_screen.visible = true
	if shift_log_title:
		shift_log_title.text = log_title
	if shift_log_desc:
		shift_log_desc.text = log_desc
	if btn_next_shift:
		var next_day_info: Dictionary = GameManager.get_day_info(shift_completed + 1)
		btn_next_shift.text = "MULAI %s [SPASI]" % next_day_info.get("day_label", "SHIFT %d" % (shift_completed + 1))

func _on_water_changed(current: float, max_amount: float) -> void:
	if water_bar:
		water_bar.max_value = max_amount
		water_bar.value = current
	if water_label:
		water_label.text = "%d / %dL" % [int(current), int(max_amount)]
		water_label.modulate = Color(1.0, 0.3, 0.3) if current < 20.0 else Color.WHITE

func _on_reservoir_changed(current: float, _max_amount: float) -> void:
	var basin_cap: float = GameManager.TOTAL_BASIN_CAPACITY
	if reservoir_bar:
		reservoir_bar.max_value = basin_cap
		reservoir_bar.value = current
	if reservoir_label:
		var depth_m: float = (current / basin_cap) * 3.5
		if current <= 0.0:
			reservoir_label.text = "KERING TOTAL (0L | 0.0m)"
			reservoir_label.modulate = Color(1.0, 0.2, 0.2)
		elif current < 60.0:
			reservoir_label.text = "%dL (%.1fm • KRITIS)" % [int(current), depth_m]
			reservoir_label.modulate = Color(1.0, 0.35, 0.2)
		elif current < 200.0:
			reservoir_label.text = "%dL (%.1fm • SURUT)" % [int(current), depth_m]
			reservoir_label.modulate = Color(1.0, 0.75, 0.25)
		else:
			reservoir_label.text = "%dL (%.1fm • PENUH)" % [int(current), depth_m]
			reservoir_label.modulate = Color(0.3, 0.85, 1.0)

func _on_time_tick(seconds_left: int) -> void:
	if timer_label:
		var mins: int = seconds_left / 60
		var secs: int = seconds_left % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		timer_label.modulate = Color(1.0, 0.2, 0.2) if seconds_left <= 15 else Color.WHITE
	
	if clock_label:
		var clock_info: Dictionary = GameManager.get_clock_info()
		clock_label.text = "🕒 " + clock_info.get("time_str", "06:00") + " (" + clock_info.get("period", "PAGI") + ")"
		match GameManager.current_shift:
			1:
				clock_label.modulate = Color(1.0, 0.90, 0.45)
			2:
				clock_label.modulate = Color(1.0, 0.65, 0.25)
			3:
				clock_label.modulate = Color(1.0, 0.35, 0.25)

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

# ==============================================================================
# CINEMATIC PROLOGUE & TUTORIAL CUTSCENE CONTROLLER
# ==============================================================================

func start_prologue_cutscene() -> void:
	is_cutscene_running = true
	current_beat_index = 0
	prompt_blink_timer = 0.0
	
	if cinematic_overlay:
		cinematic_overlay.visible = true
	if top_bar:
		top_bar.visible = false
	if objective_tracker:
		objective_tracker.visible = false
	if bottom_guide:
		bottom_guide.visible = false
	
	_show_cutscene_beat(0)

func _show_cutscene_beat(index: int) -> void:
	if index >= PROLOGUE_BEATS.size():
		_finish_prologue_cutscene()
		return
	
	current_beat_index = index
	var beat: Dictionary = PROLOGUE_BEATS[index]
	var cam_pos: Vector2 = beat.get("camera_target", Vector2.ZERO)
	
	cutscene_camera_pan.emit(cam_pos, 1.4)
	_play_sfx(SFX_CLICK)
	
	if speaker_badge:
		speaker_badge.text = beat.get("speaker_badge", "")
		speaker_badge.modulate = beat.get("speaker_color", Color.WHITE)
	
	if advance_prompt:
		advance_prompt.text = beat.get("prompt", "[SPASI] Lanjut ▸")
		advance_prompt.visible = false
	
	var raw_text: String = beat.get("raw_text", "")
	if dialogue_text:
		dialogue_text.text = raw_text
		dialogue_text.visible_ratio = 0.0
	
	is_typewriting = true
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	
	var char_count: int = raw_text.length()
	var duration: float = clampf(float(char_count) / 45.0, 1.2, 3.2)
	
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	typewriter_tween.finished.connect(_on_typewriter_finished)

func _on_typewriter_finished() -> void:
	is_typewriting = false
	if dialogue_text:
		dialogue_text.visible_ratio = 1.0
	if advance_prompt:
		advance_prompt.visible = true

func _on_cutscene_input_pressed() -> void:
	if is_typewriting:
		if typewriter_tween and typewriter_tween.is_valid():
			typewriter_tween.kill()
		_on_typewriter_finished()
		_play_sfx(SFX_CLICK)
	else:
		_play_sfx(SFX_WIN)
		_show_cutscene_beat(current_beat_index + 1)

func skip_prologue_cutscene() -> void:
	if not is_cutscene_running:
		return
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	_play_sfx(SFX_CLICK)
	_finish_prologue_cutscene()

func _finish_prologue_cutscene() -> void:
	is_cutscene_running = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	if top_bar:
		top_bar.visible = true
	if objective_tracker:
		objective_tracker.visible = true
	if bottom_guide:
		bottom_guide.visible = true
	
	cutscene_camera_return.emit(0.8)
	cutscene_ended.emit()


