extends Control

@onready var admob: Admob = $Admob

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var beat_sync: BeatSync = $BeatSync

@onready var spectrum: AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Music"), 0) as AudioEffectSpectrumAnalyzerInstance

@onready var tap_sound: AudioStreamPlayer2D = $TapSound

@onready var background: ColorRect = $Background

@onready var quanta_label = $CurrencyDisplay/QuantaLabel

@onready var quantum_core: TextureButton = $QuantumCore
@onready var quantum_core_2d: AnimatedSprite2D = $QuantumCore2D

@onready var particle_effect = $ParticleEffect
@onready var particle_effect_2: CPUParticles2D = $ParticleEffect2

@onready var circular_cascade_progress: ColorRect = $CircularCascadeProgress
@onready var cascade_progress: ProgressBar = $ProgressContainer/ProgressDisplay/CascadeProgress

@onready var progress_container_2: VBoxContainer = $ProgressContainer2
@onready var quanta_goal_progress: ProgressBar = $ProgressContainer2/ProgressDisplay/QuantaGoalProgress

@onready var upgrade_scroll_container: ScrollContainer = $UpgradeScrollContainer
@onready var upgrade1: Upgrade = $UpgradeScrollContainer/UpgradesContainer/Upgrade1
@onready var upgrade2: Upgrade = $UpgradeScrollContainer/UpgradesContainer/Upgrade2
@onready var upgrade3: Upgrade = $UpgradeScrollContainer/UpgradesContainer/Upgrade3
@onready var upgrade4: Upgrade = $UpgradeScrollContainer/UpgradesContainer/Upgrade4

@onready var new_game_dialog: ConfirmationDialog = $NewGameDialog
@onready var new_game: TextureButton = $TopMenu/NewGame
@onready var audio_on_off: TextureButton = $TopMenu/AudioOnOff
@onready var music_on_off: TextureButton = $TopMenu/MusicOnOff
@onready var stats_button: TextureButton = $TopMenu/StatsButton
@onready var ad_boost: TextureButton = $TopMenu/AdBoost

@onready var stats_label: Label = $ProgressContainer2/StatsLabel
@onready var character_video: VideoStreamPlayer = $CharacterVideo

var floating_label_scene := preload("res://floating_label.tscn")
var floating_labels: Array[FloatingLabel] = []

var circular_cascade_progress_rotation_speed: float = 0.0
var circular_cascade_progress_ring_thickness: float = 0.01

var is_admob_initialized: bool = false
var interstitial_ad_loading_timer: Timer = null

@export var target_nodes: Array[NodePath]

