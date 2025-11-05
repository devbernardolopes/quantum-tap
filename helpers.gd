extends Node

const SCREENSHOT_DIR: String = "screenshots"
const FILE_PREFIX: String = "screenshot_"

func setup_screenshot_directory() -> void:
	var user_dir = DirAccess.open("user://")
	if user_dir == null:
		push_error("Cannot access user:// directory")
		return
	
	var target_path = "user://" + SCREENSHOT_DIR
	if not user_dir.dir_exists(SCREENSHOT_DIR):
		var result = user_dir.make_dir_recursive(SCREENSHOT_DIR)
		if result != OK:
			push_error("Failed to create screenshot directory: " + str(result))
		else:
			print("Screenshot directory created: ", target_path)

func take_screenshot() -> void:
	var viewport: Viewport = get_viewport()
	var image: Image = viewport.get_texture().get_image()
	
	if image == null or image.is_empty():
		push_error("Failed to capture viewport image")
		return
	
	# Use Unix timestamp for guaranteed uniqueness
	var timestamp: float = Time.get_unix_time_from_system()
	var filename: String = "%s%d.png" % [FILE_PREFIX, timestamp]
	var full_path: String = "user://%s/%s" % [SCREENSHOT_DIR, filename]
	
	# Ensure directory exists
	var dir_check = DirAccess.open("user://%s" % SCREENSHOT_DIR)
	if dir_check == null:
		setup_screenshot_directory()
		dir_check = DirAccess.open("user://%s" % SCREENSHOT_DIR)
	
	var error: int = image.save_png(full_path)
	
	match error:
		OK:
			print("Screenshot saved successfully: ", full_path)
			# Optional: Show in-game notification
			# show_notification("Screenshot saved!")
		ERR_FILE_CANT_WRITE:
			push_error("Cannot write to file. Check permissions for: ", full_path)
		ERR_FILE_CORRUPT:
			push_error("Image data is corrupted")
		_:
			push_error("Unknown save error: ", error_string(error))
