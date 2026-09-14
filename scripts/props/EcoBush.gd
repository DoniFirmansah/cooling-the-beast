@tool
extends Area2D
class_name EcoBush

const TEX_BUSH = preload("res://assets/environment/farmland/bush_large.png")
const SFX_RUSTLING: AudioStream = preload("res://assets/audio/sfx/sfx_bush_rustling.mp3")

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $GroundShadow

var rustle_tween: Tween
var rustle_sfx: AudioStreamPlayer2D
var _bodies_inside: int = 0
var _rustle_repeat_timer: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		_setup_ground_shadow()
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		GameManager.shift_started.connect(_on_shift_started)
		_apply_shift_visuals(GameManager.current_shift, false)

		# SFX rustling saat player menabrak / melewati bush
		rustle_sfx = AudioStreamPlayer2D.new()
		rustle_sfx.stream = SFX_RUSTLING
		rustle_sfx.bus = &"Master"
		rustle_sfx.volume_db = -6.0
		rustle_sfx.max_distance = 500.0
		add_child(rustle_sfx)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Re-trigger rustle + SFX secara berkala selama masih ada yang bergerak di dalam bush
	if _bodies_inside > 0:
		_rustle_repeat_timer -= delta
		if _rustle_repeat_timer <= 0.0:
			var mover: Node2D = _get_moving_body()
			if mover != null:
				_rustle_repeat_timer = 0.65
				_play_rustle()
				_play_rustle_sfx(mover.global_position)
	else:
		_rustle_repeat_timer = 0.0

func _get_moving_body() -> Node2D:
	for b in get_overlapping_bodies():
		if b is Node2D and b.velocity.length_squared() > 25.0:
			return b
	return null

func _setup_ground_shadow() -> void:
	if not Engine.is_editor_hint():
		var shadows_group: Node = get_tree().get_first_node_in_group("ground_shadows")
		if shadows_group:
			for sh in [shadow, get_node_or_null("GroundShadow2")]:
				if sh:
					var gp: Vector2 = sh.global_position
					sh.get_parent().remove_child(sh)
					shadows_group.add_child(sh)
					sh.global_position = gp

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_slow_effect"):
		body.add_slow_effect(0.55)
		_bodies_inside += 1
		_play_rustle()
		_play_rustle_sfx(body.global_position)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("remove_slow_effect"):
		body.remove_slow_effect()
		_bodies_inside = max(0, _bodies_inside - 1)

func _play_rustle_sfx(at_pos: Vector2) -> void:
	if rustle_sfx:
		rustle_sfx.global_position = at_pos
		rustle_sfx.pitch_scale = randf_range(0.9, 1.1)
		if not rustle_sfx.playing:
			rustle_sfx.play()

func _play_rustle() -> void:
	if not sprite:
		return
	if rustle_tween and rustle_tween.is_valid():
		rustle_tween.kill()
	
	rustle_tween = create_tween()
	rustle_tween.tween_property(sprite, "rotation", 0.08, 0.08)
	rustle_tween.tween_property(sprite, "rotation", -0.08, 0.08)
	rustle_tween.tween_property(sprite, "rotation", 0.04, 0.06)
	rustle_tween.tween_property(sprite, "rotation", 0.0, 0.06)

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_visuals(shift_num, true)

func _apply_shift_visuals(shift_num: int, animate: bool) -> void:
	var target_color: Color = Color.WHITE
	match shift_num:
		1:
			target_color = Color(1.0, 1.0, 1.0)
		2:
			target_color = Color(0.92, 0.78, 0.46)
		3:
			target_color = Color(0.42, 0.30, 0.24)
	
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", target_color, 2.0)
	else:
		sprite.modulate = target_color

