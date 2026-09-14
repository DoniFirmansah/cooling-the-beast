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
var current_beat_index: int = 0
var is_typewriting: bool = false
var typewriter_tween: Tween
var prompt_blink_timer: float = 0.0
var active_cutscene_beats: Array[Dictionary] = []
var on_cutscene_complete_callable: Callable = Callable()

const PROLOGUE_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "ðŸ’§ ðŸ¤– AQUA-7 // PROTOKOL INTERNAL",
		"speaker_color": Color(0.15, 0.90, 1.0),
		"raw_text": "Inisialisasi sistem hidrolik selesai. Sumber air bersih terdeteksi [b]280 Liter[/b].\n[color=#66e5ff][b][TUTORIAL]:[/b] Berjalanlah ke tepi danau lalu tahan [b][SPASI][/b] untuk menyedot air bersih ke dalam tangki 120L robot.[/color]",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "ðŸ”¥ ðŸ–¥ï¸ DEEPBEAST-2.0T // DIRECTIVE ALPHA",
		"speaker_color": Color(1.0, 0.35, 0.25),
		"raw_text": "Peringatan Panas: 4 klaster rak server AI beroperasi pada daya komputasi tinggi.\n[color=#ff8a80][b][TUTORIAL]:[/b] Dekati rak server lalu semprot pendingin dengan [b][SPASI][/b]. Jangan biarkan suhu menyentuh 90Â°C atau chip rusak permanen![/color]",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "ðŸŒ± ðŸŒ¾ PAK MARNO // KETUA TANI AGRI-DOME",
		"speaker_color": Color(0.40, 0.95, 0.45),
		"raw_text": "AQUA-7, dengarkan kami! Sawah ini adalah tumpuan pangan ratusan keluarga warga.\n[color=#8ce99a][b][TUTORIAL]:[/b] Lari melintasi jembatan ke timur. Semprot petak sawah dengan [b][SPASI][/b] agar kelembapan tanah tetap hijau di atas 30%![/color]",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(0, 65), # Karakter AQUA-7
		"speaker_badge": "âš¡ âš™ï¸ STATUS OPERASIONAL // HARI KE-1",
		"speaker_color": Color(1.0, 0.85, 0.30),
		"raw_text": "[color=#ffe066][b][KONTROL]:[/b] [b][WASD][/b] Gerak â€¢ Tahan [b][SHIFT][/b] Lari Cepat â€¢ [b][SPASI][/b] Siram / Ambil Air.[/color]\nAir melimpah 280L. Waktu 06:00 dimulai. Selamat bertugas, Unit AQUA-7!",
		"prompt": "[SPASI] Mulai Operasi ðŸš€"
	}
]

const SHIFT_1_TO_2_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "ðŸ“¡ TELEMETRI SATELIT // +14 HARI BERLALU",
		"speaker_color": Color(0.15, 0.90, 1.0),
		"raw_text": "[b]HARI KE-1 SELESAI.[/b] +14 Hari telah berlalu (Memasuki 15 Agustus 2049).\nBatch pelatihan model AI DeepBeast 2.0T parameter telah berjalan penuh selama 2 pekan non-stop!",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "ðŸ’§ SENSOR HIDROLOGI // DANAU SURUT",
		"speaker_color": Color(1.0, 0.75, 0.25),
		"raw_text": "Sistem pendingin evaporatif AI menyedot air tanah secara masif. Cadangan danau kini [b]anjlok ke 190 Liter (2.4m)[/b]!\nGaris air surut ~25% dan dasar lumpur mulai retak.",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "ðŸŒ¾ PAK MARNO // LAPORAN KEKERINGAN",
		"speaker_color": Color(0.40, 0.95, 0.45),
		"raw_text": "Gelombang panas musiman mulai membakar daun-daun padi kami! AQUA-7, jangan biarkan seluruh air bersih disedot hanya untuk mesin AI!",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(0, 65), # Robot AQUA-7
		"speaker_badge": "âš¡ âš™ï¸ OPERASI HARI KE-15 // BEBAN MASIF",
		"speaker_color": Color(1.0, 0.85, 0.30),
		"raw_text": "Pemanasan server naik 1.15x dan pengeringan sawah naik 1.10x. Cadangan danau dipangkas ke 190L. Persiapkan nosel pendingin dan pompa sirammu!",
		"prompt": "[SPASI] Masuk Hari ke-15 ðŸš€"
	}
]

