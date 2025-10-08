class_name FloatingLabel

extends Node2D

@export var float_distance := 400.0
@export var float_duration := 1.85
#@export var float_movement_duration := 0.85
#@export var float_modulation_duration := 1.75
@export var start_color := Color(0.168, 0.641, 0.0, 1.0)
@export var end_color := Color(1, 1, 1, 0)

@onready var label := $Label

func setup(text: String, _position: Vector2, gain: int = 0, _start_color: Color = Color.BLUE_VIOLET) -> void:
	#var offset_x = randf_range(-10.0, 10.0)
	#var offset_y = randf_range(-5.0, 5.0)

	label.add_theme_font_override("font", Globals.FONT_XOLONIUM_BOLD)
	label.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_ULTRA_LARGE)
	label.add_theme_constant_override("outline_size", 4)

	label.text = text
	global_position = _position - Vector2(get_width() / 2, 0)
	label.modulate = _start_color

	float_distance = float_distance + min(gain * 2.0, 80.0)
	float_duration = float_duration - clamp(gain * 0.02, 0.0, 0.3)
	
	var tween := create_tween()
	tween.tween_property(self, "position:y", _position.y - float_distance, float_duration)
	tween.parallel().tween_property(label, "modulate", end_color, float_duration)
	
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	
	tween.tween_callback(queue_free)

func get_width() -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")

	var text_width = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var outline_size = label.get_theme_constant("outline_size")
	text_width += outline_size * 2
	
	return text_width
