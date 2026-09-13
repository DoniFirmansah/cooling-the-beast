extends StaticBody2D
class_name WaterStation

const SFX_REFILL = preload("res://assets/audio/sfx/switch_001.ogg")

@export var refill_rate: float = 65.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var bubble_particles: CPUParticles2D = $BubbleParticles
@onready var prompt_label: Label = $PromptLabel
@onready var area: Area2D = $InteractionArea

var refill_audio: AudioStreamPlayer2D
var is_targeted: bool = false
var was_interacted_this_frame: bool = false

func _ready() -> void:
	y_sort_enabled = true
	bubble_particles.emitting = false
	prompt_label.visible = false
	
	refill_audio = AudioStreamPlayer2D.new()
	refill_audio.stream = SFX_REFILL
	refill_audio.bus = &"Master"
	add_child(refill_audio)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not was_interacted_this_frame:
		bubble_particles.emitting = false
	was_interacted_this_frame = false
	
	if prompt_label.visible or is_targeted:
		prompt_label.visible = true
		if GameManager.current_water >= GameManager.MAX_WATER:
			prompt_label.text = "TANGKI PENUH"
			prompt_label.modulate = Color(0.4, 1.0, 0.4)
		else:
			prompt_label.text = "TAHAN [SPASI] ISI AIR"
			prompt_label.modulate = Color(0.3, 0.85, 1.0)
	else:
		prompt_label.visible = false

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	if is_targeted:
		sprite.modulate = Color(1.3, 1.3, 1.3)
	else:
		sprite.modulate = Color.WHITE

func interact_tick(delta: float, _player: Node) -> bool:
	if GameManager.current_water >= GameManager.MAX_WATER:
		bubble_particles.emitting = false
		return false
	
	was_interacted_this_frame = true
	GameManager.refill_water(refill_rate * delta)
	bubble_particles.emitting = true
	if refill_audio and not refill_audio.playing:
		refill_audio.play()
	return true

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		prompt_label.visible = false
		bubble_particles.emitting = false


