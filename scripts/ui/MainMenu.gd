extends Control
class_name MainMenu

const SFX_CLICK = preload("res://assets/audio/sfx/click_001.ogg")

@onready var btn_start: Button = %BtnStart
@onready var btn_load: Button = %BtnLoad
@onready var btn_collection: Button = %BtnCollection
@onready var btn_exit: Button = %BtnExit

# Collection Modal & Cards
@onready var collection_modal: Control = %CollectionModal
@onready var btn_close_collection: Button = %BtnCloseCollection

@onready var card_harmony: PanelContainer = %CardHarmony
@onready var card_organic: PanelContainer = %CardOrganic
@onready var card_silicon: PanelContainer = %CardSilicon
@onready var card_collapse: PanelContainer = %CardCollapse

var audio_player: AudioStreamPlayer

func _ready() -> void:
	collection_modal.visible = false
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = &"Master"
	add_child(audio_player)
	
	btn_start.pressed.connect(_on_start_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_collection.pressed.connect(_on_collection_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_close_collection.pressed.connect(_on_close_collection_pressed)
	
	_update_load_button()

func _update_load_button() -> void:
	GameManager.load_save_file()
	if GameManager.saved_shift > 1:
		btn_load.disabled = false
		btn_load.text = "LOAD (LANJUTKAN SHIFT %d)" % GameManager.saved_shift
	else:
		btn_load.disabled = false
		btn_load.text = "LOAD GAME (SHIFT 1)"

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

func _on_exit_pressed() -> void:
	_play_sfx(SFX_CLICK)
	if OS.has_feature("web"):
		btn_exit.text = "TERIMA KASIH TELAH BERMAIN!"
	else:
		get_tree().quit()

func _populate_collection() -> void:
	GameManager.load_save_file()
	_render_ending_card(card_harmony, "HARMONY", "⚖️ ENDING 1: KESEIMBANGAN RAPUH", "Melalui kalkulasi presisi mikroliter, Unit AQUA-7 mempertahankan kedua sektor. Manusia dan kecerdasan buatan bertahan hidup berdampingan.", Color(0.3, 0.9, 0.5))
	_render_ending_card(card_organic, "ORGANIC", "🌿 ENDING 2: NURANI ORGANIK", "Unit AQUA-7 melanggar direktif demi sawah warga. Model AI gagal, namun ratusan keluarga petani selamat dari kelaparan.", Color(0.4, 0.85, 0.4))
	_render_ending_card(card_silicon, "SILICON", "⚡ ENDING 3: GURUN SILIKON", "Mega server berhasil didinginkan, namun sawah warga mati menjadi debu tandus. AI tercerdas berpikir di bumi yang kelaparan.", Color(0.3, 0.8, 1.0))
	_render_ending_card(card_collapse, "TOTAL_COLLAPSE", "💀 ENDING: BENCANA EKOLOGI TOTAL", "Waduk habis terlalu cepat. Server AI terbakar hangus dan sawah mati total dalam kekeringan.", Color(0.9, 0.3, 0.3))

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
			badge_node.modulate = Color(0.4, 1.0, 0.5)
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
