@tool
extends Area2D
class_name EcoBush

const TEX_BUSH = preload("res://assets/environment/farmland/bush_large.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $GroundShadow

var rustle_tween: Tween

func _ready() -> void:
	if not Engine.is_editor_hint():
		_setup_ground_shadow()
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		GameManager.shift_started.connect(_on_shift_started)
		_apply_shift_visuals(GameManager.current_shift, false)

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
		_play_rustle()

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("remove_slow_effect"):
		body.remove_slow_effect()

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

