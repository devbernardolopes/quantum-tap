extends Node2D
class_name Fireworks

@export var bursts := 6
@export var area := Vector2(800, 600)
@export var duration := 3.0

func _ready():
	randomize()
	_spawn_bursts()
	if is_instance_valid(self):
		await get_tree().create_timer(duration).timeout
		queue_free()

func _spawn_bursts() -> void:
	for i in range(bursts):
		var pos = Vector2(randi_range(0, int(area.x)), randi_range(0, int(area.y / 1.3)))
		_spawn_firework(pos, Color.from_hsv(randf(), 0.9, 1.0))
		await get_tree().create_timer(randf() * 0.3).timeout

func _spawn_firework(pos: Vector2, color: Color) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.amount = 80
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.emitting = true
	particles.gravity = Vector2(0, 60)
	particles.initial_velocity_min = 200.0
	#particles.velocity_random = 0.6
	particles.scale_amount_min = 0.8
	#particles.scale_amount_random = 0.5
	particles.spread = 180
	particles.color = color
	particles.color_ramp = _make_ramp(color)
	add_child(particles)

	var flash := ColorRect.new()
	# explicit alpha set (replace with_alpha)
	flash.color = Color(color.r, color.g, color.b, 0.8)
	flash.size = Vector2(12, 12)
	flash.position = pos - flash.size / 2
	add_child(flash)

	var t := create_tween()
	t.tween_property(flash, "size", Vector2(80, 80), 0.4).set_trans(Tween.TRANS_CUBIC)
	t.parallel().tween_property(flash, "modulate:a", 0.0, 0.4)
	t.finished.connect(func(): flash.queue_free())

	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()

func _make_ramp(base_color: Color) -> Gradient:
	var grad := Gradient.new()
	grad.add_point(0.0, Color(base_color.r, base_color.g, base_color.b, 1.0))

	var mid := base_color.lerp(Color(1,1,1), 0.3)
	mid.a = 0.7
	grad.add_point(0.6, mid)

	grad.add_point(1.0, Color(1,1,1, 0.0))
	return grad
