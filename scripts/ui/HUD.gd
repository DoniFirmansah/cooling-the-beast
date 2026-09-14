extends CanvasLayer

signal cutscene_camera_pan(target_pos: Vector2, duration: float)
signal cutscene_camera_return(duration: float)
signal cutscene_ended()

const SFX_CLICK = preload("res://assets/audio/sfx/click_001.ogg")
const SFX_WIN = preload("res://assets/audio/sfx/confirmation_001.ogg")
const SFX_FAIL = preload("res://assets/audio/sfx/error_001.ogg")

@onready var top_bar: PanelContainer = $TopBar
@onready var bottom_guide: PanelContainer = $BottomGuide

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

# Prologue Lore Synopsis Screen (black screen with lore text before Shift 1 dialog)
@onready var prologue_synopsis_screen: Control = %PrologueSynopsisScreen
@onready var synopsis_text: RichTextLabel = %SynopsisText
@onready var synopsis_prompt: Label = %SynopsisPrompt
@onready var synopsis_skip_hint: Label = %SynopsisSkipHint

# Shift Transition Screen (full black screen with day title)
@onready var shift_transition_screen: Control = %ShiftTransitionScreen
@onready var transition_time_skip_label: Label = %TimeSkipLabel
@onready var transition_day_label: Label = %DayLabel
@onready var transition_subtitle_label: Label = %SubtitleLabel
@onready var transition_desc_label: Label = %DescLabel

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
var ending_shown: bool = false  # Guard against ending loop bug

# Cutscene Controller State
var is_cutscene_running: bool = false
var is_synopsis_running: bool = false
var is_synopsis_typing: bool = false
var synopsis_typewriter_tween: Tween
var current_beat_index: int = 0
var is_typewriting: bool = false
var typewriter_tween: Tween
var prompt_blink_timer: float = 0.0
var active_cutscene_beats: Array[Dictionary] = []
var on_cutscene_complete_callable: Callable = Callable()

const PROLOGUE_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "💧 AQUA-7 // DIAGNOSTIK HIDROLIK",
		"speaker_color": Color(0.45, 0.75, 0.90),
		"raw_text": "Sensor akuifer terhubung. Cekungan mata air alami terdeteksi pada volume awal [b]280 Liter[/b].\n[color=#90cdf4]Sistem siap menyerap pasokan air. Dekati tepian danau dan tahan [b][SPASI][/b] untuk mengisi tangki 120L.[/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "🔥 DEEPBEAST-2.0T // TELEMETRI TERMAL",
		"speaker_color": Color(0.88, 0.48, 0.38),
		"raw_text": "Beban komputasi klaster neural aktif. Suhu operasional inti silikon meningkat tajam.\n[color=#feb2b2]Direktif Utama: Semprotkan pendingin dengan [b][SPASI][/b] sebelum suhu menyentuh batas bahaya 90°C.[/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "🌾 WARGA DESA // TRANSMISI RADIO TANI",
		"speaker_color": Color(0.48, 0.78, 0.52),
		"raw_text": "\"AQUA-7, dengarkan kami... Sawah ini adalah napas hidup keluarga kami di lembah ini.\n[color=#9ae6b4]Tolong seberangi jembatan ke timur. Siram tanah kami dengan [b][SPASI][/b] agar kelembapan tidak anjlok di bawah 30%.\"",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 65), # Karakter AQUA-7
		"speaker_badge": "⚙️ AQUA-7 // INISIALISASI PROTOKOL",
		"speaker_color": Color(0.85, 0.78, 0.62),
		"raw_text": "Keseimbangan dua sektor kini berada di bawah kendalimu.\n[color=#fefcbf]Navigasi [b][WASD][/b] • Akselerasi [b][SHIFT][/b] • Semprot / Isi Air [b][SPASI][/b].[/color]\nFajar menyingsing di Hari ke-1. Selamat bertugas.",
		"prompt": "[SPASI] Start Game ▸"
	}
]

