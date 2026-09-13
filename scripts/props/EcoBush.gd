@tool
extends StaticBody2D
class_name EcoBush

const TEX_BUSH = preload("res://assets/environment/farmland/bush_large.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $GroundShadow
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	y_sort_enabled = true
	if not Engine.is_editor_hint():
		GameManager.shift_started.connect(_on_shift_started)
		_apply_shift_visuals(GameManager.current_shift, false)

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_visuals(shift_num, true)

func _apply_shift_visuals(shift_num: int, animate: bool) -> void:
	var target_color: Color = Color.WHITE
	match shift_num:
		1:
			target_color = Color(1.0, 1.0, 1.0)
		2:
			target_color = Color(0.92, 0.82, 0.52)
		3:
			target_color = Color(0.55, 0.42, 0.32)
	
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", target_color, 2.0)
	else:
		sprite.modulate = target_color
