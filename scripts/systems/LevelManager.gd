extends Node2D
class_name LevelManager

@onready var hud: CanvasLayer = $HUD
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

func _ready() -> void:
	GameManager.reset_state()
	_setup_audio()

func _setup_audio() -> void:
	if bgm_player and bgm_player.stream:
		bgm_player.play()
