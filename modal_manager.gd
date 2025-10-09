extends Node

# Public
var is_showing: bool = false

# Internal nodes
var _layer: CanvasLayer
var _overlay: ColorRect
var _panel: PanelContainer
var _label: Label
var _btn_confirm: Button
var _btn_cancel: Button
var _confirm_cb: Callable = Callable()

func _ready() -> void:
	_create_ui()

func _create_ui() -> void:
	# CanvasLayer to ensure modal is above everything
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)

	# Overlay that blocks input under the modal
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 1)            # final color (alpha will be controlled by modulate)
	_overlay.modulate = Color(1, 1, 1, 0)         # start invisible
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	# full screen anchors
	#_overlay.set_anchor(SIDE_BOTTOM, 1.0)
	#_overlay.set_anchor(SIDE_LEFT, 0.0)
	#_overlay.set_anchor(SIDE_RIGHT, 1.0)
	#_overlay.set_anchor(SIDE_TOP, 0.0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	#_overlay.anchor_left = 0
	#_overlay.anchor_top = 0
	#_overlay.anchor_right = 1
	#_overlay.anchor_bottom = 1

	#_overlay.margin_left = 0
	#_overlay.margin_top = 0
	#_overlay.margin_right = 0
	#_overlay.margin_bottom = 0
	_overlay.visible = false
	_layer.add_child(_overlay)

	# Panel (dialog) in the center
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.modulate = Color(1, 1, 1, 0)           # invisible at start (we'll fade it in)
	_panel.name = "ConfirmPanel"
	_panel.custom_minimum_size = Vector2(420, 140)

	# center the panel using anchors + margins
	
	_panel.set_anchor(SIDE_BOTTOM, 0.5)
	_panel.set_anchor(SIDE_LEFT, 0.2)
	_panel.set_anchor(SIDE_RIGHT, 0.8)
	_panel.set_anchor(SIDE_TOP, 0.5)
	#_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE, 70)
	#_panel.set_offsets_preset(Control.PRESET_CENTER)
	#_panel.set_offsets_preset(Control.PRESET_CENTER)
	#_panel.set_anchors_preset(Control.PRESET_CENTER)
	#_panel.set_end()

	#_panel.anchor_left = 0.5
	#_panel.anchor_top = 0.5
	#_panel.anchor_right = 0.5
	#_panel.anchor_bottom = 0.5

	#_panel.margin_left = -210
	#_panel.margin_top = -70
	#_panel.margin_right = 210
	#_panel.margin_bottom = 70

	_layer.add_child(_panel)

	# Content layout
	var vb := VBoxContainer.new()
	vb.anchor_left = 0
	vb.anchor_top = 0
	vb.anchor_right = 1
	vb.anchor_bottom = 1
	#vb.margin_left = 12
	#vb.margin_top = 12
	#vb.margin_right = 12
	#vb.margin_bottom = 12
	_panel.add_child(vb)

	_label = Label.new()
	_label.text = "Start a new game?"
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(_label)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	#hb.margin_top = 12
	vb.add_child(hb)

	_btn_cancel = Button.new()
	_btn_cancel.text = "Cancel"
	_btn_cancel.pressed.connect(_on_cancel)
	hb.add_child(_btn_cancel)

	_btn_confirm = Button.new()
	_btn_confirm.text = "Confirm"
	_btn_confirm.pressed.connect(_on_confirm)
	hb.add_child(_btn_confirm)

	# Build and apply a small theme (dark translucent + rounded corners + button styles)
	var theme := Theme.new()

	# Panel style
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.08, 0.95)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_size = 8
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	theme.set_stylebox("panel", "Panel", panel_style)

	# Button base style
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.14, 0.14, 0.14, 1.0)
	btn.content_margin_left = 10
	btn.content_margin_right = 10
	btn.content_margin_top = 6
	btn.content_margin_bottom = 6
	btn.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn)

	var btn_hover := btn.duplicate()
	btn_hover.bg_color = Color(0.20, 0.20, 0.20, 1.0)
	theme.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed := btn.duplicate()
	btn_pressed.bg_color = Color(0.08, 0.08, 0.08, 1.0)
	theme.set_stylebox("pressed", "Button", btn_pressed)

	# (optional) change label/button fonts by loading a Font resource:
	# var fnt = preload("res://fonts/MyFont.tres")
	# theme.set_font("font", "Label", fnt)
	# theme.set_font("font", "Button", fnt)

	# apply theme to our panel (it cascades to children)
	_panel.theme = theme

	# small spacing and margins polish
	#vb.separation = 8
	#hb.spacing = 8

func show_confirm(text: String, on_confirm: Callable) -> void:
	"""Show the modal with `text`. `on_confirm` may be null or a Callable to invoke on confirm."""
	if is_showing:
		# If a modal is already up, ignore/replace behavior could be implemented.
		return
	_confirm_cb = on_confirm
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# show overlay + panel and animate fade-in
	_overlay.visible = true
	_panel.visible = true

	# start hidden (modulate alpha = 0) then tween to visible
	_overlay.modulate = Color(1, 1, 1, 0)
	_panel.modulate = Color(1, 1, 1, 0)

	# give the overlay a blocking mouse filter (already set) and set pause flag
	Gm.is_game_paused = true
	is_showing = true

	# overlay fade to semi-transparent black (0.5 alpha) and panel to full
	_overlay.create_tween().tween_property(_overlay, "modulate:a", 0.5, 0.16)
	_panel.create_tween().tween_property(_panel, "modulate:a", 1.0, 0.16)

	# Optionally give keyboard focus to Cancel or Confirm
	#_btn_cancel.grab_focus()
	_btn_cancel.focus_mode = Control.FOCUS_NONE
	_btn_confirm.focus_mode = Control.FOCUS_NONE

func _hide_and_cleanup(call_cb: bool = false) -> void:
	# fade out both, then hide and call callback if requested
	var t1 = _overlay.create_tween()
	t1.tween_property(_overlay, "modulate:a", 0.0, 0.12)
	t1.finished.connect(func() -> void:
		_overlay.visible = false
	)

	var t2 = _panel.create_tween()
	t2.tween_property(_panel, "modulate:a", 0.0, 0.12)
	t2.finished.connect(func() -> void:
		_panel.visible = false
		is_showing = false
		Gm.is_game_paused = false
		if call_cb and _confirm_cb.is_valid():
			# run the provided callable safely
			_confirm_cb.call()
			_confirm_cb = Callable()
	)

func _on_confirm() -> void:
	_hide_and_cleanup(true)

func _on_cancel() -> void:
	_hide_and_cleanup(false)