const SHIFT_1_TO_2_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "📡 TELEMETRI SATELIT // HARI KE-15",
		"speaker_color": Color(0.45, 0.75, 0.90),
		"raw_text": "Dua pekan komputasi penuh telah berlalu. Pelatihan neural DeepBeast memasuki fase akselerasi masif.\nPanas pelepasan termal meningkat tajam melintasi seluruh modul sirkuit.",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "💧 SENSOR HIDROLOGI // AKUIFER MENYUSUT",
		"speaker_color": Color(0.85, 0.68, 0.40),
		"raw_text": "Peringatan Cekungan: Laju serapan air melampaui infiltrasi alami. Muka air danau surut hingga 25%.\nCadangan air bersih terpangkas menjadi [b]180 Liter (2.3m)[/b]. Dasar lumpur mulai mengering.",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "🌾 WARGA DESA // TRANSMISI RADIO TANI",
		"speaker_color": Color(0.48, 0.78, 0.52),
		"raw_text": "\"Kemarau ini makin kejam, AQUA-7... Daun-daun padi kami mulai menguning terpanggang matahari.\nJangan biarkan seluruh air mata air disedot ke gedung server! Kami butuh air itu untuk bertahan!\"",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 65), # Robot AQUA-7
		"speaker_badge": "⚙️ AQUA-7 // PROTOKOL DARURAT LEVEL 2",
		"speaker_color": Color(0.85, 0.78, 0.62),
		"raw_text": "Tingkat pemanasan server naik 1.15x. Pengeringan lahan sawah naik 1.10x.\nAlokasi air danau: [b]180 Liter[/b]. Siapkan nosel hidrolik untuk ritme kerja yang lebih cepat.",
		"prompt": "[SPASI] Hadapi Hari ke-15 ▸"
	}
]

const SHIFT_2_TO_3_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "🚨 ALARM TERMAL // STATUS KRITIS",
		"speaker_color": Color(0.88, 0.40, 0.35),
		"raw_text": "Memasuki Hari ke-30. Gelombang panas regional mencapai titik kulminasi ekstrem.\nSuhu inti komputasi DeepBeast melonjak liar menuju ambang kegagalan struktural permanen.",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "⚠️ SENSOR AKUIFER // TAMPUNGAN MINIMAL",
		"speaker_color": Color(0.85, 0.55, 0.35),
		"raw_text": "Suplai pipa hulu terputus akibat kekeringan regional. Cadangan danau berada pada level kritis: [b]135 Liter (1.7m)[/b].\nPalung utama telah mengering, menyingkap rekahan tanah tandus di dasar cekungan.",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "🥀 WARGA DESA // JERITAN PETANI",
		"speaker_color": Color(0.55, 0.75, 0.58),
		"raw_text": "\"Hari ini adalah penentuan panen raya kami, AQUA-7! Jika sawah ini mati sebelum senja, ratusan keluarga kami tak punya makanan esok hari...\nTolong, jangan biarkan mesin membunuh kehidupan!\"",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 65), # Robot AQUA-7
		"speaker_badge": "⚖️ AQUA-7 // TITIK KEPUTUSAN FINAL",
		"speaker_color": Color(0.85, 0.78, 0.62),
		"raw_text": "Kalkulasi sistem: Sisa air 135L danau berada pada batas kritis dengan toleransi tipis.\nSetiap liter air yang dialirkan adalah pilihan mutlak antara kecerdasan silikon atau kelangsungan pangan biologis.\nKeputusanmu akan menentukan akhir dari lembah ini.",
		"prompt": "[SPASI] Hadapi Hari Terakhir ▸"
	}
]


var hazard_alert_timer: float = 0.0
var hazard_alert_title: String = ""
var hazard_alert_msg: String = ""

func _process(delta: float) -> void:
	if hazard_alert_timer > 0.0:
		hazard_alert_timer = max(0.0, hazard_alert_timer - delta)

	if is_synopsis_running and synopsis_prompt:
		prompt_blink_timer += delta * 3.5
		synopsis_prompt.modulate.a = 0.55 + 0.45 * ((sin(prompt_blink_timer) + 1.0) * 0.5)

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
	if hazard_alert_timer > 0.0:
		if objective_title:
			objective_title.text = "⚠️ " + hazard_alert_title
			objective_title.modulate = Color(1.0, 0.35, 0.25)
		if objective_subtext:
			objective_subtext.text = hazard_alert_msg
			objective_subtext.modulate = Color(1.0, 0.85, 0.6)
	else:
		if objective_title:
			objective_title.text = data.get("title", "")
			objective_title.modulate = Color(0.95, 0.96, 0.98)
		if objective_subtext:
			objective_subtext.text = data.get("subtext", "")
			objective_subtext.modulate = Color(0.68, 0.72, 0.78)
	if objective_icon:
		objective_icon.text = data.get("icon", "💧")
	if objective_dir:
		objective_dir.text = data.get("dir_arrow", "►")
		objective_dir.modulate = Color(0.85, 0.88, 0.92)
	if objective_dist:
		var dist_px: float = data.get("distance", 0.0)
		var dist_m: int = int(dist_px / 16.0)
		if data.get("is_near", false):
			objective_dist.text = "[TEKAN SPASI]"
			objective_dist.modulate = Color(0.40, 0.85, 0.50)
		else:
			objective_dist.text = "%dm" % dist_m
			objective_dist.modulate = Color(0.55, 0.78, 0.90)

