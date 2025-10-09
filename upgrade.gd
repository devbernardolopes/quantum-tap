@tool

class_name Upgrade

extends VBoxContainer

@export var upgrade_id: String:  # New: Links to Gm.upgrades key
	set(value):
		upgrade_id = value
		update_ui()
@export var upgrade_name: String:
	set(value):
		upgrade_name = value
		update_ui()
@export var description: String:
	set(value):
		description = value
		update_ui()
@export var initial_cost: int:
	set(value):
		initial_cost = value
@export var cost: int:
	set(value):
		cost = value
		update_ui()
@export var level: int:
	set(value):
		level = value
		update_ui()
@export var max_level: int:
	set(value):
		max_level = value
@export var texture: Texture2D:
	set(value):
		texture = value
		update_ui()

@onready var icon_button = $IconButton
@onready var name_label = $NameLabel
@onready var info_label = $InfoLabel
@onready var purchase_sound: AudioStreamPlayer2D = $PurchaseSound

func _ready() -> void:
	if name_label:
		name_label.add_theme_font_override("font", Globals.FONT_XOLONIUM_REGULAR)
		name_label.add_theme_font_size_override("font_size", Globals.UPGRADE_NAME_FONT_SIZE)

	if info_label:
		info_label.add_theme_font_override("font", Globals.FONT_BPMONO)
		info_label.add_theme_font_size_override("font_size", Globals.UPGRADE_INFO_FONT_SIZE)

	update_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		update_ui()

func is_enabled() -> bool:
	var result: bool = false
	if icon_button:
		result = !icon_button.disabled
	return result

func set_enabled(enabled: bool) -> void:
	if icon_button:
		if level < max_level:
			icon_button.disabled = not enabled
			icon_button.modulate = Color(1.0, 1.0, 1.0, 1.0) if enabled else Color(0.502, 0.502, 0.502, 1.0)
		else:
			icon_button.disabled = true

func update_ui() -> void:
	if icon_button and texture:
		icon_button.texture_normal = texture
	if name_label:
		name_label.text = upgrade_name if upgrade_name else "Upgrade"
	if info_label:
		if level < max_level:
			info_label.text = "%s\nCost: %d\n Level: %d/%d" % [description, cost, level, max_level]
		else:
			info_label.text = "%s\nMAX" % [description]

	# Check Quanta against cost for enabling/disabling
	if Engine.is_editor_hint():
		set_enabled(true) # Enable in editor for visibility
	else:
		set_enabled(Gm.quanta >= cost)

	# Force redraw in editor
	if Engine.is_editor_hint():
		queue_redraw()

func play_purchase_animation() -> void:
	if icon_button:
		if Gm.is_sound_on:
			purchase_sound.play()
		var tween = create_tween().set_parallel(true)
		# Scale pulse: grow to 1.15x and back
		tween.tween_property(icon_button, "scale", Vector2(1.15, 1.15), Globals.UPGRADE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon_button, "scale", Vector2(1.0, 1.0), Globals.UPGRADE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.UPGRADE_TWEEN_DELAY)
		# Glow flash: brighten with green tint and back
		tween.tween_property(icon_button, "modulate", Color(1.5, 2.0, 1.5, 1.0), Globals.UPGRADE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), Globals.UPGRADE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(Globals.UPGRADE_TWEEN_DELAY)
		# Rotation: slight spin
		tween.tween_property(icon_button, "rotation_degrees", 7.0, Globals.UPGRADE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon_button, "rotation_degrees", 0.0, Globals.UPGRADE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.UPGRADE_TWEEN_DELAY)
