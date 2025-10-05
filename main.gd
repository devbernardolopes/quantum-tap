extends Control

@onready var admob: Admob = $Admob

@onready var tap_sound: AudioStreamPlayer2D = $TapSound

@onready var quanta_label = $CurrencyDisplay/QuantaLabel

@onready var quantum_core: TextureButton = $QuantumCore
@onready var particle_effect = $ParticleEffect

@onready var cascade_progress = $ProgressContainer/ProgressDisplay/CascadeProgress
@onready var stats_label: Label = $ProgressContainer/StatsLabel

@onready var upgrade1 = $UpgradesContainer/GridContainer/Upgrade1
@onready var upgrade2 = $UpgradesContainer/GridContainer/Upgrade2
@onready var upgrade3 = $UpgradesContainer/GridContainer/Upgrade3

@onready var new_game: TextureButton = $NewGame
@onready var ad_boost: TextureButton = $AdBoost

var is_admob_initialized: bool = false

var interstitial_ad_loading_timer: Timer = null

func _ready() -> void:
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
	
	# Connect button signals
	quantum_core.pressed.connect(_on_quantum_core_pressed)
	
	new_game.pressed.connect(_on_new_game_pressed)
	ad_boost.pressed.connect(_on_ad_boost_pressed)
	
	upgrade1.get_node("IconButton").pressed.connect(_on_upgrade_pressed.bind("accelerator"))
	upgrade2.get_node("IconButton").pressed.connect(_on_upgrade_pressed.bind("stabilizer"))
	upgrade3.get_node("IconButton").pressed.connect(_on_upgrade_pressed.bind("shift"))
	
	# Connect Gm signal
	Gm.game_state_updated.connect(update_ui)
	
	quanta_label.add_theme_font_override("font", Globals.UI_FONT_BOLD)
	quanta_label.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_NORMAL)

	stats_label.add_theme_font_override("font", Globals.UI_FONT_REGULAR)
	stats_label.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_NORMAL)

	setup_cascade_progress_bar()
	
	particle_effect.emitting = false

	# Update initial UI
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
	update_ui()

func _on_quantum_core_pressed() -> void:
	tap_sound.play()
	
	Gm.add_quanta(Gm.quanta_per_tap)
	particle_effect.emitting = true
	particle_effect.one_shot = true
	#await get_tree().create_timer(0.5).timeout
	#particle_effect.emitting = false
	
	# Create tween for animation
	var tween = create_tween().set_parallel(true)
	# Scale pulse: grow to 1.1x and back
	tween.tween_property(quantum_core, "scale", Vector2(1.1, 1.1), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(quantum_core, "scale", Vector2(1.0, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)
	# Glow flash: brighten modulate and back
	tween.tween_property(quantum_core, "modulate", Color(1.5, 1.5, 2.0, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(quantum_core, "modulate", Color(1.0, 1.0, 1.0, 1.0), Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)
	# Rotation: slight spin
	tween.tween_property(quantum_core, "rotation_degrees", 5.0, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(quantum_core, "rotation_degrees", 0.0, Globals.QUANTUM_CORE_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(Globals.QUANTUM_CORE_TWEEN_DELAY)

func _on_upgrade_pressed(upgrade_id: String) -> void:
	if Gm.purchase_upgrade(upgrade_id):
		# Play animation for the purchased upgrade
		if upgrade_id == "accelerator":
			upgrade1.play_purchase_animation()
		elif upgrade_id == "stabilizer":
			upgrade2.play_purchase_animation()
		elif upgrade_id == "shift":
			upgrade3.play_purchase_animation()
		update_ui()

func update_ui() -> void:
	particle_effect.position = quantum_core.position + (quantum_core.size / 2)
	quanta_label.text = Globals.QUANTA_LABEL_TEXT + "\n%d" % Gm.quanta
	cascade_progress.value = Gm.cascade_progress
	
	# Sync Upgrade properties with Gm.upgrades
	upgrade1.cost = Gm.upgrades.accelerator.cost
	upgrade1.level = Gm.upgrades.accelerator.level
	upgrade2.cost = Gm.upgrades.stabilizer.cost
	upgrade2.level = Gm.upgrades.stabilizer.level
	upgrade3.cost = Gm.upgrades.shift.cost
	upgrade3.level = Gm.upgrades.shift.level
	upgrade1.update_ui()
	upgrade2.update_ui()
	upgrade3.update_ui()
	
	if stats_label:
		stats_label.text = "\nq/t: %d, q/s: %d, m: %d" % [Gm.quanta_per_tap, Gm.quanta_per_second, Gm.multiplier]

	#upgrade1.tooltip_text = "Particle Accelerator: +1 Quanta/tap, Cost: %d" % Gm.upgrades.accelerator.cost
	#upgrade2.tooltip_text = "Quantum Stabilizer: +1 Quanta/sec, Cost: %d" % Gm.upgrades.stabilizer.cost
	#upgrade3.tooltip_text = "Dimensional Shift: x2 Multiplier, Cost: %d" % Gm.upgrades.shift.cost

func setup_cascade_progress_bar() -> void:
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
	
	fill.bg_color = Color(0.2, 0.5, 1.0)
	fill.shadow_color = Color(0, 0, 0, 0.3)
	fill.shadow_size = 2

	cascade_progress.add_theme_stylebox_override("background", bg)
	cascade_progress.add_theme_stylebox_override("fill", fill)
	cascade_progress.add_theme_font_override("font", Globals.UI_FONT_BOLD)
	cascade_progress.add_theme_font_size_override("font_size", Globals.UI_FONT_SIZE_LARGE)
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
	Gm.reset_game()
	update_ui()

func _on_new_game_pressed() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if admob.is_interstitial_ad_loaded():
				show_interstitial_ad()
			else:
				load_interstitial_ad()
				reset_game()
	else:
		reset_game()

func _on_ad_boost_pressed() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if is_admob_initialized:
			if admob.is_rewarded_ad_loaded():
				show_rewarded_ad()
			#else:
				#load_interstitial_ad()
				#reset_game()
