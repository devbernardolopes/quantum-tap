class_name ModalDialog

extends Modal

@onready var cancel_button: Button = $Panel/VBoxContainer/MarginContainer/HBoxContainer/CancelButton

func _ready() -> void:
	super._ready()
	
	cancel_button.pressed.connect(_on_cancel)

func _on_cancel() -> void:
	_hide_and_cleanup(false)
