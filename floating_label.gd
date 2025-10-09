class_name FloatingLabel

extends Node2D

@onready var label := $Label

@export var float_distance := 400.0
@export var float_duration := 1.75
@export var start_color := Color(0.168, 0.641, 0.0, 1.0)
@export var end_color := Color(1, 1, 1, 0)

var starting_global_position: Vector2 = Vector2.ONE
var starting_global_position_x: float = 0.0

@warning_ignore("unused_parameter")
func setup(text: String, _position: Vector2, gain: int = 0, _start_color: Color = Color.BLUE_VIOLET) -> void:
	label.add_theme_font_override("font", Globals.FONT_CLEARSANS_BOLD)
	label.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_ULTRA_LARGE)
	label.add_theme_constant_override("outline_size", 4)

	label.text = text
	global_position = _position - Vector2(get_width() / 2, 0)
	starting_global_position = global_position
	starting_global_position.x = global_position.x
	label.modulate = _start_color

	#float_distance = float_distance + min(gain * 2.0, 80.0)
	#float_duration = float_duration - clamp(gain * 0.02, 0.0, 0.3)
	
	var tween = create_tween().set_parallel(true) #.finished.connect(func(): queue_free())

	tween.tween_property(self, "position:y", _position.y - float_distance, float_duration)
	tween.tween_property(label, "modulate", end_color, float_duration)
	tween.tween_property(label, "scale", Vector2(1.6, 1.6), float_duration / 4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), float_duration / 6).set_delay(float_duration / 4)

	# This runs AFTER all the parallel property tweens complete
	#tween.tween_callback(queue_free)

func get_width() -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")

	var text_width = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var outline_size = label.get_theme_constant("outline_size")
	text_width += outline_size * 2
	
	return text_width

@warning_ignore("unused_parameter")       
func _process(delta: float) -> void:
	var new_viewport_width: float = get_viewport().get_visible_rect().size.x
	var new_x_position: float = (new_viewport_width / 2) - get_width() / 2
	if global_position.x != new_x_position:
		global_position.x = new_x_position
