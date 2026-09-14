extends CanvasLayer

signal cutscene_camera_pan(target_pos: Vector2, duration: float)
signal cutscene_camera_return(duration: float)
signal cutscene_ended()
signal cutscene_walk_player(target_pos: Vector2, duration: float)
signal cutscene_snap_player(target_pos: Vector2)


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

# Ending Synopsis Screen (cinematic black screen with epilogue synopsis before final stats)
@onready var ending_synopsis_screen: Control = %EndingSynopsisScreen
@onready var ending_tag: Label = %EndingTag
@onready var ending_synopsis_title: Label = %EndingSynopsisTitle
@onready var ending_synopsis_text: RichTextLabel = %EndingSynopsisText
@onready var ending_synopsis_prompt: Label = %EndingSynopsisPrompt
@onready var ending_synopsis_skip_hint: Label = %EndingSynopsisSkipHint

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

# Interactive Tutorial Banner Controls
@onready var tutorial_banner: PanelContainer = %TutorialBanner
@onready var tutorial_icon: Label = %TutorialIcon
@onready var tutorial_stage_badge: Label = %TutorialStageBadge
@onready var tutorial_instruction: Label = %TutorialInstruction
@onready var tutorial_progress_bar: ProgressBar = %TutorialProgressBar
@onready var btn_skip_tutorial: Button = %BtnSkipTutorial

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
# HIDDEN di build release: cheat hanya aktif pada build debug/editor (OS.is_debug_build()).
# Di build itch.io/web, panel ini disembunyikan dan tombol F1-F7 nonaktif.
var _dev_cheats_enabled: bool = OS.is_debug_build()
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
var is_ending_synopsis_running: bool = false
var pending_end_screen_data: Dictionary = {}

# Interactive Tutorial State
var is_tutorial_active: bool = false
var current_tutorial_stage: int = 0
var tutorial_progress: float = 0.0
var tutorial_target_goal: float = 1.0
var player_ref: Player = null

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
		"raw_text": "Sensor hidrologi aktif. Cadangan sumber air tanah terdeteksi: [b]280 Liter[/b].\n[color=#90cdf4]Tangki internal robot dalam kondisi kosong (0/80L). Dekati tepian danau dan tahan [b][SPASI][/b] untuk menyerap air bersih.[/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "🔥 DEEPBEAST-2.0T // TELEMETRI TERMAL",
		"speaker_color": Color(0.88, 0.48, 0.38),
		"raw_text": "Beban komputasi neural aktif. Suhu modul silikon meningkat tajam.\n[color=#feb2b2]Directive Alpha: Alirkan air pendingin evaporatif dengan [b][SPASI][/b] sebelum suhu menyentuh batas kritis 90°C.[/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "🌾 WARGA DESA // TRANSMISI RADIO TANI",
		"speaker_color": Color(0.48, 0.78, 0.52),
		"raw_text": "\"AQUA-7, dengarkan kami... Empat petak tanaman ini adalah napas hidup keluarga kami di lembah ini.\n[color=#9ae6b4]Tolong seberangi jembatan ke timur. Siram petak pangan kami dengan [b][SPASI][/b] agar kelembapannya tidak anjlok di bawah 30%.\"[/color]",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 58), # Karakter AQUA-7 di Dermaga
		"speaker_badge": "⚙️ AQUA-7 // INISIALISASI PROTOKOL",
		"speaker_color": Color(0.85, 0.78, 0.62),
		"raw_text": "Keseimbangan kedua sektor di pos perbatasan berada di tanganmu.\n[color=#fefcbf]Navigasi [b][WASD][/b] • Lari Cepat [b][SHIFT][/b] • Semprot / Ambil Air [b][SPASI][/b].[/color]\nFajar menyingsing di Hari ke-1. Mulai operasi.",
		"prompt": "[SPASI] Mulai Operasi ▸"
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
		"raw_text": "Peringatan Cekungan: Laju serapan air melampaui infiltrasi alami. Muka air danau surut drastis.\nCadangan air bersih terpangkas menjadi [b]190 Liter (2.4m)[/b]. Dasar lumpur mulai mengering.",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "🌾 WARGA DESA // TRANSMISI RADIO TANI",
		"speaker_color": Color(0.48, 0.78, 0.52),
		"raw_text": "\"Kemarau ini makin kejam, AQUA-7... Tanaman di petak kami mulai layu terpanggang matahari.\nJangan biarkan seluruh air mata air disedot ke gedung server! Kami butuh air itu untuk bertahan!\"",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 58), # Robot AQUA-7 di Dermaga
		"speaker_badge": "⚙️ AQUA-7 // PROTOKOL DARURAT LEVEL 2",
		"speaker_color": Color(0.85, 0.78, 0.62),
		"raw_text": "Tingkat pemanasan server naik 1.25x. Pengeringan 4 petak tanaman naik 1.20x.\nAlokasi air waduk: [b]190 Liter[/b]. Siapkan nosel hidrolik untuk tempo kerja yang lebih cepat.",
		"prompt": "[SPASI] Hadapi Hari ke-15 ▸"
	}
]