func _on_hazard_alert(title: String, message: String) -> void:
	hazard_alert_timer = 4.0
	hazard_alert_title = title
	hazard_alert_msg = message
	_play_sfx(SFX_FAIL)
	if objective_title:
		objective_title.text = "⚠️ " + title
		objective_title.modulate = Color(1.0, 0.35, 0.25)
	if objective_subtext:
		objective_subtext.text = message
		objective_subtext.modulate = Color(1.0, 0.85, 0.6)



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	end_screen.visible = false
	pause_screen.visible = false
	if intermission_screen:
		intermission_screen.visible = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	if shift_transition_screen:
		shift_transition_screen.visible = false
	
	# Cegah glitch visual: Frame 0 langsung tutup layar dengan hitam jika baru mulai Shift 1
	if GameManager.current_shift == 1 and not GameManager.prologue_seen:
		if top_bar:
			top_bar.visible = false
		if objective_tracker:
			objective_tracker.visible = false
		if bottom_guide:
			bottom_guide.visible = false
		if prologue_synopsis_screen:
			prologue_synopsis_screen.visible = true
	else:
		if prologue_synopsis_screen:
			prologue_synopsis_screen.visible = false
	
	if btn_skip_cutscene:
		btn_skip_cutscene.pressed.connect(skip_prologue_cutscene)
	if prologue_synopsis_screen:
		prologue_synopsis_screen.gui_input.connect(_on_synopsis_gui_input)
	
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
	GameManager.hazard_alert.connect(_on_hazard_alert)
	
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
	if is_synopsis_running:
		if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_on_synopsis_skip_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			_on_synopsis_advance_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_synopsis_advance_pressed()
			get_viewport().set_input_as_handled()
			return
		return

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
				if not is_cutscene_running and not is_synopsis_running:
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
	ending_shown = false
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

func _on_shift_intermission(shift_completed: int, _log_title: String, _log_desc: String) -> void:
	if shift_completed == 1:
		var tl: Dictionary = GameManager.TIMELINES.get(GameManager.TIMELINE_MODE, {}).get(2, {})
		_play_shift_transition_then_cutscene(
			tl.get("time_jump", "+ 14 HARI BERLALU"),
			tl.get("day_label", "HARI KE-15"),
			"BEBAN KOMPUTASI MASIF",
			GameManager.SHIFT_CONFIG[1].get("next_desc", "").split("\n")[0] if GameManager.SHIFT_CONFIG[1].get("next_desc", "") != "" else "Sistem AI menyedot cadangan air secara masif.",
			SHIFT_1_TO_2_BEATS,
			func():
				GameManager.advance_to_next_shift()
		)
	elif shift_completed == 2:
		var tl: Dictionary = GameManager.TIMELINES.get(GameManager.TIMELINE_MODE, {}).get(3, {})
		_play_shift_transition_then_cutscene(
			tl.get("time_jump", "+ 15 HARI BERLALU"),
			tl.get("day_label", "HARI KE-30"),
			"DILEMA PENGORBANAN ZERO-SUM",
			GameManager.SHIFT_CONFIG[2].get("next_desc", "").split("\n")[0] if GameManager.SHIFT_CONFIG[2].get("next_desc", "") != "" else "Pipa suplai regional terputus! Hanya tersisa 110L untuk kedua sektor.",
			SHIFT_2_TO_3_BEATS,
			func():
				GameManager.advance_to_next_shift()
		)

