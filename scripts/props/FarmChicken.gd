extends Node2D
class_name FarmChicken

@onready var sprite: Sprite2D = $Sprite2D

var peck_timer: float = 0.0
var is_pecking: bool = false
var anim_timer: float = 0.0
var current_frame: int = 0

func _ready() -> void:
	peck_timer = randf_range(1.0, 3.0)
	if randf() > 0.5:
		sprite.flip_h = true

func _process(delta: float) -> void:
	if is_pecking:
		anim_timer += delta
		if anim_timer >= 0.18:
			anim_timer = 0.0
			current_frame += 1
			if current_frame > 3:
				current_frame = 0
				is_pecking = false
				peck_timer = randf_range(1.5, 4.5)
			sprite.frame = current_frame
	else:
		peck_timer -= delta
		if peck_timer <= 0.0:
			is_pecking = true
			anim_timer = 0.0
			current_frame = 0
			# Occasionally change facing direction
			if randf() > 0.6:
				sprite.flip_h = not sprite.flip_h
