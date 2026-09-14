extends Node2D
class_name GrassTuft

@export_enum("grass_1", "grass_2", "grass_3", "grass_4", "flower_red", "flower_yellow", "flower_white", "bush_small") var tuft_type: String = "grass_1"
@export var enable_wind_sway: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

const TEXTURES: Dictionary = {
	"grass_1": preload("res://assets/environment/farmland/grass_01.png"),
	"grass_2": preload("res://assets/environment/farmland/grass_02.png"),
	"grass_3": preload("res://assets/environment/farmland/grass_03.png"),
	"grass_4": preload("res://assets/environment/farmland/grass_04.png"),
	"flower_red": preload("res://assets/environment/farmland/flower_red_01.png"),
	"flower_yellow": preload("res://assets/environment/farmland/flower_yellow_01.png"),
	"flower_white": preload("res://assets/environment/farmland/flower_white_01.png"),
	"bush_small": preload("res://assets/environment/farmland/bush_small_flowers.png"),
}

var sway_tween: Tween
var is_rustling: bool = false

func _ready() -> void:
	y_sort_enabled = true
	if sprite and TEXTURES.has(tuft_type):
		sprite.texture = TEXTURES[tuft_type]
		var h: float = float(sprite.texture.get_height())
		sprite.offset = Vector2(0, -h * 0.5)
	
	if area:
		area.body_entered.connect(_on_body_entered)
	
	if enable_wind_sway:
		_start_wind_sway()

func _start_wind_sway() -> void:
	var delay: float = randf_range(0.0, 1.8)
	var sway_dur: float = randf_range(1.6, 2.4)
	var sway_angle: float = deg_to_rad(randf_range(4.0, 7.0))
	
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or not is_instance_valid(sprite):
		return
	
	sway_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway_tween.tween_property(sprite, "rotation", sway_angle, sway_dur * 0.5)
	sway_tween.tween_property(sprite, "rotation", -sway_angle, sway_dur * 0.5)

func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	if is_rustling or not is_instance_valid(sprite):
		return
	is_rustling = true
	
	var lean_dir: float = sign(body.velocity.x) if abs(body.velocity.x) > 5.0 else 1.0
	var rustle_tween: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	rustle_tween.tween_property(sprite, "scale", Vector2(1.25, 0.8), 0.08)
	rustle_tween.parallel().tween_property(sprite, "rotation", deg_to_rad(14.0 * lean_dir), 0.08)
	rustle_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.35)
	rustle_tween.parallel().tween_property(sprite, "rotation", 0.0, 0.35)
	await rustle_tween.finished
	is_rustling = false