## Tampilkan layar hitam transisi shift, lalu jalankan cutscene dialog setelah jeda.
func _play_shift_transition_then_cutscene(
		time_skip_text: String,
		day_text: String,
		subtitle: String,
		desc_line: String,
		beats: Array[Dictionary],
		on_done: Callable) -> void:
	
	if top_bar:
		top_bar.visible = false
	if objective_tracker:
		objective_tracker.visible = false
	if bottom_guide:
		bottom_guide.visible = false
	if intermission_screen:
		intermission_screen.visible = false
	
	if transition_time_skip_label:
		transition_time_skip_label.text = time_skip_text
	if transition_day_label:
		transition_day_label.text = day_text
	if transition_subtitle_label:
		transition_subtitle_label.text = subtitle
	if transition_desc_label:
		transition_desc_label.text = desc_line
	
	if shift_transition_screen:
		var vbox: Node = shift_transition_screen.get_node_or_null("VBox")
		if vbox:
			vbox.modulate = Color(1, 1, 1, 0)
		shift_transition_screen.visible = true
		
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(shift_transition_screen) and vbox:
			var tween_in: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_in.tween_property(vbox, "modulate", Color.WHITE, 0.7)
			await tween_in.finished
		
		await get_tree().create_timer(2.5).timeout
		
		if is_instance_valid(shift_transition_screen) and vbox:
			var tween_out: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tween_out.tween_property(vbox, "modulate", Color(1, 1, 1, 0), 0.5)
			await tween_out.finished
	
	if shift_transition_screen:
		shift_transition_screen.visible = false
	
	play_cutscene(beats, on_done, "LEWATI INTRO [ESC]")

func _on_water_changed(current: float, max_amount: float) -> void:
	if water_bar:
		water_bar.max_value = max_amount
		water_bar.value = current
		water_bar.modulate = Color(0.92, 0.35, 0.32) if current < 20.0 else Color.WHITE
	if water_label:
		water_label.text = "%d / %dL" % [int(current), int(max_amount)]
		water_label.modulate = Color(0.92, 0.35, 0.32) if current < 20.0 else Color.WHITE

func _on_reservoir_changed(current: float, _max_amount: float) -> void:
	var basin_cap: float = GameManager.TOTAL_BASIN_CAPACITY
	if reservoir_bar:
		reservoir_bar.max_value = basin_cap
		reservoir_bar.value = current
		if current <= 0.0:
			reservoir_bar.modulate = Color(0.92, 0.32, 0.30)
		elif current < 60.0:
			reservoir_bar.modulate = Color(0.92, 0.58, 0.28)
		else:
			reservoir_bar.modulate = Color.WHITE
	if reservoir_label:
		var depth_m: float = (current / basin_cap) * 3.5
		if current <= 0.0:
			reservoir_label.text = "KERING TOTAL (0L | 0.0m)"
			reservoir_label.modulate = Color(0.92, 0.32, 0.30)
		elif current < 60.0:
			reservoir_label.text = "%dL (%.1fm • KRITIS)" % [int(current), depth_m]
			reservoir_label.modulate = Color(0.92, 0.55, 0.28)
		elif current < 200.0:
			reservoir_label.text = "%dL (%.1fm • SURUT)" % [int(current), depth_m]
			reservoir_label.modulate = Color(0.88, 0.75, 0.40)
		else:
			reservoir_label.text = "%dL (%.1fm • PENUH)" % [int(current), depth_m]
			reservoir_label.modulate = Color(0.72, 0.85, 0.95)

func _on_time_tick(seconds_left: int) -> void:
	if timer_label:
		var mins: int = seconds_left / 60
		var secs: int = seconds_left % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		timer_label.modulate = Color(0.92, 0.32, 0.30) if seconds_left <= 15 else Color.WHITE
	
	if clock_label:
		var clock_info: Dictionary = GameManager.get_clock_info()
		clock_label.text = "🕒 " + clock_info.get("time_str", "06:00") + " (" + clock_info.get("period", "PAGI") + ")"
		match GameManager.current_shift:
			1:
				clock_label.modulate = Color(0.92, 0.88, 0.78)
			2:
				clock_label.modulate = Color(0.94, 0.76, 0.52)
			3:
				clock_label.modulate = Color(0.92, 0.52, 0.42)

func _on_server_integrity_changed(val: float) -> void:
	if server_bar:
		server_bar.value = val
		server_bar.modulate = Color(0.92, 0.32, 0.30) if val <= 25.0 else Color.WHITE
	if server_label:
		server_label.text = str(int(val)) + "%"
		server_label.modulate = Color(0.92, 0.32, 0.30) if val <= 25.0 else Color.WHITE