func _ready() -> void:
	#print("MAIN ready")

	# Initialize AdMob plugin
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		admob.initialization_completed.connect(_on_admob_initialization_completed)

		admob.banner_ad_loaded.connect(_on_banner_ad_loaded)
		admob.banner_ad_failed_to_load.connect(_on_banner_ad_failed_to_load)

		admob.interstitial_ad_loaded.connect(_on_interstitial_ad_loaded)
		admob.interstitial_ad_failed_to_load.connect(_on_interstitial_ad_failed_to_load)
		admob.interstitial_ad_dismissed_full_screen_content.connect(_on_interstitial_ad_dismissed_full_screen_content)

		admob.rewarded_ad_loaded.connect(_on_rewarded_ad_loaded)
		admob.rewarded_ad_failed_to_load.connect(_on_rewarded_ad_failed_to_load)
		admob.rewarded_ad_user_earned_reward.connect(_on_rewarded_ad_user_earned_reward)

		#admob.rewarded_interstitial_ad_loaded.connect(_on_rewarded_interstitial_ad_loaded)
		#admob.rewarded_interstitial_ad_failed_to_load.connect(_on_rewarded_interstitial_ad_failed_to_load)
		#admob.rewarded_interstitial_ad_user_earned_reward.connect(_on_rewarded_interstitial_ad_user_earned_reward)

		interstitial_ad_loading_timer = Timer.new()
		interstitial_ad_loading_timer.wait_time = 1.0
		interstitial_ad_loading_timer.timeout.connect(_on_interstitial_ad_loading_timer_timeout)
		
		if !is_admob_initialized:
			admob.initialize()
	else:
		ad_boost.disabled = true
		ad_boost.visible = false
	
	# Set upgrade IDs
	upgrade1.upgrade_id = "accelerator"
	upgrade2.upgrade_id = "stabilizer"
	upgrade3.upgrade_id = "shift"
	upgrade4.upgrade_id = "entanglement"
	
	# Connect button signals
	self.resized.connect(_on_resized)
	beat_sync.beat.connect(pulse)
	
	new_game_dialog.confirmed.connect(_on_new_game_confirmed)
	new_game_dialog.canceled.connect(_on_new_game_canceled)
	
	new_game_dialog.add_theme_font_override("font", Globals.FONT_KENNEY_FUTURE)
	new_game_dialog.add_theme_font_size_override("font", Globals.UI_FONT_SIZE_LARGE)
	
	quantum_core.pressed.connect(_on_quantum_core_pressed)
	
	new_game.pressed.connect(_on_new_game_pressed)
	audio_on_off.toggled.connect(_on_audio_on_off_toggled)
	music_on_off.toggled.connect(_on_music_on_off_toggled)
	ad_boost.pressed.connect(_on_ad_boost_pressed)
	
	character_video.finished.connect(_on_character_video_finished)
	
	upgrade1.get_node("IconButton").pressed.connect(_on_upgrade_pressed.bind("accelerator"))
	upgrade2.get_node("IconButton").pressed.connect(_on_upgrade_pressed.bind("stabilizer"))
	upgrade3.get_node("IconButton").pressed.connect(_on_upgrade_pressed.bind("shift"))
	upgrade4.get_node("IconButton").pressed.connect(_on_upgrade_pressed.bind("entanglement"))
	
	# Connect Gm signals
	Gm.quanta_changed.connect(_on_quanta_changed)
	Gm.game_state_updated.connect(update_ui)
	
	# Apply custom themes
	stats_label.add_theme_font_override("font", Globals.FONT_BPMONO)
	stats_label.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_SMALL)

	quanta_label.add_theme_font_override("font", Globals.QUANTA_LABEL_FONT)
	quanta_label.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_NORMAL)

	cascade_progress.value_changed.connect(_on_cascade_progress_value_changed)
	setup_progress_bar(cascade_progress)
	
	quanta_goal_progress.value_changed.connect(_on_quanta_goal_progress_value_changed)
	setup_progress_bar(quanta_goal_progress)

	setup_h_scroll_bar()

	# Update initial UI
	particle_effect.emitting = false
	particle_effect_2.emitting = false
	quantum_core.grab_focus()
	
	character_video.visible = false
	cascade_progress.value = 0

	update_circular_cascade_progress(0.0)

	quanta_goal_progress.value = 0
	quanta_goal_progress.max_value = Globals.QUANTA_GOAL

	audio_on_off.set_pressed_no_signal(!Gm.is_sound_on)
	music_on_off.set_pressed_no_signal(!Gm.is_music_on)

	beat_sync.beat_index = Gm.last_beat_index
	audio_stream_player.play(Gm.music_last_position)

	upgrade_scroll_container.get_h_scroll_bar().value = Gm.last_h_scrollbar_value

	update_ui()

func load_banner_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if !admob.is_banner_ad_loaded():
				print("Attempting to load banner ad")
				admob.load_banner_ad()

func show_banner_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if !admob.is_banner_ad_loaded():
				print("Showing banner ad")
				admob.show_banner_ad()

func load_interstitial_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if !admob.is_interstitial_ad_loaded():
				print("Attempting to load interstitial ad")
				admob.load_interstitial_ad()