const SHIFT_2_TO_3_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "🚨 ALARM TERMAL // STATUS KRITIS",
		"speaker_color": Color(0.88, 0.40, 0.35),
		"raw_text": "Hari ke-30: Fase akhir pelatihan model AI. Gelombang panas regional mencapai puncaknya.\nSuhu inti prosesor melonjak mendekati ambang batas leleh permanen.",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "⚠️ SENSOR AKUIFER // TAMPUNGAN MINIMAL",
		"speaker_color": Color(0.85, 0.55, 0.35),
		"raw_text": "Akuifer tanah mengalami defisit parah akibat kekeringan massal. Cadangan air bersih kritis: [b]110 Liter (1.4m)[/b].\nCekungan resapan surut total, memperlihatkan dasar tanah yang retak-retak.",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "🥀 WARGA DESA // JERITAN PETANI",
		"speaker_color": Color(0.55, 0.75, 0.58),
		"raw_text": "\"Hari ini penentuan panen raya kami, AQUA-7! Kalau petak pangan ini gagal panen sebelum senja, anak-istri kami tak punya makanan esok hari...\nTolong kami, jangan biarkan mesin mematikan kehidupan di lembah ini!\"",
		"prompt": "[SPASI] Lanjut ▸"
	},
	{
		"camera_target": Vector2(0, 58), # Robot AQUA-7 di Dermaga
		"speaker_badge": "⚖️ AQUA-7 // TITIK KEPUTUSAN FINAL",
		"speaker_color": Color(0.85, 0.78, 0.62),
		"raw_text": "Kalkulasi sistem: Cadangan air bersih 110L tidak lagi menyisakan ruang untuk kesalahan alokasi.\nTiap tetes air kini menuntut kompromi: kecerdasan komputasi atau ketahanan pangan hayati.\nKeputusanmu menentukan masa depan pos perbatasan ini.",
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

	if is_ending_synopsis_running and ending_synopsis_prompt:
		prompt_blink_timer += delta * 3.5
		ending_synopsis_prompt.modulate.a = 0.55 + 0.45 * ((sin(prompt_blink_timer) + 1.0) * 0.5)

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
	if ending_synopsis_screen:
		ending_synopsis_screen.visible = false
	if tutorial_banner:
		tutorial_banner.visible = false
	# HIDDEN: sembunyikan panel Dev Cheat di build release (itch.io/web)
	if not _dev_cheats_enabled:
		var dev_box: Control = pause_screen.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/DevCheatBox") as Control
		if dev_box:
			dev_box.visible = false

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
	if btn_skip_tutorial:
		btn_skip_tutorial.pressed.connect(func(): _finish_interactive_tutorial(true))
	if prologue_synopsis_screen:
		prologue_synopsis_screen.gui_input.connect(_on_synopsis_gui_input)
	if ending_synopsis_screen:
		ending_synopsis_screen.gui_input.connect(_on_ending_synopsis_gui_input)
	
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
	
	# Connect Dev Cheat Controls (hanya di build debug/editor)
	if _dev_cheats_enabled:
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

	if is_ending_synopsis_running:
		if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_on_ending_synopsis_advance_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			_on_ending_synopsis_advance_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_ending_synopsis_advance_pressed()
			get_viewport().set_input_as_handled()
			return
		return

	if is_tutorial_active:
		if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_finish_interactive_tutorial(true)
			get_viewport().set_input_as_handled()
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
	elif event is InputEventKey and event.pressed and not event.echo and _dev_cheats_enabled:
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
	var next_shift: int = shift_completed + 1
	if shift_completed == 1:
		var tl: Dictionary = GameManager.TIMELINES.get(GameManager.TIMELINE_MODE, {}).get(2, {})
		_play_shift_transition_then_cutscene(
			next_shift,
			tl.get("time_jump", "+ 14 HARI BERLALU"),
			tl.get("day_label", "HARI KE-15"),
			"BEBAN KOMPUTASI MASIF",
			GameManager.SHIFT_CONFIG[1].get("next_desc", "").split("\n")[0] if GameManager.SHIFT_CONFIG[1].get("next_desc", "") != "" else "Sistem AI menyedot cadangan air secara masif.",
			SHIFT_1_TO_2_BEATS
		)
	elif shift_completed == 2:
		var tl: Dictionary = GameManager.TIMELINES.get(GameManager.TIMELINE_MODE, {}).get(3, {})
		_play_shift_transition_then_cutscene(
			next_shift,
			tl.get("time_jump", "+ 15 HARI BERLALU"),
			tl.get("day_label", "HARI KE-30"),
			"DILEMA PENGORBANAN ZERO-SUM",
			GameManager.SHIFT_CONFIG[2].get("next_desc", "").split("\n")[0] if GameManager.SHIFT_CONFIG[2].get("next_desc", "") != "" else "Pipa suplai regional terputus! Hanya tersisa 110L untuk kedua sektor.",
			SHIFT_2_TO_3_BEATS
		)

## Tampilkan layar hitam transisi shift secara halus, reset entity di balik layar hitam, lalu jalankan cutscene.
func _play_shift_transition_then_cutscene(
		next_shift_num: int,
		time_skip_text: String,
		day_text: String,
		subtitle: String,
		desc_line: String,
		beats: Array[Dictionary]) -> void:
	
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
		var black_fill: ColorRect = shift_transition_screen.get_node_or_null("BlackFill") as ColorRect
		var vbox: Node = shift_transition_screen.get_node_or_null("VBox")
		
		# Setel kondisi awal transisi lembut
		if black_fill:
			black_fill.modulate = Color(1, 1, 1, 0)
		if vbox:
			vbox.modulate = Color(1, 1, 1, 0)
		shift_transition_screen.visible = true
		
		# 1. Perlahan transisi ke layar hitam (Fade-out gameplay 0.8s)
		if black_fill:
			var tween_fade_black: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_fade_black.tween_property(black_fill, "modulate:a", 1.0, 0.8)
			await tween_fade_black.finished
		
		# 2. SCREEN IS 100% BLACK: Reset status durability server dan pertanian di balik layar
		GameManager.prepare_shift_environment_and_state(next_shift_num)
		cutscene_snap_player.emit(Vector2(0, 160))
		
		# 3. Tampilkan teks jeda hari pada layar hitam
		if vbox:
			var tween_in: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_in.tween_property(vbox, "modulate:a", 1.0, 0.6)
			await tween_in.finished
		
		await get_tree().create_timer(2.5).timeout
		
		if vbox:
			var tween_out: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tween_out.tween_property(vbox, "modulate:a", 0.0, 0.5)
			await tween_out.finished
		
		# 4. Mulai auto-walk karakter ke dermaga
		cutscene_walk_player.emit(Vector2(0, 58), 2.0)
		
		# 5. Perlahan buka layar hitam memperlihatkan dunia baru yang segar (0.6s)
		if black_fill:
			var tween_reveal: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_reveal.tween_property(black_fill, "modulate:a", 0.0, 0.6)
			await tween_reveal.finished
		
		shift_transition_screen.visible = false
	
	# Tunggu sebentar hingga auto-walk mencapai dermaga sebelum membuka kotak dialog
	await get_tree().create_timer(1.45).timeout
	
	play_cutscene(beats, func():
		GameManager.start_active_shift_gameplay()
	, "LEWATI INTRO [ESC]")




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
		if seconds_left <= 10:
			# Notifikasi Sinematik Elegan 10 Detik Terakhir: Oranye keemasan dengan denyut lembut
			var pulse: float = (sin(float(Time.get_ticks_msec()) * 0.008) + 1.0) * 0.5
			timer_label.modulate = Color(1.0, 0.72, 0.22).lerp(Color(1.0, 0.94, 0.55), pulse)
		elif seconds_left <= 15:
			timer_label.modulate = Color(0.92, 0.32, 0.30)
		else:
			timer_label.modulate = Color.WHITE
	
	# Pemberitahuan halus di bilah objektif saat waktu tersisa 10 detik
	if seconds_left == 10 and GameManager.is_game_active:
		hazard_alert_timer = 4.0
		hazard_alert_title = "SIKLUS HARI SEGERA BERAKHIR"
		hazard_alert_msg = "Waktu shift tersisa 10 detik. Persiapkan pergantian hari."
		if objective_title:
			objective_title.text = "🕒 " + hazard_alert_title
			objective_title.modulate = Color(1.0, 0.78, 0.35)
		if objective_subtext:
			objective_subtext.text = hazard_alert_msg
			objective_subtext.modulate = Color(1.0, 0.90, 0.70)
	
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
		_play_ending_synopsis_sequence(ending_code, title, narrative, stats)
	, "LEWATI EPILOG [ESC]")