func _on_food_security_changed(val: float) -> void:
	if food_bar:
		food_bar.value = val
		food_bar.modulate = Color(0.92, 0.40, 0.30) if val <= 30.0 else Color.WHITE
	if food_label:
		food_label.text = str(int(val)) + "%"
		food_label.modulate = Color(0.92, 0.40, 0.30) if val <= 30.0 else Color.WHITE

func _on_game_finished(ending_code: String, title: String, narrative: String, stats: Dictionary) -> void:
	if ending_shown:
		return
	ending_shown = true
	
	var beats: Array[Dictionary] = _build_ending_beats(ending_code, title, narrative, stats)
	play_cutscene(beats, func():
		_display_end_screen(ending_code, title, narrative, stats)
	, "LEWATI EPILOG [ESC]")

func _display_end_screen(ending_code: String, title: String, narrative: String, stats: Dictionary) -> void:
	end_screen.visible = true
	if ending_code == "HARMONY":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.42, 0.80, 0.58)
	elif ending_code == "ORGANIC":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.48, 0.75, 0.52)
	elif ending_code == "SILICON":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.42, 0.65, 0.85)
	else:
		_play_sfx(SFX_FAIL)
		end_title.modulate = Color(0.88, 0.38, 0.35)
	
	end_title.text = title
	end_reason.text = narrative
	end_stats.text = (
		"STATISTIK AIR UNIT AQUA-7:\n" +
		"• Air Dingin Terpakai (Mega AI Server): " + str(int(stats.get("servers_used_water", 0))) + " Liter\n" +
		"• Air Bersih Terpakai (Sawah Warga): " + str(int(stats.get("crops_used_water", 0))) + " Liter\n" +
		"• Integritas Server Akhir: " + str(int(stats.get("server_integrity", 0))) + "%\n" +
		"• Ketahanan Pangan Akhir: " + str(int(stats.get("food_security", 0))) + "%"
	)
	end_moral.text = "Save the Earth: Setiap tetes air pendingin komputasi di dunia nyata diambil dari hak alam dan kehidupan sekitar. Bisakah manusia dan teknologi tumbuh berdampingan secara bijak?"


