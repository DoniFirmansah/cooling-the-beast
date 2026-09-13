@tool
extends StaticBody2D
class_name EcoTree

const TEX_OAK = preload("res://assets/environment/farmland/oak_tree_large.png")
const TEX_PINE = preload("res://assets/environment/farmland/pine_tree_large.png")
const TEX_BUSHY = preload("res://assets/environment/farmland/tree_bushy_large.png")

@export_enum("oak", "pine", "bushy") var tree_type: String = "oak":
	set(val):
		tree_type = val
		if is_node_ready():
			_setup_variant()

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $GroundShadow
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	y_sort_enabled = true
	_setup_variant()
	if not Engine.is_editor_hint():
		GameManager.shift_started.connect(_on_shift_started)
		_apply_shift_visuals(GameManager.current_shift, false)

func _setup_variant() -> void:
	if not sprite:
		return
	match tree_type:
		"pine":
			sprite.texture = TEX_PINE
			sprite.position = Vector2(0, -62)
			if collision:
				collision.position = Vector2(0, -4)
			if shadow:
				shadow.scale = Vector2(1.2, 0.7)
		"bushy":
			sprite.texture = TEX_BUSHY
			sprite.position = Vector2(0, -56)
			if collision:
				collision.position = Vector2(0, -4)
			if shadow:
				shadow.scale = Vector2(1.1, 0.6)
		_:
			sprite.texture = TEX_OAK
			sprite.position = Vector2(0, -64)
			if collision:
				collision.position = Vector2(0, -4)
			if shadow:
				shadow.scale = Vector2(1.4, 0.8)

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_visuals(shift_num, true)

func _apply_shift_visuals(shift_num: int, animate: bool) -> void:
	var target_color: Color = Color.WHITE
	match shift_num:
		1:
			target_color = Color(1.0, 1.0, 1.0) # Lush verdant green
		2:
			target_color = Color(0.92, 0.82, 0.52) # Dry yellowish-amber
		3:
			target_color = Color(0.55, 0.42, 0.32) # Charred drought brown
	
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", target_color, 2.0)
	else:
		sprite.modulate = target_color