func show_interstitial_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if admob.is_interstitial_ad_loaded():
				print("Showing interstitial ad")
				admob.show_interstitial_ad()

func load_rewarded_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if !admob.is_rewarded_ad_loaded():
				print("Attempting to load rewarded ad")
				admob.load_rewarded_ad()

func show_rewarded_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if admob.is_rewarded_ad_loaded():
				print("Showing rewarded ad")
				admob.show_rewarded_ad()

func load_rewarded_interstitial_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if !admob.is_rewarded_interstitial_ad_loaded():
				print("Attempting to load rewarded interstitial ad")
				admob.load_rewarded_interstitial_ad()

func show_rewarded_interstitial_ad() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if admob.is_rewarded_interstitial_ad_loaded():
				print("Showing rewarded interstitial ad")
				admob.show_rewarded_interstitial_ad()

func _process(_delta: float) -> void:
	if upgrade1.is_enabled():
		if !Gm.has_character_video_particle_accelerator_info_played:
			Gm.play_character_video_particle_accelerator_info = true

	if upgrade2.is_enabled():
		if !Gm.has_character_video_quantum_stabilizer_info_played:
			Gm.play_character_video_quantum_stabilizer_info = true

	if upgrade3.is_enabled():
		if !Gm.has_character_video_dimensional_shift_info_played:
			Gm.play_character_video_dimensional_shift_info = true

	if upgrade4.is_enabled():
		if !Gm.has_character_video_entanglement_array_info_played:
			Gm.play_character_video_entanglement_array_info = true

	if Gm.play_character_video_particle_accelerator_info:
		if !Gm.has_character_video_particle_accelerator_info_played:
			if character_video:
				if !character_video.is_playing():
					character_video.stream = Globals.ALIX_PARTICLE_ACCELERATOR_INFO
					character_video.visible = true
					character_video.play()
					Gm.has_character_video_particle_accelerator_info_played = true

	if Gm.play_character_video_quantum_stabilizer_info:
		if !Gm.has_character_video_quantum_stabilizer_info_played:
			if character_video:
				if !character_video.is_playing():
					character_video.stream = Globals.ALIX_QUANTUM_STABILIZER_INFO
					character_video.visible = true
					character_video.play()
					Gm.has_character_video_quantum_stabilizer_info_played = true

	if Gm.play_character_video_dimensional_shift_info:
		if !Gm.has_character_video_dimensional_shift_info_played:
			if character_video:
				if !character_video.is_playing():
					character_video.stream = Globals.ALIX_DIMENSIONAL_SHIFT_INFO
					character_video.visible = true
					character_video.play()
					Gm.has_character_video_dimensional_shift_info_played = true

	if Gm.play_character_video_entanglement_array_info:
		if !Gm.has_character_video_entanglement_array_info_played:
			if character_video:
				if !character_video.is_playing():
					character_video.stream = Globals.ALIX_ENTANGLEMENT_ARRAY_INFO
					character_video.visible = true
					character_video.play()
					Gm.has_character_video_entanglement_array_info_played = true

	if Gm.is_sound_on:
		character_video.volume = 1.0
	else:
		character_video.volume = 0.0

	if Gm.is_music_on:
		audio_stream_player.volume_linear = 1.0
		
		if character_video:
			if character_video.is_playing():
				audio_stream_player.volume_linear = 0.35
			else:
				audio_stream_player.volume_linear = 1.0
	else:
		audio_stream_player.volume_linear = 0.0

	if audio_stream_player:
		if audio_stream_player.playing:
			Gm.music_last_position = audio_stream_player.get_playback_position()

	if upgrade_scroll_container:
		if upgrade_scroll_container.get_h_scroll_bar():
			Gm.last_h_scrollbar_value = upgrade_scroll_container.get_h_scroll_bar().value

	if circular_cascade_progress.material:
		var _material: ShaderMaterial = circular_cascade_progress.material
		if _material:
			var rotation_offset: float = _material.get_shader_parameter("rotation_offset")
			rotation_offset += circular_cascade_progress_rotation_speed * _delta

			if rotation_offset >= TAU:
				rotation_offset -= TAU

			_material.set_shader_parameter("rotation_offset", rotation_offset)

	for p in target_nodes:
		var node = get_node(p)
		node.scale = node.scale.lerp(Vector2.ONE, _delta * Globals.PULSE_SPEED)
		node.modulate = node.modulate.lerp(Color.WHITE, _delta * Globals.PULSE_SPEED)

	update_ui()

