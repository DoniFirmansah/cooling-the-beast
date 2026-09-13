extends CanvasLayer

const SFX_CLICK = preload("res://assets/audio/sfx/click_001.ogg")
const SFX_WIN = preload("res://assets/audio/sfx/confirmation_001.ogg")
const SFX_FAIL = preload("res://assets/audio/sfx/error_001.ogg")

@onready var water_bar: ProgressBar = %WaterBar
@onready var water_label: Label = %WaterLabel
@onready var timer_label: Label = %TimerLabel
@onready var server_bar: ProgressBar = %ServerBar
@onready var server_label: Label = %ServerLabel
@onready var food_bar: ProgressBar = %FoodBar
@onready var food_label: Label = %FoodLabel

@onready var end_screen: Control = %EndScreen
@onready var end_title: Label = %EndTitle
@onready var end_reason: Label = %EndReason
@onready var end_stats: Label = %EndStats
@onready var end_moral: Label = %EndMoral
@onready var btn_restart: Button = %BtnRestart

@onready var pause_screen: Control = %PauseScreen
@onready var btn_resume: Button = %BtnResume
@onready var btn_pause_restart: Button = %BtnPauseRestart

var audio_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	end_screen.visible = false
	pause_screen.visible = false
	
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = &"Master"
	add_child(audio_player)
	
	GameManager.water_changed.connect(_on_water_changed)
	GameManager.food_security_changed.connect(_on_food_security_changed)
	GameManager.server_integrity_changed.connect(_on_server_integrity_changed)
	GameManager.time_tick.connect(_on_time_tick)
	GameManager.game_finished.connect(_on_game_finished)
	
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_pause_restart.pressed.connect(_on_restart_pressed)
	
	_on_water_changed(GameManager.current_water, GameManager.MAX_WATER)
	_on_food_security_changed(GameManager.food_security)
	_on_server_integrity_changed(GameManager.server_integrity)
	_on_time_tick(int(GameManager.SHIFT_DURATION))

func _play_sfx(stream: AudioStream) -> void:
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not end_screen.visible:
			_toggle_pause()

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

func _on_water_changed(current: float, max_amount: float) -> void:
	if water_bar:
		water_bar.max_value = max_amount
		water_bar.value = current
	if water_label:
		water_label.text = "%d / %dL" % [int(current), int(max_amount)]
		if current < 20.0:
			water_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			water_label.modulate = Color.WHITE

func _on_time_tick(seconds_left: int) -> void:
	if timer_label:
		var mins: int = seconds_left / 60
		var secs: int = seconds_left % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		if seconds_left <= 15:
			timer_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			timer_label.modulate = Color.WHITE

func _on_server_integrity_changed(val: float) -> void:
	if server_bar:
		server_bar.value = val
	if server_label:
		server_label.text = "%d%%" % int(val)
		if val <= 25.0:
			server_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			server_label.modulate = Color.WHITE

func _on_food_security_changed(val: float) -> void:
	if food_bar:
		food_bar.value = val
	if food_label:
		food_label.text = "%d%%" % int(val)
		if val <= 25.0:
			food_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			food_label.modulate = Color.WHITE

func _on_game_finished(victory: bool, reason: String, stats: Dictionary) -> void:
	get_tree().paused = true
	end_screen.visible = true
	
	if victory:
		_play_sfx(SFX_WIN)
		end_title.text = "BERHASIL: KESEIMBANGAN TERJAGA!"
		end_title.modulate = Color(0.3, 1.0, 0.4)
	else:
		_play_sfx(SFX_FAIL)
		end_title.text = "GAGAL: EKOSISTEM RUNTUH!"
		end_title.modulate = Color(1.0, 0.2, 0.2)
	
	end_reason.text = reason
	
	end_stats.text = (
		"STATISTIK AIR & SUMBER DAYA:\n" +
		"• Air Dingin Terpakai (AI Server): %d Liter\n" % int(stats.get("servers_used_water", 0)) +
		"• Air Bersih Terpakai (Sawah): %d Liter\n" % int(stats.get("crops_used_water", 0)) +
		"• Sisa Integritas AI: %d%%\n" % int(stats.get("server_integrity", 0)) +
		"• Sisa Ketahanan Pangan: %d%%" % int(stats.get("food_security", 0))
	)
	
	if victory:
		end_moral.text = "Pesan Lingkungan: Melatih model kecerdasan buatan menyerap jutaan liter air tawar. Kamu membuktikan bahwa dengan pembagian sumber daya yang bijak, teknologi masa depan tidak harus mengorbankan lumbung pangan dan kehidupan bumi."
	else:
		end_moral.text = "Pesan Lingkungan: Krisis air di kawasan industri AI nyata terjadi. Ketika pendinginan komputasi mengabaikan kebutuhan agrikultur, bumi menanggung bencana kekeringan yang tak terbalikkan."