const SHIFT_2_TO_3_BEATS: Array[Dictionary] = [
	{
		"camera_target": Vector2(-356, -36), # Mega Server Data Center
		"speaker_badge": "ðŸš¨ ALARM KRITIS // DIRECTIVE ALPHA",
		"speaker_color": Color(1.0, 0.25, 0.25),
		"raw_text": "[b]HARI KE-15 SELESAI.[/b] +15 Hari berlalu (Memasuki 30 Agustus 2049 // Hari ke-30).\nGelombang panas mencapai rekor suhu ekstrem tertinggi! Seluruh klaster superkomputer di ambang meltdown permanen!",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(0, 15), # Danau Tengah
		"speaker_badge": "âš ï¸ SENSOR AKUIFER // DARURAT AIR",
		"speaker_color": Color(1.0, 0.50, 0.20),
		"raw_text": "Pipa suplai regional terputus total! Cadangan danau kini [b]KRITIS HANYA 110 LITER (1.4m)[/b]!\nPalung dalam mengering total dan tanah retak-retak menganga di seluruh dasar danau.",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(336, 0), # Agri-Dome Sawah Warga
		"speaker_badge": "ðŸ¥€ PAK MARNO // JERITAN PETANI",
		"speaker_color": Color(1.0, 0.85, 0.40),
		"raw_text": "Hari ke-30 adalah hari penentuan panen raya! Jika tanaman mati hari ini, ratusan keluarga kami akan kelaparan! Tolong prioritaskan kehidupan bumi!",
		"prompt": "[SPASI] Lanjut â–¸"
	},
	{
		"camera_target": Vector2(0, 65), # Robot AQUA-7
		"speaker_badge": "âš–ï¸ DILEMA ZERO-SUM // HARI KE-30",
		"speaker_color": Color(1.0, 0.85, 0.30),
		"raw_text": "Air 110L tidak lagi cukup untuk mempertahankan kedua sektor secara sempurna. Anda dipaksa berhitung presisi atau memilih sektor mana yang harus dikorbankan!\nKeputusan Anda menentukan masa depan bumi.",
		"prompt": "[SPASI] Hadapi Hari Terakhir âš–ï¸"
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
		objective_icon.text = data.get("icon", "ðŸ’§")
	if objective_dir:
		objective_dir.text = data.get("dir_arrow", "â–º")
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
	if shift_transition_screen:
		shift_transition_screen.visible = false
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
			btn_cheat_god_mode.text = "ðŸ›¡ï¸ KEBAL DURABILITAS: AKTIF (GOD MODE)"
			btn_cheat_god_mode.modulate = Color(0.35, 1.0, 0.5)
		else:
			btn_cheat_god_mode.text = "ðŸ›¡ï¸ KEBAL DURABILITAS: NONAKTIF"
			btn_cheat_god_mode.modulate = Color.WHITE
	
	if btn_cheat_speed:
		if GameManager.dev_time_multiplier == 1.0:
			btn_cheat_speed.text = "âš¡ KECEPATAN WAKTU: 1X (NORMAL)"
			btn_cheat_speed.modulate = Color.WHITE
		elif GameManager.dev_time_multiplier == 5.0:
			btn_cheat_speed.text = "âš¡ KECEPATAN WAKTU: 5X (CEPAT)"
			btn_cheat_speed.modulate = Color(1.0, 0.9, 0.3)
		else:
			btn_cheat_speed.text = "âš¡ KECEPATAN WAKTU: 10X (ULTRA CEPAT)"
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
		clock_label.text = "ðŸ•’ " + clock_info.get("time_str", "06:00") + " (" + clock_info.get("period", "PAGI") + ")"

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
## time_skip_text: misal "+ 14 HARI BERLALU"
## day_text:       misal "HARI KE-15"
## subtitle:       misal "BEBAN KOMPUTASI MASIF"
## desc_line:      satu baris keterangan singkat
## beats:          Array dialog cutscene yang diputar SETELAH layar gelap
## on_done:        Callable yang dieksekusi setelah cutscene selesai
func _play_shift_transition_then_cutscene(
		time_skip_text: String,
		day_text: String,
		subtitle: String,
		desc_line: String,
		beats: Array[Dictionary],
		on_done: Callable) -> void:
	
	# Sembunyikan HUD gameplay dulu
	if top_bar:
		top_bar.visible = false
	if objective_tracker:
		objective_tracker.visible = false
	if bottom_guide:
		bottom_guide.visible = false
	if intermission_screen:
		intermission_screen.visible = false
	
	# Isi teks layar transisi
	if transition_time_skip_label:
		transition_time_skip_label.text = time_skip_text
	if transition_day_label:
		transition_day_label.text = day_text
	if transition_subtitle_label:
		transition_subtitle_label.text = subtitle
	if transition_desc_label:
		transition_desc_label.text = desc_line
	
	# Tampilkan dan fade-in layar hitam transisi
	if shift_transition_screen:
		var vbox: Node = shift_transition_screen.get_node_or_null("VBox")
		if vbox:
			vbox.modulate = Color(1, 1, 1, 0)
		shift_transition_screen.visible = true
		
		# Fade in teks setelah jeda singkat (layar sudah hitam sepenuhnya)
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(shift_transition_screen) and vbox:
			var tween_in: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween_in.tween_property(vbox, "modulate", Color.WHITE, 0.7)
			await tween_in.finished
		
		# Tahan layar transisi selama 2.5 detik agar bisa dibaca
		await get_tree().create_timer(2.5).timeout
		
		# Fade out teks
		if is_instance_valid(shift_transition_screen) and vbox:
			var tween_out: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tween_out.tween_property(vbox, "modulate", Color(1, 1, 1, 0), 0.5)
			await tween_out.finished
	
	# Setelah layar transisi selesai â†’ langsung putar cutscene dialog
	# (layar hitam tetap ada sebagai backdrop â€” cinematic_overlay akan menutupinya)
	if shift_transition_screen:
		shift_transition_screen.visible = false
	
	play_cutscene(beats, on_done, "LEWATI INTRO [ESC]")

func _on_game_finished(ending_code: String, title: String, narrative: String, stats: Dictionary) -> void:
	# PERBAIKAN BUG LOOP: Guard agar tidak dipanggil lebih dari sekali
	if ending_shown:
		return
	ending_shown = true
	
	var beats: Array[Dictionary] = _build_ending_beats(ending_code, title, narrative, stats)
	play_cutscene(beats, func():
		_display_end_screen(ending_code, title, narrative, stats)
	, "LEWATI EPILOG [ESC]")

func _on_water_changed(current: float, max_amount: float) -> void:
	if water_bar:
		water_bar.max_value = max_amount
		water_bar.value = current
		water_bar.modulate = Color(1.0, 0.35, 0.35) if current < 20.0 else Color.WHITE
	if water_label:
		water_label.text = "%d / %dL" % [int(current), int(max_amount)]
		water_label.modulate = Color(1.0, 0.3, 0.3) if current < 20.0 else Color.WHITE

func _on_reservoir_changed(current: float, _max_amount: float) -> void:
	var basin_cap: float = GameManager.TOTAL_BASIN_CAPACITY
	if reservoir_bar:
		reservoir_bar.max_value = basin_cap
		reservoir_bar.value = current
		if current <= 0.0:
			reservoir_bar.modulate = Color(1.0, 0.2, 0.2)
		elif current < 60.0:
			reservoir_bar.modulate = Color(1.0, 0.45, 0.25)
		else:
			reservoir_bar.modulate = Color.WHITE
	if reservoir_label:
		var depth_m: float = (current / basin_cap) * 3.5
		if current <= 0.0:
			reservoir_label.text = "KERING TOTAL (0L | 0.0m)"
			reservoir_label.modulate = Color(1.0, 0.2, 0.2)
		elif current < 60.0:
			reservoir_label.text = "%dL (%.1fm â€¢ KRITIS)" % [int(current), depth_m]
			reservoir_label.modulate = Color(1.0, 0.35, 0.2)
		elif current < 200.0:
			reservoir_label.text = "%dL (%.1fm â€¢ SURUT)" % [int(current), depth_m]
			reservoir_label.modulate = Color(1.0, 0.75, 0.25)
		else:
			reservoir_label.text = "%dL (%.1fm â€¢ PENUH)" % [int(current), depth_m]
			reservoir_label.modulate = Color(0.3, 0.85, 1.0)

func _on_time_tick(seconds_left: int) -> void:
	if timer_label:
		var mins: int = seconds_left / 60
		var secs: int = seconds_left % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		timer_label.modulate = Color(1.0, 0.2, 0.2) if seconds_left <= 15 else Color.WHITE
	
	if clock_label:
		var clock_info: Dictionary = GameManager.get_clock_info()
		clock_label.text = "ðŸ•’ " + clock_info.get("time_str", "06:00") + " (" + clock_info.get("period", "PAGI") + ")"
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
		server_bar.modulate = Color(1.0, 0.25, 0.25) if val <= 25.0 else Color.WHITE
	if server_label:
		server_label.text = "%d%%" % int(val)
		server_label.modulate = Color(1.0, 0.2, 0.2) if val <= 25.0 else Color.WHITE

func _on_food_security_changed(val: float) -> void:
	if food_bar:
		food_bar.value = val
		food_bar.modulate = Color(1.0, 0.3, 0.2) if val <= 30.0 else Color.WHITE
	if food_label:
		food_label.text = "%d%%" % int(val)
		food_label.modulate = Color(1.0, 0.2, 0.2) if val <= 30.0 else Color.WHITE

func _display_end_screen(ending_code: String, title: String, narrative: String, stats: Dictionary) -> void:
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
		"â€¢ Air Dingin Terpakai (Mega AI Server): %d Liter\n" % int(stats.get("servers_used_water", 0)) +
		"â€¢ Air Bersih Terpakai (Sawah Warga): %d Liter\n" % int(stats.get("crops_used_water", 0)) +
		"â€¢ Integritas Server Akhir: %d%%\n" % int(stats.get("server_integrity", 0)) +
		"â€¢ Ketahanan Pangan Akhir: %d%%" % int(stats.get("food_security", 0))
	)
	end_moral.text = "Tema Grafika Gametastic 2026: Save the Earth. Setiap tetes air pendingin komputasi di dunia nyata diambil dari hak alam dan kehidupan sekitar. Bisakah manusia dan teknologi tumbuh berdampingan secara bijak?"

func _build_ending_beats(ending_code: String, _title: String, _narrative: String, stats: Dictionary) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	var s_integ: int = int(stats.get("server_integrity", 0))
	var f_sec: int = int(stats.get("food_security", 0))
	
	match ending_code:
		"HARMONY":
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "ðŸ–¥ï¸ DEEPBEAST-2.0T // TELEMETRI STABIL",
				"speaker_color": Color(0.2, 0.9, 1.0),
				"raw_text": "Integritas server terjaga pada [b]%d%%[/b]. Model AI 2.0T parameter berhasil dilatih dengan efisiensi energi hijau!" % s_integ,
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "ðŸŒ¾ PAK MARNO // AIR MATA HARU",
				"speaker_color": Color(0.3, 1.0, 0.4),
				"raw_text": "Ketahanan pangan warga bertahan pada [b]%d%%[/b]! Panen raya berhasil dipetik. Terima kasih AQUA-7, kamu membuktikan manusia dan mesin bisa hidup berdampingan!" % f_sec,
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "âœ¨ EPILOG: KESEIMBANGAN RAPUH (TRUE ENDING)",
				"speaker_color": Color(1.0, 0.85, 0.30),
				"raw_text": "Melalui kalkulasi presisi mikroliter, Unit AQUA-7 menyelamatkan bumi dan masa depan peradaban sekaligus.\nSebuah bukti abadi: [b]Kemajuan teknologi tidak harus membunuh bumi tempatnya berpijak.[/b]",
				"prompt": "[SPASI] Lihat Statistik ðŸ“Š"
			})
		"ORGANIC":
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "ðŸŒ¾ PAK MARNO // SUJUD SYUKUR",
				"speaker_color": Color(0.4, 0.9, 0.5),
				"raw_text": "Sawah pangan warga terselamatkan ([b]%d%%[/b])! Ratusan keluarga petani tersenyum menyambut masa depan tanpa ancaman kelaparan.",
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "ðŸ–¥ï¸ DEEPBEAST-2.0T // DAYA MATI",
				"speaker_color": Color(1.0, 0.3, 0.3),
				"raw_text": "Data center padam dan server mengalami kerusakan chip ([b]%d%%[/b]). Korporasi merugi, namun nurani kehidupan telah dimenangkan.",
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "ðŸŒ± EPILOG: NURANI ORGANIK",
				"speaker_color": Color(0.4, 1.0, 0.4),
				"raw_text": "Unit AQUA-7 melanggar algoritma korporasi demi mengalirkan sisa air terakhir ke kehidupan.\n[b]Logika mesin tunduk pada nurani kehidupan.[/b]",
				"prompt": "[SPASI] Lihat Statistik ðŸ“Š"
			})
		"SILICON":
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "ðŸ–¥ï¸ DEEPBEAST-2.0T // DOMINASI MUTLAK",
				"speaker_color": Color(0.2, 0.85, 1.0),
				"raw_text": "Integritas superkomputer prima ([b]%d%%[/b])! Model AI 2.0T parameter lahir dengan sempurna, memproses miliaran token per detik.",
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "ðŸ¥€ TANAH TANDUS // GURUN SILIKON",
				"speaker_color": Color(0.9, 0.6, 0.3),
				"raw_text": "Seluruh tanaman pangan mati kering ([b]%d%%[/b]). Tanah pertanian retak menjadi gurun abu dan para petani terpaksa mengungsi.",
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "ðŸ¤– EPILOG: GURUN SILIKON",
				"speaker_color": Color(0.3, 0.85, 1.0),
				"raw_text": "Kecerdasan buatan paling mutakhir di dunia kini berpikir tanpa henti di atas tanah tandus...\n[b]di mana tak ada lagi manusia yang tersisa untuk menikmatinya.[/b]",
				"prompt": "[SPASI] Lihat Statistik ðŸ“Š"
			})
		_: # TOTAL_COLLAPSE
			beats.append({
				"camera_target": Vector2(-356, -36),
				"speaker_badge": "â˜ ï¸ KONTROL ALARM // KEGAGALAN SISTEM",
				"speaker_color": Color(1.0, 0.2, 0.2),
				"raw_text": "Data center terbakar dan seluruh rak server hancur berkeping-keping karena panas berlebih!",
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(336, 0),
				"speaker_badge": "â˜ ï¸ TANAH MATI // GAGAL TOTAL",
				"speaker_color": Color(1.0, 0.2, 0.2),
				"raw_text": "Tanaman pangan puso dan mati kekeringan sebelum waktu panen tiba.",
				"prompt": "[SPASI] Lanjut â–¸"
			})
			beats.append({
				"camera_target": Vector2(0, 65),
				"speaker_badge": "â˜ ï¸ EPILOG: BENCANA EKOLOGI TOTAL",
				"speaker_color": Color(1.0, 0.2, 0.2),
				"raw_text": "Ketidakmampuan mengelola air mengakibatkan keruntuhan total ekosistem.\n[b]Peradaban kehilangan teknologi dan pangannya sekaligus.[/b]",
				"prompt": "[SPASI] Lihat Statistik ðŸ“Š"
			})
	
	return beats

# ==============================================================================
# CINEMATIC CUTSCENE & DIALOGUE CONTROLLER
# ==============================================================================

func start_prologue_cutscene() -> void:
	play_cutscene(PROLOGUE_BEATS, Callable(), "LEWATI PROLOG [ESC]")

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
		advance_prompt.text = beat.get("prompt", "[SPASI] Lanjut â–¸")
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
	_finish_active_cutscene()

func _finish_active_cutscene() -> void:
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
	
	var cb: Callable = on_cutscene_complete_callable
	on_cutscene_complete_callable = Callable()
	if cb.is_valid():
		cb.call()