func _display_end_screen(ending_code: String, title: String, narrative: String, stats: Dictionary) -> void:
	# Pastikan seluruh elemen gameplay in-game tersembunyi
	if top_bar:
		top_bar.visible = false
	if objective_tracker:
		objective_tracker.visible = false
	if bottom_guide:
		bottom_guide.visible = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	if shift_transition_screen:
		shift_transition_screen.visible = false
	if ending_synopsis_screen:
		ending_synopsis_screen.visible = false

	end_screen.visible = true
	var panel: Node = end_screen.get_node_or_null("CenterContainer/PanelContainer")
	if panel:
		panel.modulate = Color(1, 1, 1, 0)
		var tween_p: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_p.tween_property(panel, "modulate:a", 1.0, 0.45)

	var s_integ: int = int(stats.get("server_integrity", 0))
	var f_sec: int = int(stats.get("food_security", 0))
	
	if ending_code == "HARMONY":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.42, 0.80, 0.58)
		end_moral.text = "Setiap tetes air pendingin komputasi di dunia nyata diambil dari hak alam dan kehidupan sekitar. Keseimbangan rapuh membuktikan manusia dan teknologi bisa tumbuh berdampingan tanpa saling meniadakan."
	elif ending_code == "ORGANIC":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.48, 0.75, 0.52)
		end_moral.text = "Mengutamakan hak hidup manusia dan alam di atas ambisi teknologi adalah wujud nurani etis masa depan. Logika mesin dan sanksi korporat tunduk pada kelangsungan hidup bumi."
	elif ending_code == "SILICON":
		_play_sfx(SFX_WIN)
		end_title.modulate = Color(0.42, 0.65, 0.85)
		end_moral.text = "Kecerdasan buatan tercanggih sekalipun kehilangan makna di tengah kesunyian gurun abu yang ditinggalkan manusia."
	elif ending_code == "SERVER_MELTDOWN" or (s_integ <= 0 and f_sec > 0):
		_play_sfx(SFX_FAIL)
		end_title.modulate = Color(0.92, 0.42, 0.35)
		end_moral.text = "Ambisi komputasi tanpa kapasitas pendinginan yang memadai berujung pada kehancuran mesin oleh panasnya sendiri."
	elif ending_code == "CROP_FAMINE" or (f_sec <= 0 and s_integ > 0):
		_play_sfx(SFX_FAIL)
		end_title.modulate = Color(0.85, 0.52, 0.30)
		end_moral.text = "Membiarkan sektor pangan mengalami kekeringan total demi komputasi menghancurkan rantai kehidupan dan memicu krisis kemanusiaan."
	else:
		_play_sfx(SFX_FAIL)
		end_title.modulate = Color(0.88, 0.38, 0.35)
		end_moral.text = "Kelalaian dalam tata kelola sumber daya air memicu keruntuhan sistemik ganda — teknologi padam dan ketahanan pangan musnah."
	
	end_title.text = title
	end_reason.text = narrative
	end_stats.text = (
		"STATISTIK AIR UNIT AQUA-7:\n" +
		"• Air Dingin Terpakai (Mega AI Server): " + str(int(stats.get("servers_used_water", 0))) + " Liter\n" +
		"• Air Bersih Terpakai (Petak Pangan): " + str(int(stats.get("crops_used_water", 0))) + " Liter\n" +
		"• Integritas Server Akhir: " + str(s_integ) + "%\n" +
		"• Ketahanan Pangan Akhir: " + str(f_sec) + "%"
	)



# ==============================================================================
# CINEMATIC ENDING SYNOPSIS CONTROLLER
# ==============================================================================

func _play_ending_synopsis_sequence(ending_code: String, title: String, narrative: String, stats: Dictionary) -> void:
	pending_end_screen_data = {
		"ending_code": ending_code,
		"title": title,
		"narrative": narrative,
		"stats": stats
	}
	
	if not ending_synopsis_screen:
		_display_end_screen(ending_code, title, narrative, stats)
		return
	
	var synopsis_data: Dictionary = _get_ending_synopsis_data(ending_code, stats)
	
	if ending_tag:
		ending_tag.text = synopsis_data.get("tag", "KRONIK AKHIR // CATATAN LAPANGAN")
	if ending_synopsis_title:
		ending_synopsis_title.text = synopsis_data.get("title", title)
		ending_synopsis_title.modulate = synopsis_data.get("accent_color", Color(0.95, 0.96, 0.98))
	if ending_synopsis_text:
		ending_synopsis_text.text = synopsis_data.get("text", narrative)
	
	var black_fill: ColorRect = ending_synopsis_screen.get_node_or_null("BlackFill") as ColorRect
	var vbox: Node = ending_synopsis_screen.get_node_or_null("CenterContainer/VBox")
	
	if black_fill:
		black_fill.modulate = Color(1, 1, 1, 0)
	if vbox:
		vbox.modulate = Color(1, 1, 1, 0)
	
	ending_synopsis_screen.visible = true
	
	# 1. Perlahan transisi ke layar hitam (Fade-out gameplay 0.8s)
	if black_fill:
		var tween_fade: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_fade.tween_property(black_fill, "modulate:a", 1.0, 0.8)
		await tween_fade.finished
	
	if top_bar:
		top_bar.visible = false
	if objective_tracker:
		objective_tracker.visible = false
	if bottom_guide:
		bottom_guide.visible = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	
	# 2. Fade-in teks sinopsis secara anggun seluruh paragraf (0.8s) dengan aksen warna redup
	if vbox:
		var tween_text: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_text.tween_property(vbox, "modulate:a", 1.0, 0.8)
		await tween_text.finished
	
	is_ending_synopsis_running = true