func _build_ending_beats(ending_code: String, _title: String, _narrative: String, stats: Dictionary) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	var s_integ: int = int(stats.get("server_integrity", 0))
	var f_sec: int = int(stats.get("food_security", 0))
	
	match ending_code:
		"HARMONY":
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "🖥️ DEEPBEAST-2.0T // TELEMETRI STABIL",
				"speaker_color": Color(0.42, 0.72, 0.88),
				"raw_text": "Telemetri stabil pada integritas [b]" + str(s_integ) + "%[/b]. Model kecerdasan buatan 2.0T parameter berhasil dilatih dengan efisiensi energi terukur.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🌾 WARGA DESA // AIR MATA HARU",
				"speaker_color": Color(0.45, 0.80, 0.55),
				"raw_text": "Air mata kami menetes melihat bulir padi ini, AQUA-7... [b]" + str(f_sec) + "%[/b] tanaman berhasil dipanen. Kamu membuktikan teknologi dan manusia bisa saling menjaga!",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "✨ EPILOG: KESEIMBANGAN RAPUH (TRUE ENDING)",
				"speaker_color": Color(0.85, 0.78, 0.62),
				"raw_text": "Di tepi jurang kepunahan, Unit AQUA-7 menemukan satu celah sempit harmoni.\nSebuah bukti abadi: [b]Kemajuan teknologi tidak harus mematikan bumi tempatnya berpijak.[/b]",
				"prompt": "[SPASI] Lihat Statistik 📊"
			})
		"ORGANIC":
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🌾 WARGA DESA // SUJUD SYUKUR",
				"speaker_color": Color(0.48, 0.75, 0.52),
				"raw_text": "Sawah pangan warga terselamatkan pada [b]" + str(f_sec) + "%[/b]! Ratusan keluarga petani menyambut masa depan tanpa ancaman kelaparan.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "🖥️ DEEPBEAST-2.0T // DAYA MATI",
				"speaker_color": Color(0.85, 0.45, 0.42),
				"raw_text": "Daya server padam total ([b]" + str(s_integ) + "%[/b]). Kerusakan termal permanen terkonfirmasi. Korporasi kehilangan aset komputasi, namun nurani kehidupan dimenangkan.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "🌱 EPILOG: NURANI ORGANIK",
				"speaker_color": Color(0.45, 0.78, 0.52),
				"raw_text": "Unit AQUA-7 mengesampingkan algoritma korporasi demi mengalirkan sisa air terakhir kepada kehidupan.\n[b]Logika mesin tunduk pada nurani bumi.[/b]",
				"prompt": "[SPASI] Lihat Statistik 📊"
			})
		"SILICON":
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "🖥️ DEEPBEAST-2.0T // DOMINASI MUTLAK",
				"speaker_color": Color(0.42, 0.68, 0.85),
				"raw_text": "Integritas superkomputer prima ([b]" + str(s_integ) + "%[/b]). Arsitektur neural 2.0T terlahir sempurna, memproses miliaran data peradaban per detik.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🥀 TANAH TANDUS // GURUN SILIKON",
				"speaker_color": Color(0.82, 0.62, 0.42),
				"raw_text": "Tanah pertanian mati retak menjadi abu ([b]" + str(f_sec) + "%[/b]). Tak ada lagi padi yang tersisa. Kami terpaksa meninggalkan lembah ini selamanya...",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "🤖 EPILOG: GURUN SILIKON",
				"speaker_color": Color(0.42, 0.68, 0.85),
				"raw_text": "Kecerdasan buatan paling mutakhir di dunia kini berpikir tanpa henti di tengah kesunyian gurun abu...\n[b]di mana tak ada lagi manusia yang tersisa untuk menikmatinya.[/b]",
				"prompt": "[SPASI] Lihat Statistik 📊"
			})

		_: # TOTAL_COLLAPSE
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "☠️ KONTROL ALARM // KEGAGALAN SISTEM",
				"speaker_color": Color(0.85, 0.38, 0.35),
				"raw_text": "Alarm kegagalan katastrofik: Seluruh rak server meledak terbakar dalam kepulan asap hitam!",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "☠️ TANAH MATI // GAGAL TOTAL",
				"speaker_color": Color(0.85, 0.38, 0.35),
				"raw_text": "Tanaman sawah puso dan kering terbakar terik matahari... Semua yang kami perjuangkan musnah tak bersisa.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "☠️ EPILOG: BENCANA EKOLOGI TOTAL",
				"speaker_color": Color(0.85, 0.38, 0.35),
				"raw_text": "Kelalaian dalam mengelola sumber daya berujung pada keruntuhan total ekosistem.\n[b]Peradaban kehilangan teknologi dan pangannya sekaligus.[/b]",
				"prompt": "[SPASI] Lihat Statistik 📊"
			})
	
	return beats

# ==============================================================================
# CINEMATIC CUTSCENE & DIALOGUE CONTROLLER
# ==============================================================================

func start_prologue_cutscene() -> void:
	if top_bar:
		top_bar.visible = false
	if objective_tracker:
		objective_tracker.visible = false
	if bottom_guide:
		bottom_guide.visible = false
	if intermission_screen:
		intermission_screen.visible = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	
	if prologue_synopsis_screen:
		is_synopsis_running = true
		var vbox: Node = prologue_synopsis_screen.get_node_or_null("CenterContainer/VBox")
		if vbox:
			vbox.modulate = Color(1, 1, 1, 0)
		prologue_synopsis_screen.visible = true
		
		is_synopsis_typing = true
		if synopsis_text:
			synopsis_text.visible_ratio = 0.0
		if synopsis_prompt:
			synopsis_prompt.visible = false
		if synopsis_skip_hint:
			synopsis_skip_hint.text = "[SPASI] Percepat   •   [ESC] Lewati"

		# Fade-in container judul
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(prologue_synopsis_screen) and vbox:
			var tween_vbox: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_vbox.tween_property(vbox, "modulate", Color.WHITE, 0.6)
			await tween_vbox.finished

		# Animasi teks mengalir / mengetik (Typewriter effect)
		if is_instance_valid(prologue_synopsis_screen) and synopsis_text and is_synopsis_typing:
			if synopsis_typewriter_tween and synopsis_typewriter_tween.is_valid():
				synopsis_typewriter_tween.kill()

			var char_count: int = synopsis_text.get_total_character_count()
			if char_count <= 0:
				char_count = synopsis_text.text.length()
			var duration: float = clampf(float(char_count) / 65.0, 4.0, 7.5)

			synopsis_typewriter_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
			synopsis_typewriter_tween.tween_property(synopsis_text, "visible_ratio", 1.0, duration)
			synopsis_typewriter_tween.finished.connect(_on_synopsis_typewriter_finished)
	else:
		play_cutscene(PROLOGUE_BEATS, Callable(), "LEWATI PROLOG [ESC]")