func _on_quantum_core_pressed() -> void:
	if Gm.is_sound_on:
		tap_sound.play()

	Gm.add_quanta(Gm.quanta_per_tap)

	particle_effect.emitting = true
	particle_effect.one_shot = true
	particle_effect_2.emitting = true
	particle_effect_2.one_shot = true

	# Create tween for animation
	var tween = create_tween().set_parallel(true)
	# Scale pulse: grow to 1.1x and back
	tween.tween_property(quantum_core_2d, "scale", Globals.QUANTUM_CORE_MAX_SCALE, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(quantum_core_2d, "scale", Globals.QUANTUM_CORE_ORIGINAL_SCALE, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)
	# Glow flash: brighten modulate and back
	tween.tween_property(quantum_core_2d, "modulate", Color(1.81, 0.679, 0.879, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(quantum_core_2d, "modulate", Color(1.0, 1.0, 1.0, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)
	# Rotation: slight spin
	tween.tween_property(quantum_core_2d, "rotation_degrees", 5.0, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(quantum_core_2d, "rotation_degrees", 0.0, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)

	
	## Create tween for animation
	#var tween = create_tween().set_parallel(true)
	## Scale pulse: grow to 1.1x and back
	#tween.tween_property(quantum_core, "scale", Vector2(1.1, 1.1), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	#tween.tween_property(quantum_core, "scale", Vector2(1.0, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)
	## Glow flash: brighten modulate and back
	#tween.tween_property(quantum_core, "modulate", Color(1.5, 1.5, 2.0, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#tween.tween_property(quantum_core, "modulate", Color(1.0, 1.0, 1.0, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)
	## Rotation: slight spin
	#tween.tween_property(quantum_core, "rotation_degrees", 5.0, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	#tween.tween_property(quantum_core, "rotation_degrees", 0.0, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)

func _on_upgrade_pressed(upgrade_id: String) -> void:
	if Gm.purchase_upgrade(upgrade_id):
		# Play animation for the purchased upgrade
		if upgrade_id == "accelerator":
			upgrade1.play_purchase_animation()
		elif upgrade_id == "stabilizer":
			upgrade2.play_purchase_animation()
		elif upgrade_id == "shift":
			upgrade3.play_purchase_animation()
		elif upgrade_id == "entanglement":
			upgrade4.play_purchase_animation()
		update_ui()

func update_ui() -> void:
	particle_effect.position = quantum_core.position + (quantum_core.size / 2)
	particle_effect_2.position = quantum_core.position + (quantum_core.size / 2)
	quantum_core_2d.position = quantum_core.position + (quantum_core.size / 2)
	character_video.position.x = quantum_core.position.x + (quantum_core.size.x / 2) - (character_video.size.x / 2)
	circular_cascade_progress.position = quantum_core.position # + (quantum_core.size / 2)
	stats_label.text = Gm.format_time(Gm.elapsed_timer) + " " + Gm.format_number(Globals.QUANTA_GOAL, " ")
	quanta_label.text = Globals.QUANTA_LABEL_TEXT + "\n" + Gm.format_number(Gm.quanta, " ")
	cascade_progress.value = Gm.cascade_progress
	quanta_goal_progress.value = Gm.quanta
	
	# Sync Upgrade properties with Gm.upgrades
	upgrade1.cost = Gm.upgrades.accelerator.cost
	upgrade1.level = Gm.upgrades.accelerator.level
	upgrade2.cost = Gm.upgrades.stabilizer.cost
	upgrade2.level = Gm.upgrades.stabilizer.level
	upgrade3.cost = Gm.upgrades.shift.cost
	upgrade3.level = Gm.upgrades.shift.level
	upgrade4.cost = Gm.upgrades.entanglement.cost
	upgrade4.level = Gm.upgrades.entanglement.level
	upgrade1.update_ui()
	upgrade2.update_ui()
	upgrade3.update_ui()
	upgrade4.update_ui()

func create_gradient_fill() -> StyleBoxTexture:
	var _size: Vector2i = cascade_progress.size # Vector2i(256, cascade_progress.size.y)  # base texture size; adjust to your bar height
	var img := Image.create_empty(_size.x, _size.y, false, Image.FORMAT_RGBA8)

	# Create a horizontal gradient
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.3, 0.6, 1.0))   # left color
	gradient.add_point(1.0, Color(0.0, 0.22, 0.473)) # right color

	# Fill the image with gradient colors
	for x in range(_size.x):
		var t := float(x) / float(_size.x - 1)
		var col := gradient.sample(t)
		for y in range(_size.y):
			img.set_pixel(x, y, col)

	# Create texture from image
	var tex := ImageTexture.create_from_image(img)

	# Create a StyleBoxTexture and use that gradient texture
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_expand_margin_all(2.0)
	sb.modulate_color = Color.WHITE  # preserves gradient colors accurately

	return sb

func setup_progress_bar(progress_bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	bg.corner_radius_top_left = Globals.CORNER_RADIUS
	bg.corner_radius_top_right = Globals.CORNER_RADIUS
	bg.corner_radius_bottom_left = Globals.CORNER_RADIUS
	bg.corner_radius_bottom_right = Globals.CORNER_RADIUS
	bg.set_border_width_all(1)
	bg.border_color = Color(0.3, 0.3, 0.4)
	
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.6, 1.0)
	fill.corner_radius_top_left = Globals.CORNER_RADIUS
	fill.corner_radius_top_right = Globals.CORNER_RADIUS
	fill.corner_radius_bottom_left = Globals.CORNER_RADIUS
	fill.corner_radius_bottom_right = Globals.CORNER_RADIUS
	fill.set_border_width_all(1)
	fill.border_color = Color(0.0, 0.22, 0.473, 1.0)
	
	#fill.bg_color = Color(0.2, 0.5, 1.0)
	#fill.shadow_color = Color(0, 0, 0, 0.3)
	#fill.shadow_size = 2

	progress_bar.add_theme_stylebox_override("background", bg)
	progress_bar.add_theme_stylebox_override("fill", fill)

	progress_bar.add_theme_font_override("font", Globals.CASCADE_PROGRESS_FONT)
	progress_bar.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_SMALLER)
	#var tw = create_tween()
	#tw.tween_property(fill, "bg_color", Color(0.4, 0.8, 1.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#tw.set_loops()

@warning_ignore("unused_parameter")
func _on_admob_initialization_completed(status_data: InitializationStatus) -> void:
	for key in status_data._data.keys():
		#print(key, ":", status_data._data[key])
		pass

	is_admob_initialized = true

	if !admob.is_banner_ad_loaded():
		load_banner_ad()

	if !admob.is_interstitial_ad_loaded():
		load_interstitial_ad()

	if !admob.is_rewarded_ad_loaded():
		load_rewarded_ad()

	#if !admob.is_rewarded_interstitial_ad_loaded():
		#load_rewarded_interstitial_ad()

@warning_ignore("unused_parameter")
func _on_banner_ad_loaded(ad_id: String) -> void:
	print("Banner ad loaded")
	show_banner_ad()

@warning_ignore("unused_parameter")
func _on_banner_ad_failed_to_load(ad_id: String, error_data: LoadAdError) -> void:
	print(error_data.get_response_info())

@warning_ignore("unused_parameter")
func _on_interstitial_ad_loaded(ad_id: String) -> void:
	print("Interstital ad loaded")

@warning_ignore("unused_parameter")
func _on_interstitial_ad_dismissed_full_screen_content(ad_id: String) -> void:
	reset_game()

@warning_ignore("unused_parameter")
func _on_interstitial_ad_failed_to_load(ad_id: String, error_data: LoadAdError) -> void:
	print(error_data.get_response_info())
	pass

@warning_ignore("unused_parameter")
func _on_rewarded_ad_loaded(ad_id: String) -> void:
	print("Rewarded ad loaded")

@warning_ignore("unused_parameter")
func _on_rewarded_ad_failed_to_load(ad_id: String, error_data: LoadAdError) -> void:
	print(error_data.get_response_info())

@warning_ignore("unused_parameter")
func _on_rewarded_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	for key in reward_data._data.keys():
		print(key, ":", reward_data._data[key])

@warning_ignore("unused_parameter")
func _on_rewarded_interstitial_ad_loaded(ad_id: String) -> void:
	print("Rewarded interstital ad loaded")

@warning_ignore("unused_parameter")
func _on_rewarded_interstitial_ad_failed_to_load(ad_id: String, error_data: LoadAdError) -> void:
	print(error_data.get_response_info())

@warning_ignore("unused_parameter")
func _on_rewarded_interstitial_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	for key in reward_data._data.keys():
		print(key, ":", reward_data._data[key])

func _on_interstitial_ad_loading_timer_timeout() -> void:
	pass

func reset_game() -> void:
	clear_all_labels()
	
	character_video.visible = false
	if character_video.is_playing():
		character_video.stop()
		character_video.stream = null

	cascade_progress.value = 0

	Gm.reset_game()

	Gm.last_quanta = Gm.quanta

	audio_on_off.set_pressed_no_signal(!Gm.is_sound_on)
	music_on_off.set_pressed_no_signal(!Gm.is_music_on)
	audio_stream_player.play()
	
	upgrade_scroll_container.get_h_scroll_bar().value = Gm.last_h_scrollbar_value

	beat_sync.reset()

	update_ui()

func _on_new_game_pressed() -> void:
	Gm.is_game_paused = true
	new_game_dialog.modulate.a = 0.0
	new_game_dialog.popup_centered()

func _on_new_game_confirmed() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if admob.is_interstitial_ad_loaded():
				show_interstitial_ad()
			else:
				load_interstitial_ad()
				reset_game()
	else:
		reset_game()

func _on_new_game_canceled() -> void:
	Gm.is_game_paused = false

func _on_ad_boost_pressed() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if admob.is_rewarded_ad_loaded():
				show_rewarded_ad()
			#else:
				#load_interstitial_ad()
				#reset_game()

func _on_quanta_changed(new_value: int) -> void:
	if !Gm.has_reached_goal:
		circular_cascade_progress_rotation_speed = Gm.get_normalized_value(new_value, Globals.QUANTA_GOAL, Globals.CIRCULAR_CASCADE_PROGRESS_ROTATION_SPEED, 6.28)

		if new_value > Gm.last_quanta:
			var gain := new_value - Gm.last_quanta
			_show_quanta_gain(gain)
		Gm.last_quanta = new_value

func update_circular_cascade_progress(value: float) -> void:
	if circular_cascade_progress.material:
		var _material: ShaderMaterial = circular_cascade_progress.material
		if _material:
			_material.set_shader_parameter("progress", Gm.get_normalized_value(value, cascade_progress.max_value, 0.0, 1.0))
			_material.set_shader_parameter("ring_thickness", Gm.get_normalized_value(value, cascade_progress.max_value, Globals.CIRCULAR_CASCADE_PROGRESS_MINIMUM_RING_THICKNESS, Globals.CIRCULAR_CASCADE_PROGRESS_MAXIMUM_RING_THICKNESS))

@warning_ignore("unused_parameter")
func _on_quanta_goal_progress_value_changed(value: float) -> void:
	#print(str(value))
	pass

func _on_cascade_progress_value_changed(value: float) -> void:
	if character_video:
		if !character_video.is_playing():
			var cascade_progress_percentage: float = Gm.get_normalized_value(value, cascade_progress.max_value, 0.0, 1.0)
			if cascade_progress_percentage >= Globals.CASCADE_ALIX_THRESHOLD_MIN:
				if !Gm.has_character_video_pre_cascade_played_this_cascade:
					#print("Cascade" + str(cascade_progress.value) + " Value:" + str(value) + " MaxValue:" + str(cascade_progress.max_value))
					
					character_video.visible = true
					character_video.stream = [Globals.ALIX_PRE_CASCADE, Globals.ALIX_PRE_CASCADE_2][randi_range(0, 1)]
					character_video.play()
					Gm.has_character_video_pre_cascade_played_this_cascade = true

	update_circular_cascade_progress(value)

func _on_character_video_finished() -> void:
	character_video.visible = false

func _show_quanta_gain(gain: int) -> void:
	var label_instance: FloatingLabel = floating_label_scene.instantiate()
	get_tree().current_scene.add_child(label_instance)
	
	var start_pos = quantum_core_2d.get_global_position()
	label_instance.setup(str(gain), start_pos, gain)
	floating_labels.append(label_instance)

func clear_all_labels() -> void:
	for label in floating_labels:
		if is_instance_valid(label):
			label.queue_free()
	floating_labels.clear()

func _on_audio_on_off_toggled(toggled_on: bool) -> void:
	Gm.is_sound_on = !toggled_on

func _on_music_on_off_toggled(toggled_on: bool) -> void:
	Gm.is_music_on = !toggled_on

func get_live_frequency_data(_delta: float) -> float:
	var low = spectrum.get_magnitude_for_frequency_range(20, 250)  # Bass
	var mid = spectrum.get_magnitude_for_frequency_range(250, 2000)
	var high = spectrum.get_magnitude_for_frequency_range(2000, 8000)
	
	var total_energy = (low.length() + mid.length() + high.length()) / 3.0

	var smooth_energy: float = 0.0
	smooth_energy = lerp(smooth_energy, total_energy, 0.1)

	# For example, scale a UI element (like a Panel or TextureRect)
	#$YourUIElement.scale = Vector2.ONE * (1.0 + total_energy * 3.0)

	return smooth_energy

func pulse():
	for p in target_nodes:
		var node = get_node(p)
		node.scale = Vector2.ONE * Globals.PULSE_STRENGTH
		node.modulate = Globals.PULSE_TINT_COLOR # optional brief tint

func _on_resized() -> void:
	if particle_effect:
		if particle_effect.emitting:
			particle_effect.emitting = false

	if particle_effect_2:
		if particle_effect_2.emitting:
			particle_effect_2.emitting = false

func setup_h_scroll_bar():
	var scrollbar = upgrade_scroll_container.get_h_scroll_bar()
	
	#scrollbar.set_size(Vector2(scrollbar.size.x, 512.0))
	#print(str(scrollbar.size.y))
	# Create a StyleBox for the grabber
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.8, 0.2, 0.2) # Red grabber
	grabber_style.set_corner_radius_all(5)
	#grabber_style.border_width_left = 2
	#grabber_style.border_color = Color(1, 1, 1) # White border

	# Style for the track
	#var track_style = StyleBoxFlat.new()
	#track_style.bg_color = Color(0.2, 0.2, 0.2) # Dark gray

	# Apply the style to the grabber
	scrollbar.add_theme_stylebox_override("grabber", grabber_style)
	#scrollbar.add_theme_stylebox_override("scroll", track_style)
	
	# Optionally, adjust other properties
	#scrollbar.add_theme_color_override("grabber", Color(1, 1, 1)) # White grabber text/icon