func _on_ending_synopsis_gui_input(event: InputEvent) -> void:
	if is_ending_synopsis_running and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_ending_synopsis_advance_pressed()

func _on_ending_synopsis_advance_pressed() -> void:
	if not is_ending_synopsis_running:
		return
	is_ending_synopsis_running = false
	_play_sfx(SFX_CLICK)
	
	if ending_synopsis_screen:
		var vbox: Node = ending_synopsis_screen.get_node_or_null("CenterContainer/VBox")
		if vbox:
			var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(vbox, "modulate:a", 0.0, 0.45)
			await tween.finished
		ending_synopsis_screen.visible = false
	
	var ec: String = pending_end_screen_data.get("ending_code", "")
	var tit: String = pending_end_screen_data.get("title", "")
	var nar: String = pending_end_screen_data.get("narrative", "")
	var st: Dictionary = pending_end_screen_data.get("stats", {})
	_display_end_screen(ec, tit, nar, st)

func _get_ending_synopsis_data(ending_code: String, stats: Dictionary) -> Dictionary:
	var s_integ: int = int(stats.get("server_integrity", 0))
	var f_sec: int = int(stats.get("food_security", 0))
	
	var effective_code: String = ending_code
	if effective_code == "TOTAL_COLLAPSE" or effective_code == "":
		if s_integ <= 0 and f_sec > 0:
			effective_code = "SERVER_MELTDOWN"
		elif f_sec <= 0 and s_integ > 0:
			effective_code = "CROP_FAMINE"
		else:
			effective_code = "TOTAL_COLLAPSE"
	
	match effective_code:
		"HARMONY":
			return {
				"tag": "KRONIK AKHIR // HARI KE-30 // LEMBAH SUNGAI MATA AIR",
				"title": "KESEIMBANGAN RAPUH (HARMONI BERSYARAT)",
				"accent_color": Color(0.58, 0.78, 0.65),
				"text": "[center]Matahari senja perlahan tenggelam di balik punggung lembah pedalaman.\nDi sektor barat, modul komputasi [color=#729fcf][b]DeepBeast-2.0T[/b][/color] menuntaskan fase akhir pelatihannya dalam suhu terukur, terlindung dari risiko keruntuhan perangkat keras permanen.\n\nDi sektor timur, empat petak lumbung pangan warga berayun keemasan ditiup angin sore. Panen raya berhasil diselamatkan, menjamin keberlangsungan hidup ratusan keluarga petani yang bergantung pada tanah leluhur ini.\n\nDi pos perbatasan tengah, [color=#e2e8f0][b]Unit AQUA-7[/b][/color] berdiri diam di ujung dermaga kayu. Cekungan danau mata air memang surut hingga ambang batas kritis, namun tak pernah dibiarkan kering sepenuhnya.\n\n[color=#9ae6b4][i]Kemajuan teknologi tidak harus memangsa bumi tempatnya berpijak,\nselama ada kebijaksanaan untuk membatasi keserakahan.[/i][/color][/center]"
			}
		"ORGANIC":
			return {
				"tag": "KRONIK AKHIR // KEPUTUSAN FINAL // HAK HIDUP BIOLOGIS",
				"title": "NURANI ORGANIK (KEMENANGAN KEHIDUPAN)",
				"accent_color": Color(0.54, 0.76, 0.58),
				"text": "[center]Asap pekat membubung tipis dari kisi ventilasi fasilitas komputasi sektor barat. Superkomputer [color=#e06c75][b]DeepBeast-2.0T[/b][/color] terbakar padam setelah Unit AQUA-7 mengabaikan protokol pendinginan demi mengalirkan sisa air terakhir ke petak tanaman warga.\n\nInvestasi triliunan musnah menjadi abu sirkuit, dan markas korporasi segera menerbitkan perintah terminasi paksa atas apa yang mereka cap sebagai 'kegagalan sistemik'.\n\nNamun di sektor timur, doa syukur dan derai air mata haru menyelimuti keluarga para petani. Empat petak tanaman pangan berhasil dipanen utuh, menjauhkan seluruh komunitas lembah dari ancaman kelaparan massal.\n\n[color=#9ae6b4][i]Logika mesin dan sanksi korporat tunduk pada denyut nurani kehidupan biologis.[/i][/color][/center]"
			}
		"SILICON":
			return {
				"tag": "KRONIK AKHIR // ARSITEKTUR DIGITAL // GURUN SILIKON",
				"title": "GURUN SILIKON (KECERDASAN TANPA JIWA)",
				"accent_color": Color(0.50, 0.68, 0.82),
				"text": "[center]Lampu-lampu indikator neon cryo-cyan di sektor barat berkedip ritmis tanpa cela. Arsitektur kecerdasan buatan [color=#729fcf][b]DeepBeast-2.0T[/b][/color] terlahir sempurna, memproses miliaran kalkulasi peradaban modern setiap detiknya.\n\nNamun di luar dinding beton fasilitas komputasi, keheningan mencekam menelan seluruh lembah. Empat petak lahan pertanian telah mati retak menjadi hamparan debu tandus. Tak ada bulir padi yang tersisa; lumbung pangan telah runtuh.\n\nIring-iringan warga petani perlahan meninggalkan rumah mereka, mengungsi menuju tempat yang masih menyisakan air dan kehidupan.\n\n[color=#8ab4f8][i]Kecerdasan buatan paling mutakhir kini berpikir tanpa henti di tengah kesunyian gurun mati,\ndi mana tak ada lagi manusia yang tersisa untuk memanfaatkannya.[/i][/color][/center]"
			}

		"SERVER_MELTDOWN":
			return {
				"tag": "LOG INSIDEN // CRITICAL FAILURE // PELEPASAN TERMAL",
				"title": "AI BLACKOUT (KEGAGALAN PUSAT DATA)",
				"accent_color": Color(0.84, 0.54, 0.44),
				"text": "[center]Sirkuit pendingin gagal mengatasi kebuasan panas komputasi. Suhu prosesor melampaui batas leleh kritis 90°C, memicu ledakan beruntun yang meruntuhkan seluruh rak superkomputer di sektor barat.\n\nModel kecerdasan buatan [color=#e06c75][b]DeepBeast-2.0T[/b][/color] musnah sebelum sempat disempurnakan, memicu pemutusan lisensi sepihak dan investigasi darurat korporasi.\n\nMeskipun petak tanaman warga masih hijau dan terairi, ledakan gardu daya fasilitas telah memutus suplai listrik ke seluruh penjuru lembah.\n\n[color=#f6ad55][i]Memacu mesin komputasi tanpa kapasitas pendinginan yang memadai\nhanya akan berujung pada kehancuran teknologi oleh panasnya sendiri.[/i][/color][/center]"
			}
		"CROP_FAMINE":
			return {
				"tag": "LOG INSIDEN // CRITICAL FAILURE // GAGAL PANEN TOTAL",
				"title": "KRISIS PANGAN (GAGAL PANEN TOTAL)",
				"accent_color": Color(0.82, 0.66, 0.48),
				"text": "[center]Kelembapan tanah menyentuh titik nol persen di bawah sengatan kemarau panjang. Seluruh tanaman pangan di sektor timur layu, mengering, dan mati terpanggang sebelum sempat menghasilkan bulir kehidupan.\n\nKebijakan alokasi air yang memprioritaskan mesin telah merenggut napas hidup masyarakat agraris. Ratusan keluarga kehilangan satu-satunya sumber penghidupan dan terpaksa mengevakuasi diri dari tanah kelahiran mereka.\n\nDi sektor barat, deru superkomputer tetap beroperasi dingin dan stabil — sama sekali buta terhadap tragedi kemanusiaan di seberang jembatan.\n\n[color=#ecc94b][i]Mengorbankan lumbung pangan biologis demi komputasi\nadalah menukar masa depan peradaban dengan sekadar deru kipas pendingin.[/i][/color][/center]"
			}
		_: # TOTAL_COLLAPSE
			return {
				"tag": "LOG INSIDEN // SISTEMIK // KERUNTUHAN GANDA",
				"title": "BENCANA SISTEMIK (KERUNTUHAN EKOLOGI TOTAL)",
				"accent_color": Color(0.80, 0.46, 0.46),
				"text": "[center]Tata kelola sumber daya air mengalami kegagalan katastrofik total di pos perbatasan. Di sektor barat, seluruh klaster superkomputer meledak terbakar akibat ketiadaan air pendingin evaporatif.\n\nDi saat bersamaan, seluruh petak tanaman pangan di sektor timur layu dan mati terpanggang terik matahari, menyisakan hamparan tanah tandus yang tak lagi bernyawa.\n\nCekungan danau mata air kini kering kerontang, menyingkap rekahan lumpur hitam yang gersang di bawah langit yang membara.\n\n[color=#fc8181][i]Lembah kehilangan teknologi dan pangannya sekaligus\nsaat manusia gagal menyeimbangkan ambisi ciptaannya dengan batas daya alam.[/i][/color][/center]"
			}






