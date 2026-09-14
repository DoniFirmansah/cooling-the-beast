extends Control
class_name MainMenu

const SFX_CLICK = preload("res://assets/audio/sfx/click_001.ogg")
const SFX_SELECT = preload("res://assets/audio/sfx/select_001.ogg")

@onready var btn_start: Button = %BtnStart
@onready var btn_load: Button = %BtnLoad
@onready var btn_collection: Button = %BtnCollection
@onready var btn_guide: Button = %BtnGuide
@onready var btn_exit: Button = %BtnExit

# Collection Modal & Cards
@onready var collection_modal: Control = %CollectionModal
@onready var btn_close_collection: Button = %BtnCloseCollection

# Guide Modal
@onready var guide_modal: Control = %GuideModal
@onready var btn_close_guide: Button = %BtnCloseGuide

@onready var card_harmony: PanelContainer = %CardHarmony
@onready var card_organic: PanelContainer = %CardOrganic
@onready var card_silicon: PanelContainer = %CardSilicon
@onready var card_collapse: PanelContainer = %CardCollapse

@onready var server_a_leds: Sprite2D = %ServerClusterALeds if has_node("%ServerClusterALeds") else null
@onready var server_b_leds: Sprite2D = %ServerClusterBLeds if has_node("%ServerClusterBLeds") else null
@onready var water_surface: Sprite2D = %WaterSurface if has_node("%WaterSurface") else null

var audio_player: AudioStreamPlayer
var ambient_time: float = 0.0

func _ready() -> void:
	collection_modal.visible = false
	guide_modal.visible = false
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = &"Master"
	add_child(audio_player)
	
	btn_start.pressed.connect(_on_start_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_collection.pressed.connect(_on_collection_pressed)
	btn_guide.pressed.connect(_on_guide_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_close_collection.pressed.connect(_on_close_collection_pressed)
	btn_close_guide.pressed.connect(_on_close_guide_pressed)
	
	for btn in [btn_start, btn_load, btn_collection, btn_guide, btn_exit, btn_close_collection, btn_close_guide]:
		if btn:
			btn.mouse_entered.connect(func(): _play_sfx(SFX_SELECT))
	
	_update_load_button()

func _process(delta: float) -> void:
	ambient_time += delta
	if server_a_leds and is_instance_valid(server_a_leds):
		server_a_leds.modulate.a = 0.65 + 0.35 * sin(ambient_time * 3.2)
	if server_b_leds and is_instance_valid(server_b_leds):
		server_b_leds.modulate.a = 0.65 + 0.35 * cos(ambient_time * 2.6)
	if water_surface and is_instance_valid(water_surface):
		water_surface.position.y = sin(ambient_time * 2.0) * 1.5


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if collection_modal.visible:
			_on_close_collection_pressed()
			get_viewport().set_input_as_handled()
		elif guide_modal.visible:
			_on_close_guide_pressed()
			get_viewport().set_input_as_handled()

func _update_load_button() -> void:
	GameManager.load_save_file()
	var load_lbl: Label = btn_load.get_node_or_null("Margin/HBox/Text")
	if GameManager.saved_shift > 1:
		btn_load.disabled = false
		if load_lbl:
			load_lbl.text = "CONTINUE (SHIFT %d)" % GameManager.saved_shift
		else:
			btn_load.text = "CONTINUE (SHIFT %d)" % GameManager.saved_shift
	else:
		btn_load.disabled = false
		if load_lbl:
			load_lbl.text = "CONTINUE"
		else:
			btn_load.text = "CONTINUE"

func _play_sfx(stream: AudioStream) -> void:
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.play()

func _on_start_pressed() -> void:
	_play_sfx(SFX_CLICK)
	GameManager.start_new_game_from_menu()

func _on_load_pressed() -> void:
	_play_sfx(SFX_CLICK)
	GameManager.start_loaded_game()

func _on_collection_pressed() -> void:
	_play_sfx(SFX_CLICK)
	_populate_collection()
	collection_modal.visible = true

func _on_close_collection_pressed() -> void:
	_play_sfx(SFX_CLICK)
	collection_modal.visible = false

func _on_guide_pressed() -> void:
	_play_sfx(SFX_CLICK)
	guide_modal.visible = true

func _on_close_guide_pressed() -> void:
	_play_sfx(SFX_CLICK)
	guide_modal.visible = false

func _on_exit_pressed() -> void:
	_play_sfx(SFX_CLICK)
	if OS.has_feature("web"):
		var exit_lbl: Label = btn_exit.get_node_or_null("Margin/HBox/Text")
		if exit_lbl:
			exit_lbl.text = "TERIMA KASIH TELAH BERMAIN!"
		else:
			btn_exit.text = "TERIMA KASIH TELAH BERMAIN!"
	else:
		get_tree().quit()

func _populate_collection() -> void:
	GameManager.load_save_file()
	_render_ending_card(card_harmony, "HARMONY", "⚖️ ENDING 1: KESEIMBANGAN RAPUH", "Melalui kalkulasi presisi mikroliter, Unit AQUA-7 mempertahankan kedua sektor. Manusia dan kecerdasan buatan bertahan hidup berdampingan.", Color(0.42, 0.80, 0.58))
	_render_ending_card(card_organic, "ORGANIC", "🌿 ENDING 2: NURANI ORGANIK", "Unit AQUA-7 melanggar direktif demi sawah warga. Model AI gagal, namun ratusan keluarga petani selamat dari kelaparan.", Color(0.50, 0.75, 0.50))
	_render_ending_card(card_silicon, "SILICON", "⚡ ENDING 3: GURUN SILIKON", "Mega server berhasil didinginkan, namun sawah warga mati menjadi debu tandus. AI tercerdas berpikir di bumi yang kelaparan.", Color(0.42, 0.65, 0.85))
	_render_ending_card(card_collapse, "TOTAL_COLLAPSE", "💀 ENDING: BENCANA EKOLOGI TOTAL", "Waduk habis terlalu cepat. Server AI terbakar hangus dan sawah mati total dalam kekeringan.", Color(0.85, 0.40, 0.38))

func _render_ending_card(card: PanelContainer, code: String, title_text: String, desc_text: String, accent_color: Color) -> void:
	if not card:
		return
	var is_unlocked: bool = GameManager.is_ending_unlocked(code)
	var title_node: Label = card.get_node_or_null("MarginContainer/VBoxContainer/Title")
	var desc_node: Label = card.get_node_or_null("MarginContainer/VBoxContainer/Desc")
	var badge_node: Label = card.get_node_or_null("MarginContainer/VBoxContainer/Badge")
	
	if is_unlocked:
		card.modulate = Color(1, 1, 1, 1)
		if title_node:
			title_node.text = title_text
			title_node.modulate = accent_color
		if desc_node:
			desc_node.text = desc_text
			desc_node.modulate = Color(0.9, 0.95, 1, 1)
		if badge_node:
			badge_node.text = "STATUS: TERBUKA [ARCHIVED]"
			badge_node.modulate = Color(0.52, 0.78, 0.60)
	else:
		card.modulate = Color(0.22, 0.22, 0.26, 0.75)
		if title_node:
			title_node.text = "🔒 ??? [ARSIP TERKUNCI]"
			title_node.modulate = Color(0.5, 0.5, 0.5)
		if desc_node:
			desc_node.text = "Capai keputusan hidrologis di Shift 3 untuk membuka rekaman arsip masa depan ini."
			desc_node.modulate = Color(0.4, 0.4, 0.45)
		if badge_node:
			badge_node.text = "STATUS: BELUM DIDAPATKAN"
			badge_node.modulate = Color(0.5, 0.3, 0.3)
