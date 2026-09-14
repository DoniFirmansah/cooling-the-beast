@tool
extends StaticBody2D
class_name EcoTree

const TEX_OAK = preload("res://assets/environment/farmland/oak_tree_large.png")
const TEX_PINE = preload("res://assets/environment/farmland/pine_tree_large.png")
const TEX_BUSHY = preload("res://assets/environment/farmland/tree_bushy_large.png")

const SHADOW_OAK = preload("res://assets/environment/farmland/oak_tree_shadow.png")
const SHADOW_PINE = preload("res://assets/environment/farmland/pine_tree_shadow.png")
const SHADOW_BUSHY = preload("res://assets/environment/farmland/tree_bushy_shadow.png")

@export_enum("oak", "pine", "bushy") var tree_type: String = "oak":
	set(val):
		tree_type = val
		if is_node_ready():
			_setup_variant()

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $GroundShadow
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var canopy_area: Area2D = $CanopyArea

var current_shift_color: Color = Color.WHITE
var is_canopy_occluding: bool = false
var fade_tween: Tween

func _ready() -> void:
	_setup_variant()
	if not Engine.is_editor_hint():
		_setup_ground_shadow()
		_setup_canopy_area()
		GameManager.shift_started.connect(_on_shift_started)
		_apply_shift_visuals(GameManager.current_shift, false)

func _setup_ground_shadow() -> void:
	if shadow and not Engine.is_editor_hint():
		var shadows_group: Node = get_tree().get_first_node_in_group("ground_shadows")
		if shadows_group:
			var global_p: Vector2 = shadow.global_position
			shadow.get_parent().remove_child(shadow)
			shadows_group.add_child(shadow)
			shadow.global_position = global_p

func _setup_canopy_area() -> void:
	if canopy_area and not Engine.is_editor_hint():
		canopy_area.body_entered.connect(_on_canopy_body_entered)
		canopy_area.body_exited.connect(_on_canopy_body_exited)

func _on_canopy_body_entered(body: Node2D) -> void:
	if body.has_method("set_occluded"):
		body.set_occluded(true)
		is_canopy_occluding = true
		_update_canopy_alpha(0.42)

func _on_canopy_body_exited(body: Node2D) -> void:
	if body.has_method("set_occluded"):
		body.set_occluded(false)
		is_canopy_occluding = false
		_update_canopy_alpha(1.0)

func _update_canopy_alpha(target_alpha: float) -> void:
	if not sprite:
		return
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	var target_col: Color = current_shift_color
	target_col.a = target_alpha
	fade_tween.tween_property(sprite, "modulate", target_col, 0.22)

func _setup_variant() -> void:
	if not sprite:
		return
	match tree_type:
		"pine":
			sprite.texture = TEX_PINE
			sprite.position = Vector2(0, -68)
			if shadow:
				shadow.texture = SHADOW_PINE
				shadow.position = Vector2(0, -68)
				shadow.scale = Vector2.ONE
			if collision:
				collision.position = Vector2(0, -4)
		"bushy":
			sprite.texture = TEX_BUSHY
			sprite.position = Vector2(0, -68)
			if shadow:
				shadow.texture = SHADOW_BUSHY
				shadow.position = Vector2(0, -68)
				shadow.scale = Vector2.ONE
			if collision:
				collision.position = Vector2(0, -4)
		_:
			sprite.texture = TEX_OAK
			sprite.position = Vector2(0, -68)
			if shadow:
				shadow.texture = SHADOW_OAK
				shadow.position = Vector2(0, -68)
				shadow.scale = Vector2.ONE
			if collision:
				collision.position = Vector2(0, -4)

func _on_shift_started(shift_num: int, _title: String) -> void:
	_apply_shift_visuals(shift_num, true)

func _apply_shift_visuals(shift_num: int, animate: bool) -> void:
	match shift_num:
		1:
			current_shift_color = Color(1.0, 1.0, 1.0)
		2:
			current_shift_color = Color(0.92, 0.78, 0.46)
		3:
			current_shift_color = Color(0.42, 0.30, 0.24)
	
	var final_color: Color = current_shift_color
	final_color.a = 0.42 if is_canopy_occluding else 1.0
	
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", final_color, 2.0)
	else:
		sprite.modulate = final_color



