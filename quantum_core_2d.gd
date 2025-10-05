extends AnimatedSprite2D

# State variables
var playing_forward: bool = true

# The maximum frame index for the "default" animation (0 to 80)
const MAX_FRAME: int = 80
const MIN_FRAME: int = 0
const SPEED_SCALE: float = 0.5

func _ready() -> void:
	speed_scale = SPEED_SCALE

	# Set the animation to "default" and start it.
	play("default")

	# Connect the frame_changed signal to handle the transition at the ends.
	# We use this signal because it triggers reliably whenever the frame index updates.
	frame_changed.connect(_on_frame_changed)

func _on_frame_changed() -> void:
	# Check if we are playing the "default" animation
	if animation != "default":
		return

	if playing_forward:
		# Check if we've reached the last frame (index 80)
		if frame == MAX_FRAME:
			# Change direction to backwards
			playing_forward = false
			# Invert the animation speed by setting the speed_scale to a negative value.
			# Since your speed scale is already 2.0, we set it to -2.0.
			# The base animation speed is 24.0 FPS.
			speed_scale = -0.5
			# Manually advance or retreat one frame to ensure the negative speed takes effect immediately.
			# Moving back one frame (80 -> 79)
			frame = MAX_FRAME - 1

	else: # playing_backwards
		# Check if we've reached the first frame (index 0)
		if frame == MIN_FRAME:
			# Change direction to forwards
			playing_forward = true
			# Restore the forward speed scale.
			speed_scale = 0.5
			# Manually advance one frame to ensure the positive speed takes effect immediately.
			# Moving forward one frame (0 -> 1)
			frame = MIN_FRAME + 1
