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
		if GameManager.reservoir_water <= 0.0:
			prompt_label.text = "⚠️ WADUK HABIS! (0L)"
			prompt_label.modulate = Color(1.0, 0.25, 0.25)
		elif GameManager.current_water >= GameManager.MAX_BACKPACK_WATER:
			prompt_label.text = "TANGKI PENUH (%dL SISA)" % int(GameManager.reservoir_water)
			prompt_label.modulate = Color(0.4, 1.0, 0.4)
		else:
			prompt_label.text = "[SPASI] ISI AIR (%dL)" % int(GameManager.reservoir_water)
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
	if GameManager.current_water >= GameManager.MAX_BACKPACK_WATER or GameManager.reservoir_water <= 0.0:
		bubble_particles.emitting = false
		return false
	
	was_interacted_this_frame = true
	var success: bool = GameManager.refill_water(refill_rate * delta)
	if success:
		bubble_particles.emitting = true
		if refill_audio and not refill_audio.playing:
			refill_audio.play()
		return true
	else:
		bubble_particles.emitting = false
		return false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		prompt_label.visible = false
		bubble_particles.emitting = false


