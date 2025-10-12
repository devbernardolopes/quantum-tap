class_name Modal

extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var panel: Panel = $Panel
@onready var v_box_container: VBoxContainer = $Panel/VBoxContainer
@onready var title: Label = $Panel/VBoxContainer/Title
@onready var confirm_button: Button = $Panel/VBoxContainer/MarginContainer/HBoxContainer/ConfirmButton

var _confirm_cb: Callable = Callable()

#var viewport_size: Vector2 = get_viewport().get_visible_rect().size

func _ready() -> void:
	#viewport_size = get_viewport().get_visible_rect().size

	title.add_theme_font_override("font", Globals.FONT_KENNEY_FUTURE_NARROW)
	title.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_LARGE)
	
	panel.add_theme_font_override("font", Globals.FONT_KENNEY_FUTURE_NARROW)
	panel.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_NORMAL)
	
	#confirm_button.add_theme_font_override("font", Globals.FONT_KENNEY_FUTURE_NARROW)
	#confirm_button.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_NORMAL)

	confirm_button.pressed.connect(_on_confirm)
	
	var theme: Theme = Theme.new()
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.14, 0.14, 0.14, 1.0)
	btn.bg_color = Color(0.506, 0.173, 0.498, 0.949)
	btn.content_margin_left = 10
	btn.content_margin_right = 10
	btn.content_margin_top = 6
	btn.content_margin_bottom = 6
	btn.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn)
	
	panel.theme = theme

	visible = false

func _hide_and_cleanup(call_cb: bool = false) -> void:
	# fade out both, then hide and call callback if requested
	var t1 = background.create_tween()
	t1.tween_property(background, "modulate:a", 0.0, 0.12)
	t1.finished.connect(func() -> void:
		background.visible = false
	)

	var t2 = panel.create_tween()
	t2.tween_property(panel, "modulate:a", 0.0, 0.12)
	t2.finished.connect(func() -> void:
		panel.visible = false
		Gm.is_modal_showing = false
		Gm.set_is_game_paused(false)
		if call_cb and _confirm_cb.is_valid():
			# run the provided callable safely
			_confirm_cb.call()
			_confirm_cb = Callable()
			queue_free()
	)

func _on_confirm() -> void:
	_hide_and_cleanup(true)

func show_modal(text: String, on_confirm: Callable = Callable()) -> void:
	if Gm.is_modal_showing:
		return
	
	visible = true

	title.text = text

	_confirm_cb = on_confirm

	# start hidden (modulate alpha = 0) then tween to visible
	background.modulate = Color(1, 1, 1, 0)
	panel.modulate = Color(1, 1, 1, 0)

	# give the overlay a blocking mouse filter (already set) and set pause flag
	Gm.set_is_game_paused(true)
	Gm.is_modal_showing = true

	# overlay fade to semi-transparent black (0.5 alpha) and panel to full
	background.create_tween().tween_property(background, "modulate:a", 0.5, 0.16)
	panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.16)