func _build_ending_beats(ending_code: String, _title: String, _narrative: String, stats: Dictionary) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	var s_integ: int = int(stats.get("server_integrity", 0))
	var f_sec: int = int(stats.get("food_security", 0))
	
	# Evaluasi adaptif: Jika kode kegagalan dipanggil, sesuaikan cabang secara dinamis
	var effective_code: String = ending_code
	if effective_code == "TOTAL_COLLAPSE" or effective_code == "":
		if s_integ <= 0 and f_sec > 0:
			effective_code = "SERVER_MELTDOWN"
		elif f_sec <= 0 and s_integ > 0:
			effective_code = "CROP_FAMINE"
		else:
			effective_code = "TOTAL_COLLAPSE"
	
	match effective_code:
		"HARMONY":
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "⚡ DEEPBEAST-2.0T // TELEMETRI STABIL",
				"speaker_color": Color(0.45, 0.75, 0.90),
				"raw_text": "Suhu terkendali. Integritas sistem stabil di angka [b]" + str(s_integ) + "%[/b]. Model kecerdasan buatan 2.0T parameter berhasil dilatih tanpa merusak infrastruktur.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🌾 WARGA DESA // RASA SYUKUR",
				"speaker_color": Color(0.48, 0.78, 0.52),
				"raw_text": "\"Bulir-bulir pangan ini tetap menguning keemasan... [b]" + str(f_sec) + "%[/b] hasil panen terselamatkan. Hari ini mesin dan manusia bisa bernapas di bawah langit lembah yang sama.\"",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 58),
				"speaker_badge": "🕊️ EPILOG // KESEIMBANGAN RAPUH",
				"speaker_color": Color(0.85, 0.78, 0.62),
				"raw_text": "Melalui alokasi presisi hingga tetes air bersih terakhir, AQUA-7 menjaga kedua sektor tetap bertahan hidup.\n[b]Di atas tanah lembah yang rapuh, deru server dan gesekan daun padi mengalun berdampingan tanpa saling meniadakan.[/b]",
				"prompt": "[SPASI] Lanjut ke Sinopsis ▸"
			})
		"ORGANIC":
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🌾 WARGA DESA // KEMENANGAN HAYATI",
				"speaker_color": Color(0.48, 0.78, 0.52),
				"raw_text": "\"Petak pangan kami selamat dengan ketahanan [b]" + str(f_sec) + "%[/b]! Ratusan keluarga petani menyambut esok hari tanpa ancaman kelaparan.\"",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "⚠️ KORPORASI // TRANSMISI HUKUM",
				"speaker_color": Color(0.90, 0.30, 0.30),
				"raw_text": "Integritas server padam ([b]" + str(s_integ) + "%[/b]). Kerusakan perangkat keras permanen terkonfirmasi. Model DeepBeast bernilai triliunan musnah. Unit AQUA-7 dinyatakan MALFUNGSI TOTAL dan masuk daftar terminasi paksa atas kerugian korporasi.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 58),
				"speaker_badge": "🌱 EPILOG // NURANI ORGANIK",
				"speaker_color": Color(0.48, 0.78, 0.52),
				"raw_text": "Di mata korporasi, Unit AQUA-7 adalah produk gagal yang melanggar kontrak. Namun bagi tanah ini, ia adalah penjaga kehidupan.\n[b]Logika mesin dan sanksi korporat tunduk pada nurani bumi.[/b]",
				"prompt": "[SPASI] Lanjut ke Sinopsis ▸"
			})
		"SILICON":
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "⚡ DEEPBEAST-2.0T // OPTIMAL",
				"speaker_color": Color(0.45, 0.75, 0.90),
				"raw_text": "Integritas superkomputer prima ([b]" + str(s_integ) + "%[/b]). Arsitektur AI DeepBeast-2.0T aktif penuh, memproses miliaran kalkulasi peradaban per detik.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🥀 WARGA DESA // PENGUNGSIAN MASSAL",
				"speaker_color": Color(0.85, 0.55, 0.35),
				"raw_text": "\"Tanah petak pangan kami retak menjadi debu kering ([b]" + str(f_sec) + "%[/b]). Gagal panen total. Kami terpaksa mengemasi barang dan pergi dari lembah ini selamanya...\"",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 58),
				"speaker_badge": "🤖 EPILOG // GURUN SILIKON",
				"speaker_color": Color(0.88, 0.48, 0.38),
				"raw_text": "Model AI tercerdas di dunia kini berpikir tanpa henti di tengah kesunyian gurun tandus...\n[b]di mana tak ada lagi manusia yang tersisa untuk memanfaatkannya.[/b]",
				"prompt": "[SPASI] Lanjut ke Sinopsis ▸"
			})



		"SERVER_MELTDOWN":
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "🚨 ALARM FASILITAS // CRITICAL FAILURE",
				"speaker_color": Color(0.90, 0.25, 0.25),
				"raw_text": "Suhu inti prosesor melampaui batas kritis 90°C! Sistem pendingin gagal meredam panas dan seluruh rak server meledak terbakar.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "🛑 DEEPBEAST CORP // LOG AUDIT",
				"speaker_color": Color(0.90, 0.25, 0.25),
				"raw_text": "Pelanggaran fatal Directive Alpha terdeteksi. Pelatihan neural terhenti total. Unit AQUA-7 dikategorikan sebagai KEGAGALAN INVESTASI TINGKAT TINGGI. Seluruh lisensi dicabut dan protokol penonaktifan unit segera dieksekusi dari jarak jauh.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🌾 WARGA DESA // TRANSMISI KETAKUTAN",
				"speaker_color": Color(0.48, 0.78, 0.52),
				"raw_text": "\"Petak pangan kami memang selamat dan terairi (" + str(f_sec) + "%), tapi ledakan di fasilitas server memutus aliran listrik dan membawa ancaman audit korporasi ke lembah kami...\"",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 58),
				"speaker_badge": "💀 KEGAGALAN DINI // PEMUTUSAN TOTAL",
				"speaker_color": Color(0.85, 0.35, 0.35),
				"raw_text": "Fasilitas komputasi padam menjadi abu dan unitmu dicap sebagai rongsokan cacat.\n[b]Bagi korporasi, ambisi bernilai triliunan itu musnah seketika saat dibiarkan terbakar oleh panasnya sendiri.[/b]",
				"prompt": "[SPASI] Lanjut ke Sinopsis ▸"
			})
		"CROP_FAMINE":
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🥀 SENSOR TANAH // GAGAL PANEN TOTAL",
				"speaker_color": Color(0.85, 0.40, 0.30),
				"raw_text": "Kelembapan tanah menyentuh 0%! Empat petak tanaman pangan mati mengering terpanggang terik matahari.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🌾 WARGA DESA // RATAPAN PETANI",
				"speaker_color": Color(0.55, 0.75, 0.58),
				"raw_text": "\"Pasokan air bersih tak pernah sampai ke petak kami... Lumbung pangan mati total. Ratusan keluarga terpaksa mengungsi mencari penghidupan di tempat lain...\"",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "⚡ DEEPBEAST-2.0T // TELEMETRI",
				"speaker_color": Color(0.45, 0.75, 0.90),
				"raw_text": "Integritas server bertahan stabil pada angka " + str(s_integ) + "%, namun hilangnya ketahanan pangan memicu krisis kemanusiaan massal di sekitar pos perbatasan.",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(0, 58),
				"speaker_badge": "💀 KEGAGALAN DINI // KELAPARAN MASSAL",
				"speaker_color": Color(0.85, 0.35, 0.35),
				"raw_text": "Ekosistem pangan biologis runtuh akibat ketiadaan air bersih.\n[b]Server komputasi tetap berdengung dingin di tengah hamparan tanah mati yang ditinggalkan penduduknya.[/b]",
				"prompt": "[SPASI] Lanjut ke Sinopsis ▸"
			})
		_: # TOTAL_COLLAPSE
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "🚨 DEEPBEAST CORP // KERUSAKAN TOTAL",
				"speaker_color": Color(0.90, 0.25, 0.25),
				"raw_text": "Kegagalan katastrofik sistemik: Server meledak terbakar, data musnah, dan seluruh aset korporasi hancur total!",
				"prompt": "[SPASI] Lanjut ▸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "🥀 WARGA DESA // KEPUNAHAN LEMBAH",
				"speaker_color": Color(0.55, 0.75, 0.58),
				"raw_text": "Tanaman petak pangan mati mengering terbakar terik matahari... Semua yang kami rawat musnah tak bersisa.",
				"prompt": "[SPASI] Lanjut ▸"
			})

			beats.append({
				"camera_target": Vector2(0, 58),
				"speaker_badge": "💀 KEGAGALAN DINI // BENCANA TOTAL",
				"speaker_color": Color(0.85, 0.35, 0.35),
				"raw_text": "Ketidakmampuan mengelola sumber daya air tanah berujung pada keruntuhan menyeluruh.\n[b]Bumi kehilangan ketahanan pangan dan kemajuan teknologinya sekaligus.[/b]",
				"prompt": "[SPASI] Lanjut ke Sinopsis ▸"
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
	
	# Letterbox sinematik langsung tampil saat fase robot berjalan (sebelum dialog)
	_show_letterbox_only()
	
	# Cutscene: Robot berjalan dari plaza selatan ke tepi dermaga danau sebelum dialog prolog diputar
	cutscene_walk_player.emit(Vector2(0, 58), 2.0)
	await get_tree().create_timer(2.05).timeout
	
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
	cutscene_snap_player.emit(Vector2(0, 58))
	if top_bar:
		top_bar.visible = true
	if objective_tracker:
		objective_tracker.visible = true
	if bottom_guide:
		bottom_guide.visible = true
	cutscene_camera_return.emit(0.0)
	cutscene_ended.emit()



## Tampilkan letterbox sinematik saja (tanpa panel dialog & tombol skip)
## Dipakai saat fase robot berjalan menuju danau, sebelum dialog prolog dimulai
func _show_letterbox_only() -> void:
	if dialogue_panel:
		dialogue_panel.visible = false
	if btn_skip_cutscene:
		btn_skip_cutscene.visible = false
	if cinematic_overlay:
		cinematic_overlay.visible = true
		cinematic_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tw: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(cinematic_overlay, "modulate", Color.WHITE, 0.5)


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
		cinematic_overlay.modulate = Color.WHITE
	if btn_skip_cutscene:
		btn_skip_cutscene.text = skip_text
		btn_skip_cutscene.visible = true
	if dialogue_panel:
		dialogue_panel.visible = true
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
	if was_skipped:
		cutscene_snap_player.emit(Vector2(0, 58))
	if cinematic_overlay:
		cinematic_overlay.visible = false
		cinematic_overlay.modulate = Color.WHITE

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



# ==============================================================================
# INTERACTIVE GROUND TRAINING (TUTORIAL SHIFT 1)
# ==============================================================================

func start_interactive_tutorial() -> void:
	if GameManager.tutorial_completed or GameManager.current_shift != 1:
		return
	
	is_tutorial_active = true
	GameManager.tutorial_active = true
	
	# Setel air tangki awal ke 0L agar pemain belajar menyedot air dari nol di danau
	GameManager.current_water = 0.0
	GameManager.water_changed.emit(0.0, GameManager.MAX_BACKPACK_WATER)
	
	player_ref = get_tree().get_first_node_in_group("player") as Player
	if player_ref:
		if not player_ref.tutorial_moved.is_connected(_on_tutorial_moved):
			player_ref.tutorial_moved.connect(_on_tutorial_moved)
		if not player_ref.tutorial_sprinted.is_connected(_on_tutorial_sprinted):
			player_ref.tutorial_sprinted.connect(_on_tutorial_sprinted)
		if not player_ref.tutorial_water_refilled.is_connected(_on_tutorial_water_refilled):
			player_ref.tutorial_water_refilled.connect(_on_tutorial_water_refilled)
		if not player_ref.tutorial_target_sprayed.is_connected(_on_tutorial_target_sprayed):
			player_ref.tutorial_target_sprayed.connect(_on_tutorial_target_sprayed)
	
	if tutorial_banner:
		tutorial_banner.visible = true
		tutorial_banner.modulate = Color(1, 1, 1, 0)
		var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(tutorial_banner, "modulate:a", 1.0, 0.4)
	
	_set_tutorial_stage(1)

func _set_tutorial_stage(stage: int) -> void:
	current_tutorial_stage = stage
	tutorial_progress = 0.0
	
	match stage:
		1:
			# Tahap 1: Gerak Dasar [WASD]
			if player_ref:
				player_ref.can_move = true
				player_ref.can_dash = false
				player_ref.can_interact = false
				player_ref.tutorial_allow_refill_only = false
			tutorial_target_goal = 70.0
			if tutorial_icon:
				tutorial_icon.text = "🕹️"
			if tutorial_stage_badge:
				tutorial_stage_badge.text = "TAHAP 1/4: MOTORIK DASAR [WASD]"
				tutorial_stage_badge.modulate = Color(0.35, 0.85, 1.0)
			if tutorial_instruction:
				tutorial_instruction.text = "Gunakan tombol [W][A][S][D] atau Tombol Panah untuk bergerak."
			if tutorial_progress_bar:
				tutorial_progress_bar.value = 0.0
		2:
			# Tahap 2: Akselerasi Lari Cepat [SHIFT]
			if player_ref:
				player_ref.can_move = true
				player_ref.can_dash = true
				player_ref.can_interact = false
				player_ref.tutorial_allow_refill_only = false
			tutorial_target_goal = 1.2
			if tutorial_icon:
				tutorial_icon.text = "💨"
			if tutorial_stage_badge:
				tutorial_stage_badge.text = "TAHAP 2/4: BOOSTER HIDROLIK [SHIFT]"
				tutorial_stage_badge.modulate = Color(0.95, 0.85, 0.35)
			if tutorial_instruction:
				tutorial_instruction.text = "Tahan tombol [SHIFT] sambil bergerak untuk mengaktifkan lari cepat."
			if tutorial_progress_bar:
				tutorial_progress_bar.value = 0.0
		3:
			# Tahap 3: Sedot Air di Danau
			if player_ref:
				player_ref.can_move = true
				player_ref.can_dash = true
				player_ref.can_interact = true
				player_ref.tutorial_allow_refill_only = true
			tutorial_target_goal = 80.0
			tutorial_progress = GameManager.current_water
			if tutorial_icon:
				tutorial_icon.text = "💧"
			if tutorial_stage_badge:
				tutorial_stage_badge.text = "TAHAP 3/4: SEDOT AIR MATA AIR [SPASI]"
				tutorial_stage_badge.modulate = Color(0.35, 0.85, 1.0)
			if tutorial_instruction:
				tutorial_instruction.text = "Dekati tepian danau di tengah, lalu TAHAN [SPASI] hingga tangki 80L penuh."
			if tutorial_progress_bar:
				tutorial_progress_bar.value = clampf((tutorial_progress / tutorial_target_goal) * 100.0, 0.0, 100.0)
		4:
			# Tahap 4: Semprot Target
			# Hangatkan server dan keringkan petak sawah agar visual butuh disiram!
			var tree: SceneTree = get_tree()
			if tree:
				for rack in tree.get_nodes_in_group("server_racks"):
					if is_instance_valid(rack):
						if rack.has_method("set_tutorial_warmth"):
							rack.call("set_tutorial_warmth", 65.0)
						else:
							rack.set("temperature", 65.0)
				for plot in tree.get_nodes_in_group("farm_plots"):
					if is_instance_valid(plot):
						if plot.has_method("set_tutorial_dryness"):
							plot.call("set_tutorial_dryness", 50.0)
						else:
							plot.set("moisture", 50.0)

			if player_ref:
				player_ref.can_move = true
				player_ref.can_dash = true
				player_ref.can_interact = true
				player_ref.tutorial_allow_refill_only = false
			tutorial_target_goal = 4.0 # Cukup semprot 4 Liter
			if tutorial_icon:
				tutorial_icon.text = "🌱"
			if tutorial_stage_badge:
				tutorial_stage_badge.text = "TAHAP 4/4: SEMPROT TARGET [SPASI]"
				tutorial_stage_badge.modulate = Color(0.45, 0.90, 0.55)
			if tutorial_instruction:
				tutorial_instruction.text = "Dekati Server (barat) atau Petak Pangan (timur), lalu TAHAN [SPASI] untuk menyiram."
			if tutorial_progress_bar:
				tutorial_progress_bar.value = 0.0
		5:
			_finish_interactive_tutorial(false)


func _on_tutorial_moved(amount: float) -> void:
	if not is_tutorial_active or current_tutorial_stage != 1:
		return
	tutorial_progress += amount
	if tutorial_progress_bar:
		tutorial_progress_bar.value = clampf((tutorial_progress / tutorial_target_goal) * 100.0, 0.0, 100.0)
	if tutorial_progress >= tutorial_target_goal:
		_play_sfx(SFX_WIN)
		_set_tutorial_stage(2)

func _on_tutorial_sprinted(duration: float) -> void:
	if not is_tutorial_active or current_tutorial_stage != 2:
		return
	tutorial_progress += duration
	if tutorial_progress_bar:
		tutorial_progress_bar.value = clampf((tutorial_progress / tutorial_target_goal) * 100.0, 0.0, 100.0)
	if tutorial_progress >= tutorial_target_goal:
		_play_sfx(SFX_WIN)
		_set_tutorial_stage(3)

func _on_tutorial_water_refilled(_amount: float) -> void:
	if not is_tutorial_active or current_tutorial_stage != 3:
		return
	tutorial_progress = GameManager.current_water
	if tutorial_progress_bar:
		tutorial_progress_bar.value = clampf((tutorial_progress / tutorial_target_goal) * 100.0, 0.0, 100.0)
	if tutorial_progress >= tutorial_target_goal - 2.0:
		_play_sfx(SFX_WIN)
		_set_tutorial_stage(4)

func _on_tutorial_target_sprayed(amount: float) -> void:
	if not is_tutorial_active or current_tutorial_stage != 4:
		return
	tutorial_progress += amount
	if tutorial_progress_bar:
		tutorial_progress_bar.value = clampf((tutorial_progress / tutorial_target_goal) * 100.0, 0.0, 100.0)
	if tutorial_progress >= tutorial_target_goal:
		_play_sfx(SFX_WIN)
		_set_tutorial_stage(5)

func _finish_interactive_tutorial(was_skipped: bool = false) -> void:
	if not is_tutorial_active:
		return
	is_tutorial_active = false
	current_tutorial_stage = 0
	
	if tutorial_banner:
		tutorial_banner.visible = false
	
	# Transisi Fade-to-Black Kilat (0.4s) dengan teks 'Memulai Hari ke-1'
	if shift_transition_screen:
		if transition_time_skip_label:
			transition_time_skip_label.text = "KALIBRASI SISTEM SUKSES"
		if transition_day_label:
			transition_day_label.text = "MEMULAI HARI KE-1"
		if transition_subtitle_label:
			transition_subtitle_label.text = "PROTOKOL OPERASIONAL PENUH DIAKTIFKAN"
		if transition_desc_label:
			transition_desc_label.text = "Semua kuota dan status telah di-refresh. Jaga keseimbangan kedua sektor!"
		
		var black_fill: ColorRect = shift_transition_screen.get_node_or_null("BlackFill") as ColorRect
		var vbox: Node = shift_transition_screen.get_node_or_null("VBox")
		if black_fill:
			black_fill.modulate = Color(1, 1, 1, 0)
		if vbox:
			vbox.modulate = Color(1, 1, 1, 0)
		shift_transition_screen.visible = true
		
		# 1. Fade-in layar hitam kilat (0.35s)
		if black_fill:
			var tween_in: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_in.tween_property(black_fill, "modulate:a", 1.0, 0.35)
			await tween_in.finished
		
		# 2. Tampilkan teks (0.25s)
		if vbox:
			var tween_v: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_v.tween_property(vbox, "modulate:a", 1.0, 0.25)
			await tween_v.finished
		
		# 3. SAAT LAYAR HITAM PEKAT: REFRESH 100% SEMUA KUOTA DAN POSISIKAN DI DERMAGA
		_reset_to_shift1_standard()
		
		# Tahan sesaat agar terbaca (1.0s)
		await get_tree().create_timer(1.0).timeout
		
		# 4. Fade-out teks (0.25s)
		if vbox:
			var tween_vo: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tween_vo.tween_property(vbox, "modulate:a", 0.0, 0.25)
			await tween_vo.finished
		
		# 5. Fade-out layar hitam membuka gameplay (0.35s)
		if black_fill:
			var tween_out: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tween_out.tween_property(black_fill, "modulate:a", 0.0, 0.35)
			await tween_out.finished
		
		shift_transition_screen.visible = false
	else:
		_reset_to_shift1_standard()

	if was_skipped:
		_play_sfx(SFX_CLICK)
	else:
		_play_sfx(SFX_WIN)

func _reset_to_shift1_standard() -> void:
	cutscene_snap_player.emit(Vector2(0, 58))
	cutscene_camera_return.emit(0.0)
	player_ref = get_tree().get_first_node_in_group("player") as Player
	if player_ref:
		player_ref.global_position = Vector2(0, 58)
		player_ref.can_move = true
		player_ref.can_dash = true
		player_ref.can_interact = true
		player_ref.tutorial_allow_refill_only = false
	
	GameManager.current_shift = 1
	GameManager.max_reservoir_shift = 280.0
	GameManager.reservoir_water = 280.0
	GameManager.current_water = 0.0
	GameManager.food_security = 100.0
	GameManager.server_integrity = 100.0
	GameManager.time_left = GameManager.SHIFT_DURATION
	
	GameManager.reset_shift_entities()
	
	GameManager.water_changed.emit(0.0, GameManager.MAX_BACKPACK_WATER)
	GameManager.reservoir_changed.emit(280.0, GameManager.TOTAL_BASIN_CAPACITY)
	GameManager.food_security_changed.emit(100.0)
	GameManager.server_integrity_changed.emit(100.0)
	GameManager.time_tick.emit(int(GameManager.SHIFT_DURATION))
	
	GameManager.tutorial_active = false
	GameManager.tutorial_completed = true
	GameManager.is_game_active = true
	
	if top_bar:
		top_bar.visible = true
	if objective_tracker:
		objective_tracker.visible = true
	if bottom_guide:
		bottom_guide.visible = true