func _on_synopsis_gui_input(event: InputEvent) -> void:
	if is_synopsis_running and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_synopsis_advance_pressed()

func _on_synopsis_typewriter_finished() -> void:
	is_synopsis_typing = false
	if synopsis_text:
		synopsis_text.visible_ratio = 1.0
	if synopsis_prompt:
		synopsis_prompt.visible = true
		synopsis_prompt.text = "Klik Layar atau Tekan [SPASI] untuk Lanjut ▸"
	if synopsis_skip_hint:
		synopsis_skip_hint.text = "[ESC] Lewati Sinopsis"

func _on_synopsis_advance_pressed() -> void:
	if not is_synopsis_running:
		return
	
	# Jika teks masih animasi, percepat seketika
	if is_synopsis_typing:
		if synopsis_typewriter_tween and synopsis_typewriter_tween.is_valid():
			synopsis_typewriter_tween.kill()
		_on_synopsis_typewriter_finished()
		_play_sfx(SFX_CLICK)
		return

	is_synopsis_running = false
	_play_sfx(SFX_CLICK)
	
	if prologue_synopsis_screen:
		var vbox: Node = prologue_synopsis_screen.get_node_or_null("CenterContainer/VBox")
		if vbox:
			var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(vbox, "modulate", Color(1, 1, 1, 0), 0.45)
			await tween.finished
		if is_instance_valid(prologue_synopsis_screen):
			prologue_synopsis_screen.visible = false
	
	# Putar cutscene dialog prolog
	play_cutscene(PROLOGUE_BEATS, Callable(), "LEWATI PROLOG [ESC]")

func _on_synopsis_skip_pressed() -> void:
	if not is_synopsis_running:
		return
	if synopsis_typewriter_tween and synopsis_typewriter_tween.is_valid():
		synopsis_typewriter_tween.kill()
	is_synopsis_running = false
	is_synopsis_typing = false
	_play_sfx(SFX_CLICK)
	
	if prologue_synopsis_screen:
		prologue_synopsis_screen.visible = false
	
	# Lewati sinopsis dan cutscene langsung ke gameplay
	GameManager.prologue_seen = true
	if top_bar:
		top_bar.visible = true
	if objective_tracker:
		objective_tracker.visible = true
	if bottom_guide:
		bottom_guide.visible = true
	cutscene_camera_return.emit(0.0)
	cutscene_ended.emit()

func play_cutscene(beats: Array[Dictionary], on_complete: Callable = Callable(), skip_text: String = "LEWATI [ESC]") -> void:
	if beats.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return
	
	active_cutscene_beats = beats
	on_cutscene_complete_callable = on_complete
	is_cutscene_running = true
	current_beat_index = 0
	prompt_blink_timer = 0.0
	
	if cinematic_overlay:
		cinematic_overlay.visible = true
	if btn_skip_cutscene:
		btn_skip_cutscene.text = skip_text
	if top_bar:
		top_bar.visible = false
	if objective_tracker:
		objective_tracker.visible = false
	if bottom_guide:
		bottom_guide.visible = false
	if intermission_screen:
		intermission_screen.visible = false
	
	_show_active_cutscene_beat(0)

func _show_active_cutscene_beat(index: int) -> void:
	if index >= active_cutscene_beats.size():
		_finish_active_cutscene()
		return
	
	current_beat_index = index
	var beat: Dictionary = active_cutscene_beats[index]
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
		_show_active_cutscene_beat(current_beat_index + 1)

func skip_prologue_cutscene() -> void:
	skip_current_cutscene()

func skip_current_cutscene() -> void:
	if not is_cutscene_running:
		return
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	_play_sfx(SFX_CLICK)
	_finish_active_cutscene(true)

func _finish_active_cutscene(was_skipped: bool = false) -> void:
	is_cutscene_running = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	if top_bar:
		top_bar.visible = true
	if objective_tracker:
		objective_tracker.visible = true
	if bottom_guide:
		bottom_guide.visible = true
	
	var return_dur: float = 0.0 if was_skipped else 0.4
	cutscene_camera_return.emit(return_dur)
	cutscene_ended.emit()
	
	var cb: Callable = on_cutscene_complete_callable
	on_cutscene_complete_callable = Callable()
	if cb.is_valid():
		cb.call()


