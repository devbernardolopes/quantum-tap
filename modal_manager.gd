extends Node

# Public
var is_showing: bool = false

# Internal nodes
var _layer: CanvasLayer
var _overlay: ColorRect
var _panel: PanelContainer
var _label: Label
var _grid_container: GridContainer
var _btn_confirm: Button
var _btn_cancel: Button
var _confirm_cb: Callable = Callable()

func _ready() -> void:
	_create_ui()

func _on_confirm() -> void:
	_hide_and_cleanup(true)

func _on_cancel() -> void:
	_hide_and_cleanup(false)

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

	var new_viewport_width: float = get_viewport().get_visible_rect().size.x

	# Panel (dialog) in the center
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.modulate = Color(1, 1, 1, 0)           # invisible at start (we'll fade it in)
	_panel.name = "ConfirmPanel"
	_panel.custom_minimum_size = Vector2(new_viewport_width / 4, 140)

	# center the panel using anchors + margins
	
	_panel.set_anchor(SIDE_BOTTOM, 0.5)
	_panel.set_anchor(SIDE_LEFT, 0.0)
	_panel.set_anchor(SIDE_RIGHT, 1.0)
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
	#_label.text = "Start a new game?"
	_label.text = "START A NEW GAME?"
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(_label)

	var mc: MarginContainer = MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_bottom", 32)
	mc.add_theme_constant_override("margin_left", 16)
	mc.add_theme_constant_override("margin_right", 16)
	vb.add_child(mc)
	
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_child(hb)

	_grid_container = GridContainer.new()
	_grid_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grid_container.columns = 4
	_grid_container.visible = false
	hb.add_child(_grid_container)

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
	panel_style.bg_color = Color(0.506, 0.173, 0.498, 0.949)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_size = 8
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 32
	theme.set_stylebox("panel", "Panel", panel_style)

	# Button base style
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.14, 0.14, 0.14, 1.0)
	btn.bg_color = Color(0.506, 0.173, 0.498, 0.949)
	btn.content_margin_left = 10
	btn.content_margin_right = 10
	btn.content_margin_top = 6
	btn.content_margin_bottom = 6
	#btn.
	btn.set_corner_radius_all(8)
	#btn.se
	theme.set_stylebox("normal", "Button", btn)
	theme.set_font("font", "Button", Globals.FONT_KENNEY_FUTURE)

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
	Gm.set_is_game_paused(true)
	is_showing = true

	# overlay fade to semi-transparent black (0.5 alpha) and panel to full
	_overlay.create_tween().tween_property(_overlay, "modulate:a", 0.5, 0.16)
	_panel.create_tween().tween_property(_panel, "modulate:a", 1.0, 0.16)

	# Optionally give keyboard focus to Cancel or Confirm
	#_btn_cancel.grab_focus()
	#_btn_cancel.add_theme_constant_override("")
	
	_btn_cancel.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn_confirm.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	_btn_cancel.focus_mode = Control.FOCUS_NONE
	_btn_confirm.focus_mode = Control.FOCUS_NONE

func _hide_and_cleanup(call_cb: bool = false) -> void:
	_grid_container.visible = false
	
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
		Gm.set_is_game_paused(false)
		if call_cb and _confirm_cb.is_valid():
			# run the provided callable safely
			_confirm_cb.call()
			_confirm_cb = Callable()
	)

func show_okay(text: String, on_confirm: Callable) -> void:
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
	Gm.set_is_game_paused(true)
	is_showing = true

	# overlay fade to semi-transparent black (0.5 alpha) and panel to full
	_overlay.create_tween().tween_property(_overlay, "modulate:a", 0.5, 0.16)
	_panel.create_tween().tween_property(_panel, "modulate:a", 1.0, 0.16)

	# Optionally give keyboard focus to Cancel or Confirm
	#_btn_cancel.grab_focus()
	#_btn_cancel.add_theme_constant_override("")
	
	_btn_confirm.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	_btn_confirm.focus_mode = Control.FOCUS_NONE
	_btn_cancel.visible = false

func show_stats(text: String, on_confirm: Callable) -> void:
	if is_showing:
		# If a modal is already up, ignore/replace behavior could be implemented.
		return
	_confirm_cb = on_confirm
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_grid_container.visible = true
	
	var high_scores: Array = Gm.load_high_scores()

	if high_scores:
		var l1: Label = Label.new()
		l1.text = "Time"
		var l2: Label = Label.new()
		l2.text = "Quanta Generated"
		var l3: Label = Label.new()
		l3.text = "Quanta Spent"
		var l4: Label = Label.new()
		l4.text = "Quanta per Second"

		_grid_container.add_child(l1)
		_grid_container.add_child(l2)
		_grid_container.add_child(l3)
		_grid_container.add_child(l4)
		
		high_scores.sort_custom(func(a, b): return a.elapsed_timer < b.elapsed_timer)
		
		for i in high_scores.size():
			var _l1: Label = Label.new()
			_l1.text = Gm.format_time(high_scores[i].elapsed_timer)
			var _l2: Label = Label.new()
			_l2.text = str(high_scores[i].player_quanta_generated)
			var _l3: Label = Label.new()
			_l3.text = str(high_scores[i].player_quanta_spent)
			var _l4: Label = Label.new()
			_l4.text = str(high_scores[i].player_quanta_per_second)

			_grid_container.add_child(_l1)
			_grid_container.add_child(_l2)
			_grid_container.add_child(_l3)
			_grid_container.add_child(_l4)

	# show overlay + panel and animate fade-in
	_overlay.visible = true
	_panel.visible = true

	var theme := Theme.new()
	theme.set_font("font", "Label", Globals.FONT_KENNEY_FUTURE)

	# start hidden (modulate alpha = 0) then tween to visible
	_overlay.modulate = Color(1, 1, 1, 0)
	_panel.modulate = Color(1, 1, 1, 0)

	# give the overlay a blocking mouse filter (already set) and set pause flag
	Gm.set_is_game_paused(true)
	is_showing = true

	# overlay fade to semi-transparent black (0.5 alpha) and panel to full
	_overlay.create_tween().tween_property(_overlay, "modulate:a", 0.5, 0.16)
	_panel.create_tween().tween_property(_panel, "modulate:a", 1.0, 0.16)

	# Optionally give keyboard focus to Cancel or Confirm
	#_btn_cancel.grab_focus()
	#_btn_cancel.add_theme_constant_override("")
	
	_btn_confirm.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	_btn_confirm.focus_mode = Control.FOCUS_NONE
	_btn_cancel.visible = false
